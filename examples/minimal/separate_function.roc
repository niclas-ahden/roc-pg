app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pg.Client
import pg.Catalog
import pg.Sql
import "schema.sql" as schema_sql : Str

catalog : Catalog
catalog = Catalog.from_schema(schema_sql)

Schema := [].{
	catalog : {} -> Catalog
	catalog = |{}| catalog
}

Planet : { id : I32, name : Str }

older_than : Sql.Sql(Schema, { min_age : I32 }, Planet)
older_than = "SELECT id, name FROM planets WHERE age > $min_age ORDER BY name"

main! = |_| {
	db : Client.Client(Tcp.Stream, Schema)
	db = Client.connect_url!("some-database-url", { connect!: Tcp.connect!, random_u64!: Random.seed_u64! })?

	planets = db.query!(older_than, { min_age: 5 })?

	for planet in planets {
		Stdout.line!("${planet.name} (#${I32.to_str(planet.id)})")?
	}

	db.close!()

	Ok({})
}
