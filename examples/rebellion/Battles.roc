import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Connection, Schema)

Battle : {
	id : I32,
	name : Str,
	year_aby : Try(I32, [Null]),
	started_at : Try(Str, [Null]),
	ended_at : Try(Str, [Null]),
	space_battle : Bool,
	ground_battle : Bool,
	imperial_commander : Try(Str, [Null]),
	rebel_ships : I32,
	imperial_ships : I32,
	rebel_troops : I32,
	imperial_troops : I32,
	rebel_losses : I32,
	imperial_losses : I32,
	outcome : Try(Str, [Null]),
	decisive : Bool,
	superweapon_involved : Bool,
	superweapon_name : Try(Str, [Null]),
	summary : Try(Str, [Null]),
	propaganda_value : I32,
	source_reliability : Str,
	planet : Try(Str, [Null]),
	rebel_commander : Try(Str, [Null]),
}

BattleSummary : {
	id : I32,
	name : Str,
	year_aby : Try(I32, [Null]),
	outcome : Try(Str, [Null]),
}

AfterAction : {
	id : I32,
	name : Str,
	location : Str,
	year_aby : Try(I32, [Null]),
	started_at : Try(Str, [Null]),
	ended_at : Try(Str, [Null]),
	duration_hours : Try(F64, [Null]),
	theater : Str,
	rebel_ships : I32,
	imperial_ships : I32,
	rebel_troops : I32,
	imperial_troops : I32,
	rebel_losses : I32,
	imperial_losses : I32,
	exchange_ratio : Dec,
	verdict : Str,
	outcome : Try(Str, [Null]),
	decisive : Bool,
	weapons : Str,
	rebel_commander : Try(Str, [Null]),
	imperial_commander : Str,
	mission : Try(Str, [Null]),
	rebel_participants : I64,
	total_kills : I64,
	fatalities : I64,
	wounded : I64,
	top_ace : Try(Str, [Null]),
	propaganda_value : I32,
	source_reliability : Str,
	summary : Try(Str, [Null]),
}

CampaignRow : {
	id : I32,
	name : Str,
	era : Str,
	location : Str,
	sector : Try(Str, [Null]),
	theater : Str,
	started_on : Try(Str, [Null]),
	days_ago : Try(I32, [Null]),
	rebel_strength : I32,
	imperial_strength : I32,
	odds : Str,
	rebel_losses : I32,
	imperial_losses : I32,
	rebel_loss_pct : Dec,
	imperial_loss_pct : Dec,
	result : Str,
	decisive : Bool,
	superweapon : Str,
	ships_destroyed : I64,
	aces : I64,
	casualties_recorded : I64,
	mission : Str,
	headline : Str,
	reliability : Str,
	propaganda_value : I32,
}

Battles := [].{
	battle! : I32, Db => Try(Try(Battle, [NotFound]), _)
	battle! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    b.year_aby,
			\\    b.started_at,
			\\    b.ended_at,
			\\    b.space_battle,
			\\    b.ground_battle,
			\\    b.imperial_commander,
			\\    b.rebel_ships,
			\\    b.imperial_ships,
			\\    b.rebel_troops,
			\\    b.imperial_troops,
			\\    b.rebel_losses,
			\\    b.imperial_losses,
			\\    b.outcome,
			\\    b.decisive,
			\\    b.superweapon_involved,
			\\    b.superweapon_name,
			\\    b.summary,
			\\    b.propaganda_value,
			\\    b.source_reliability,
			\\    p.name AS planet,
			\\    c.name AS rebel_commander
			\\FROM battles b
			\\LEFT JOIN planets p ON p.id = b.planet_id
			\\LEFT JOIN characters c ON c.id = b.rebel_commander_id
			\\WHERE b.id = $id
			,
			{ id, },
		)

	on_planet! : I32, Db => Try(List(BattleSummary), _)
	on_planet! = |planet_id, db|
		db.query!(
			\\SELECT id, name, year_aby, outcome
			\\FROM battles
			\\WHERE planet_id = $planet_id AND archived_at IS NULL
			\\ORDER BY started_at DESC NULLS LAST
			,
			{ planet_id, },
		)

	recent! : I32, Db => Try(List({ id : I32, name : Str, rebel_losses : I32, imperial_losses : I32, assessment : Str }), _)
	recent! = |days, db|
		db.query!(
			\\SELECT
			\\    id,
			\\    name,
			\\    rebel_losses,
			\\    imperial_losses,
			\\    CASE WHEN rebel_losses < imperial_losses THEN 'favorable' ELSE 'costly' END AS assessment
			\\FROM battles
			\\WHERE started_at > now() - interval '1 day' * $days
			\\ORDER BY started_at DESC
			,
			{ days, },
		)

	record! : Str, Try(I32, [Null]), Try(I32, [Null]), Bool, Bool, Try(I32, [Null]), Db => Try({ id : I32 }, _)
	record! = |name, planet_id, mission_id, space_battle, ground_battle, year_aby, db|
		db.query_one!(
			\\INSERT INTO battles (name, planet_id, mission_id, space_battle, ground_battle, year_aby, started_at, created_at, updated_at)
			\\VALUES ($name, $planet_id, $mission_id, $space_battle, $ground_battle, $year_aby, now(), now(), now())
			\\RETURNING id
			,
			{ name, planet_id, mission_id, space_battle, ground_battle, year_aby },
		)

	report_losses! : I32, I32, I32, Try(Str, [Null]), Bool, Db => Try(U64, _)
	report_losses! = |id, rebel_losses, imperial_losses, outcome, decisive, db|
		db.execute!(
			\\UPDATE battles
			\\SET rebel_losses = $rebel_losses,
			\\    imperial_losses = $imperial_losses,
			\\    outcome = $outcome,
			\\    decisive = $decisive,
			\\    ended_at = coalesce(ended_at, now()),
			\\    updated_at = now()
			\\WHERE id = $id
			,
			{ id, rebel_losses, imperial_losses, outcome, decisive },
		)

	add_participant! : I32, Try(I32, [Null]), Try(I32, [Null]), Str, I32, Db => Try(U64, _)
	add_participant! = |battle_id, character_id, starship_id, side, kills, db|
		db.execute!(
			\\INSERT INTO battle_participants (battle_id, character_id, starship_id, side, kills, created_at, updated_at)
			\\VALUES ($battle_id, $character_id, $starship_id, $side::allegiance, $kills, now(), now())
			,
			{ battle_id, character_id, starship_id, side, kills },
		)

	top_aces! : Db => Try(List({ battle_id : I32, battle : Str, pilot : Str, kills : I32 }), _)
	top_aces! = |db|
		db.query!(
			\\SELECT DISTINCT ON (bp.battle_id)
			\\    bp.battle_id,
			\\    b.name AS battle,
			\\    c.name AS pilot,
			\\    bp.kills
			\\FROM battle_participants bp
			\\JOIN battles b ON b.id = bp.battle_id
			\\JOIN characters c ON c.id = bp.character_id
			\\WHERE bp.kills > 0 AND bp.side = 'rebel_alliance'
			\\ORDER BY bp.battle_id, bp.kills DESC
			,
			{},
		)

	casualties! : I32, Db => Try(List({ name : Str, fatal : Bool, description : Try(Str, [Null]), status : Str }), _)
	casualties! = |battle_id, db|
		db.query!(
			\\SELECT
			\\    c.name,
			\\    ca.fatal,
			\\    ca.description,
			\\    CASE WHEN ca.fatal THEN 'killed in action' ELSE 'wounded' END AS status
			\\FROM casualties ca
			\\JOIN characters c ON c.id = ca.character_id
			\\WHERE ca.battle_id = $battle_id
			\\ORDER BY ca.fatal DESC, c.name
			,
			{ battle_id, },
		)

	record_casualty! : I32, I32, Bool, Try(Str, [Null]), Db => Try(U64, _)
	record_casualty! = |battle_id, character_id, fatal, description, db|
		db.execute!(
			\\INSERT INTO casualties (battle_id, character_id, fatal, description, created_at, updated_at)
			\\VALUES ($battle_id, $character_id, $fatal, $description, now(), now())
			,
			{ battle_id, character_id, fatal, description },
		)

	without_casualties! : Db => Try(List(BattleSummary), _)
	without_casualties! = |db|
		db.query!(
			\\SELECT b.id, b.name, b.year_aby, b.outcome
			\\FROM battles b
			\\WHERE b.ended_at IS NOT NULL
			\\  AND NOT EXISTS (SELECT 1 FROM casualties ca WHERE ca.battle_id = b.id)
			\\ORDER BY b.name
			,
			{},
		)

	archive_older_than! : I32, Db => Try(U64, _)
	archive_older_than! = |years, db|
		db.execute!(
			\\UPDATE battles
			\\SET archived_at = now(), updated_at = now()
			\\WHERE archived_at IS NULL AND ended_at < now() - interval '1 year' * $years
			,
			{ years, },
		)

	after_action! : I32, Db => Try(Try(AfterAction, [NotFound]), _)
	after_action! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    coalesce(p.name, ss.name, 'deep space') AS location,
			\\    b.year_aby,
			\\    b.started_at,
			\\    b.ended_at,
			\\    date_part('epoch', b.ended_at - b.started_at) / 3600 AS duration_hours,
			\\    CASE
			\\        WHEN b.space_battle AND b.ground_battle THEN 'combined'
			\\        WHEN b.space_battle THEN 'space'
			\\        WHEN b.ground_battle THEN 'ground'
			\\        ELSE 'skirmish'
			\\    END AS theater,
			\\    b.rebel_ships,
			\\    b.imperial_ships,
			\\    b.rebel_troops,
			\\    b.imperial_troops,
			\\    b.rebel_losses,
			\\    b.imperial_losses,
			\\    round(b.imperial_losses::numeric / greatest(b.rebel_losses, 1), 2) AS exchange_ratio,
			\\    CASE
			\\        WHEN b.imperial_losses > b.rebel_losses * 3 THEN 'rout'
			\\        WHEN b.imperial_losses > b.rebel_losses THEN 'victory'
			\\        WHEN b.imperial_losses = b.rebel_losses THEN 'stalemate'
			\\        ELSE 'defeat'
			\\    END AS verdict,
			\\    b.outcome,
			\\    b.decisive,
			\\    CASE WHEN b.superweapon_involved THEN 'superweapon: ' || coalesce(b.superweapon_name, 'unidentified') ELSE 'conventional' END AS weapons,
			\\    c.name AS rebel_commander,
			\\    coalesce(b.imperial_commander, 'unknown') AS imperial_commander,
			\\    m.code_name AS mission,
			\\    coalesce((SELECT count(*) FROM battle_participants bp WHERE bp.battle_id = b.id AND bp.side = 'rebel_alliance'), 0) AS rebel_participants,
			\\    coalesce((SELECT sum(bp.kills) FROM battle_participants bp WHERE bp.battle_id = b.id), 0) AS total_kills,
			\\    coalesce((SELECT count(*) FROM casualties ca WHERE ca.battle_id = b.id AND ca.fatal), 0) AS fatalities,
			\\    coalesce((SELECT count(*) FROM casualties ca WHERE ca.battle_id = b.id AND NOT ca.fatal), 0) AS wounded,
			\\    (SELECT ch.name FROM battle_participants bp JOIN characters ch ON ch.id = bp.character_id WHERE bp.battle_id = b.id ORDER BY bp.kills DESC LIMIT 1) AS top_ace,
			\\    b.propaganda_value,
			\\    b.source_reliability,
			\\    b.summary
			\\FROM battles b
			\\LEFT JOIN planets p ON p.id = b.planet_id
			\\LEFT JOIN star_systems ss ON ss.id = b.star_system_id
			\\LEFT JOIN characters c ON c.id = b.rebel_commander_id
			\\LEFT JOIN missions m ON m.id = b.mission_id
			\\WHERE b.id = $id
			,
			{ id, },
		)

	campaign_log! : I32, I32, Db => Try(List(CampaignRow), _)
	campaign_log! = |from_year, to_year, db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    b.name,
			\\    coalesce(b.year_aby::text || ' ABY', 'undated') AS era,
			\\    coalesce(p.name, ss.name, 'deep space') AS location,
			\\    (SELECT se.name FROM sectors se WHERE se.id = ss.sector_id) AS sector,
			\\    CASE WHEN b.space_battle AND b.ground_battle THEN 'combined' WHEN b.space_battle THEN 'space' ELSE 'ground' END AS theater,
			\\    to_char(b.started_at, 'YYYY-MM-DD') AS started_on,
			\\    current_date - b.started_at::date AS days_ago,
			\\    b.rebel_ships + b.rebel_troops AS rebel_strength,
			\\    b.imperial_ships + b.imperial_troops AS imperial_strength,
			\\    CASE
			\\        WHEN b.imperial_ships + b.imperial_troops > (b.rebel_ships + b.rebel_troops) * 5 THEN 'hopeless'
			\\        WHEN b.imperial_ships + b.imperial_troops > b.rebel_ships + b.rebel_troops THEN 'outnumbered'
			\\        ELSE 'even'
			\\    END AS odds,
			\\    b.rebel_losses,
			\\    b.imperial_losses,
			\\    round(100.0 * b.rebel_losses / greatest(b.rebel_ships + b.rebel_troops, 1), 1) AS rebel_loss_pct,
			\\    round(100.0 * b.imperial_losses / greatest(b.imperial_ships + b.imperial_troops, 1), 1) AS imperial_loss_pct,
			\\    coalesce(b.outcome, 'undetermined') AS result,
			\\    b.decisive,
			\\    CASE WHEN b.superweapon_involved THEN coalesce(b.superweapon_name, 'unidentified') ELSE 'none' END AS superweapon,
			\\    coalesce((SELECT count(*) FROM starships s WHERE s.destroyed_in_battle_id = b.id), 0) AS ships_destroyed,
			\\    coalesce((SELECT count(*) FROM battle_participants bp WHERE bp.battle_id = b.id AND bp.kills >= 5), 0) AS aces,
			\\    coalesce((SELECT count(*) FROM casualties ca WHERE ca.battle_id = b.id), 0) AS casualties_recorded,
			\\    coalesce(m.code_name, 'unplanned') AS mission,
			\\    b.name || ' (' || coalesce(p.name, ss.name, 'deep space') || '): ' || coalesce(b.outcome, 'undetermined') AS headline,
			\\    b.source_reliability::text AS reliability,
			\\    b.propaganda_value
			\\FROM battles b
			\\LEFT JOIN planets p ON p.id = b.planet_id
			\\LEFT JOIN star_systems ss ON ss.id = b.star_system_id
			\\LEFT JOIN missions m ON m.id = b.mission_id
			\\WHERE b.archived_at IS NULL
			\\  AND b.year_aby BETWEEN $from_year AND $to_year
			\\ORDER BY b.year_aby, b.started_at
			,
			{ from_year, to_year },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["battle", id] => Str.inspect(Battles.battle!(Args.i32(id), db))
			["planet", planet_id] => Str.inspect(Battles.on_planet!(Args.i32(planet_id), db))
			["recent", days] => Str.inspect(Battles.recent!(Args.i32(days), db))
			["record", name, planet_id] => Str.inspect(Battles.record!(name, Ok(Args.i32(planet_id)), Err(Null), Bool.True, Bool.False, Err(Null), db))
			["losses", id, rebel_losses, imperial_losses, outcome] => Str.inspect(Battles.report_losses!(Args.i32(id), Args.i32(rebel_losses), Args.i32(imperial_losses), Ok(outcome), Bool.False, db))
			["participant", battle_id, character_id, side, kills] => Str.inspect(Battles.add_participant!(Args.i32(battle_id), Ok(Args.i32(character_id)), Err(Null), side, Args.i32(kills), db))
			["aces"] => Str.inspect(Battles.top_aces!(db))
			["casualties", battle_id] => Str.inspect(Battles.casualties!(Args.i32(battle_id), db))
			["casualty", battle_id, character_id, fatal] => Str.inspect(Battles.record_casualty!(Args.i32(battle_id), Args.i32(character_id), fatal == "yes", Err(Null), db))
			["unscathed"] => Str.inspect(Battles.without_casualties!(db))
			["archive", years] => Str.inspect(Battles.archive_older_than!(Args.i32(years), db))
			["after-action", id] => Str.inspect(Battles.after_action!(Args.i32(id), db))
			["campaign", from_year, to_year] => Str.inspect(Battles.campaign_log!(Args.i32(from_year), Args.i32(to_year), db))
			_ => "unknown battles command"
		}
}
