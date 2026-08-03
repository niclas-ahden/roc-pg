## A Postgres client connection.
##
## The package cannot import platform modules, so all IO arrives through an
## `effects` record of platform functions (the same pattern as roc-playwright).
## Build it once from basic-cli's `Tcp` module:
##
## ```
## effects = {
##     connect!: Tcp.connect!,
##     write!: Tcp.Stream.write!,
##     read_exactly!: Tcp.Stream.read_exactly!,
##     close!: Tcp.close!,
##     pool!: Tcp.pool!,
##     pool_acquire!: Tcp.pool_acquire!,
##     pool_release!: Tcp.pool_release!,
## }
##
## client = Client.connect!(effects, {
##     host: "localhost",
##     port: 5432,
##     user: "postgres",
##     database: "postgres",
##     auth: NoAuth,
##     timeout_ms: 5000,
## })?
## result = Client.command!(Cmd.new("select 1 as one"), client)?
## ```
##
## `timeout_ms` caps each TCP dial, read, and write (not a whole command).
## Zero is not "no timeout": the platform fails a zero timeout immediately.
##
## For concurrent apps, prefer a [Pool] over a single shared client so parallel
## requests each get their own connection.
##
## A client value is a record `{ stream, effects, timeout_ms, backend_key }`;
## `command!`, `prepare!` and `close!` accept it as the last argument.
##
## Error handling: a server error (`PgErr`) leaves the connection usable, the
## client drains the conversation for you. After a transport or protocol error
## (`PgProtoErr`, `TcpReadErr`, ...) the connection state is unknown: `close!`
## it instead of reusing or releasing it.
import Bytes
import ProtoBackend
import ProtoFrontend
import Cmd
import PgResult

Client :: [].{

	## Connect and authenticate. `auth` is `NoAuth` or `Password(str)`
	## (cleartext; use pg_hba `trust` or `password` methods). A server that
	## asks for anything else fails with `UnsupportedAuth(code)`, where the
	## code is the protocol's auth type (5 is md5, 10 is scram-sha-256).
	connect! = |effects, { host, port, user, database, auth, timeout_ms }| {
		connect_stream! = effects.connect!
		stream = connect_stream!(host, port, timeout_ms)?
		match do_startup!(effects, stream, { user, database, auth, timeout_ms }) {
			Ok(client) => Ok(client)
			Err(err) => {
				# A half-started session is useless, and the package cannot
				# assume the platform closes dropped streams.
				close_stream! = effects.close!
				_ = close_stream!(stream)
				Err(err)
			}
		}
	}

	## Run a command and return its [PgResult].
	##
	## The wire conversation is: Parse, Bind, Describe, Execute, Sync — then
	## read messages until ReadyForQuery.
	command! = |cmd, client| {
		{ format_codes, param_values } = Cmd.encode_bindings(cmd)
		row_limit = Cmd.limit_of(cmd)

		# A named prepared statement only exists on the connection it was
		# prepared on. When this command's statement was prepared on a
		# DIFFERENT backend (a pool checkout landed elsewhere), fall back to
		# re-parsing its SQL as an unnamed statement — correct on any
		# connection, at the cost of one extra Parse.
		plan = 
			match Cmd.kind(cmd) {
				SqlCmd(sql) => UnnamedFlow(sql)
				PreparedCmd(prepared) =>
					match client.backend_key {
						Known(current) =>
							match prepared.prepared_on {
								Known(origin) =>
									# Backend keys are only unique within one
									# server, so statements prepared against a
									# different host could in principle collide.
									if current.process_id == origin.process_id and current.secret_key == origin.secret_key {
										PreparedFlow(prepared)
									} else {
										UnnamedFlow(prepared.sql)
									}
								Pending => UnnamedFlow(prepared.sql)
							}
						Pending => UnnamedFlow(prepared.sql)
					}
				}

		messages = 
			match plan {
				UnnamedFlow(sql) =>
					[
						ProtoFrontend.parse({ sql: sql, name: "" }),
						ProtoFrontend.bind({ prepared_statement: "", format_codes: format_codes, param_values: param_values }),
						ProtoFrontend.describe_portal({}),
						ProtoFrontend.execute({ limit: row_limit }),
						ProtoFrontend.sync,
					]
				PreparedFlow(prepared) =>
					[
						ProtoFrontend.bind({ prepared_statement: prepared.name, format_codes: format_codes, param_values: param_values }),
						ProtoFrontend.execute({ limit: row_limit }),
						ProtoFrontend.sync,
					]
				}

		init_fields = 
			match plan {
				UnnamedFlow(_) => []
				PreparedFlow(prepared) => prepared.fields
			}

		write_all!(client, Bytes.sequence(messages))?

		# On a server error the backend skips to the next Sync and still
		# sends ReadyForQuery, so drain to it before returning the error.
		# Otherwise the next command on this connection would read this
		# conversation's leftover messages.
		match read_cmd_result!(client, init_fields, []) {
			Ok(result) =>
				match read_ready_for_query!(client)?.outcome {
					# The command completed but the conversation still ended in
					# an error, e.g. an implicit commit failing on a deferred
					# constraint after CommandComplete was already sent.
					NoError => Ok(result)
					SawError(error) => Err(PgErr(error))
				}
			Err(PgErr(error)) => {
				# The first error is the one the caller cares about, so any
				# further ErrorResponse in the drain never replaces it.
				_ = read_ready_for_query!(client)?
				Err(PgErr(error))
			}
			Err(other) => Err(other)
		}
	}

	## Parse a named prepared statement on this connection. The returned
	## [Cmd] can be run many times with fresh bindings: on this connection it
	## uses the named statement directly; on any other connection (e.g. a
	## later pool checkout that landed on a different backend) `command!`
	## transparently re-parses the SQL as an unnamed statement instead.
	prepare! = |sql, { name, client }| {
		write_all!(
			client,
			Bytes.sequence([
				# Close first so preparing the same name on a recycled
				# pooled connection replaces the old statement instead of
				# failing with "prepared statement already exists".
				ProtoFrontend.close_statement({ name: name }),
				ProtoFrontend.parse({ sql: sql, name: name }),
				ProtoFrontend.describe_statement({ name: name }),
				ProtoFrontend.sync,
			]),
		)?

		# Same drain as command!, a failed Parse still ends in ReadyForQuery.
		match read_prepare_fields!(client, []) {
			Ok(fields) => Ok(Cmd.prepared({ name, sql, prepared_on: client.backend_key, fields }))
			Err(PgErr(error)) => {
				_ = read_ready_for_query!(client)?
				Err(PgErr(error))
			}
			Err(other) => Err(other)
		}
	}

	## Tell the server the session is over (Terminate), then close the
	## stream. The write is best effort: a dead connection closes anyway.
	close! = |client| {
		_ = write_all!(client, ProtoFrontend.terminate)
		close_stream! = client.effects.close!
		close_stream!(client.stream)
	}

	## Run the startup/auth conversation on a fresh stream and return a
	## client. Used by [Pool.acquire!]; apps normally use [Client.connect!].
	startup! = |effects, stream, opts| do_startup!(effects, stream, opts)

	## Round trip a Sync and report the transaction status the server ends
	## up in: `Idle`, `TransactionBlock`, or `FailedTransactionBlock`. Used
	## by [Pool.release!] to decide whether a connection is clean enough to
	## go back into the pool.
	sync_status! = |client| {
		write_all!(client, ProtoFrontend.sync)?
		drained = read_ready_for_query!(client)?
		match drained.outcome {
			NoError => Ok(drained.status)
			SawError(error) => Err(PgErr(error))
		}
	}

	## Render a server error (the payload of `PgErr`) as a readable string.
	error_to_str : ProtoBackend.Error -> Str
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

write_all! = |client, bytes| {
	write! = client.effects.write!
	write!(client.stream, bytes, client.timeout_ms)
}

## Read one backend message from the stream.
read_message! = |client| {
	read_exactly! = client.effects.read_exactly!
	header_bytes = read_exactly!(client.stream, 5, client.timeout_ms)?
	{ msg_type, len } = ProtoBackend.header(header_bytes).map_err(|e| PgProtoErr(e))?

	payload = 
		if len > 0 {
			read_exactly!(client.stream, len, client.timeout_ms)?
		} else {
			[]
		}

	ProtoBackend.message(msg_type, payload).map_err(|e| PgProtoErr(e))
}

## The startup conversation: send the startup message, answer an auth
## challenge if the server sends one, then collect the backend key until
## ReadyForQuery.
do_startup! = |effects, stream, { user, database, auth, timeout_ms }| {
	client = { stream, effects, timeout_ms, backend_key: Pending }
	write_all!(client, ProtoFrontend.startup({ user, database }))?
	startup_loop!(client, auth)
}

startup_loop! = |client, auth|
	match read_message!(client)? {
		AuthOk => startup_loop!(client, auth)
		AuthCleartextPassword =>
			match auth {
				NoAuth => Err(PasswordRequired)
				Password(pwd) => {
					write_all!(client, ProtoFrontend.password_message(pwd))?
					startup_loop!(client, auth)
				}
			}
		AuthUnsupported(code) => Err(UnsupportedAuth(code))
		ParameterStatus(_) => startup_loop!(client, auth)
		NoticeResponse => startup_loop!(client, auth)
		BackendKeyData(key) => startup_loop!({ ..client, backend_key: Known(key) }, auth)
		ReadyForQuery(_) => Ok(client)
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

## Collect data rows until the command completes.
read_cmd_result! = |client, fields, rows|
	match read_message!(client)? {
		ParseComplete | BindComplete | ParameterDescription | NoData => read_cmd_result!(client, fields, rows)
		ParameterStatus(_) | NoticeResponse => read_cmd_result!(client, fields, rows)
		RowDescription(new_fields) => read_cmd_result!(client, new_fields, rows)
		DataRow(row) => read_cmd_result!(client, fields, rows.append(row))
		CommandComplete(_) | EmptyQueryResponse | PortalSuspended => Ok(PgResult.new(fields, rows))
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

## After a command result, consume messages until ReadyForQuery, remembering
## the first server error seen on the way plus the transaction status that
## ReadyForQuery reports. Only transport/protocol failures are returned as
## `Err`; an `ErrorResponse` is data (`SawError`), so a drain can never lose
## an earlier, more relevant error to a later one.
read_ready_for_query! = |client|
	drain_loop!(client, NoError)

drain_loop! = |client, first|
	match drain_step(read_message!(client)?, first) {
		Continue(next) => drain_loop!(client, next)
		Done(final) => Ok(final)
		Unexpected(msg) => Err(PgProtoErr(UnexpectedMsg(msg)))
	}

## One step of draining to ReadyForQuery. Pure, so the first-error-wins
## behavior is testable without a connection (see the expects below).
drain_step : ProtoBackend.Message, [NoError, SawError(ProtoBackend.Error)] -> [Continue([NoError, SawError(ProtoBackend.Error)]), Done({ status : ProtoBackend.Status, outcome : [NoError, SawError(ProtoBackend.Error)] }), Unexpected(Str)]
drain_step = |msg, first|
	match msg {
		ReadyForQuery(status) => Done({ status, outcome: first })
		ErrorResponse(error) =>
			match first {
				NoError => Continue(SawError(error))
				SawError(_) => Continue(first)
			}
		CloseComplete | ParameterStatus(_) | NoticeResponse => Continue(first)
		other => Unexpected(Str.inspect(other))
	}

## Collect the RowDescription for a just-prepared statement until ReadyForQuery.
read_prepare_fields! = |client, fields|
	match read_message!(client)? {
		CloseComplete | ParseComplete | ParameterDescription | NoData => read_prepare_fields!(client, fields)
		ParameterStatus(_) | NoticeResponse => read_prepare_fields!(client, fields)
		RowDescription(new_fields) => read_prepare_fields!(client, new_fields)
		ReadyForQuery(_) => Ok(fields)
		ErrorResponse(error) => Err(PgErr(error))
		other => Err(PgProtoErr(UnexpectedMsg(Str.inspect(other))))
	}

# ---- drain_step unit tests ----

test_error : Str -> ProtoBackend.Error
test_error = |code| {
	localized_severity: "ERROR",
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
