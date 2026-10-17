## A value bound to a `$n` placeholder of a [Statement] or of SQL built at
## runtime, such as with `Client.query_unchecked!`: SQL NULL, a text value,
## raw bytes, or an array of such values. Checked queries take a record of
## parameters instead.
##
## ```
## client.query_unchecked!(
##     "select name from people where age > $1 and team = any($2)",
##     [Param.u8(18), Param.list([Param.str("red"), Param.str("blue")])],
##     |row| row.str("name"),
## )?
## ```
##
## Numbers, bools, strings and arrays go in Postgres text format, so the
## server infers each parameter's type from where its `$n` appears: an enum
## column takes its label as `Param.str`, an `int[]` column takes
## `Param.list(ids.map(Param.i32))`. Only `bytes` goes in binary format.
import Numeric

Param :: [NullParam, Text(Str), Binary(List(U8)), TextArray(Str)].{

	null : Param
	null = NullParam

	str : Str -> Param
	str = |value| Text(value)

	## Sent in binary format, so no escaping is needed. Inside a [Param.list]
	## it takes the text form instead (`\x` followed by hex).
	bytes : List(U8) -> Param
	bytes = |value| Binary(value)

	bool : Bool -> Param
	bool = |value| if value Text("t") else Text("f")

	u8 : U8 -> Param
	u8 = |value| Text(value.to_str())

	u16 : U16 -> Param
	u16 = |value| Text(value.to_str())

	u32 : U32 -> Param
	u32 = |value| Text(value.to_str())

	u64 : U64 -> Param
	u64 = |value| Text(value.to_str())

	i8 : I8 -> Param
	i8 = |value| Text(value.to_str())

	i16 : I16 -> Param
	i16 = |value| Text(value.to_str())

	i32 : I32 -> Param
	i32 = |value| Text(value.to_str())

	i64 : I64 -> Param
	i64 = |value| Text(value.to_str())

	f32 : F32 -> Param
	f32 = |value| Text(value.to_str())

	f64 : F64 -> Param
	f64 = |value| Text(value.to_str())

	numeric : Numeric -> Param
	numeric = |value| Text(value.to_str())

	dec : Dec -> Param
	dec = |value| Text(value.to_str())

	## An array, sent as a Postgres array literal such as `{"a","b"}`. The
	## elements take the text form of their own `Param`, so
	## `Param.list(ids.map(Param.i32))` binds an `int[]` and a list of
	## `Param.str` binds a `text[]` or an enum array. Nest lists for a
	## multi-dimensional array. Every element is quoted, which Postgres
	## accepts for any element type, so no value needs special casing.
	list : List(Param) -> Param
	list = |elems| TextArray("{${Str.join_with(elems.map(element_literal), ",")}}")

	## The wire form of a statement's parameters: one format code and one
	## value per parameter (used by `Client.command!`).
	encode : List(Param) -> { format_codes : List([Text, Binary]), param_values : List([Null, Value(List(U8))]) }
	encode = |params| {
		format_codes = params.map(
			|param|
				match param {
					NullParam => Binary
					Binary(_) => Binary
					Text(_) => Text
					TextArray(_) => Text
				},
		)
		param_values = params.map(
			|param|
				match param {
					NullParam => Null
					Binary(value) => Value(value)
					Text(value) => Value(value.to_utf8())
					TextArray(literal) => Value(literal.to_utf8())
				},
		)
		{ format_codes, param_values }
	}
}

## One element of an array literal. Text is always double quoted, with `\`
## and `"` escaped by a backslash, which is valid for every element type.
## A nested array goes in unquoted, and NULL is the bare word.
element_literal : Param -> Str
element_literal = |param|
	match param {
		NullParam => "NULL"
		Text(value) => quote(value)
		Binary(value) => quote("\\x${hex(value)}")
		TextArray(literal) => literal
	}

quote : Str -> Str
quote = |value| {
	# 34 is `"` and 92 is `\`. Both are ASCII, so they never occur inside a
	# multi-byte UTF-8 sequence.
	escaped = value.to_utf8().fold(
		[34],
		|acc, byte| if byte == 34 or byte == 92 acc.append(92).append(byte) else acc.append(byte),
	)
	Str.from_utf8_lossy(escaped.append(34))
}

hex : List(U8) -> Str
hex = |bytes| Str.from_utf8_lossy(bytes.fold([], |acc, byte| acc.append(hex_digit(byte // 16)).append(hex_digit(byte % 16))))

hex_digit : U8 -> U8
hex_digit = |n| if n < 10 48 + n else 87 + n

# The array literal is the Postgres text form: quoted elements, NULL bare,
# nested arrays unquoted. Checked through encode, whose output is structural.
literal_of = |param| Param.encode([param]).param_values

expect literal_of(Param.list([])) == [Value("{}".to_utf8())]
expect literal_of(Param.list([Param.i32(1), Param.i32(-2)])) == [Value("{\"1\",\"-2\"}".to_utf8())]
expect literal_of(Param.list([Param.str("a"), Param.null, Param.str("b,c")])) == [Value("{\"a\",NULL,\"b,c\"}".to_utf8())]
expect literal_of(Param.list([Param.str("say \"hi\""), Param.str("back\\slash")])) == [Value("{\"say \\\"hi\\\"\",\"back\\\\slash\"}".to_utf8())]
expect literal_of(Param.list([Param.list([Param.i32(1)]), Param.list([Param.i32(2)])])) == [Value("{{\"1\"},{\"2\"}}".to_utf8())]
expect literal_of(Param.list([Param.bytes([1, 255])])) == [Value("{\"\\\\x01ff\"}".to_utf8())]
expect literal_of(Param.list([Param.bool(Bool.True), Param.dec(1.5)])) == [Value("{\"t\",\"1.5\"}".to_utf8())]

# Text goes in text format, bytes in binary, and NULL has no value.
expect Param.encode([Param.str("x"), Param.bytes([7]), Param.null]) == { format_codes: [Text, Binary, Binary], param_values: [Value([120]), Value([7]), Null] }
