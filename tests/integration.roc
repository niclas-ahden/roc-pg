## Integration tests against a real Postgres server.
##
## Normally run by ./tests.roc, which boots a throwaway server and passes its
## address here. To point it at your own server:
##
##     roc tests/integration.roc <host> <port> <user> <database>
##
## Note that the password auth test expects the pg_hba rule ./tests.roc
## installs, so it fails against a server that trusts every connection.
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.23.0/7NpDhuqoqGFedmVLvmm1zjq37GCmaFGzwr5sz4ch9wTK.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.OsStr exposing [OsStr]
import pg.Client
import pg.Cmd
import pg.PgResult
import pg.Pool

effects = {
	connect!: Tcp.connect!,
	write!: Tcp.Stream.write!,
	read_exactly!: Tcp.Stream.read_exactly!,
	close!: Tcp.close!,
	pool!: Tcp.pool!,
	pool_acquire!: Tcp.pool_acquire!,
	pool_release!: Tcp.pool_release!,
}

main! : List(OsStr) => Try({}, _)
main! = |args| {
	server = 
		match args.drop_first(1) {
			[host_arg, port_arg, user_arg, database_arg] => {
				port = U16.from_str(OsStr.display(port_arg)) ? |_| InvalidPortArg
				Ok({ host: OsStr.display(host_arg), port, user: OsStr.display(user_arg), database: OsStr.display(database_arg) })
			}
			_ => Err(UsageArgs("host port user database"))
		}?

	client = Client.connect!(
		effects,
		{
			host: server.host,
			port: server.port,
			user: server.user,
			database: server.database,
			auth: NoAuth,
			timeout_ms: 5000,
		},
	)?
	Stdout.line!("ok: connect")?

	test_decoding!(client)?
	test_nulls!(client)?
	test_table_round_trip!(client)?
	test_error_recovery!(client)?
	test_commit_error!(client)?
	test_prepared!(client)?
	test_limit!(client)?
	test_password_auth!(server, client)?
	Client.close!(client)

	test_pool!(server)?
	test_dirty_release!(server)?

	Stdout.line!("all integration tests passed")?
	Ok({})
}

check : Str, Bool -> Try({}, [TestFailed(Str), ..])
check = |label, ok| if ok Ok({}) else Err(TestFailed(label))

## Every row accessor type against literal Postgres values.
test_decoding! = |client| {
	cmd = Cmd.new("select 'hello' as s, 250::int2 as small, -7::int as i, 9000000000::int8 as big, 2.5::float8 as f, 2.25::float4 as f4, 1.25::numeric as d, true as t, false as f2, 'raw'::bytea as b")
	result = Client.command!(cmd, client)?
	row = PgResult.decode_one(
		result,
		|r| {
			s = r.str("s")?
			small = r.u8("small")?
			i = r.i32("i")?
			big = r.i64("big")?
			f = r.f64("f")?
			f4 = r.f32("f4")?
			d = r.dec("d")?
			t = r.bool("t")?
			f2 = r.bool("f2")?
			b = r.bytes("b")?
			Ok({ s, small, i, big, f, f4, d, t, f2, b })
		},
	)?

	check("str", row.s == "hello")?
	check("u8", row.small == 250)?
	check("i32", row.i == -7)?
	check("i64", row.big == 9000000000)?
	check("f64", row.f == 2.5)?
	check("f32", row.f4 == 2.25)?
	check("dec", row.d == 1.25)?
	check("bool true", row.t)?
	check("bool false", row.f2 == Bool.False)?
	# bytea arrives in Postgres text format, hex encoded with a \x prefix
	check("bytes", row.b == "\\x726177".to_utf8())?
	Stdout.line!("ok: decoding")
}

## The nullable accessors return Null for NULL and Present otherwise.
test_nulls! = |client| {
	cmd = Cmd.new("select null::text as no_s, 'x' as yes_s, null::int as no_i, 5::int as yes_i, null::bool as no_b, true as yes_b, null::bytea as no_by, 'raw'::bytea as yes_by, null::int2 as no_u8, 250::int2 as yes_u8, null::int8 as no_u64, 9000000000::int8 as yes_u64")
	result = Client.command!(cmd, client)?
	row = PgResult.decode_one(
		result,
		|r| {
			no_s = r.str_nullable("no_s")?
			yes_s = r.str_nullable("yes_s")?
			no_i = r.i32_nullable("no_i")?
			yes_i = r.i32_nullable("yes_i")?
			no_b = r.bool_nullable("no_b")?
			yes_b = r.bool_nullable("yes_b")?
			no_by = r.bytes_nullable("no_by")?
			yes_by = r.bytes_nullable("yes_by")?
			no_u8 = r.u8_nullable("no_u8")?
			yes_u8 = r.u8_nullable("yes_u8")?
			no_u64 = r.u64_nullable("no_u64")?
			yes_u64 = r.u64_nullable("yes_u64")?
			Ok({ no_s, yes_s, no_i, yes_i, no_b, yes_b, no_by, yes_by, no_u8, yes_u8, no_u64, yes_u64 })
		},
	)?

	check("str_nullable null", row.no_s == Null)?
	check("str_nullable present", row.yes_s == Present("x"))?
	check("i32_nullable null", row.no_i == Null)?
	check("i32_nullable present", row.yes_i == Present(5))?
	check("bool_nullable null", row.no_b == Null)?
	check("bool_nullable present", row.yes_b == Present(Bool.True))?
	check("bytes_nullable null", row.no_by == Null)?
	# bytea arrives in Postgres text format, hex encoded with a \x prefix
	check("bytes_nullable present", row.yes_by == Present("\\x726177".to_utf8()))?
	check("u8_nullable null", row.no_u8 == Null)?
	check("u8_nullable present", row.yes_u8 == Present(250))?
	check("u64_nullable null", row.no_u64 == Null)?
	check("u64_nullable present", row.yes_u64 == Present(9000000000))?
	Stdout.line!("ok: nulls")
}

## DDL and DML: create a table, insert with bindings (including a NULL),
## and read the rows back.
test_table_round_trip! = |client| {
	_ = Client.command!(Cmd.new("create temp table people (name text not null, age int)"), client)?
	insert = Cmd.new("insert into people (name, age) values ($1, $2), ($3, $4)")
	_ = Client.command!(insert.bind([Cmd.str("John"), Cmd.u8(25), Cmd.str("Julio"), Cmd.null]), client)?

	result = Client.command!(Cmd.new("select name, age from people order by name"), client)?
	people = PgResult.decode(
		result,
		|r| {
			name = r.str("name")?
			age = r.i32_nullable("age")?
			Ok({ name, age })
		},
	)?

	check("table rows", people == [{ name: "John", age: Present(25) }, { name: "Julio", age: Null }])?
	Stdout.line!("ok: table round trip")
}

## A failing command must not desync the connection: the client drains the
## conversation to ReadyForQuery, so the next command still works.
test_error_recovery! = |client| {
	match Client.command!(Cmd.new("select nope from does_not_exist"), client) {
		Ok(_) => Err(TestFailed("query of missing table should fail"))
		Err(PgErr(error)) => check("error code", error.code == "42P01")
		Err(other) => Err(other)
	}?

	after_error = Client.command!(Cmd.new("select 1 as one"), client)?
	one = PgResult.decode_one(after_error, |r| r.i32("one"))?
	check("query after error", one == 1)?

	# The same drain applies to a failed prepare.
	match Client.prepare!("select syntax error (", { name: "broken", client }) {
		Ok(_) => Err(TestFailed("preparing broken sql should fail"))
		Err(PgErr(_)) => Ok({})
		Err(other) => Err(other)
	}?

	after_prepare_error = Client.command!(Cmd.new("select 2 as two"), client)?
	two = PgResult.decode_one(after_prepare_error, |r| r.i32("two"))?
	check("query after prepare error", two == 2)?
	Stdout.line!("ok: error recovery")
}

## A command can succeed and still end in an error: with a deferred
## constraint, Execute completes (CommandComplete) and the violation only
## surfaces at the implicit commit on Sync. command! must report that error,
## and the drain must leave the connection usable.
test_commit_error! = |client| {
	_ = Client.command!(Cmd.new("create temp table deferred_unique (i int unique deferrable initially deferred)"), client)?

	match Client.command!(Cmd.new("insert into deferred_unique values (1), (1)"), client) {
		Ok(_) => Err(TestFailed("deferred constraint violation should fail at commit"))
		Err(PgErr(error)) => check("commit error code", error.code == "23505")
		Err(other) => Err(other)
	}?

	after = Client.command!(Cmd.new("select 3 as three"), client)?
	three = PgResult.decode_one(after, |r| r.i32("three"))?
	check("query after commit error", three == 3)?
	Stdout.line!("ok: commit-time error")
}

## Prepared statements run many times with fresh bindings.
test_prepared! = |client| {
	add_cmd = Client.prepare!("select $1::int + $2::int as result", { name: "add", client })?

	first = Client.command!(add_cmd.bind([Cmd.i32(1), Cmd.i32(2)]), client)?
	first_sum = PgResult.decode_one(first, |r| r.i32("result"))?
	check("prepared first run", first_sum == 3)?

	second = Client.command!(add_cmd.bind([Cmd.i32(11), Cmd.i32(31)]), client)?
	second_sum = PgResult.decode_one(second, |r| r.i32("result"))?
	check("prepared second run", second_sum == 42)?

	# Re-preparing the same name replaces the old statement.
	sub_cmd = Client.prepare!("select $1::int - $2::int as result", { name: "add", client })?
	replaced = Client.command!(sub_cmd.bind([Cmd.i32(11), Cmd.i32(31)]), client)?
	replaced_result = PgResult.decode_one(replaced, |r| r.i32("result"))?
	check("prepared replaced", replaced_result == -20)?
	Stdout.line!("ok: prepared statements")
}

## Cmd.limit caps the rows the server sends back.
test_limit! = |client| {
	result = Client.command!(Cmd.new("select n from generate_series(1, 10) as t (n)").limit(3), client)?
	check("limit", PgResult.len(result) == 3)?
	Stdout.line!("ok: limit")
}

## The pool recycles authenticated connections and prepared statements keep
## working across checkouts.
test_pool! = |server| {
	pool = Pool.new!(
		effects,
		{
			host: server.host,
			port: server.port,
			user: server.user,
			database: server.database,
			auth: NoAuth,
			timeout_ms: 5000,
			max_connections: 2,
		},
	)

	client = Pool.acquire!(effects, pool)?
	first = Client.command!(Cmd.new("select 1 as one"), client)?
	first_one = PgResult.decode_one(first, |r| r.i32("one"))?
	check("pool first checkout", first_one == 1)?

	double_cmd = Client.prepare!("select $1::int * 2 as doubled", { name: "double", client })?
	Pool.release!(client)

	# The recycled connection is mid-session, no second handshake.
	client2 = Pool.acquire!(effects, pool)?
	doubled_result = Client.command!(double_cmd.bind([Cmd.i32(21)]), client2)?
	doubled = PgResult.decode_one(doubled_result, |r| r.i32("doubled"))?
	check("pool prepared across checkout", doubled == 42)?

	# A second concurrent checkout dials a fresh connection, and the prepared
	# statement transparently re-parses there (different backend).
	client3 = Pool.acquire!(effects, pool)?
	fresh_result = Client.command!(double_cmd.bind([Cmd.i32(4)]), client3)?
	fresh_doubled = PgResult.decode_one(fresh_result, |r| r.i32("doubled"))?
	check("pool prepared on fresh connection", fresh_doubled == 8)?

	Pool.release!(client2)
	Pool.release!(client3)
	Stdout.line!("ok: pool")
}

## A connection released mid-transaction must not leak the transaction into
## the next checkout: release! rolls the abandoned transaction back before
## pooling the connection.
test_dirty_release! = |server| {
	pool = Pool.new!(
		effects,
		{
			host: server.host,
			port: server.port,
			user: server.user,
			database: server.database,
			auth: NoAuth,
			timeout_ms: 5000,
			# One slot, so the next acquire gets exactly this session back.
			max_connections: 1,
		},
	)

	client = Pool.acquire!(effects, pool)?
	_ = Client.command!(Cmd.new("begin"), client)?
	_ = Client.command!(Cmd.new("create temp table dirty_probe (i int)"), client)?
	Pool.release!(client)

	# Had the transaction leaked, this checkout would still be inside it and
	# see its uncommitted temp table.
	client2 = Pool.acquire!(effects, pool)?
	check("released connection idle", Client.sync_status!(client2)? == Idle)?
	match Client.command!(Cmd.new("select i from dirty_probe"), client2) {
		Ok(_) => Err(TestFailed("abandoned transaction leaked into next checkout"))
		Err(PgErr(error)) => check("abandoned transaction rolled back", error.code == "42P01")
		Err(other) => Err(other)
	}?

	# Same for a transaction already in the failed state.
	_ = Client.command!(Cmd.new("begin"), client2)?
	match Client.command!(Cmd.new("select nope from does_not_exist"), client2) {
		Ok(_) => Err(TestFailed("query of missing table should fail"))
		Err(PgErr(_)) => Ok({})
		Err(other) => Err(other)
	}?
	Pool.release!(client2)

	client3 = Pool.acquire!(effects, pool)?
	check("failed transaction rolled back", Client.sync_status!(client3)? == Idle)?
	after = Client.command!(Cmd.new("select 4 as four"), client3)?
	four = PgResult.decode_one(after, |r| r.i32("four"))?
	check("query after failed transaction release", four == 4)?

	Pool.release!(client3)
	Stdout.line!("ok: dirty release")
}

## The cleartext password flow. ./tests.roc prepends a pg_hba rule that
## makes the server demand a password from this one user, so this test only
## passes on the throwaway server it boots (a `trust` server never sends a
## password challenge).
test_password_auth! = |server, admin| {
	_ = Client.command!(Cmd.new("drop user if exists roc_pg_password_test"), admin)?
	_ = Client.command!(Cmd.new("create user roc_pg_password_test password 'opensesame'"), admin)?

	authed = Client.connect!(
		effects,
		{
			host: server.host,
			port: server.port,
			user: "roc_pg_password_test",
			database: server.database,
			auth: Password("opensesame"),
			timeout_ms: 5000,
		},
	)?
	result = Client.command!(Cmd.new("select 1 as one"), authed)?
	one = PgResult.decode_one(result, |r| r.i32("one"))?
	check("query after password auth", one == 1)?
	Client.close!(authed)

	match
		Client.connect!(
			effects,
			{
				host: server.host,
				port: server.port,
				user: "roc_pg_password_test",
				database: server.database,
				auth: NoAuth,
				timeout_ms: 5000,
			},
		)
	{
		Ok(_) => Err(TestFailed("connecting without a password should fail"))
		Err(PasswordRequired) => Ok({})
		Err(other) => Err(other)
	}?

	match
		Client.connect!(
			effects,
			{
				host: server.host,
				port: server.port,
				user: "roc_pg_password_test",
				database: server.database,
				auth: Password("wrong"),
				timeout_ms: 5000,
			},
		)
	{
		Ok(_) => Err(TestFailed("a wrong password should fail"))
		# 28P01 is invalid_password
		Err(PgErr(error)) => check("wrong password code", error.code == "28P01")
		Err(other) => Err(other)
	}?
	Stdout.line!("ok: password auth")
}
