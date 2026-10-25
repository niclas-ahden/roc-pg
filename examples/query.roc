## Connect, run a query with parameters, and decode rows by column name.
##
## Expects a Postgres server on localhost:5432 with a `postgres` user and
## database (adjust below). Run it with: roc examples/query.roc
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

	# Every row, decoded by column name. A missing column, a NULL or a value
	# that doesn't fit the type is an error rather than a crash.
	people = client.query_unchecked!(
		"select name, age from (values ('John', 25), ('Julio', 23), ('Sara', 17)) as people (name, age) where age > $1",
		[Param.u8(18)],
		|row| Ok({ name: row.str("name")?, age: row.u8("age")? }),
	)?

	for person in people {
		Stdout.line!("${person.name}: ${person.age.to_str()}")?
	}

	# Exactly one row, or EmptyResult / MultipleRows.
	oldest = client.query_one_unchecked!(
		"select name from (values ('John', 25), ('Julio', 23)) as people (name, age) order by age desc limit 1",
		[],
		|row| row.str("name"),
	)?
	Stdout.line!("oldest: ${oldest}")?

	# Arrays go in as a list of params and come back as a list.
	tags = client.query_one_unchecked!(
		"select $1::text[] as tags",
		[Param.list([Param.str("roc"), Param.str("postgres")])],
		|row| row.str_list("tags"),
	)?
	Stdout.line!("tags: ${Str.join_with(tags, ", ")}")?

	client.close!()
	Ok({})
}
