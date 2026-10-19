app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pg.Client
import pg.Catalog
import pg.Hole
import "schema.sql" as schema_sql : Str

catalog : Catalog
catalog = Catalog.from_schema(schema_sql)

Schema := [].{
	catalog : {} -> Catalog
	catalog = |{}| catalog
}

main! = |_| {
	db : Client.Client(Tcp.Stream, Schema)
	db = Client.connect_url!("some-database-url", { connect!: Tcp.connect!, random_u64!: Random.seed_u64! })?

	## Current solution
	# `min_age` defaults to `Dec` and needs `.I32` to pin it
	# Error: column `age` is `integer`, but `$min_age` is `Dec`
	current = db.query!("SELECT id, name FROM planets WHERE age > $min_age", { min_age: 5 })?

	# Disallows using named arguments in the wrong spot (error message needs improvement)
	# Error: syntax error at or near "$1" (line 1, column 30)
	current_broken = db.query!("SELECT id, name FROM planets $min_age age > 5", { min_age: 5 })?

	## Interpolation
	# Same as above
	# Error: column `age` is `integer`, but interpolation 1 is `Dec`
	interpolated = 5
	variable = db.query_interpolated!("SELECT id, name FROM planets WHERE age > ${interpolated}")?
	literal = db.query_interpolated!("SELECT id, name FROM planets WHERE age > ${5}")?

	# All values in one query must have the same type?
	# Error: type mismatch: This string literal must have the same type as a number literal, and nothing in
	mixed = db.query_interpolated!("SELECT id, name FROM planets WHERE age > ${5} AND name <> ${"Earth"}")?

	## Interpolation with a wrapper type using `from_numeral` and `from_quote`
	# Works fine
	id = 5
	name = "foo"
	tagged = db.query_tagged!("SELECT id, name FROM planets WHERE age > ${5} AND name <> ${"Earth"} AND id <> ${id} AND name <> ${name}")?

	# But doesn't work when a variable's type is pinned (since we use `from_*`)
	# Error: type mismatch: This expression is used in an unexpected way.
	pinned = 5.I32
	tagged_pinned = db.query_tagged!("SELECT id, name FROM planets WHERE age > ${pinned}")?

	# And allows type mismatches at comp-time which fail at runtime
	# Runtime error: PgErr "invalid input syntax for type integer: \"old\""
	str = "old"
	tagged_mismatch = db.query_tagged!("SELECT id, name FROM planets WHERE age > ${str}")?

	for planet in [current, current_broken, variable, literal, mixed, tagged, tagged_pinned, tagged_mismatch].join() {
		# Here we do need the `I32.to_str` to pin the type
		Stdout.line!("${planet.name} (#${I32.to_str(planet.id)})")?
	}

	db.close!()

	Ok({})
}
