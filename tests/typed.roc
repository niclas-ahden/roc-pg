## Integration tests of the checked query API against a real Postgres
## server: named parameters from a record, rows decoded into records, and
## the checks that happen when a query runs.
##
## Normally run by ./tests.roc. By hand:
##
##     roc tests/typed.roc <host> <port> <user> <database>
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pf.OsStr
import pg.Client
import pg.Catalog
import pg.Numeric

## The schema the queries below are checked against. An app imports its
## `schema.sql` instead of writing it inline.
schema_sql =
	\\CREATE TABLE public.typed_people (
	\\    id integer NOT NULL,
	\\    name text NOT NULL,
	\\    email text,
	\\    age integer,
	\\    tags text[] NOT NULL,
	\\    score numeric NOT NULL
	\\);
	\\
	\\CREATE TABLE public.typed_badges (
	\\    person_id integer NOT NULL
	\\);
	\\
	\\CREATE DOMAIN public.typed_u8 AS smallint CHECK (VALUE BETWEEN 0 AND 255);
	\\CREATE TABLE public.typed_pixels (red public.typed_u8 NOT NULL);

parsed_schema = Catalog.from_schema(schema_sql)

Schema := [].{ catalog = |{}| parsed_schema }

Db : Client.Client(Tcp.Stream, Schema)

Person : { id : I32, name : Str, email : Try(Str, [Null]), tags : List(Str), score : Dec }

check : Str, Bool -> Try({}, [TestFailed(Str)])
check = |label, ok| if ok Ok({}) else Err(TestFailed(label))

main! : List(OsStr) => Try({}, _)
main! = |args| {
	{ host, port, user, database } =
		match args {
			[host_arg, port_arg, user_arg, database_arg] => {
				port_num = U16.from_str(OsStr.display(port_arg)) ? |_| InvalidPortArg
				Ok({ host: OsStr.display(host_arg), port: port_num, user: OsStr.display(user_arg), database: OsStr.display(database_arg) })
			}
			_ => Err(UsageArgs("host port user database"))
		}?
	client = Client.connect!({ connect!: Tcp.connect!, random_u64!: Random.seed_u64!, host, port, user, database, auth: NoAuth, timeout_ms: 5000 })?
	_ = client.execute_unchecked!("drop table if exists typed_people", [])?
	_ = client.execute_unchecked!("create table typed_people (id integer not null, name text not null, email text, age integer, tags text[] not null, score numeric not null)", [])?
	# The schema above lacks `name`, as when the database got a column
	# before the app was rebuilt.
	_ = client.execute_unchecked!("drop table if exists typed_badges", [])?
	_ = client.execute_unchecked!("create table typed_badges (person_id integer not null, name text not null)", [])?
	_ = client.execute_unchecked!("drop table if exists typed_pixels", [])?
	_ = client.execute_unchecked!("drop domain if exists typed_u8", [])?
	_ = client.execute_unchecked!("create domain typed_u8 as smallint check (value between 0 and 255)", [])?
	_ = client.execute_unchecked!("create table typed_pixels (red typed_u8 not null)", [])?

	test_insert_and_select!(client)?
	test_one_and_optional!(client)?
	test_optional_filters!(client)?
	test_runtime_checks!(client)?
	test_transaction!(client)?

	_ = client.execute_unchecked!("drop table typed_people", [])?
	client.close!()
	Stdout.line!("all typed tests passed")?
	Ok({})
}

## Named parameters in, records out: NULL both ways, arrays both ways.
test_insert_and_select! : Db => Try({}, _)
test_insert_and_select! = |db| {
	no_email : Try(Str, [Null])
	no_email = Err(Null)
	ada_email : Try(Str, [Null])
	ada_email = Ok("ada@example.com")
	no_tags : List(Str)
	no_tags = []
	inserted = db.execute!(
		"insert into typed_people (id, name, email, age, tags, score) values ($id, $name, $email, $age, $tags, $score)",
		{ id: 1.I32, name: "Ada", email: ada_email, age: 36.I32, tags: ["math", "engines"], score: 9.5 },
	)?
	check("execute! inserts one row", inserted == 1)?
	_ = db.execute!(
		"insert into typed_people (id, name, email, age, tags, score) values ($id, $name, $email, $age, $tags, $score)",
		{ id: 2.I32, name: "Grace", email: no_email, age: 85.I32, tags: no_tags, score: 10 },
	)?

	people : List(Person)
	people = db.query!("select id, name, email, tags, score from typed_people where age > $min_age order by id", { min_age: 18.I32 })?
	check(
		"query! decodes rows",
		people
		== [
			{ id: 1, name: "Ada", email: Ok("ada@example.com"), tags: ["math", "engines"], score: 9.5 },
			{ id: 2, name: "Grace", email: Err(Null), tags: [], score: 10 },
		],
	)?

	# A parameter used twice is sent once.
	names : List({ name : Str })
	names = db.query!("select name from typed_people where id = $id or (id > $id and name = $name) order by name", { id: 1.I32, name: "Grace" })?
	check("a placeholder used twice", names == [{ name: "Ada" }, { name: "Grace" }])?
	Stdout.line!("ok: typed insert and select")
}

test_one_and_optional! : Db => Try({}, _)
test_one_and_optional! = |db| {
	one : { name : Str }
	one = db.query_one!("select name from typed_people where id = $id", { id: 2.I32 })?
	check("query_one!", one == { name: "Grace" })?

	found : Try({ name : Str }, [NotFound])
	found = db.query_optional!("select name from typed_people where id = $id", { id: 1.I32 })?
	check("query_optional! found", found == Ok({ name: "Ada" }))?

	missing : Try({ name : Str }, [NotFound])
	missing = db.query_optional!("select name from typed_people where id = $id", { id: 99.I32 })?
	check("query_optional! not found", missing == Err(NotFound))?

	many : Try({ name : Str }, _)
	many = db.query_one!("select name from typed_people", {})
	check(
		"query_one! with two rows",
		match many {
			Err(MultipleRows(2)) => Bool.True
			_ => Bool.False
		},
	)?
	Stdout.line!("ok: typed one and optional")
}

## What only running the query tells: what the server says about the
## result, and the values themselves. Everything the analysis can see is
## checked at compile time, see tests/checked_sql_errors.roc.
test_runtime_checks! : Db => Try({}, _)
test_runtime_checks! = |db| {
	# An array subscript hides the type from the analysis, not from the
	# server's description of the result.
	total : Try(List({ total : Try(I32, [Null]) }), _)
	total = db.query!("select (array[sum(age)])[1] as total from typed_people", {})
	check(
		"a column type that does not fit its field",
		match total {
			Err(PgTypeMismatch({ column: "total", type: "bigint", field: "I32" })) => Bool.True
			_ => Bool.False
		},
	)?

	# An array subscript can be NULL, which the field must take.
	null_age : List({ age : Try(I32, [Null]) })
	null_age = db.query!("select (array[nullif(age, 85)])[1] as age from typed_people where id = $id", { id: 2.I32 })?
	check("NULL in a field that takes it", null_age == [{ age: Err(Null) }])?
	# The server reports a domain's column as its base type, smallint here,
	# which the build already saw fits the U8.
	_ = db.execute!("insert into typed_pixels (red) values ($red)", { red: 200.U8 })?
	reds : List({ red : U8 })
	reds = db.query!("select red from typed_pixels", {})?
	check("a bounded domain into a narrower field", reds == [{ red: 200 }])?

	# The dump above lacks the badge's name, as a dump older than the
	# database would.
	check(
		"a database that differs from the dump",
		match db.verify_schema!() {
			Err(SchemaDiffers(differences)) => differences == ["column `public.typed_badges.name` is in the database but not in the dump"]
			_ => Bool.False
		},
	)?

	# A Numeric keeps every digit the server gives, and goes back exact.
	exact : List({ x : Numeric })
	exact = db.query!("select $third::numeric / 3 as x", { third: Numeric.from_i128(1) })?
	check("a numeric division into a Numeric", exact.map(|r| r.x.to_str()) == ["0.33333333333333333333"])?
	back : List({ same : Bool })
	back = db.query!("select $x = 0.33333333333333333333 as same", { x: (exact.first() ?? { x: Numeric.from_i128(0) }).x })?
	check("a Numeric parameter", back == [{ same: Bool.True }])?

	# numeric division gives 20 places here, a Dec keeps 18.
	third : List({ x : Dec })
	third = db.query!("select 1::numeric / 3 as x", {})?
	check("a numeric with more places than a Dec", third == [{ x: 0.333333333333333333 }])?

	# The build sees one `name`, the server returns the badge's too.
	_ = db.execute_unchecked!("insert into typed_badges values (2, 'pioneer')", [])?
	badges : Try(List({ person_id : I32, name : Str }), _)
	badges = db.query!("select b.*, p.name from typed_badges b join typed_people p on p.id = b.person_id", {})
	check(
		"two columns named after one field",
		match badges {
			Err(DuplicateColumn("name")) => Bool.True
			_ => Bool.False
		},
	)?
	Stdout.line!("ok: typed runtime checks")
}

## One query with optional filters: `Err(Null)` turns a filter off.
search! : Try(Str, [Null]), Try(I32, [Null]), Db => Try(List({ name : Str }), _)
search! = |name, min_age, db|
	db.query!(
		"select name from typed_people where ($name::text is null or name = $name) and ($min_age::integer is null or age >= $min_age) order by id",
		{ name, min_age },
	)

test_optional_filters! : Db => Try({}, _)
test_optional_filters! = |db| {
	any_name : Try(Str, [Null])
	any_name = Err(Null)
	any_age : Try(I32, [Null])
	any_age = Err(Null)

	everyone = search!(any_name, any_age, db)?
	check("optional filters: none set", everyone == [{ name: "Ada" }, { name: "Grace" }])?
	by_name = search!(Ok("Grace"), any_age, db)?
	check("optional filters: name", by_name == [{ name: "Grace" }])?
	by_age = search!(any_name, Ok(50), db)?
	check("optional filters: age", by_age == [{ name: "Grace" }])?
	both = search!(Ok("Ada"), Ok(50), db)?
	check("optional filters: both", both == [])?
	Stdout.line!("ok: optional filters")
}

## A named body function, annotated. A body whose row type is only inferred
## from how the result is used works too.
bonus_and_count! : Db => Try({ n : I64 }, _)
bonus_and_count! = |tx| {
	_ = tx.execute!("update typed_people set score = score + $bonus where id = $id", { bonus: 1, id: 1.I32 })?
	tx.query_one!("select count(*) as n from typed_people where score > $min", { min: 10 })
}

test_transaction! : Db => Try({}, _)
test_transaction! = |db| {
	count = db.transaction!(bonus_and_count!)?
	check("typed queries in a transaction", count == { n: 1 })?
	Stdout.line!("ok: typed transaction")
}
