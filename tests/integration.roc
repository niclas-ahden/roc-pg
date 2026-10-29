## Integration tests of a single client against a real Postgres server.
##
## Normally run by ./tests.roc, which boots a throwaway server and passes its
## address here. To point it at your own server:
##
##     roc tests/integration.roc <host> <port> <user> <database>
##
## Note that the password auth test expects the pg_hba rule ./tests.roc
## installs, so it fails against a server that trusts every connection.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Duration
import pf.OsStr
import pf.Random
import pg.Client
import pg.Param
import pg.Statement
import pg.PgResult
import pg.NoSchema

## Dial the test server. No statement here runs for long, so five seconds
## for the dial and each read or write is plenty, and the tests connect
## without a statement timeout unless they test one.
## The client every test gets. The tests run unchecked queries only, so
## it has no schema.
Db : Client.Client(Tcp.Connection, NoSchema)

dial! = |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(5) })

main! : List(OsStr) => Try({}, _)
main! = |args| {
	server =
		match args {
			[host_arg, port_arg, user_arg, database_arg] => {
				port_num = U16.from_str(OsStr.display(port_arg)) ? |_| InvalidPortArg
				Ok({ host: OsStr.display(host_arg), port: port_num, user: OsStr.display(user_arg), database: OsStr.display(database_arg) })
			}
			_ => Err(UsageArgs("host port user database"))
		}?

	client = Client.connect!(
		{
			connect!: dial!,
			random_u64!: Random.seed_u64!,
			host: server.host,
			port: server.port,
			user: server.user,
			database: server.database,
			auth: NoAuth,
			statement_timeout: Duration.zero,
		},
	)?
	Stdout.line!("ok: connect")?

	test_decoding!(client)?
	test_bytea_round_trip!(client)?
	test_nulls!(client)?
	test_table_round_trip!(client)?
	test_error_recovery!(client)?
	test_commit_error!(client)?
	test_prepared!(client)?
	test_transaction!(client)?
	test_transaction_aborted!(client)?
	test_nested_transactions!(client)?
	test_nested_transactions_quiet!(client)?
	test_execute_counts!(client)?
	test_pipeline!(client)?
	test_batch_execute!(client)?
	test_query_one!(client)?
	test_query_optional!(client)?
	test_arrays!(client)?
	test_enums!(client)?
	test_password_auth!(server, client)?
	test_md5_and_scram!(server, client)?
	test_scram_passwords!(server, client)?
	test_connect_url!(server)?
	test_nul_bytes!(server, client)?
	test_fatal_error!(server)?
	test_commit_refused!(client)?
	test_statement_timeout!(server)?
	test_prepared_elsewhere!(server, client)?
	test_param_not_allowed!(server)?
	test_startup_last_value_wins!(server)?
	test_notifications_skipped!(client)?
	client.close!()

	Stdout.line!("all integration tests passed")?
	Ok({})
}

check : Str, Bool -> Try({}, [TestFailed(Str)])
check = |label, ok| if ok Ok({}) else Err(TestFailed(label))

## Every row accessor type against literal Postgres values.
test_decoding! : Db => Try({}, _)
test_decoding! = |client| {
	cmd = Statement.new_unchecked("select 'hello' as s, 250::int2 as small, -7::int as i, 9000000000::int8 as big, 2.5::float8 as f, 2.25::float4 as f4, 1.25::numeric as d, true as t, false as f2, 'raw'::bytea as b")
	result = client.command!(cmd)?
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
	# bytea arrives as hex text (\x726177) and is decoded to its bytes
	check("bytes", row.b == "raw".to_utf8())?
	Stdout.line!("ok: decoding")
}

## Bytes sent with Param.bytes come back from row.bytes as they went, every
## value from 0 to 255 included.
test_bytea_round_trip! : Db => Try({}, _)
test_bytea_round_trip! = |client| {
	sent = List.repeat({}, 256).map_with_index(|_, n| n.to_u8_wrap())
	back = client.query_one_unchecked!("select $1::bytea as b", [Param.bytes(sent)], |row| row.bytes("b"))?
	check("bytea round trip", back == sent)?
	Stdout.line!("ok: bytea round trip")
}

## The nullable accessors return Null for NULL and Present otherwise.
test_nulls! : Db => Try({}, _)
test_nulls! = |client| {
	cmd = Statement.new_unchecked("select null::text as no_s, 'x' as yes_s, null::int as no_i, 5::int as yes_i, null::bool as no_b, true as yes_b, null::bytea as no_by, 'raw'::bytea as yes_by, null::int2 as no_u8, 250::int2 as yes_u8, null::int8 as no_u64, 9000000000::int8 as yes_u64")
	result = client.command!(cmd)?
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
	# bytea arrives as hex text and is decoded to its bytes
	check("bytes_nullable present", row.yes_by == Present("raw".to_utf8()))?
	check("u8_nullable null", row.no_u8 == Null)?
	check("u8_nullable present", row.yes_u8 == Present(250))?
	check("u64_nullable null", row.no_u64 == Null)?
	check("u64_nullable present", row.yes_u64 == Present(9000000000))?
	Stdout.line!("ok: nulls")
}

## DDL and DML: create a table, insert with bindings (including a NULL),
## and read the rows back.
test_table_round_trip! : Db => Try({}, _)
test_table_round_trip! = |client| {
	_ = client.command!(Statement.new_unchecked("create temp table people (name text not null, age int)"))?
	insert = Statement.new_unchecked("insert into people (name, age) values ($1, $2), ($3, $4)")
	_ = client.command!(insert.bind([Param.str("John"), Param.u8(25), Param.str("Julio"), Param.null]))?

	result = client.command!(Statement.new_unchecked("select name, age from people order by name"))?
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
test_error_recovery! : Db => Try({}, _)
test_error_recovery! = |client| {
	match client.command!(Statement.new_unchecked("select nope from does_not_exist")) {
		Ok(_) => Err(TestFailed("query of missing table should fail"))
		Err(PgErr(error)) => check("error code", error.code == "42P01")
		Err(other) => Err(other)
	}?

	after_error = client.command!(Statement.new_unchecked("select 1 as one"))?
	one = PgResult.decode_one(after_error, |r| r.i32("one"))?
	check("query after error", one == 1)?

	# The same drain applies to a failed prepare.
	match client.prepare_unchecked!("select syntax error (", { name: "broken" }) {
		Ok(_) => Err(TestFailed("preparing broken sql should fail"))
		Err(PgErr(_)) => Ok({})
		Err(other) => Err(other)
	}?

	after_prepare_error = client.command!(Statement.new_unchecked("select 2 as two"))?
	two = PgResult.decode_one(after_prepare_error, |r| r.i32("two"))?
	check("query after prepare error", two == 2)?
	Stdout.line!("ok: error recovery")
}

## A command can succeed and still end in an error: with a deferred
## constraint, Execute completes (CommandComplete) and the violation only
## surfaces at the implicit commit on Sync. command! must report that error,
## and the drain must leave the connection usable.
test_commit_error! : Db => Try({}, _)
test_commit_error! = |client| {
	_ = client.command!(Statement.new_unchecked("create temp table deferred_unique (i int unique deferrable initially deferred)"))?

	match client.command!(Statement.new_unchecked("insert into deferred_unique values (1), (1)")) {
		Ok(_) => Err(TestFailed("deferred constraint violation should fail at commit"))
		Err(PgErr(error)) => check("commit error code", error.code == "23505")
		Err(other) => Err(other)
	}?

	after = client.command!(Statement.new_unchecked("select 3 as three"))?
	three = PgResult.decode_one(after, |r| r.i32("three"))?
	check("query after commit error", three == 3)?
	Stdout.line!("ok: commit-time error")
}

## Prepared statements run many times with fresh bindings.
test_prepared! : Db => Try({}, _)
test_prepared! = |client| {
	add_cmd = client.prepare_unchecked!("select $1::int + $2::int as result", { name: "add" })?

	first = client.command!(add_cmd.bind([Param.i32(1), Param.i32(2)]))?
	first_sum = PgResult.decode_one(first, |r| r.i32("result"))?
	check("prepared first run", first_sum == 3)?

	second = client.command!(add_cmd.bind([Param.i32(11), Param.i32(31)]))?
	second_sum = PgResult.decode_one(second, |r| r.i32("result"))?
	check("prepared second run", second_sum == 42)?

	# Re-preparing the same name replaces the old statement.
	sub_cmd = client.prepare_unchecked!("select $1::int - $2::int as result", { name: "add" })?
	replaced = client.command!(sub_cmd.bind([Param.i32(11), Param.i32(31)]))?
	replaced_result = PgResult.decode_one(replaced, |r| r.i32("result"))?
	check("prepared replaced", replaced_result == -20)?
	Stdout.line!("ok: prepared statements")
}

## transaction! commits a body that succeeds and rolls back one that fails.
## query! and execute! are command! with the encoding and decoding done.
test_transaction! : Db => Try({}, _)
test_transaction! = |client| {
	_ = client.execute_unchecked!("create temp table tx_people (name text)", [])?
	inserted = client.transaction!(|db| {
		_ = db.execute_unchecked!("insert into tx_people (name) values ($1)", [Param.str("Ada")])?
		db.query_unchecked!("select count(*)::int as n from tx_people", [], |row| row.i32("n"))
	})?
	check("transaction! commits", inserted == [1])?

	rolled_back = client.transaction!(|db| {
		_ = db.execute_unchecked!("insert into tx_people (name) values ($1)", [Param.str("Grace")])?
		_ = db.command!(Statement.new_unchecked("select nope from does_not_exist"))?
		Ok({})
	})
	match rolled_back {
		Ok(_) => Err(TestFailed("a failing transaction body should fail"))
		Err(PgErr(error)) => check("transaction! passes the body error through", error.code == "42P01")
		Err(other) => Err(other)
	}?
	after = client.query_unchecked!("select count(*)::int as n from tx_people", [], |row| row.i32("n"))?
	check("transaction! rolls back the failed body", after == [1])?
	check("transaction! leaves the session idle", client.sync_status!()? == Idle)?
	Stdout.line!("ok: transaction")
}

## A body that catches a failed statement and returns Ok commits nothing:
## the server rolls the transaction back at `commit`, and transaction!
## reports that instead of the body's value.
test_transaction_aborted! : Db => Try({}, _)
test_transaction_aborted! = |client| {
	_ = client.execute_unchecked!("create temp table aborted_people (name text)", [])?
	aborted = client.transaction!(|db| {
		_ = db.execute_unchecked!("insert into aborted_people (name) values ($1)", [Param.str("Ada")])?
		_ = db.execute_unchecked!("select nope from does_not_exist", [])
		Ok("done")
	})
	match aborted {
		Err(TransactionAborted) => Ok({})
		Ok(_) => Err(TestFailed("a transaction the server rolled back should fail"))
		Err(other) => Err(other)
	}?
	check("an aborted transaction commits nothing", nested_count!(client, "aborted_people")? == 0)?
	check("an aborted transaction leaves the session idle", client.sync_status!()? == Idle)?
	_ = client.execute_unchecked!("drop table aborted_people", [])?
	Stdout.line!("ok: transaction aborted")
}

## transaction! inside a transaction runs in a savepoint. A nested call that
## fails undoes only its own work, the enclosing transaction goes on, and
## the enclosing commit decides for all of it. That holds when the nested
## call goes through the outer connection too, as a body that closes over
## it does.
test_nested_transactions! : Db => Try({}, _)
test_nested_transactions! = |client| {
	_ = client.execute_unchecked!("create temp table nested (name text)", [])?

	# Both levels succeed and both land.
	count = client.transaction!(|outer| {
		_ = outer.execute_unchecked!("insert into nested values ($1)", [Param.str("a")])?
		outer.transaction!(|inner| inner.execute_unchecked!("insert into nested values ($1)", [Param.str("b")]))
	})?
	check("nested: the inner value comes through", count == 1)?
	check("nested: both levels commit", nested_names!(client)? == ["a", "b"])?
	_ = client.execute_unchecked!("delete from nested", [])?

	# The inner call fails, the outer one carries on.
	_ = client.transaction!(|outer| {
		_ = outer.execute_unchecked!("insert into nested values ($1)", [Param.str("a")])?
		inner = outer.transaction!(|db| {
			_ = db.execute_unchecked!("insert into nested values ($1)", [Param.str("b")])?
			db.execute_unchecked!("select nope from does_not_exist", [])
		})
		check("nested: the inner failure comes through", Try.is_err(inner))?
		outer.execute_unchecked!("insert into nested values ($1)", [Param.str("c")])
	})?
	check("nested: a failed inner call undoes only its own work", nested_names!(client)? == ["a", "c"])?
	_ = client.execute_unchecked!("delete from nested", [])?

	# The inner body catches a failed statement and returns Ok. The inner
	# call reports the abort and the outer transaction is still usable.
	_ = client.transaction!(|outer| {
		_ = outer.execute_unchecked!("insert into nested values ($1)", [Param.str("a")])?
		inner = outer.transaction!(|db| {
			_ = db.execute_unchecked!("insert into nested values ($1)", [Param.str("b")])?
			_ = db.execute_unchecked!("select nope from does_not_exist", [])
			Ok({})
		})
		aborted =
			match inner {
				Err(TransactionAborted) => Bool.True
				_ => Bool.False
			}
		check("nested: a caught failure aborts the inner call", aborted)?
		outer.execute_unchecked!("insert into nested values ($1)", [Param.str("c")])
	})?
	check("nested: the outer transaction goes on after an inner abort", nested_names!(client)? == ["a", "c"])?
	_ = client.execute_unchecked!("delete from nested", [])?

	# Three levels, the innermost fails and the middle one carries on, so
	# each release and rollback finds its own savepoint.
	_ = client.transaction!(|top| {
		_ = top.execute_unchecked!("insert into nested values ($1)", [Param.str("a")])?
		_ = top.transaction!(|middle| {
			_ = middle.execute_unchecked!("insert into nested values ($1)", [Param.str("b")])?
			_ = middle.transaction!(|bottom| {
				_ = bottom.execute_unchecked!("insert into nested values ($1)", [Param.str("x")])?
				bottom.execute_unchecked!("select nope from does_not_exist", [])
			})
			middle.execute_unchecked!("insert into nested values ($1)", [Param.str("c")])
		})?
		top.execute_unchecked!("insert into nested values ($1)", [Param.str("d")])
	})?
	check("nested: three levels", nested_names!(client)? == ["a", "b", "c", "d"])?
	_ = client.execute_unchecked!("delete from nested", [])?

	# A nested call that succeeded is still undone when the outer one fails.
	outer_failed = client.transaction!(|outer| {
		_ = outer.transaction!(|db| db.execute_unchecked!("insert into nested values ($1)", [Param.str("a")]))?
		outer.execute_unchecked!("select nope from does_not_exist", [])
	})
	check("nested: the outer failure comes through", Try.is_err(outer_failed))?
	check("nested: an outer failure undoes a nested success", nested_names!(client)? == [])?

	# Nesting through the outer connection instead of the body's.
	_ = client.transaction!(|_| {
		_ = client.execute_unchecked!("insert into nested values ($1)", [Param.str("a")])?
		_ = client.transaction!(|_| {
			_ = client.execute_unchecked!("insert into nested values ($1)", [Param.str("b")])?
			client.execute_unchecked!("select nope from does_not_exist", [])
		})
		client.execute_unchecked!("insert into nested values ($1)", [Param.str("c")])
	})?
	check("nested through the outer connection: only the inner work is undone", nested_names!(client)? == ["a", "c"])?
	_ = client.execute_unchecked!("delete from nested", [])?

	outer_connection_failed = client.transaction!(|_| {
		_ = client.transaction!(|_| client.execute_unchecked!("insert into nested values ($1)", [Param.str("a")]))?
		client.execute_unchecked!("select nope from does_not_exist", [])
	})
	check("nested through the outer connection: the outer failure comes through", Try.is_err(outer_connection_failed))?
	check("nested through the outer connection: the inner call did not commit early", nested_names!(client)? == [])?

	check("nested: the session ends idle", client.sync_status!()? == Idle)?
	_ = client.execute_unchecked!("drop table nested", [])?
	Stdout.line!("ok: nested transactions")
}

## Nesting through the client a body is given goes straight to a savepoint,
## without the `begin` that makes the server warn "there is already a
## transaction in progress". Reads the server's log through pg_read_file,
## which needs the superuser and the log file ./tests.roc sets up.
test_nested_transactions_quiet! : Db => Try({}, _)
test_nested_transactions_quiet! = |client| {
	before = log_size!(client)?
	_ = client.transaction!(|outer| outer.transaction!(|inner| inner.transaction!(|db| db.execute_unchecked!("select 1", []))))?
	_ = client.transaction!(|outer| {
		_ = outer.transaction!(|db| db.execute_unchecked!("select nope from does_not_exist", []))
		outer.execute_unchecked!("select 1", [])
	})?
	logged = log_since!(client, before)?
	check("nested transactions through the body's client put no warning in the server log, it says:\n${logged}", !logged.contains("there is already a transaction in progress"))?
	Stdout.line!("ok: nested transactions without server warnings")
}

log_size! : Db => Try(I64, _)
log_size! = |client| client.query_one_unchecked!("select (pg_stat_file('log')).size as n", [], |r| r.i64("n"))

log_since! : Db, I64 => Try(Str, _)
log_since! = |client, offset| client.query_one_unchecked!("select pg_read_file('log', $1::int8, 1000000) as text", [Param.i64(offset)], |r| r.str("text"))

nested_names! : Db => Try(List(Str), _)
nested_names! = |client| client.query_unchecked!("select name from nested order by name", [], |row| row.str("name"))

nested_count! : Db, Str => Try(I32, _)
nested_count! = |client, table| client.query_one_unchecked!("select count(*)::int as n from ${table}", [], |row| row.i32("n"))

## execute! returns how many rows a statement affected, and zero for one
## that reports no count. The count comes from the command tag, which
## PgResult keeps.
test_execute_counts! : Db => Try({}, _)
test_execute_counts! = |client| {
	created = client.execute_unchecked!("create temp table counted (n int)", [])?
	check("execute! counts nothing for create table", created == 0)?
	inserted = client.execute_unchecked!("insert into counted select generate_series(1, 5)", [])?
	check("execute! counts inserted rows", inserted == 5)?
	updated = client.execute_unchecked!("update counted set n = n * 10 where n > $1", [Param.i32(2)])?
	check("execute! counts updated rows", updated == 3)?
	none = client.execute_unchecked!("delete from counted where n < 0", [])?
	check("execute! counts zero rows", none == 0)?
	deleted = client.execute_unchecked!("delete from counted where n >= $1", [Param.i32(30)])?
	check("execute! counts deleted rows", deleted == 3)?
	result = client.command!(Statement.new_unchecked("insert into counted values (1), (2) returning n"))?
	check("PgResult.command_tag", PgResult.command_tag(result) == "INSERT 0 2")?
	check("PgResult.rows_affected", PgResult.rows_affected(result) == 2)?
	_ = client.execute_unchecked!("drop table counted", [])?
	Stdout.line!("ok: execute counts")
}

## The names in `piped`, in the order of their ids.
piped_names! = |client|
	client.query_unchecked!("select name from piped order by id", [], |row| row.str("name"))

## Statements sent together and answered in one round trip: each one's row
## count in order, every write or none, and a usable connection after a
## failure.
test_pipeline! : Db => Try({}, _)
test_pipeline! = |client| {
	_ = client.execute_unchecked!("create temp table piped (id int primary key, name text not null)", [])?
	add = |id, name| { sql: "insert into piped (id, name) values ($1, $2)", params: [Param.i32(id), Param.str(name)] }

	nothing = client.pipeline_unchecked!([])?
	check("an empty pipeline", nothing == [])?

	counts = client.pipeline_unchecked!([
		add(1, "Hedy"),
		add(2, "Lise"),
		{ sql: "update piped set name = name || '!' where id >= $1", params: [Param.i32(1)] },
		{ sql: "select name from piped", params: [] },
		{ sql: "delete from piped where id = $1", params: [Param.i32(2)] },
	])?
	check("each statement's row count, in order", counts == [1, 1, 2, 2, 1])?
	check("the pipeline's writes landed", piped_names!(client)? == ["Hedy!"])?

	# The third insert repeats id 3. The server skips the fourth, and
	# outside a transaction the pipeline is one transaction of its own, so
	# the first two are rolled back.
	failing = [add(3, "Emmy"), add(4, "Rosalind"), add(3, "Chien-Shiung"), add(5, "Dorothy")]
	check(
		"a failing statement fails the pipeline with its place and error",
		match client.pipeline_unchecked!(failing) {
			Err(PgPipelineErr({ index: 2, error: { code: "23505", .. } })) => Bool.True
			_ => Bool.False
		},
	)?
	check("a failed pipeline outside a transaction stores nothing", piped_names!(client)? == ["Hedy!"])?

	in_transaction = client.transaction!(
		|tx| {
			_ = tx.execute_unchecked!("update piped set name = $1 where id = $2", [Param.str("Hedy Lamarr"), Param.i32(1)])?
			tx.pipeline_unchecked!(failing)
		},
	)
	check(
		"a failing pipeline fails its transaction",
		match in_transaction {
			Err(PgPipelineErr({ index: 2, error: { code: "23505", .. } })) => Bool.True
			_ => Bool.False
		},
	)?
	check("and the transaction is rolled back", piped_names!(client)? == ["Hedy!"])?

	# A thousand statements in one round trip.
	many = List.repeat("Noether", 1000).map_with_index(|name, i| { sql: "insert into piped (id, name) values ($1, $2)", params: [Param.u64(100 + i), Param.str(name)] })
	many_counts = client.pipeline_unchecked!(many)?
	check("a thousand statements, a count each", many_counts == List.repeat(1, 1000))?
	stored_many = client.query_one_unchecked!("select count(*)::int as n from piped where id >= 100", [], |row| row.i32("n"))?
	check("a thousand rows stored", stored_many == 1000)?
	_ = client.execute_unchecked!("delete from piped where id >= 100", [])?

	_ = client.transaction!(|tx| tx.pipeline_unchecked!([add(6, "Ada Yonath")]))?
	check("a pipeline in a transaction lands with its commit", piped_names!(client)? == ["Hedy!", "Ada Yonath"])?
	_ = client.execute_unchecked!("drop table piped", [])?
	Stdout.line!("ok: pipeline")
}

## Several statements in one simple query. The server splits them, so a `;`
## in a string, a comment or a function body is safe. A failing statement
## rolls the whole batch back, and the connection stays usable after it.
test_batch_execute! : Db => Try({}, _)
test_batch_execute! = |client| {
	client.batch_execute_unchecked!(
		Str.join_with(
			[
				"create temp table batched (n int, note text);",
				"-- a comment with a ; in it",
				"insert into batched values (1, 'semi;colon'), (2, $$dollar;quoted$$);",
				"select * from batched;",
				"create function pg_temp.batched_double(x int) returns int as $$ select x * 2; $$ language sql",
			],
			"\n",
		),
	)?
	notes = client.query_unchecked!("select note from batched order by n", [], |row| row.str("note"))?
	check("batch_execute_unchecked! runs every statement, whatever holds a ;", notes == ["semi;colon", "dollar;quoted"])?
	doubled = client.query_one_unchecked!("select pg_temp.batched_double(21) as n", [], |row| row.i32("n"))?
	check("batch_execute_unchecked! creates a function whose body holds a ;", doubled == 42)?

	match client.batch_execute_unchecked!("insert into batched values (3, 'rolled back'); select 1 / 0; insert into batched values (4, 'never run')") {
		Ok({}) => Err(TestFailed("a batch with a failing statement should fail"))
		Err(PgErr(error)) => check("batch_execute_unchecked! reports the failing statement", error.code == "22012")
		Err(other) => Err(other)
	}?
	after_error = client.query_one_unchecked!("select count(*)::int as n from batched", [], |row| row.i32("n"))?
	check("batch_execute_unchecked! rolls the whole batch back after a failure", after_error == 2)?
	check("batch_execute_unchecked! leaves the session idle after a failure", client.sync_status!()? == Idle)?

	undone = client.transaction!(|db| {
		db.batch_execute_unchecked!("insert into batched values (5, 'undone'); insert into batched values (6, 'undone')")?
		Err(UndoOnPurpose)
	})
	match undone {
		Err(UndoOnPurpose) => Ok({})
		Ok(_) => Err(TestFailed("the transaction body should fail"))
		Err(other) => Err(other)
	}?
	after_undo = client.query_one_unchecked!("select count(*)::int as n from batched", [], |row| row.i32("n"))?
	check("batch_execute_unchecked! inside transaction! rolls back with it", after_undo == 2)?

	client.batch_execute_unchecked!("")?
	match client.batch_execute_unchecked!("select 1;\u(0)drop table batched") {
		Err(ContainsNul(what)) => check("batch_execute_unchecked! refuses a NUL byte", what == "sql")
		Ok({}) => Err(TestFailed("a batch with a NUL byte should be refused"))
		Err(other) => Err(other)
	}?

	client.batch_execute_unchecked!("drop table batched; drop function pg_temp.batched_double(int)")?
	Stdout.line!("ok: batch_execute")
}

## The cleartext password flow. ./tests.roc prepends a pg_hba rule that
## makes the server demand a password from this one user, so this test only
## passes on the throwaway server it boots (a `trust` server never sends a
## password challenge).
test_password_auth! : _, Db => Try({}, _)
test_password_auth! = |server, admin| {
	_ = admin.command!(Statement.new_unchecked("drop user if exists roc_pg_password_test"))?
	_ = admin.command!(Statement.new_unchecked("create user roc_pg_password_test password 'opensesame'"))?

	authed = Client.connect!(
		{
			connect!: dial!,
			random_u64!: Random.seed_u64!,
			host: server.host,
			port: server.port,
			user: "roc_pg_password_test",
			database: server.database,
			auth: Password("opensesame"),
			statement_timeout: Duration.zero,
		},
	)?
	result = authed.command!(Statement.new_unchecked("select 1 as one"))?
	one = PgResult.decode_one(result, |r| r.i32("one"))?
	check("query after password auth", one == 1)?
	authed.close!()

	match
		Client.connect!(
			{
				connect!: dial!,
				random_u64!: Random.seed_u64!,
				host: server.host,
				port: server.port,
				user: "roc_pg_password_test",
				database: server.database,
				auth: NoAuth,
				statement_timeout: Duration.zero,
			},
		)
	{
		Ok(_) => Err(TestFailed("connecting without a password should fail"))
		Err(PasswordRequired) => Ok({})
		Err(other) => Err(other)
	}?

	match
		Client.connect!(
			{
				connect!: dial!,
				random_u64!: Random.seed_u64!,
				host: server.host,
				port: server.port,
				user: "roc_pg_password_test",
				database: server.database,
				auth: Password("wrong"),
				statement_timeout: Duration.zero,
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

## query_one! wants exactly one row, and the decoder's errors come through.
test_query_one! : Db => Try({}, _)
test_query_one! = |client| {
	one = client.query_one_unchecked!("select 7 as n", [], |r| r.i32("n"))?
	check("query_one! one row", one == 7)?

	match client.query_one_unchecked!("select 1 as n where false", [], |r| r.i32("n")) {
		Err(EmptyResult) => Ok({})
		Ok(_) => Err(TestFailed("no rows should be EmptyResult"))
		Err(other) => Err(other)
	}?

	match client.query_one_unchecked!("select n from generate_series(1, 3) as t (n)", [], |r| r.i32("n")) {
		Err(MultipleRows(3)) => Ok({})
		Ok(_) => Err(TestFailed("three rows should be MultipleRows"))
		Err(other) => Err(other)
	}?

	match client.query_one_unchecked!("select 'x' as n", [], |r| r.i32("n")) {
		Err(InvalidNumStr("n")) => Ok({})
		Ok(_) => Err(TestFailed("decoding 'x' as an int should fail"))
		Err(other) => Err(other)
	}?
	Stdout.line!("ok: query_one")
}

## query_optional! tells one row from none inside its result, refuses more
## than one, and passes decode and server errors through.
test_query_optional! : Db => Try({}, _)
test_query_optional! = |client| {
	found = client.query_optional_unchecked!("select 7 as n", [], |r| r.i32("n"))?
	check("query_optional! one row", found == Ok(7))?

	none = client.query_optional_unchecked!("select 1 as n where false", [], |r| r.i32("n"))?
	check("query_optional! no row", none == Err(NotFound))?

	match client.query_optional_unchecked!("select n from generate_series(1, 2) as t (n)", [], |r| r.i32("n")) {
		Err(MultipleRows(2)) => Ok({})
		Ok(_) => Err(TestFailed("two rows should be MultipleRows"))
		Err(other) => Err(other)
	}?

	match client.query_optional_unchecked!("select 'x' as n", [], |r| r.i32("n")) {
		Err(InvalidNumStr("n")) => Ok({})
		Ok(_) => Err(TestFailed("decoding 'x' as an int should fail"))
		Err(other) => Err(other)
	}?

	match client.query_optional_unchecked!("select nope from does_not_exist", [], |r| r.i32("nope")) {
		Err(PgErr(error)) => check("query_optional! passes a server error through", error.code == "42P01")
		Ok(_) => Err(TestFailed("a missing table should fail"))
		Err(other) => Err(other)
	}?
	Stdout.line!("ok: query_optional")
}

## Arrays go both ways: a Param.list binds a text[] or int[] (the server
## infers the element type from the placeholder), and the list accessors
## decode the text form back, quoting and all.
test_arrays! : Db => Try({}, _)
test_arrays! = |client| {
	_ = client.execute_unchecked!("create temp table tagged (id int, tags text[], nums int[])", [])?
	_ = client.execute_unchecked!(
		"insert into tagged (id, tags, nums) values ($1, $2, $3)",
		[
			Param.i32(1),
			Param.list([Param.str("a b"), Param.str("say \"hi\""), Param.str("back\\slash"), Param.str("NULL"), Param.str("")]),
			Param.list([Param.i32(1), Param.i32(-2)]),
		],
	)?
	row = client.query_one_unchecked!(
		"select tags, nums from tagged where id = $1",
		[Param.i32(1)],
		|r| Ok({ tags: r.str_list("tags")?, nums: r.i32_list("nums")? }),
	)?
	check("text[] round trip", row.tags == ["a b", "say \"hi\"", "back\\slash", "NULL", ""])?
	check("int[] round trip", row.nums == [1, -2])?

	# `= any($1)` is how a list of ids goes into a where clause.
	matched = client.query_unchecked!("select id from tagged where id = any($1)", [Param.list([Param.i32(1), Param.i32(5)])], |r| r.i32("id"))?
	check("any(list) binding", matched == [1])?

	# A NULL element, an empty array, and a nested list, which binds as a
	# two-dimensional array but only decodes as text.
	odd = client.query_one_unchecked!(
		"select array[1, null]::int[] as with_null, '{}'::int[] as empty, $1::int[][] as nested",
		[Param.list([Param.list([Param.i32(1), Param.i32(2)]), Param.list([Param.i32(3), Param.i32(4)])])],
		|r| {
			null_element =
				match r.list("with_null", |text| Ok(text)) {
					Err(NullElement("with_null")) => Bool.True
					_ => Bool.False
				}
			nested_invalid =
				match r.str_list("nested") {
					Err(InvalidArray("nested")) => Bool.True
					_ => Bool.False
				}
			Ok({ null_element, empty: r.i32_list("empty")?, nested_invalid, nested: r.str("nested")? })
		},
	)?
	check("NULL element is NullElement", odd.null_element)?
	check("empty array", odd.empty == [])?
	check("nested list binds as int[][]", odd.nested == "{{1,2},{3,4}}")?
	check("nested array does not decode as a list", odd.nested_invalid)?
	Stdout.line!("ok: arrays")
}

## An enum column takes its label as Param.str and gives it back as a
## string, and an enum array is an array like any other. Enum types are
## not temporary, so the test drops its own.
test_enums! : Db => Try({}, _)
test_enums! = |client| {
	_ = client.execute_unchecked!("drop type if exists roc_pg_mood", [])?
	_ = client.execute_unchecked!("create type roc_pg_mood as enum ('sad', 'ok', 'happy')", [])?
	_ = client.execute_unchecked!("create temp table moods (id int, mood roc_pg_mood, history roc_pg_mood[])", [])?
	_ = client.execute_unchecked!(
		"insert into moods values ($1, $2, $3)",
		[Param.i32(1), Param.str("happy"), Param.list([Param.str("sad"), Param.str("ok")])],
	)?

	row = client.query_one_unchecked!(
		"select mood, history from moods where mood = $1",
		[Param.str("happy")],
		|r| Ok({ mood: r.str("mood")?, history: r.str_list("history")? }),
	)?
	check("enum in and out", row.mood == "happy")?
	check("enum array in and out", row.history == ["sad", "ok"])?

	matched = client.query_unchecked!("select id from moods where mood = any($1)", [Param.list([Param.str("happy"), Param.str("sad")])], |r| r.i32("id"))?
	check("enum any(list)", matched == [1])?

	match client.execute_unchecked!("insert into moods values ($1, $2, $3)", [Param.i32(2), Param.str("angry"), Param.list([])]) {
		Ok(_) => Err(TestFailed("a label outside the enum should fail"))
		# 22P02 is invalid_text_representation
		Err(PgErr(error)) => check("bad enum label is a server error", error.code == "22P02")
		Err(other) => Err(other)
	}?

	_ = client.execute_unchecked!("drop table moods", [])?
	_ = client.execute_unchecked!("drop type roc_pg_mood", [])?
	Stdout.line!("ok: enums")
}

## md5 and SCRAM logins, and the client's say in them: a login `auth_methods`
## leaves out is refused. ./tests.roc prepends the pg_hba rules that make the
## server ask these users for md5 and for SCRAM.
test_md5_and_scram! = |server, admin| {
	_ = admin.command!(Statement.new_unchecked("drop user if exists roc_pg_md5_test"))?
	_ = admin.command!(Statement.new_unchecked("drop user if exists roc_pg_scram_test"))?
	# How a password is stored decides what the server can check it with: an
	# md5 hash only with md5.
	_ = admin.command!(Statement.new_unchecked("set password_encryption = 'md5'"))?
	_ = admin.command!(Statement.new_unchecked("create user roc_pg_md5_test password 'md5-secret'"))?
	_ = admin.command!(Statement.new_unchecked("set password_encryption = 'scram-sha-256'"))?
	_ = admin.command!(Statement.new_unchecked("create user roc_pg_scram_test password 'scram-secret'"))?

	all = [Scram, Md5, Cleartext, Trust]
	md5 = { user: "roc_pg_md5_test", password: "md5-secret" }
	scram = { user: "roc_pg_scram_test", password: "scram-secret" }
	cleartext = { user: "roc_pg_password_test", password: "opensesame" }
	trust = { user: server.user, password: "unused" }

	# Every login works with everything allowed, and a wrong password is the
	# server's refusal.
	login!(server, md5, all)?
	login!(server, scram, all)?
	login!(server, md5, [Md5])?
	refused!(login!(server, { ..md5, password: "wrong" }, all), "a wrong md5 password")?
	refused!(login!(server, { ..scram, password: "wrong" }, all), "a wrong SCRAM password")?

	# A login auth_methods leaves out is refused.
	not_allowed(login!(server, md5, [Scram, Cleartext, Trust]), "md5")?
	not_allowed(login!(server, scram, [Md5, Cleartext, Trust]), "SCRAM-SHA-256")?
	not_allowed(login!(server, cleartext, [Scram, Md5, Trust]), "password")?
	not_allowed(login!(server, trust, [Scram, Md5, Cleartext]), "trust")?

	# SCRAM alone takes a SCRAM login and nothing else.
	login!(server, scram, [Scram])?
	not_allowed(login!(server, md5, [Scram]), "md5")?
	not_allowed(login!(server, cleartext, [Scram]), "password")?
	# A server that lets the client in without asking cannot pass for one
	# that checked the password.
	not_allowed(login!(server, trust, [Scram]), "trust")?
	Stdout.line!("ok: md5 and SCRAM auth")
}

## roc-scram against a real server, beyond the plain login: a non-ASCII
## password, a password that SASLprep changes, and the bounds roc-scram puts
## on the iteration count the server asks for. ./tests.roc prepends the
## pg_hba rule that makes the server ask these users for SCRAM.
test_scram_passwords! : _, Db => Try({}, _)
test_scram_passwords! = |server, admin| {
	users = [
		{ user: "roc_pg_scram_utf8_test", password: "pässword with spaces", iterations: 4096 },
		# SASLprep maps the no-break space to a space, so the server stores
		# the password "no break".
		{ user: "roc_pg_scram_nbsp_test", password: "no\u(A0)break", iterations: 4096 },
		{ user: "roc_pg_scram_low_test", password: "scram-secret", iterations: 1000 },
		{ user: "roc_pg_scram_high_test", password: "scram-secret", iterations: 1_000_001 },
	]
	_ = admin.command!(Statement.new_unchecked("set password_encryption = 'scram-sha-256'"))?
	for stored in users {
		_ = admin.command!(Statement.new_unchecked("drop user if exists ${stored.user}"))?
		_ = admin.command!(Statement.new_unchecked("set scram_iterations = ${stored.iterations.to_str()}"))?
		_ = admin.command!(Statement.new_unchecked("create user ${stored.user} password '${stored.password}'"))?
	}
	_ = admin.command!(Statement.new_unchecked("reset scram_iterations"))?

	login!(server, { user: "roc_pg_scram_utf8_test", password: "pässword with spaces" }, [Scram])?

	# roc-scram does not apply SASLprep, so the password as typed does not
	# match what the server stored, and the mapped one does.
	refused!(login!(server, { user: "roc_pg_scram_nbsp_test", password: "no\u(A0)break" }, [Scram]), "a password that SASLprep changes, as typed")?
	login!(server, { user: "roc_pg_scram_nbsp_test", password: "no break" }, [Scram])?

	# The client turns these servers down before it computes a proof.
	scram_refused(login!(server, { user: "roc_pg_scram_low_test", password: "scram-secret" }, [Scram]), "IterationCountTooLow(1000)")?
	scram_refused(login!(server, { user: "roc_pg_scram_high_test", password: "scram-secret" }, [Scram]), "IterationCountTooHigh(1000001)")?
	Stdout.line!("ok: SCRAM passwords and iteration counts")
}

## Log in as `user` with `password`, allowing `auth_methods`, and run one
## query.
login! = |server, { user, password }, auth_methods| {
	client = Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user, database: server.database, auth: Password(password), statement_timeout: Duration.zero, auth_methods })?
	one = client.query_one_unchecked!("select 1 as one", [], |r| r.i32("one"))
	client.close!()
	check("a query after logging in as ${user}", one? == 1)
}

refused! = |outcome, what|
	match outcome {
		# 28P01 is invalid_password
		Err(PgErr(error)) => check("${what} is refused with 28P01, got ${error.code}", error.code == "28P01")
		other => Err(TestFailed("${what} was not refused: ${Str.inspect(other)}"))
	}

not_allowed = |outcome, method|
	match outcome {
		Err(AuthMethodNotAllowed(refused)) => check("refused ${method}, not ${refused}", refused == method)
		other => Err(TestFailed("${method} left out of auth_methods was not refused: ${Str.inspect(other)}"))
	}

## A SCRAM login the client turned down, for `reason`.
scram_refused = |outcome, reason|
	match outcome {
		Err(ScramFailed(given)) => check("SCRAM refused for ${reason}, not ${given}", given == reason)
		other => Err(TestFailed("SCRAM was not refused for ${reason}: ${Str.inspect(other)}"))
	}

## A connection URL over plaintext, with a SCRAM login. The URL's
## application name and `-c` settings reach the session, and an `sslmode`
## that demands TLS is refused.
test_connect_url! = |server| {
	base = "postgresql://roc_pg_scram_test:scram-secret@${server.host}:${server.port.to_str()}/${server.database}"
	options = "application_name=roc-pg-insane-in-the-membrane-url&options=-c%20statement_timeout%3D4321"
	client = Client.connect_url!("${base}?sslmode=disable&${options}", { connect!: dial!, random_u64!: Random.seed_u64!, statement_timeout: Duration.zero })?
	application_name = client.query_one_unchecked!("select current_setting('application_name') as name", [], |r| r.str("name"))
	timeout = client.query_one_unchecked!("select current_setting('statement_timeout') as t", [], |r| r.str("t"))
	client.close!()
	check("the URL's application_name reaches the session", application_name? == "roc-pg-insane-in-the-membrane-url")?
	check("the URL's -c statement_timeout reaches the session", timeout? == "4321ms")?
	match Client.connect_url!("${base}?sslmode=require", { connect!: dial!, random_u64!: Random.seed_u64!, statement_timeout: Duration.zero }) {
		Err(InvalidConnectionUrl(UnsupportedSslMode("require"))) => Ok({})
		other => Err(TestFailed("sslmode=require was not refused: ${Str.inspect(other)}"))
	}?
	Stdout.line!("ok: connection url")
}

## A NUL byte in SQL, a statement name or a connection setting is refused
## before anything is sent. The protocol carries those as C strings, so the
## server would read the rest as further fields: the tail of the SQL, or a
## startup setting of its own.
test_nul_bytes! : _, Db => Try({}, _)
test_nul_bytes! = |server, client| {
	nul = |outcome, what|
		match outcome {
			Err(ContainsNul(given)) => check("a NUL byte in ${what} is ContainsNul(${what}), not ContainsNul(${given})", given == what)
			other => Err(TestFailed("a NUL byte in ${what} was not refused: ${Str.inspect(other)}"))
		}
	nul(client.query_unchecked!("select 1\u(0)drop table nested", [], |r| r.i32("one")), "sql")?
	nul(client.execute_unchecked!("select 1\u(0)", []), "sql")?
	nul(client.prepare_unchecked!("select 1\u(0)", { name: "nul" }), "sql")?
	nul(client.prepare_unchecked!("select 1", { name: "nul\u(0)" }), "statement name")?
	after = client.query_one_unchecked!("select 4 as four", [], |r| r.i32("four"))?
	check("the client works after a refused NUL byte", after == 4)?

	connect! = |settings| Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user: settings.user, database: settings.database, auth: settings.auth, params: settings.params, statement_timeout: Duration.zero })
	fine = { user: server.user, database: server.database, auth: NoAuth, params: [] }
	nul(connect!({ ..fine, user: "${server.user}\u(0)options" }), "user")?
	nul(connect!({ ..fine, database: "postgres\u(0)x" }), "database")?
	nul(connect!({ ..fine, auth: Password("se\u(0)cret") }), "password")?
	nul(connect!({ ..fine, params: [("application_name", "app\u(0)options\u(0)-c x=y")] }), "parameter application_name")?
	nul(connect!({ ..fine, params: [("application\u(0)name", "app")] }), "a parameter name")?

	# A percent-encoded NUL in a URL is decoded before it is checked.
	base = "postgresql://${server.user}@${server.host}:${server.port.to_str()}/${server.database}"
	nul(Client.connect_url!("${base}?application_name=a%00b", { connect!: dial!, random_u64!: Random.seed_u64!, statement_timeout: Duration.zero }), "parameter application_name")?
	Stdout.line!("ok: NUL bytes")
}

## After a FATAL error the server closes the connection instead of sending
## ReadyForQuery. The client returns the server's error, with its SQLSTATE,
## rather than failing to read the rest of the conversation.
test_fatal_error! = |server| {
	client = Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user: server.user, database: server.database, auth: NoAuth, statement_timeout: Duration.zero })?
	# 57P01 is admin_shutdown, what a terminated session is told.
	match client.execute_unchecked!("select pg_terminate_backend(pg_backend_pid())", []) {
		Err(PgErr(error)) => check("a terminated session is PgErr 57P01 FATAL, got ${error.code} ${error.severity}", error.code == "57P01" and error.severity == "FATAL")
		other => Err(TestFailed("a terminated session was not a FATAL PgErr: ${Str.inspect(other)}"))
	}?
	Stdout.line!("ok: FATAL error")
}

## A commit the server refuses inside transaction! (a deferred constraint
## that only fails at commit) is TransactionCommitRefused, with the server's
## error, and nothing of the transaction lands.
test_commit_refused! : Db => Try({}, _)
test_commit_refused! = |client| {
	_ = client.execute_unchecked!("create temp table deferred_in_transaction (i int unique deferrable initially deferred)", [])?
	outcome = client.transaction!(|db| db.execute_unchecked!("insert into deferred_in_transaction values (1), (1)", []))
	match outcome {
		Err(TransactionCommitRefused(error)) => check("a refused commit keeps the server's SQLSTATE, got ${error.code}", error.code == "23505")
		other => Err(TestFailed("a deferred violation inside transaction! was not TransactionCommitRefused: ${Str.inspect(other)}"))
	}?
	count = client.query_one_unchecked!("select count(*)::int as n from deferred_in_transaction", [], |r| r.i32("n"))?
	check("a refused commit lands nothing", count == 0)?
	check("a refused commit leaves the session idle", client.sync_status!()? == Idle)?
	Stdout.line!("ok: commit refused inside transaction!")
}

## statement_timeout has the server cancel a statement that runs too
## long (SQLSTATE 57014), and the connection goes on.
test_statement_timeout! = |server| {
	client = Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user: server.user, database: server.database, auth: NoAuth, statement_timeout: Duration.millis(100) })?
	# 57014 is query_canceled.
	match client.execute_unchecked!("select pg_sleep(2)", []) {
		Err(PgErr(error)) => check("a statement past statement_timeout is 57014, got ${error.code}", error.code == "57014")
		other => Err(TestFailed("a statement past statement_timeout was not cancelled: ${Str.inspect(other)}"))
	}?
	after = client.query_one_unchecked!("select 5 as five", [], |r| r.i32("five"))?
	check("the connection works after a cancelled statement", after == 5)?
	client.close!()
	Stdout.line!("ok: statement timeout")
}

## A statement prepared on one connection runs on another too, where its
## name does not exist: the client parses its SQL again there.
test_prepared_elsewhere! : _, Db => Try({}, _)
test_prepared_elsewhere! = |server, client| {
	add = client.prepare_unchecked!("select $1::int + $2::int as sum", { name: "add_elsewhere" })?
	other = Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user: server.user, database: server.database, auth: NoAuth, statement_timeout: Duration.zero })?
	elsewhere = other.command!(add.bind([Param.i32(40), Param.i32(2)]))
	names = other.query_unchecked!("select name from pg_prepared_statements", [], |r| r.str("name"))
	other.close!()
	sum = PgResult.decode_one(elsewhere?, |r| r.i32("sum"))?
	check("a statement prepared on another connection runs here", sum == 42)?
	check("running it here prepares nothing here, got ${Str.inspect(names)}", names? == [])?
	here = PgResult.decode_one(client.command!(add.bind([Param.i32(1), Param.i32(2)]))?, |r| r.i32("sum"))?
	check("it still runs where it was prepared", here == 3)?
	Stdout.line!("ok: prepared statement on another connection")
}

## Names in `params` that are not session settings are refused: the
## protocol's own keys, which would replace the login or change the
## protocol, and `client_encoding`, which must stay UTF8. Case does not
## matter. A URL whose `options` sets one is refused the same way.
test_param_not_allowed! = |server| {
	refused_param = |outcome, name|
		match outcome {
			Err(ParamNotAllowed(given)) => check("${name} in params is ParamNotAllowed(${name}), not ParamNotAllowed(${given})", given == name)
			other => Err(TestFailed("${name} in params was not refused: ${Str.inspect(other)}"))
		}
	connect! = |params| Client.connect!({ connect!: dial!, random_u64!: Random.seed_u64!, host: server.host, port: server.port, user: server.user, database: server.database, auth: NoAuth, params, statement_timeout: Duration.zero })
	refused_param(connect!([("user", "postgres")]), "user")?
	refused_param(connect!([("application_name", "app"), ("database", "template1")]), "database")?
	refused_param(connect!([("options", "-c work_mem=64MB")]), "options")?
	refused_param(connect!([("replication", "true")]), "replication")?
	refused_param(connect!([("_pq_.anything", "1")]), "_pq_.anything")?
	refused_param(connect!([("client_encoding", "LATIN1")]), "client_encoding")?
	refused_param(connect!([("CLIENT_ENCODING", "LATIN1")]), "CLIENT_ENCODING")?
	base = "postgresql://${server.user}@${server.host}:${server.port.to_str()}/${server.database}"
	refused_param(Client.connect_url!("${base}?options=-c%20user%3Dpostgres", { connect!: dial!, random_u64!: Random.seed_u64!, statement_timeout: Duration.zero }), "user")?
	refused_param(Client.connect_url!("${base}?options=-c%20client_encoding%3DLATIN1", { connect!: dial!, random_u64!: Random.seed_u64!, statement_timeout: Duration.zero }), "client_encoding")?
	Stdout.line!("ok: names that are not session settings refused in params")
}

## The package sends its own startup keys (`client_encoding`, `user`,
## `database`) after the app's `params`. That keeps them in force, even if a
## name slipped past the check above, only because the server keeps the last
## value of a repeated key. This pins that down with a startup message built
## by hand: a role and a database that do not exist and LATIN1 first, the
## real user, database and UTF8 last. The server must log in with the last
## ones and report UTF8.
test_startup_last_value_wins! = |server| {
	stream = dial!(server.host, server.port) ? |_| TestFailed("could not connect for the startup message test")
	pair = |key, value| key.to_utf8().append(0).concat(value.to_utf8()).append(0)
	body =
		# Protocol version 3.0, the key value pairs, and an empty key to end them.
		[0, 3, 0, 0]
			.concat(pair("user", "roc_pg_no_such_role"))
			.concat(pair("database", "roc_pg_no_such_database"))
			.concat(pair("client_encoding", "LATIN1"))
			.concat(pair("client_encoding", "UTF8"))
			.concat(pair("user", server.user))
			.concat(pair("database", server.database))
			.append(0)
	write_bytes!(stream, big_endian_u32(body.len() + 4).concat(body)) ? |_| TestFailed("could not send the startup message")
	reported = read_startup_replies!(stream, [])?
	# Terminate, best effort.
	_ = write_bytes!(stream, ['X', 0, 0, 0, 4])
	check("the server logs in as the last user, it reported ${Str.inspect(reported)}", reported.contains(("session_authorization", server.user)))?
	check("the server takes the last client_encoding, it reported ${Str.inspect(reported)}", reported.contains(("client_encoding", "UTF8")))?
	Stdout.line!("ok: the server keeps the last value of a startup key")
}

big_endian_u32 : U64 -> List(U8)
big_endian_u32 = |n| [n.shr_zf_wrap(24).to_u8_wrap(), n.shr_zf_wrap(16).to_u8_wrap(), n.shr_zf_wrap(8).to_u8_wrap(), n.to_u8_wrap()]

## The connection's methods, called through functions of our own. Calling them
## directly and using the connection after an error check frees it in a dev
## build (roc-lang/roc#12692).
write_bytes! = |stream, bytes| stream.write_bytes!(bytes)

read_exactly! = |stream, n| stream.read_exactly!(n)

## Read the server's replies to a startup message through ReadyForQuery and
## return the settings it reported (ParameterStatus). An error, such as a
## role or database that does not exist, fails the test with its text.
read_startup_replies! : Tcp.Connection, List((Str, Str)) => Try(List((Str, Str)), _)
read_startup_replies! = |stream, reported| {
	header = read_exactly!(stream, 5) ? |_| TestFailed("the server closed the connection during the startup")
	len = header.drop_first(1).fold(0, |acc, byte| acc * 256 + byte.to_u64())
	payload = if len > 4 (read_exactly!(stream, len - 4) ? |_| TestFailed("the server closed the connection during the startup")) else []
	match header.first() {
		Ok('Z') => Ok(reported)
		Ok('E') => Err(TestFailed("the server refused the startup message: ${Str.from_utf8_lossy(payload.map(|byte| if byte == 0 ' ' else byte))}"))
		Ok('S') =>
			match payload.split_first(0) {
				Ok({ before, after }) => read_startup_replies!(stream, reported.append((Str.from_utf8_lossy(before), Str.from_utf8_lossy(after.drop_last(1)))))
				Err(_) => Err(TestFailed("a ParameterStatus without a name"))
			}
		# AuthOk (the test server trusts this user), BackendKeyData and notices.
		_ => read_startup_replies!(stream, reported)
	}
}

## A notification for a channel the session listens on arrives as soon as
## the notifying transaction commits, in the middle of a reply. The client
## reads past it, for extended and simple queries alike.
test_notifications_skipped! : Db => Try({}, _)
test_notifications_skipped! = |client| {
	_ = client.execute_unchecked!("listen roc_pg_test", [])?
	_ = client.execute_unchecked!("notify roc_pg_test, 'extended'", [])?
	client.batch_execute_unchecked!("notify roc_pg_test, 'simple'; select 1")?
	n = client.query_one_unchecked!("select 2 as n", [], |r| r.i32("n"))?
	check("a query after notifications", n == 2)?
	_ = client.execute_unchecked!("unlisten roc_pg_test", [])?
	Stdout.line!("ok: notifications skipped")
}
