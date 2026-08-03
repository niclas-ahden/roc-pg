## Encoders for the messages the client sends to the Postgres server.
## https://www.postgresql.org/docs/current/protocol-message-formats.html
import Bytes

ProtoFrontend :: [].{
	FormatCode : [Text, Binary]

	startup : { user : Str, database : Str } -> List(U8)
	startup = |{ user, database }|
		prepend_length(
			Bytes.sequence([
				# Protocol version 3.0
				Bytes.i16(3),
				Bytes.i16(0),
				Bytes.null_terminate(
					Bytes.sequence([
						startup_param("client_encoding", "UTF8"),
						startup_param("user", user),
						startup_param("database", database),
					]),
				),
			]),
		)

	password_message : Str -> List(U8)
	password_message = |pwd| message('p', [Bytes.c_str(pwd)])

	terminate : List(U8)
	terminate = message('X', [])

	parse : { sql : Str, name : Str } -> List(U8)
	parse = |{ sql, name }|
		message(
			'P',
			[
				Bytes.c_str(name),
				Bytes.c_str(sql),
				# no pre-specified parameter type oids
				Bytes.i16(0),
			],
		)

	bind :
		{
			prepared_statement : Str,
			format_codes : List(FormatCode),
			param_values : List([Null, Value(List(U8))]),
		} -> List(U8)
	bind = |{ prepared_statement, format_codes, param_values }|
		message(
			'B',
			[
				# portal name (unnamed)
				Bytes.c_str(""),
				Bytes.c_str(prepared_statement),
				array(format_codes.map(|code| format_code(code))),
				array(
					param_values.map(
						|value|
							match value {
								Null => Bytes.i32(-1)
								Value(b) => length_prefixed(b)
							},
					),
				),
				# no column format codes: everything as text
				Bytes.i16(0),
			],
		)

	describe_portal : {} -> List(U8)
	describe_portal = |{}| message('D', [Bytes.u8('P'), Bytes.c_str("")])

	describe_statement : { name : Str } -> List(U8)
	describe_statement = |{ name }| message('D', [Bytes.u8('S'), Bytes.c_str(name)])

	## Close (deallocate) a named prepared statement. Closing a name that was
	## never prepared is not an error, which makes re-preparing idempotent.
	close_statement : { name : Str } -> List(U8)
	close_statement = |{ name }| message('C', [Bytes.u8('S'), Bytes.c_str(name)])

	execute : { limit : [NoLimit, Limit(I32)] } -> List(U8)
	execute = |{ limit }| {
		limit_or_zero = 
			match limit {
				NoLimit => 0
				Limit(lim) => lim
			}

		# unnamed portal
		message('E', [Bytes.c_str(""), Bytes.i32(limit_or_zero)])
	}

	sync : List(U8)
	sync = message('S', [])
}

startup_param : Str, Str -> List(U8)
startup_param = |key, value|
	Bytes.sequence([Bytes.c_str(key), Bytes.c_str(value)])

format_code : [Text, Binary] -> List(U8)
format_code = |code|
	match code {
		Text => Bytes.i16(0)
		Binary => Bytes.i16(1)
	}

## An i16 count followed by the already-encoded items.
array : List(List(U8)) -> List(U8)
array = |encoded_items|
	Bytes.sequence([
		Bytes.i16(encoded_items.len().to_i16_wrap()),
		Bytes.sequence(encoded_items),
	])

length_prefixed : List(U8) -> List(U8)
length_prefixed = |value|
	Bytes.sequence([Bytes.i32(value.len().to_i32_wrap()), value])

message : U8, List(List(U8)) -> List(U8)
message = |msg_type, content|
	Bytes.sequence([Bytes.u8(msg_type), prepend_length(Bytes.sequence(content))])

prepend_length : List(U8) -> List(U8)
prepend_length = |msg|
	Bytes.i32((msg.len() + 4).to_i32_wrap()).concat(msg)

# 'S' plus a length of 4 (the length includes itself).
expect ProtoFrontend.sync == [83, 0, 0, 0, 4]
expect ProtoFrontend.terminate == [88, 0, 0, 0, 4]

# 'p', length, then the password as a c string.
expect ProtoFrontend.password_message("abc") == [112, 0, 0, 0, 8, 97, 98, 99, 0]

# Startup: length, protocol 3.0, then null-terminated key/value params.
expect
	ProtoFrontend.startup({ user: "u", database: "d" })
		== Bytes.sequence([
			[0, 0, 0, 48, 0, 3, 0, 0],
			Bytes.c_str("client_encoding"),
			Bytes.c_str("UTF8"),
			Bytes.c_str("user"),
			Bytes.c_str("u"),
			Bytes.c_str("database"),
			Bytes.c_str("d"),
			[0],
		])
