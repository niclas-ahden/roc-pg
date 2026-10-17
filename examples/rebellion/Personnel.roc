import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Dossier : {
	id : I32,
	name : Str,
	alias : Try(Str, [Null]),
	callsign : Try(Str, [Null]),
	species_id : Try(I32, [Null]),
	homeworld_id : Try(I32, [Null]),
	rank_id : Try(I32, [Null]),
	base_id : Try(I32, [Null]),
	allegiance : Str,
	force_sensitive : Bool,
	force_side : Try(Str, [Null]),
	midichlorian_count : Try(I64, [Null]),
	birth_year_bby : Try(I32, [Null]),
	death_year_aby : Try(I32, [Null]),
	height_cm : Try(F64, [Null]),
	mass_kg : Try(F64, [Null]),
	eye_color : Try(Str, [Null]),
	hair_color : Try(Str, [Null]),
	skin_color : Try(Str, [Null]),
	gender : Try(Str, [Null]),
	cybernetic_parts : I32,
	clearance_level : I32,
	comlink_frequency : Try(Str, [Null]),
	holonet_handle : Try(Str, [Null]),
	service_number : Try(Str, [Null]),
	enlisted_at : Try(Str, [Null]),
	captured_at : Try(Str, [Null]),
	last_seen_at : Try(Str, [Null]),
	medical_clearance_at : Try(Str, [Null]),
	flight_certified : Bool,
	flight_hours : F64,
	confirmed_kills : I32,
	missions_flown : I32,
	commendations : I32,
	reprimands : I32,
	piloting_score : Try(I32, [Null]),
	marksmanship_score : Try(I32, [Null]),
	tactics_score : Try(I32, [Null]),
	diplomacy_score : Try(I32, [Null]),
	engineering_score : Try(I32, [Null]),
	languages_spoken : I32,
	preferred_weapon : Try(Str, [Null]),
	signature_ship : Try(Str, [Null]),
	bounty_on_head : Try(Dec, [Null]),
	wanted_by_empire : Bool,
	wanted_by_hutts : Bool,
	quarters : Try(Str, [Null]),
	squadron_role : Try(Str, [Null]),
	next_of_kin : Try(Str, [Null]),
	biography : Try(Str, [Null]),
	psych_profile : Try(Str, [Null]),
	rescue_priority : I32,
	cover_identity : Try(Str, [Null]),
	credits_balance : I64,
	monthly_stipend : I64,
	on_leave : Bool,
	active : Bool,
	lock_version : I32,
	species_name : Try(Str, [Null]),
	homeworld_name : Try(Str, [Null]),
	rank_title : Try(Str, [Null]),
}

DossierChanges : {
	alias : Try(Str, [Null]),
	callsign : Try(Str, [Null]),
	species_id : Try(I32, [Null]),
	homeworld_id : Try(I32, [Null]),
	rank_id : Try(I32, [Null]),
	allegiance : Str,
	force_sensitive : Bool,
	force_side : Try(Str, [Null]),
	eye_color : Try(Str, [Null]),
	hair_color : Try(Str, [Null]),
	skin_color : Try(Str, [Null]),
	gender : Try(Str, [Null]),
	height_cm : Try(F64, [Null]),
	mass_kg : Try(F64, [Null]),
	clearance_level : I32,
	comlink_frequency : Try(Str, [Null]),
	holonet_handle : Try(Str, [Null]),
	preferred_weapon : Try(Str, [Null]),
	signature_ship : Try(Str, [Null]),
	quarters : Try(Str, [Null]),
	base_id : Try(I32, [Null]),
	squadron_role : Try(Str, [Null]),
	next_of_kin : Try(Str, [Null]),
	biography : Try(Str, [Null]),
}

CharacterSummary : {
	id : I32,
	name : Str,
	alias : Try(Str, [Null]),
	callsign : Try(Str, [Null]),
	allegiance : Str,
}

ServiceRecord : {
	id : I32,
	display_name : Str,
	callsign : Str,
	service_number : Str,
	base : Str,
	squadron : Str,
	enlisted_by : Str,
	enlisted_on : Str,
	days_of_service : I32,
	missions : I64,
	missions_completed : I64,
	times_wounded : I64,
	battles : I64,
	battle_kills : I64,
	confirmed_kills : I32,
	commendations : I32,
	reprimands : I32,
	flight_hours : F64,
	highest_bounty : Dec,
	next_of_kin : Str,
	leave_days_left : I32,
	status : Str,
}

Personnel := [].{
	dossier! : I32, Db => Try(Try(Dossier, [NotFound]), _)
	dossier! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    c.id,
			\\    c.name,
			\\    c.alias,
			\\    c.callsign,
			\\    c.species_id,
			\\    c.homeworld_id,
			\\    c.rank_id,
			\\    c.base_id,
			\\    c.allegiance,
			\\    c.force_sensitive,
			\\    c.force_side,
			\\    c.midichlorian_count,
			\\    c.birth_year_bby,
			\\    c.death_year_aby,
			\\    c.height_cm,
			\\    c.mass_kg,
			\\    c.eye_color,
			\\    c.hair_color,
			\\    c.skin_color,
			\\    c.gender,
			\\    c.cybernetic_parts,
			\\    c.clearance_level,
			\\    c.comlink_frequency,
			\\    c.holonet_handle,
			\\    c.service_number,
			\\    c.enlisted_at,
			\\    c.captured_at,
			\\    c.last_seen_at,
			\\    c.medical_clearance_at,
			\\    c.flight_certified,
			\\    c.flight_hours,
			\\    c.confirmed_kills,
			\\    c.missions_flown,
			\\    c.commendations,
			\\    c.reprimands,
			\\    c.piloting_score,
			\\    c.marksmanship_score,
			\\    c.tactics_score,
			\\    c.diplomacy_score,
			\\    c.engineering_score,
			\\    c.languages_spoken,
			\\    c.preferred_weapon,
			\\    c.signature_ship,
			\\    c.bounty_on_head,
			\\    c.wanted_by_empire,
			\\    c.wanted_by_hutts,
			\\    c.quarters,
			\\    c.squadron_role,
			\\    c.next_of_kin,
			\\    c.biography,
			\\    c.psych_profile,
			\\    c.rescue_priority,
			\\    c.cover_identity,
			\\    c.credits_balance,
			\\    c.monthly_stipend,
			\\    c.on_leave,
			\\    c.active,
			\\    c.lock_version,
			\\    s.name AS species_name,
			\\    p.name AS homeworld_name,
			\\    r.title AS rank_title
			\\FROM characters c
			\\LEFT JOIN species s ON s.id = c.species_id
			\\LEFT JOIN planets p ON p.id = c.homeworld_id
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\WHERE c.id = $id
			,
			{ id, },
		)

	update_dossier! : I32, I32, DossierChanges, Db => Try(U64, _)
	update_dossier! = |id, lock_version, changes, db|
		db.execute!(
			\\UPDATE characters
			\\SET alias = $alias,
			\\    callsign = $callsign,
			\\    species_id = $species_id,
			\\    homeworld_id = $homeworld_id,
			\\    rank_id = $rank_id,
			\\    allegiance = $allegiance,
			\\    force_sensitive = $force_sensitive,
			\\    force_side = $force_side,
			\\    eye_color = $eye_color,
			\\    hair_color = $hair_color,
			\\    skin_color = $skin_color,
			\\    gender = $gender,
			\\    height_cm = $height_cm,
			\\    mass_kg = $mass_kg,
			\\    clearance_level = $clearance_level,
			\\    comlink_frequency = $comlink_frequency,
			\\    holonet_handle = $holonet_handle,
			\\    preferred_weapon = $preferred_weapon,
			\\    signature_ship = $signature_ship,
			\\    quarters = $quarters,
			\\    base_id = $base_id,
			\\    squadron_role = $squadron_role,
			\\    next_of_kin = $next_of_kin,
			\\    biography = $biography,
			\\    lock_version = lock_version + 1,
			\\    updated_at = now()
			\\WHERE id = $id AND lock_version = $lock_version
			,
			{
				id,
				lock_version,
				alias: changes.alias,
				callsign: changes.callsign,
				species_id: changes.species_id,
				homeworld_id: changes.homeworld_id,
				rank_id: changes.rank_id,
				allegiance: changes.allegiance,
				force_sensitive: changes.force_sensitive,
				force_side: changes.force_side,
				eye_color: changes.eye_color,
				hair_color: changes.hair_color,
				skin_color: changes.skin_color,
				gender: changes.gender,
				height_cm: changes.height_cm,
				mass_kg: changes.mass_kg,
				clearance_level: changes.clearance_level,
				comlink_frequency: changes.comlink_frequency,
				holonet_handle: changes.holonet_handle,
				preferred_weapon: changes.preferred_weapon,
				signature_ship: changes.signature_ship,
				quarters: changes.quarters,
				base_id: changes.base_id,
				squadron_role: changes.squadron_role,
				next_of_kin: changes.next_of_kin,
				biography: changes.biography,
			},
		)

	search! : Str, Db => Try(List(CharacterSummary), _)
	search! = |text, db|
		db.query!(
			\\SELECT id, name, alias, callsign, allegiance
			\\FROM characters
			\\WHERE archived_at IS NULL
			\\  AND (name ILIKE '%' || $text || '%'
			\\    OR alias ILIKE '%' || $text || '%'
			\\    OR callsign ILIKE '%' || $text || '%')
			\\ORDER BY name
			\\LIMIT 50
			,
			{ text, },
		)

	by_ids! : List(I32), Db => Try(List(CharacterSummary), _)
	by_ids! = |ids, db|
		db.query!(
			\\SELECT id, name, alias, callsign, allegiance
			\\FROM characters
			\\WHERE id = any($ids)
			\\ORDER BY name
			,
			{ ids, },
		)

	roster! : I32, Db => Try(List({ id : I32, name : Str, callsign : Try(Str, [Null]), rank_title : Str, on_leave : Bool }), _)
	roster! = |base_id, db|
		db.query!(
			\\SELECT
			\\    c.id,
			\\    c.name,
			\\    c.callsign,
			\\    coalesce(r.title, 'Unranked') AS rank_title,
			\\    c.on_leave
			\\FROM characters c
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\WHERE c.base_id = $base_id AND c.active
			\\ORDER BY r.seniority DESC NULLS LAST, c.name
			,
			{ base_id, },
		)

	recently_seen! : I32, Db => Try(List({ id : I32, name : Str, last_seen_at : Try(Str, [Null]), planet : Try(Str, [Null]) }), _)
	recently_seen! = |hours, db|
		db.query!(
			\\SELECT c.id, c.name, c.last_seen_at, p.name AS planet
			\\FROM characters c
			\\LEFT JOIN planets p ON p.id = c.last_seen_planet_id
			\\WHERE c.last_seen_at > now() - interval '1 hour' * $hours
			\\ORDER BY c.last_seen_at DESC
			,
			{ hours, },
		)

	wanted! : Db => Try(List({ id : I32, name : Str, wanted_by : Str, bounty_on_head : Dec }), _)
	wanted! = |db|
		db.query!(
			\\SELECT
			\\    id,
			\\    name,
			\\    CASE
			\\        WHEN wanted_by_empire AND wanted_by_hutts THEN 'everyone'
			\\        WHEN wanted_by_empire THEN 'empire'
			\\        ELSE 'hutts'
			\\    END AS wanted_by,
			\\    coalesce(bounty_on_head, 0) AS bounty_on_head
			\\FROM characters
			\\WHERE (wanted_by_empire OR wanted_by_hutts) AND deceased_at IS NULL
			\\ORDER BY bounty_on_head DESC NULLS LAST
			,
			{},
		)

	pilots! : Db => Try(List({ id : I32, name : Str, callsign : Try(Str, [Null]), piloting_score : I32, flight_hours : F64, confirmed_kills : I32 }), _)
	pilots! = |db|
		db.query!(
			\\SELECT
			\\    id,
			\\    name,
			\\    callsign,
			\\    coalesce(piloting_score, 0) AS piloting_score,
			\\    flight_hours,
			\\    confirmed_kills
			\\FROM characters
			\\WHERE flight_certified AND active
			\\ORDER BY coalesce(piloting_score, 0) DESC, flight_hours DESC
			,
			{},
		)

	unassigned_pilots! : Db => Try(List({ id : I32, name : Str, callsign : Try(Str, [Null]) }), _)
	unassigned_pilots! = |db|
		db.query!(
			\\SELECT c.id, c.name, c.callsign
			\\FROM characters c
			\\WHERE c.flight_certified
			\\  AND c.active
			\\  AND NOT c.on_leave
			\\  AND NOT EXISTS (
			\\      SELECT 1
			\\      FROM squadron_assignments sa
			\\      WHERE sa.character_id = c.id AND (sa.ends_on IS NULL OR sa.ends_on >= current_date)
			\\  )
			\\ORDER BY c.name
			,
			{},
		)

	top_enlisters! : Db => Try(List({ id : I32, name : Str, enlistees : I64 }), _)
	top_enlisters! = |db|
		db.query!(
			\\SELECT c.id, c.name, count(r.id) AS enlistees
			\\FROM characters c
			\\JOIN characters r ON r.enlisted_by_id = c.id
			\\WHERE c.id IN (
			\\    SELECT enlisted_by_id
			\\    FROM characters
			\\    WHERE enlisted_at > now() - interval '1 year'
			\\)
			\\GROUP BY c.id
			\\ORDER BY enlistees DESC
			\\LIMIT 10
			,
			{},
		)

	enlistees_by_homeworld! : I64, Db => Try(List({ homeworld : Str, enlistees : I64 }), _)
	enlistees_by_homeworld! = |limit, db|
		db.query!(
			\\WITH kin AS (
			\\    SELECT homeworld_id, count(*) AS n
			\\    FROM characters
			\\    WHERE active AND homeworld_id IS NOT NULL
			\\    GROUP BY homeworld_id
			\\)
			\\SELECT p.name AS homeworld, kin.n AS enlistees
			\\FROM kin
			\\JOIN planets p ON p.id = kin.homeworld_id
			\\ORDER BY kin.n DESC
			\\LIMIT $limit
			,
			{ limit, },
		)

	due_for_medical! : I32, Db => Try(List({ id : I32, name : Str, medical_clearance_at : Try(Str, [Null]) }), _)
	due_for_medical! = |days, db|
		db.query!(
			\\SELECT id, name, medical_clearance_at
			\\FROM characters
			\\WHERE active
			\\  AND (medical_clearance_at IS NULL OR medical_clearance_at < now() - interval '1 day' * $days)
			\\ORDER BY medical_clearance_at NULLS FIRST
			,
			{ days, },
		)

	profile_card! : I32, Db => Try({ card : Str }, _)
	profile_card! = |id, db|
		db.query_one!(
			\\SELECT json_build_object(
			\\    'name', name,
			\\    'callsign', callsign,
			\\    'allegiance', allegiance,
			\\    'clearance', clearance_level
			\\)::text AS card
			\\FROM characters
			\\WHERE id = $id
			,
			{ id, },
		)

	species! : Db => Try(List({ id : I32, name : Str, classification : Try(Str, [Null]), members : I64 }), _)
	species! = |db|
		db.query!(
			\\SELECT s.id, s.name, s.classification, count(c.id) AS members
			\\FROM species s
			\\LEFT JOIN characters c ON c.species_id = s.id
			\\GROUP BY s.id
			\\ORDER BY s.name
			,
			{},
		)

	ranks! : Db => Try(List({ id : I32, title : Str, abbreviation : Str, seniority : I32 }), _)
	ranks! = |db|
		db.query!("SELECT id, title, abbreviation, seniority FROM ranks ORDER BY seniority DESC", {})

	languages_of! : I32, Db => Try(List({ name : Str, fluency : I32 }), _)
	languages_of! = |character_id, db|
		db.query!(
			\\SELECT l.name, cl.fluency
			\\FROM character_languages cl
			\\JOIN languages l ON l.id = cl.language_id
			\\WHERE cl.character_id = $character_id
			\\ORDER BY cl.fluency DESC, l.name
			,
			{ character_id, },
		)

	add_language! : I32, I32, I32, Db => Try(U64, _)
	add_language! = |character_id, language_id, fluency, db|
		db.execute!(
			\\INSERT INTO character_languages (character_id, language_id, fluency, created_at, updated_at)
			\\VALUES ($character_id, $language_id, $fluency, now(), now())
			\\ON CONFLICT (character_id, language_id)
			\\DO UPDATE SET fluency = excluded.fluency, updated_at = now()
			,
			{ character_id, language_id, fluency },
		)

	forget_language! : I32, I32, Db => Try(U64, _)
	forget_language! = |character_id, language_id, db|
		db.execute!("DELETE FROM character_languages WHERE character_id = $character_id AND language_id = $language_id", { character_id, language_id })

	induct! : Str, Try(Str, [Null]), Try(I32, [Null]), Try(I32, [Null]), Try(I32, [Null]), Db => Try({ id : I32, callsign : Try(Str, [Null]) }, _)
	induct! = |name, callsign, species_id, homeworld_id, enlisted_by_id, db|
		db.query_one!(
			\\INSERT INTO characters (
			\\    name, callsign, species_id, homeworld_id, allegiance,
			\\    enlisted_by_id, enlisted_at, created_at, updated_at
			\\)
			\\VALUES (
			\\    $name, $callsign, $species_id, $homeworld_id, 'rebel_alliance',
			\\    $enlisted_by_id, now(), now(), now()
			\\)
			\\RETURNING id, callsign
			,
			{ name, callsign, species_id, homeworld_id, enlisted_by_id },
		)

	promote! : I32, I32, Db => Try({ id : I32, rank_id : Try(I32, [Null]), commendations : I32 }, _)
	promote! = |id, rank_id, db|
		db.query_one!(
			\\UPDATE characters
			\\SET rank_id = $rank_id, commendations = commendations + 1, updated_at = now()
			\\WHERE id = $id
			\\RETURNING id, rank_id, commendations
			,
			{ id, rank_id },
		)

	mark_seen! : I32, I32, Db => Try(U64, _)
	mark_seen! = |id, planet_id, db|
		db.execute!(
			\\UPDATE characters
			\\SET last_seen_at = now(), last_seen_planet_id = $planet_id, updated_at = now()
			\\WHERE id = $id
			,
			{ id, planet_id },
		)

	record_capture! : I32, Db => Try(U64, _)
	record_capture! = |id, db|
		db.execute!(
			\\UPDATE characters
			\\SET captured_at = now(),
			\\    rescue_priority = CASE WHEN clearance_level >= 5 THEN 10 ELSE 5 END,
			\\    updated_at = now()
			\\WHERE id = $id AND captured_at IS NULL
			,
			{ id, },
		)

	pay_stipends! : Str, Db => Try(U64, _)
	pay_stipends! = |through, db|
		db.execute!(
			\\UPDATE characters
			\\SET credits_balance = credits_balance + monthly_stipend,
			\\    stipend_paid_through = $through::date,
			\\    updated_at = now()
			\\WHERE active
			\\  AND monthly_stipend > 0
			\\  AND (stipend_paid_through IS NULL OR stipend_paid_through < $through::date)
			,
			{ through, },
		)

	grant_leave! : I32, I32, Db => Try(U64, _)
	grant_leave! = |id, days, db|
		db.execute!(
			\\UPDATE characters
			\\SET on_leave = true,
			\\    leave_starts_on = current_date,
			\\    leave_ends_on = current_date + $days::integer,
			\\    updated_at = now()
			\\WHERE id = $id AND NOT on_leave
			,
			{ id, days },
		)

	archive! : I32, Str, Db => Try(U64, _)
	archive! = |id, reason, db|
		db.execute!(
			\\UPDATE characters
			\\SET active = false, archived_at = now(), archived_reason = $reason, updated_at = now()
			\\WHERE id = $id AND archived_at IS NULL
			,
			{ id, reason },
		)

	service_record! : I32, Db => Try(Try(ServiceRecord, [NotFound]), _)
	service_record! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    c.id,
			\\    coalesce(r.abbreviation || ' ', '') || c.name AS display_name,
			\\    coalesce(c.callsign, '') AS callsign,
			\\    coalesce(c.service_number, 'unregistered') AS service_number,
			\\    coalesce(b.name, 'unassigned') AS base,
			\\    coalesce((SELECT sq.name FROM squadron_assignments sa JOIN squadrons sq ON sq.id = sa.squadron_id WHERE sa.character_id = c.id AND sa.ends_on IS NULL ORDER BY sa.starts_on DESC LIMIT 1), 'none') AS squadron,
			\\    coalesce(rec.name, 'founding member') AS enlisted_by,
			\\    coalesce(to_char(c.enlisted_at, 'YYYY-MM-DD'), 'unknown') AS enlisted_on,
			\\    coalesce(current_date - c.enlisted_at::date, 0) AS days_of_service,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id), 0) AS missions,
			\\    coalesce((SELECT count(*) FROM mission_participants mp JOIN missions m ON m.id = mp.mission_id WHERE mp.character_id = c.id AND m.status = 'completed'), 0) AS missions_completed,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id AND mp.wounded), 0) AS times_wounded,
			\\    coalesce((SELECT count(*) FROM battle_participants bp WHERE bp.character_id = c.id), 0) AS battles,
			\\    coalesce((SELECT sum(bp.kills) FROM battle_participants bp WHERE bp.character_id = c.id), 0) AS battle_kills,
			\\    c.confirmed_kills,
			\\    c.commendations,
			\\    c.reprimands,
			\\    c.flight_hours,
			\\    coalesce((SELECT max(bo.reward) FROM bounties bo WHERE bo.target_id = c.id AND bo.status = 'posted'), 0) AS highest_bounty,
			\\    coalesce(c.next_of_kin || coalesce(' (' || c.next_of_kin_planet || ')', ''), 'none listed') AS next_of_kin,
			\\    coalesce(c.leave_ends_on - current_date, 0) AS leave_days_left,
			\\    CASE
			\\        WHEN c.deceased_at IS NOT NULL THEN 'killed in action'
			\\        WHEN c.captured_at IS NOT NULL AND c.rescued_at IS NULL THEN 'missing'
			\\        WHEN c.deserted_at IS NOT NULL THEN 'deserted'
			\\        WHEN c.on_leave THEN 'on leave'
			\\        WHEN c.active THEN 'active duty'
			\\        ELSE 'retired'
			\\    END AS status
			\\FROM characters c
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\LEFT JOIN bases b ON b.id = c.base_id
			\\LEFT JOIN characters rec ON rec.id = c.enlisted_by_id
			\\WHERE c.id = $id
			,
			{ id, },
		)


	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["dossier", id] => Str.inspect(Personnel.dossier!(Args.i32(id), db))
			["update-dossier", id, callsign, quarters] =>
				match Personnel.dossier!(Args.i32(id), db) {
					Ok(Ok(d)) =>
						Str.inspect(
							Personnel.update_dossier!(
								d.id,
								d.lock_version,
								{
									alias: d.alias,
									callsign: Ok(callsign),
									species_id: d.species_id,
									homeworld_id: d.homeworld_id,
									rank_id: d.rank_id,
									allegiance: d.allegiance,
									force_sensitive: d.force_sensitive,
									force_side: d.force_side,
									eye_color: d.eye_color,
									hair_color: d.hair_color,
									skin_color: d.skin_color,
									gender: d.gender,
									height_cm: d.height_cm,
									mass_kg: d.mass_kg,
									clearance_level: d.clearance_level,
									comlink_frequency: d.comlink_frequency,
									holonet_handle: d.holonet_handle,
									preferred_weapon: d.preferred_weapon,
									signature_ship: d.signature_ship,
									quarters: Ok(quarters),
									base_id: d.base_id,
									squadron_role: d.squadron_role,
									next_of_kin: d.next_of_kin,
									biography: d.biography,
								},
								db,
							),
						)
					other => Str.inspect(other)
				}
			["search", text] => Str.inspect(Personnel.search!(text, db))
			["by-ids", .. as ids] => Str.inspect(Personnel.by_ids!(List.map(ids, Args.i32), db))
			["roster", base_id] => Str.inspect(Personnel.roster!(Args.i32(base_id), db))
			["recently-seen", hours] => Str.inspect(Personnel.recently_seen!(Args.i32(hours), db))
			["wanted"] => Str.inspect(Personnel.wanted!(db))
			["pilots"] => Str.inspect(Personnel.pilots!(db))
			["unassigned-pilots"] => Str.inspect(Personnel.unassigned_pilots!(db))
			["top-enlisters"] => Str.inspect(Personnel.top_enlisters!(db))
			["enlistees-by-homeworld", limit] => Str.inspect(Personnel.enlistees_by_homeworld!(Args.i64(limit), db))
			["due-for-medical", days] => Str.inspect(Personnel.due_for_medical!(Args.i32(days), db))
			["card", id] => Str.inspect(Personnel.profile_card!(Args.i32(id), db))
			["species"] => Str.inspect(Personnel.species!(db))
			["ranks"] => Str.inspect(Personnel.ranks!(db))
			["languages", character_id] => Str.inspect(Personnel.languages_of!(Args.i32(character_id), db))
			["add-language", character_id, language_id, fluency] => Str.inspect(Personnel.add_language!(Args.i32(character_id), Args.i32(language_id), Args.i32(fluency), db))
			["forget-language", character_id, language_id] => Str.inspect(Personnel.forget_language!(Args.i32(character_id), Args.i32(language_id), db))
			["induct", name] => Str.inspect(Personnel.induct!(name, Err(Null), Err(Null), Err(Null), Err(Null), db))
			["induct", name, callsign, enlisted_by_id] => Str.inspect(Personnel.induct!(name, Ok(callsign), Err(Null), Err(Null), Ok(Args.i32(enlisted_by_id)), db))
			["promote", id, rank_id] => Str.inspect(Personnel.promote!(Args.i32(id), Args.i32(rank_id), db))
			["seen", id, planet_id] => Str.inspect(Personnel.mark_seen!(Args.i32(id), Args.i32(planet_id), db))
			["captured", id] => Str.inspect(Personnel.record_capture!(Args.i32(id), db))
			["pay-stipends", through] => Str.inspect(Personnel.pay_stipends!(through, db))
			["leave", id, days] => Str.inspect(Personnel.grant_leave!(Args.i32(id), Args.i32(days), db))
			["archive", id, reason] => Str.inspect(Personnel.archive!(Args.i32(id), reason, db))
			["service-record", id] => Str.inspect(Personnel.service_record!(Args.i32(id), db))
			_ => "unknown personnel command"
		}
}
