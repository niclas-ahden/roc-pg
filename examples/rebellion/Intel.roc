import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Informant : {
	id : I32,
	code_name : Str,
	paid_credits : I64,
	burned : Bool,
	planet : Try(Str, [Null]),
}

ReportSummary : {
	id : I32,
	subject : Str,
	reliability : Str,
	received_at : Str,
	informant : Try(Str, [Null]),
	planet : Try(Str, [Null]),
}

Report : {
	id : I32,
	informant_id : Try(I32, [Null]),
	received_by_id : Try(I32, [Null]),
	planet_id : Try(I32, [Null]),
	mission_id : Try(I32, [Null]),
	subject : Str,
	body : Str,
	reliability : Str,
	received_at : Str,
	verified_at : Try(Str, [Null]),
	verified_by_id : Try(I32, [Null]),
	actionable : Bool,
	acted_on : Bool,
	clearance_required : I32,
}

InboxEntry : {
	id : I32,
	subject : Try(Str, [Null]),
	band : Str,
	priority : I32,
	sent_at : Str,
	sender : Str,
}

ReportDossier : {
	id : I32,
	subject : Str,
	body : Str,
	reliability : Str,
	received_at : Str,
	verified_at : Try(Str, [Null]),
	actionable : Bool,
	acted_on : Bool,
	clearance_required : I32,
	headline : Str,
	age_days : I32,
	state : Str,
	informant : Try(Str, [Null]),
	informant_burned : Bool,
	informant_paid : Try(I64, [Null]),
	planet : Try(Str, [Null]),
	planet_allegiance : Try(Str, [Null]),
	planet_threat : I32,
	mission : Try(Str, [Null]),
	mission_status : Try(Str, [Null]),
	received_by : Try(Str, [Null]),
	verified_by : Try(Str, [Null]),
	related_reports : Try(I64, [Null]),
	informant_previous_report : Try(Str, [Null]),
	informant_disinformation : Try(I64, [Null]),
}

TransmissionLogEntry : {
	id : I32,
	band : Str,
	priority : I32,
	subject : Try(Str, [Null]),
	preview : Str,
	sent_at : Str,
	sent_label : Str,
	expires_at : Try(Str, [Null]),
	intercepted : Bool,
	acknowledged : Bool,
	acknowledged_at : Try(Str, [Null]),
	sender : Str,
	sender_allegiance : Try(Str, [Null]),
	sender_flagged : Try(Bool, [Null]),
	recipient : Str,
	base : Try(Str, [Null]),
	key_label : Try(Str, [Null]),
	key_retired : Try(Bool, [Null]),
	frequency_khz : Try(I64, [Null]),
	minutes_to_ack : Try(Dec, [Null]),
	state : Str,
	relays : Try(I64, [Null]),
	last_relay_at : Try(Str, [Null]),
}

Intel := [].{
	informants! : Str, Db => Try(List(Informant), _)
	informants! = |text, db|
		db.query!(
			\\SELECT i.id, i.code_name, i.paid_credits, i.burned, p.name AS planet
			\\FROM informants i
			\\LEFT JOIN planets p ON p.id = i.planet_id
			\\WHERE i.code_name ILIKE $text || '%'
			\\ORDER BY i.burned, i.code_name
			,
			{ text, },
		)

	add_informant! : Str, Try(I32, [Null]), Db => Try({ id : I32 }, _)
	add_informant! = |code_name, planet_id, db|
		db.query_one!(
			\\INSERT INTO informants (code_name, planet_id, created_at, updated_at)
			\\VALUES ($code_name, $planet_id, now(), now())
			\\ON CONFLICT (code_name) DO UPDATE
			\\SET planet_id = excluded.planet_id, updated_at = now()
			\\RETURNING id
			,
			{ code_name, planet_id },
		)

	pay_informant! : I32, I64, Db => Try({ paid_credits : I64 }, _)
	pay_informant! = |id, credits, db|
		db.query_one!(
			\\UPDATE informants
			\\SET paid_credits = paid_credits + $credits, updated_at = now()
			\\WHERE id = $id AND NOT burned
			\\RETURNING paid_credits
			,
			{ id, credits },
		)

	recent_reports! : I32, Try(Str, [Null]), Db => Try(List(ReportSummary), _)
	recent_reports! = |days, reliability, db|
		db.query!(
			\\SELECT
			\\    r.id,
			\\    r.subject,
			\\    r.reliability,
			\\    r.received_at,
			\\    i.code_name AS informant,
			\\    p.name AS planet
			\\FROM intel_reports r
			\\LEFT JOIN informants i ON i.id = r.informant_id
			\\LEFT JOIN planets p ON p.id = r.planet_id
			\\WHERE r.received_at > now() - interval '1 day' * $days
			\\  AND ($reliability::text IS NULL OR r.reliability::text = $reliability)
			\\ORDER BY r.received_at DESC
			\\LIMIT 100
			,
			{ days, reliability },
		)

	report! : I32, Db => Try(Try(Report, [NotFound]), _)
	report! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    id,
			\\    informant_id,
			\\    received_by_id,
			\\    planet_id,
			\\    mission_id,
			\\    subject,
			\\    body,
			\\    reliability,
			\\    received_at,
			\\    verified_at,
			\\    verified_by_id,
			\\    actionable,
			\\    acted_on,
			\\    clearance_required
			\\FROM intel_reports
			\\WHERE id = $id
			,
			{ id, },
		)

	file_report! : Try(I32, [Null]), I32, Try(I32, [Null]), Str, Str, I32, Db => Try({ id : I32 }, _)
	file_report! = |informant_id, received_by_id, planet_id, subject, body, clearance_required, db|
		db.query_one!(
			\\INSERT INTO intel_reports (
			\\    informant_id,
			\\    received_by_id,
			\\    planet_id,
			\\    subject,
			\\    body,
			\\    clearance_required,
			\\    received_at,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES ($informant_id, $received_by_id, $planet_id, $subject, $body, $clearance_required, now(), now(), now())
			\\RETURNING id
			,
			{ informant_id, received_by_id, planet_id, subject, body, clearance_required },
		)

	verify_report! : I32, I32, Str, Db => Try(U64, _)
	verify_report! = |id, verified_by_id, reliability, db|
		db.execute!(
			\\UPDATE intel_reports
			\\SET reliability = $reliability::intel_reliability,
			\\    verified_at = now(),
			\\    verified_by_id = $verified_by_id,
			\\    actionable = $reliability::intel_reliability = 'confirmed',
			\\    updated_at = now()
			\\WHERE id = $id
			,
			{ id, verified_by_id, reliability },
		)

	actionable_reports! : Db => Try(List({ id : I32, subject : Str, clearance_required : I32, planet : Str }), _)
	actionable_reports! = |db|
		db.query!(
			\\SELECT r.id, r.subject, r.clearance_required, coalesce(p.name, 'unknown') AS planet
			\\FROM intel_reports r
			\\LEFT JOIN planets p ON p.id = r.planet_id
			\\WHERE r.actionable
			\\  AND NOT r.acted_on
			\\  AND r.reliability IN ('plausible', 'confirmed')
			\\ORDER BY r.clearance_required DESC, r.received_at
			,
			{},
		)

	inbox! : I32, Db => Try(List(InboxEntry), _)
	inbox! = |recipient_id, db|
		db.query!(
			\\SELECT
			\\    t.id,
			\\    t.subject,
			\\    t.band,
			\\    t.priority,
			\\    t.sent_at,
			\\    coalesce(c.callsign, c.name, 'unknown') AS sender
			\\FROM transmissions t
			\\LEFT JOIN characters c ON c.id = t.sender_id
			\\WHERE t.recipient_id = $recipient_id
			\\  AND NOT t.acknowledged
			\\  AND (t.expires_at IS NULL OR t.expires_at > now())
			\\ORDER BY t.priority DESC, t.sent_at
			,
			{ recipient_id, },
		)

	send_transmission! : I32, I32, Try(I32, [Null]), Str, Str, Str, I32, I32, Db => Try({ id : I32, sent_at : Str }, _)
	send_transmission! = |sender_id, recipient_id, base_id, band, subject, body, priority, expires_in_hours, db|
		db.query_one!(
			\\INSERT INTO transmissions (
			\\    sender_id,
			\\    recipient_id,
			\\    base_id,
			\\    band,
			\\    encryption_key_id,
			\\    subject,
			\\    body,
			\\    priority,
			\\    expires_at,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES (
			\\    $sender_id,
			\\    $recipient_id,
			\\    $base_id,
			\\    $band::transmission_band,
			\\    (SELECT id FROM encryption_keys WHERE retired_at IS NULL ORDER BY created_at DESC LIMIT 1),
			\\    $subject,
			\\    $body,
			\\    $priority,
			\\    now() + interval '1 hour' * $expires_in_hours,
			\\    now(),
			\\    now()
			\\)
			\\RETURNING id, sent_at
			,
			{ sender_id, recipient_id, base_id, band, subject, body, priority, expires_in_hours },
		)

	acknowledge! : List(I32), I32, Db => Try(U64, _)
	acknowledge! = |ids, recipient_id, db|
		db.execute!(
			\\UPDATE transmissions
			\\SET acknowledged = true, acknowledged_at = now(), updated_at = now()
			\\WHERE id = any($ids) AND recipient_id = $recipient_id
			,
			{ ids, recipient_id },
		)

	undelivered_holonet! : Db => Try(List({ id : I32, transmission_id : I32, subject : Try(Str, [Null]), created_at : Str }), _)
	undelivered_holonet! = |db|
		db.query!(
			\\SELECT h.id, h.transmission_id, t.subject, h.created_at
			\\FROM holonet_messages h
			\\JOIN transmissions t ON t.id = h.transmission_id
			\\WHERE h.delivered_at IS NULL
			\\ORDER BY h.created_at
			,
			{},
		)

	traffic_by_band! : Db => Try(List({ band : Str, total : I64, intercepted : I64 }), _)
	traffic_by_band! = |db|
		db.query!(
			\\SELECT band, count(*) AS total, count(*) FILTER (WHERE intercepted) AS intercepted
			\\FROM transmissions
			\\WHERE sent_at > now() - interval '7 days'
			\\GROUP BY band
			\\ORDER BY band
			,
			{},
		)

	report_dossier! : I32, I32, Db => Try(Try(ReportDossier, [NotFound]), _)
	report_dossier! = |id, clearance, db|
		db.query_optional!(
			\\SELECT
			\\    r.id,
			\\    r.subject,
			\\    r.body,
			\\    r.reliability,
			\\    r.received_at,
			\\    r.verified_at,
			\\    r.actionable,
			\\    r.acted_on,
			\\    r.clearance_required,
			\\    '[' || upper(r.reliability::text) || '] ' || r.subject AS headline,
			\\    current_date - r.received_at::date AS age_days,
			\\    CASE
			\\        WHEN r.acted_on THEN 'closed'
			\\        WHEN r.actionable AND r.received_at > now() - interval '2 days' THEN 'urgent'
			\\        WHEN r.actionable THEN 'open'
			\\        WHEN r.verified_at IS NULL THEN 'awaiting verification'
			\\        ELSE 'archived'
			\\    END AS state,
			\\    i.code_name AS informant,
			\\    coalesce(i.burned, false) AS informant_burned,
			\\    i.paid_credits AS informant_paid,
			\\    p.name AS planet,
			\\    p.allegiance AS planet_allegiance,
			\\    coalesce(p.threat_level, 0) AS planet_threat,
			\\    m.code_name AS mission,
			\\    m.status AS mission_status,
			\\    coalesce(rc.callsign, rc.name) AS received_by,
			\\    (SELECT v.name FROM characters v WHERE v.id = r.verified_by_id) AS verified_by,
			\\    (
			\\        SELECT count(*)
			\\        FROM intel_reports o
			\\        WHERE o.planet_id = r.planet_id
			\\          AND o.id <> r.id
			\\          AND o.received_at > r.received_at - interval '30 days'
			\\    ) AS related_reports,
			\\    (
			\\        SELECT max(o.received_at)
			\\        FROM intel_reports o
			\\        WHERE o.informant_id = r.informant_id AND o.id <> r.id
			\\    ) AS informant_previous_report,
			\\    (
			\\        SELECT count(*)
			\\        FROM intel_reports o
			\\        WHERE o.informant_id = r.informant_id AND o.reliability = 'disinformation'
			\\    ) AS informant_disinformation
			\\FROM intel_reports r
			\\LEFT JOIN informants i ON i.id = r.informant_id
			\\LEFT JOIN planets p ON p.id = r.planet_id
			\\LEFT JOIN missions m ON m.id = r.mission_id
			\\LEFT JOIN characters rc ON rc.id = r.received_by_id
			\\WHERE r.id = $id AND r.clearance_required <= $clearance
			,
			{ id, clearance },
		)

	transmission_log! : Try(I32, [Null]), I32, Db => Try(List(TransmissionLogEntry), _)
	transmission_log! = |recipient_id, days, db|
		db.query!(
			\\SELECT
			\\    t.id,
			\\    t.band,
			\\    t.priority,
			\\    t.subject,
			\\    left(coalesce(t.body, ''), 120) AS preview,
			\\    t.sent_at,
			\\    to_char(t.sent_at, 'YYYY-MM-DD HH24:MI') AS sent_label,
			\\    t.expires_at,
			\\    t.intercepted,
			\\    t.acknowledged,
			\\    t.acknowledged_at,
			\\    coalesce(s.callsign, s.name, 'unknown') AS sender,
			\\    s.allegiance AS sender_allegiance,
			\\    s.double_agent OR s.under_investigation AS sender_flagged,
			\\    coalesce(rc.callsign, rc.name, 'broadcast') AS recipient,
			\\    b.code_name AS base,
			\\    k.label AS key_label,
			\\    k.retired_at IS NOT NULL AS key_retired,
			\\    t.frequency_khz,
			\\    round((extract(epoch FROM t.acknowledged_at - t.sent_at::timestamp) / 60)::numeric, 1) AS minutes_to_ack,
			\\    CASE
			\\        WHEN t.expires_at < now() THEN 'expired'
			\\        WHEN t.acknowledged THEN 'read'
			\\        WHEN t.priority >= 5 THEN 'flash'
			\\        ELSE 'unread'
			\\    END AS state,
			\\    (SELECT count(*) FROM holonet_messages h WHERE h.transmission_id = t.id) AS relays,
			\\    (SELECT max(h.delivered_at) FROM holonet_messages h WHERE h.transmission_id = t.id) AS last_relay_at
			\\FROM transmissions t
			\\LEFT JOIN characters s ON s.id = t.sender_id
			\\LEFT JOIN characters rc ON rc.id = t.recipient_id
			\\LEFT JOIN bases b ON b.id = t.base_id
			\\LEFT JOIN encryption_keys k ON k.id = t.encryption_key_id
			\\WHERE ($recipient_id::integer IS NULL OR t.recipient_id = $recipient_id)
			\\  AND t.sent_at > now() - interval '1 day' * $days
			\\ORDER BY t.priority DESC, t.sent_at DESC
			\\LIMIT 200
			,
			{ recipient_id, days },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["dossier", id, clearance] => Str.inspect(Intel.report_dossier!(Args.i32(id), Args.i32(clearance), db))
			["log", days] => Str.inspect(Intel.transmission_log!(Err(Null), Args.i32(days), db))
			["log", days, recipient_id] => Str.inspect(Intel.transmission_log!(Ok(Args.i32(recipient_id)), Args.i32(days), db))
			["informants"] => Str.inspect(Intel.informants!("", db))
			["informants", text] => Str.inspect(Intel.informants!(text, db))
			["add-informant", code_name] => Str.inspect(Intel.add_informant!(code_name, Err(Null), db))
			["add-informant", code_name, planet_id] => Str.inspect(Intel.add_informant!(code_name, Ok(Args.i32(planet_id)), db))
			["pay", id, credits] => Str.inspect(Intel.pay_informant!(Args.i32(id), Args.i64(credits), db))
			["reports", days] => Str.inspect(Intel.recent_reports!(Args.i32(days), Err(Null), db))
			["reports", days, reliability] => Str.inspect(Intel.recent_reports!(Args.i32(days), Ok(reliability), db))
			["report", id] => Str.inspect(Intel.report!(Args.i32(id), db))
			["file-report", received_by_id, subject, body] => Str.inspect(Intel.file_report!(Err(Null), Args.i32(received_by_id), Err(Null), subject, body, 3, db))
			["verify", id, verified_by_id, reliability] => Str.inspect(Intel.verify_report!(Args.i32(id), Args.i32(verified_by_id), reliability, db))
			["actionable"] => Str.inspect(Intel.actionable_reports!(db))
			["inbox", recipient_id] => Str.inspect(Intel.inbox!(Args.i32(recipient_id), db))
			["send", sender_id, recipient_id, subject, body] => Str.inspect(Intel.send_transmission!(Args.i32(sender_id), Args.i32(recipient_id), Err(Null), "subspace", subject, body, 0, 24, db))
			["ack", recipient_id, .. as ids] => Str.inspect(Intel.acknowledge!(List.map(ids, Args.i32), Args.i32(recipient_id), db))
			["holonet"] => Str.inspect(Intel.undelivered_holonet!(db))
			["traffic"] => Str.inspect(Intel.traffic_by_band!(db))
			_ => "unknown intel command"
		}
}
