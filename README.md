# roc-pg-insane-in-the-membrane

A PostgreSQL client for Roc that checks every SQL query when the app compiles. When I say check, I mean _really_ checks: it has a complete parser from Postgres 18, so it can detect all sorts of issues. It also ingests a schema dump from your app so that it knows your complete database layout. omg.

The checking works, but it's not fast. Two examples measure and profile that, on my machine, with Roc `7d7b432` and a cold cache:

- [examples/small](examples/small/) is one table and 20 queries. `roc check` takes about 9 seconds and 5 GB of memory, and `roc build` about 63 seconds and 9 GB.
- [examples/rebellion](examples/rebellion/) is sized like a real production app. `roc check` takes about 24 seconds and 10 GB.

An app that runs only unchecked queries pays none of that: the parser is compiled only for an app that checks a query.

## What's it look like?

```roc
import "schema.sql" as schema_sql : Str

parsed_schema = Catalog.from_schema(schema_sql)

Schema := [].{ catalog = |{}| parsed_schema }

Db : Client.Client(Tcp.Stream, Schema)

moons! : I32, Db => Try(List({ id : I32, name : Str }), _)
moons! = |planet_id, db|
	db.query!("SELECT id, name FROM moons WHERE planet_id = $planet_id ORDER BY name", { planet_id, })
```
Isn't that sweet? Real SQL, but with named arguments (who doesn't want that?), and low friction but high type safety.

The compiler checks a query through its type alone, so the schema rides on a type, `Schema`. Keep the parsed dump in a top-level constant as above: parsing it inside `catalog` would parse it again for every query.

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

## Telling the checker more

The checker never promises more than it can prove. A column it can't prove is `NOT NULL` needs a `Try(T, [Null])` field, just like one that can be NULL, so a NULL never turns into a decode error at runtime. When you know better, say so in the SQL, in a way the checker can see.

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

Postgres has no unsigned integers, and no 8-bit ones. For a `U8`, `U16`, `U32`, `U64` or `I8`, make a domain that bounds its values, and use it as the column's type:

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

Use Roc `7d7b432` (there's a flake if you're using Nix). Then step into one of the examples, `small` for a quick loop or `rebellion` for the full size:

```sh
cd examples/small
```

Check the app:

```sh
time roc check main.roc
```

Build it:

```sh
time roc build main.roc --output=app
```

## Examples

### small

[main.roc](examples/small/main.roc) has 20 queries over the `planets` table of a one-table [schema.sql](examples/small/schema.sql). Each query returns its own 8-field record: `id`, `name` and a different run of six more columns. Everything else is the same in every query, so it isolates the cost of row types (see [Where the time goes](#where-the-time-goes)).

### rebellion

`rebellion` is a large example modeled after a real production web app to make it realistic.

- [schema.sql](examples/rebellion/schema.sql) is the `pg_dump --schema-only` the queries are checked against, followed by a data dump of `schema_migrations`, as a Rails app's dump looks.
- [Schema.roc](examples/rebellion/Schema.roc) reads it into the catalog.
- Each area of the database has a module with its queries: `Galaxy.roc`, `Personnel.roc`, `Fleet.roc`, `Missions.roc` and nine more. Most queries are short lookups by key. There are also wide detail views, reports with CASE, coalesce and scalar subqueries, `UPDATE`s with up to 26 parameters, `INSERT`s, upserts and a few `DELETE`s. Each query has its own row type, as in a real app.
- [main.roc](examples/rebellion/main.roc) dispatches to each module's `run!`, which gives every query a command, such as `rebellion <database url> galaxy planet Hoth`. A query is only checked when `main!` can reach it, so a query without a command would not be part of the measurement.

## Build times

Measured on an AMD 9950X, 32 core machine with Roc `7d7b432`, from a cold cache:

| App | Command | Time and peak memory |
|-----|---------|----------------------|
| `small` | `roc check` | 9 s, 4.9 GB |
| `small` | `roc build` | 63 s, 9.0 GB |
| `rebellion` | `roc check` | 23 to 26 s, 9.7 GB |
| [examples/query.roc](examples/query.roc), unchecked queries only | `roc check` | 0.23 s, 0.28 GB |
| [examples/query.roc](examples/query.roc), unchecked queries only | `roc build` | 4.1 s, 0.66 GB |

For comparison, the real app rebellion is modeled on builds in about 7 seconds on [roc-pg](https://github.com/niclas-ahden/roc-pg), which does not check queries.

### Where the time goes

Measured with Roc `b797cda`, before the numbers above:

**A fixed cost for the parser.** The first checked query adds about 6 seconds, when the compiler lowers the parser and the analysis for compile-time evaluation. An app without a checked query doesn't compile the parser at all. Earlier profiling found three hotspots, each growing with the size of the 222-variant `Node` type of the parse tree:

- The exhaustiveness check of every `match` on `Node` is quadratic in the number of variants.
- Every construction `Node.C(...)` rebuilds the union. `Actions.roc` has about 4,700 of them.
- Monotype lowering spends most of its time in interface relations.

**A cost for each row type, in `roc build` only.** Every distinct row type adds build time in proportion to its number of fields. These apps have 20 queries each against the rebellion schema:

| Each query returns | `roc build` |
|--------------------|-------------|
| The same 2-field row type | 35 s |
| Its own 2-field row type | 49 s |
| Its own 8-field row type | 96 s |
| Its own 8-field row type, without a schema (`NoSchema`) | 96 s |

That is about 0.4 seconds for each field of each distinct row type, whether or not there is a schema. The same 20 queries check in about 26 seconds either way. `small` shows the same at a realistic mix of column types: 130 seconds with a row type for each query, 46 seconds when they all share one. rebellion has 212 distinct row types, many of them wide, which is most likely why its build takes more than 30 minutes.

## Not supported

- `LISTEN` and `NOTIFY`. A session can run them, but the client never delivers a notification. It reads past any that arrive.

## Structure

- `Scan.roc` (a port of Postgres's lexer) and `Parse.roc` (Postgres's parser loop, driven by the tables in `Grammar.roc`) parse the SQL. `Actions.roc` builds the parse tree out of `Node.roc`'s types, one function per rule of `gram.y`.
- `Dump.roc` reads `schema.sql`, with the same parser. `Catalog.roc` wraps it for apps, and its `check` runs everything a checked query is checked for.
- `Check.roc` walks the tree against the dump in one pass, bottom up: tables, columns, parameters, row fields, NULL. `Overload.roc` picks functions and operators by argument types, and finds the type values share, using the built in types and functions in `Builtins.roc`.
- `PgType.roc` says which Roc types hold which Postgres types' values, both for the build and when a query runs.
- `Sql.roc` is the type of a checked query. It reaches the checker only through the schema type's catalog, so `Client.roc` and an app with only unchecked queries never compile the parser.

`Grammar.roc`, `Node.roc`, `Enums.roc`, `Actions.roc`, `Keywords.roc` and `Builtins.roc` are generated from Postgres's sources by the programs in `tools/`.

When changing or regenerating code, follow the
[code-generation guidelines](docs/code-generation-guidelines.md). They explain
the representation, reuse, correctness, and measurement principles behind the
generated-action cleanup, with a checklist for future generation agents.

## Tests

```sh
nix develop -c roc test package/main.roc
```

runs the package's unit tests. `nix develop -c ./tests.roc` runs everything, including a check of every example and integration tests against a temporary Postgres, which the development shell provides.
