import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Manufacturer : {
	id : I32,
	name : Str,
	short_name : Try(Str, [Null]),
	imperial_contractor : Bool,
	sells_to_rebels : Bool,
}

Model : {
	id : I32,
	name : Str,
	model_code : Str,
	starship_class : Str,
	hyperdrive_rating : Try(F64, [Null]),
	mglt : Try(I32, [Null]),
	cost_credits : Try(I64, [Null]),
	manufacturer : Str,
}

Starship : {
	id : I32,
	name : Str,
	registry_code : Str,
	transponder_code : Try(Str, [Null]),
	false_transponder_code : Try(Str, [Null]),
	condition : Str,
	hull_integrity : I32,
	shield_integrity : I32,
	fuel_pct : I32,
	hyperdrive_operational : Bool,
	stolen : Bool,
	stolen_from : Try(Str, [Null]),
	acquired_at : Try(Str, [Null]),
	acquired_from : Try(Str, [Null]),
	acquisition_cost : Try(I64, [Null]),
	last_jump_at : Try(Str, [Null]),
	last_maintenance_at : Try(Str, [Null]),
	next_maintenance_due_on : Try(Str, [Null]),
	flight_hours : F64,
	jumps_count : I32,
	kills_count : I32,
	destroyed_at : Try(Str, [Null]),
	decommissioned_at : Try(Str, [Null]),
	paint_scheme : Try(Str, [Null]),
	nickname : Try(Str, [Null]),
	notes : Try(Str, [Null]),
	lock_version : I32,
	model : Str,
	model_code : Str,
	starship_class : Str,
	hyperdrive_rating : Try(F64, [Null]),
	mglt : Try(I32, [Null]),
	crew_min : Try(I32, [Null]),
	manufacturer : Str,
	squadron : Try(Str, [Null]),
	callsign_prefix : Try(Str, [Null]),
	pilot : Try(Str, [Null]),
	pilot_callsign : Try(Str, [Null]),
}

ShipSummary : {
	id : I32,
	name : Str,
	registry_code : Str,
	condition : Str,
	hull_integrity : I32,
}

ReadinessRow : {
	id : I32,
	display_name : Str,
	designation_label : Str,
	model : Str,
	starship_class : Str,
	manufacturer : Str,
	pilot : Try(Str, [Null]),
	pilot_callsign : Str,
	hangar : Try(Str, [Null]),
	base : Try(Str, [Null]),
	condition : Str,
	readiness : Str,
	readiness_score : I32,
	hull_integrity : I32,
	shield_integrity : I32,
	fuel_pct : I32,
	hyperdrive : Str,
	flight_hours : F64,
	jumps_count : I32,
	kills_count : I32,
	days_since_maintenance : Try(I32, [Null]),
	days_until_maintenance : Try(I32, [Null]),
	failed_inspections : I64,
	weapons_fitted : I64,
	droids_aboard : I64,
	provenance : Str,
	transponder_status : Str,
}

AcquisitionRow : {
	id : I32,
	name : Str,
	registry_code : Str,
	model : Str,
	starship_class : Str,
	manufacturer : Str,
	sells_to_rebels : Bool,
	acquired_at : Try(Str, [Null]),
	acquired_year : Try(F64, [Null]),
	days_in_service : Try(I32, [Null]),
	acquired_from : Str,
	acquisition_cost : Try(I64, [Null]),
	list_price : Try(I64, [Null]),
	used_price : Try(I64, [Null]),
	deal : Str,
	savings : I64,
	stolen : Bool,
	stolen_from : Str,
	transponder_code : Try(Str, [Null]),
	false_transponder_code : Try(Str, [Null]),
	transponder_status : Str,
	condition : Str,
	flight_hours : F64,
	kills_count : I32,
	kills_per_hour : Dec,
	weapons_fitted : I64,
	maintenance_hours : F64,
	status : Str,
}

Fleet := [].{
	manufacturers! : Db => Try(List(Manufacturer), _)
	manufacturers! = |db|
		db.query!(
			\\SELECT id, name, short_name, imperial_contractor, sells_to_rebels
			\\FROM manufacturers
			\\ORDER BY name
			,
			{},
		)

	upsert_manufacturer! : Str, Try(Str, [Null]), Bool, Db => Try({ id : I32 }, _)
	upsert_manufacturer! = |name, short_name, sells_to_rebels, db|
		db.query_one!(
			\\INSERT INTO manufacturers (name, short_name, sells_to_rebels, created_at, updated_at)
			\\VALUES ($name, $short_name, $sells_to_rebels, now(), now())
			\\ON CONFLICT (name) DO UPDATE
			\\SET short_name = excluded.short_name,
			\\    sells_to_rebels = excluded.sells_to_rebels,
			\\    updated_at = now()
			\\RETURNING id
			,
			{ name, short_name, sells_to_rebels },
		)

	models_by_class! : Str, Db => Try(List(Model), _)
	models_by_class! = |starship_class, db|
		db.query!(
			\\SELECT
			\\    sm.id,
			\\    sm.name,
			\\    sm.model_code,
			\\    sm.starship_class,
			\\    sm.hyperdrive_rating,
			\\    sm.mglt,
			\\    sm.cost_credits,
			\\    mf.name AS manufacturer
			\\FROM starship_models sm
			\\JOIN manufacturers mf ON mf.id = sm.manufacturer_id
			\\WHERE sm.starship_class = $starship_class::starship_class AND sm.in_production
			\\ORDER BY sm.name
			,
			{ starship_class, },
		)

	starship! : I32, Db => Try(Try(Starship, [NotFound]), _)
	starship! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    s.id,
			\\    s.name,
			\\    s.registry_code,
			\\    s.transponder_code,
			\\    s.false_transponder_code,
			\\    s.condition,
			\\    s.hull_integrity,
			\\    s.shield_integrity,
			\\    s.fuel_pct,
			\\    s.hyperdrive_operational,
			\\    s.stolen,
			\\    s.stolen_from,
			\\    s.acquired_at,
			\\    s.acquired_from,
			\\    s.acquisition_cost,
			\\    s.last_jump_at,
			\\    s.last_maintenance_at,
			\\    s.next_maintenance_due_on,
			\\    s.flight_hours,
			\\    s.jumps_count,
			\\    s.kills_count,
			\\    s.destroyed_at,
			\\    s.decommissioned_at,
			\\    s.paint_scheme,
			\\    s.nickname,
			\\    s.notes,
			\\    s.lock_version,
			\\    sm.name AS model,
			\\    sm.model_code,
			\\    sm.starship_class,
			\\    sm.hyperdrive_rating,
			\\    sm.mglt,
			\\    sm.crew_min,
			\\    mf.name AS manufacturer,
			\\    sq.name AS squadron,
			\\    sq.callsign_prefix,
			\\    c.name AS pilot,
			\\    c.callsign AS pilot_callsign
			\\FROM starships s
			\\JOIN starship_models sm ON sm.id = s.starship_model_id
			\\JOIN manufacturers mf ON mf.id = sm.manufacturer_id
			\\LEFT JOIN squadrons sq ON sq.id = s.squadron_id
			\\LEFT JOIN characters c ON c.id = s.pilot_id
			\\WHERE s.id = $id AND s.archived_at IS NULL
			,
			{ id, },
		)

	starships_by_ids! : List(I32), Db => Try(List(ShipSummary), _)
	starships_by_ids! = |ids, db|
		db.query!(
			\\SELECT id, name, registry_code, condition, hull_integrity
			\\FROM starships
			\\WHERE id = any($ids)
			\\ORDER BY name
			,
			{ ids, },
		)

	squadron_ships! : I32, Db => Try(List({ id : I32, display_name : Str, condition : Str, pilot : Try(Str, [Null]) }), _)
	squadron_ships! = |squadron_id, db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    coalesce(s.nickname, s.name) AS display_name,
			\\    s.condition,
			\\    c.name AS pilot
			\\FROM starships s
			\\LEFT JOIN characters c ON c.id = s.pilot_id
			\\WHERE s.squadron_id = $squadron_id AND s.destroyed_at IS NULL
			\\ORDER BY s.name
			,
			{ squadron_id, },
		)

	in_hangars_of_base! : I32, Db => Try(List(ShipSummary), _)
	in_hangars_of_base! = |base_id, db|
		db.query!(
			\\SELECT id, name, registry_code, condition, hull_integrity
			\\FROM starships
			\\WHERE hangar_id IN (SELECT id FROM hangars WHERE base_id = $base_id)
			\\  AND destroyed_at IS NULL
			\\ORDER BY name
			,
			{ base_id, },
		)

	due_for_maintenance! : I32, Db => Try(List({ id : I32, name : Str, next_maintenance_due_on : Try(Str, [Null]), last_maintenance : Str }), _)
	due_for_maintenance! = |days, db|
		db.query!(
			\\SELECT
			\\    id,
			\\    name,
			\\    next_maintenance_due_on,
			\\    coalesce(last_maintenance_at::text, 'never') AS last_maintenance
			\\FROM starships
			\\WHERE destroyed_at IS NULL
			\\  AND (next_maintenance_due_on <= current_date + $days::integer
			\\       OR last_maintenance_at IS NULL
			\\       OR last_maintenance_at < now() - interval '90 days')
			\\ORDER BY next_maintenance_due_on NULLS FIRST
			,
			{ days, },
		)

	latest_maintenance! : Db => Try(List({ starship_id : I32, name : Str, performed_at : Str, summary : Str, passed_inspection : Bool }), _)
	latest_maintenance! = |db|
		db.query!(
			\\SELECT DISTINCT ON (ml.starship_id)
			\\    ml.starship_id,
			\\    s.name,
			\\    ml.performed_at,
			\\    ml.summary,
			\\    ml.passed_inspection
			\\FROM maintenance_logs ml
			\\JOIN starships s ON s.id = ml.starship_id
			\\ORDER BY ml.starship_id, ml.performed_at DESC
			,
			{},
		)

	maintenance_history! : I32, Db => Try(List({ id : I32, performed_at : Str, summary : Str, hours_spent : Try(F64, [Null]), passed_inspection : Bool, technician : Try(Str, [Null]) }), _)
	maintenance_history! = |starship_id, db|
		db.query!(
			\\SELECT ml.id, ml.performed_at, ml.summary, ml.hours_spent, ml.passed_inspection, c.name AS technician
			\\FROM maintenance_logs ml
			\\LEFT JOIN characters c ON c.id = ml.technician_id
			\\WHERE ml.starship_id = $starship_id
			\\ORDER BY ml.performed_at DESC
			\\LIMIT 20
			,
			{ starship_id, },
		)

	log_maintenance! : I32, Try(I32, [Null]), Str, F64, Bool, Db => Try({ id : I32 }, _)
	log_maintenance! = |starship_id, technician_id, summary, hours_spent, passed_inspection, db|
		db.query_one!(
			\\INSERT INTO maintenance_logs (
			\\    starship_id, technician_id, performed_at, summary, hours_spent,
			\\    passed_inspection, next_due_on, created_at, updated_at
			\\)
			\\VALUES (
			\\    $starship_id, $technician_id, now(), $summary, $hours_spent,
			\\    $passed_inspection, current_date + 90, now(), now()
			\\)
			\\RETURNING id
			,
			{ starship_id, technician_id, summary, hours_spent, passed_inspection },
		)

	record_jump! : I32, I32, Db => Try(Try({ jumps_count : I32, fuel_pct : I32 }, [NotFound]), _)
	record_jump! = |id, system_id, db|
		db.query_optional!(
			\\UPDATE starships
			\\SET last_jump_at = now(),
			\\    last_jump_system_id = $system_id,
			\\    jumps_count = jumps_count + 1,
			\\    fuel_pct = greatest(fuel_pct - 10, 0),
			\\    updated_at = now()
			\\WHERE id = $id AND hyperdrive_operational
			\\RETURNING jumps_count, fuel_pct
			,
			{ id, system_id },
		)

	set_condition! : I32, Str, I32, Db => Try(U64, _)
	set_condition! = |id, condition, hull_integrity, db|
		db.execute!(
			\\UPDATE starships
			\\SET condition = $condition::ship_condition,
			\\    hull_integrity = $hull_integrity,
			\\    destroyed_at = CASE WHEN $condition::ship_condition = 'destroyed' THEN now() ELSE destroyed_at END,
			\\    updated_at = now()
			\\WHERE id = $id
			,
			{ id, condition, hull_integrity },
		)

	loadout! : I32, Db => Try(List({ name : Str, kind : Str, damage_rating : I32, quantity : I32, range_km : Try(F64, [Null]) }), _)
	loadout! = |starship_id, db|
		db.query!(
			\\SELECT w.name, w.kind, w.damage_rating, sl.quantity, w.range_km
			\\FROM ship_loadouts sl
			\\JOIN weapons w ON w.id = sl.weapon_id
			\\WHERE sl.starship_id = $starship_id
			\\ORDER BY w.damage_rating DESC
			,
			{ starship_id, },
		)

	upsert_weapon! : Str, Str, I32, Try(F64, [Null]), Db => Try({ id : I32 }, _)
	upsert_weapon! = |name, kind, damage_rating, range_km, db|
		db.query_one!(
			\\INSERT INTO weapons (name, kind, damage_rating, range_km, created_at, updated_at)
			\\VALUES ($name, $kind, $damage_rating, $range_km, now(), now())
			\\ON CONFLICT (name) DO UPDATE
			\\SET kind = excluded.kind,
			\\    damage_rating = excluded.damage_rating,
			\\    range_km = excluded.range_km,
			\\    updated_at = now()
			\\RETURNING id
			,
			{ name, kind, damage_rating, range_km },
		)

	fit_weapon! : I32, I32, I32, Db => Try({ id : I32 }, _)
	fit_weapon! = |starship_id, weapon_id, quantity, db|
		db.query_one!(
			\\INSERT INTO ship_loadouts (starship_id, weapon_id, quantity, created_at, updated_at)
			\\VALUES ($starship_id, $weapon_id, $quantity, now(), now())
			\\RETURNING id
			,
			{ starship_id, weapon_id, quantity },
		)

	remove_weapon! : I32, I32, Db => Try(U64, _)
	remove_weapon! = |starship_id, weapon_id, db|
		db.execute!("DELETE FROM ship_loadouts WHERE starship_id = $starship_id AND weapon_id = $weapon_id", { starship_id, weapon_id })

	ships_lost! : Db => Try(List({ id : I32, name : Str, reason : Str, since : Try(Str, [Null]) }), _)
	ships_lost! = |db|
		db.query!(
			\\SELECT id, name, 'destroyed' AS reason, destroyed_at::text AS since
			\\FROM starships
			\\WHERE destroyed_at IS NOT NULL
			\\UNION ALL
			\\SELECT id, name, 'missing' AS reason, updated_at::text AS since
			\\FROM starships
			\\WHERE condition = 'missing'
			\\ORDER BY since DESC
			,
			{},
		)

	strength! : Db => Try(List({ starship_class : Str, ships : I64, kills : I64 }), _)
	strength! = |db|
		db.query!(
			\\SELECT sm.starship_class, count(*) AS ships, coalesce(sum(s.kills_count), 0) AS kills
			\\FROM starships s
			\\JOIN starship_models sm ON sm.id = s.starship_model_id
			\\WHERE s.destroyed_at IS NULL AND s.decommissioned_at IS NULL
			\\GROUP BY sm.starship_class
			\\ORDER BY ships DESC
			,
			{},
		)

	readiness_board! : Try(I32, [Null]), Try(I32, [Null]), Db => Try(List(ReadinessRow), _)
	readiness_board! = |squadron_id, base_id, db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    coalesce(s.nickname, s.name) AS display_name,
			\\    s.registry_code || ' / ' || sm.model_code AS designation_label,
			\\    sm.name AS model,
			\\    sm.starship_class,
			\\    coalesce((SELECT coalesce(mf.short_name, mf.name) FROM manufacturers mf WHERE mf.id = sm.manufacturer_id), 'unknown') AS manufacturer,
			\\    c.name AS pilot,
			\\    coalesce(c.callsign, 'unassigned') AS pilot_callsign,
			\\    h.name AS hangar,
			\\    b.code_name AS base,
			\\    s.condition,
			\\    CASE
			\\        WHEN s.condition <> 'operational' THEN 'grounded'
			\\        WHEN NOT s.hyperdrive_operational THEN 'sublight only'
			\\        WHEN s.fuel_pct < 25 THEN 'needs fuel'
			\\        WHEN s.next_maintenance_due_on < current_date THEN 'maintenance overdue'
			\\        ELSE 'ready'
			\\    END AS readiness,
			\\    (s.hull_integrity + s.shield_integrity + s.fuel_pct) / 3 AS readiness_score,
			\\    s.hull_integrity,
			\\    s.shield_integrity,
			\\    s.fuel_pct,
			\\    CASE WHEN s.hyperdrive_operational THEN 'class ' || coalesce(sm.hyperdrive_rating::text, '?') ELSE 'offline' END AS hyperdrive,
			\\    s.flight_hours,
			\\    s.jumps_count,
			\\    s.kills_count,
			\\    current_date - s.last_maintenance_at::date AS days_since_maintenance,
			\\    s.next_maintenance_due_on - current_date AS days_until_maintenance,
			\\    coalesce((SELECT count(*) FROM maintenance_logs ml WHERE ml.starship_id = s.id AND NOT ml.passed_inspection), 0) AS failed_inspections,
			\\    coalesce((SELECT sum(sl.quantity) FROM ship_loadouts sl WHERE sl.starship_id = s.id), 0) AS weapons_fitted,
			\\    coalesce((SELECT count(*) FROM droids d WHERE d.starship_id = s.id AND d.operational), 0) AS droids_aboard,
			\\    CASE WHEN s.stolen THEN 'stolen from ' || coalesce(s.stolen_from, 'unknown') ELSE 'requisitioned' END AS provenance,
			\\    CASE WHEN s.false_transponder_code IS NOT NULL THEN 'masked as ' || s.false_transponder_code ELSE 'clean' END AS transponder_status
			\\FROM starships s
			\\JOIN starship_models sm ON sm.id = s.starship_model_id
			\\LEFT JOIN characters c ON c.id = s.pilot_id
			\\LEFT JOIN hangars h ON h.id = s.hangar_id
			\\LEFT JOIN bases b ON b.id = h.base_id
			\\WHERE s.destroyed_at IS NULL
			\\  AND ($squadron_id::integer IS NULL OR s.squadron_id = $squadron_id)
			\\  AND ($base_id::integer IS NULL OR b.id = $base_id)
			\\ORDER BY readiness_score DESC, s.name
			,
			{ squadron_id, base_id },
		)

	acquisition_ledger! : Str, Db => Try(List(AcquisitionRow), _)
	acquisition_ledger! = |since, db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    s.name,
			\\    s.registry_code,
			\\    sm.name AS model,
			\\    sm.starship_class,
			\\    mf.name AS manufacturer,
			\\    mf.sells_to_rebels,
			\\    s.acquired_at,
			\\    date_part('year', s.acquired_at) AS acquired_year,
			\\    current_date - s.acquired_at::date AS days_in_service,
			\\    coalesce(s.acquired_from, 'unrecorded') AS acquired_from,
			\\    s.acquisition_cost,
			\\    sm.cost_credits AS list_price,
			\\    sm.used_cost_credits AS used_price,
			\\    CASE
			\\        WHEN s.acquisition_cost IS NULL THEN 'unknown'
			\\        WHEN s.acquisition_cost = 0 THEN 'free'
			\\        WHEN s.acquisition_cost < sm.used_cost_credits THEN 'bargain'
			\\        WHEN s.acquisition_cost <= sm.cost_credits THEN 'fair'
			\\        ELSE 'overpaid'
			\\    END AS deal,
			\\    coalesce(sm.cost_credits - s.acquisition_cost, 0) AS savings,
			\\    s.stolen,
			\\    coalesce(s.stolen_from, '') AS stolen_from,
			\\    s.transponder_code,
			\\    s.false_transponder_code,
			\\    CASE WHEN s.false_transponder_code IS NULL THEN 'clean' ELSE 'masked' END AS transponder_status,
			\\    s.condition,
			\\    s.flight_hours,
			\\    s.kills_count,
			\\    round(s.kills_count::numeric / greatest(s.flight_hours::numeric, 1), 3) AS kills_per_hour,
			\\    coalesce((SELECT sum(sl.quantity) FROM ship_loadouts sl WHERE sl.starship_id = s.id), 0) AS weapons_fitted,
			\\    coalesce((SELECT sum(ml.hours_spent) FROM maintenance_logs ml WHERE ml.starship_id = s.id), 0) AS maintenance_hours,
			\\    CASE
			\\        WHEN s.destroyed_at IS NOT NULL THEN 'destroyed ' || to_char(s.destroyed_at, 'YYYY-MM-DD')
			\\        WHEN s.decommissioned_at IS NOT NULL THEN 'decommissioned'
			\\        ELSE 'in service'
			\\    END AS status
			\\FROM starships s
			\\JOIN starship_models sm ON sm.id = s.starship_model_id
			\\JOIN manufacturers mf ON mf.id = sm.manufacturer_id
			\\WHERE s.acquired_at >= $since::timestamp
			\\ORDER BY s.acquired_at DESC
			,
			{ since, },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["manufacturers"] => Str.inspect(Fleet.manufacturers!(db))
			["upsert-manufacturer", name, short_name] => Str.inspect(Fleet.upsert_manufacturer!(name, Ok(short_name), Bool.True, db))
			["models", starship_class] => Str.inspect(Fleet.models_by_class!(starship_class, db))
			["ship", id] => Str.inspect(Fleet.starship!(Args.i32(id), db))
			["ships", .. as ids] => Str.inspect(Fleet.starships_by_ids!(List.map(ids, Args.i32), db))
			["squadron", squadron_id] => Str.inspect(Fleet.squadron_ships!(Args.i32(squadron_id), db))
			["base", base_id] => Str.inspect(Fleet.in_hangars_of_base!(Args.i32(base_id), db))
			["maintenance-due", days] => Str.inspect(Fleet.due_for_maintenance!(Args.i32(days), db))
			["latest-maintenance"] => Str.inspect(Fleet.latest_maintenance!(db))
			["maintenance", starship_id] => Str.inspect(Fleet.maintenance_history!(Args.i32(starship_id), db))
			["log-maintenance", starship_id, summary, hours] => Str.inspect(Fleet.log_maintenance!(Args.i32(starship_id), Err(Null), summary, Args.f64(hours), Bool.True, db))
			["jump", id, system_id] => Str.inspect(Fleet.record_jump!(Args.i32(id), Args.i32(system_id), db))
			["condition", id, condition, hull] => Str.inspect(Fleet.set_condition!(Args.i32(id), condition, Args.i32(hull), db))
			["loadout", starship_id] => Str.inspect(Fleet.loadout!(Args.i32(starship_id), db))
			["upsert-weapon", name, kind, damage] => Str.inspect(Fleet.upsert_weapon!(name, kind, Args.i32(damage), Err(Null), db))
			["fit", starship_id, weapon_id, quantity] => Str.inspect(Fleet.fit_weapon!(Args.i32(starship_id), Args.i32(weapon_id), Args.i32(quantity), db))
			["unfit", starship_id, weapon_id] => Str.inspect(Fleet.remove_weapon!(Args.i32(starship_id), Args.i32(weapon_id), db))
			["lost"] => Str.inspect(Fleet.ships_lost!(db))
			["strength"] => Str.inspect(Fleet.strength!(db))
			["readiness"] => Str.inspect(Fleet.readiness_board!(Err(Null), Err(Null), db))
			["readiness", "squadron", squadron_id] => Str.inspect(Fleet.readiness_board!(Ok(Args.i32(squadron_id)), Err(Null), db))
			["readiness", "base", base_id] => Str.inspect(Fleet.readiness_board!(Err(Null), Ok(Args.i32(base_id)), db))
			["acquisitions", since] => Str.inspect(Fleet.acquisition_ledger!(since, db))
			_ => "unknown fleet command"
		}
}
