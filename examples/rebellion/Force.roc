import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Lightsaber : {
	id : I32,
	hilt_style : Str,
	blade_color : Str,
	double_bladed : Bool,
	lost_at : Try(Str, [Null]),
	crystal_origin : Try(Str, [Null]),
	crystal_bled : Try(Bool, [Null]),
}

Crystal : {
	id : I32,
	origin : Str,
	color : Str,
	bled : Bool,
	resonance_hz : Try(F64, [Null]),
	found_at : Try(Str, [Null]),
}

JediProfile : {
	id : I32,
	name : Str,
	alias : Str,
	force_side : Str,
	species : Str,
	homeworld : Str,
	midichlorian_count : I64,
	enlisted_on : Str,
	sabers : I64,
	blade_colors : Str,
	bled_crystals : I64,
	hours_as_student : F64,
	hours_as_master : F64,
	students : I64,
	current_master : Try(Str, [Null]),
	last_training_at : Try(Str, [Null]),
	holocrons_kept : I64,
	battles : I64,
	wanted_by_empire : Bool,
	standing : Str,
}

TrainingReport : {
	master_id : I32,
	master : Str,
	force_side : Str,
	rank_title : Str,
	sessions : I64,
	students : I64,
	topics : I64,
	hours : F64,
	average_session_hours : Dec,
	longest_session_hours : F64,
	first_session_at : Str,
	last_session_at : Str,
	days_since_last_session : I32,
	sessions_this_week : I64,
	saber_hours : F64,
	meditation_hours : F64,
	student_names : Str,
	sabers : I64,
	teaching_load : Str,
}

Force := [].{
	sensitives! : Db => Try(List({ id : I32, name : Str, force_side : Try(Str, [Null]), midichlorian_count : Try(I64, [Null]), sabers : I64 }), _)
	sensitives! = |db|
		db.query!(
			\\SELECT
			\\    c.id,
			\\    c.name,
			\\    c.force_side,
			\\    c.midichlorian_count,
			\\    coalesce((SELECT count(*) FROM lightsabers l WHERE l.owner_id = c.id AND l.lost_at IS NULL), 0) AS sabers
			\\FROM characters c
			\\WHERE c.force_sensitive AND c.deceased_at IS NULL
			\\ORDER BY c.midichlorian_count DESC NULLS LAST
			,
			{},
		)

	lightsabers_of! : I32, Db => Try(List(Lightsaber), _)
	lightsabers_of! = |owner_id, db|
		db.query!(
			\\SELECT
			\\    l.id,
			\\    l.hilt_style,
			\\    l.blade_color,
			\\    l.double_bladed,
			\\    l.lost_at,
			\\    k.origin::text AS crystal_origin,
			\\    k.bled AS crystal_bled
			\\FROM lightsabers l
			\\LEFT JOIN kyber_crystals k ON k.id = l.kyber_crystal_id
			\\WHERE l.owner_id = $owner_id
			\\ORDER BY l.created_at
			,
			{ owner_id, },
		)

	crystals! : Try(Str, [Null]), Db => Try(List(Crystal), _)
	crystals! = |origin, db|
		db.query!(
			\\SELECT id, origin, color, bled, resonance_hz, found_at
			\\FROM kyber_crystals
			\\WHERE ($origin::text IS NULL OR origin::text = $origin)
			\\ORDER BY found_at DESC NULLS LAST
			,
			{ origin, },
		)

	lost_sabers! : Db => Try(List({ id : I32, owner : Try(Str, [Null]), blade_color : Str, lost_at : Try(Str, [Null]) }), _)
	lost_sabers! = |db|
		db.query!(
			\\SELECT l.id, c.name AS owner, l.blade_color, l.lost_at
			\\FROM lightsabers l
			\\LEFT JOIN characters c ON c.id = l.owner_id
			\\WHERE l.lost_at > now() - interval '1 year'
			\\ORDER BY l.lost_at DESC
			,
			{},
		)

	forge! : I32, I32, Str, Str, Db => Try({ id : I32 }, _)
	forge! = |owner_id, kyber_crystal_id, hilt_style, blade_color, db|
		db.query_one!(
			\\INSERT INTO lightsabers (owner_id, kyber_crystal_id, hilt_style, blade_color, created_at, updated_at)
			\\VALUES ($owner_id, $kyber_crystal_id, $hilt_style, $blade_color, now(), now())
			\\RETURNING id
			,
			{ owner_id, kyber_crystal_id, hilt_style, blade_color },
		)

	bleed_crystal! : I32, Db => Try({ id : I32, color : Str }, _)
	bleed_crystal! = |id, db|
		db.query_one!(
			\\UPDATE kyber_crystals
			\\SET bled = true, color = 'red', updated_at = now()
			\\WHERE id = $id
			\\RETURNING id, color
			,
			{ id, },
		)

	training_log! : I32, Db => Try(List({ id : I32, master : Str, topic : Str, duration_hours : F64, created_at : Str }), _)
	training_log! = |student_id, db|
		db.query!(
			\\SELECT t.id, m.name AS master, t.topic, t.duration_hours, t.created_at
			\\FROM training_sessions t
			\\JOIN characters m ON m.id = t.master_id
			\\WHERE t.student_id = $student_id
			\\ORDER BY t.created_at DESC
			,
			{ student_id, },
		)

	training_hours! : I32, Db => Try({ hours : F64 }, _)
	training_hours! = |student_id, db|
		db.query_one!(
			\\SELECT coalesce(sum(duration_hours), 0) AS hours
			\\FROM training_sessions
			\\WHERE student_id = $student_id AND created_at > now() - interval '30 days'
			,
			{ student_id, },
		)

	log_training! : I32, I32, Str, F64, Db => Try({ id : I32 }, _)
	log_training! = |student_id, master_id, topic, duration_hours, db|
		db.query_one!(
			\\INSERT INTO training_sessions (student_id, master_id, topic, duration_hours, created_at, updated_at)
			\\VALUES ($student_id, $master_id, $topic, $duration_hours, now(), now())
			\\RETURNING id
			,
			{ student_id, master_id, topic, duration_hours },
		)

	holocrons! : Str, Db => Try(List({ id : I32, title : Str, side : Str, guardian : Str, recovered_at : Try(Str, [Null]) }), _)
	holocrons! = |text, db|
		db.query!(
			\\SELECT
			\\    h.id,
			\\    h.title,
			\\    h.side,
			\\    coalesce(c.name, h.gatekeeper_name, 'unknown') AS guardian,
			\\    h.recovered_at
			\\FROM holocrons h
			\\LEFT JOIN characters c ON c.id = h.keeper_id
			\\WHERE h.title ILIKE '%' || $text || '%'
			\\ORDER BY h.title
			,
			{ text, },
		)

	recover_holocron! : I32, I32, Db => Try(U64, _)
	recover_holocron! = |id, keeper_id, db|
		db.execute!(
			\\UPDATE holocrons
			\\SET keeper_id = $keeper_id, recovered_at = coalesce(recovered_at, now()), updated_at = now()
			\\WHERE id = $id
			,
			{ id, keeper_id },
		)

	jedi_profile! : I32, Db => Try(Try(JediProfile, [NotFound]), _)
	jedi_profile! = |character_id, db|
		db.query_optional!(
			\\SELECT
			\\    c.id,
			\\    c.name,
			\\    coalesce(c.alias, '') AS alias,
			\\    coalesce(c.force_side::text, 'undeclared') AS force_side,
			\\    coalesce(s.name, 'unknown') AS species,
			\\    coalesce(p.name, 'unknown') AS homeworld,
			\\    coalesce(c.midichlorian_count, 0) AS midichlorian_count,
			\\    coalesce(to_char(c.enlisted_at, 'YYYY-MM-DD'), 'never') AS enlisted_on,
			\\    coalesce((SELECT count(*) FROM lightsabers l WHERE l.owner_id = c.id AND l.lost_at IS NULL), 0) AS sabers,
			\\    coalesce((SELECT string_agg(DISTINCT l.blade_color, ', ') FROM lightsabers l WHERE l.owner_id = c.id), '') AS blade_colors,
			\\    coalesce((SELECT count(*) FROM lightsabers l JOIN kyber_crystals k ON k.id = l.kyber_crystal_id WHERE l.owner_id = c.id AND k.bled), 0) AS bled_crystals,
			\\    coalesce((SELECT sum(t.duration_hours) FROM training_sessions t WHERE t.student_id = c.id), 0) AS hours_as_student,
			\\    coalesce((SELECT sum(t.duration_hours) FROM training_sessions t WHERE t.master_id = c.id), 0) AS hours_as_master,
			\\    coalesce((SELECT count(DISTINCT t.student_id) FROM training_sessions t WHERE t.master_id = c.id), 0) AS students,
			\\    (SELECT m.name FROM training_sessions t JOIN characters m ON m.id = t.master_id WHERE t.student_id = c.id ORDER BY t.created_at DESC LIMIT 1) AS current_master,
			\\    (SELECT max(t.created_at) FROM training_sessions t WHERE t.student_id = c.id OR t.master_id = c.id) AS last_training_at,
			\\    coalesce((SELECT count(*) FROM holocrons h WHERE h.keeper_id = c.id), 0) AS holocrons_kept,
			\\    coalesce((SELECT count(*) FROM battle_participants bp WHERE bp.character_id = c.id), 0) AS battles,
			\\    c.wanted_by_empire,
			\\    CASE
			\\        WHEN (SELECT count(DISTINCT t.student_id) FROM training_sessions t WHERE t.master_id = c.id) >= 3 THEN 'master'
			\\        WHEN (SELECT sum(t.duration_hours) FROM training_sessions t WHERE t.student_id = c.id) >= 1000 THEN 'knight'
			\\        WHEN EXISTS (SELECT 1 FROM training_sessions t WHERE t.student_id = c.id) THEN 'padawan'
			\\        ELSE 'untrained'
			\\    END AS standing
			\\FROM characters c
			\\LEFT JOIN species s ON s.id = c.species_id
			\\LEFT JOIN planets p ON p.id = c.homeworld_id
			\\WHERE c.id = $character_id AND c.force_sensitive
			,
			{ character_id, },
		)

	training_report! : I32, Db => Try(List(TrainingReport), _)
	training_report! = |days, db|
		db.query!(
			\\SELECT
			\\    m.id AS master_id,
			\\    m.name AS master,
			\\    coalesce(m.force_side::text, 'undeclared') AS force_side,
			\\    coalesce(r.title, 'Unranked') AS rank_title,
			\\    count(t.id) AS sessions,
			\\    count(DISTINCT t.student_id) AS students,
			\\    count(DISTINCT t.topic) AS topics,
			\\    coalesce(sum(t.duration_hours), 0) AS hours,
			\\    coalesce(round(avg(t.duration_hours)::numeric, 2), 0) AS average_session_hours,
			\\    coalesce(max(t.duration_hours), 0) AS longest_session_hours,
			\\    min(t.created_at) AS first_session_at,
			\\    max(t.created_at) AS last_session_at,
			\\    current_date - max(t.created_at)::date AS days_since_last_session,
			\\    count(t.id) FILTER (WHERE t.created_at > now() - interval '7 days') AS sessions_this_week,
			\\    coalesce(sum(t.duration_hours) FILTER (WHERE t.topic ILIKE '%saber%'), 0) AS saber_hours,
			\\    coalesce(sum(t.duration_hours) FILTER (WHERE t.topic ILIKE '%meditation%'), 0) AS meditation_hours,
			\\    coalesce(string_agg(DISTINCT s.name, ', '), '') AS student_names,
			\\    coalesce((SELECT count(*) FROM lightsabers l WHERE l.owner_id = m.id AND l.lost_at IS NULL), 0) AS sabers,
			\\    CASE
			\\        WHEN count(DISTINCT t.student_id) >= 3 THEN 'council material'
			\\        WHEN count(t.id) >= 10 THEN 'dedicated'
			\\        ELSE 'occasional'
			\\    END AS teaching_load
			\\FROM training_sessions t
			\\JOIN characters m ON m.id = t.master_id
			\\JOIN characters s ON s.id = t.student_id
			\\LEFT JOIN ranks r ON r.id = m.rank_id
			\\WHERE t.created_at > now() - interval '1 day' * $days
			\\GROUP BY m.id, r.title
			\\ORDER BY hours DESC
			,
			{ days, },
		)


	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["sensitives"] => Str.inspect(Force.sensitives!(db))
			["lightsabers", owner_id] => Str.inspect(Force.lightsabers_of!(Args.i32(owner_id), db))
			["crystals"] => Str.inspect(Force.crystals!(Err(Null), db))
			["crystals", origin] => Str.inspect(Force.crystals!(Ok(origin), db))
			["lost-sabers"] => Str.inspect(Force.lost_sabers!(db))
			["forge", owner_id, crystal_id, hilt_style, blade_color] => Str.inspect(Force.forge!(Args.i32(owner_id), Args.i32(crystal_id), hilt_style, blade_color, db))
			["bleed", id] => Str.inspect(Force.bleed_crystal!(Args.i32(id), db))
			["training", student_id] => Str.inspect(Force.training_log!(Args.i32(student_id), db))
			["training-hours", student_id] => Str.inspect(Force.training_hours!(Args.i32(student_id), db))
			["log-training", student_id, master_id, topic, hours] => Str.inspect(Force.log_training!(Args.i32(student_id), Args.i32(master_id), topic, Args.f64(hours), db))
			["holocrons", text] => Str.inspect(Force.holocrons!(text, db))
			["recover-holocron", id, keeper_id] => Str.inspect(Force.recover_holocron!(Args.i32(id), Args.i32(keeper_id), db))
			["profile", character_id] => Str.inspect(Force.jedi_profile!(Args.i32(character_id), db))
			["training-report", days] => Str.inspect(Force.training_report!(Args.i32(days), db))
			_ => "unknown force command"
		}
}
