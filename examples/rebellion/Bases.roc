import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Connection, Schema)

Base : {
	id : I32,
	name : Str,
	code_name : Str,
	planet_id : I32,
	commander_id : Try(I32, [Null]),
	capacity : I32,
	shield_generator : Bool,
	ion_cannon : Bool,
	established_at : Try(Str, [Null]),
	evacuated_at : Try(Str, [Null]),
	compromised : Bool,
	coordinates : Try(Str, [Null]),
}

BaseSummary : {
	id : I32,
	name : Str,
	code_name : Str,
	planet : Str,
	commander : Str,
	compromised : Bool,
}

Hangar : {
	id : I32,
	name : Str,
	bay_count : I32,
	access : Str,
	blast_doors : Bool,
	notes : Try(Str, [Null]),
}

BaseDetail : {
	id : I32,
	name : Str,
	code_name : Str,
	location : Str,
	coordinates : Str,
	commander : Str,
	capacity : I32,
	personnel : I64,
	on_leave : I64,
	hangars : I64,
	bays : I64,
	ships : I64,
	droids : I64,
	squadrons : I64,
	open_requests : I64,
	inbound_shipments : I64,
	last_transmission_at : Try(Str, [Null]),
	active_missions : I64,
	defenses : Str,
	established_on : Str,
	days_operational : I32,
	compromised : Bool,
}

SupplyStatus : {
	id : I32,
	name : Str,
	code_name : Str,
	planet : Str,
	requests : I64,
	drafts : I64,
	submitted : I64,
	approved : I64,
	on_the_way : I64,
	delivered_recently : I64,
	rejected : I64,
	committed_cost : Dec,
	top_priority : I32,
	oldest_submitted_at : Try(Str, [Null]),
	longest_wait_days : I32,
	next_needed_by : Try(Str, [Null]),
	overdue : I64,
	intercepted_shipments : I64,
	supply_state : Str,
}

Bases := [].{
	active! : Db => Try(List(BaseSummary), _)
	active! = |db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    b.code_name,
			\\    p.name AS planet,
			\\    coalesce(c.name, 'vacant') AS commander,
			\\    b.compromised
			\\FROM bases b
			\\JOIN planets p ON p.id = b.planet_id
			\\LEFT JOIN characters c ON c.id = b.commander_id
			\\WHERE b.evacuated_at IS NULL
			\\ORDER BY b.name
			,
			{},
		)

	by_code_name! : Str, Db => Try(Try(Base, [NotFound]), _)
	by_code_name! = |code_name, db|
		db.query_optional!(
			\\SELECT
			\\    id,
			\\    name,
			\\    code_name,
			\\    planet_id,
			\\    commander_id,
			\\    capacity,
			\\    shield_generator,
			\\    ion_cannon,
			\\    established_at,
			\\    evacuated_at,
			\\    compromised,
			\\    coordinates
			\\FROM bases
			\\WHERE code_name = $code_name
			,
			{ code_name, },
		)

	search! : Str, Db => Try(List({ id : I32, name : Str, code_name : Str }), _)
	search! = |text, db|
		db.query!(
			\\SELECT id, name, code_name
			\\FROM bases
			\\WHERE name ILIKE '%' || $text || '%' OR code_name ILIKE '%' || $text || '%'
			\\ORDER BY name
			,
			{ text, },
		)

	hangars! : I32, Db => Try(List(Hangar), _)
	hangars! = |base_id, db|
		db.query!(
			\\SELECT id, name, bay_count, access, blast_doors, notes
			\\FROM hangars
			\\WHERE base_id = $base_id
			\\ORDER BY name
			,
			{ base_id, },
		)

	capacity_report! : Db => Try(List({ id : I32, name : Str, capacity : I32, stationed : I64 }), _)
	capacity_report! = |db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    b.capacity,
			\\    coalesce((SELECT count(*) FROM characters c WHERE c.base_id = b.id AND c.active), 0) AS stationed
			\\FROM bases b
			\\WHERE b.evacuated_at IS NULL
			\\ORDER BY b.name
			,
			{},
		)

	occupants! : I32, Db => Try(List({ kind : Str, name : Str }), _)
	occupants! = |base_id, db|
		db.query!(
			\\SELECT 'character' AS kind, name
			\\FROM characters
			\\WHERE base_id = $base_id AND active
			\\UNION ALL
			\\SELECT 'droid' AS kind, designation AS name
			\\FROM droids
			\\WHERE base_id = $base_id AND operational
			\\ORDER BY kind, name
			,
			{ base_id, },
		)

	compromised_recently! : I32, Db => Try(List({ id : I32, name : Str, updated_at : Str }), _)
	compromised_recently! = |days, db|
		db.query!(
			\\SELECT id, name, updated_at
			\\FROM bases
			\\WHERE compromised AND updated_at > now() - interval '1 day' * $days
			\\ORDER BY updated_at DESC
			,
			{ days, },
		)

	establish! : Str, Str, I32, I32, Db => Try({ id : I32 }, _)
	establish! = |name, code_name, planet_id, capacity, db|
		db.query_one!(
			\\INSERT INTO bases (name, code_name, planet_id, capacity, established_at, created_at, updated_at)
			\\VALUES ($name, $code_name, $planet_id, $capacity, now(), now(), now())
			\\RETURNING id
			,
			{ name, code_name, planet_id, capacity },
		)

	add_hangar! : I32, Str, I32, Db => Try({ id : I32, bay_count : I32 }, _)
	add_hangar! = |base_id, name, bay_count, db|
		db.query_one!(
			\\INSERT INTO hangars (base_id, name, bay_count, created_at, updated_at)
			\\VALUES ($base_id, $name, $bay_count, now(), now())
			\\ON CONFLICT (base_id, name)
			\\DO UPDATE SET bay_count = excluded.bay_count, updated_at = now()
			\\RETURNING id, bay_count
			,
			{ base_id, name, bay_count },
		)

	set_hangar_access! : I32, Str, Db => Try(U64, _)
	set_hangar_access! = |id, access, db|
		db.execute!("UPDATE hangars SET access = $access, updated_at = now() WHERE id = $id", { id, access })

	evacuate! : I32, Db => Try(U64, _)
	evacuate! = |id, db|
		db.execute!(
			\\UPDATE bases
			\\SET evacuated_at = now(), compromised = true, updated_at = now()
			\\WHERE id = $id AND evacuated_at IS NULL
			,
			{ id, },
		)

	base_detail! : I32, Db => Try(Try(BaseDetail, [NotFound]), _)
	base_detail! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    b.code_name,
			\\    p.name || ', ' || ss.name || ' system' AS location,
			\\    coalesce(b.coordinates, 'classified') AS coordinates,
			\\    coalesce(r.abbreviation || ' ' || c.name, c.name, 'vacant') AS commander,
			\\    b.capacity,
			\\    coalesce((SELECT count(*) FROM characters ch WHERE ch.base_id = b.id AND ch.active), 0) AS personnel,
			\\    coalesce((SELECT count(*) FROM characters ch WHERE ch.base_id = b.id AND ch.on_leave), 0) AS on_leave,
			\\    coalesce((SELECT count(*) FROM hangars h WHERE h.base_id = b.id), 0) AS hangars,
			\\    coalesce((SELECT sum(h.bay_count) FROM hangars h WHERE h.base_id = b.id), 0) AS bays,
			\\    coalesce((SELECT count(*) FROM starships st JOIN hangars h ON h.id = st.hangar_id WHERE h.base_id = b.id AND st.destroyed_at IS NULL), 0) AS ships,
			\\    coalesce((SELECT count(*) FROM droids d WHERE d.base_id = b.id AND d.operational), 0) AS droids,
			\\    coalesce((SELECT count(*) FROM squadrons sq WHERE sq.base_id = b.id AND sq.active), 0) AS squadrons,
			\\    coalesce((SELECT count(*) FROM supply_requests sr WHERE sr.base_id = b.id AND sr.status IN ('submitted', 'approved', 'packed', 'in_transit')), 0) AS open_requests,
			\\    coalesce((SELECT count(*) FROM shipments sh WHERE sh.destination_base_id = b.id AND sh.arrived_at IS NULL AND NOT sh.intercepted), 0) AS inbound_shipments,
			\\    (SELECT max(t.sent_at) FROM transmissions t WHERE t.base_id = b.id) AS last_transmission_at,
			\\    coalesce((SELECT count(*) FROM missions m WHERE m.staging_base_id = b.id AND m.status = 'active'), 0) AS active_missions,
			\\    CASE
			\\        WHEN b.shield_generator AND b.ion_cannon THEN 'fortified'
			\\        WHEN b.shield_generator OR b.ion_cannon THEN 'defended'
			\\        ELSE 'exposed'
			\\    END AS defenses,
			\\    coalesce(to_char(b.established_at, 'YYYY-MM-DD'), 'unknown') AS established_on,
			\\    coalesce(current_date - b.established_at::date, 0) AS days_operational,
			\\    b.compromised
			\\FROM bases b
			\\JOIN planets p ON p.id = b.planet_id
			\\JOIN star_systems ss ON ss.id = p.star_system_id
			\\LEFT JOIN characters c ON c.id = b.commander_id
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\WHERE b.id = $id
			,
			{ id, },
		)

	supply_status! : Db => Try(List(SupplyStatus), _)
	supply_status! = |db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    b.code_name,
			\\    p.name AS planet,
			\\    count(sr.id) AS requests,
			\\    count(sr.id) FILTER (WHERE sr.status = 'draft') AS drafts,
			\\    count(sr.id) FILTER (WHERE sr.status = 'submitted') AS submitted,
			\\    count(sr.id) FILTER (WHERE sr.status = 'approved') AS approved,
			\\    count(sr.id) FILTER (WHERE sr.status IN ('packed', 'in_transit')) AS on_the_way,
			\\    count(sr.id) FILTER (WHERE sr.status = 'delivered' AND sr.delivered_at > now() - interval '30 days') AS delivered_recently,
			\\    count(sr.id) FILTER (WHERE sr.status = 'rejected') AS rejected,
			\\    coalesce(sum(sr.total_cost) FILTER (WHERE sr.status NOT IN ('rejected', 'cancelled')), 0) AS committed_cost,
			\\    coalesce(max(sr.priority) FILTER (WHERE sr.status IN ('submitted', 'approved')), 0) AS top_priority,
			\\    min(sr.submitted_at) FILTER (WHERE sr.status = 'submitted') AS oldest_submitted_at,
			\\    coalesce(max(current_date - sr.submitted_at::date) FILTER (WHERE sr.status = 'submitted'), 0) AS longest_wait_days,
			\\    min(sr.needed_by) FILTER (WHERE sr.status NOT IN ('delivered', 'rejected', 'cancelled')) AS next_needed_by,
			\\    count(sr.id) FILTER (WHERE sr.needed_by < current_date AND sr.status NOT IN ('delivered', 'rejected', 'cancelled')) AS overdue,
			\\    coalesce((SELECT count(*) FROM shipments sh WHERE sh.destination_base_id = b.id AND sh.intercepted), 0) AS intercepted_shipments,
			\\    CASE
			\\        WHEN count(sr.id) FILTER (WHERE sr.needed_by < current_date AND sr.status NOT IN ('delivered', 'rejected', 'cancelled')) > 0 THEN 'behind'
			\\        WHEN count(sr.id) FILTER (WHERE sr.status IN ('submitted', 'approved')) > 5 THEN 'backlogged'
			\\        ELSE 'ok'
			\\    END AS supply_state
			\\FROM bases b
			\\JOIN planets p ON p.id = b.planet_id
			\\LEFT JOIN supply_requests sr ON sr.base_id = b.id AND sr.archived_at IS NULL
			\\WHERE b.evacuated_at IS NULL
			\\GROUP BY b.id, p.name
			\\ORDER BY b.name
			,
			{},
		)


	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["active"] => Str.inspect(Bases.active!(db))
			["show", code_name] => Str.inspect(Bases.by_code_name!(code_name, db))
			["search", text] => Str.inspect(Bases.search!(text, db))
			["hangars", base_id] => Str.inspect(Bases.hangars!(Args.i32(base_id), db))
			["capacity"] => Str.inspect(Bases.capacity_report!(db))
			["occupants", base_id] => Str.inspect(Bases.occupants!(Args.i32(base_id), db))
			["compromised", days] => Str.inspect(Bases.compromised_recently!(Args.i32(days), db))
			["establish", name, code_name, planet_id, capacity] => Str.inspect(Bases.establish!(name, code_name, Args.i32(planet_id), Args.i32(capacity), db))
			["add-hangar", base_id, name, bay_count] => Str.inspect(Bases.add_hangar!(Args.i32(base_id), name, Args.i32(bay_count), db))
			["hangar-access", id, access] => Str.inspect(Bases.set_hangar_access!(Args.i32(id), access, db))
			["evacuate", id] => Str.inspect(Bases.evacuate!(Args.i32(id), db))
			["detail", id] => Str.inspect(Bases.base_detail!(Args.i32(id), db))
			["supply-status"] => Str.inspect(Bases.supply_status!(db))
			_ => "unknown bases command"
		}
}
