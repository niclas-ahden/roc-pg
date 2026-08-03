## A connection pool: acquires dial (and authenticate) lazily, releases park
## the connection so the next acquire reuses it, already mid-session.
##
## Expects a Postgres server on localhost:5432 with a `postgres` user and
## database (adjust below). Run it with: roc examples/pool.roc
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.23.0/7NpDhuqoqGFedmVLvmm1zjq37GCmaFGzwr5sz4ch9wTK.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
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

main! = |_args| {
	pool = Pool.new!(
		effects,
		{
			host: "localhost",
			port: 5432,
			user: "postgres",
			database: "postgres",
			auth: NoAuth,
			timeout_ms: 5000,
			max_connections: 4,
		},
	)

	# First checkout dials and authenticates a fresh connection.
	client = Pool.acquire!(effects, pool)?
	greet!(client, "first checkout")?

	# Releasing parks the authenticated connection in the pool.
	Pool.release!(client)

	# The next checkout gets it back without a new handshake.
	client2 = Pool.acquire!(effects, pool)?
	greet!(client2, "second checkout")?

	# A prepared statement survives release and reacquire: on the same backend
	# it runs as prepared, on a different one command! re-parses transparently.
	double_cmd = Client.prepare!("select $1::int * 2 as doubled", { name: "double", client: client2 })?
	Pool.release!(client2)

	client3 = Pool.acquire!(effects, pool)?
	result = Client.command!(double_cmd.bind([Cmd.i32(21)]), client3)?
	doubled = PgResult.decode_one(result, |row| row.i32("doubled"))?
	Stdout.line!("21 doubled is ${doubled.to_str()}")?
	Pool.release!(client3)

	Ok({})
}

greet! = |client, checkout| {
	result = Client.command!(Cmd.new("select 'hello from ' || $1 as greeting").bind([Cmd.str(checkout)]), client)?
	greeting = PgResult.decode_one(result, |row| row.str("greeting"))?
	Stdout.line!(greeting)?
	Ok({})
}
