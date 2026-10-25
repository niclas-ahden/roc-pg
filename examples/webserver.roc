## Postgres in a web server. The handlers run at the same time, so each
## request connects on its own: handlers that shared one connection would
## interleave their conversations and read each other's replies.
##
## Connecting is cheap to a PgBouncer on the same machine, which keeps the
## connections to the database open and can talk TLS to it. A PgBouncer on
## port 6432 in front of a Postgres with a `postgres` user and database is
## assumed below (adjust it to yours). Run it with `roc examples/webserver.roc`,
## then `curl localhost:8000`.
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.19.0/4KBAoiBazDfi9UF6e3BYKwon6rA8mnx3dbLMLKFzdEMw.tar.zst",
	pg: "../package/main.roc",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Server
import pf.Stderr
import pf.Tcp
import http.Response
import pg.Client
import pg.Param
import pg.NoSchema

## Where to connect. Never a connection, which every request would share.
Context : { host : Str, port : U16, user : Str, database : Str }

## A connection on basic-webserver. `NoSchema` because this example only
## runs unchecked queries.
Db : Client.Client(Client.FixedTimeout(Tcp.Stream), NoSchema)

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, _)
init! = || {
	context = { host: "localhost", port: 6432, user: "postgres", database: "postgres" }
	Ok({ config: Server.default_config.with_listen({ host: "127.0.0.1", port: 8000 }), context })
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |_request, context|
	match with_db!(context, demo!) {
		Ok(lines) => Ok(Server.respond(Response.from_status(200).with_body(Str.to_utf8(Str.join_with(lines, "\n")))))
		Err(err) => {
			# The details go to the log, never to the client: a server error
			# can name tables, columns and the values that broke a constraint.
			details =
				match err {
					PgErr(error) => Client.error_to_str(error)
					other => Str.inspect(other)
				}
			_ = Stderr.line!("demo failed: ${details}")
			Ok(Server.respond(Response.from_status(500).with_body(Str.to_utf8("Something went wrong"))))
		}
	}

## Connect, run `body!` on the connection, and say goodbye to the server,
## whatever `body!` returned.
with_db! = |{ host, port, user, database }, body!| {
	db = Client.connect!({
		# basic-webserver's streams take no timeout: the platform gives each
		# connect, read and write a fixed 30 seconds.
		connect!: Client.fixed_timeout(Tcp.connect!),
		# basic-webserver has no random numbers, which only a SCRAM login
		# needs. Log in to PgBouncer another way, such as trust or md5.
		random_u64!: || Err(NoRandom),
		host,
		port,
		user,
		database,
		auth: NoAuth,
	})?
	result = body!(db)
	db.close!()
	result
}

demo! : Db => Try(List(Str), _)
demo! = |db| {
	greeting = db.query_one_unchecked!("select 'hello from Postgres' as greeting", [], |row| row.str("greeting"))?

	# One transaction: both statements land, or neither does.
	total = db.transaction!(
		|tx| {
			_ = tx.execute_unchecked!("create temp table numbers (n int) on commit drop", [])?
			_ = tx.execute_unchecked!("insert into numbers values ($1), ($2)", [Param.i32(20), Param.i32(22)])?
			tx.query_one_unchecked!("select sum(n)::int as total from numbers", [], |row| row.i32("total"))
		},
	)?

	Ok([greeting, "20 + 22 = ${total.to_str()}"])
}

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})
