## A web server that answers every request on a connection of its own, for
## the concurrency test in ../../tests.roc. Handlers really do run at the
## same time here, which a basic-cli script never does.
##
## GET /q/<n> asks Postgres to echo <n> back, slowly enough for requests to
## overlap, and answers "n=<n> pid=<backend pid>". Were two handlers ever on
## one connection at once, their conversations would interleave and a request
## would get someone else's number back (or a protocol error).
##
## basic-webserver names its write `write!`, so the platform's `connect!`
## goes through `Client.basic_webserver`.
app [Context, program] {
	pf: platform "https://github.com/roc-lang/basic-webserver/releases/download/0.19.0/4KBAoiBazDfi9UF6e3BYKwon6rA8mnx3dbLMLKFzdEMw.tar.zst",
	pg: "../../package/main.roc",
	http: "https://github.com/roc-lang/http/releases/download/2.0.0/6ZUwqYhCS8PU9Mo6MF7oV82ET2o7KYb57CLKDq4cq4sS.tar.zst",
}

import pf.Env
import pf.Server
import pf.Tcp
import http.Response
import pg.Client
import pg.Param

## Where to connect. The context never holds a connection, since handlers
## that share one would interleave their conversations.
Context : { host : Str, port : U16, user : Str, database : Str }

program = { init!, respond!, shutdown! }

init! : () => Try({ config : Server.Config, context : Context }, _)
init! = || {
	host = Env.var_str!("PG_HOST")?
	port = U16.from_str(Env.var_str!("PG_PORT")?)?
	user = Env.var_str!("PG_USER")?
	database = Env.var_str!("PG_DATABASE")?
	listen_port = U16.from_str(Env.var_str!("LISTEN_PORT")?)?
	Ok({ config: Server.with_listen(Server.default_config, { host: "127.0.0.1", port: listen_port }), context: { host, port, user, database } })
}

respond! : Server.Request, Context => Try(Server.Outcome, [ServerErr(Str)])
respond! = |request, context| {
	number =
		match request.target() {
			Resource({ raw_path, .. }) => I32.from_str(raw_path.drop_prefix("/q/")) ?? -1
			_ => -1
		}

	match echo!(context, number) {
		Ok({ n, pid }) => Ok(text(200, "n=${n.to_str()} pid=${pid.to_str()}"))
		Err(err) => Ok(text(500, "error: ${Str.inspect(err)}"))
	}
}

## Connect, echo `number` back with the session's backend pid, and close.
echo! = |{ host, port, user, database }, number| {
	client = Client.connect!({
		connect!: Client.basic_webserver(Tcp.connect!),
		# basic-webserver has no random numbers, which only a SCRAM login
		# needs, and this test logs in with trust.
		random_u64!: || Err(NoRandom),
		host,
		port,
		user,
		database,
		auth: NoAuth,
		# Under the platform's fixed 30 seconds for each read.
		statement_timeout: Client.millis(25_000),
		params: [("application_name", "roc-pg-insane-in-the-membrane-concurrent")],
	})?
	answer = client.query_one_unchecked!(
		"select $1::int as n, pg_backend_pid() as pid, pg_sleep(0.02)",
		[Param.i32(number)],
		|row| Ok({ n: row.i32("n")?, pid: row.i32("pid")? }),
	)
	client.close!()
	answer
}

text = |status, body|
	Server.respond(Response.from_status(status).with_body(Str.to_utf8(body)))

shutdown! : Server.ShutdownReason, Context => Try({}, [Exit(I64)])
shutdown! = |_reason, _context| Ok({})
