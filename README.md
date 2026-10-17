# roc-pg

A PostgreSQL client for Roc that checks every SQL query when the app compiles. When I say check, I mean _really_ checks: it has a complete parser from Postgres 18, so it can detect all sorts of issues. It also ingests a schema dump from your app so that it knows your complete database layout.

## What's it look like?

```roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pg.Client
import pg.Catalog
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

	planets = db.query!("SELECT id, name FROM planets WHERE gravity = $gravity", { gravity: 9.80665 })?

	for planet in planets {
		Stdout.line!("${planet.name} (#${I32.to_str(planet.id)})")?
	}

	db.close!()

	Ok({})
}
```
Isn't that sweet? Real SQL, but with named arguments (who doesn't want that?), and high type safety without ceremony.

What you get back is Roc records with the columns you asked for, with the correct types.

## How does it work?

It uses the Roc compiler's ability to parse strings at compile-time, and takes it quite far: it has a full PostgreSQL parser so that it understands your queries and schema as well as Postgres itself does.

You dump your database schema to a file, like `schema.sql`, and import that in your Roc program (see example above). When you migrate your database you dump the schema again to keep it updated (this is easily done with `pg_dump` but there'll be even easier tooling later!)

Since this is "just" parsing strings, `roc-pg` can give fast and correct feedback without ever having to connect to your database.

## How does it compare to X?

- Similar to [`sqlx`](https://github.com/transact-rs/sqlx), but it doesn't connect to your database to check queries. It just parses your files on disk.
- Similar to [`sqlc`](https://github.com/sqlc-dev/sqlc), but it doesn't generate code. You just run your queries and use the records you get back.

## What do we get?

Each of these is a compile error:

| Mistake | Query | Error |
|---------|-------|-------|
| Syntax error | `SELECT id, name FORM planets WHERE id = $id` | syntax error at or near "planets" (line 1, column 22) |
| Unknown table | `SELECT id, name FROM planet WHERE id = $id` | table `planet` does not exist in the schema (did you mean `planets`?) |
| Unknown column | `SELECT id, nmae AS name FROM moons WHERE planet_id = $planet_id` | column `nmae` does not exist in `moons` (did you mean `name`?) |
| Ambiguous column | `SELECT m.id, name FROM moons m JOIN planets p ON p.id = m.planet_id WHERE p.id = $planet_id` | column `name` is ambiguous: it is in `m` and `p` |
| Misspelled parameter | `... WHERE planet_id = $planet_idd` with `{ planet_id, }` | `$planet_idd` is not a field of the parameter record (did you mean `planet_id`?) |
| Unused parameter | `... WHERE planet_id = $planet_id` with `{ planet_id, name }` | the parameter record has a field `name`, but the query has no `$name` |
| Positional parameter | `... WHERE planet_id = $1` | use `$name` placeholders named after the fields of the parameter record, not `$1` (at line 1, column 46) |
| NULL into a NOT NULL column | `UPDATE planets SET name = $name ...` with `name : Try(Str, [Null])` | column `name` is NOT NULL, but `$name` is `Try(Str, [Null])` |
| Insert leaves out a required column | `INSERT INTO moons (name, created_at, updated_at) VALUES (...)` | column `planet_id` is NOT NULL and has no default, but the insert leaves it out |
| Row field the query does not return | `SELECT id, name FROM planets ...` into `{ id : I32, name : Str, climate : Try(Str, [Null]) }` | the row has a field `climate`, but the query returns no column by that name (it returns `id`, `name`) |
| Nullable column in a plain field | `SELECT id, climate FROM planets ...` into `{ id : I32, climate : Str }` | column `climate` can be NULL, so its field needs to be `Try(Str, [Null])` |
| Column made nullable by a LEFT JOIN | `SELECT c.name, s.name AS species FROM characters c LEFT JOIN species s ON ...` into `species : Str` | column `species` can be NULL, so its field needs to be `Try(Str, [Null])` |
| Wrong number type | `SELECT count(*) AS n FROM planets` into `{ n : I32 }` | column `n` is `bigint`, but its field is `I32` |
| Number type too narrow | `SELECT population FROM planets` (`integer`) into `{ population : I16 }` | column `population` is `integer`, but its field is `I16` |
| Column the query does not show is NOT NULL | `SELECT (tags)[1] AS tag FROM planets` into `{ tag : Str }` | column `tag` may be NULL as far as the query shows, so its field needs to be `Try(Str, [Null])`, ... |
| Values of different types | `SELECT id FROM planets UNION SELECT name FROM moons` | UNION types integer and text cannot be matched |
| Grouping | `SELECT allegiance, name, count(*) AS n FROM planets GROUP BY allegiance` | column `name` must appear in `group by` or be used in an aggregate |
| More than one statement | `DELETE FROM moons WHERE planet_id = $id; DELETE FROM planets WHERE id = $id` | cannot insert multiple commands into a prepared statement |

The compiler shows each one at the query:

```
── ✗ invalid string ───────────────────────────────────────── Mistakes.roc:15:46

The from_quote implementation for this string literal's type rejected it.

unknown_column! = |planet_id, db| db.query!("SELECT id, nmae AS name FROM moons WHERE planet_id = $planet_id", { planet_id, })
                                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

It returned this error message:

    column `nmae` does not exist in `moons` (did you mean `name`?)
```

Does it get any better than this?

## When the SQL isn't definitive

The checker never promises more than it can prove. A column it can't prove is `NOT NULL` needs a `Try(T, [Null])` field, just like one that can be NULL, so a NULL never turns into a decode error at runtime. You can always help the checker to prove what you know:

**NULL.** These show that a value is not NULL:

- `coalesce(x, ...)` with a last argument that is not NULL.
- `WHERE x IS NOT NULL`, or a comparison, `= any`, `IN`, `LIKE` or `BETWEEN` on `x` in the `WHERE` clause, joined by `AND`. Each of those drops the rows where `x` is NULL.
- `CASE WHEN x IS NOT NULL THEN ... x ... END`, and `CASE WHEN x IS NULL THEN ... ELSE ... x ... END`. An arm sees what its condition and the arms before it rule out.
- An inner join where you had a `LEFT JOIN`.
- A cast to a `NOT NULL` domain, such as `x::present` after `CREATE DOMAIN present AS integer NOT NULL`. The cast fails on a NULL, so what it gives is never NULL.
- A parameter is NULL only when its field is a `Try(T, [Null])`.

**Types.** The checker types columns, constants, operators, function calls, `CASE` and friends the way Postgres does. Where it can't, such as an array subscript or an extension's function, the column's type is checked when the query runs. A cast gives it a type the build can check: `(tags)[1]::text`. A cast on a parameter, `$x::integer`, tells the server and the checker which type the parameter is.

**Numbers.** A field takes a column only when it holds every value of the column, and a column takes a parameter only when it holds every value of the parameter:

| Column | Fields that take it |
|--------|---------------------|
| `smallint` | `I16`, `I32`, `I64`, `Dec`, `F32`, `F64` |
| `integer` | `I32`, `I64`, `Dec`, `F64` |
| `bigint` | `I64`, `Dec` |
| `numeric` | `Dec`, `Numeric` |
| `real` | `F32`, `F64` |
| `double precision` | `F64` |

Postgres has no unsigned integers, and no 8-bit ones. If you really want a `U8`, `U16`, `U32`, `U64` or `I8`, make a domain that bounds its values, and use it as the column's type:

```sql
CREATE DOMAIN u8 AS smallint CHECK (VALUE BETWEEN 0 AND 255);
```

A `u8` column then fits a `U8` field and takes a `U8` parameter. The checker reads the bounds from a domain's `CHECK` constraints, in the form above or as `pg_dump` writes it, `((VALUE >= 0) AND (VALUE <= 255))`. A domain over `bigint` with `CHECK (VALUE >= 0)` fits a `U64` field, but takes no `U64` parameter, as a `U64` can be larger than any `bigint`. Domains cost nothing at runtime: the values decode just like the base type's.

**What the checker can't see.** A relation's columns are unknown, and its queries' columns need `Try` fields or the proofs above, when it is:

- a table of a composite type (`OF type`), or a child of a table the dump does not have,
- a function in `FROM` that returns `record` without a column definition list, `AS t(a int, b text)`,
- a view or CTE whose own query the checker can't type, or a recursive CTE's reference to itself,
- a table of an extension, or of `pg_catalog` or `information_schema`,
- anything at all with [NoSchema], which checks syntax and parameters only. Without a schema a NULL in a plain field is found when the row decodes.

## Decimal numbers

Use `Dec` for most decimal numbers. It is fast and holds 18 digits after the point and about 20 before it, which is plenty for money and most measurements. A `numeric` with more places decodes into a `Dec` rounded to 18 of them, half away from zero.

Use `Numeric` only when you need the extra precision, or a number too large for a `Dec`. It is exact and of any size, keeps its scale like Postgres does (`1.50` stays `1.50`), and adds, subtracts, multiplies and divides as Postgres does. Division gives the same digits as Postgres's `/`, so `1 / 3` is `0.33333333333333333333`. It is slower than a `Dec`.

## Schemas and the search path

A table or function named without a schema is looked up the way the server does it: in `pg_catalog`, then in each schema of the search path in order. The search path is `["public"]` unless you set it, and it must be the same as the one the server uses for the app's connections:

```roc
parsed_schema = Catalog.from_schema(schema_sql).with_search_path(["app", "public"])
```

## Checking the database at startup

The checker checks against `schema.sql`, not against the database. When the database has moved on, a query that compiled can still fail. `db.verify_schema!()` compares the two once, after connecting, and fails with every difference: a missing table, a missing or added column, a column whose type or NULL-ness differs. Views aren't compared.

```roc
db.verify_schema!()?
```

When the build could not see a row field's column type, the query checks that column's type against the server's result description each time it runs. That check runs after the statement did, so an `UPDATE ... RETURNING` has changed rows by the time it fails.

A checked query whose result has two columns named after one field fails with `DuplicateColumn`, as either could fill it. An unchecked row reads the first such column, as libpq does.

## Getting started

Use the Roc version that's recommended in the `roc-pg` release you're using (it says in the release notes) or our Nix flake. Then step into one of the examples, `minimal`, and

```sh
cd examples/minimal
```

Check the app:

```sh
roc check main.roc
```

Build it:

```sh
roc build main.roc --output=app
```

## Examples

Start with [the minimal example](examples/minimal/main.roc) which shows how to use `roc-pg`. The other examples (`small`, and `rebellion`) are mainly for performance optimizations of the Roc compiler and `roc-pg` itself.

## Not supported

- `LISTEN` and `NOTIFY`. A session can run them, but the client never delivers a notification. It reads past any that arrive.

## Tests

```sh
nix develop -c roc test package/main.roc
```

runs the package's unit tests. `nix develop -c ./tests.roc` runs everything, including a check of every example and integration tests against a temporary Postgres, which the development shell provides.
