import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Connection, Schema)

Mission : {
	id : I32,
	code_name : Str,
	objective : Str,
	status : Str,
	priority : I32,
	planned_on : Try(Str, [Null]),
	approved_at : Try(Str, [Null]),
	launched_at : Try(Str, [Null]),
	completed_at : Try(Str, [Null]),
	aborted_at : Try(Str, [Null]),
	abort_reason : Try(Str, [Null]),
	casualties_count : I32,
	ships_lost : I32,
	intel_gained : Bool,
	success_score : Try(F64, [Null]),
	budget_credits : Try(I64, [Null]),
	spent_credits : I64,
	classified : Bool,
	clearance_required : I32,
	debrief_summary : Try(Str, [Null]),
	lessons_learned : Try(Str, [Null]),
	extraction_point : Try(Str, [Null]),
	rendezvous_code : Try(Str, [Null]),
	lock_version : I32,
	target : Str,
	commander : Try(Str, [Null]),
}

MissionSummary : {
	id : I32,
	code_name : Str,
	status : Str,
	priority : I32,
}

Debrief : {
	id : I32,
	lock_version : I32,
	status : Str,
	casualties_count : I32,
	ships_lost : I32,
	intel_gained : Bool,
	success_score : Try(F64, [Null]),
	spent_credits : I64,
	debrief_summary : Try(Str, [Null]),
	lessons_learned : Try(Str, [Null]),
	extraction_point : Try(Str, [Null]),
	rendezvous_code : Try(Str, [Null]),
}

Participant : {
	name : Str,
	role : Str,
	starship : Try(Str, [Null]),
	wounded : Bool,
	killed : Bool,
	fate : Str,
}

Briefing : {
	id : I32,
	header : Str,
	code_name : Str,
	objective : Str,
	status : Str,
	priority : I32,
	urgency : Str,
	target : Str,
	target_climate : Try(Str, [Null]),
	target_threat_level : Try(I32, [Null]),
	target_allegiance : Str,
	staging_base : Str,
	commander : Try(Str, [Null]),
	commander_rank : Try(Str, [Null]),
	commander_line : Str,
	planned_on : Try(Str, [Null]),
	days_until_launch : Try(I32, [Null]),
	budget_credits : Try(I64, [Null]),
	spent_credits : I64,
	remaining_credits : I64,
	budget_status : Str,
	crew : I64,
	pilots : I64,
	ships_assigned : I64,
	reliable_intel : I64,
	latest_intel_at : Try(Str, [Null]),
	parent_code_name : Try(Str, [Null]),
	extraction_point : Str,
	rendezvous_code : Try(Str, [Null]),
	clearance_required : I32,
	classified : Bool,
}

OutcomeRow : {
	id : I32,
	code_name : Str,
	status : Str,
	grade : Str,
	target : Str,
	commander : Try(Str, [Null]),
	launched_at : Try(Str, [Null]),
	ended_at : Try(Str, [Null]),
	duration_days : Try(F64, [Null]),
	casualties_count : I32,
	ships_lost : I32,
	score : F64,
	intel_gained : Bool,
	budget_credits : Try(I64, [Null]),
	spent_credits : I64,
	overspend : I64,
	crew : I64,
	cost_per_operative : Dec,
	wounded : I64,
	captured : I64,
	commended : I64,
	battles : I64,
	battle_names : Try(Str, [Null]),
	reports_filed : I64,
	summary_line : Str,
}

Missions := [].{
	mission! : I32, Db => Try(Try(Mission, [NotFound]), _)
	mission! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    m.id,
			\\    m.code_name,
			\\    m.objective,
			\\    m.status,
			\\    m.priority,
			\\    m.planned_on,
			\\    m.approved_at,
			\\    m.launched_at,
			\\    m.completed_at,
			\\    m.aborted_at,
			\\    m.abort_reason,
			\\    m.casualties_count,
			\\    m.ships_lost,
			\\    m.intel_gained,
			\\    m.success_score,
			\\    m.budget_credits,
			\\    m.spent_credits,
			\\    m.classified,
			\\    m.clearance_required,
			\\    m.debrief_summary,
			\\    m.lessons_learned,
			\\    m.extraction_point,
			\\    m.rendezvous_code,
			\\    m.lock_version,
			\\    coalesce(p.name, 'unknown') AS target,
			\\    c.name AS commander
			\\FROM missions m
			\\LEFT JOIN planets p ON p.id = m.target_planet_id
			\\LEFT JOIN characters c ON c.id = m.commander_id
			\\WHERE m.id = $id
			,
			{ id, },
		)

	active! : Db => Try(List({ id : I32, code_name : Str, priority : I32, crew : I64 }), _)
	active! = |db|
		db.query!(
			\\WITH crew AS (
			\\    SELECT mission_id, count(*) AS size
			\\    FROM mission_participants
			\\    WHERE NOT killed AND NOT captured
			\\    GROUP BY mission_id
			\\)
			\\SELECT m.id, m.code_name, m.priority, coalesce(crew.size, 0) AS crew
			\\FROM missions m
			\\LEFT JOIN crew ON crew.mission_id = m.id
			\\WHERE m.status = 'active'
			\\ORDER BY m.priority, m.code_name
			,
			{},
		)

	search! : Str, Try(Str, [Null]), Db => Try(List(MissionSummary), _)
	search! = |text, status, db|
		db.query!(
			\\SELECT id, code_name, status, priority
			\\FROM missions
			\\WHERE (code_name ILIKE '%' || $text || '%' OR objective ILIKE '%' || $text || '%')
			\\  AND ($status::text IS NULL OR status::text = $status)
			\\ORDER BY priority, code_name
			\\LIMIT 50
			,
			{ text, status },
		)

	planned_between! : Str, Str, Db => Try(List({ id : I32, code_name : Str, planned_on : Try(Str, [Null]) }), _)
	planned_between! = |from, to, db|
		db.query!(
			\\SELECT id, code_name, planned_on
			\\FROM missions
			\\WHERE planned_on BETWEEN $from::date AND $to::date
			\\ORDER BY planned_on
			,
			{ from, to },
		)

	stalled! : Db => Try(List({ id : I32, code_name : Str, launched_at : Try(Str, [Null]) }), _)
	stalled! = |db|
		db.query!(
			\\SELECT id, code_name, launched_at
			\\FROM missions
			\\WHERE status = 'active' AND launched_at < now() - interval '30 days'
			\\ORDER BY launched_at
			,
			{},
		)

	overdue! : Db => Try(List(MissionSummary), _)
	overdue! = |db|
		db.query!(
			\\SELECT id, code_name, status, priority
			\\FROM missions
			\\WHERE status = 'planned' AND planned_on < current_date - interval '7 days'
			\\ORDER BY planned_on
			,
			{},
		)

	unstaffed! : Db => Try(List(MissionSummary), _)
	unstaffed! = |db|
		db.query!(
			\\SELECT m.id, m.code_name, m.status, m.priority
			\\FROM missions m
			\\WHERE m.status = 'planned'
			\\  AND m.planned_on < (now() + interval '14 days')::date
			\\  AND NOT EXISTS (SELECT 1 FROM mission_participants mp WHERE mp.mission_id = m.id)
			\\ORDER BY m.planned_on
			,
			{},
		)

	by_ids! : List(I32), Db => Try(List(MissionSummary), _)
	by_ids! = |ids, db|
		db.query!(
			\\SELECT id, code_name, status, priority
			\\FROM missions
			\\WHERE id = any($ids)
			\\ORDER BY priority, code_name
			,
			{ ids, },
		)

	create! : Str, Str, I32, Try(I32, [Null]), Try(Str, [Null]), Db => Try({ id : I32 }, _)
	create! = |code_name, objective, priority, target_planet_id, planned_on, db|
		db.query_one!(
			\\INSERT INTO missions (code_name, objective, priority, target_planet_id, planned_on, created_at, updated_at)
			\\VALUES ($code_name, $objective, $priority, $target_planet_id, $planned_on::date, now(), now())
			\\RETURNING id
			,
			{ code_name, objective, priority, target_planet_id, planned_on },
		)

	approve! : I32, I32, Db => Try(U64, _)
	approve! = |id, approved_by_id, db|
		db.execute!(
			\\UPDATE missions
			\\SET approved_by_id = $approved_by_id, approved_at = now(), updated_at = now()
			\\WHERE id = $id AND approved_at IS NULL
			,
			{ id, approved_by_id },
		)

	launch! : I32, Db => Try(Try({ launched_at : Try(Str, [Null]) }, [NotFound]), _)
	launch! = |id, db|
		db.query_optional!(
			\\UPDATE missions
			\\SET status = 'active', launched_at = now(), updated_at = now()
			\\WHERE id = $id AND status = 'planned' AND approved_at IS NOT NULL
			\\RETURNING launched_at
			,
			{ id, },
		)

	debrief! : Debrief, Db => Try(Try({ lock_version : I32 }, [NotFound]), _)
	debrief! = |debrief, db|
		db.query_optional!(
			\\UPDATE missions
			\\SET status = $status::mission_status,
			\\    completed_at = CASE WHEN $status::mission_status = 'completed' THEN now() ELSE completed_at END,
			\\    aborted_at = CASE WHEN $status::mission_status IN ('aborted', 'failed') THEN now() ELSE aborted_at END,
			\\    casualties_count = $casualties_count,
			\\    ships_lost = $ships_lost,
			\\    intel_gained = $intel_gained,
			\\    success_score = $success_score,
			\\    spent_credits = $spent_credits,
			\\    debrief_summary = $debrief_summary,
			\\    lessons_learned = $lessons_learned,
			\\    extraction_point = $extraction_point,
			\\    rendezvous_code = $rendezvous_code,
			\\    lock_version = lock_version + 1,
			\\    updated_at = now()
			\\WHERE id = $id AND lock_version = $lock_version
			\\RETURNING lock_version
			,
			debrief,
		)

	participants! : I32, Db => Try(List(Participant), _)
	participants! = |mission_id, db|
		db.query!(
			\\SELECT
			\\    c.name,
			\\    mp.role,
			\\    s.name AS starship,
			\\    mp.wounded,
			\\    mp.killed,
			\\    CASE
			\\        WHEN mp.killed THEN 'killed in action'
			\\        WHEN mp.captured THEN 'captured'
			\\        WHEN mp.wounded THEN 'wounded'
			\\        ELSE 'returned'
			\\    END AS fate
			\\FROM mission_participants mp
			\\JOIN characters c ON c.id = mp.character_id
			\\LEFT JOIN starships s ON s.id = mp.starship_id
			\\WHERE mp.mission_id = $mission_id
			\\ORDER BY c.name
			,
			{ mission_id, },
		)

	enlist! : I32, I32, Str, Try(I32, [Null]), Db => Try(U64, _)
	enlist! = |mission_id, character_id, role, starship_id, db|
		db.execute!(
			\\INSERT INTO mission_participants (mission_id, character_id, role, starship_id, joined_at, created_at, updated_at)
			\\VALUES ($mission_id, $character_id, $role, $starship_id, now(), now(), now())
			\\ON CONFLICT (mission_id, character_id) DO UPDATE
			\\SET role = excluded.role, starship_id = excluded.starship_id, updated_at = now()
			,
			{ mission_id, character_id, role, starship_id },
		)

	add_report! : I32, I32, Str, Db => Try({ id : I32 }, _)
	add_report! = |mission_id, author_id, body, db|
		db.query_one!(
			\\INSERT INTO mission_reports (mission_id, author_id, body, created_at, updated_at)
			\\VALUES ($mission_id, $author_id, $body, now(), now())
			\\RETURNING id
			,
			{ mission_id, author_id, body },
		)

	reports! : I32, Db => Try(List({ id : I32, author : Str, body : Str, created_at : Str }), _)
	reports! = |mission_id, db|
		db.query!(
			\\SELECT mr.id, c.name AS author, mr.body, mr.created_at
			\\FROM mission_reports mr
			\\JOIN characters c ON c.id = mr.author_id
			\\WHERE mr.mission_id = $mission_id
			\\ORDER BY mr.created_at
			,
			{ mission_id, },
		)

	veterans! : I64, Db => Try(List({ id : I32, name : Str, missions : I64 }), _)
	veterans! = |min_missions, db|
		db.query!(
			\\SELECT
			\\    c.id,
			\\    c.name,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id AND NOT mp.killed), 0) AS missions
			\\FROM characters c
			\\WHERE c.active
			\\  AND (SELECT count(*) FROM mission_participants mp WHERE mp.character_id = c.id AND NOT mp.killed) >= $min_missions
			\\ORDER BY missions DESC, c.name
			,
			{ min_missions, },
		)

	briefing! : I32, Db => Try(Try(Briefing, [NotFound]), _)
	briefing! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    m.id,
			\\    upper(m.code_name) || ' / P' || m.priority || ' / ' || upper(m.status::text) AS header,
			\\    m.code_name,
			\\    m.objective,
			\\    m.status,
			\\    m.priority,
			\\    CASE m.priority WHEN 1 THEN 'critical' WHEN 2 THEN 'high' WHEN 3 THEN 'normal' ELSE 'low' END AS urgency,
			\\    coalesce(p.name, 'classified') AS target,
			\\    p.climate AS target_climate,
			\\    p.threat_level AS target_threat_level,
			\\    coalesce(p.allegiance::text, 'unknown') AS target_allegiance,
			\\    coalesce(b.code_name, 'none') AS staging_base,
			\\    c.name AS commander,
			\\    r.title AS commander_rank,
			\\    coalesce(r.abbreviation || ' ', '') || coalesce(c.name, 'no commander assigned') AS commander_line,
			\\    m.planned_on,
			\\    m.planned_on - current_date AS days_until_launch,
			\\    m.budget_credits,
			\\    m.spent_credits,
			\\    coalesce(m.budget_credits - m.spent_credits, 0) AS remaining_credits,
			\\    CASE
			\\        WHEN m.budget_credits IS NULL THEN 'unbudgeted'
			\\        WHEN m.spent_credits > m.budget_credits THEN 'over budget'
			\\        WHEN m.spent_credits > m.budget_credits * 0.9 THEN 'nearly spent'
			\\        ELSE 'within budget'
			\\    END AS budget_status,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id), 0) AS crew,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id AND mp.starship_id IS NOT NULL), 0) AS pilots,
			\\    coalesce((SELECT count(*) FROM ship_assignments sa WHERE sa.mission_id = m.id), 0) AS ships_assigned,
			\\    coalesce((SELECT count(*) FROM intel_reports ir WHERE ir.mission_id = m.id AND ir.reliability IN ('plausible', 'confirmed')), 0) AS reliable_intel,
			\\    (SELECT max(ir.received_at) FROM intel_reports ir WHERE ir.mission_id = m.id) AS latest_intel_at,
			\\    (SELECT pm.code_name FROM missions pm WHERE pm.id = m.parent_mission_id) AS parent_code_name,
			\\    coalesce(m.extraction_point, 'to be decided') AS extraction_point,
			\\    m.rendezvous_code,
			\\    m.clearance_required,
			\\    m.classified
			\\FROM missions m
			\\LEFT JOIN planets p ON p.id = m.target_planet_id
			\\LEFT JOIN bases b ON b.id = m.staging_base_id
			\\LEFT JOIN characters c ON c.id = m.commander_id
			\\LEFT JOIN ranks r ON r.id = c.rank_id
			\\WHERE m.id = $id
			,
			{ id, },
		)

	outcomes! : Str, Str, Db => Try(List(OutcomeRow), _)
	outcomes! = |from, to, db|
		db.query!(
			\\SELECT
			\\    m.id,
			\\    m.code_name,
			\\    m.status,
			\\    CASE
			\\        WHEN m.status = 'completed' AND m.success_score >= 0.8 THEN 'triumph'
			\\        WHEN m.status = 'completed' THEN 'success'
			\\        WHEN m.status = 'aborted' THEN 'withdrawn'
			\\        ELSE 'failure'
			\\    END AS grade,
			\\    coalesce(p.name, 'classified') AS target,
			\\    c.name AS commander,
			\\    m.launched_at,
			\\    coalesce(m.completed_at, m.aborted_at) AS ended_at,
			\\    date_part('day', coalesce(m.completed_at, m.aborted_at) - m.launched_at) AS duration_days,
			\\    m.casualties_count,
			\\    m.ships_lost,
			\\    coalesce(m.success_score, 0) AS score,
			\\    m.intel_gained,
			\\    m.budget_credits,
			\\    m.spent_credits,
			\\    greatest(m.spent_credits - coalesce(m.budget_credits, m.spent_credits), 0) AS overspend,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id), 0) AS crew,
			\\    round(m.spent_credits::numeric / greatest(coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id), 0), 1), 2) AS cost_per_operative,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id AND mp.wounded), 0) AS wounded,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id AND mp.captured), 0) AS captured,
			\\    coalesce((SELECT count(*) FROM mission_participants mp WHERE mp.mission_id = m.id AND mp.commended), 0) AS commended,
			\\    coalesce((SELECT count(*) FROM battles bt WHERE bt.mission_id = m.id), 0) AS battles,
			\\    (SELECT string_agg(bt.name, ', ' ORDER BY bt.started_at) FROM battles bt WHERE bt.mission_id = m.id) AS battle_names,
			\\    coalesce((SELECT count(*) FROM mission_reports mr WHERE mr.mission_id = m.id), 0) AS reports_filed,
			\\    m.code_name || ': ' || m.casualties_count || ' casualties, ' || m.ships_lost || ' ships lost' AS summary_line
			\\FROM missions m
			\\LEFT JOIN planets p ON p.id = m.target_planet_id
			\\LEFT JOIN characters c ON c.id = m.commander_id
			\\WHERE m.status IN ('completed', 'aborted', 'failed')
			\\  AND coalesce(m.completed_at, m.aborted_at) BETWEEN $from::timestamp AND $to::timestamp
			\\ORDER BY ended_at DESC
			,
			{ from, to },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["mission", id] => Str.inspect(Missions.mission!(Args.i32(id), db))
			["active"] => Str.inspect(Missions.active!(db))
			["search", text] => Str.inspect(Missions.search!(text, Err(Null), db))
			["search", text, status] => Str.inspect(Missions.search!(text, Ok(status), db))
			["planned", from, to] => Str.inspect(Missions.planned_between!(from, to, db))
			["stalled"] => Str.inspect(Missions.stalled!(db))
			["overdue"] => Str.inspect(Missions.overdue!(db))
			["unstaffed"] => Str.inspect(Missions.unstaffed!(db))
			["missions", .. as ids] => Str.inspect(Missions.by_ids!(List.map(ids, Args.i32), db))
			["create", code_name, objective, priority] => Str.inspect(Missions.create!(code_name, objective, Args.i32(priority), Err(Null), Err(Null), db))
			["approve", id, approved_by_id] => Str.inspect(Missions.approve!(Args.i32(id), Args.i32(approved_by_id), db))
			["launch", id] => Str.inspect(Missions.launch!(Args.i32(id), db))
			["debrief", id, lock_version, status, casualties, ships_lost, intel, score, spent, summary] =>
				Str.inspect(
					Missions.debrief!(
						{
							id: Args.i32(id),
							lock_version: Args.i32(lock_version),
							status,
							casualties_count: Args.i32(casualties),
							ships_lost: Args.i32(ships_lost),
							intel_gained: intel == "yes",
							success_score: Ok(Args.f64(score)),
							spent_credits: Args.i64(spent),
							debrief_summary: Ok(summary),
							lessons_learned: Err(Null),
							extraction_point: Err(Null),
							rendezvous_code: Err(Null),
						},
						db,
					),
				)
			["participants", mission_id] => Str.inspect(Missions.participants!(Args.i32(mission_id), db))
			["enlist", mission_id, character_id, role] => Str.inspect(Missions.enlist!(Args.i32(mission_id), Args.i32(character_id), role, Err(Null), db))
			["report", mission_id, author_id, body] => Str.inspect(Missions.add_report!(Args.i32(mission_id), Args.i32(author_id), body, db))
			["reports", mission_id] => Str.inspect(Missions.reports!(Args.i32(mission_id), db))
			["veterans", min_missions] => Str.inspect(Missions.veterans!(Args.i64(min_missions), db))
			["briefing", id] => Str.inspect(Missions.briefing!(Args.i32(id), db))
			["outcomes", from, to] => Str.inspect(Missions.outcomes!(from, to, db))
			_ => "unknown missions command"
		}
}
