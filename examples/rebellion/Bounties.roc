import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

OpenBounty : {
	id : I32,
	target : Str,
	reward : Dec,
	dead_or_alive : Bool,
	posted_by : Str,
	expires_at : Try(Str, [Null]),
	last_known_planet : Try(Str, [Null]),
}

Bounty : {
	id : I32,
	target_id : I32,
	posted_by : Str,
	posted_by_allegiance : Str,
	reward : Dec,
	currency : Str,
	dead_or_alive : Bool,
	status : Str,
	hunter_id : Try(I32, [Null]),
	accepted_at : Try(Str, [Null]),
	collected_at : Try(Str, [Null]),
	expires_at : Try(Str, [Null]),
	last_known_planet_id : Try(I32, [Null]),
	last_known_at : Try(Str, [Null]),
	disintegrations_allowed : Bool,
	guild_registered : Bool,
	guild_code : Try(Str, [Null]),
	contact_frequency : Try(Str, [Null]),
	description : Try(Str, [Null]),
	threat_assessment : Try(Str, [Null]),
	hunters_engaged : I32,
	hunters_lost : I32,
}

NewBounty : {
	target_id : I32,
	posted_by : Str,
	posted_by_allegiance : Str,
	reward : Dec,
	dead_or_alive : Bool,
	expires_in_days : I32,
	description : Try(Str, [Null]),
}

Hunter : {
	id : I32,
	name : Str,
	guild_rank : I32,
	collected : I64,
	earned : Dec,
}

LastSighting : {
	character_id : I32,
	name : Str,
	seen_at : Str,
	confidence : Str,
	planet : Try(Str, [Null]),
}

TargetBounty : {
	id : I32,
	reward : Dec,
	currency : Str,
	status : Str,
	dead_or_alive : Bool,
	posted_by : Str,
	posted_by_allegiance : Str,
	expires_at : Try(Str, [Null]),
	accepted_at : Try(Str, [Null]),
	target : Str,
	known_as : Str,
	display_name : Str,
	target_allegiance : Str,
	bounty_on_head : Try(Dec, [Null]),
	wanted_by_empire : Bool,
	wanted_by_hutts : Bool,
	last_known_planet : Try(Str, [Null]),
	days_since_known : Try(I32, [Null]),
	hunter_name : Try(Str, [Null]),
	hunter_rank : Try(I32, [Null]),
	board_state : Str,
	recent_sightings : Try(I64, [Null]),
	last_confidence : Try(Str, [Null]),
	open_reward_total : Try(Dec, [Null]),
	hunters_active : I32,
	description : Try(Str, [Null]),
}

HunterReport : {
	id : I32,
	name : Str,
	handle : Try(Str, [Null]),
	guild_rank : I32,
	tier : Str,
	allegiance : Str,
	species : Try(Str, [Null]),
	homeworld : Try(Str, [Null]),
	confirmed_kills : I32,
	marksmanship_score : Try(I32, [Null]),
	stealth_score : Try(I32, [Null]),
	field_score : I32,
	active_contracts : Try(I64, [Null]),
	collected : Try(I64, [Null]),
	earned : Try(Dec, [Null]),
	failed : Try(I64, [Null]),
	last_collected_at : Try(Str, [Null]),
	avg_days_to_collect : Try(Dec, [Null]),
	wanted_themselves : Bool,
	last_seen_at : Try(Str, [Null]),
	days_since_seen : Try(I32, [Null]),
	credits_balance : I64,
	registered_on : Str,
}

Bounties := [].{
	open_bounties! : Dec, Db => Try(List(OpenBounty), _)
	open_bounties! = |min_reward, db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    c.name AS target,
			\\    b.reward,
			\\    b.dead_or_alive,
			\\    b.posted_by,
			\\    b.expires_at,
			\\    p.name AS last_known_planet
			\\FROM bounties b
			\\JOIN characters c ON c.id = b.target_id
			\\LEFT JOIN planets p ON p.id = b.last_known_planet_id
			\\WHERE b.status = 'posted'
			\\  AND b.reward >= $min_reward
			\\  AND (b.expires_at IS NULL OR b.expires_at > now())
			\\ORDER BY b.reward DESC
			,
			{ min_reward, },
		)

	bounty! : I32, Db => Try(Try(Bounty, [NotFound]), _)
	bounty! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    id,
			\\    target_id,
			\\    posted_by,
			\\    posted_by_allegiance,
			\\    reward,
			\\    currency,
			\\    dead_or_alive,
			\\    status,
			\\    hunter_id,
			\\    accepted_at,
			\\    collected_at,
			\\    expires_at,
			\\    last_known_planet_id,
			\\    last_known_at,
			\\    disintegrations_allowed,
			\\    guild_registered,
			\\    guild_code,
			\\    contact_frequency,
			\\    description,
			\\    threat_assessment,
			\\    hunters_engaged,
			\\    hunters_lost
			\\FROM bounties
			\\WHERE id = $id
			,
			{ id, },
		)

	post_bounty! : NewBounty, Db => Try({ id : I32 }, _)
	post_bounty! = |bounty, db|
		db.query_one!(
			\\INSERT INTO bounties (
			\\    target_id,
			\\    posted_by,
			\\    posted_by_allegiance,
			\\    reward,
			\\    dead_or_alive,
			\\    expires_at,
			\\    description,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES (
			\\    $target_id,
			\\    $posted_by,
			\\    $posted_by_allegiance,
			\\    $reward,
			\\    $dead_or_alive,
			\\    now() + interval '1 day' * $expires_in_days,
			\\    $description,
			\\    now(),
			\\    now()
			\\)
			\\RETURNING id
			,
			bounty,
		)

	accept! : I32, I32, Db => Try(U64, _)
	accept! = |id, hunter_id, db|
		db.execute!(
			\\UPDATE bounties
			\\SET status = 'accepted',
			\\    hunter_id = $hunter_id,
			\\    accepted_at = now(),
			\\    hunters_engaged = hunters_engaged + 1,
			\\    updated_at = now()
			\\WHERE id = $id AND status = 'posted'
			,
			{ id, hunter_id },
		)

	collect! : I32, Db => Try({ reward : Dec }, _)
	collect! = |id, db|
		db.query_one!(
			\\UPDATE bounties
			\\SET status = 'collected', collected_at = now(), updated_at = now()
			\\WHERE id = $id AND status = 'accepted'
			\\RETURNING reward
			,
			{ id, },
		)

	expire_old! : Db => Try(U64, _)
	expire_old! = |db|
		db.execute!("UPDATE bounties SET status = 'expired', updated_at = now() WHERE status = 'posted' AND expires_at < now()", {})

	register_hunter! : I32, I32, Db => Try({ id : I32 }, _)
	register_hunter! = |character_id, guild_rank, db|
		db.query_one!(
			\\INSERT INTO bounty_hunters (character_id, guild_rank, created_at, updated_at)
			\\VALUES ($character_id, $guild_rank, now(), now())
			\\ON CONFLICT (character_id) DO UPDATE
			\\SET guild_rank = excluded.guild_rank, updated_at = now()
			\\RETURNING id
			,
			{ character_id, guild_rank },
		)

	leaderboard! : Db => Try(List(Hunter), _)
	leaderboard! = |db|
		db.query!(
			\\SELECT
			\\    h.id,
			\\    c.name,
			\\    h.guild_rank,
			\\    count(b.id) AS collected,
			\\    coalesce(sum(b.reward), 0) AS earned
			\\FROM bounty_hunters h
			\\JOIN characters c ON c.id = h.character_id
			\\LEFT JOIN bounties b ON b.hunter_id = h.id AND b.status = 'collected'
			\\GROUP BY h.id, c.name, h.guild_rank
			\\ORDER BY earned DESC, c.name
			\\LIMIT 20
			,
			{},
		)

	report_sighting! : I32, Try(I32, [Null]), Try(I32, [Null]), Str, Try(Str, [Null]), Db => Try(U64, _)
	report_sighting! = |character_id, planet_id, reported_by_id, confidence, details, db|
		db.execute!(
			\\INSERT INTO sightings (character_id, planet_id, reported_by_id, seen_at, confidence, details, created_at, updated_at)
			\\VALUES ($character_id, $planet_id, $reported_by_id, now(), $confidence, $details, now(), now())
			,
			{ character_id, planet_id, reported_by_id, confidence, details },
		)

	last_sightings! : List(I32), Db => Try(List(LastSighting), _)
	last_sightings! = |ids, db|
		db.query!(
			\\SELECT DISTINCT ON (s.character_id)
			\\    s.character_id,
			\\    c.name,
			\\    s.seen_at,
			\\    s.confidence,
			\\    p.name AS planet
			\\FROM sightings s
			\\JOIN characters c ON c.id = s.character_id
			\\LEFT JOIN planets p ON p.id = s.planet_id
			\\WHERE s.character_id = any($ids)
			\\ORDER BY s.character_id, s.seen_at DESC
			,
			{ ids, },
		)

	wanted_and_seen! : Db => Try(List({ id : I32, name : Str, last_seen_at : Try(Str, [Null]) }), _)
	wanted_and_seen! = |db|
		db.query!(
			\\SELECT c.id, c.name, c.last_seen_at
			\\FROM characters c
			\\WHERE c.wanted_by_empire
			\\  AND EXISTS (
			\\      SELECT 1
			\\      FROM sightings s
			\\      WHERE s.character_id = c.id AND s.seen_at > now() - interval '30 days'
			\\  )
			\\ORDER BY c.name
			,
			{},
		)

	target_dossier! : I32, Db => Try(List(TargetBounty), _)
	target_dossier! = |target_id, db|
		db.query!(
			\\SELECT
			\\    b.id,
			\\    b.reward,
			\\    b.currency,
			\\    b.status,
			\\    b.dead_or_alive,
			\\    b.posted_by,
			\\    b.posted_by_allegiance,
			\\    b.expires_at,
			\\    b.accepted_at,
			\\    c.name AS target,
			\\    coalesce(c.alias, c.callsign, c.name) AS known_as,
			\\    c.name || coalesce(' (' || c.alias || ')', '') AS display_name,
			\\    c.allegiance AS target_allegiance,
			\\    c.bounty_on_head,
			\\    c.wanted_by_empire,
			\\    c.wanted_by_hutts,
			\\    lp.name AS last_known_planet,
			\\    current_date - b.last_known_at::date AS days_since_known,
			\\    hc.name AS hunter_name,
			\\    h.guild_rank AS hunter_rank,
			\\    CASE
			\\        WHEN b.status = 'collected' THEN 'closed'
			\\        WHEN b.expires_at < now() THEN 'lapsed'
			\\        WHEN b.hunter_id IS NOT NULL THEN 'in pursuit'
			\\        WHEN b.reward >= 100000 THEN 'high value'
			\\        ELSE 'open'
			\\    END AS board_state,
			\\    (
			\\        SELECT count(*)
			\\        FROM sightings s
			\\        WHERE s.character_id = b.target_id AND s.seen_at > now() - interval '14 days'
			\\    ) AS recent_sightings,
			\\    (
			\\        SELECT s.confidence
			\\        FROM sightings s
			\\        WHERE s.character_id = b.target_id
			\\        ORDER BY s.seen_at DESC
			\\        LIMIT 1
			\\    ) AS last_confidence,
			\\    (
			\\        SELECT sum(o.reward)
			\\        FROM bounties o
			\\        WHERE o.target_id = b.target_id AND o.status IN ('posted', 'accepted')
			\\    ) AS open_reward_total,
			\\    b.hunters_engaged - b.hunters_lost AS hunters_active,
			\\    b.description
			\\FROM bounties b
			\\JOIN characters c ON c.id = b.target_id
			\\LEFT JOIN planets lp ON lp.id = b.last_known_planet_id
			\\LEFT JOIN bounty_hunters h ON h.id = b.hunter_id
			\\LEFT JOIN characters hc ON hc.id = h.character_id
			\\WHERE b.target_id = $target_id
			\\ORDER BY b.created_at DESC
			,
			{ target_id, },
		)

	hunter_report! : I32, Db => Try(List(HunterReport), _)
	hunter_report! = |days, db|
		db.query!(
			\\SELECT
			\\    h.id,
			\\    c.name,
			\\    coalesce(c.callsign, c.alias) AS handle,
			\\    h.guild_rank,
			\\    CASE
			\\        WHEN h.guild_rank >= 5 THEN 'master'
			\\        WHEN h.guild_rank >= 3 THEN 'journeyman'
			\\        ELSE 'apprentice'
			\\    END AS tier,
			\\    c.allegiance,
			\\    sp.name AS species,
			\\    hw.name AS homeworld,
			\\    c.confirmed_kills,
			\\    c.marksmanship_score,
			\\    c.stealth_score,
			\\    coalesce(c.marksmanship_score, 0) + coalesce(c.stealth_score, 0) + coalesce(c.tactics_score, 0) AS field_score,
			\\    (SELECT count(*) FROM bounties b WHERE b.hunter_id = h.id AND b.status = 'accepted') AS active_contracts,
			\\    (
			\\        SELECT count(*)
			\\        FROM bounties b
			\\        WHERE b.hunter_id = h.id
			\\          AND b.status = 'collected'
			\\          AND b.collected_at > now() - interval '1 day' * $days
			\\    ) AS collected,
			\\    (
			\\        SELECT coalesce(sum(b.reward), 0)
			\\        FROM bounties b
			\\        WHERE b.hunter_id = h.id
			\\          AND b.status = 'collected'
			\\          AND b.collected_at > now() - interval '1 day' * $days
			\\    ) AS earned,
			\\    (SELECT count(*) FROM bounties b WHERE b.hunter_id = h.id AND b.status = 'expired') AS failed,
			\\    (SELECT max(b.collected_at) FROM bounties b WHERE b.hunter_id = h.id) AS last_collected_at,
			\\    (
			\\        SELECT round((avg(extract(epoch FROM b.collected_at - b.accepted_at)) / 86400)::numeric, 1)
			\\        FROM bounties b
			\\        WHERE b.hunter_id = h.id AND b.collected_at IS NOT NULL
			\\    ) AS avg_days_to_collect,
			\\    c.wanted_by_empire OR c.wanted_by_hutts AS wanted_themselves,
			\\    c.last_seen_at,
			\\    current_date - c.last_seen_at::date AS days_since_seen,
			\\    c.credits_balance,
			\\    h.created_at::date AS registered_on
			\\FROM bounty_hunters h
			\\JOIN characters c ON c.id = h.character_id
			\\LEFT JOIN species sp ON sp.id = c.species_id
			\\LEFT JOIN planets hw ON hw.id = c.homeworld_id
			\\ORDER BY earned DESC, h.guild_rank DESC, c.name
			,
			{ days, },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["dossier", target_id] => Str.inspect(Bounties.target_dossier!(Args.i32(target_id), db))
			["hunters", days] => Str.inspect(Bounties.hunter_report!(Args.i32(days), db))
			["open"] => Str.inspect(Bounties.open_bounties!(0, db))
			["open", min_reward] => Str.inspect(Bounties.open_bounties!(Args.dec(min_reward), db))
			["show", id] => Str.inspect(Bounties.bounty!(Args.i32(id), db))
			["post", target_id, posted_by, allegiance, reward, days] =>
				Str.inspect(
					Bounties.post_bounty!(
						{
							target_id: Args.i32(target_id),
							posted_by,
							posted_by_allegiance: allegiance,
							reward: Args.dec(reward),
							dead_or_alive: Bool.False,
							expires_in_days: Args.i32(days),
							description: Err(Null),
						},
						db,
					),
				)

			["accept", id, hunter_id] => Str.inspect(Bounties.accept!(Args.i32(id), Args.i32(hunter_id), db))
			["collect", id] => Str.inspect(Bounties.collect!(Args.i32(id), db))
			["expire"] => Str.inspect(Bounties.expire_old!(db))
			["register-hunter", character_id, guild_rank] => Str.inspect(Bounties.register_hunter!(Args.i32(character_id), Args.i32(guild_rank), db))
			["leaderboard"] => Str.inspect(Bounties.leaderboard!(db))
			["sighting", character_id, confidence] => Str.inspect(Bounties.report_sighting!(Args.i32(character_id), Err(Null), Err(Null), confidence, Err(Null), db))
			["sighting", character_id, planet_id, confidence, details] => Str.inspect(Bounties.report_sighting!(Args.i32(character_id), Ok(Args.i32(planet_id)), Err(Null), confidence, Ok(details), db))
			["last-seen", .. as ids] => Str.inspect(Bounties.last_sightings!(List.map(ids, Args.i32), db))
			["wanted"] => Str.inspect(Bounties.wanted_and_seen!(db))
			_ => "unknown bounties command"
		}
}
