# roc-pg-insane-in-the-membrane

A PostgreSQL client for Roc that checks every SQL query when the app compiles. When I say check, I mean _really_ checks: it has a complete parser from Postgres 18, so it can detect all sorts of issues. It also ingests a schema dump from your app so that it knows your complete database layout. omg.

The checking works, but it's not fast. Two examples measure and profile that, on my machine:

- [examples/small](examples/small/) is one table and 20 queries. `roc check` takes about 30 seconds and 14 GB of memory, and `roc build` about 2 minutes and 15 GB.
- [examples/rebellion](examples/rebellion/) is sized like a real production app. `roc check` takes about 35 seconds and 17 GB, and `roc build` more than 30 minutes and 25 GB.

These timings predate the generated-action cleanup and compiler cache improvements.

## What's it look like?

```roc
moons! : I32, Db => Try(List({ id : I32, name : Str }), _)
moons! = |planet_id, db|
	db.query!("SELECT id, name FROM moons WHERE planet_id = $planet_id ORDER BY name", { planet_id, })
```
Isn't that sweet? Real SQL, but with named arguments (who doesn't want that?), and low friction but high type safety.

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

## Getting started

Use Roc `b797cda` (there's a flake if you're using Nix). Then step into one of the examples, `small` for a quick loop or `rebellion` for the full size:

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

Measured on an AMD 9950X, 32 core machine with Roc `b797cda`:

`small`:

| Command | Time and peak memory |
|---------|----------------------|
| `roc check` | 28 s, 13.6 GB |
| `roc build` | 130 s, 15.0 GB |
| `roc build`, with all 20 queries sharing one row type | 46 s, 13.9 GB |

`rebellion`:

| Command | Time and peak memory |
|---------|----------------------|
| `roc check`, cold cache | 60 s, 20.2 GB |
| `roc check`, nothing changed | 34 s, 16.6 GB |
| `roc check` after editing one query | 34 s, 16.7 GB |
| `roc build` | did not finish in 30 minutes, 25.5 GB when stopped |

For comparison, the real app rebellion is modeled on builds in about 7 seconds on [roc-pg](https://github.com/niclas-ahden/roc-pg), which does not check queries.

### Where the time goes

**A fixed cost for the parser.** An app that imports the package and checks no query takes about 10 seconds and 10 GB to build. The first checked query adds about 6 seconds, when the compiler lowers the parser and the analysis for compile-time evaluation. Earlier profiling found three hotspots, each growing with the size of the 222-variant `Node` type of the parse tree:

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
- `Catalog.roc` reads `schema.sql`, with the same parser.
- `Check.roc` walks the tree against the catalog: tables, columns, parameters, row fields, NULL. `Overload.roc` picks functions and operators by argument types, using the built in types and functions in `Builtins.roc`.

`Grammar.roc`, `Node.roc`, `Enums.roc`, `Actions.roc`, `Keywords.roc` and `Builtins.roc` are generated from Postgres's sources by the programs in `tools/`.

When changing or regenerating code, follow the
[code-generation guidelines](docs/code-generation-guidelines.md). They explain
the representation, reuse, correctness, and measurement principles behind the
generated-action cleanup, with a checklist for future generation agents.

## Tests

```sh
nix develop -c roc test package/main.roc
```

runs the package's 376 unit tests. `nix develop -c ./tests.roc` runs everything, including a check of every example and integration tests against a temporary Postgres, which the development shell provides.
