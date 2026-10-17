import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Droid : {
	id : I32,
	designation : Str,
	nickname : Try(Str, [Null]),
	serial_number : Try(Str, [Null]),
	plating_color : Try(Str, [Null]),
	restraining_bolt : Bool,
	memory_wiped_count : I32,
	last_memory_wipe_at : Try(Str, [Null]),
	personality_quirks : Try(Str, [Null]),
	carries_secret_plans : Bool,
	operational : Bool,
	oil_bath_due_on : Try(Str, [Null]),
	repair_count : I32,
	stolen : Bool,
	jawa_salvaged : Bool,
	purchase_price : Try(I64, [Null]),
	purchased_from : Try(Str, [Null]),
	activated_at : Try(Str, [Null]),
	notes : Try(Str, [Null]),
	model : Str,
	droid_class : Str,
	languages_known : Try(I32, [Null]),
	owner : Try(Str, [Null]),
	starship : Try(Str, [Null]),
}

DroidSummary : {
	id : I32,
	designation : Str,
	nickname : Try(Str, [Null]),
	operational : Bool,
}

Dossier : {
	id : I32,
	label : Str,
	display_name : Str,
	model : Str,
	droid_class : Str,
	manufacturer : Str,
	height_m : Try(F64, [Null]),
	languages_known : Try(I32, [Null]),
	serial_number : Str,
	plating_color : Try(Str, [Null]),
	owner : Try(Str, [Null]),
	owner_allegiance : Try(Str, [Null]),
	starship : Try(Str, [Null]),
	base : Str,
	status : Str,
	restraining_bolt : Bool,
	memory_wiped_count : I32,
	wipes_logged : I64,
	last_wipe_logged_at : Try(Str, [Null]),
	last_wipe_reason : Try(Str, [Null]),
	oil_bath_overdue_days : Try(I32, [Null]),
	repair_count : I32,
	provenance : Str,
	purchase_price : Try(I64, [Null]),
	activated_at : Try(Str, [Null]),
	days_active : Try(F64, [Null]),
	payload : Str,
	personality_quirks : Try(Str, [Null]),
	notes : Try(Str, [Null]),
}

AttentionRow : {
	id : I32,
	designation : Str,
	droid_class : Str,
	base : Str,
	owner : Try(Str, [Null]),
	assigned_to : Str,
	oil_bath : Str,
	oil_bath_overdue : Bool,
	wipe_due : Bool,
	days_since_wipe : Try(I32, [Null]),
	wipes_logged : I64,
	repair_count : I32,
	repair_band : Str,
	restraining_bolt : Bool,
	unbolted_with_secrets : Bool,
	attention_score : I32,
	next_action : Str,
	model_languages : Str,
	days_active : Try(I32, [Null]),
	jawa_salvaged : Bool,
	value : I64,
}

Droids := [].{
	droid! : I32, Db => Try(Try(Droid, [NotFound]), _)
	droid! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    d.id,
			\\    d.designation,
			\\    d.nickname,
			\\    d.serial_number,
			\\    d.plating_color,
			\\    d.restraining_bolt,
			\\    d.memory_wiped_count,
			\\    d.last_memory_wipe_at,
			\\    d.personality_quirks,
			\\    d.carries_secret_plans,
			\\    d.operational,
			\\    d.oil_bath_due_on,
			\\    d.repair_count,
			\\    d.stolen,
			\\    d.jawa_salvaged,
			\\    d.purchase_price,
			\\    d.purchased_from,
			\\    d.activated_at,
			\\    d.notes,
			\\    dm.name AS model,
			\\    dm.droid_class,
			\\    dm.languages_known,
			\\    c.name AS owner,
			\\    s.name AS starship
			\\FROM droids d
			\\JOIN droid_models dm ON dm.id = d.droid_model_id
			\\LEFT JOIN characters c ON c.id = d.owner_id
			\\LEFT JOIN starships s ON s.id = d.starship_id
			\\WHERE d.id = $id
			,
			{ id, },
		)

	search! : Str, Db => Try(List(DroidSummary), _)
	search! = |text, db|
		db.query!(
			\\SELECT id, designation, nickname, operational
			\\FROM droids
			\\WHERE archived_at IS NULL
			\\  AND (designation ILIKE $text || '%' OR nickname ILIKE '%' || $text || '%')
			\\ORDER BY designation
			\\LIMIT 50
			,
			{ text, },
		)

	by_class! : Str, Db => Try(List(DroidSummary), _)
	by_class! = |droid_class, db|
		db.query!(
			\\SELECT d.id, d.designation, d.nickname, d.operational
			\\FROM droids d
			\\JOIN droid_models dm ON dm.id = d.droid_model_id
			\\WHERE dm.droid_class = $droid_class::droid_class AND d.archived_at IS NULL
			\\ORDER BY d.designation
			,
			{ droid_class, },
		)

	unassigned_astromechs! : Db => Try(List(DroidSummary), _)
	unassigned_astromechs! = |db|
		db.query!(
			\\SELECT id, designation, nickname, operational
			\\FROM droids
			\\WHERE starship_id IS NULL
			\\  AND operational
			\\  AND droid_model_id IN (SELECT id FROM droid_models WHERE droid_class = 'astromech')
			\\ORDER BY designation
			,
			{},
		)

	carrying_plans! : Db => Try(List({ id : I32, designation : Str, payload : Str }), _)
	carrying_plans! = |db|
		db.query!(
			\\SELECT id, designation, coalesce(secret_payload, 'unknown') AS payload
			\\FROM droids
			\\WHERE carries_secret_plans
			\\ORDER BY designation
			,
			{},
		)

	register! : I32, Str, Str, Try(I32, [Null]), Db => Try(Try({ id : I32 }, [NotFound]), _)
	register! = |droid_model_id, designation, serial_number, owner_id, db|
		db.query_optional!(
			\\INSERT INTO droids (droid_model_id, designation, serial_number, owner_id, activated_at, created_at, updated_at)
			\\VALUES ($droid_model_id, $designation, $serial_number, $owner_id, now(), now(), now())
			\\ON CONFLICT (serial_number) DO NOTHING
			\\RETURNING id
			,
			{ droid_model_id, designation, serial_number, owner_id },
		)

	log_memory_wipe! : I32, Try(I32, [Null]), Try(Str, [Null]), Db => Try({ id : I32 }, _)
	log_memory_wipe! = |droid_id, performed_by_id, reason, db|
		db.query_one!(
			\\INSERT INTO droid_memory_wipes (droid_id, performed_by_id, reason, created_at, updated_at)
			\\VALUES ($droid_id, $performed_by_id, $reason, now(), now())
			\\RETURNING id
			,
			{ droid_id, performed_by_id, reason },
		)

	wipe_memory! : I32, Db => Try(Try({ memory_wiped_count : I32 }, [NotFound]), _)
	wipe_memory! = |id, db|
		db.query_optional!(
			\\UPDATE droids
			\\SET memory_wiped_count = memory_wiped_count + 1,
			\\    last_memory_wipe_at = now(),
			\\    personality_quirks = NULL,
			\\    updated_at = now()
			\\WHERE id = $id
			\\RETURNING memory_wiped_count
			,
			{ id, },
		)

	oil_baths_due! : I32, Db => Try(List({ id : I32, designation : Str, oil_bath_due_on : Str }), _)
	oil_baths_due! = |days, db|
		db.query!(
			\\SELECT id, designation, oil_bath_due_on::text AS oil_bath_due_on
			\\FROM droids
			\\WHERE operational
			\\  AND oil_bath_due_on < (current_date + interval '1 day' * $days)::date
			\\ORDER BY oil_bath_due_on
			,
			{ days, },
		)

	set_owner! : I32, Try(I32, [Null]), Db => Try(U64, _)
	set_owner! = |id, owner_id, db|
		db.execute!(
			\\UPDATE droids
			\\SET owner_id = $owner_id,
			\\    restraining_bolt = CASE WHEN $owner_id::integer IS NULL THEN false ELSE restraining_bolt END,
			\\    updated_at = now()
			\\WHERE id = $id
			,
			{ id, owner_id },
		)

	wipe_counts! : Db => Try(List({ droid_class : Str, droids : I64, wipes : I64 }), _)
	wipe_counts! = |db|
		db.query!(
			\\SELECT dm.droid_class, count(*) AS droids, coalesce(sum(d.memory_wiped_count), 0) AS wipes
			\\FROM droids d
			\\JOIN droid_models dm ON dm.id = d.droid_model_id
			\\GROUP BY dm.droid_class
			\\ORDER BY wipes DESC
			,
			{},
		)

	dossier! : I32, Db => Try(Try(Dossier, [NotFound]), _)
	dossier! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    d.id,
			\\    d.designation || coalesce(' "' || d.nickname || '"', '') AS label,
			\\    coalesce(d.nickname, d.designation) AS display_name,
			\\    dm.name AS model,
			\\    dm.droid_class,
			\\    coalesce(mf.name, 'unknown') AS manufacturer,
			\\    dm.height_m,
			\\    dm.languages_known,
			\\    coalesce(d.serial_number, 'none') AS serial_number,
			\\    d.plating_color,
			\\    c.name AS owner,
			\\    c.allegiance::text AS owner_allegiance,
			\\    s.name AS starship,
			\\    coalesce((SELECT b.name FROM bases b WHERE b.id = d.base_id), 'unassigned') AS base,
			\\    CASE
			\\        WHEN NOT d.operational THEN 'deactivated'
			\\        WHEN d.restraining_bolt THEN 'restrained'
			\\        WHEN d.owner_id IS NULL THEN 'free agent'
			\\        ELSE 'owned'
			\\    END AS status,
			\\    d.restraining_bolt,
			\\    d.memory_wiped_count,
			\\    coalesce((SELECT count(*) FROM droid_memory_wipes w WHERE w.droid_id = d.id), 0) AS wipes_logged,
			\\    (SELECT max(w.created_at) FROM droid_memory_wipes w WHERE w.droid_id = d.id) AS last_wipe_logged_at,
			\\    (SELECT w.reason FROM droid_memory_wipes w WHERE w.droid_id = d.id ORDER BY w.created_at DESC LIMIT 1) AS last_wipe_reason,
			\\    current_date - d.oil_bath_due_on AS oil_bath_overdue_days,
			\\    d.repair_count,
			\\    CASE
			\\        WHEN d.jawa_salvaged THEN 'salvaged by jawas'
			\\        WHEN d.stolen THEN 'stolen'
			\\        WHEN d.purchase_price IS NOT NULL THEN 'bought from ' || coalesce(d.purchased_from, 'unknown seller')
			\\        ELSE 'unknown'
			\\    END AS provenance,
			\\    d.purchase_price,
			\\    d.activated_at,
			\\    date_part('day', now() - d.activated_at) AS days_active,
			\\    CASE WHEN d.carries_secret_plans THEN coalesce(d.secret_payload, 'classified') ELSE 'none' END AS payload,
			\\    d.personality_quirks,
			\\    d.notes
			\\FROM droids d
			\\JOIN droid_models dm ON dm.id = d.droid_model_id
			\\LEFT JOIN manufacturers mf ON mf.id = dm.manufacturer_id
			\\LEFT JOIN characters c ON c.id = d.owner_id
			\\LEFT JOIN starships s ON s.id = d.starship_id
			\\WHERE d.id = $id
			,
			{ id, },
		)

	attention_board! : Try(I32, [Null]), Try(Str, [Null]), Db => Try(List(AttentionRow), _)
	attention_board! = |base_id, droid_class, db|
		db.query!(
			\\SELECT
			\\    d.id,
			\\    d.designation,
			\\    dm.droid_class,
			\\    coalesce(b.code_name, 'in the field') AS base,
			\\    c.name AS owner,
			\\    coalesce(s.name, b.name, 'nobody') AS assigned_to,
			\\    coalesce(to_char(d.oil_bath_due_on, 'YYYY-MM-DD'), 'never scheduled') AS oil_bath,
			\\    coalesce(d.oil_bath_due_on < current_date, false) AS oil_bath_overdue,
			\\    coalesce(d.last_memory_wipe_at < now() - interval '180 days', true) AS wipe_due,
			\\    current_date - d.last_memory_wipe_at::date AS days_since_wipe,
			\\    coalesce((SELECT count(*) FROM droid_memory_wipes w WHERE w.droid_id = d.id), 0) AS wipes_logged,
			\\    d.repair_count,
			\\    CASE WHEN d.repair_count > 10 THEN 'scrap candidate' WHEN d.repair_count > 5 THEN 'fragile' ELSE 'sound' END AS repair_band,
			\\    d.restraining_bolt,
			\\    d.carries_secret_plans AND NOT d.restraining_bolt AS unbolted_with_secrets,
			\\    CASE WHEN d.oil_bath_due_on < current_date THEN 3 ELSE 0 END
			\\        + CASE WHEN d.repair_count > 5 THEN 2 ELSE 0 END
			\\        + CASE WHEN d.carries_secret_plans AND NOT d.restraining_bolt THEN 4 ELSE 0 END
			\\        + CASE WHEN d.last_memory_wipe_at IS NULL OR d.last_memory_wipe_at < now() - interval '180 days' THEN 1 ELSE 0 END AS attention_score,
			\\    CASE
			\\        WHEN d.carries_secret_plans AND NOT d.restraining_bolt THEN 'fit a restraining bolt'
			\\        WHEN d.oil_bath_due_on < current_date THEN 'oil bath'
			\\        WHEN d.repair_count > 5 THEN 'full diagnostic'
			\\        ELSE 'none'
			\\    END AS next_action,
			\\    dm.name || ' (' || coalesce(dm.languages_known::text, '?') || ' languages)' AS model_languages,
			\\    current_date - d.activated_at::date AS days_active,
			\\    d.jawa_salvaged,
			\\    coalesce(d.purchase_price, 0) AS value
			\\FROM droids d
			\\JOIN droid_models dm ON dm.id = d.droid_model_id
			\\LEFT JOIN bases b ON b.id = d.base_id
			\\LEFT JOIN characters c ON c.id = d.owner_id
			\\LEFT JOIN starships s ON s.id = d.starship_id
			\\WHERE d.operational
			\\  AND d.archived_at IS NULL
			\\  AND ($base_id::integer IS NULL OR d.base_id = $base_id)
			\\  AND ($droid_class::text IS NULL OR dm.droid_class::text = $droid_class)
			\\ORDER BY attention_score DESC, d.designation
			,
			{ base_id, droid_class },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["droid", id] => Str.inspect(Droids.droid!(Args.i32(id), db))
			["search", text] => Str.inspect(Droids.search!(text, db))
			["class", droid_class] => Str.inspect(Droids.by_class!(droid_class, db))
			["unassigned-astromechs"] => Str.inspect(Droids.unassigned_astromechs!(db))
			["carrying-plans"] => Str.inspect(Droids.carrying_plans!(db))
			["register", model_id, designation, serial_number] => Str.inspect(Droids.register!(Args.i32(model_id), designation, serial_number, Err(Null), db))
			["wipe", id, reason] => {
				logged = Droids.log_memory_wipe!(Args.i32(id), Err(Null), Ok(reason), db)
				wiped = Droids.wipe_memory!(Args.i32(id), db)
				"${Str.inspect(logged)}\n${Str.inspect(wiped)}"
			}
			["oil-baths", days] => Str.inspect(Droids.oil_baths_due!(Args.i32(days), db))
			["owner", id, owner_id] => Str.inspect(Droids.set_owner!(Args.i32(id), Ok(Args.i32(owner_id)), db))
			["release", id] => Str.inspect(Droids.set_owner!(Args.i32(id), Err(Null), db))
			["wipe-counts"] => Str.inspect(Droids.wipe_counts!(db))
			["dossier", id] => Str.inspect(Droids.dossier!(Args.i32(id), db))
			["attention"] => Str.inspect(Droids.attention_board!(Err(Null), Err(Null), db))
			["attention", "base", base_id] => Str.inspect(Droids.attention_board!(Ok(Args.i32(base_id)), Err(Null), db))
			["attention", "class", droid_class] => Str.inspect(Droids.attention_board!(Err(Null), Ok(droid_class), db))
			_ => "unknown droids command"
		}
}
