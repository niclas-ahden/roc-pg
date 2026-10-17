import pf.Tcp
import pg.Client
import Args
import Schema

Db : Client.Client(Tcp.Stream, Schema)

Smuggler : {
	id : I32,
	name : Str,
	commission_rate : Dec,
	trusted : Bool,
	owes_hutts : Bool,
	kessel_run_parsecs : Try(F64, [Null]),
	ship : Try(Str, [Null]),
}

SupplyItem : {
	id : I32,
	name : Str,
	category : Str,
	unit : Str,
	unit_cost : Try(Dec, [Null]),
	restricted : Bool,
}

NewRequest : {
	base_id : I32,
	requested_by_id : I32,
	approved_by_id : Try(I32, [Null]),
	status : Str,
	priority : I32,
	needed_by : Try(Str, [Null]),
	justification : Try(Str, [Null]),
	submitted_at : Try(Str, [Null]),
	approved_at : Try(Str, [Null]),
	rejected_at : Try(Str, [Null]),
	rejection_reason : Try(Str, [Null]),
	total_cost : I64,
	smuggler_id : Try(I32, [Null]),
	reference_code : Str,
}

RequestReport : {
	id : I32,
	reference_code : Str,
	status : Str,
	priority : I32,
	needed_by : Try(Str, [Null]),
	requested_by : Str,
	line_count : I64,
	quantity : I64,
	received : I64,
	damaged : I64,
	line_cost : Dec,
	any_backordered : Bool,
	shipments : I64,
	intercepted : I64,
	last_arrival : Try(Str, [Null]),
	schedule : Str,
}

RequestLine : {
	id : I32,
	item : Str,
	quantity : I32,
	quantity_shipped : I32,
	quantity_received : I32,
	unit_cost : Try(Dec, [Null]),
	backordered : Bool,
	substitute : Try(Str, [Null]),
}

NewShipment : {
	supply_request_id : I32,
	starship_id : Try(I32, [Null]),
	smuggler_id : Try(I32, [Null]),
	destination_base_id : I32,
	hyperspace_lane_id : Try(I32, [Null]),
	declared_value : Try(Dec, [Null]),
	manifest_code : Str,
}

InTransit : {
	id : I32,
	manifest_code : Str,
	departed_at : Try(Str, [Null]),
	destination : Str,
	ship : Try(Str, [Null]),
	lane : Try(Str, [Null]),
	late : Try(Bool, [Null]),
}

NewTransfer : {
	direction : Str,
	amount : Dec,
	counterparty : Str,
	character_id : Try(I32, [Null]),
	smuggler_id : Try(I32, [Null]),
	mission_id : Try(I32, [Null]),
	supply_request_id : Try(I32, [Null]),
	memo : Try(Str, [Null]),
	reference_code : Str,
}

LedgerEntry : {
	kind : Str,
	reference_code : Str,
	amount : Dec,
	counterparty : Str,
	created_at : Str,
}

Manifest : {
	id : I32,
	manifest_code : Str,
	tracking_code : Try(Str, [Null]),
	declared_value : Try(Dec, [Null]),
	departed_at : Try(Str, [Null]),
	arrived_at : Try(Str, [Null]),
	intercepted : Bool,
	jettisoned : Bool,
	reference_code : Str,
	request_status : Str,
	priority : I32,
	needed_by : Try(Str, [Null]),
	destination : Str,
	destination_code : Str,
	ship : Try(Str, [Null]),
	registry_code : Try(Str, [Null]),
	broadcast_transponder : Try(Str, [Null]),
	lane : Try(Str, [Null]),
	length_parsecs : Try(F64, [Null]),
	origin : Try(Str, [Null]),
	smuggler : Try(Str, [Null]),
	state : Str,
	slack_days : Try(I32, [Null]),
	lines : Try(I64, [Null]),
	units_shipped : Try(I64, [Null]),
	contents : Try(Str, [Null]),
	has_restricted : Try(Bool, [Null]),
}

Logistics := [].{
	smugglers! : Db => Try(List(Smuggler), _)
	smugglers! = |db|
		db.query!(
			\\SELECT
			\\    sm.id,
			\\    c.name,
			\\    sm.commission_rate,
			\\    sm.trusted,
			\\    sm.owes_hutts,
			\\    sm.kessel_run_parsecs,
			\\    st.name AS ship
			\\FROM smugglers sm
			\\JOIN characters c ON c.id = sm.character_id
			\\LEFT JOIN starships st ON st.id = sm.starship_id
			\\ORDER BY sm.trusted DESC, c.name
			,
			{},
		)

	trust_smuggler! : I32, Bool, Db => Try(U64, _)
	trust_smuggler! = |id, trusted, db|
		db.execute!("UPDATE smugglers SET trusted = $trusted, updated_at = now() WHERE id = $id", { id, trusted })

	supply_items! : Str, Db => Try(List(SupplyItem), _)
	supply_items! = |text, db|
		db.query!(
			\\SELECT id, name, category, unit, unit_cost, restricted
			\\FROM supply_items
			\\WHERE name ILIKE '%' || $text || '%' OR category ILIKE '%' || $text || '%'
			\\ORDER BY category, name
			,
			{ text, },
		)

	upsert_item! : Str, Str, Str, Try(Dec, [Null]), Db => Try({ id : I32 }, _)
	upsert_item! = |name, category, unit, unit_cost, db|
		db.query_one!(
			\\INSERT INTO supply_items (name, category, unit, unit_cost, created_at, updated_at)
			\\VALUES ($name, $category, $unit, $unit_cost, now(), now())
			\\ON CONFLICT (name) DO UPDATE
			\\SET category = excluded.category,
			\\    unit = excluded.unit,
			\\    unit_cost = excluded.unit_cost,
			\\    updated_at = now()
			\\RETURNING id
			,
			{ name, category, unit, unit_cost },
		)

	create_request! : NewRequest, Db => Try({ id : I32, status : Str }, _)
	create_request! = |request, db|
		db.query_one!(
			\\INSERT INTO supply_requests (
			\\    base_id,
			\\    requested_by_id,
			\\    approved_by_id,
			\\    status,
			\\    priority,
			\\    needed_by,
			\\    justification,
			\\    submitted_at,
			\\    approved_at,
			\\    rejected_at,
			\\    rejection_reason,
			\\    total_cost,
			\\    smuggler_id,
			\\    reference_code,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES (
			\\    $base_id,
			\\    $requested_by_id,
			\\    $approved_by_id,
			\\    $status::supply_request_status,
			\\    $priority,
			\\    $needed_by::date,
			\\    $justification,
			\\    $submitted_at::timestamp,
			\\    $approved_at::timestamp,
			\\    $rejected_at::timestamp,
			\\    $rejection_reason,
			\\    $total_cost,
			\\    $smuggler_id,
			\\    $reference_code,
			\\    now(),
			\\    now()
			\\)
			\\RETURNING id, status
			,
			request,
		)

	request_report! : I32, Db => Try(List(RequestReport), _)
	request_report! = |base_id, db|
		db.query!(
			\\WITH line_totals AS (
			\\    SELECT
			\\        l.supply_request_id,
			\\        count(*) AS line_count,
			\\        coalesce(sum(l.quantity), 0) AS quantity,
			\\        coalesce(sum(l.quantity_received), 0) AS received,
			\\        coalesce(sum(l.damaged_count), 0) AS damaged,
			\\        coalesce(sum(l.quantity * l.unit_cost), 0) AS line_cost,
			\\        bool_or(l.backordered) AS any_backordered
			\\    FROM supply_request_lines l
			\\    GROUP BY l.supply_request_id
			\\),
			\\shipment_totals AS (
			\\    SELECT
			\\        s.supply_request_id,
			\\        count(*) AS shipments,
			\\        count(*) FILTER (WHERE s.intercepted) AS intercepted,
			\\        max(s.arrived_at) AS last_arrival
			\\    FROM shipments s
			\\    GROUP BY s.supply_request_id
			\\)
			\\SELECT
			\\    r.id,
			\\    r.reference_code,
			\\    r.status,
			\\    r.priority,
			\\    r.needed_by,
			\\    c.name AS requested_by,
			\\    coalesce(lt.line_count, 0) AS line_count,
			\\    coalesce(lt.quantity, 0) AS quantity,
			\\    coalesce(lt.received, 0) AS received,
			\\    coalesce(lt.damaged, 0) AS damaged,
			\\    coalesce(lt.line_cost, 0) AS line_cost,
			\\    coalesce(lt.any_backordered, false) AS any_backordered,
			\\    coalesce(st.shipments, 0) AS shipments,
			\\    coalesce(st.intercepted, 0) AS intercepted,
			\\    st.last_arrival,
			\\    CASE
			\\        WHEN r.delivered_at IS NOT NULL THEN 'delivered'
			\\        WHEN r.needed_by IS NULL THEN 'no deadline'
			\\        WHEN r.needed_by < current_date THEN 'overdue'
			\\        ELSE 'on time'
			\\    END AS schedule
			\\FROM supply_requests r
			\\JOIN characters c ON c.id = r.requested_by_id
			\\LEFT JOIN line_totals lt ON lt.supply_request_id = r.id
			\\LEFT JOIN shipment_totals st ON st.supply_request_id = r.id
			\\WHERE r.base_id = $base_id AND r.archived_at IS NULL
			\\ORDER BY r.priority, r.needed_by NULLS LAST
			,
			{ base_id, },
		)

	request_lines! : I32, Db => Try(List(RequestLine), _)
	request_lines! = |supply_request_id, db|
		db.query!(
			\\SELECT
			\\    l.id,
			\\    i.name AS item,
			\\    l.quantity,
			\\    l.quantity_shipped,
			\\    l.quantity_received,
			\\    l.unit_cost,
			\\    l.backordered,
			\\    sub.name AS substitute
			\\FROM supply_request_lines l
			\\JOIN supply_items i ON i.id = l.supply_item_id
			\\LEFT JOIN supply_items sub ON sub.id = l.substitute_item_id
			\\WHERE l.supply_request_id = $supply_request_id
			\\ORDER BY i.name
			,
			{ supply_request_id, },
		)

	add_line! : I32, I32, I32, Db => Try({ id : I32 }, _)
	add_line! = |supply_request_id, supply_item_id, quantity, db|
		db.query_one!(
			\\INSERT INTO supply_request_lines (supply_request_id, supply_item_id, quantity, unit_cost, created_at, updated_at)
			\\SELECT $supply_request_id::integer, i.id, $quantity::integer, i.unit_cost, now(), now()
			\\FROM supply_items i
			\\WHERE i.id = $supply_item_id
			\\RETURNING id
			,
			{ supply_request_id, supply_item_id, quantity },
		)

	approve! : I32, I32, I32, Db => Try(U64, _)
	approve! = |id, approved_by_id, lock_version, db|
		db.execute!(
			\\UPDATE supply_requests
			\\SET status = 'approved',
			\\    approved_by_id = $approved_by_id,
			\\    approved_at = now(),
			\\    lock_version = lock_version + 1,
			\\    updated_at = now()
			\\WHERE id = $id AND status = 'submitted' AND lock_version = $lock_version
			,
			{ id, approved_by_id, lock_version },
		)

	reject! : I32, Str, Db => Try(U64, _)
	reject! = |id, reason, db|
		db.execute!(
			\\UPDATE supply_requests
			\\SET status = 'rejected',
			\\    rejected_at = now(),
			\\    rejection_reason = $reason,
			\\    lock_version = lock_version + 1,
			\\    updated_at = now()
			\\WHERE id = $id AND status IN ('submitted', 'approved')
			,
			{ id, reason },
		)

	dispatch! : NewShipment, Db => Try({ id : I32 }, _)
	dispatch! = |shipment, db|
		db.query_one!(
			\\INSERT INTO shipments (
			\\    supply_request_id,
			\\    starship_id,
			\\    smuggler_id,
			\\    destination_base_id,
			\\    hyperspace_lane_id,
			\\    declared_value,
			\\    manifest_code,
			\\    departed_at,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES ($supply_request_id, $starship_id, $smuggler_id, $destination_base_id, $hyperspace_lane_id, $declared_value, $manifest_code, now(), now(), now())
			\\RETURNING id
			,
			shipment,
		)

	receive! : I32, Db => Try({ supply_request_id : I32 }, _)
	receive! = |id, db|
		db.query_one!(
			\\UPDATE shipments
			\\SET arrived_at = now(), updated_at = now()
			\\WHERE id = $id AND arrived_at IS NULL
			\\RETURNING supply_request_id
			,
			{ id, },
		)

	in_transit! : Db => Try(List(InTransit), _)
	in_transit! = |db|
		db.query!(
			\\SELECT
			\\    s.id,
			\\    s.manifest_code,
			\\    s.departed_at,
			\\    b.name AS destination,
			\\    st.name AS ship,
			\\    l.name AS lane,
			\\    s.departed_at < now() - interval '3 days' AS late
			\\FROM shipments s
			\\JOIN bases b ON b.id = s.destination_base_id
			\\LEFT JOIN starships st ON st.id = s.starship_id
			\\LEFT JOIN hyperspace_lanes l ON l.id = s.hyperspace_lane_id
			\\WHERE s.arrived_at IS NULL AND NOT s.intercepted
			\\ORDER BY s.departed_at
			,
			{},
		)

	record_transfer! : NewTransfer, Db => Try(U64, _)
	record_transfer! = |transfer, db|
		db.execute!(
			\\INSERT INTO credit_transfers (
			\\    direction,
			\\    amount,
			\\    counterparty,
			\\    character_id,
			\\    smuggler_id,
			\\    mission_id,
			\\    supply_request_id,
			\\    memo,
			\\    reference_code,
			\\    created_at,
			\\    updated_at
			\\)
			\\VALUES ($direction, $amount, $counterparty, $character_id, $smuggler_id, $mission_id, $supply_request_id, $memo, $reference_code, now(), now())
			\\ON CONFLICT (reference_code) DO NOTHING
			,
			transfer,
		)

	ledger! : Str, Str, Db => Try(List(LedgerEntry), _)
	ledger! = |from_date, to_date, db|
		db.query!(
			\\SELECT 'credit' AS kind, reference_code, amount, counterparty, created_at
			\\FROM credit_transfers
			\\WHERE direction = 'incoming' AND created_at >= $from_date::date AND created_at < $to_date::date
			\\UNION ALL
			\\SELECT 'debit' AS kind, reference_code, -amount AS amount, counterparty, created_at
			\\FROM credit_transfers
			\\WHERE direction = 'outgoing' AND created_at >= $from_date::date AND created_at < $to_date::date
			\\ORDER BY created_at
			,
			{ from_date, to_date },
		)

	balance! : Db => Try({ summary : Str }, _)
	balance! = |db|
		db.query_one!(
			\\SELECT json_build_object(
			\\    'incoming', coalesce(sum(amount) FILTER (WHERE direction = 'incoming'), 0),
			\\    'outgoing', coalesce(sum(amount) FILTER (WHERE direction = 'outgoing'), 0),
			\\    'laundered', count(*) FILTER (WHERE laundered)
			\\) AS summary
			\\FROM credit_transfers
			\\WHERE cleared_at IS NOT NULL
			,
			{},
		)

	delete_draft_lines! : I32, Db => Try(U64, _)
	delete_draft_lines! = |supply_request_id, db|
		db.execute!(
			\\DELETE FROM supply_request_lines
			\\WHERE supply_request_id = $supply_request_id
			\\  AND EXISTS (SELECT 1 FROM supply_requests r WHERE r.id = $supply_request_id AND r.status = 'draft')
			,
			{ supply_request_id, },
		)

	manifest! : I32, Db => Try(Try(Manifest, [NotFound]), _)
	manifest! = |id, db|
		db.query_optional!(
			\\SELECT
			\\    s.id,
			\\    s.manifest_code,
			\\    s.tracking_code,
			\\    s.declared_value,
			\\    s.departed_at,
			\\    s.arrived_at,
			\\    s.intercepted,
			\\    s.jettisoned,
			\\    r.reference_code,
			\\    r.status AS request_status,
			\\    r.priority,
			\\    r.needed_by,
			\\    b.name AS destination,
			\\    b.code_name AS destination_code,
			\\    st.name AS ship,
			\\    st.registry_code,
			\\    coalesce(st.false_transponder_code, st.transponder_code) AS broadcast_transponder,
			\\    l.name AS lane,
			\\    l.length_parsecs,
			\\    (SELECT p.name FROM planets p WHERE p.id = s.origin_planet_id) AS origin,
			\\    (
			\\        SELECT c.name
			\\        FROM smugglers sm
			\\        JOIN characters c ON c.id = sm.character_id
			\\        WHERE sm.id = s.smuggler_id
			\\    ) AS smuggler,
			\\    CASE
			\\        WHEN s.intercepted THEN 'intercepted'
			\\        WHEN s.jettisoned THEN 'jettisoned'
			\\        WHEN s.arrived_at IS NOT NULL THEN 'arrived'
			\\        WHEN s.departed_at IS NULL THEN 'loading'
			\\        WHEN r.needed_by < current_date THEN 'late'
			\\        ELSE 'in transit'
			\\    END AS state,
			\\    r.needed_by - s.departed_at::date AS slack_days,
			\\    (SELECT count(*) FROM supply_request_lines li WHERE li.supply_request_id = r.id) AS lines,
			\\    (
			\\        SELECT coalesce(sum(li.quantity_shipped), 0)
			\\        FROM supply_request_lines li
			\\        WHERE li.supply_request_id = r.id
			\\    ) AS units_shipped,
			\\    (
			\\        SELECT string_agg(i.name || ' x' || li.quantity, ', ' ORDER BY i.name)
			\\        FROM supply_request_lines li
			\\        JOIN supply_items i ON i.id = li.supply_item_id
			\\        WHERE li.supply_request_id = r.id
			\\    ) AS contents,
			\\    (
			\\        SELECT bool_or(i.restricted)
			\\        FROM supply_request_lines li
			\\        JOIN supply_items i ON i.id = li.supply_item_id
			\\        WHERE li.supply_request_id = r.id
			\\    ) AS has_restricted
			\\FROM shipments s
			\\JOIN supply_requests r ON r.id = s.supply_request_id
			\\JOIN bases b ON b.id = s.destination_base_id
			\\LEFT JOIN starships st ON st.id = s.starship_id
			\\LEFT JOIN hyperspace_lanes l ON l.id = s.hyperspace_lane_id
			\\WHERE s.id = $id
			,
			{ id, },
		)

	run! : List(Str), Db => Str
	run! = |args, db|
		match args {
			["manifest", id] => Str.inspect(Logistics.manifest!(Args.i32(id), db))
			["smugglers"] => Str.inspect(Logistics.smugglers!(db))
			["trust", id] => Str.inspect(Logistics.trust_smuggler!(Args.i32(id), Bool.True, db))
			["distrust", id] => Str.inspect(Logistics.trust_smuggler!(Args.i32(id), Bool.False, db))
			["items", text] => Str.inspect(Logistics.supply_items!(text, db))
			["upsert-item", name, category, unit, unit_cost] => Str.inspect(Logistics.upsert_item!(name, category, unit, Ok(Args.dec(unit_cost)), db))
			["request", base_id, requested_by_id, reference_code] =>
				Str.inspect(
					Logistics.create_request!(
						{
							base_id: Args.i32(base_id),
							requested_by_id: Args.i32(requested_by_id),
							approved_by_id: Err(Null),
							status: "draft",
							priority: 3,
							needed_by: Err(Null),
							justification: Err(Null),
							submitted_at: Err(Null),
							approved_at: Err(Null),
							rejected_at: Err(Null),
							rejection_reason: Err(Null),
							total_cost: 0,
							smuggler_id: Err(Null),
							reference_code,
						},
						db,
					),
				)

			["report", base_id] => Str.inspect(Logistics.request_report!(Args.i32(base_id), db))
			["lines", request_id] => Str.inspect(Logistics.request_lines!(Args.i32(request_id), db))
			["add-line", request_id, item_id, quantity] => Str.inspect(Logistics.add_line!(Args.i32(request_id), Args.i32(item_id), Args.i32(quantity), db))
			["approve", id, approved_by_id, lock_version] => Str.inspect(Logistics.approve!(Args.i32(id), Args.i32(approved_by_id), Args.i32(lock_version), db))
			["reject", id, reason] => Str.inspect(Logistics.reject!(Args.i32(id), reason, db))
			["dispatch", request_id, base_id, manifest_code] =>
				Str.inspect(
					Logistics.dispatch!(
						{
							supply_request_id: Args.i32(request_id),
							starship_id: Err(Null),
							smuggler_id: Err(Null),
							destination_base_id: Args.i32(base_id),
							hyperspace_lane_id: Err(Null),
							declared_value: Err(Null),
							manifest_code,
						},
						db,
					),
				)

			["receive", id] => Str.inspect(Logistics.receive!(Args.i32(id), db))
			["in-transit"] => Str.inspect(Logistics.in_transit!(db))
			["transfer", direction, amount, counterparty, reference_code] =>
				Str.inspect(
					Logistics.record_transfer!(
						{
							direction,
							amount: Args.dec(amount),
							counterparty,
							character_id: Err(Null),
							smuggler_id: Err(Null),
							mission_id: Err(Null),
							supply_request_id: Err(Null),
							memo: Err(Null),
							reference_code,
						},
						db,
					),
				)

			["ledger", from_date, to_date] => Str.inspect(Logistics.ledger!(from_date, to_date, db))
			["balance"] => Str.inspect(Logistics.balance!(db))
			["delete-draft-lines", request_id] => Str.inspect(Logistics.delete_draft_lines!(Args.i32(request_id), db))
			_ => "unknown logistics command"
		}
}
