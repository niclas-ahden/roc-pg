import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Operator : {
	id : I32,
	character_id : Try(I32, [Null]),
	username : Str,
	email : Str,
	admin : Bool,
	clearance_level : I32,
	otp_enabled : Bool,
	failed_logins : I32,
	locked_at : Try(Str, [Null]),
	last_login_at : Try(Str, [Null]),
	time_zone : Str,
}

SessionOperator : {
	id : I32,
	username : Str,
	admin : Bool,
	clearance_level : I32,
}

AuditEntry : {
	id : I32,
	action : Str,
	ip : Try(Str, [Null]),
	occurred_at : Str,
	username : Try(Str, [Null]),
}

OperatorOverview : {
	id : I32,
	username : Str,
	admin : Bool,
	sessions : I64,
	last_action : Try(Str, [Null]),
}

OperatorProfile : {
	id : I32,
	username : Str,
	email : Str,
	display : Str,
	admin : Bool,
	clearance_level : I32,
	otp_enabled : Bool,
	failed_logins : I32,
	locked_at : Try(Str, [Null]),
	last_login_at : Try(Str, [Null]),
	last_login_ip : Try(Str, [Null]),
	password_changed_at : Try(Str, [Null]),
	password_age_days : Try(I32, [Null]),
	time_zone : Str,
	character_name : Try(Str, [Null]),
	character_handle : Try(Str, [Null]),
	rank : Try(Str, [Null]),
	base : Try(Str, [Null]),
	standing : Str,
	live_sessions : Try(I64, [Null]),
	actions_30d : Try(I64, [Null]),
	last_action_at : Try(Str, [Null]),
	last_action : Try(Str, [Null]),
	channels : Try(Str, [Null]),
	distinct_ips : Try(I64, [Null]),
	reset_pending : Try(Bool, [Null]),
}

SecurityReviewRow : {
	id : I32,
	username : Str,
	admin : Bool,
	clearance_level : I32,
	otp_enabled : Bool,
	failed_logins : I32,
	locked_at : Try(Str, [Null]),
	last_login_at : Try(Str, [Null]),
	last_login_ip : Try(Str, [Null]),
	character_name : Try(Str, [Null]),
	double_agent : Try(Bool, [Null]),
	under_investigation : Try(Bool, [Null]),
	character_active : Try(Bool, [Null]),
	days_since_login : Try(I32, [Null]),
	password_age_days : Try(I32, [Null]),
	actions : Try(I64, [Null]),
	failed_logins_recent : Try(I64, [Null]),
	session_ips : Try(I64, [Null]),
	latest_session_ip : Try(Str, [Null]),
	risk_score : I32,
	status : Str,
	clearance_mismatch : Bool,
}

Operators := [].{
	by_username! : Str, Db => Try(Try(Operator, [NotFound]), _)
	by_username! = |username, db|
		db.query_optional!(
			\\SELECT
			\\    id,
			\\    character_id,
			\\    username,
			\\    email,
			\\    admin,
			\\    clearance_level,
			\\    otp_enabled,
			\\    failed_logins,
			\\    locked_at,
			\\    last_login_at,
			\\    time_zone
			\\FROM operators
			\\WHERE username = $username
			,
			{ username, },
		)

	record_login! : I32, Str, Bool, Db => Try({ failed_logins : I32, locked_at : Try(Str, [Null]) }, _)
	record_login! = |id, ip, success, db|
		db.query_one!(
			\\UPDATE operators
			\\SET failed_logins = CASE WHEN $success THEN 0 ELSE failed_logins + 1 END,
			\\    locked_at = CASE WHEN NOT $success AND failed_logins >= 4 THEN now() ELSE locked_at END,
			\\    last_login_at = CASE WHEN $success THEN now() ELSE last_login_at END,
			\\    last_login_ip = CASE WHEN $success THEN $ip ELSE last_login_ip END,
			\\    updated_at = now()
			\\WHERE id = $id
			\\RETURNING failed_logins, locked_at
			,
			{ id, ip, success },
		)

	start_session! : I32, Str, Db => Try({ token : Str }, _)
	start_session! = |operator_id, ip, db|
		db.query_one!(
			\\INSERT INTO operator_sessions (operator_id, ip_address, created_at, updated_at)
			\\VALUES ($operator_id, $ip::inet, now(), now())
			\\RETURNING token
			,
			{ operator_id, ip },
		)

	session! : Str, Db => Try(Try(SessionOperator, [NotFound]), _)
	session! = |token, db|
		db.query_optional!(
			\\SELECT o.id, o.username, o.admin, o.clearance_level
			\\FROM operator_sessions s
			\\JOIN operators o ON o.id = s.operator_id
			\\WHERE s.token = $token
			\\  AND s.created_at > now() - interval '12 hours'
			\\  AND o.locked_at IS NULL
			,
			{ token, },
		)

	api_client! : Str, Db => Try(Try({ id : I32, name : Str, scopes : Str }, [NotFound]), _)
	api_client! = |token, db|
		db.query_optional!("SELECT id, name, scopes FROM api_clients WHERE token = $token AND revoked_at IS NULL", { token, })

	revoke_api_client! : I32, Db => Try(U64, _)
	revoke_api_client! = |id, db|
		db.execute!("UPDATE api_clients SET revoked_at = now(), updated_at = now() WHERE id = $id AND revoked_at IS NULL", { id, })

	subscribers! : Str, Db => Try(List({ id : I32, username : Str, email : Str }), _)
	subscribers! = |channel, db|
		db.query!(
			\\SELECT o.id, o.username, o.email
			\\FROM alert_subscriptions a
			\\JOIN operators o ON o.id = a.operator_id
			\\WHERE a.channel = $channel::alert_channel AND o.locked_at IS NULL
			\\ORDER BY o.username
			,
			{ channel, },
		)

	audit! : Try(I32, [Null]), Str, Try(Str, [Null]), Db => Try(U64, _)
	audit! = |operator_id, action, ip, db|
		db.execute!(
			\\INSERT INTO audit_events (operator_id, action, ip_address, created_at)
			\\VALUES ($operator_id, $action, $ip::inet, now())
			,
			{ operator_id, action, ip },
		)

	audit_trail! : Try(I32, [Null]), I32, Db => Try(List(AuditEntry), _)
	audit_trail! = |operator_id, days, db|
		db.query!(
			\\SELECT e.id, e.action, e.ip_address::text AS ip, e.occurred_at, o.username
			\\FROM audit_events e
			\\LEFT JOIN operators o ON o.id = e.operator_id
			\\WHERE ($operator_id::integer IS NULL OR e.operator_id = $operator_id)
			\\  AND e.occurred_at > now() - interval '1 day' * $days
			\\ORDER BY e.occurred_at DESC
			\\LIMIT 200
			,
			{ operator_id, days },
		)

	setting! : Str, Db => Try(Try({ value : Try(Str, [Null]) }, [NotFound]), _)
	setting! = |key, db|
		db.query_optional!(
			\\SELECT value
			\\FROM settings
			\\WHERE key = $key AND updated_at > now() - interval '1 second' * ttl_seconds
			,
			{ key, },
		)

	put_setting! : Str, Try(Str, [Null]), Db => Try(U64, _)
	put_setting! = |key, value, db|
		db.execute!(
			\\INSERT INTO settings (key, value, created_at, updated_at)
			\\VALUES ($key, $value, now(), now())
			\\ON CONFLICT (key) DO UPDATE SET value = excluded.value, updated_at = now()
			,
			{ key, value },
		)

	migrations! : I64, Db => Try(List({ version : Str }), _)
	migrations! = |limit, db|
		db.query!("SELECT version FROM schema_migrations ORDER BY version DESC LIMIT $limit", { limit, })

	overview! : Str, Db => Try(List(OperatorOverview), _)
	overview! = |text, db|
		db.query!(
			\\SELECT
			\\    o.id,
			\\    o.username,
			\\    o.admin,
			\\    coalesce((SELECT count(*) FROM operator_sessions s WHERE s.operator_id = o.id), 0) AS sessions,
			\\    (SELECT max(e.occurred_at) FROM audit_events e WHERE e.operator_id = o.id) AS last_action
			\\FROM operators o
			\\WHERE o.username ILIKE $text || '%'
			\\ORDER BY o.username
			,
			{ text, },
		)

	profile! : I32, Db => Try(Try(OperatorProfile, [NotFound]), _)
	profile! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    o.id,
			\\    o.username,
			\\    o.email,
			\\    o.username || ' <' || o.email || '>' AS display,
			\\    o.admin,
			\\    o.clearance_level,
			\\    o.otp_enabled,
			\\    o.failed_logins,
			\\    o.locked_at,
			\\    o.last_login_at,
			\\    o.last_login_ip,
			\\    o.password_changed_at,
			\\    current_date - o.password_changed_at::date AS password_age_days,
			\\    o.time_zone,
			\\    c.name AS character_name,
			\\    coalesce(c.callsign, c.alias) AS character_handle,
			\\    rk.title AS rank,
			\\    b.code_name AS base,
			\\    CASE
			\\        WHEN o.locked_at IS NOT NULL THEN 'locked'
			\\        WHEN o.admin AND NOT o.otp_enabled THEN 'admin without otp'
			\\        WHEN o.password_changed_at IS NULL OR o.password_changed_at < now() - interval '180 days' THEN 'password stale'
			\\        WHEN o.last_login_at < now() - interval '90 days' THEN 'dormant'
			\\        ELSE 'ok'
			\\    END AS standing,
			\\    (
			\\        SELECT count(*)
			\\        FROM operator_sessions s
			\\        WHERE s.operator_id = o.id AND s.created_at > now() - interval '12 hours'
			\\    ) AS live_sessions,
			\\    (
			\\        SELECT count(*)
			\\        FROM audit_events e
			\\        WHERE e.operator_id = o.id AND e.occurred_at > now() - interval '30 days'
			\\    ) AS actions_30d,
			\\    (SELECT max(e.occurred_at) FROM audit_events e WHERE e.operator_id = o.id) AS last_action_at,
			\\    (
			\\        SELECT e.action
			\\        FROM audit_events e
			\\        WHERE e.operator_id = o.id
			\\        ORDER BY e.occurred_at DESC
			\\        LIMIT 1
			\\    ) AS last_action,
			\\    (
			\\        SELECT string_agg(a.channel::text, ', ' ORDER BY a.channel)
			\\        FROM alert_subscriptions a
			\\        WHERE a.operator_id = o.id
			\\    ) AS channels,
			\\    (SELECT count(DISTINCT e.ip_address) FROM audit_events e WHERE e.operator_id = o.id) AS distinct_ips,
			\\    o.reset_token IS NOT NULL AND o.reset_sent_at > now() - interval '1 hour' AS reset_pending
			\\FROM operators o
			\\LEFT JOIN characters c ON c.id = o.character_id
			\\LEFT JOIN ranks rk ON rk.id = c.rank_id
			\\LEFT JOIN bases b ON b.id = c.base_id
			\\WHERE o.id = $id
			,
			{ id, },
		)

	security_review! : I32, Db => Try(List(SecurityReviewRow), _)
	security_review! = |days, db|
		db.query!(
			\\SELECT
			\\    o.id,
			\\    o.username,
			\\    o.admin,
			\\    o.clearance_level,
			\\    o.otp_enabled,
			\\    o.failed_logins,
			\\    o.locked_at,
			\\    o.last_login_at,
			\\    o.last_login_ip,
			\\    c.name AS character_name,
			\\    c.double_agent,
			\\    c.under_investigation,
			\\    c.active AS character_active,
			\\    current_date - o.last_login_at::date AS days_since_login,
			\\    current_date - o.password_changed_at::date AS password_age_days,
			\\    (
			\\        SELECT count(*)
			\\        FROM audit_events e
			\\        WHERE e.operator_id = o.id AND e.occurred_at > now() - interval '1 day' * $days
			\\    ) AS actions,
			\\    (
			\\        SELECT count(*)
			\\        FROM audit_events e
			\\        WHERE e.operator_id = o.id
			\\          AND e.action ILIKE 'login.fail%'
			\\          AND e.occurred_at > now() - interval '1 day' * $days
			\\    ) AS failed_logins_recent,
			\\    (
			\\        SELECT count(DISTINCT s.ip_address)
			\\        FROM operator_sessions s
			\\        WHERE s.operator_id = o.id AND s.created_at > now() - interval '1 day' * $days
			\\    ) AS session_ips,
			\\    (
			\\        SELECT host(s.ip_address)
			\\        FROM operator_sessions s
			\\        WHERE s.operator_id = o.id
			\\        ORDER BY s.created_at DESC
			\\        LIMIT 1
			\\    ) AS latest_session_ip,
			\\    (CASE WHEN o.admin AND NOT o.otp_enabled THEN 3 ELSE 0 END)
			\\        + (CASE WHEN o.failed_logins >= 3 THEN 2 ELSE 0 END)
			\\        + (CASE WHEN coalesce(c.double_agent, false) OR coalesce(c.under_investigation, false) THEN 5 ELSE 0 END)
			\\        + (CASE WHEN o.password_changed_at IS NULL OR o.password_changed_at < now() - interval '1 year' THEN 1 ELSE 0 END) AS risk_score,
			\\    CASE
			\\        WHEN o.locked_at IS NOT NULL THEN 'locked'
			\\        WHEN c.id IS NOT NULL AND NOT c.active THEN 'character inactive'
			\\        WHEN o.last_login_at IS NULL THEN 'never logged in'
			\\        ELSE 'active'
			\\    END AS status,
			\\    o.clearance_level > coalesce(c.clearance_level, 0) AS clearance_mismatch
			\\FROM operators o
			\\LEFT JOIN characters c ON c.id = o.character_id
			\\ORDER BY risk_score DESC, o.username
			,
			{ days, },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["profile", id] => Str.inspect(Operators.profile!(Args.i32(id), db))
			["security", days] => Str.inspect(Operators.security_review!(Args.i32(days), db))
			["show", username] => Str.inspect(Operators.by_username!(username, db))
			["login", id, ip, "ok"] => Str.inspect(Operators.record_login!(Args.i32(id), ip, Bool.True, db))
			["login", id, ip, _] => Str.inspect(Operators.record_login!(Args.i32(id), ip, Bool.False, db))
			["start-session", operator_id, ip] => Str.inspect(Operators.start_session!(Args.i32(operator_id), ip, db))
			["session", token] => Str.inspect(Operators.session!(token, db))
			["api-client", token] => Str.inspect(Operators.api_client!(token, db))
			["revoke-api-client", id] => Str.inspect(Operators.revoke_api_client!(Args.i32(id), db))
			["subscribers", channel] => Str.inspect(Operators.subscribers!(channel, db))
			["audit", action] => Str.inspect(Operators.audit!(Err(Null), action, Err(Null), db))
			["audit", operator_id, action, ip] => Str.inspect(Operators.audit!(Ok(Args.i32(operator_id)), action, Ok(ip), db))
			["trail", days] => Str.inspect(Operators.audit_trail!(Err(Null), Args.i32(days), db))
			["trail", days, operator_id] => Str.inspect(Operators.audit_trail!(Ok(Args.i32(operator_id)), Args.i32(days), db))
			["setting", key] => Str.inspect(Operators.setting!(key, db))
			["put-setting", key, value] => Str.inspect(Operators.put_setting!(key, Ok(value), db))
			["clear-setting", key] => Str.inspect(Operators.put_setting!(key, Err(Null), db))
			["migrations", limit] => Str.inspect(Operators.migrations!(Args.i64(limit), db))
			["overview"] => Str.inspect(Operators.overview!("", db))
			["overview", text] => Str.inspect(Operators.overview!(text, db))
			_ => "unknown operators command"
		}
}
