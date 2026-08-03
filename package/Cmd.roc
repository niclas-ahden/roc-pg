## A Postgres command: SQL (or a prepared statement) plus parameter bindings.
##
## ```
## cmd = Cmd.new("select * from users where id = $1").bind([Cmd.u64(user_id)])
## result = Client.command!(cmd, client)?
## ```
##
## Unlike the pre-port roc-pg, a `Cmd` carries no decode function (storing
## closures in data structures crashes the current compiler); decode the
## `PgResult` with `PgResult.decode` after running the command.
import ProtoBackend

Cmd :: {
	kind : Kind,
	bindings : List(Binding),
	row_limit : RowLimit,
}.{
	## One `$n` parameter value on the wire: SQL NULL, a text-format value,
	## or a binary-format value.
	Binding : [NullBinding, Text(Str), Binary(List(U8))]

	## What a prepared statement needs to run anywhere: its server-side name,
	## the SQL to re-parse on a connection where that name does not exist,
	## the backend it was prepared on, and its result columns.
	Prepared : {
		name : Str,
		sql : Str,
		prepared_on : [Pending, Known(ProtoBackend.KeyData)],
		fields : List(ProtoBackend.RowField),
	}

	Kind : [SqlCmd(Str), PreparedCmd(Prepared)]

	RowLimit : [NoLimit, Limit(I32)]

	## Create a command from a SQL string. Use `$1`, `$2`, ... placeholders
	## for parameters and supply them with [Cmd.bind].
	new : Str -> Cmd
	new = |sql| {
		kind: SqlCmd(sql),
		bindings: [],
		row_limit: NoLimit,
	}

	## Create a command from a prepared statement (see `Client.prepare!`).
	##
	## The statement name only exists on the connection it was prepared on,
	## so the command also carries its SQL and the backend key it was
	## prepared against: run on a different connection (e.g. after a pool
	## checkout), `Client.command!` transparently falls back to re-parsing
	## the SQL as an unnamed statement instead of failing with
	## "prepared statement does not exist".
	prepared : Prepared -> Cmd
	prepared = |prep| {
		kind: PreparedCmd(prep),
		bindings: [],
		row_limit: NoLimit,
	}

	## Supply the parameter bindings for the command's `$n` placeholders.
	bind : Cmd, List(Binding) -> Cmd
	bind = |cmd, bindings| { ..cmd, bindings }

	## The command's kind (used by `Client.command!`).
	kind : Cmd -> Kind
	kind = |cmd| cmd.kind

	## The command's row limit (used by `Client.command!`).
	limit_of : Cmd -> RowLimit
	limit_of = |cmd| cmd.row_limit

	## Ask the server to return at most `n` rows.
	limit : Cmd, I32 -> Cmd
	limit = |cmd, n| { ..cmd, row_limit: Limit(n) }

	# ---- Binding constructors ----

	null : Binding
	null = NullBinding

	str : Str -> Binding
	str = |value| Text(value)

	bytes : List(U8) -> Binding
	bytes = |value| Binary(value)

	bool : Bool -> Binding
	bool = |value| if value Text("t") else Text("f")

	u8 : U8 -> Binding
	u8 = |value| Text(value.to_str())

	u16 : U16 -> Binding
	u16 = |value| Text(value.to_str())

	u32 : U32 -> Binding
	u32 = |value| Text(value.to_str())

	u64 : U64 -> Binding
	u64 = |value| Text(value.to_str())

	i8 : I8 -> Binding
	i8 = |value| Text(value.to_str())

	i16 : I16 -> Binding
	i16 = |value| Text(value.to_str())

	i32 : I32 -> Binding
	i32 = |value| Text(value.to_str())

	i64 : I64 -> Binding
	i64 = |value| Text(value.to_str())

	f32 : F32 -> Binding
	f32 = |value| Text(value.to_str())

	f64 : F64 -> Binding
	f64 = |value| Text(value.to_str())

	## Encode the bindings as wire-format values plus their format codes.
	encode_bindings :
		Cmd -> {
			format_codes : List([Text, Binary]),
			param_values : List([Null, Value(List(U8))]),
		}
	encode_bindings = |cmd| {
		format_codes = cmd.bindings.map(
			|binding|
				match binding {
					NullBinding => Binary
					Binary(_) => Binary
					Text(_) => Text
				},
		)
		param_values = cmd.bindings.map(
			|binding|
				match binding {
					NullBinding => Null
					Binary(value) => Value(value)
					Text(value) => Value(value.to_utf8())
				},
		)
		{ format_codes, param_values }
	}
}
