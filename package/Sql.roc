## A query that is checked when you build.
##
## You don't create a `Sql` yourself. Write the query as a string literal
## where one is expected, such as the first argument of `Client.query!`,
## and the compiler checks it. A problem with the query is a compile error
## pointing at the literal.
##
## `roc check` and `roc build` check that:
##
## - the SQL is a single statement that Postgres accepts, using Postgres's
##   own grammar and error messages
## - every table and column exists in the schema, and an unqualified column
##   is not ambiguous
## - parameters are written `$name` (not `$1`), every placeholder is a field
##   of the parameter record, and every field is used
## - a parameter fits the type Postgres gives it: next to a column
##   (`col = $name`, `set col = $name`, an inserted value), in a function
##   or operator call, or in a cast, and one that can be NULL doesn't go
##   into a `NOT NULL` column
## - an insert gives a value for every column it names and every `NOT NULL`
##   column without a default, and inserted and assigned values fit their
##   columns
## - every function and operator call matches a function or operator
## - a query that groups reads only grouped columns outside aggregates
## - every field of the row type is a column the query returns, with a
##   matching type, and a column that can be NULL has a `Try(T, [Null])`
##   field
##
## A misspelled table, column, parameter or field gets a "did you mean"
## hint.
##
## `schema` is the schema the query is checked against (see [Catalog]),
## `params` is the record of parameters, and `row` is the record type each
## row decodes into.
import RowFormat

Sql(schema, params, row) :: { text : Str, params : List(Str), unverified : List(Str) }.{
	## The compiler calls this with the string literal. It reaches the
	## checker through `schema`'s catalog, a [Catalog], whose `check` does
	## the work. So a query run without being checked, or code that only
	## passes a `Sql` along, never pulls the parser into the build.
	from_quote : Str -> Try(Sql(schema, params, row), [BadQuotedBytes(Str)])
		where [
			schema.catalog : {} -> catalog,
			catalog.check : catalog, Str, List(RowFormat.Field), List(RowFormat.Field) -> Try({ text : Str, params : List(Str), unverified : List(Str) }, Str),
			params.parser_for : RowFormat -> (RowFormat.State -> Try({ value : params, rest : RowFormat.State }, RowFormat.Err)),
			row.parser_for : RowFormat -> (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)),
		]
	from_quote = |raw| {
		Schema : schema
		Params : params
		Row : row
		param_fields = RowFormat.shape(Params.parser_for(RowFormat.Nulls), Params.parser_for(RowFormat.Kinds)) ? |_| BadQuotedBytes("a field of the parameter record is a record, which is no parameter")
		row_fields = RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) ? |_| BadQuotedBytes("a field of the row type is a record, which a result row cannot fill")
		match Schema.catalog({}).check(raw, param_fields, row_fields) {
			Ok({ text, params: names, unverified }) => Ok(Sql.{ text, params: names, unverified })
			Err(message) => Err(BadQuotedBytes(message))
		}
	}

	## The SQL as it goes to the server, with `$1`, `$2`, ... in place of the
	## names.
	text : Sql(schema, params, row) -> Str
	text = |sql| sql.text

	## The parameter names, in the order of `$1`, `$2`, ...
	params : Sql(schema, params, row) -> List(Str)
	params = |sql| sql.params

	## The fields of the row type whose column type the build could not see,
	## which the query's result description is checked against when it runs.
	unverified : Sql(schema, params, row) -> List(Str)
	unverified = |sql| sql.unverified
}

