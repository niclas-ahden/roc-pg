## A query whose parameters are interpolated [Hole] values.
## An experiment next to [Sql] and [Interpolated]: values of different
## types can share a query, at the cost of checking them only when it runs.
##
## ```
## planets = db.query_tagged!("select id, name from planets where age > ${5} and name <> ${Text(name)}")?
## ```
##
## The SQL, the tables and columns it names and the row type are checked
## when you build, as for [Sql]. The interpolations are not. Every one is
## a [Hole] by then, whatever its tag, so the build cannot tell an `I32`
## from a `Text`. The server checks them when the query runs.
import RowFormat
import Param
import Hole
import Holes

Tagged(schema, row) :: { text : Str, params : List(Str), unverified : List(Str), fields : List(RowFormat.Field), values : List((Str, Param.Param)) }.{
	## A query without interpolations, checked like one with them.
	from_quote : Str -> Try(Tagged(schema, row), [BadQuotedBytes(Str)])
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
			Ok({ text, params, unverified }) => Ok(Tagged.{ text, params, unverified, fields: row_fields, values: [] })
			Err(message) => Err(BadQuotedBytes(Holes.message(message, [])))
		}
	}

	from_interpolation : List(Str) -> Try((List(Hole) -> Tagged(schema, row)), [InvalidInterpolation(Str)])
		where [
			schema.catalog : {} -> catalog,
			catalog.check : catalog, Str, List(RowFormat.Field), List(RowFormat.Field) -> Try({ text : Str, params : List(Str), unverified : List(Str) }, Str),
			row.parser_for : RowFormat -> (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)),
		]
	from_interpolation = |segments| {
		Schema : schema
		Row : row
		row_fields = RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) ? |_| InvalidInterpolation("a field of the row type is a record, which a result row cannot fill")
		names = Holes.names(segments)
		# An empty kind fits any column, as nothing is known of a hole's type.
		holes = names.map(|name| { name, kind: "", nullable: Bool.False })
		match Schema.catalog({}).check(Holes.sql(segments), holes, row_fields) {
			Ok({ text, params, unverified }) =>
				Ok(|values| Tagged.{ text, params, unverified, fields: row_fields, values: values.map_with_index(|value, index| (Holes.name(index), value.to_param())) })
			Err(message) => Err(InvalidInterpolation(Holes.message(message, names)))
		}
	}

	## The SQL as it goes to the server, with `$1`, `$2`, ... in place of the
	## interpolations.
	text : Tagged(schema, row) -> Str
	text = |sql| sql.text

	## The placeholder names of the interpolations, in the order of `$1`,
	## `$2`, ...
	params : Tagged(schema, row) -> List(Str)
	params = |sql| sql.params

	## The fields of the row type whose column type the build could not see.
	unverified : Tagged(schema, row) -> List(Str)
	unverified = |sql| sql.unverified

	## The fields of the row type as `from_interpolation` read them.
	fields : Tagged(schema, row) -> List(RowFormat.Field)
	fields = |sql| sql.fields

	## The interpolated values as parameters, by placeholder name.
	values : Tagged(schema, row) -> List((Str, Param.Param))
	values = |sql| sql.values
}
