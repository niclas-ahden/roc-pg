## A query whose parameters are interpolated values, checked when you
## build. An experiment next to [Sql]: the values go where they are used
## instead of in a record.
##
## ```
## planets = db.query_interpolated!("select id, name from planets where age > ${min_age}")?
## ```
##
## The compiler calls `from_interpolation` with the text around the
## interpolations and gives it one type for every interpolated value, the
## `item` below. So the values of one query must all have the same type,
## and that type is what each of them is checked against. A number literal
## whose type nothing else decides is a `Dec` by then, so `${5}` next to an
## `integer` column fails where `${5.I32}` does not.
import RowFormat
import ParamFormat
import Param
import Holes

Interpolated(schema, row) :: { text : Str, params : List(Str), unverified : List(Str), fields : List(RowFormat.Field), values : List((Str, Param.Param)) }.{
	## A query without interpolations, checked like one with them.
	from_quote : Str -> Try(Interpolated(schema, row), [BadQuotedBytes(Str)])
		where [
			schema.catalog : {} -> catalog,
			catalog.check : catalog, Str, List(RowFormat.Field), List(RowFormat.Field) -> Try({ text : Str, params : List(Str), unverified : List(Str) }, Str),
			row.parser_for : RowFormat -> (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)),
		]
	from_quote = |raw| {
		Schema : schema
		Row : row
		row_fields = RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) ? |_| BadQuotedBytes("a field of the row type is a record, which a result row cannot fill")
		match Schema.catalog({}).check(raw, [], row_fields) {
			Ok({ text, params, unverified }) => Ok(Interpolated.{ text, params, unverified, fields: row_fields, values: [] })
			Err(message) => Err(BadQuotedBytes(Holes.message(message, [])))
		}
	}

	from_interpolation : List(Str) -> Try((List(item) -> Interpolated(schema, row)), [InvalidInterpolation(Str)])
		where [
			schema.catalog : {} -> catalog,
			catalog.check : catalog, Str, List(RowFormat.Field), List(RowFormat.Field) -> Try({ text : Str, params : List(Str), unverified : List(Str) }, Str),
			item.parser_for : RowFormat -> (RowFormat.State -> Try({ value : item, rest : RowFormat.State }, RowFormat.Err)),
			item.encoder_for : ParamFormat -> (item, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)),
			row.parser_for : RowFormat -> (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)),
		]
	from_interpolation = |segments| {
		Schema : schema
		Item : item
		Row : row
		hole = RowFormat.value_shape(Item.parser_for(RowFormat.Nulls), Item.parser_for(RowFormat.Kinds)) ? |_| InvalidInterpolation("an interpolated value is a record, which is no parameter")
		row_fields = RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) ? |_| InvalidInterpolation("a field of the row type is a record, which a result row cannot fill")
		names = Holes.names(segments)
		match Schema.catalog({}).check(Holes.sql(segments), names.map(|name| { ..hole, name }), row_fields) {
			Ok({ text, params, unverified }) =>
				Ok(
					|values| {
						encode = Item.encoder_for(ParamFormat.Text)
						named = values.map_with_index(
							|value, index|
								match ParamFormat.encode_value(value, encode) {
									Ok(param) => (Holes.name(index), param)
									Err(_) => crash "roc-pg-insane-in-the-membrane: an interpolated value is a record, which `Interpolated.from_interpolation` should have refused"
								},
						)
						Interpolated.{ text, params, unverified, fields: row_fields, values: named }
					},
				)
			Err(message) => Err(InvalidInterpolation(Holes.message(message, names)))
		}
	}

	## The SQL as it goes to the server, with `$1`, `$2`, ... in place of the
	## interpolations.
	text : Interpolated(schema, row) -> Str
	text = |sql| sql.text

	## The placeholder names of the interpolations, in the order of `$1`,
	## `$2`, ...
	params : Interpolated(schema, row) -> List(Str)
	params = |sql| sql.params

	## The fields of the row type whose column type the build could not see.
	unverified : Interpolated(schema, row) -> List(Str)
	unverified = |sql| sql.unverified

	## The fields of the row type as `from_interpolation` read them.
	fields : Interpolated(schema, row) -> List(RowFormat.Field)
	fields = |sql| sql.fields

	## The interpolated values as parameters, by placeholder name.
	values : Interpolated(schema, row) -> List((Str, Param.Param))
	values = |sql| sql.values
}
