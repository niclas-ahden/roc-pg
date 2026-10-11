## A Postgres client connection.
##
## Connect with [Client.connect!], handing it the platform's `connect!` and
## its source of random numbers, which a SCRAM login needs. Everything else
## goes through two methods of the stream `connect!` returns, `write!` and
## `read_exactly!`, each taking a timeout in milliseconds, as `Tcp.Stream`
## does on [basic-cli](https://github.com/roc-lang/basic-cli):
##
## ```
## client = Client.connect!({
##     connect!: Tcp.connect!,
##     random_u64!: Random.seed_u64!,
##     host: "localhost",
##     port: 5432,
##     user: "postgres",
##     database: "postgres",
##     auth: Password(password),
## })?
## one = client.query_one!("select 1 as one", [], |row| row.i32("one"))?
## ```
##
## On [basic-webserver](https://github.com/roc-lang/basic-webserver), whose
## streams take no timeout, wrap its `connect!` in [Client.fixed_timeout].
##
## The connection is plaintext for now, because neither
## [roc-lang/basic-cli](https://github.com/roc-lang/basic-cli) nor
## [roc-lang/basic-webserver](https://github.com/roc-lang/basic-webserver)
## offers TLS on its TCP streams yet. This package will support TLS once a
## platform does. To reach a database on another machine until then, you
## can connect to a TLS proxy on this one, such as a
## [PgBouncer](https://www.pgbouncer.org) that talks TLS to the database.
##
## `timeout_ms` caps each TCP dial, read, and write (not a whole command).
## Zero is not "no timeout": the platform fails a zero timeout immediately.
## See [Client.connect!] for its default and for `statement_timeout_ms`.
##
## A client is one connection, and a connection carries one conversation at a
## time. Never share a client between code that runs at the same time, like
## the handlers of a web server: their messages would interleave, and each
## could read the other's reply. Connect in each request instead. We
## recommend a [PgBouncer](https://www.pgbouncer.org) on the same machine
## for that, since it keeps the connections to the database open, which
## makes connecting cheap.
##
## A client is a nominal record `Client(stream)`, parameterized by the
## platform's stream type, since this package never names platform types.
## Its functions take the client first, so they read as methods:
## `client.query!(sql, params, decode_row)`, `client.execute!(sql, params)`,
## `client.pipeline!(statements)`, `client.batch_execute!(sql)`,
## `client.transaction!(|db| ...)`,
## `client.command!(stmt)`,
## `client.prepare!(sql, { name })`, `client.close!()`. In an app signature
## the client is `Client.Client(Tcp.Stream)`, or
## `Client.Client(Client.FixedTimeout(Tcp.Stream))` through
## [Client.fixed_timeout].
##
## Errors: every function names its error union (see [Client.CommandErr]).
## A server error (`PgErr`) leaves the connection usable, the client drains
## the conversation for you, unless its severity is `FATAL` or `PANIC`: the
## server closes the connection after those. After a transport or protocol
## error (`PgReadErr`, `PgWriteErr`, `PgProtoErr`) the connection state is
## unknown, so don't reuse the client. The platform closes its stream once
## nothing refers to it anymore. The platform's own error is the payload of
## `PgReadErr`, `PgWriteErr` and `PgConnectErr`. Wrapping it there, instead
## of passing the platform's union through, keeps each call's error union
## independent, so a bare `?` and a `? Tag` on the same client can share a
## function.
import Bytes
import ConnectionUrl
import Prepared
import ProtoBackend
import ProtoFrontend
import Statement
import Param
import scram.Scram
import PgResult

Client(stream) :: {
	stream : stream,
	timeout_ms : U64,
	backend_key : [Known(ProtoBackend.KeyData), Pending],
	# Set on the client a transaction! body gets, so that a transaction!
	# called on it goes straight to a savepoint.
	in_transaction : Bool,
}.{

	## An error the server sent, the payload of `PgErr`. `code` is the
	## SQLSTATE, such as `23505` for a unique violation, and
	## [Client.error_to_str] renders the whole error. `severity` is `ERROR`
	## for a command the server refused, and `FATAL` or `PANIC` when the
	## server closed the connection after the error. `localized_severity` is
	## the same in the server's `lc_messages` language. The rest are the
	## optional fields of a Postgres error, `NoField` when the server did not
	## send them.
	ServerError : {
		severity : Str,
		localized_severity : Str,
		code : Str,
		message : Str,
		detail : [NoField, Field(Str)],
		hint : [NoField, Field(Str)],
		position : [NoField, Field(Str)],
		ewhere : [NoField, Field(Str)],
		schema_name : [NoField, Field(Str)],
		table_name : [NoField, Field(Str)],
		column_name : [NoField, Field(Str)],
		data_type_name : [NoField, Field(Str)],
		constraint_name : [NoField, Field(Str)],
		file : [NoField, Field(Str)],
		line : [NoField, Field(Str)],
		routine : [NoField, Field(Str)],
	}

	## A reply that does not fit the protocol, the payload of `PgProtoErr`.
	ProtoErr : [BadUtf8, InvalidMessageLength(I32), TerminatorNotFound, UnexpectedEnd, UnexpectedMsg(Str), UnrecognizedBackendMessage(U8), UnrecognizedBackendStatus(U8)]

	## Where the session stands, as [Client.sync_status!] reports it.
	TransactionStatus : [Idle, TransactionBlock, FailedTransactionBlock]

	## The errors a command can fail with.
	##
	## - `PgErr(error)`: the server refused the command (see
	##   [Client.ServerError]).
	## - `ContainsNul(what)`: the SQL, a statement name or a connection
	##   setting holds a NUL byte, which the protocol cannot carry. Nothing
	##   was sent. `what` says which, such as `sql` or `user`.
	## - `PgProtoErr(err)`, `PgReadErr(err)` and `PgWriteErr(err)` leave the
	##   connection in an unknown state: a reply that does not fit the
	##   protocol, or the platform failing a read or a write, whose own error
	##   is the payload.
	##
	## Like every error union in this package it is open (`others`), so a `?`
	## merges it into the caller's union.
	CommandErr(read, write, others) : [PgErr(Client.ServerError), ContainsNul(Str), PgProtoErr(Client.ProtoErr), PgReadErr(read), PgWriteErr(write), ..others]

	## The errors of the startup handshake, which [Client.connect!] runs: the
	## command errors, and
	##
	## - `PasswordRequired`: the server asks for a password and `auth` is
	##   `NoAuth`.
	## - `AuthMethodNotAllowed(method)`: the server asks for a login
	##   (`"SCRAM-SHA-256"`, `"md5"`, `"password"`, or `"trust"` for none at
	##   all) that `auth_methods` leaves out.
	## - `ScramFailed(reason)`: the SCRAM exchange failed, for example on the
	##   server's proof, or the server refused it. A wrong password is still
	##   the server's `PgErr` (SQLSTATE `28P01`).
	## - `UnsupportedAuth(code)`: an auth method this package lacks, by the
	##   protocol's auth type (GSSAPI is 7, SSPI 9).
	StartupErr(read, write, others) : Client.CommandErr(read, write, [PasswordRequired, AuthMethodNotAllowed(Str), ScramFailed(Str), UnsupportedAuth(I32), ..others])

	## [Client.StartupErr] plus `PgConnectErr(TcpConnectErr(err))`, the
	## platform refusing the dial with its own error, and
	## `ParamNotAllowed(name)`, a name in `params` that is not a session
	## setting (see [Client.connect!]).
	ConnectErr(connect, read, write, others) : Client.StartupErr(read, write, [PgConnectErr(connect), ParamNotAllowed(Str), ..others])

	## [Client.CommandErr] plus the two ways a query meant to return one
	## row can fail: `EmptyResult` and `MultipleRows(n)`.
	QueryOneErr(read, write, others) : Client.CommandErr(read, write, [EmptyResult, MultipleRows(U64), ..others])

	## [Client.CommandErr] plus `MultipleRows(n)`, for a query meant to
	## return at most one row that returned more.
	QueryOptionalErr(read, write, others) : Client.CommandErr(read, write, [MultipleRows(U64), ..others])

	## [Client.CommandErr] plus `PgPipelineErr({ index, error })`: the server
	## refused the statement at `index` (from 0) of a [Client.pipeline!], with
	## `error` as for `PgErr`.
	PipelineErr(read, write, others) : Client.CommandErr(read, write, [PgPipelineErr({ index : U64, error : Client.ServerError }), ..others])

	## The errors [Client.transaction!] adds to those of its body: `begin` or
	## `commit` failing with a [Client.CommandErr], the server refusing the
	## `commit` (a deferred constraint, say), which keeps the server error and
	## its SQLSTATE `code`, and `TransactionAborted` for a body that returned
	## `Ok` although one of its statements failed, which made the server roll
	## the transaction back.
	TransactionErr(read, write, others) : [TransactionBeginFailed(Client.CommandErr(read, write, [])), TransactionCommitRefused(Client.ServerError), TransactionCommitFailed(Client.CommandErr(read, write, [])), TransactionAborted, ..others]

	## Connect and authenticate. `connect!` is the platform's dial (`Tcp.connect!`)
	## and `random_u64!` its random numbers (`Random.seed_u64!`), for the nonce
	## of a SCRAM login. `auth` is `NoAuth` or `Password(str)`. The
	## server decides how the password is checked, and the client answers
	## SCRAM-SHA-256 (PostgreSQL 10 and later), md5 (any version) and
	## cleartext, the three methods PostgreSQL has for passwords. A dial the
	## platform refuses fails with `PgConnectErr(TcpConnectErr(err))`. See
	## [Client.StartupErr] for how a login fails.
	##
	## `auth_methods` is optional: the logins the client agrees to, named as
	## in pg_hba.conf:
	##
	## - `Scram`: SCRAM-SHA-256.
	## - `Md5`: an md5 hash of the password.
	## - `Cleartext`: the password itself (pg_hba's `password`).
	## - `Trust`: no login at all, the server lets the client in unasked.
	##
	## The server decides which it asks for. One it asks for that is not
	## listed fails with `AuthMethodNotAllowed(method)`. By default all four
	## are allowed. An app that knows how its server logs in says so, like
	## `auth_methods: [Md5]`. SCRAM draws its nonce from `random_u64!`. A
	## platform without random numbers can pass `|| Err(NoRandom)` and leave
	## `Scram` out.
	##
	## The connection is plaintext, the password included, so it is for a
	## server on the same machine, or on a network nobody else can reach. A
	## server that demands TLS refuses it.
	##
	## `params` is optional: extra run-time parameters for the session, such
	## as `("application_name", "my_app")` or `("search_path", "app,public")`.
	## Only session settings go there. The names the protocol keeps for
	## itself are refused with `ParamNotAllowed(name)`: `user` and `database`
	## (fields of their own here), `options` (settings written as command
	## line switches, which `params` already covers), `replication` (which
	## would switch the connection to the replication protocol) and any
	## name starting with `_pq_.`. So is `client_encoding`, which stays
	## `UTF8` because every string is read as UTF-8. Case does not matter,
	## as it does not for setting names.
	##
	## `statement_timeout_ms` is optional: how long a statement may run before
	## the server cancels it, which fails it with `PgErr` and SQLSTATE `57014`
	## and leaves the connection usable. Off by default, as in Postgres. It is
	## sent when the session starts, and one transaction can lift it with
	## `set local statement_timeout = 0`. [PgBouncer](https://www.pgbouncer.org)
	## refuses startup parameters it does not know, so behind
	## [PgBouncer](https://www.pgbouncer.org) set it on the role instead.
	##
	## `timeout_ms` is optional: how long the dial and each read or write may
	## wait. It is the backstop for a server or network that
	## stops answering, and must outlast the longest statement, because the
	## server sends nothing while one runs. By default 5 seconds more than
	## `statement_timeout_ms`, or 60 seconds without one. A job with longer
	## statements passes its own.
	connect! : { connect! : Str, U16, U64 => Try(_, _), random_u64! : () => Try(U64, _), host : Str, port : U16, user : Str, database : Str, auth : [NoAuth, Password(Str)], timeout_ms ?: U64, statement_timeout_ms ?: U64, params ?: List((Str, Str)), auth_methods ?: List([Scram, Md5, Cleartext, Trust]) } => Try(Client(_), Client.ConnectErr(_, _, _, others))
	connect! = |{ connect!: dial!, random_u64!, host, port, user, database, auth, timeout_ms: given_timeout_ms, statement_timeout_ms, params, auth_methods }| {
		statement_ms = statement_timeout_ms ?? 0
		timeout_ms = given_timeout_ms ?? default_timeout_ms(statement_ms)
		all_params = statement_timeout_params(statement_ms).concat(params ?? [])
		# The startup message is a list of C strings, so a NUL byte in any of
		# them would end it early and turn the rest into settings of its own.
		for (name, _) in all_params {
			if !is_session_setting(name) {
				return Err(ParamNotAllowed(name))
			}
		}
		check_no_nul(user, "user")?
		check_no_nul(database, "database")?
		for (name, value) in all_params {
			check_no_nul(name, "a parameter name")?
			check_no_nul(value, "parameter ${name}")?
		}
		match auth {
			Password(password) => check_no_nul(password, "password")?
			NoAuth => {}
		}
		stream =
			match dial!(host, port, timeout_ms) {
				Ok(s) => Ok(s)
				Err(err) => Err(PgConnectErr(TcpConnectErr(err)))
			}?
		do_startup!(stream, { user, database, auth, timeout_ms, params: all_params, auth_methods: auth_methods ?? all_auth_methods, random_u64! })
	}

	## Connect with the settings of a connection URL, the form hosted
	## databases hand out, like
	## `postgresql://user:password@localhost:5432/app?sslmode=disable`.
	## See [ConnectionUrl] for what each part means. `connect!` and
	## `random_u64!` are those of [Client.connect!], and the rest is optional,
	## as there. A URL it refuses fails with `InvalidConnectionUrl(err)`,
	## carrying a [ConnectionUrl.ParseErr].
	##
	## ```
	## client = Client.connect_url!(url, { connect!: Tcp.connect!, random_u64!: Random.seed_u64!, statement_timeout_ms: 30_000 })?
	## ```
	connect_url! : Str, { connect! : Str, U16, U64 => Try(_, _), random_u64! : () => Try(U64, _), timeout_ms ?: U64, statement_timeout_ms ?: U64, auth_methods ?: List([Scram, Md5, Cleartext, Trust]) } => Try(Client(_), Client.ConnectErr(_, _, _, [InvalidConnectionUrl(ConnectionUrl.ParseErr), ..others]))
	connect_url! = |url, { connect!: dial!, random_u64!, timeout_ms, statement_timeout_ms, auth_methods }| {
		settings = ConnectionUrl.parse(url) ? |err| InvalidConnectionUrl(err)
		statement_ms = statement_timeout_ms ?? 0
		connect!({ connect!: dial!, random_u64!, host: settings.host, port: settings.port, user: settings.user, database: settings.database, auth: settings.auth, params: settings.params, timeout_ms: timeout_ms ?? default_timeout_ms(statement_ms), statement_timeout_ms: statement_ms, auth_methods: auth_methods ?? all_auth_methods })
	}

	## A stream from a platform whose reads and writes take no timeout, given
	## the `write!` and `read_exactly!` that [Client.connect!] calls. They
	## drop the timeout, and the platform's own applies instead. See
	## [Client.fixed_timeout].
	# Transparent, although nothing outside needs its field: made opaque
	# (`::`), it segfaults `roc check` on examples/webserver.roc at b797cda.
	FixedTimeout(stream) := { stream : stream }.{
		write! = |fixed, bytes, _timeout_ms| fixed.stream.write!(bytes)
		read_exactly! = |fixed, len, _timeout_ms| fixed.stream.read_exactly!(len)
	}

	## The `connect!` of a platform whose streams take no timeout, made fit
	## for [Client.connect!].
	## [basic-webserver](https://github.com/roc-lang/basic-webserver)'s
	## `Tcp.Stream` is one: it gives every dial, read and write a fixed 30
	## seconds.
	##
	## ```
	## client = Client.connect!({ connect!: Client.fixed_timeout(Tcp.connect!), random_u64!: || Err(NoRandom), host, port, user, database, auth })?
	## ```
	##
	## basic-webserver has no random numbers either, hence `|| Err(NoRandom)`,
	## which rules out a SCRAM login.
	##
	## `timeout_ms` then has no effect, and a statement that runs longer than
	## the platform's timeout fails with `PgReadErr`. Set a shorter
	## `statement_timeout` on the role, which fails such a statement with
	## `PgErr` instead and leaves the connection usable. The client's type is
	## `Client.Client(Client.FixedTimeout(Tcp.Stream))`.
	fixed_timeout : (Str, U16 => Try(stream, err)) -> (Str, U16, U64 => Try(Client.FixedTimeout(stream), err))
	fixed_timeout = |dial!|
		|host, port, _timeout_ms|
			match dial!(host, port) {
				Ok(stream) => Ok(Client.FixedTimeout.{ stream })
				Err(err) => Err(err)
			}

	## Run a [Statement] and return its [PgResult]. [Client.query!],
	## [Client.query_one!], [Client.query_optional!] and [Client.execute!] cover
	## the common cases.
	##
	## The wire conversation is: Parse, Bind, Describe, Execute, Sync, then
	## read messages until ReadyForQuery.
	command! : Client(_), Statement.Statement => Try(PgResult.PgResult, Client.CommandErr(_, _, others))
	command! = |client, stmt| {
		{ format_codes, param_values } = Param.encode(stmt.params)

		# A named prepared statement only exists on the connection it was
		# prepared on. When this statement was prepared on a DIFFERENT
		# connection, fall back to re-parsing its SQL as an unnamed
		# statement, which is correct on any connection, at the cost of one
		# extra Parse.
		plan =
			match stmt.kind {
				Sql(sql) => {
					check_no_nul(sql, "sql")?
					UnnamedFlow(sql)
				}
				Prepared(prepared) =>
					match (client.backend_key, prepared.prepared_on()) {
						# Backend keys are only unique within one server, so
						# statements prepared against a different host could
						# in principle collide.
						(Known(current), Known(origin)) if current.process_id == origin.process_id and current.secret_key == origin.secret_key => PreparedFlow(prepared)
						_ => UnnamedFlow(prepared.sql())
					}
			}

		messages =
			match plan {
				UnnamedFlow(sql) => unnamed_messages(sql, format_codes, param_values)
				PreparedFlow(prepared) =>
					[
						ProtoFrontend.bind({ prepared_statement: prepared.name(), format_codes: format_codes, param_values: param_values }),
						ProtoFrontend.execute,
						ProtoFrontend.sync,
					]
				}

		init_columns =
			match plan {
				UnnamedFlow(_) => []
				PreparedFlow(prepared) => prepared.columns()
			}

		write_all!(client, Bytes.sequence(messages))?
		read_reply!(client, init_columns)
	}

	## Run `sql` with `params` and decode every row by column name with
	## `decode_row` (see [PgResult.decode]). The decoder's errors join the
	## command's in the result.
	##
	## ```
	## people = client.query!(
	##     "select name, age from people where age > $1",
	##     [Param.u8(18)],
	##     |row| Ok({ name: row.str("name")?, age: row.u8("age")? }),
	## )?
	## ```
	query! : Client(_), Str, List(Param.Param), (PgResult.Row -> Try(a, Client.CommandErr(_, _, others))) => Try(List(a), Client.CommandErr(_, _, others))
	query! = |client, sql, params, decode_row|
		PgResult.decode(client.command!(Statement.new(sql).bind(params))?, decode_row)

	## Run `sql` with `params` and decode the one row it returns. `EmptyResult`
	## when there is none, and `MultipleRows(n)` when there are more: a query
	## meant to return one row that returns several is a bug worth catching,
	## not a row to pick.
	##
	## ```
	## id = client.query_one!("insert into people (name) values ($1) returning id", [Param.str(name)], |row| row.i32("id"))?
	## ```
	query_one! : Client(_), Str, List(Param.Param), (PgResult.Row -> Try(a, Client.QueryOneErr(_, _, others))) => Try(a, Client.QueryOneErr(_, _, others))
	query_one! = |client, sql, params, decode_row| {
		result = client.command!(Statement.new(sql).bind(params))?
		PgResult.decode_one(result, decode_row)
	}

	## Run `sql` with `params` and decode the row it returns, if any: `Ok(row)`
	## for one row and `Err(NotFound)` for none, both inside the command's own
	## `Ok`. More than one row fails with `MultipleRows(n)`, like
	## [Client.query_one!].
	##
	## ```
	## found = client.query_optional!("select name from people where email = $1", [Param.str(email)], |row| row.str("name"))?
	## match found {
	##     Ok(name) => greet(name)
	##     Err(NotFound) => sign_up(email)
	## }
	## ```
	query_optional! : Client(_), Str, List(Param.Param), (PgResult.Row -> Try(a, Client.QueryOptionalErr(_, _, others))) => Try(Try(a, [NotFound]), Client.QueryOptionalErr(_, _, others))
	query_optional! = |client, sql, params, decode_row| {
		result = client.command!(Statement.new(sql).bind(params))?
		PgResult.decode_optional(result, decode_row)
	}

	## Run `sql` with `params` for its effect and return how many rows it
	## inserted, updated, deleted, merged or copied (see
	## [PgResult.rows_affected]). For a `select` that is how many rows it
	## returned, which are read and dropped. A command that reports no count,
	## such as `create table`, returns zero.
	##
	## ```
	## updated = client.execute!("update users set seen = now() where id = $1", [Param.i64(id)])?
	## if updated == 0 Err(UserNotFound(id)) else Ok({})
	## ```
	##
	## A statement in Roc must be `{}`, so a call that has no use for the
	## count discards it: `_ = client.execute!(sql, params)?`.
	execute! : Client(_), Str, List(Param.Param) => Try(U64, Client.CommandErr(_, _, others))
	execute! = |client, sql, params| {
		result = client.command!(Statement.new(sql).bind(params))?
		Ok(PgResult.rows_affected(result))
	}

	## Run several statements, each with its own `$1` parameters, in one
	## round trip, and return how many rows each one inserted, updated or
	## deleted, in their order (see [Client.execute!]).
	##
	## ```
	## [updated, _] = client.pipeline!([
	##     { sql: "update users set seen = now() where id = $1", params: [Param.i64(id)] },
	##     { sql: "delete from reminders where user_id = $1", params: [Param.i64(id)] },
	## ])?
	## ```
	##
	## The client writes every statement and then one Sync, and the server
	## runs them in order, each one seeing what the ones before it did. Outside
	## [Client.transaction!] the statements up to the Sync are one transaction
	## of their own, so a pipeline is a transaction in one round trip. No
	## statement can use what an earlier one returned, since all of them are
	## sent before the first answer comes back: a write that depends on what
	## is there decides in SQL, such as an `insert ... where not exists`.
	##
	## When a statement fails, the server skips the rest, and the pipeline
	## fails with `PgPipelineErr({ index, error })`, the statement's place in
	## the list (from 0) and the server's error. None of it lands then: inside
	## [Client.transaction!] the transaction fails, and outside one its own
	## transaction is rolled back. A commit that fails at the end, on a
	## deferred constraint, is a `PgErr`.
	##
	## Rows a `select` returns are read and dropped. Since the client reads
	## nothing until it has written everything, a pipeline is for writes and
	## statements that return little: statements that return many rows can
	## fill the server's send buffer while the client is still writing, and
	## the two would wait for each other until the timeout. Use
	## [Client.query!] for those. A pipeline without statements sends
	## nothing.
	pipeline! : Client(_), List({ sql : Str, params : List(Param.Param) }) => Try(List(U64), Client.PipelineErr(_, _, others))
	pipeline! = |client, statements| {
		if statements.is_empty() {
			return Ok([])
		}
		for statement in statements {
			check_no_nul(statement.sql, "sql")?
		}
		messages = statements.map(
			|statement| {
				{ format_codes, param_values } = Param.encode(statement.params)
				Bytes.sequence(unnamed_messages(statement.sql, format_codes, param_values).drop_last(1))
			},
		)
		write_all!(client, Bytes.sequence(messages.append(ProtoFrontend.sync)))?
		var $counts = []
		for _ in statements {
			result =
				match read_cmd_result!(client, [], []) {
					Ok(answered) => answered
					Err(PgErr(error)) => {
						# The server skips to the Sync and answers ReadyForQuery, unless
						# the error closed the connection (see drain_after_error!).
						if !closes_connection(error) {
							_ = read_ready_for_query!(client)?
						}
						return Err(PgPipelineErr({ index: $counts.len(), error }))
					}
					Err(other) => return Err(other)
				}
			$counts = $counts.append(PgResult.rows_affected(result))
		}
		match read_ready_for_query!(client)?.outcome {
			NoError => Ok($counts)
			SawError(error) => Err(PgErr(error))
		}
	}

	## Run `sql`, which may hold several statements separated by `;`, like a
	## migration or a schema dump. The server splits them, so a `;` inside a
	## string, a comment or a function body is safe.
	##
	## ```
	## client.batch_execute!("create table users (id serial primary key, name text); create index on users (name)")?
	## ```
	##
	## It takes no parameters, because the protocol cannot bind values to a
	## batch. Never build its SQL from values a user supplied. Use
	## [Client.execute!] with `$1` placeholders for those.
	##
	## Unless the batch has its own `begin` and `commit`, the server runs it as
	## one transaction: the first statement that fails ends the batch with
	## `PgErr`, and the statements before it are rolled back. Inside
	## [Client.transaction!] the batch is part of that transaction. A statement
	## that refuses to run inside a transaction, like `vacuum` or
	## `create index concurrently`, needs a batch of its own.
	##
	## Rows a `select` returns are read and dropped. `copy` to or from the
	## client is not supported: it fails with `PgProtoErr`, and the
	## connection can't be used after it.
	batch_execute! : Client(_), Str => Try({}, Client.CommandErr(_, _, others))
	batch_execute! = |client, sql| {
		check_no_nul(sql, "sql")?
		write_all!(client, ProtoFrontend.query(sql))?
		read_batch!(client)
	}

	## Run `body!` inside one `begin`/`commit` on this connection, which is
	## passed to it. When `body!` fails, the transaction is rolled back and
	## its error returned, so a partial write never lands. When it failed
	## because the server stopped answering, the rollback waits out
	## `timeout_ms` once more before it gives up. The server rolls the
	## transaction back by itself when the connection goes away.
	##
	## A body that returns `Ok` although one of its statements failed (it
	## caught the error and carried on) fails with `TransactionAborted`. The
	## server ignores everything after a failed statement and rolls the whole
	## transaction back at `commit`, so none of it landed.
	##
	## A `commit` the server refuses (a deferred constraint, say) fails with
	## `TransactionCommitRefused(error)`, carrying the server error and its
	## SQLSTATE `code`. A `begin` or `commit` that fails for any other reason
	## fails with `TransactionBeginFailed(err)` or
	## `TransactionCommitFailed(err)`, carrying that [Client.CommandErr].
	##
	## Called while the connection is already inside a transaction, from a
	## body or from any other code on the same connection, it nests: the
	## inner call runs in a savepoint, and when it fails only its own work is
	## rolled back, so the enclosing transaction can go on. Whether any of it
	## lands is still up to the enclosing transaction's `commit`. Nest
	## through the client the body is given. That one knows it is inside a
	## transaction and goes straight to the savepoint. Any other client value
	## for the connection asks the server first, which costs a round trip
	## and puts a warning in the server's log.
	##
	## ```
	## id = client.transaction!(|db| {
	##     _ = db.execute!("insert into sources (name) values ($1)", [Param.str(name)])?
	##     db.query_one!("insert into leads (source_id) values (currval('sources_id_seq')) returning id", [], |row| row.i32("id"))
	## })?
	## ```
	transaction! : Client(_), (Client(_) => Try(a, Client.TransactionErr(_, _, others))) => Try(a, Client.TransactionErr(_, _, others))
	transaction! = |client, body!|
		match open_transaction!(client) {
			Err(err) => Err(TransactionBeginFailed(err))
			Ok(level) =>
				match body!({ ..client, in_transaction: Bool.True }) {
					Ok(value) =>
						match close_transaction!(client, level) {
							Ok({}) => Ok(value)
							Err(err) => Err(err)
						}

					Err(err) => {
						undo_transaction!(client, level)
						Err(err)
					}
				}
		}

	## Parse a named prepared statement on this connection. The returned
	## [Statement] can be run many times with fresh parameters. On this
	## connection it uses the named statement directly. On any other
	## connection `command!` re-parses the SQL as an unnamed statement
	## instead.
	##
	## On the server the statement is called after its SQL as well as `name`
	## (see `statement_name`), so two different queries prepared under one
	## name on one connection cannot replace each other. A [Statement] whose
	## named statement was replaced would silently run the other query.
	prepare! : Client(_), Str, { name : Str } => Try(Statement.Statement, Client.CommandErr(_, _, others))
	prepare! = |client, sql, { name: given_name }| {
		check_no_nul(sql, "sql")?
		check_no_nul(given_name, "statement name")?
		name = statement_name(sql, given_name)
		write_all!(
			client,
			Bytes.sequence([
				# Close first so preparing the same name again on this
				# connection replaces the old statement instead of failing
				# with "prepared statement already exists".
				ProtoFrontend.close_statement({ name: name }),
				ProtoFrontend.parse({ sql: sql, name: name }),
				ProtoFrontend.describe_statement({ name: name }),
				ProtoFrontend.sync,
			]),
		)?

		# Same drain as command!, a failed Parse still ends in ReadyForQuery.
		match read_prepare_columns!(client, []) {
			Ok(columns) => {
				prepared = Prepared.new({ name, sql, prepared_on: client.backend_key, columns })
				Ok({ kind: Prepared(prepared), params: [] })
			}
			Err(PgErr(error)) => drain_after_error!(client, error)
			Err(other) => Err(other)
		}
	}

	## Tell the server the session is over (Terminate). The write is best
	## effort: a dead connection is over anyway. The platform closes the
	## stream once nothing refers to the client anymore.
	close! : Client(_) => {}
	close! = |client| {
		_ = write_all!(client, ProtoFrontend.terminate)
		{}
	}

	## Round trip a Sync and report the transaction status the server ends
	## up in: `Idle`, `TransactionBlock`, or `FailedTransactionBlock`. A
	## cheap check that the server still answers, and of whether the session
	## was left inside a transaction.
	sync_status! : Client(_) => Try(Client.TransactionStatus, Client.CommandErr(_, _, others))
	sync_status! = |client| {
		write_all!(client, ProtoFrontend.sync)?
		drained = read_ready_for_query!(client)?
		match drained.outcome {
			NoError => Ok(drained.status)
			SawError(error) => Err(PgErr(error))
		}
	}

	## Render a server error (the payload of `PgErr`) as a readable string.
	error_to_str : Client.ServerError -> Str
	error_to_str = |err| {
		fields_str =
			[
				("Detail", err.detail),
				("Hint", err.hint),
				("Position", err.position),
				("Where", err.ewhere),
				("Schema", err.schema_name),
				("Table", err.table_name),
				("Column", err.column_name),
				("Data type", err.data_type_name),
				("Constraint", err.constraint_name),
				("File", err.file),
				("Line", err.line),
				("Routine", err.routine),
			]
				.fold(
					"",
					|acc, (label, field)|
						match field {
							Field(value) => "${acc}\n${label}: ${value}"
							NoField => acc
						},
				)

		"${err.localized_severity} (${err.code}): ${err.message}${fields_str}"
	}
}

## The `timeout_ms` of [Client.connect!] when none is given: 5 seconds more
## than the statement timeout, which a healthy server always answers within,
## or 60 seconds without one.
default_timeout_ms : U64 -> U64
default_timeout_ms = |statement_timeout_ms|
	if statement_timeout_ms > 0 {
		statement_timeout_ms + 5_000
	} else {
		60_000
	}

## The startup parameter that sets `statement_timeout_ms`, none for 0. Used
## by [Client.connect!], ahead of the caller's own `params`, which win.
statement_timeout_params : U64 -> List((Str, Str))
statement_timeout_params = |statement_timeout_ms|
	if statement_timeout_ms > 0 {
		[("statement_timeout", statement_timeout_ms.to_str())]
	} else {
		[]
	}

## Whether a name in `params` is a session setting. The startup message
## also carries the protocol's own keys: `user`, `database`, `options`,
## `replication` and names starting with `_pq_.`, which the server reads
## without regard to what came before, so one in `params` would replace
## the login or change the protocol. `client_encoding` is a setting, but
## this package reads every string as UTF-8, so it must stay `UTF8`.
## Setting names ignore case, and so does this check.
is_session_setting : Str -> Bool
is_session_setting = |name| {
	lower = name.with_ascii_lowercased()
	!(["user", "database", "options", "replication", "client_encoding"].contains(lower) or lower.starts_with("_pq_."))
}

expect is_session_setting("application_name")
expect is_session_setting("search_path")
expect is_session_setting("app.tenant_id")
expect !is_session_setting("user")
expect !is_session_setting("Database")
expect !is_session_setting("options")
expect !is_session_setting("replication")
expect !is_session_setting("_pq_.anything")
expect !is_session_setting("CLIENT_ENCODING")

## Refuse a string the protocol would carry as a C string when it holds a
## NUL byte. The server would read it as ending there and take the rest for
## the next field, which cuts SQL short or adds startup settings nobody
## asked for.
check_no_nul : Str, Str -> Try({}, [ContainsNul(Str), ..others])
check_no_nul = |value, what| if value.to_utf8().contains(0) Err(ContainsNul(what)) else Ok({})

expect check_no_nul("select 1", "sql") == Ok({})
expect check_no_nul("select 1\u(0)drop table x", "sql") == Err(ContainsNul("sql"))

## The two transport boundaries. Each wraps the platform's error in a tag of
## this package as a payload, so the platform's union never becomes the
## tail of a client method's error union (see the module doc). A `match`
## rather than `.map_err`: static dispatch cannot resolve a method on the
## effect function's return type.
write_all! : Client(_), List(U8) => Try({}, [PgWriteErr(_), ..others])
write_all! = |client, bytes| {
	match client.stream.write!(bytes, client.timeout_ms) {
		Ok(v) => Ok(v)
		Err(err) => Err(PgWriteErr(err))
	}
}

read_bytes! : Client(_), U64 => Try(List(U8), [PgReadErr(_), ..others])
read_bytes! = |client, len| {
	match client.stream.read_exactly!(len, client.timeout_ms) {
		Ok(bytes) => Ok(bytes)
		Err(err) => Err(PgReadErr(err))
	}
}

## Read one backend message from the stream.
read_message! : Client(_) => Try(ProtoBackend.Message, [PgReadErr(_), PgProtoErr(ProtoBackend.ProtoErr), ..others])
read_message! = |client| {
	header_bytes = read_bytes!(client, 5)?
	{ msg_type, len } =
		match ProtoBackend.header(header_bytes) {
			Ok(header) => Ok(header)
			Err(err) => Err(PgProtoErr(err))
		}?

	payload =
		if len > 0 {
			read_bytes!(client, len)?
		} else {
			[]
		}

	match ProtoBackend.message(msg_type, payload) {
		Ok(message) => Ok(message)
		Err(err) => Err(PgProtoErr(err))
	}
}

## The startup conversation: send the startup message, answer an auth
## challenge if the server sends one, then collect the backend key until
## ReadyForQuery.
do_startup! : _, { user : Str, database : Str, auth : [NoAuth, Password(Str)], timeout_ms : U64, params : List((Str, Str)), auth_methods : List([Scram, Md5, Cleartext, Trust]), random_u64! : () => Try(U64, _) } => Try(Client(_), Client.StartupErr(_, _, others))
do_startup! = |stream, { user, database, auth, timeout_ms, params, auth_methods, random_u64! }| {
	client = Client.{ stream, timeout_ms, backend_key: Pending, in_transaction: Bool.False }
	write_all!(client, ProtoFrontend.startup({ user, database, params }))?
	startup_loop!(client, { user, auth, auth_methods, random_u64! }, Waiting)
}

## Every login this package speaks, allowed when the app names none.
all_auth_methods : List([Scram, Md5, Cleartext, Trust])
all_auth_methods = [Scram, Md5, Cleartext, Trust]

## The login and the rest of the startup, one backend message at a time.
## `login` is how far the authentication got, which decides what the server
## may send next: `Waiting`, `PasswordSent`, the SCRAM steps, `Authenticated`.
startup_loop! : Client(_), { user : Str, auth : [NoAuth, Password(Str)], auth_methods : List([Scram, Md5, Cleartext, Trust]), random_u64! : () => Try(U64, _) }, _ => Try(Client(_), Client.StartupErr(_, _, others))
startup_loop! = |client, settings, login|
	match read_message!(client)? {
		AuthOk => {
			check_authenticated(settings, login)?
			startup_loop!(client, settings, Authenticated)
		}
		AuthCleartextPassword => {
			password = password_for(settings, Cleartext, "password")?
			write_all!(client, ProtoFrontend.password_message(password))?
			startup_loop!(client, settings, PasswordSent)
		}
		AuthMd5Password(salt) => {
			password = password_for(settings, Md5, "md5")?
			write_all!(client, ProtoFrontend.md5_password_message({ user: settings.user, password, salt }))?
			startup_loop!(client, settings, PasswordSent)
		}
		AuthSasl(offered) => {
			first = scram_start!(settings, offered)?
			write_all!(client, ProtoFrontend.sasl_initial_response({ mechanism: first.mechanism(), data: first.message() }))?
			startup_loop!(client, settings, ScramStarted(first))
		}
		AuthSaslContinue(data) =>
			match login {
				ScramStarted(first) => {
					server_first = sasl_text(data)?
					final = first.receive_server_first(server_first) ? |err| ScramFailed(Str.inspect(err))
					write_all!(client, ProtoFrontend.sasl_response(final.message()))?
					startup_loop!(client, settings, ScramAnswered(final))
				}
				_ => unexpected_in_login("AuthSaslContinue")
			}
		AuthSaslFinal(data) =>
			match login {
				ScramAnswered(final) => {
					server_final = sasl_text(data)?
					final.verify_server_final(server_final) ? |err| ScramFailed(Str.inspect(err))
					startup_loop!(client, settings, ScramVerified)
				}
				_ => unexpected_in_login("AuthSaslFinal")
			}
		AuthUnsupported(code) => Err(UnsupportedAuth(code))
		ParameterStatus(_) => startup_loop!(client, settings, login)
		NoticeResponse => startup_loop!(client, settings, login)
		BackendKeyData(key) => startup_loop!({ ..client, backend_key: Known(key) }, settings, login)
		ReadyForQuery(_) =>
			match login {
				Authenticated => Ok(client)
				_ => unexpected_in_login("ReadyForQuery")
			}
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

## Whether the client agrees the login is done when the server says so. A
## SCRAM exchange counts only once the server proved it knows the password.
## A server that lets the client in without asking for anything counts only
## when `Trust` is allowed, which is how a downgrade to no login at all is
## caught. The method of any other login was allowed when the server asked
## for it.
check_authenticated : _, _ -> Try({}, [AuthMethodNotAllowed(Str), ScramFailed(Str), ..others])
check_authenticated = |settings, login|
	match login {
		ScramStarted(_) => Err(ScramFailed("the server ended the login before it proved it knows the password"))
		ScramAnswered(_) => Err(ScramFailed("the server ended the login before it proved it knows the password"))
		Waiting =>
			if settings.auth_methods.contains(Trust) {
				Ok({})
			} else {
				Err(AuthMethodNotAllowed("trust"))
			}
		_ => Ok({})
	}

## The password to answer the server's request for `method` with: refused
## when the app does not allow the method, or gave no password.
password_for : _, [Scram, Md5, Cleartext, Trust], Str -> Try(Str, [AuthMethodNotAllowed(Str), PasswordRequired, ..others])
password_for = |settings, method, name|
	if !settings.auth_methods.contains(method) {
		Err(AuthMethodNotAllowed(name))
	} else {
		match settings.auth {
			NoAuth => Err(PasswordRequired)
			Password(password) => Ok(password)
		}
	}

## Pick SCRAM-SHA-256 among the mechanisms the server offered and build the
## client-first message. A plaintext connection has nothing to bind the
## login to, so the client never binds, and says so. The nonce is 24 bytes
## from the platform's `random_u64!`, which draws from the operating system.
scram_start! : _, List(Str) => Try(Scram.ClientFirst, [AuthMethodNotAllowed(Str), PasswordRequired, ScramFailed(Str), ..others])
scram_start! = |settings, offered| {
	password =
		if !settings.auth_methods.contains(Scram) {
			return Err(AuthMethodNotAllowed("SCRAM-SHA-256"))
		} else {
			match settings.auth {
				NoAuth => return Err(PasswordRequired)
				Password(given) => given
			}
		}
	binding =
		match Scram.select({ offered, transport: Plain, require_channel_binding: Bool.False }) {
			Ok(chosen) => Ok(chosen)
			Err(err) => Err(ScramFailed(Str.inspect(err)))
		}?
	a = random_u64!(settings.random_u64!)?
	b = random_u64!(settings.random_u64!)?
	c = random_u64!(settings.random_u64!)?
	nonce = [a, b, c].map(|value| [0, 8, 16, 24, 32, 40, 48, 56].map(|shift| value.shr_zf_wrap(shift).to_u8_wrap())).join()
	first = Scram.start({ username: "", password, nonce, channel_binding: binding }) ? |err| ScramFailed(Str.inspect(err))
	Ok(first)
}

## A random U64 from the platform's `random_u64!`, for the SCRAM nonce.
random_u64! : (() => Try(U64, _)) => Try(U64, [ScramFailed(Str), ..others])
random_u64! = |random!| {
	value = random!() ? |err| ScramFailed("the platform gave no random bytes for the nonce: ${Str.inspect(err)}")
	Ok(value)
}

## The text of a SASL message. One that is not UTF-8 breaks the protocol.
sasl_text : List(U8) -> Try(Str, [PgProtoErr(ProtoBackend.ProtoErr), ..others])
sasl_text = |data|
	match Str.from_utf8(data) {
		Ok(text) => Ok(text)
		Err(_) => Err(PgProtoErr(BadUtf8))
	}

## A login message that arrived out of turn, like a SCRAM step no exchange
## asked for, or ReadyForQuery before the login finished.
unexpected_in_login : Str -> Try(a, [PgProtoErr(ProtoBackend.ProtoErr), ..others])
unexpected_in_login = |what| Err(PgProtoErr(UnexpectedMsg("${what} out of turn in the login")))

## The messages that run `sql` once as an unnamed statement: Parse, Bind,
## Describe, Execute and Sync.
unnamed_messages : Str, List([Text, Binary]), List([Null, Value(List(U8))]) -> List(List(U8))
unnamed_messages = |sql, format_codes, param_values| [
	ProtoFrontend.parse({ sql: sql, name: "" }),
	ProtoFrontend.bind({ prepared_statement: "", format_codes: format_codes, param_values: param_values }),
	ProtoFrontend.describe_portal({}),
	ProtoFrontend.execute,
	ProtoFrontend.sync,
]

## Read the reply to one command through its ReadyForQuery.
##
## On a server error the backend skips to the next Sync and still sends
## ReadyForQuery, so this drains to it before returning the error.
## Otherwise the next command on this connection would read this
## conversation's leftover messages.
read_reply! : Client(_), List(ProtoBackend.Column) => Try(PgResult.PgResult, Client.CommandErr(_, _, others))
read_reply! = |client, init_columns|
	match read_cmd_result!(client, init_columns, []) {
		Ok(result) =>
			match read_ready_for_query!(client)?.outcome {
				# The command completed but the conversation still ended in
				# an error, e.g. an implicit commit failing on a deferred
				# constraint after CommandComplete was already sent.
				NoError => Ok(result)
				SawError(error) => Err(PgErr(error))
			}
		Err(PgErr(error)) => drain_after_error!(client, error)
		Err(other) => Err(other)
	}

## Return a server error once the conversation it ended is over. After an
## ERROR the server skips to the next Sync and answers ReadyForQuery, which
## this reads. The first error is the one the caller cares about, so any
## further ErrorResponse in the drain never replaces it. After a FATAL or
## PANIC the server closes the connection and sends nothing more, so waiting
## for ReadyForQuery would only turn the error into a failed read.
drain_after_error! : Client(_), ProtoBackend.Error => Try(a, Client.CommandErr(_, _, others))
drain_after_error! = |client, error|
	if closes_connection(error) {
		Err(PgErr(error))
	} else {
		_ = read_ready_for_query!(client)?
		Err(PgErr(error))
	}

## Whether the server closes the connection after this error.
closes_connection : ProtoBackend.Error -> Bool
closes_connection = |error| error.severity == "FATAL" or error.severity == "PANIC"

## The savepoint a nested [Client.transaction!] runs in. One name serves
## every level: Postgres keeps a savepoint that shares its name with a newer
## one, and `rollback to` and `release` act on the newest, so nesting works
## as long as each level releases its own before it returns.
savepoint = "roc_pg_transaction"

## Start a transaction, or a savepoint when the connection is already in
## one, and say which.
##
## The client a body was given knows it is inside a transaction, so that
## one goes straight to the savepoint. Any other client asks the server: a
## Sync goes out ahead of the `begin`, in the same write, so the server
## reports the transaction status from before the `begin` without an extra
## round trip. Only when some code reached a transaction without going
## through the body's client, such as a body that closes over the outer
## client, does that `begin` land inside one. It changes nothing there (the
## server only warns), and inside a failed transaction it is refused like
## any other statement.
open_transaction! : Client(_) => Try([Outermost, Nested], Client.CommandErr(_, _, others))
open_transaction! = |client|
	if client.in_transaction {
		open_savepoint!(client)
	} else {
		write_all!(client, Bytes.sequence([ProtoFrontend.sync].concat(unnamed_messages("begin", [], []))))?
		# A lone Sync has nothing to fail, so only its status matters.
		before = read_ready_for_query!(client)?
		_ = read_reply!(client, [])?
		match before.status {
			Idle => Ok(Outermost)
			_ => open_savepoint!(client)
		}
	}

open_savepoint! : Client(_) => Try([Outermost, Nested], Client.CommandErr(_, _, others))
open_savepoint! = |client| {
	_ = Client.command!(client, Statement.new("savepoint ${savepoint}"))?
	Ok(Nested)
}

## Finish a transaction whose body succeeded: `commit` the outermost one,
## `release` the savepoint of a nested one.
close_transaction! : Client(_), [Outermost, Nested] => Try({}, [TransactionAborted, TransactionCommitRefused(Client.ServerError), TransactionCommitFailed(Client.CommandErr(_, _, [])), ..others])
close_transaction! = |client, level|
	match level {
		Outermost =>
			match Client.command!(client, Statement.new("commit")) {
				# The commit of a transaction in which a statement failed is
				# answered with a ROLLBACK tag, not an error.
				Ok(result) if PgResult.command_tag(result) == "ROLLBACK" => Err(TransactionAborted)
				Ok(_) => Ok({})
				Err(PgErr(error)) => Err(TransactionCommitRefused(error))
				Err(err) => Err(TransactionCommitFailed(err))
			}

		Nested =>
			match Client.command!(client, Statement.new("release savepoint ${savepoint}")) {
				Ok(_) => Ok({})
				Err(PgErr(error)) => {
					# Roll back to the savepoint, which also clears a failed
					# statement from the enclosing transaction, so that one can
					# go on as if this nested call had failed on its own.
					undo_transaction!(client, Nested)
					# 25P02 is in_failed_sql_transaction: a statement of this
					# body failed and the body carried on.
					if error.code == "25P02" Err(TransactionAborted) else Err(TransactionCommitRefused(error))
				}
				Err(err) => Err(TransactionCommitFailed(err))
			}
	}

## Undo a transaction whose body failed: `rollback` the outermost one, roll
## back to the savepoint of a nested one and release it. Best effort: when
## this fails, the connection's next statement fails too.
undo_transaction! : Client(_), [Outermost, Nested] => {}
undo_transaction! = |client, level|
	match level {
		Outermost => {
			_ = Client.command!(client, Statement.new("rollback"))
			{}
		}

		Nested => {
			_ = Client.command!(client, Statement.new("rollback to savepoint ${savepoint}"))
			_ = Client.command!(client, Statement.new("release savepoint ${savepoint}"))
			{}
		}
	}

## Collect data rows until the command completes.
read_cmd_result! : Client(_), List(ProtoBackend.Column), List(List([Null, Present(List(U8))])) => Try(PgResult.PgResult, Client.CommandErr(_, _, others))
read_cmd_result! = |client, columns, rows|
	match read_message!(client)? {
		ParseComplete | BindComplete | ParameterDescription | NoData => read_cmd_result!(client, columns, rows)
		ParameterStatus(_) | NoticeResponse => read_cmd_result!(client, columns, rows)
		RowDescription(new_columns) => read_cmd_result!(client, new_columns, rows)
		DataRow(row) => read_cmd_result!(client, columns, rows.append(row))
		CommandComplete(tag) => Ok(PgResult.new(columns.map(|column| column.name), rows, tag))
		EmptyQueryResponse => Ok(PgResult.new(columns.map(|column| column.name), rows, ""))
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

## Read the replies to a batch through its ReadyForQuery. Each statement
## ends in CommandComplete (or EmptyQueryResponse), and a `select` sends
## its rows first, which are dropped. An error ends the batch, and the
## server still answers ReadyForQuery, which drain_after_error! reads.
read_batch! : Client(_) => Try({}, Client.CommandErr(_, _, others))
read_batch! = |client|
	match read_message!(client)? {
		RowDescription(_) | DataRow(_) | CommandComplete(_) | EmptyQueryResponse => read_batch!(client)
		ParameterStatus(_) | NoticeResponse => read_batch!(client)
		ReadyForQuery(_) => Ok({})
		ErrorResponse(error) => drain_after_error!(client, error)
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

## After a command result, consume messages until ReadyForQuery, remembering
## the first server error seen on the way plus the transaction status that
## ReadyForQuery reports. An `ErrorResponse` is data (`SawError`), so a drain
## can never lose an earlier, more relevant error to a later one. Only
## transport and protocol failures are returned as `Err`, and a FATAL or
## PANIC error, after which the server closes the connection instead of
## answering ReadyForQuery.
read_ready_for_query! : Client(_) => Try({ status : ProtoBackend.Status, outcome : [NoError, SawError(ProtoBackend.Error)] }, [PgErr(ProtoBackend.Error), PgReadErr(_), PgProtoErr(ProtoBackend.ProtoErr), ..others])
read_ready_for_query! = |client|
	drain_loop!(client, NoError)

drain_loop! : Client(_), [NoError, SawError(ProtoBackend.Error)] => Try({ status : ProtoBackend.Status, outcome : [NoError, SawError(ProtoBackend.Error)] }, [PgErr(ProtoBackend.Error), PgReadErr(_), PgProtoErr(ProtoBackend.ProtoErr), ..others])
drain_loop! = |client, first|
	match drain_step(read_message!(client)?, first) {
		Continue(next) => drain_loop!(client, next)
		Done(final) => Ok(final)
		Closed(error) => Err(PgErr(error))
		Unexpected(msg) => Err(PgProtoErr(UnexpectedMsg(msg)))
	}

## One step of draining to ReadyForQuery. Pure, so the first-error-wins
## behavior is testable without a connection (see the expects below).
drain_step : ProtoBackend.Message, [NoError, SawError(ProtoBackend.Error)] -> [Continue([NoError, SawError(ProtoBackend.Error)]), Done({ status : ProtoBackend.Status, outcome : [NoError, SawError(ProtoBackend.Error)] }), Closed(ProtoBackend.Error), Unexpected(Str)]
drain_step = |msg, first|
	match msg {
		ReadyForQuery(status) => Done({ status, outcome: first })
		# The connection is gone, which matters more than an earlier error.
		ErrorResponse(error) if closes_connection(error) => Closed(error)
		ErrorResponse(error) =>
			match first {
				NoError => Continue(SawError(error))
				SawError(_) => Continue(first)
			}
		CloseComplete | ParameterStatus(_) | NoticeResponse => Continue(first)
		other => Unexpected(Str.inspect(other))
	}

## Collect the column names of a just-prepared statement until ReadyForQuery.
read_prepare_columns! : Client(_), List(ProtoBackend.Column) => Try(List(ProtoBackend.Column), Client.CommandErr(_, _, others))
read_prepare_columns! = |client, columns|
	match read_message!(client)? {
		CloseComplete | ParseComplete | ParameterDescription | NoData => read_prepare_columns!(client, columns)
		ParameterStatus(_) | NoticeResponse => read_prepare_columns!(client, columns)
		RowDescription(new_columns) => read_prepare_columns!(client, new_columns)
		ReadyForQuery(_) => Ok(columns)
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

# ---- drain_step unit tests ----

test_error : Str -> ProtoBackend.Error
test_error = |code| test_error_of_severity(code, "ERROR")

test_error_of_severity : Str, Str -> ProtoBackend.Error
test_error_of_severity = |code, severity| {
	severity,
	localized_severity: severity,
	code,
	message: "test",
	detail: NoField,
	hint: NoField,
	position: NoField,
	ewhere: NoField,
	schema_name: NoField,
	table_name: NoField,
	column_name: NoField,
	data_type_name: NoField,
	constraint_name: NoField,
	file: NoField,
	line: NoField,
	routine: NoField,
}

# ReadyForQuery ends the drain and reports what was seen, plus the
# transaction status the connection ended up in.
expect drain_step(ReadyForQuery(Idle), NoError) == Done({ status: Idle, outcome: NoError })
expect drain_step(ReadyForQuery(TransactionBlock), NoError) == Done({ status: TransactionBlock, outcome: NoError })
expect drain_step(ReadyForQuery(Idle), SawError(test_error("23505"))) == Done({ status: Idle, outcome: SawError(test_error("23505")) })

# An error during the drain is recorded, not returned as a failure.
expect drain_step(ErrorResponse(test_error("23505")), NoError) == Continue(SawError(test_error("23505")))

# The first error wins: a second ErrorResponse never replaces it.
expect drain_step(ErrorResponse(test_error("XX000")), SawError(test_error("23505"))) == Continue(SawError(test_error("23505")))

# Housekeeping messages pass through without touching the recorded error.
expect drain_step(NoticeResponse, SawError(test_error("23505"))) == Continue(SawError(test_error("23505")))
expect drain_step(CloseComplete, NoError) == Continue(NoError)
expect drain_step(ParameterStatus({ name: "TimeZone", value: "UTC" }), NoError) == Continue(NoError)

# Anything else mid-drain is a protocol error.
expect drain_step(BindComplete, NoError) == Unexpected(Str.inspect(BindComplete))

# A FATAL or PANIC error ends the drain at once, even after an earlier
# error: the server closes the connection rather than send ReadyForQuery.
expect drain_step(ErrorResponse(test_error_of_severity("57P01", "FATAL")), NoError) == Closed(test_error_of_severity("57P01", "FATAL"))
expect drain_step(ErrorResponse(test_error_of_severity("XX000", "PANIC")), SawError(test_error("23505"))) == Closed(test_error_of_severity("XX000", "PANIC"))

## The server side name of a prepared statement: a digest of the SQL, then
## the name the caller chose. The digest comes first because Postgres only
## looks at the first 63 bytes of a statement name.
statement_name : Str, Str -> Str
statement_name = |sql, given_name| {
	digest = Crypto.SHA256.hash(sql.to_utf8()).to_hex()
	prefix = Str.from_utf8_lossy(digest.to_utf8().take_first(16))
	"${prefix}_${given_name}"
}

# The same query under the same name is the same statement, so preparing it
# again on the same connection replaces it with itself.
expect statement_name("select 1", "one") == statement_name("select 1", "one")

# Different queries under one name are different statements.
expect statement_name("select 1", "one") != statement_name("select 2", "one")

# Sixteen hex characters, an underscore, then the caller's name.
expect statement_name("select 1", "one").to_utf8().len() == 20
expect statement_name("select 1", "one").ends_with("_one")

# ---- login policy unit tests ----

with_methods = |auth_methods| { auth_methods, auth: Password("secret") }

# A SCRAM exchange is done only once the server proved it knows the password:
# AuthOk in the middle of one is refused, whatever is allowed.
expect check_authenticated(with_methods(all_auth_methods), ScramStarted({})) == Err(ScramFailed("the server ended the login before it proved it knows the password"))
expect check_authenticated(with_methods(all_auth_methods), ScramAnswered({})) == Err(ScramFailed("the server ended the login before it proved it knows the password"))
expect check_authenticated(with_methods([Scram]), ScramVerified) == Ok({})

# A server that lets the client in without asking is refused unless Trust is
# allowed.
expect check_authenticated(with_methods(all_auth_methods), Waiting) == Ok({})
expect check_authenticated(with_methods([Scram]), Waiting) == Err(AuthMethodNotAllowed("trust"))
expect check_authenticated(with_methods([Md5]), Waiting) == Err(AuthMethodNotAllowed("trust"))
expect check_authenticated(with_methods([Md5]), PasswordSent) == Ok({})

# A method left out of auth_methods is refused, as is a request for a
# password without one.
expect password_for(with_methods([Scram, Cleartext]), Md5, "md5") == Err(AuthMethodNotAllowed("md5"))
expect password_for(with_methods([Scram]), Cleartext, "password") == Err(AuthMethodNotAllowed("password"))
expect password_for(with_methods([Md5]), Md5, "md5") == Ok("secret")
expect password_for({ auth_methods: all_auth_methods, auth: NoAuth }, Md5, "md5") == Err(PasswordRequired)
