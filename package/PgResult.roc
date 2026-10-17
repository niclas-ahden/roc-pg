## The result of a Postgres command: row descriptions plus raw row data,
## with by-name accessors for decoding.
##
## ```
## result = client.command!(stmt)?
## users = PgResult.decode(result, |row| {
##     name = row.str("name")?
##     age = row.u8("age")?
##     Ok({ name, age })
## })?
## ```
##
## `client.query_unchecked!` and the other query functions run and decode
## in one call.
import Numeric

PgResult :: {
	columns : List(Str),
	raw_rows : List(List([Null, Present(List(U8))])),
	command_tag : Str,
}.{

	## One result row. Decode columns by name with the accessors below. When
	## several columns share a name, as `select *` over a join can give, the
	## name reads the first of them. Rename the others with `as` to read them.
	Row :: {
		columns : List(Str),
		values : List([Null, Present(List(U8))]),
	}.{

		## The raw column value: `Null`, or `Present(bytes)`.
		raw : Row, Str -> Try([Null, Present(List(U8))], [FieldNotFound(Str)])
		raw = |row, name|
			match row.columns.find_first_index(|column| column == name) {
				Ok(index) =>
					match row.values.get(index) {
						Ok(value) => Ok(value)
						Err(_) => Err(FieldNotFound(name))
					}
				Err(_) => Err(FieldNotFound(name))
			}

		## The column value as a string. Fails on NULL.
		str : Row, Str -> Try(Str, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str)])
		str = |row, name|
			match Row.raw(row, name)? {
				Null => Err(UnexpectedNull(name))
				Present(bytes) =>
					match Str.from_utf8(bytes) {
						Ok(value) => Ok(value)
						Err(_) => Err(BadUtf8(name))
					}
				}

		## The column value as a string, or `Null`.
		str_nullable : Row, Str -> Try([Null, Present(Str)], [FieldNotFound(Str), BadUtf8(Str)])
		str_nullable = |row, name|
			match Row.raw(row, name)? {
				Null => Ok(Null)
				Present(bytes) =>
					match Str.from_utf8(bytes) {
						Ok(value) => Ok(Present(value))
						Err(_) => Err(BadUtf8(name))
					}
				}

		## A `bytea` column as the bytes it holds, the ones [Param.bytes] sends.
		## Postgres sends `bytea` as text, `\x` and two hex digits per byte (its
		## default `bytea_output`), and this decodes that. Fails on NULL, and with
		## `InvalidBytea(name)` on anything else, like the older `escape` output.
		## [PgResult.Row.raw] gives the text as it arrived.
		bytes : Row, Str -> Try(List(U8), [FieldNotFound(Str), UnexpectedNull(Str), InvalidBytea(Str)])
		bytes = |row, name|
			match Row.raw(row, name)? {
				Null => Err(UnexpectedNull(name))
				Present(text) => decode_bytea(text).map_err(|_| InvalidBytea(name))
			}

		## Like [PgResult.Row.bytes], or `Null`.
		bytes_nullable : Row, Str -> Try([Null, Present(List(U8))], [FieldNotFound(Str), InvalidBytea(Str)])
		bytes_nullable = |row, name|
			match Row.raw(row, name)? {
				Null => Ok(Null)
				Present(text) =>
					match decode_bytea(text) {
						Ok(value) => Ok(Present(value))
						Err(_) => Err(InvalidBytea(name))
					}
				}

		## The column value as a bool (postgres text format: `t`/`f`).
		bool : Row, Str -> Try(Bool, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidBool(Str)])
		bool = |row, name| {
			text = Row.str(row, name)?
			if text == "t" {
				Ok(Bool.True)
			} else if text == "f" {
				Ok(Bool.False)
			} else {
				Err(InvalidBool(name))
			}
		}

		u8 : Row, Str -> Try(U8, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u8 = |row, name| U8.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u16 : Row, Str -> Try(U16, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u16 = |row, name| U16.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u32 : Row, Str -> Try(U32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u32 = |row, name| U32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u64 : Row, Str -> Try(U64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u64 = |row, name| U64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i8 : Row, Str -> Try(I8, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i8 = |row, name| I8.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i16 : Row, Str -> Try(I16, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i16 = |row, name| I16.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i32 : Row, Str -> Try(I32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i32 = |row, name| I32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i64 : Row, Str -> Try(I64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i64 = |row, name| I64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		f32 : Row, Str -> Try(F32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		f32 = |row, name| F32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		f64 : Row, Str -> Try(F64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		f64 = |row, name| F64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		dec : Row, Str -> Try(Dec, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		dec = |row, name| dec_text(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		## An exact [Numeric], for a `numeric` value with more digits than a
		## [Dec] holds.
		numeric : Row, Str -> Try(Numeric, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str)])
		numeric = |row, name| Numeric.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u8_nullable : Row, Str -> Try([Null, Present(U8)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u8_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U8.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u16_nullable : Row, Str -> Try([Null, Present(U16)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u16_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U16.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u32_nullable : Row, Str -> Try([Null, Present(U32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u64_nullable : Row, Str -> Try([Null, Present(U64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		u64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i8_nullable : Row, Str -> Try([Null, Present(I8)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i8_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I8.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i16_nullable : Row, Str -> Try([Null, Present(I16)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i16_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I16.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i32_nullable : Row, Str -> Try([Null, Present(I32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i64_nullable : Row, Str -> Try([Null, Present(I64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		i64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		f32_nullable : Row, Str -> Try([Null, Present(F32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		f32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => F32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		f64_nullable : Row, Str -> Try([Null, Present(F64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		f64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => F64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		dec_nullable : Row, Str -> Try([Null, Present(Dec)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		dec_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => dec_text(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		numeric_nullable : Row, Str -> Try([Null, Present(Numeric)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str)])
		numeric_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => Numeric.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		## The column value as a bool (postgres text format), or `Null`.
		bool_nullable : Row, Str -> Try([Null, Present(Bool)], [FieldNotFound(Str), BadUtf8(Str), InvalidBool(Str)])
		bool_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) =>
					if text == "t" {
						Ok(Present(Bool.True))
					} else if text == "f" {
						Ok(Present(Bool.False))
					} else {
						Err(InvalidBool(name))
					}
				}

		## The column value as a one-dimensional array (`text[]`, `int[]`, an
		## enum array, ...), each element decoded from its text form by
		## `decode_elem`. A NULL element fails with `NullElement(name)`, a
		## NULL column with `UnexpectedNull(name)`, and anything that is not
		## the text form of a one-dimensional array with `InvalidArray(name)`.
		##
		## ```
		## ids = row.list("ids", |text| I32.from_str(text).map_err(|_| BadId(text)))?
		## ```
		list : Row, Str, (Str -> Try(a, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidArray(Str), NullElement(Str), ..others])) -> Try(List(a), [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidArray(Str), NullElement(Str), ..others])
		list = |row, name, decode_elem|
			match Row.str(row, name) {
				Err(FieldNotFound(n)) => Err(FieldNotFound(n))
				Err(UnexpectedNull(n)) => Err(UnexpectedNull(n))
				Err(BadUtf8(n)) => Err(BadUtf8(n))
				Ok(text) =>
					match parse_array(text) {
						Err(InvalidArray) => Err(InvalidArray(name))
						Ok(elems) => decode_elems(elems, decode_elem, name, [])
					}
			}

		## The column value as an array of strings: `text[]`, `varchar[]`, or
		## an enum array, whose labels arrive as strings.
		str_list : Row, Str -> Try(List(Str), [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidArray(Str), NullElement(Str)])
		str_list = |row, name| Row.list(row, name, |text| Ok(text))

		i32_list : Row, Str -> Try(List(I32), [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidArray(Str), NullElement(Str), InvalidNumStr(Str)])
		i32_list = |row, name| Row.list(row, name, |text| I32.from_str(text).map_err(|_| InvalidNumStr(name)))

		i64_list : Row, Str -> Try(List(I64), [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidArray(Str), NullElement(Str), InvalidNumStr(Str)])
		i64_list = |row, name| Row.list(row, name, |text| I64.from_str(text).map_err(|_| InvalidNumStr(name)))
	}

	## Build a result by hand: the column names, each row's values as
	## [PgResult.Row.raw] gives them (Postgres text format), and the command
	## tag. `Client.command!` builds its results with it, and a test can use
	## it to check a row decoder without a server.
	##
	## ```
	## result = PgResult.new(["id", "name"], [[Present("7".to_utf8()), Null]], "SELECT 1")
	## ```
	new : List(Str), List(List([Null, Present(List(U8))])), Str -> PgResult
	new = |columns, raw_rows, command_tag| { columns, raw_rows, command_tag }

	## The rows as the server sent them: `Null` or the text of each value, in
	## column order. Checked queries decode them with their row type.
	rows : PgResult -> List(List([Null, Present(List(U8))]))
	rows = |result| result.raw_rows

	## The elements of a one-dimensional array in Postgres text form, such as
	## `{a,"b c",NULL}`.
	array_elements : Str -> Try(List([Null, Present(Str)]), [InvalidArray])
	array_elements = |text| parse_array(text)

	## A `numeric` value in Postgres text form as a [Dec]. Digits past the
	## 18th after the point are rounded off, half away from zero, as
	## `round(x, 18)` would. Fails on `NaN`, the infinities and a value too
	## large for a Dec.
	dec_from_text : Str -> Try(Dec, [InvalidNumStr])
	dec_from_text = |text| dec_text(text)

	## How many rows the command returned.
	len : PgResult -> U64
	len = |result| result.raw_rows.len()

	## The tag the server completed the command with, such as `INSERT 0 1`,
	## `UPDATE 3` or `COMMIT`. Empty for an empty query.
	command_tag : PgResult -> Str
	command_tag = |result| result.command_tag

	## How many rows the command inserted, updated, deleted, merged, copied or
	## returned, read from the last word of its [PgResult.command_tag]. Zero
	## for a command that reports no count, such as `create table` or `set`.
	rows_affected : PgResult -> U64
	rows_affected = |result|
		match result.command_tag.split_on(" ").last() {
			Ok(word) => U64.from_str(word) ?? 0
			Err(_) => 0
		}

	## The column names of the result.
	field_names : PgResult -> List(Str)
	field_names = |result| result.columns

	## Decode every row with the given row decoder.
	decode : PgResult, (Row -> Try(a, err)) -> Try(List(a), err)
	decode = |result, decode_row| decode_rows_help(result.columns, result.raw_rows, decode_row, [])

	## Decode the one row of a result. `EmptyResult` when there is none, and
	## `MultipleRows(n)` when there are more: a query meant to return one row
	## that returns several is a bug worth catching, not a row to pick.
	decode_one : PgResult, (Row -> Try(a, [EmptyResult, MultipleRows(U64), ..others])) -> Try(a, [EmptyResult, MultipleRows(U64), ..others])
	decode_one = |result, decode_row|
		match result.raw_rows {
			[] => Err(EmptyResult)
			[values] => decode_row({ columns: result.columns, values })
			_ => Err(MultipleRows(result.raw_rows.len()))
		}

	## Decode the row of a result that has at most one: `Ok(Ok(row))` for one
	## row, `Ok(Err(NotFound))` for none, and `MultipleRows(n)` for more.
	decode_optional : PgResult, (Row -> Try(a, [MultipleRows(U64), ..others])) -> Try(Try(a, [NotFound]), [MultipleRows(U64), ..others])
	decode_optional = |result, decode_row|
		match result.raw_rows {
			[] => Ok(Err(NotFound))
			[values] =>
				match decode_row({ columns: result.columns, values }) {
					Ok(value) => Ok(Ok(value))
					Err(err) => Err(err)
				}
			_ => Err(MultipleRows(result.raw_rows.len()))
		}
}

decode_rows_help = |columns, raw_rows, decode_row, decoded|
	match raw_rows.first() {
		Err(_) => Ok(decoded)
		Ok(values) => {
			value = decode_row({ columns, values })?
			decode_rows_help(columns, raw_rows.drop_first(1), decode_row, decoded.append(value))
		}
	}

decode_elems = |elems, decode_elem, name, decoded|
	match elems.first() {
		Err(_) => Ok(decoded)
		Ok(Null) => Err(NullElement(name))
		Ok(Present(text)) => {
			value = decode_elem(text)?
			decode_elems(elems.drop_first(1), decode_elem, name, decoded.append(value))
		}
	}

# ---- Postgres bytea text format ----

## The bytes of a `bytea` value in Postgres's hex text format: `\x` (92, 120)
## and two hex digits per byte.
decode_bytea : List(U8) -> Try(List(U8), [InvalidBytea])
decode_bytea = |text|
	match text {
		[92, 120, .. as digits] => hex_pairs(digits, List.with_capacity(digits.len() // 2))
		_ => Err(InvalidBytea)
	}

hex_pairs : List(U8), List(U8) -> Try(List(U8), [InvalidBytea])
hex_pairs = |digits, decoded|
	match digits {
		[] => Ok(decoded)
		[high, low, .. as rest] => hex_pairs(rest, decoded.append(hex_value(high)? * 16 + hex_value(low)?))
		_ => Err(InvalidBytea)
	}

hex_value : U8 -> Try(U8, [InvalidBytea])
hex_value = |digit|
	if digit >= 48 and digit <= 57 {
		Ok(digit - 48)
	} else if digit >= 97 and digit <= 102 {
		Ok(digit - 87)
	} else if digit >= 65 and digit <= 70 {
		Ok(digit - 55)
	} else {
		Err(InvalidBytea)
	}

expect decode_bytea("\\x726177".to_utf8()) == Ok("raw".to_utf8())
expect decode_bytea("\\x00FFa0".to_utf8()) == Ok([0, 255, 160])
expect decode_bytea("\\x".to_utf8()) == Ok([])
# An odd number of digits, a digit that is not hex, and the escape format.
expect decode_bytea("\\x7".to_utf8()) == Err(InvalidBytea)
expect decode_bytea("\\x7g".to_utf8()) == Err(InvalidBytea)
expect decode_bytea("raw".to_utf8()) == Err(InvalidBytea)

# ---- Postgres array text format ----
#
# `{a,"b c",NULL}`: elements separated by commas inside braces, quoted when
# they contain a delimiter, a brace, a quote, a backslash or whitespace, or
# spell NULL, or are empty. Inside quotes a backslash escapes the next byte.
# An unquoted NULL is a null element. The braces may be preceded by an
# explicit dimension such as `[0:2]=` when the lower bound is not 1.

## Parse the text form of a one-dimensional array into its elements.
parse_array : Str -> Try(List([Null, Present(Str)]), [InvalidArray])
parse_array = |text| {
	bytes = text.to_utf8()
	body =
		match bytes.first() {
			# 91 is `[`: skip the dimension prefix through its `=` (61).
			Ok(91) =>
				match bytes.find_first_index(|b| b == 61) {
					Ok(index) => Ok(bytes.drop_first(index + 1))
					Err(_) => Err(InvalidArray)
				}
			_ => Ok(bytes)
		}?
	match body.first() {
		# 123 is `{`.
		Ok(123) => parse_elements(body.drop_first(1), [])
		_ => Err(InvalidArray)
	}
}

## After `{` or a `,`: one element, or the closing `}` of an empty array.
parse_elements = |bytes, elems|
	match bytes.first() {
		# 125 is `}`, which must be the last byte.
		Ok(125) => if bytes.len() == 1 Ok(elems) else Err(InvalidArray)
		# 34 is `"`: a quoted element.
		Ok(34) => {
			{ value, rest } = parse_quoted(bytes.drop_first(1), [])?
			after_element(rest, elems.append(Present(Str.from_utf8_lossy(value))))
		}
		# 123 is `{`: a nested array, which this decoder does not read.
		Ok(123) => Err(InvalidArray)
		# Anything else is unquoted and runs to the next `,` (44) or `}`.
		Ok(_) => {
			end = bytes.find_first_index(|b| b == 44 or b == 125) ? |_| InvalidArray
			raw = bytes.take_first(end)
			elem = if raw == "NULL".to_utf8() Null else Present(Str.from_utf8_lossy(raw))
			after_element(bytes.drop_first(end), elems.append(elem))
		}
		Err(_) => Err(InvalidArray)
	}

## After an element: a `,` and another element, or the closing `}`.
after_element = |bytes, elems|
	match bytes.first() {
		Ok(44) => parse_elements(bytes.drop_first(1), elems)
		Ok(125) => if bytes.len() == 1 Ok(elems) else Err(InvalidArray)
		_ => Err(InvalidArray)
	}

## Inside quotes, up to the closing quote. A backslash (92) escapes one byte.
parse_quoted = |bytes, acc|
	match bytes.first() {
		Ok(34) => Ok({ value: acc, rest: bytes.drop_first(1) })
		Ok(92) =>
			match bytes.get(1) {
				Ok(escaped) => parse_quoted(bytes.drop_first(2), acc.append(escaped))
				Err(_) => Err(InvalidArray)
			}
		Ok(byte) => parse_quoted(bytes.drop_first(1), acc.append(byte))
		Err(_) => Err(InvalidArray)
	}

expect parse_array("{}") == Ok([])
expect parse_array("{1,2}") == Ok([Present("1"), Present("2")])
expect parse_array("{red,NULL,blue}") == Ok([Present("red"), Null, Present("blue")])
expect parse_array("{\"a b\",\"say \\\"hi\\\"\",\"back\\\\slash\",\"NULL\",\"\"}") == Ok([Present("a b"), Present("say \"hi\""), Present("back\\slash"), Present("NULL"), Present("")])
expect parse_array("[0:1]={x,y}") == Ok([Present("x"), Present("y")])
expect parse_array("{{1},{2}}") == Err(InvalidArray)
expect parse_array("{1,2") == Err(InvalidArray)
expect parse_array("nope") == Err(InvalidArray)

# decode_one accepts exactly one row.
one_row = PgResult.new(["n"], [[Present("7".to_utf8())]], "SELECT 1")
expect PgResult.decode_one(one_row, |row| row.i32("n")) == Ok(7)
expect PgResult.decode_one(PgResult.new([], [], "SELECT 0"), |row| row.i32("n")) == Err(EmptyResult)
expect PgResult.decode_one(PgResult.new([], [[], []], "SELECT 2"), |row| row.i32("n")) == Err(MultipleRows(2))

# decode_optional tells none from one, and refuses more.
expect PgResult.decode_optional(one_row, |row| row.i32("n")) == Ok(Ok(7))
expect PgResult.decode_optional(PgResult.new([], [], "SELECT 0"), |row| row.i32("n")) == Ok(Err(NotFound))
expect PgResult.decode_optional(PgResult.new([], [[], []], "SELECT 2"), |row| row.i32("n")) == Err(MultipleRows(2))

# The count is the last word of the tag, and a tag without one counts zero.
rows_affected_of = |tag| PgResult.new([], [], tag).rows_affected()

expect rows_affected_of("INSERT 0 3") == 3
expect rows_affected_of("UPDATE 2") == 2
expect rows_affected_of("DELETE 0") == 0
expect rows_affected_of("SELECT 7") == 7
expect rows_affected_of("MERGE 1") == 1
expect rows_affected_of("CREATE TABLE") == 0
expect rows_affected_of("COMMIT") == 0
expect rows_affected_of("") == 0

## [PgResult.dec_from_text]. Postgres writes a numeric as an optional `-`,
## digits and an optional fraction, never with an exponent.
dec_text : Str -> Try(Dec, [InvalidNumStr])
dec_text = |text| {
	negative = text.starts_with("-")
	unsigned = if negative text.drop_prefix("-") else text
	{ before, after } = unsigned.split_first(".") ?? { before: unsigned, after: "" }
	int_digits = digits(before)?
	frac_digits = digits(after)?
	if int_digits.is_empty() and frac_digits.is_empty() {
		return Err(InvalidNumStr)
	}
	(whole, frac) =
		if frac_digits.len() > 18 and (frac_digits.get(18) ?? 0) >= 5 {
			round_up(int_digits, frac_digits.take_first(18))
		} else {
			(int_digits, frac_digits.take_first(18))
		}
	value = Dec.from_dec_digits((whole, frac)) ? |_| InvalidNumStr
	Ok(if negative -value else value)
}

## The decimal digits of `text`, each 0 to 9. Fails on anything else.
digits : Str -> Try(List(U8), [InvalidNumStr])
digits = |text| {
	var $out = []
	for byte in text.to_utf8() {
		if byte < '0' or byte > '9' {
			return Err(InvalidNumStr)
		}
		$out = $out.append(byte - '0')
	}
	Ok($out)
}

## One more in the last fraction digit, carried as far left as it goes.
round_up : List(U8), List(U8) -> (List(U8), List(U8))
round_up = |whole, frac| {
	all = whole.concat(frac)
	var $out = []
	var $carry = Bool.True
	var $i = all.len()
	while $i > 0 {
		$i = $i - 1
		digit = all.get($i) ?? 0
		if $carry and digit == 9 {
			$out = $out.prepend(0)
		} else if $carry {
			$out = $out.prepend(digit + 1)
			$carry = Bool.False
		} else {
			$out = $out.prepend(digit)
		}
	}
	carried = if $carry $out.prepend(1) else $out
	split = carried.len() - frac.len()
	(carried.take_first(split), carried.drop_first(split))
}

expect dec_text("12.5") == Ok(12.5)
expect dec_text("-0.25") == Ok(-0.25)
expect dec_text("7") == Ok(7)
expect dec_text(".5") == Ok(0.5)
expect dec_text("0.1234567890123456789") == Ok(0.123456789012345679)
expect dec_text("0.1234567890123456784") == Ok(0.123456789012345678)
expect dec_text("-0.0000000000000000005") == Ok(-0.000000000000000001)
expect dec_text("9.9999999999999999999") == Ok(10)
expect dec_text("1.000000000000000000000000000000") == Ok(1)
expect dec_text("NaN") == Err(InvalidNumStr)
expect dec_text("Infinity") == Err(InvalidNumStr)
expect dec_text("-") == Err(InvalidNumStr)
expect dec_text("1e5") == Err(InvalidNumStr)
expect dec_text("99999999999999999999999999999") == Err(InvalidNumStr)
