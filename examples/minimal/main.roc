app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.28.1/7brgwR8YUqfeGrkdfF1V4GPPN7DnP7ftqub9KcrTEZtr.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Duration
import pf.Random
import pg.Client
import pg.Catalog
import "schema.sql" as schema_sql : Str

schema_catalog : Catalog
schema_catalog = Catalog.from_schema(schema_sql)

Schema := [].{
	catalog : {} -> Catalog
	catalog = |{}| schema_catalog
}

main! = |_| {
	db : Client.Client(Tcp.Connection, Schema)
	db = Client.connect_url!("some-database-url", { connect!: |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(35) }), random_u64!: Random.seed_u64!, statement_timeout: Duration.seconds(30) })?

	planets = db.query!("SELECT id, name FROM planets", {})?

	for planet in planets {
		Stdout.line!("${planet.name} (#${I32.to_str(planet.id)})")?
	}

	db.close!()

	Ok({})
}
