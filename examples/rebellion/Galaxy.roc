import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Region : {
	id : I32,
	name : Str,
	slug_code : Str,
	distance_from_core : Try(F64, [Null]),
	sort_order : I32,
}

StarSystem : {
	id : I32,
	name : Str,
	star_name : Try(Str, [Null]),
	star_type : Try(Str, [Null]),
	grid_x : F64,
	grid_y : F64,
	planet_count : I32,
	has_asteroid_field : Bool,
	sector_name : Str,
	region_name : Str,
}

Planet : {
	id : I32,
	star_system_id : I32,
	name : Str,
	climate : Try(Str, [Null]),
	terrain : Try(Str, [Null]),
	diameter_km : Try(F64, [Null]),
	gravity_standard : Try(F64, [Null]),
	rotation_period_hours : Try(F64, [Null]),
	orbital_period_days : Try(F64, [Null]),
	surface_water_pct : Try(F64, [Null]),
	population : Try(I64, [Null]),
	capital_city : Try(Str, [Null]),
	allegiance : Str,
	imperial_garrison : Bool,
	rebel_cell : Bool,
	breathable_atmosphere : Bool,
	hyperspace_beacon_code : Try(Str, [Null]),
	spaceport_count : I32,
	threat_level : I32,
	last_patrol_at : Try(Str, [Null]),
	liberated_at : Try(Str, [Null]),
	occupied_at : Try(Str, [Null]),
	description : Try(Str, [Null]),
	holonet_entry_url : Try(Str, [Null]),
	first_contact_on : Try(Str, [Null]),
}

PlanetSummary : {
	id : I32,
	name : Str,
	climate : Try(Str, [Null]),
	allegiance : Str,
	threat_level : I32,
}

Lane : {
	id : I32,
	name : Str,
	destination : Str,
	length_parsecs : F64,
	patrolled : Bool,
}

PlanetReport : {
	id : I32,
	name : Str,
	location : Str,
	star_name : Try(Str, [Null]),
	climate : Try(Str, [Null]),
	terrain : Try(Str, [Null]),
	population : I64,
	allegiance : Str,
	threat : Str,
	imperial_garrison : Bool,
	rebel_cell : Bool,
	days_since_patrol : I32,
	liberated_on : Str,
	moons : I64,
	active_bases : I64,
	natives_in_service : I64,
	active_missions : I64,
	battles : I64,
	rebel_losses : I64,
	last_intel_at : Try(Str, [Null]),
	open_intel : I64,
	recent_sightings : I64,
	landing_sites : I64,
}

SectorOverview : {
	id : I32,
	name : Str,
	grid_code : Str,
	region : Str,
	imperial_presence : Bool,
	systems : I64,
	planets : I64,
	rebel_planets : I64,
	imperial_planets : I64,
	rebel_cells : I64,
	garrisons : I64,
	population : Dec,
	average_threat : Dec,
	max_threat : I32,
	oldest_patrol_at : Try(Str, [Null]),
	spaceports : I64,
	unpatrolled : I64,
	open_lanes : I64,
	blockaded_lanes : I64,
	control : Str,
}

Galaxy := [].{
	regions! : Db => Try(List(Region), _)
	regions! = |db|
		db.query!(
			\\SELECT id, name, slug_code, distance_from_core, sort_order
			\\FROM regions
			\\ORDER BY sort_order, name
			,
			{},
		)

	sectors_in_region! : I32, Db => Try(List({ id : I32, name : Str, grid_code : Str, imperial_presence : Bool }), _)
	sectors_in_region! = |region_id, db|
		db.query!(
			\\SELECT id, name, grid_code, imperial_presence
			\\FROM sectors
			\\WHERE region_id = $region_id
			\\ORDER BY name
			,
			{ region_id, },
		)

	system_by_name! : Str, Db => Try(Try(StarSystem, [NotFound]), _)
	system_by_name! = |name, db|
		db.query_optional!(
			\\SELECT
			\\    ss.id,
			\\    ss.name,
			\\    ss.star_name,
			\\    ss.star_type,
			\\    ss.grid_x,
			\\    ss.grid_y,
			\\    ss.planet_count,
			\\    ss.has_asteroid_field,
			\\    s.name AS sector_name,
			\\    r.name AS region_name
			\\FROM star_systems ss
			\\JOIN sectors s ON s.id = ss.sector_id
			\\JOIN regions r ON r.id = s.region_id
			\\WHERE ss.name = $name
			,
			{ name, },
		)

	planet_by_name! : Str, Db => Try(Try(Planet, [NotFound]), _)
	planet_by_name! = |name, db|
		db.query_optional!(
			\\SELECT
			\\    id,
			\\    star_system_id,
			\\    name,
			\\    climate,
			\\    terrain,
			\\    diameter_km,
			\\    gravity_standard,
			\\    rotation_period_hours,
			\\    orbital_period_days,
			\\    surface_water_pct,
			\\    population,
			\\    capital_city,
			\\    allegiance,
			\\    imperial_garrison,
			\\    rebel_cell,
			\\    breathable_atmosphere,
			\\    hyperspace_beacon_code,
			\\    spaceport_count,
			\\    threat_level,
			\\    last_patrol_at,
			\\    liberated_at,
			\\    occupied_at,
			\\    description,
			\\    holonet_entry_url,
			\\    first_contact_on
			\\FROM planets
			\\WHERE name = $name AND archived_at IS NULL
			,
			{ name, },
		)

	search_planets! : Str, Try(Str, [Null]), Db => Try(List(PlanetSummary), _)
	search_planets! = |text, allegiance, db|
		db.query!(
			\\SELECT id, name, climate, allegiance, threat_level
			\\FROM planets
			\\WHERE archived_at IS NULL
			\\  AND (name ILIKE '%' || $text || '%' OR terrain ILIKE '%' || $text || '%')
			\\  AND ($allegiance::text IS NULL OR allegiance::text = $allegiance)
			\\ORDER BY name
			\\LIMIT 50
			,
			{ text, allegiance },
		)

	planets_in_system! : I32, Db => Try(List(PlanetSummary), _)
	planets_in_system! = |star_system_id, db|
		db.query!(
			\\SELECT id, name, climate, allegiance, threat_level
			\\FROM planets
			\\WHERE star_system_id = $star_system_id AND archived_at IS NULL
			\\ORDER BY name
			,
			{ star_system_id, },
		)

	neighbors! : I32, Db => Try(List(PlanetSummary), _)
	neighbors! = |planet_id, db|
		db.query!(
			\\SELECT p.id, p.name, p.climate, p.allegiance, p.threat_level
			\\FROM planet_neighbors pn
			\\JOIN planets p ON p.id = pn.neighbor_id
			\\WHERE pn.planet_id = $planet_id
			\\ORDER BY p.name
			,
			{ planet_id, },
		)

	moons! : I32, Db => Try(List({ id : I32, name : Str }), _)
	moons! = |planet_id, db|
		db.query!("SELECT id, name FROM moons WHERE planet_id = $planet_id ORDER BY name", { planet_id, })

	occupied! : Db => Try(List(PlanetSummary), _)
	occupied! = |db|
		db.query!(
			\\SELECT id, name, climate, allegiance, threat_level
			\\FROM planets
			\\WHERE allegiance = 'galactic_empire'
			\\  AND imperial_garrison
			\\  AND archived_at IS NULL
			\\ORDER BY threat_level DESC, name
			,
			{},
		)

	stale_patrols! : I32, Db => Try(List({ id : I32, name : Str, last_patrol_at : Try(Str, [Null]) }), _)
	stale_patrols! = |days, db|
		db.query!(
			\\SELECT id, name, last_patrol_at
			\\FROM planets
			\\WHERE rebel_cell
			\\  AND (last_patrol_at IS NULL OR last_patrol_at < now() - interval '1 day' * $days)
			\\ORDER BY last_patrol_at NULLS FIRST
			,
			{ days, },
		)

	open_lanes_from! : I32, Db => Try(List(Lane), _)
	open_lanes_from! = |system_id, db|
		db.query!(
			\\SELECT l.id, l.name, ss.name AS destination, l.length_parsecs, l.patrolled
			\\FROM hyperspace_lanes l
			\\JOIN star_systems ss ON ss.id = l.destination_system_id
			\\WHERE l.origin_system_id = $system_id AND l.status = 'open'
			\\ORDER BY l.length_parsecs
			,
			{ system_id, },
		)

	lane_route! : I32, Db => Try(List({ position : I32, system : Str, jump_hours : F64 }), _)
	lane_route! = |lane_id, db|
		db.query!(
			\\SELECT seg.position, ss.name AS system, seg.jump_hours
			\\FROM lane_segments seg
			\\JOIN star_systems ss ON ss.id = seg.star_system_id
			\\WHERE seg.hyperspace_lane_id = $lane_id
			\\ORDER BY seg.position
			,
			{ lane_id, },
		)

	add_planet! : I32, Str, Try(Str, [Null]), Try(Str, [Null]), Db => Try({ id : I32 }, _)
	add_planet! = |star_system_id, name, climate, terrain, db|
		db.query_one!(
			\\INSERT INTO planets (star_system_id, name, climate, terrain, created_at, updated_at)
			\\VALUES ($star_system_id, $name, $climate, $terrain, now(), now())
			\\RETURNING id
			,
			{ star_system_id, name, climate, terrain },
		)

	link_neighbors! : I32, I32, Db => Try(U64, _)
	link_neighbors! = |planet_id, neighbor_id, db|
		db.execute!(
			\\INSERT INTO planet_neighbors (planet_id, neighbor_id)
			\\VALUES ($planet_id, $neighbor_id)
			\\ON CONFLICT (planet_id, neighbor_id) DO NOTHING
			,
			{ planet_id, neighbor_id },
		)

	set_allegiance! : I32, Str, Db => Try(U64, _)
	set_allegiance! = |id, allegiance, db|
		db.execute!(
			\\UPDATE planets
			\\SET allegiance = $allegiance::allegiance,
			\\    liberated_at = CASE WHEN $allegiance::allegiance = 'rebel_alliance' THEN now() ELSE liberated_at END,
			\\    occupied_at = CASE WHEN $allegiance::allegiance = 'galactic_empire' THEN now() ELSE occupied_at END,
			\\    updated_at = now()
			\\WHERE id = $id
			,
			{ id, allegiance },
		)

	record_patrol! : I32, I32, Db => Try(U64, _)
	record_patrol! = |id, threat_level, db|
		db.execute!(
			\\UPDATE planets
			\\SET last_patrol_at = now(), threat_level = $threat_level, updated_at = now()
			\\WHERE id = $id
			,
			{ id, threat_level },
		)

	set_lane_status! : I32, Str, Db => Try(U64, _)
	set_lane_status! = |id, status, db|
		db.execute!("UPDATE hyperspace_lanes SET status = $status, updated_at = now() WHERE id = $id", { id, status })

	archive_planet! : I32, Db => Try(U64, _)
	archive_planet! = |id, db|
		db.execute!("UPDATE planets SET archived_at = now(), updated_at = now() WHERE id = $id AND archived_at IS NULL", { id, })

	planet_report! : I32, Db => Try(Try(PlanetReport, [NotFound]), _)
	planet_report! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    p.id,
			\\    p.name,
			\\    r.name || ' / ' || s.name || ' / ' || ss.name AS location,
			\\    ss.star_name,
			\\    p.climate,
			\\    p.terrain,
			\\    coalesce(p.population, 0) AS population,
			\\    p.allegiance::text AS allegiance,
			\\    CASE
			\\        WHEN p.threat_level >= 8 THEN 'extreme'
			\\        WHEN p.threat_level >= 5 THEN 'high'
			\\        WHEN p.threat_level >= 2 THEN 'moderate'
			\\        ELSE 'low'
			\\    END AS threat,
			\\    p.imperial_garrison,
			\\    p.rebel_cell,
			\\    coalesce(current_date - p.last_patrol_at::date, -1) AS days_since_patrol,
			\\    coalesce(to_char(p.liberated_at, 'YYYY-MM-DD'), 'never') AS liberated_on,
			\\    coalesce((SELECT count(*) FROM moons m WHERE m.planet_id = p.id), 0) AS moons,
			\\    coalesce((SELECT count(*) FROM bases b WHERE b.planet_id = p.id AND b.evacuated_at IS NULL), 0) AS active_bases,
			\\    coalesce((SELECT count(*) FROM characters c WHERE c.homeworld_id = p.id AND c.active), 0) AS natives_in_service,
			\\    coalesce((SELECT count(*) FROM missions mi WHERE mi.target_planet_id = p.id AND mi.status = 'active'), 0) AS active_missions,
			\\    coalesce((SELECT count(*) FROM battles bt WHERE bt.planet_id = p.id), 0) AS battles,
			\\    coalesce((SELECT sum(bt.rebel_losses) FROM battles bt WHERE bt.planet_id = p.id), 0) AS rebel_losses,
			\\    (SELECT max(ir.received_at) FROM intel_reports ir WHERE ir.planet_id = p.id) AS last_intel_at,
			\\    coalesce((SELECT count(*) FROM intel_reports ir WHERE ir.planet_id = p.id AND ir.actionable AND NOT ir.acted_on), 0) AS open_intel,
			\\    coalesce((SELECT count(*) FROM sightings si WHERE si.planet_id = p.id AND si.seen_at > now() - interval '30 days'), 0) AS recent_sightings,
			\\    p.spaceport_count + coalesce((SELECT count(*) FROM bases b WHERE b.planet_id = p.id), 0) AS landing_sites
			\\FROM planets p
			\\JOIN star_systems ss ON ss.id = p.star_system_id
			\\JOIN sectors s ON s.id = ss.sector_id
			\\JOIN regions r ON r.id = s.region_id
			\\WHERE p.id = $id
			,
			{ id, },
		)

	sector_overview! : I32, Db => Try(List(SectorOverview), _)
	sector_overview! = |region_id, db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    s.name,
			\\    s.grid_code,
			\\    r.name AS region,
			\\    s.imperial_presence,
			\\    count(DISTINCT ss.id) AS systems,
			\\    count(p.id) AS planets,
			\\    count(p.id) FILTER (WHERE p.allegiance = 'rebel_alliance') AS rebel_planets,
			\\    count(p.id) FILTER (WHERE p.allegiance = 'galactic_empire') AS imperial_planets,
			\\    count(p.id) FILTER (WHERE p.rebel_cell) AS rebel_cells,
			\\    count(p.id) FILTER (WHERE p.imperial_garrison) AS garrisons,
			\\    coalesce(sum(p.population), 0) AS population,
			\\    coalesce(round(avg(p.threat_level), 1), 0) AS average_threat,
			\\    coalesce(max(p.threat_level), 0) AS max_threat,
			\\    min(p.last_patrol_at) AS oldest_patrol_at,
			\\    coalesce(sum(p.spaceport_count), 0) AS spaceports,
			\\    count(p.id) FILTER (WHERE p.last_patrol_at IS NULL OR p.last_patrol_at < now() - interval '90 days') AS unpatrolled,
			\\    coalesce((SELECT count(*) FROM hyperspace_lanes hl JOIN star_systems o ON o.id = hl.origin_system_id WHERE o.sector_id = s.id AND hl.status = 'open'), 0) AS open_lanes,
			\\    coalesce((SELECT count(*) FROM hyperspace_lanes hl JOIN star_systems o ON o.id = hl.origin_system_id WHERE o.sector_id = s.id AND hl.status = 'blockaded'), 0) AS blockaded_lanes,
			\\    CASE
			\\        WHEN count(p.id) FILTER (WHERE p.allegiance = 'galactic_empire') > count(p.id) / 2 THEN 'imperial'
			\\        WHEN count(p.id) FILTER (WHERE p.allegiance = 'rebel_alliance') > count(p.id) / 2 THEN 'rebel'
			\\        ELSE 'contested'
			\\    END AS control
			\\FROM sectors s
			\\JOIN regions r ON r.id = s.region_id
			\\LEFT JOIN star_systems ss ON ss.sector_id = s.id
			\\LEFT JOIN planets p ON p.star_system_id = ss.id AND p.archived_at IS NULL
			\\WHERE s.region_id = $region_id
			\\GROUP BY s.id, r.name
			\\ORDER BY s.name
			,
			{ region_id, },
		)


	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["regions"] => Str.inspect(Galaxy.regions!(db))
			["sectors", region_id] => Str.inspect(Galaxy.sectors_in_region!(Args.i32(region_id), db))
			["system", name] => Str.inspect(Galaxy.system_by_name!(name, db))
			["planet", name] => Str.inspect(Galaxy.planet_by_name!(name, db))
			["search", text] => Str.inspect(Galaxy.search_planets!(text, Err(Null), db))
			["search", text, allegiance] => Str.inspect(Galaxy.search_planets!(text, Ok(allegiance), db))
			["planets", system_id] => Str.inspect(Galaxy.planets_in_system!(Args.i32(system_id), db))
			["neighbors", planet_id] => Str.inspect(Galaxy.neighbors!(Args.i32(planet_id), db))
			["moons", planet_id] => Str.inspect(Galaxy.moons!(Args.i32(planet_id), db))
			["occupied"] => Str.inspect(Galaxy.occupied!(db))
			["stale-patrols", days] => Str.inspect(Galaxy.stale_patrols!(Args.i32(days), db))
			["lanes", system_id] => Str.inspect(Galaxy.open_lanes_from!(Args.i32(system_id), db))
			["route", lane_id] => Str.inspect(Galaxy.lane_route!(Args.i32(lane_id), db))
			["add-planet", system_id, name] => Str.inspect(Galaxy.add_planet!(Args.i32(system_id), name, Err(Null), Err(Null), db))
			["link", planet_id, neighbor_id] => Str.inspect(Galaxy.link_neighbors!(Args.i32(planet_id), Args.i32(neighbor_id), db))
			["allegiance", id, allegiance] => Str.inspect(Galaxy.set_allegiance!(Args.i32(id), allegiance, db))
			["patrol", id, threat_level] => Str.inspect(Galaxy.record_patrol!(Args.i32(id), Args.i32(threat_level), db))
			["lane-status", id, status] => Str.inspect(Galaxy.set_lane_status!(Args.i32(id), status, db))
			["archive", id] => Str.inspect(Galaxy.archive_planet!(Args.i32(id), db))
			["planet-report", id] => Str.inspect(Galaxy.planet_report!(Args.i32(id), db))
			["sector-overview", region_id] => Str.inspect(Galaxy.sector_overview!(Args.i32(region_id), db))
			_ => "unknown galaxy command"
		}
}
