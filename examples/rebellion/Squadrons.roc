import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Squadron : {
	id : I32,
	name : Str,
	callsign_prefix : Str,
	starship_class : Str,
	motto : Try(Str, [Null]),
	commander : Try(Str, [Null]),
	base : Try(Str, [Null]),
}

Member : {
	assignment_id : I32,
	character_id : I32,
	name : Str,
	callsign : Try(Str, [Null]),
	position_number : I32,
	slot : Str,
	role : Try(Str, [Null]),
	starts_on : Str,
	wingmate : Try(Str, [Null]),
}

Readiness : {
	id : I32,
	name : Str,
	callsign_prefix : Str,
	starship_class : Str,
	commander : Str,
	base : Str,
	planet : Str,
	pilots : I64,
	pilots_on_leave : I64,
	ships : I64,
	ships_ready : I64,
	ships_in_repair : I64,
	average_hull : Dec,
	lowest_fuel : I32,
	next_maintenance_on : Try(Str, [Null]),
	kills : I64,
	days_active : I32,
	readiness : Str,
}

RosterEntry : {
	assignment_id : I32,
	position_number : I32,
	callsign : Str,
	character_id : I32,
	display_name : Str,
	role : Str,
	flight_hours : F64,
	confirmed_kills : I32,
	missions_flown : I32,
	piloting_score : I32,
	back_from_leave : Str,
	days_in_squadron : I32,
	wingmate : Str,
	ship : Str,
	registry_code : Str,
	model : Str,
	hull_integrity : I32,
	shield_integrity : I32,
	ship_condition : Str,
	recent_missions : I64,
	commendations : I64,
	status : Str,
}

Squadrons := [].{
	active! : Db => Try(List(Squadron), _)
	active! = |db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    s.name,
			\\    s.callsign_prefix,
			\\    s.starship_class,
			\\    s.motto,
			\\    c.name AS commander,
			\\    b.name AS base
			\\FROM squadrons s
			\\LEFT JOIN characters c ON c.id = s.commander_id
			\\LEFT JOIN bases b ON b.id = s.base_id
			\\WHERE s.active
			\\ORDER BY s.name
			,
			{},
		)

	by_name! : Str, Db => Try(Try({ id : I32, name : Str, callsign_prefix : Str, starship_class : Str, active : Bool, disbanded_at : Try(Str, [Null]) }, [NotFound]), _)
	by_name! = |name, db|
		db.query_optional!(
			\\SELECT id, name, callsign_prefix, starship_class, active, disbanded_at
			\\FROM squadrons
			\\WHERE name = $name
			,
			{ name, },
		)

	members! : I32, Db => Try(List(Member), _)
	members! = |squadron_id, db|
		db.query!(
			\\SELECT
			\\    sa.id AS assignment_id,
			\\    c.id AS character_id,
			\\    c.name,
			\\    c.callsign,
			\\    sa.position_number,
			\\    CASE WHEN sa.position_number = 1 THEN 'lead' ELSE 'wing' END AS slot,
			\\    sa.role,
			\\    sa.starts_on::text AS starts_on,
			\\    w.name AS wingmate
			\\FROM squadron_assignments sa
			\\JOIN characters c ON c.id = sa.character_id
			\\LEFT JOIN characters w ON w.id = sa.wingmate_id
			\\WHERE sa.squadron_id = $squadron_id
			\\  AND (sa.ends_on IS NULL OR sa.ends_on >= current_date)
			\\ORDER BY sa.position_number
			,
			{ squadron_id, },
		)

	current_squadrons! : List(I32), Db => Try(List({ character_id : I32, squadron : Str, starts_on : Str }), _)
	current_squadrons! = |ids, db|
		db.query!(
			\\SELECT DISTINCT ON (sa.character_id)
			\\    sa.character_id,
			\\    s.name AS squadron,
			\\    sa.starts_on::text AS starts_on
			\\FROM squadron_assignments sa
			\\JOIN squadrons s ON s.id = sa.squadron_id
			\\WHERE sa.character_id = any($ids)
			\\ORDER BY sa.character_id, sa.starts_on DESC
			,
			{ ids, },
		)

	strength! : Db => Try(List({ id : I32, name : Str, pilots : I64 }), _)
	strength! = |db|
		db.query!(
			\\SELECT s.id, s.name, count(sa.id) AS pilots
			\\FROM squadrons s
			\\LEFT JOIN squadron_assignments sa ON sa.squadron_id = s.id AND sa.ends_on IS NULL
			\\WHERE s.active
			\\GROUP BY s.id
			\\ORDER BY pilots DESC, s.name
			,
			{},
		)

	create! : Str, Str, Str, Try(I32, [Null]), Db => Try(Try({ id : I32 }, [NotFound]), _)
	create! = |name, callsign_prefix, starship_class, base_id, db|
		db.query_optional!(
			\\INSERT INTO squadrons (name, callsign_prefix, starship_class, base_id, created_at, updated_at)
			\\VALUES ($name, $callsign_prefix, $starship_class, $base_id, now(), now())
			\\ON CONFLICT (name) DO NOTHING
			\\RETURNING id
			,
			{ name, callsign_prefix, starship_class, base_id },
		)

	assign! : I32, I32, I32, Try(Str, [Null]), Db => Try({ id : I32 }, _)
	assign! = |squadron_id, character_id, position_number, role, db|
		db.query_one!(
			\\INSERT INTO squadron_assignments (
			\\    squadron_id, character_id, position_number, role, starts_on, created_at, updated_at
			\\)
			\\VALUES ($squadron_id, $character_id, $position_number, $role, current_date, now(), now())
			\\RETURNING id
			,
			{ squadron_id, character_id, position_number, role },
		)

	end_assignment! : I32, Db => Try(U64, _)
	end_assignment! = |id, db|
		db.execute!(
			\\UPDATE squadron_assignments
			\\SET ends_on = current_date, updated_at = now()
			\\WHERE id = $id AND ends_on IS NULL
			,
			{ id, },
		)

	set_wingmate! : I32, Try(I32, [Null]), Db => Try(U64, _)
	set_wingmate! = |id, wingmate_id, db|
		db.execute!("UPDATE squadron_assignments SET wingmate_id = $wingmate_id, updated_at = now() WHERE id = $id", { id, wingmate_id })

	set_motto! : I32, Str, Db => Try(U64, _)
	set_motto! = |id, motto, db|
		db.execute!("UPDATE squadrons SET motto = $motto, updated_at = now() WHERE id = $id", { id, motto })

	disband! : I32, Db => Try(U64, _)
	disband! = |id, db|
		db.execute!(
			\\UPDATE squadrons
			\\SET active = false, disbanded_at = now(), updated_at = now()
			\\WHERE id = $id AND active
			,
			{ id, },
		)

	readiness_report! : Db => Try(List(Readiness), _)
	readiness_report! = |db|
		db.query!(
			\\SELECT
			\\    sq.id,
			\\    sq.name,
			\\    sq.callsign_prefix,
			\\    sq.starship_class::text AS starship_class,
			\\    coalesce(c.name, 'no commander') AS commander,
			\\    coalesce(b.name, 'unassigned') AS base,
			\\    coalesce(p.name, 'unknown') AS planet,
			\\    coalesce((SELECT count(*) FROM squadron_assignments sa WHERE sa.squadron_id = sq.id AND sa.ends_on IS NULL), 0) AS pilots,
			\\    coalesce((SELECT count(*) FROM squadron_assignments sa JOIN characters pc ON pc.id = sa.character_id WHERE sa.squadron_id = sq.id AND sa.ends_on IS NULL AND pc.on_leave), 0) AS pilots_on_leave,
			\\    coalesce((SELECT count(*) FROM starships st WHERE st.squadron_id = sq.id AND st.destroyed_at IS NULL), 0) AS ships,
			\\    coalesce((SELECT count(*) FROM starships st WHERE st.squadron_id = sq.id AND st.condition = 'operational'), 0) AS ships_ready,
			\\    coalesce((SELECT count(*) FROM starships st WHERE st.squadron_id = sq.id AND st.condition IN ('damaged', 'under_repair')), 0) AS ships_in_repair,
			\\    coalesce((SELECT round(avg(st.hull_integrity), 1) FROM starships st WHERE st.squadron_id = sq.id AND st.destroyed_at IS NULL), 0) AS average_hull,
			\\    coalesce((SELECT min(st.fuel_pct) FROM starships st WHERE st.squadron_id = sq.id AND st.destroyed_at IS NULL), 0) AS lowest_fuel,
			\\    (SELECT min(st.next_maintenance_due_on) FROM starships st WHERE st.squadron_id = sq.id) AS next_maintenance_on,
			\\    coalesce((SELECT sum(st.kills_count) FROM starships st WHERE st.squadron_id = sq.id), 0) AS kills,
			\\    current_date - sq.created_at::date AS days_active,
			\\    CASE
			\\        WHEN NOT sq.active THEN 'disbanded'
			\\        WHEN (SELECT count(*) FROM starships st WHERE st.squadron_id = sq.id AND st.condition = 'operational') >= 12 THEN 'full strength'
			\\        WHEN (SELECT count(*) FROM starships st WHERE st.squadron_id = sq.id AND st.condition = 'operational') >= 6 THEN 'ready'
			\\        ELSE 'understrength'
			\\    END AS readiness
			\\FROM squadrons sq
			\\LEFT JOIN characters c ON c.id = sq.commander_id
			\\LEFT JOIN bases b ON b.id = sq.base_id
			\\LEFT JOIN planets p ON p.id = b.planet_id
			\\WHERE sq.active OR sq.disbanded_at > now() - interval '30 days'
			\\ORDER BY sq.name
			,
			{},
		)

	pilot_roster! : I32, Db => Try(List(RosterEntry), _)
	pilot_roster! = |squadron_id, db|
		db.query!(
			\\SELECT
			\\    sa.id AS assignment_id,
			\\    sa.position_number,
			\\    sq.callsign_prefix || ' ' || sa.position_number AS callsign,
			\\    c.id AS character_id,
			\\    coalesce(r.abbreviation || ' ', '') || c.name AS display_name,
			\\    coalesce(sa.role, 'pilot') AS role,
			\\    c.flight_hours,
			\\    c.confirmed_kills,
			\\    c.missions_flown,
			\\    coalesce(c.piloting_score, 0) AS piloting_score,
			\\    coalesce(to_char(c.leave_ends_on, 'YYYY-MM-DD'), '') AS back_from_leave,
			\\    current_date - sa.starts_on AS days_in_squadron,
			\\    coalesce((SELECT coalesce(w.callsign, w.name) FROM characters w WHERE w.id = sa.wingmate_id), 'none') AS wingmate,
			\\    coalesce(st.name, 'no ship') AS ship,
			\\    coalesce(st.registry_code, '') AS registry_code,
			\\    coalesce((SELECT sm.name FROM starship_models sm WHERE sm.id = st.starship_model_id), '') AS model,
			\\    coalesce(st.hull_integrity, 0) AS hull_integrity,
			\\    coalesce(st.shield_integrity, 0) AS shield_integrity,
			\\    coalesce(st.condition::text, 'none') AS ship_condition,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id AND mp.joined_at > now() - interval '90 days'), 0) AS recent_missions,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id AND mp.commended), 0) AS commendations,
			\\    CASE
			\\        WHEN c.on_leave THEN 'on leave'
			\\        WHEN c.captured_at IS NOT NULL AND c.rescued_at IS NULL THEN 'captured'
			\\        WHEN st.id IS NULL THEN 'grounded'
			\\        WHEN st.condition <> 'operational' THEN 'waiting for repairs'
			\\        ELSE 'ready'
			\\    END AS status
			\\FROM squadron_assignments sa
			\\JOIN squadrons sq ON sq.id = sa.squadron_id
			\\JOIN characters c ON c.id = sa.character_id
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\LEFT JOIN starships st ON st.pilot_id = c.id AND st.squadron_id = sq.id AND st.destroyed_at IS NULL
			\\WHERE sa.squadron_id = $squadron_id AND (sa.ends_on IS NULL OR sa.ends_on >= current_date)
			\\ORDER BY sa.position_number
			,
			{ squadron_id, },
		)


	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["active"] => Str.inspect(Squadrons.active!(db))
			["show", name] => Str.inspect(Squadrons.by_name!(name, db))
			["members", squadron_id] => Str.inspect(Squadrons.members!(Args.i32(squadron_id), db))
			["current", .. as ids] => Str.inspect(Squadrons.current_squadrons!(List.map(ids, Args.i32), db))
			["strength"] => Str.inspect(Squadrons.strength!(db))
			["create", name, prefix, starship_class] => Str.inspect(Squadrons.create!(name, prefix, starship_class, Err(Null), db))
			["create", name, prefix, starship_class, base_id] => Str.inspect(Squadrons.create!(name, prefix, starship_class, Ok(Args.i32(base_id)), db))
			["assign", squadron_id, character_id, position] => Str.inspect(Squadrons.assign!(Args.i32(squadron_id), Args.i32(character_id), Args.i32(position), Err(Null), db))
			["end", id] => Str.inspect(Squadrons.end_assignment!(Args.i32(id), db))
			["wingmate", id, wingmate_id] => Str.inspect(Squadrons.set_wingmate!(Args.i32(id), Ok(Args.i32(wingmate_id)), db))
			["no-wingmate", id] => Str.inspect(Squadrons.set_wingmate!(Args.i32(id), Err(Null), db))
			["motto", id, motto] => Str.inspect(Squadrons.set_motto!(Args.i32(id), motto, db))
			["disband", id] => Str.inspect(Squadrons.disband!(Args.i32(id), db))
			["readiness"] => Str.inspect(Squadrons.readiness_report!(db))
			["roster", squadron_id] => Str.inspect(Squadrons.pilot_roster!(Args.i32(squadron_id), db))
			_ => "unknown squadrons command"
		}
}
