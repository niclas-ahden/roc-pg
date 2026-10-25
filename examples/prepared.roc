## Prepared statements: parse a query once, run it many times with fresh
## bindings.
##
## Expects a Postgres server on localhost:5432 with a `postgres` user and
## database (adjust below). Run it with: roc examples/prepared.roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Duration
import pf.Random
import pg.Client
import pg.Param
import pg.PgResult

main! = |_args| {
	client = Client.connect!(
		{
			connect!: |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(35) }),
			random_u64!: Random.seed_u64!,
			host: "localhost",
			port: 5432,
			user: "postgres",
			database: "postgres",
			auth: NoAuth,
			statement_timeout: Duration.seconds(30),
		},
	)?

	Stdout.line!("Connected!")?

	add_cmd = client.prepare_unchecked!("select $1::int + $2::int as result", { name: "add" })?

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
