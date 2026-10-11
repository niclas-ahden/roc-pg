# roc-pg

A PostgreSQL client in pure Roc. The package implements the wire protocol itself and only needs TCP from the platform. Connections are plaintext for now, because neither [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli) nor [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver) offers TLS on its TCP streams yet (see [TLS](#tls)). Originally forked from [agu-z/roc-pg](https://github.com/agu-z/roc-pg) and rewritten for the new Roc compiler.

## Example usage

```roc
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.23.0/GNN5tt2gKdX4dhawg4915C4YB193woHFdcCkz31fhGxv.tar.zst",
	pg: "https://github.com/niclas-ahden/roc-pg/releases/download/0.2.0/EGCCBmR793d6wQJzX8aS9994n9nzz6dgMvhKuU6PqQ12.tar.zst",
}

import pf.Random
import pf.Stdout
import pf.Tcp
import pf.OsStr exposing [OsStr]
import pg.Client
import pg.Param

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	client = Client.connect!(
		{
			connect!: Tcp.connect!,
			random_u64!: Random.seed_u64!,
			host: "localhost",
			port: 5432,
			user: "postgres",
			database: "postgres",
			auth: NoAuth,
			# Caps each TCP dial, read and write (not a whole command).
			timeout_ms: 5000,
		},
	)?

	# Rows are decoded by column name. A missing column, a NULL or a value
	# that doesn't fit the type is an error rather than a crash.
	people = client.query!(
		"select name, age from people where age > $1",
		[Param.u8(18)],
		|row| Ok({ name: row.str("name")?, age: row.u8("age")? }),
	)?

	for person in people {
		Stdout.line!("${person.name}: ${person.age.to_str()}")?
	}

	client.close!()
	Ok({})
}
```

See [examples/](examples/) for runnable versions of this, prepared statements and a web server.

## The API in short

A `Client` is one connection. Its functions take the client first, so they read as methods:

- `client.query!(sql, params, decode_row)` runs `sql` and decodes every row.
- `client.query_one!(sql, params, decode_row)` decodes the one row, and fails with `EmptyResult` or `MultipleRows(n)` otherwise.
- `client.query_optional!(sql, params, decode_row)` decodes the row if there is one: `Ok(row)` or `Err(NotFound)` inside the result, and `MultipleRows(n)` for more than one.
- `client.execute!(sql, params)` runs `sql` for its effect and returns how many rows it affected.
- `client.pipeline!(statements)` runs several statements, each `{ sql, params }`, in one round trip and returns how many rows each one affected. Outside a transaction they are one transaction of their own. A statement that fails skips the rest, none of them lands, and the error, `PgPipelineErr`, says which statement it was.
- `client.batch_execute!(sql)` runs several statements separated by `;`, such as a migration, without parameters. The server splits them, and a statement that fails rolls the whole batch back.
- `client.transaction!(|db| ...)` runs the body inside `begin`/`commit`, rolling back when the body fails. Called on the body's `db` it nests in a savepoint.
- `client.command!(stmt)` runs a `Statement` (SQL or a prepared statement, with params) and returns the raw `PgResult`, for when the ones above don't fit.
- `client.prepare!(sql, { name })` parses a named prepared statement and returns it as a `Statement`.

Parameters are built with `Param`: `Param.str`, `Param.i32`, `Param.bool`, `Param.null`, `Param.bytes`, ... and `Param.list` for arrays. Rows are decoded with the accessors on `PgResult.Row`: `row.str("name")`, `row.i64("id")`, `row.str_nullable("bio")`, `row.str_list("tags")`, `row.list("ids", decode_elem)`, ...

In an app signature the client is `Client.Client(Tcp.Stream)`, or `Client.Client(Client.FixedTimeout(Tcp.Stream))` on [basic-webserver](https://github.com/roc-lang/basic-webserver) (see Requirements). Every function names its error union, so mistakes surface at the call, not deep inside a handler.

## Requirements

- A platform with TCP streams whose `write!` and `read_exactly!` take a timeout in milliseconds, like [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli). `roc-pg` calls those two methods on the stream, so the app only hands over the platform's `connect!` and `random_u64!`.
- On [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver), whose streams take no timeout (the platform gives each operation a fixed 30 seconds), wrap its dial: `connect!: Client.fixed_timeout(Tcp.connect!)`. It has no random numbers, so pass `random_u64!: || Err(NoRandom)`. That rules out SCRAM logins there, so log in another way, such as trust or md5.
- PostgreSQL 10 or later for SCRAM-SHA-256, any version for md5 and cleartext passwords.

## Authentication

`auth` is `NoAuth` or `Password(str)`. The server decides how it checks a password, and the client answers each of PostgreSQL's three password methods: SCRAM-SHA-256 (with [roc-scram](https://github.com/niclas-ahden/roc-scram)), md5 (with [roc-md5](https://github.com/niclas-ahden/roc-md5)) and cleartext. The optional `auth_methods` of `Client.connect!` lists the logins the client agrees to, named as in pg_hba.conf:

- `Scram`: SCRAM-SHA-256.
- `Md5`: an md5 hash of the password.
- `Cleartext`: the password itself (pg_hba's `password`).
- `Trust`: no login at all, the server lets the client in unasked.

A login the server asks for that is not listed fails with `AuthMethodNotAllowed(method)`. By default all four are allowed. An app that knows how its server logs in says so, like `auth_methods: [Md5]`.

## Connection URLs

`Client.connect_url!(url, { connect!: Tcp.connect!, random_u64!: Random.seed_u64! })` connects with a URL like `postgresql://user:password@localhost:6432/app`, and `ConnectionUrl.parse(url)` gives its settings.

The syntax is parsed by [roc-database-url](https://github.com/niclas-ahden/roc-database-url). The meaning follows [libpq](https://www.postgresql.org/docs/current/libpq.html): the port defaults to 5432 and the database to the user's name, and `application_name` and the `-c name=value` settings of `options` become session parameters. The connection is plaintext for now (see [TLS](#tls)), which `sslmode` `disable`, `allow` and `prefer` (the default) settle for. `require`, `verify-ca` and `verify-full` demand TLS and are refused with `UnsupportedSslMode(mode)`, and any other option with `UnsupportedOption(name)`, so nothing a URL asks for is silently ignored.

## TLS

`roc-pg` connects in plaintext for now, because neither [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli) nor [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver) offers TLS on its TCP streams yet. Postgres starts TLS on an open connection, after a short plaintext exchange, so the platform needs a way to upgrade a TCP stream to TLS. `roc-pg` will support TLS once a platform has that.

Until then a server that demands TLS refuses the connection, and a password travels in the clear. That is fine for a server on the same machine or on a private network. To reach a database elsewhere, you can connect to a TLS proxy on your own machine instead, such as a [PgBouncer](https://www.pgbouncer.org) with `server_tls_sslmode` set.

## Arrays and enums

Everything except `Param.bytes` travels in Postgres text format, so the server infers each parameter's type from where its `$n` appears. That covers enums: an enum column takes its label as `Param.str` and returns it through `row.str`. Arrays are `Param.list` of the element params and decode with `row.str_list`, `row.i32_list`, `row.i64_list` or the generic `row.list(name, decode_elem)`:

```roc
ids = client.query!(
	"select id from users where role = any($1)",
	[Param.list([Param.str("admin"), Param.str("editor")])],
	|row| row.i32("id"),
)?
```

A nested `Param.list` binds a multi-dimensional array. Decoding reads one dimension, and a NULL element fails with `NullElement`.

## Web servers

A `Client` is one connection, and a connection carries one conversation at a time. The handlers of a web server run at the same time, so never keep a client where they all reach it, such as a web server's context: their messages would interleave, and each could read the other's reply, or land in the other's transaction. The package has no connection pool, so the simplest safe setup keeps the connection settings in the context and connects in each request:

```roc
Context : { host : Str, port : U16, user : Str, database : Str }

with_db! = |{ host, port, user, database }, body!| {
	db = Client.connect!({ connect!: Client.fixed_timeout(Tcp.connect!), random_u64!: || Err(NoRandom), host, port, user, database, auth: NoAuth })?
	result = body!(db)
	db.close!()
	result
}

respond! = |request, context| {
	name = with_db!(context, |db| db.query_one!("select name from users where id = $1", [Param.i64(id)], |row| row.str("name")))?
	...
}
```

For a busy web server you may want a [PgBouncer](https://www.pgbouncer.org) on the same machine. It gives you pooling and lets you securely connect to a database elsewhere (see [TLS](#tls)).

If you use [PgBouncer](https://www.pgbouncer.org) in transaction mode:

- [PgBouncer](https://www.pgbouncer.org) refuses startup parameters it does not know, so set `statement_timeout` on the role (`alter role my_app set statement_timeout = '30s'`) rather than with `statement_timeout_ms`, and leave settings other than `application_name` out of `params`.
- Named prepared statements need [PgBouncer](https://www.pgbouncer.org) 1.21 or later with `max_prepared_statements` set. `query!`, `execute!` and the rest use unnamed statements and need nothing.
- Session state (`set`, session advisory locks, temp tables) does not last from one transaction to the next. Use `set local` inside a transaction.

## Timeouts

We've got two and they're both optional in `Client.connect!`:

- `statement_timeout_ms`: how long a statement may run before the server cancels it (`PgErr`, SQLSTATE `57014`). The connection stays usable. Off by default, as in Postgres. It is sent as a startup parameter, so it is the session's default, and one transaction can lift it with `set local statement_timeout = 0`. Behind [PgBouncer](https://www.pgbouncer.org) set it on the role instead, see above.
- `timeout_ms`: how long the dial and one read or write may wait, the backstop for a server or network that stops answering. The server sends nothing while a statement runs, so it must outlast the longest one. By default 5 seconds more than `statement_timeout_ms`, or 60 seconds without one. Through `Client.fixed_timeout` the platform's own timeout applies instead.

## Limitations

- Plaintext only, until a platform offers TLS on TCP streams (see [TLS](#tls)). A server that demands TLS refuses the connection.
- No connection pool in the package. See [Web servers](#web-servers) for connecting in each request.
- No `listen` and `notify`. A notification breaks the connection: the next command fails with `PgProtoErr`, so a session must not `listen`.
- Notices are consumed and dropped.

## Development

```sh
nix develop -c ./tests.roc
```

This runs the unit tests, checks the examples and runs the integration tests against a throwaway Postgres server, then a concurrency test through [basic-webserver](https://github.com/roc-lang/basic-webserver), where every request connects on its own.

## Documentation

View the full API documentation at [https://niclas-ahden.github.io/roc-pg/](https://niclas-ahden.github.io/roc-pg/).
