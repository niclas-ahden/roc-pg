# roc-pg

A PostgreSQL client for Roc that checks every SQL query when the app compiles. When I say check, I mean _really_ checks: it has a complete parser from Postgres 18, so it can detect all sorts of issues. It also ingests a schema dump from your app so that it knows your complete database layout.

## What's it look like?

```roc
app [main!] {
    pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
    pg: "https://github.com/niclas-ahden/roc-pg/releases/download/0.5.0/3RhKioDLx8pWHv72xyu4Dc3U3xyWQiAokmBXyezbPSxr.tar.zst",
}

import pf.Stdout
import pf.Tcp
import pf.Duration
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
    db : Client.Client(Tcp.Connection, Schema)
    db = Client.connect_url!(
        "some-database-url",
        {
            connect!: |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(35) }),
            random_u64!: Random.seed_u64!,
            statement_timeout: Duration.seconds(30),
        },
    )?

    planets = db.query!("SELECT id, name FROM planets WHERE gravity = $gravity", { gravity: 9.80665 })?

    for planet in planets {
        Stdout.line!("${planet.name} (ID ${I32.to_str(planet.id)})")?
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

For your own app, dump your database's schema next to `main.roc` and import it as in [the example above](#whats-it-look-like):

```sh
pg_dump --schema-only --no-owner mydb > schema.sql
```

Dump it again after each migration so the checks match the database. We'll provide tooling for this later.

## Examples

Start with [the minimal example](examples/minimal/main.roc) which shows how to use `roc-pg`. The other examples (`small`, and `rebellion`) are mainly for performance optimizations of the Roc compiler and `roc-pg` itself.

## How does it compare to X?

There are many great Postgres clients and these are some similar ones:

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

## Arrays and enums

A `List` in the parameter record is sent as a Postgres array. Use it with `= any(...)` to match a column against every element of the list:

```roc
ids : List(I32)
ids = [1, 5, 8]

users = db.query!("SELECT id, name FROM users WHERE id = any($ids)", { ids, })?
```

The build checks that the elements fit the column. A number literal on its own is a `Dec` in Roc, which is why `ids` has a type above. Without it the build says that `id` is `integer`, so `$ids` must be a list of it, but it is `List(Dec)`.

Arrays work in the other direction too. A `text[]` column goes into a `List(Str)` field, and a `List` parameter fills an array column, as in `UPDATE users SET tags = $tags`.

An enum label is a `Str`, as a parameter and as a field. With this schema:

```sql
CREATE TYPE public.role AS ENUM ('admin', 'editor', 'viewer');
CREATE TABLE public.users (id integer NOT NULL, name text NOT NULL, role public.role NOT NULL);
```

you write:

```roc
editors = db.query!("SELECT name, role FROM users WHERE role = any($roles)", { roles: ["admin", "editor"] })?

_ = db.execute!("UPDATE users SET role = $role WHERE id = $id", { role: "viewer", id: user_id })?
```

and `editors` is a `List({ name : Str, role : Str })`. The build doesn't check the labels themselves. A label the enum doesn't have, such as `"admn"`, fails when the query runs, with a `PgErr` from the server.

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

## Queries built at runtime

`query!` and the other checked functions take the SQL as a string literal, since the build reads it. For SQL that the app puts together while it runs there are unchecked versions: `query_unchecked!`, `query_one_unchecked!`, `query_optional_unchecked!`, `execute_unchecked!`, `pipeline_unchecked!` and `batch_execute_unchecked!`. They take positional placeholders (`$1`, `$2`, ...), a list of `Param`s, and a function that decodes each row by column name:

```roc
import pg.Param

ids = db.query_unchecked!(
	"SELECT id FROM users WHERE role = any($1)",
	[Param.list(roles.map(Param.str))],
	|row| row.i32("id"),
)?
```

Nothing about them is checked before they run. `Param.str`, `Param.i32`, `Param.bool`, `Param.null` and friends make the parameters, and `Param.list` makes an array of them. A row has accessors such as `row.str("name")`, `row.i64("id")`, `row.str_list("tags")` and `row.list("ids", decode_elem)`.

## Connecting

`Client.connect!` takes the connection settings as fields, and `Client.connect_url!` takes them as a URL (see the example at the top). Both also take two functions from the platform: `connect!`, which opens a TCP connection to a host and port with the timeouts you want, and `random_u64!`, which a SCRAM login needs. Both take a `statement_timeout` too (see [Timeouts](#timeouts)).

### Platforms

- [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli): pass `connect!: |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(35) })` and `Random.seed_u64!`. The client is a `Client.Client(Tcp.Connection, Schema)`. Any platform whose TCP connections have `write_bytes!` and `read_exactly!` methods works the same way.
- [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver): its connections name their write `write!`, so wrap its dial, `connect!: Client.basic_webserver(Tcp.connect!)`. The platform gives each connect, read and write a fixed 30 seconds. It has no `Duration`, so give the statement timeout as `statement_timeout: Client.millis(25_000)`. It has no random numbers either, so pass `random_u64!: || Err(NoRandom)`. That rules out SCRAM logins there, so log in another way, such as trust or md5. The client is then a `Client.Client(Client.BasicWebserver(Tcp.Connection), Schema)`.

### Authentication

`auth` is `NoAuth` or `Password(str)`. The server decides how it checks a password, and the client answers each of PostgreSQL's three password methods: SCRAM-SHA-256 (PostgreSQL 10 or later, with [roc-scram](https://github.com/niclas-ahden/roc-scram)), md5 (with [roc-md5](https://github.com/niclas-ahden/roc-md5)) and cleartext. The optional `auth_methods` lists the logins the client agrees to, named as in pg_hba.conf:

- `Scram`: SCRAM-SHA-256.
- `Md5`: an md5 hash of the password.
- `Cleartext`: the password itself (pg_hba's `password`).
- `Trust`: no login at all, the server lets the client in unasked.

A login the server asks for that is not listed fails with `AuthMethodNotAllowed(method)`. By default all four are allowed. An app that knows how its server logs in says so, like `auth_methods: [Md5]`.

### Connection URLs

`Client.connect_url!(url, { connect!, random_u64!: Random.seed_u64!, statement_timeout: Duration.seconds(30) })` connects with a URL like `postgresql://user:password@localhost:6432/app`, and `ConnectionUrl.parse(url)` gives its settings.

The syntax is parsed by [roc-database-url](https://github.com/niclas-ahden/roc-database-url). The meaning follows [libpq](https://www.postgresql.org/docs/current/libpq.html): the port defaults to 5432 and the database to the user's name, and `application_name` and the `-c name=value` settings of `options` become session parameters. The connection is plaintext for now (see [TLS](#tls)), which `sslmode` `disable`, `allow` and `prefer` (the default) settle for. `require`, `verify-ca` and `verify-full` demand TLS and are refused with `UnsupportedSslMode(mode)`, and any other option with `UnsupportedOption(name)`, so nothing a URL asks for is silently ignored.

## Timeouts

There are two, and you set both:

- `statement_timeout`, a field of `Client.connect!` and `Client.connect_url!`: how long a statement may run before the server cancels it (`PgErr`, SQLSTATE `57014`). The connection stays usable. It is a duration, anything with a `to_millis` method, such as basic-cli's `Duration.seconds(30)`, or `Client.millis(30_000)` on a platform without one. A zero duration turns it off, as in Postgres. It is sent as a startup parameter, so it is the session's default, and one transaction can lift it with `set local statement_timeout = 0`. Behind [PgBouncer](https://www.pgbouncer.org) set it on the role instead, see [Web servers](#web-servers).
- The connection's own timeout: how long the dial and one read or write may wait, the backstop for a server or network that stops answering. It belongs to the connection, so you set it in your `connect!`, like `io_timeout: Duration.seconds(35)` on basic-cli. basic-webserver gives every connection a fixed 30 seconds.

Make the connection's timeout a few seconds longer than `statement_timeout`. The server sends nothing while a statement runs, so with a shorter one a slow statement breaks the connection with `PgReadErr` before the server gets to cancel it, where it would otherwise fail with `PgErr` and leave the connection usable. `roc-pg` cannot check this for you, since it cannot see the connection's timeout.

## TLS

`roc-pg` connects in plaintext for now, because neither [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli) nor [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver) offers TLS on its TCP streams yet. Postgres starts TLS on an open connection, after a short plaintext exchange, so the platform needs a way to upgrade a TCP stream to TLS. `roc-pg` can easily support TLS once platform support rolls out.

Until then a server that demands TLS refuses the connection, and a password travels in the clear. That is fine for a server on the same machine or on a private network. To reach a database elsewhere, you can connect to a TLS proxy on your own machine instead, such as a [PgBouncer](https://www.pgbouncer.org) with `server_tls_sslmode` set.

## Web servers

A `Client` is one connection, and a connection carries one conversation at a time. The handlers of a web server run at the same time, so never keep a client where they all reach it, such as a web server's context. Their messages would interleave, and each could read the other's reply, or land in the other's transaction. The package has no connection pool, so the simplest safe setup keeps the connection settings in the context and connects in each request:

```roc
Context : { host : Str, port : U16, user : Str, database : Str }

Db : Client.Client(Client.BasicWebserver(Tcp.Connection), Schema)

with_db! = |{ host, port, user, database }, body!| {
	db : Db
	# A few seconds under basic-webserver's fixed 30 seconds for each read.
	db = Client.connect!({ connect!: Client.basic_webserver(Tcp.connect!), random_u64!: || Err(NoRandom), host, port, user, database, auth: NoAuth, statement_timeout: Client.millis(25_000) })?
	result = body!(db)
	db.close!()
	result
}

respond! = |request, context| {
	user = with_db!(context, |db| db.query_one!("SELECT name FROM users WHERE id = $id", { id, }))?
	...
}
```

For a busy web server you may want a [PgBouncer](https://www.pgbouncer.org) on the same machine. It keeps the connections to the database open, which makes connecting in each request cheap, and it lets you securely connect to a database elsewhere (see [TLS](#tls)). [examples/webserver.roc](examples/webserver.roc) is a runnable version.

If you use [PgBouncer](https://www.pgbouncer.org) in transaction mode:

- [PgBouncer](https://www.pgbouncer.org) refuses startup parameters it does not know, so set `statement_timeout` on the role (`alter role my_app set statement_timeout = '30s'`) and pass a zero `statement_timeout` (`Client.millis(0)`), and leave settings other than `application_name` out of `params`.
- Named prepared statements (`prepare_unchecked!`) need [PgBouncer](https://www.pgbouncer.org) 1.21 or later with `max_prepared_statements` set. `query!`, `execute!` and the rest use unnamed statements and need nothing.
- Session state (`set`, session advisory locks, temp tables) does not last from one transaction to the next. Use `set local` inside a transaction.

## Limitations

- Plaintext only, until a platform offers TLS on TCP streams (see [TLS](#tls)). A server that demands TLS refuses the connection.
- No connection pool in the package. See [Web servers](#web-servers) for connecting in each request.
- No `LISTEN` and `NOTIFY`. A session can run them, but the client never delivers a notification. It reads past any that arrive.
- Notices are consumed and dropped.

## Tests

```sh
nix develop -c roc test package/main.roc
```

runs the package's unit tests. `nix develop -c ./tests.roc` runs everything, including a check of every example and integration tests against a temporary Postgres, which the development shell provides.

## Documentation

View the full API documentation at [https://niclas-ahden.github.io/roc-pg/](https://niclas-ahden.github.io/roc-pg/).
