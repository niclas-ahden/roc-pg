## Connect, run a query with bindings, and decode rows by column name.
##
## Expects a Postgres server on localhost:5432 with a `postgres` user and
## database (adjust below). Run it with: roc examples/query.roc
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.23.0/7NpDhuqoqGFedmVLvmm1zjq37GCmaFGzwr5sz4ch9wTK.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pg.Client
import pg.Cmd
import pg.PgResult

# The package implements the wire protocol in pure Roc and never names
# platform types, so the app hands it the platform's TCP functions once.
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
	client = Client.connect!(
		effects,
		{
			host: "localhost",
			port: 5432,
			user: "postgres",
			database: "postgres",
			auth: NoAuth,
			timeout_ms: 5000,
		},
	)?

	Stdout.line!("Connected!")?

	cmd = 
		Cmd.new("select name, age from (values ('John', 25), ('Julio', 23), ('Sara', 17)) as people (name, age) where age > $1")
			.bind([Cmd.u8(18)])

	result = Client.command!(cmd, client)?

	people = PgResult.decode(
		result,
		|row| {
			name = row.str("name")?
			age = row.u8("age")?
			Ok({ name, age })
		},
	)?

	for person in people {
		Stdout.line!("${person.name}: ${person.age.to_str()}")?
	}

	Client.close!(client)
	Ok({})
}
