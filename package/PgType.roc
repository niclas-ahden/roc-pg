## Postgres's built in types against the Roc types values decode into and
## encode from: the type a result column's OID names, and which Roc types
## hold every value of which Postgres type. Both the build and a running
## query use it, so it reads no schema and no SQL.
##
## A type is spelled as `pg_dump` spells it (`integer`, `text[]`). Types and
## Roc types this does not know always fit, so a domain, an enum or a type
## of an extension is left to the server.
PgType :: [].{
	## What values a type holds, as far as fitting Roc types goes: integers
	## from `low` to `high`, any decimal, floats of 32 or 64 bits, booleans,
	## text, or a type this does not know.
	Values : [Integers(I128, I128), Decimals, Floats(U8), Booleans, Texts, Unknown]

	## The name of a built in type, from its OID as a result description
	## reports it.
	from_oid : I32 -> Try(Str, [UnknownOid])
	from_oid = |oid|
		match oid {
			16 => Ok("boolean")
			17 => Ok("bytea")
			20 => Ok("bigint")
			21 => Ok("smallint")
			23 => Ok("integer")
			25 => Ok("text")
			114 => Ok("json")
			700 => Ok("real")
			701 => Ok("double precision")
			869 => Ok("inet")
			1000 => Ok("boolean[]")
			1005 => Ok("smallint[]")
			1007 => Ok("integer[]")
			1009 => Ok("text[]")
			1015 => Ok("character varying[]")
			1016 => Ok("bigint[]")
			1021 => Ok("real[]")
			1022 => Ok("double precision[]")
			1042 => Ok("character")
			1043 => Ok("character varying")
			1082 => Ok("date")
			1083 => Ok("time without time zone")
			1114 => Ok("timestamp without time zone")
			1184 => Ok("timestamp with time zone")
			1231 => Ok("numeric[]")
			1700 => Ok("numeric")
			2950 => Ok("uuid")
			3802 => Ok("jsonb")
			_ => Err(UnknownOid)
		}

	## The values of a type without its array brackets.
	values : Str -> PgType.Values
	values = |type|
		if ["smallint", "int2", "smallserial"].contains(type) {
			Integers(-32768, 32767)
		} else if ["integer", "int", "int4", "serial"].contains(type) {
			Integers(-2147483648, 2147483647)
		} else if ["bigint", "int8", "bigserial"].contains(type) {
			Integers(-9223372036854775808, 9223372036854775807)
		} else if ["numeric", "decimal"].contains(type) {
			Decimals
		} else if ["real", "float4"].contains(type) {
			Floats(32)
		} else if ["double precision", "float8", "float"].contains(type) {
			Floats(64)
		} else if ["boolean", "bool"].contains(type) {
			Booleans
		} else if texts.contains(type) {
			Texts
		} else {
			Unknown
		}

	## Whether a row field that decodes as `kind` (a `RowFormat.Field` kind
	## such as `I32` or `List(Str)`) takes every value of a column of
	## `type`, whose values are `holds`: a narrower range than the type's
	## when a domain bounds it. Integers fit a Roc integer type whose range
	## holds theirs, a `Dec`, and a float that holds them exactly. `numeric`
	## fits `Dec`, which rounds a value past its 18 decimal places.
	field_holds : Str, PgType.Values, Str -> Bool
	field_holds = |kind, holds, type|
		if kind == "Str" or kind == "" {
			Bool.True
		} else if type.ends_with("[]") or kind.starts_with("List(") {
			match (element_kind(kind), type.ends_with("[]")) {
				(Ok(inner), Bool.True) => PgType.field_holds(inner, PgType.values(type.drop_suffix("[]")), type.drop_suffix("[]"))
				(Err(_), Bool.True) => Bool.False
				(Ok(_), Bool.False) => holds == Unknown
				(Err(_), Bool.False) => Bool.True
			}
		} else {
			match (holds, kind_values(kind)) {
				(Unknown, _) | (_, Unknown) => Bool.True
				(Integers(low, high), Integers(min, max)) => min <= low and high <= max
				(Integers(_, _), Decimals) => Bool.True
				(Integers(low, high), Floats(bits)) => exact_in_float(low, high, bits)
				(Decimals, Decimals) => Bool.True
				(Floats(bits), Floats(field_bits)) => bits <= field_bits
				(Booleans, Booleans) => Bool.True
				_ => Bool.False
			}
		}

	## Whether a column of `type`, whose values are `holds`, takes every
	## value of a parameter that encodes as `kind`. The server parses a
	## `Str` as the column's type, so it always fits.
	column_holds : Str, PgType.Values, Str -> Bool
	column_holds = |type, holds, kind|
		if kind == "Str" or kind == "" {
			Bool.True
		} else if type.ends_with("[]") or kind.starts_with("List(") {
			match (element_kind(kind), type.ends_with("[]")) {
				(Ok(inner), Bool.True) => PgType.column_holds(type.drop_suffix("[]"), PgType.values(type.drop_suffix("[]")), inner)
				(Err(_), Bool.True) => Bool.False
				(Ok(_), Bool.False) => holds == Unknown
				(Err(_), Bool.False) => Bool.True
			}
		} else {
			match (holds, kind_values(kind)) {
				(Unknown, _) | (_, Unknown) => Bool.True
				(Integers(low, high), Integers(min, max)) => low <= min and max <= high
				(Decimals, Integers(_, _)) | (Decimals, Decimals) | (Decimals, Floats(_)) => Bool.True
				(Floats(bits), Integers(min, max)) => exact_in_float(min, max, bits)
				(Floats(bits), Floats(kind_bits)) => kind_bits <= bits
				(Booleans, Booleans) => Bool.True
				_ => Bool.False
			}
		}
}

## Types whose values decode as text and nothing else.
texts : List(Str)
texts = ["text", "character varying", "varchar", "character", "char", "bpchar", "name", "citext", "uuid", "date", "time without time zone", "time with time zone", "time", "timetz", "timestamp without time zone", "timestamp with time zone", "timestamp", "timestamptz", "interval", "json", "jsonb", "inet", "cidr", "macaddr", "bytea", "xml", "tsvector", "money"]

## The values of a Roc type that a field or a parameter is.
kind_values : Str -> PgType.Values
kind_values = |kind|
	match kind {
		"I8" => Integers(-128, 127)
		"U8" => Integers(0, 255)
		"I16" => Integers(-32768, 32767)
		"U16" => Integers(0, 65535)
		"I32" => Integers(-2147483648, 2147483647)
		"U32" => Integers(0, 4294967295)
		"I64" => Integers(-9223372036854775808, 9223372036854775807)
		"U64" => Integers(0, 18446744073709551615)
		"Dec" => Decimals
		"F32" => Floats(32)
		"F64" => Floats(64)
		"Bool" => Booleans
		_ => Unknown
	}

element_kind : Str -> Try(Str, [NotAList])
element_kind = |kind| if kind.starts_with("List(") Ok(kind.drop_prefix("List(").drop_suffix(")")) else Err(NotAList)

## Whether every integer from `low` to `high` is a float of `bits` bits,
## which has 24 or 53 bits of mantissa.
exact_in_float : I128, I128, U8 -> Bool
exact_in_float = |low, high, bits| {
	limit = if bits == 32 16777216 else 9007199254740992
	-limit <= low and high <= limit
}

expect PgType.field_holds("I32", PgType.values("integer"), "integer")
expect PgType.field_holds("I64", PgType.values("integer"), "integer")
expect !PgType.field_holds("I32", PgType.values("bigint"), "bigint")
expect !PgType.field_holds("I16", PgType.values("integer"), "integer")
expect !PgType.field_holds("U16", PgType.values("smallint"), "smallint")
expect !PgType.field_holds("U8", PgType.values("smallint"), "smallint")
expect PgType.field_holds("U8", Integers(0, 255), "u8")
expect PgType.field_holds("U16", Integers(0, 255), "u8")
expect !PgType.field_holds("I8", Integers(0, 255), "u8")
expect PgType.field_holds("Dec", PgType.values("bigint"), "bigint")
expect PgType.field_holds("Dec", PgType.values("numeric"), "numeric")
expect !PgType.field_holds("I64", PgType.values("numeric"), "numeric")
expect PgType.field_holds("F64", PgType.values("integer"), "integer")
expect !PgType.field_holds("F64", PgType.values("bigint"), "bigint")
expect !PgType.field_holds("F32", PgType.values("integer"), "integer")
expect PgType.field_holds("F64", PgType.values("real"), "real")
expect !PgType.field_holds("F32", PgType.values("double precision"), "double precision")
expect !PgType.field_holds("F64", PgType.values("numeric"), "numeric")
expect PgType.field_holds("Str", PgType.values("bigint"), "bigint")
expect !PgType.field_holds("I32", PgType.values("text"), "text")
expect PgType.field_holds("I32", PgType.values("access_level"), "access_level")
expect PgType.field_holds("List(I64)", PgType.values("integer[]"), "integer[]")
expect !PgType.field_holds("List(I32)", PgType.values("bigint[]"), "bigint[]")
expect !PgType.field_holds("I32", PgType.values("integer[]"), "integer[]")
expect !PgType.field_holds("List(I32)", PgType.values("integer"), "integer")

expect PgType.column_holds("integer", PgType.values("integer"), "I32")
expect PgType.column_holds("bigint", PgType.values("bigint"), "I32")
expect !PgType.column_holds("smallint", PgType.values("smallint"), "I32")
expect PgType.column_holds("smallint", PgType.values("smallint"), "U8")
expect !PgType.column_holds("u8", Integers(0, 255), "I16")
expect PgType.column_holds("u8", Integers(0, 255), "U8")
expect !PgType.column_holds("bigint", PgType.values("bigint"), "U64")
expect PgType.column_holds("numeric", PgType.values("numeric"), "U64")
expect PgType.column_holds("numeric", PgType.values("numeric"), "Dec")
expect !PgType.column_holds("double precision", PgType.values("double precision"), "Dec")
expect PgType.column_holds("double precision", PgType.values("double precision"), "I32")
expect !PgType.column_holds("double precision", PgType.values("double precision"), "I64")
expect !PgType.column_holds("text", PgType.values("text"), "I32")
expect PgType.column_holds("text", PgType.values("text"), "Str")
expect PgType.column_holds("integer[]", PgType.values("integer[]"), "List(I16)")
expect PgType.from_oid(23) == Ok("integer")
