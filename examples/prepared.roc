## Prepared statements: parse a query once, run it many times with fresh
## bindings.
##
## Expects a Postgres server on localhost:5432 with a `postgres` user and
## database (adjust below). Run it with: roc examples/prepared.roc
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.29.0/GrSTLEKd6yw8orQ5ByQQVY3Htg59vZYaoHBvQELueiMB.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pg.Client
import pg.Param
import pg.PgResult

main! = |_args| {
	client = Client.connect!(
		{
			connect!: Tcp.connect!,
			random_u64!: Random.seed_u64!,
			host: "localhost",
			port: 5432,
			user: "postgres",
			database: "postgres",
			auth: NoAuth,
			timeout_ms: 5000,
		},
	)?

	Stdout.line!("Connected!")?

	add_cmd = client.prepare!("select $1::int + $2::int as result", { name: "add" })?

	add_and_print!(client, add_cmd, 1, 2)?
	add_and_print!(client, add_cmd, 11, 31)?

	client.close!()
	Ok({})
}

add_and_print! = |client, add_cmd, a, b| {
	result = client.command!(add_cmd.bind([Param.i32(a), Param.i32(b)]))?
	sum = PgResult.decode_one(result, |row| row.i32("result"))?
	Stdout.line!("${a.to_str()} + ${b.to_str()} = ${sum.to_str()}")?
	Ok({})
}
