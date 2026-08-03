## The result of a Postgres command: row descriptions plus raw row data,
## with by-name accessors for decoding.
##
## ```
## result = Client.command!(cmd, client)?
## users = PgResult.decode(result, |row| {
##     name = row.str("name")?
##     age = row.u8("age")?
##     Ok({ name, age })
## })?
## ```
import ProtoBackend

PgResult :: {
	fields : List(ProtoBackend.RowField),
	raw_rows : List(List([Null, Present(List(U8))])),
}.{

	## One result row; decode columns by name with the accessors below.
	Row :: {
		fields : List(ProtoBackend.RowField),
		values : List([Null, Present(List(U8))]),
	}.{

		## The raw column value: `Null`, or `Present(bytes)`.
		raw : Row, Str -> Try([Null, Present(List(U8))], [FieldNotFound(Str), ..])
		raw = |row, name|
			match row.fields.find_first_index(|f| f.name == name) {
				Ok(index) =>
					match row.values.get(index) {
						Ok(value) => Ok(value)
						Err(_) => Err(FieldNotFound(name))
					}
				Err(_) => Err(FieldNotFound(name))
			}

		## The column value as a string. Fails on NULL.
		str : Row, Str -> Try(Str, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), ..])
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
		str_nullable : Row, Str -> Try([Null, Present(Str)], [FieldNotFound(Str), BadUtf8(Str), ..])
		str_nullable = |row, name|
			match Row.raw(row, name)? {
				Null => Ok(Null)
				Present(bytes) =>
					match Str.from_utf8(bytes) {
						Ok(value) => Ok(Present(value))
						Err(_) => Err(BadUtf8(name))
					}
				}

		## The column value as raw bytes. Fails on NULL.
		bytes : Row, Str -> Try(List(U8), [FieldNotFound(Str), UnexpectedNull(Str), ..])
		bytes = |row, name|
			match Row.raw(row, name)? {
				Null => Err(UnexpectedNull(name))
				Present(value) => Ok(value)
			}

		## The column value as raw bytes, or `Null`.
		bytes_nullable : Row, Str -> Try([Null, Present(List(U8))], [FieldNotFound(Str), ..])
		bytes_nullable = |row, name|
			match Row.raw(row, name)? {
				Null => Ok(Null)
				Present(value) => Ok(Present(value))
			}

		## The column value as a bool (postgres text format: `t`/`f`).
		bool : Row, Str -> Try(Bool, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidBool(Str), ..])
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

		u8 : Row, Str -> Try(U8, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u8 = |row, name| U8.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u16 : Row, Str -> Try(U16, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u16 = |row, name| U16.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u32 : Row, Str -> Try(U32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u32 = |row, name| U32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u64 : Row, Str -> Try(U64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u64 = |row, name| U64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i8 : Row, Str -> Try(I8, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i8 = |row, name| I8.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i16 : Row, Str -> Try(I16, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i16 = |row, name| I16.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i32 : Row, Str -> Try(I32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i32 = |row, name| I32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		i64 : Row, Str -> Try(I64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i64 = |row, name| I64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		f32 : Row, Str -> Try(F32, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		f32 = |row, name| F32.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		f64 : Row, Str -> Try(F64, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		f64 = |row, name| F64.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		dec : Row, Str -> Try(Dec, [FieldNotFound(Str), UnexpectedNull(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		dec = |row, name| Dec.from_str(Row.str(row, name)?).map_err(|_| InvalidNumStr(name))

		u8_nullable : Row, Str -> Try([Null, Present(U8)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u8_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U8.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u16_nullable : Row, Str -> Try([Null, Present(U16)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u16_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U16.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u32_nullable : Row, Str -> Try([Null, Present(U32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		u64_nullable : Row, Str -> Try([Null, Present(U64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		u64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => U64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i8_nullable : Row, Str -> Try([Null, Present(I8)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i8_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I8.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i16_nullable : Row, Str -> Try([Null, Present(I16)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i16_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I16.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i32_nullable : Row, Str -> Try([Null, Present(I32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		i64_nullable : Row, Str -> Try([Null, Present(I64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		i64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => I64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		f32_nullable : Row, Str -> Try([Null, Present(F32)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		f32_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => F32.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		f64_nullable : Row, Str -> Try([Null, Present(F64)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		f64_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => F64.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		dec_nullable : Row, Str -> Try([Null, Present(Dec)], [FieldNotFound(Str), BadUtf8(Str), InvalidNumStr(Str), ..])
		dec_nullable = |row, name|
			match Row.str_nullable(row, name)? {
				Null => Ok(Null)
				Present(text) => Dec.from_str(text).map_ok(|v| Present(v)).map_err(|_| InvalidNumStr(name))
			}

		## The column value as a bool (postgres text format), or `Null`.
		bool_nullable : Row, Str -> Try([Null, Present(Bool)], [FieldNotFound(Str), BadUtf8(Str), InvalidBool(Str), ..])
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
	}

	## Build a result (used by `Client.command!`; apps normally never call this).
	new : List(ProtoBackend.RowField), List(List([Null, Present(List(U8))])) -> PgResult
	new = |fields, raw_rows| { fields, raw_rows }

	## How many rows the command returned.
	len : PgResult -> U64
	len = |result| result.raw_rows.len()

	## The column names of the result.
	field_names : PgResult -> List(Str)
	field_names = |result| result.fields.map(|f| f.name)

	## Decode every row with the given row decoder.
	decode : PgResult, (Row -> Try(a, err)) -> Try(List(a), err)
	decode = |result, decode_row| decode_rows_help(result.fields, result.raw_rows, decode_row, [])

	## Decode the single row of a result; `EmptyResult` if there are no rows.
	## Extra rows are ignored, use `Cmd.limit(cmd, 1)` to avoid fetching them.
	decode_one : PgResult, (Row -> Try(a, [EmptyResult, ..others])) -> Try(a, [EmptyResult, ..others])
	decode_one = |result, decode_row|
		match result.raw_rows.first() {
			Ok(values) => decode_row({ fields: result.fields, values })
			Err(_) => Err(EmptyResult)
		}
}

decode_rows_help = |fields, raw_rows, decode_row, decoded|
	match raw_rows.first() {
		Err(_) => Ok(decoded)
		Ok(values) => {
			value = decode_row({ fields, values })?
			decode_rows_help(fields, raw_rows.drop_first(1), decode_row, decoded.append(value))
		}
	}
