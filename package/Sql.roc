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
import Lex
import Parse
import Node
import RowFormat
import Catalog
import Check

Sql(schema, params, row) :: { text : Str, params : List(Str), unverified : List(Str) }.{
	from_quote : Str -> Try(Sql(schema, params, row), [BadQuotedBytes(Str)])
		where [
			schema.catalog : {} -> Catalog,
			params.parser_for : RowFormat -> (RowFormat.State -> Try({ value : params, rest : RowFormat.State }, RowFormat.Err)),
			row.parser_for : RowFormat -> (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)),
		]
	from_quote = |raw| {
		Schema : schema
		Params : params
		Row : row
		param_fields = RowFormat.shape(Params.parser_for(RowFormat.Nulls), Params.parser_for(RowFormat.Kinds)) ? |_| BadQuotedBytes("a field of the parameter record is a record, which is no parameter")
		row_fields = RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) ? |_| BadQuotedBytes("a field of the row type is a record, which a result row cannot fill")
		match check(raw, Schema.catalog({}), param_fields, row_fields) {
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

## Everything `from_quote` checks, as a plain function: the SQL against the
## catalog, the placeholders against the fields of the parameter record,
## and the result columns against the fields of the row type.
check : Str, Catalog, List(RowFormat.Field), List(RowFormat.Field) -> Try({ text : Str, params : List(Str), unverified : List(Str) }, Str)
check = |raw, catalog, param_fields, row_fields| {
	toks = Lex.tokens(raw) ? |err| Lex.err_to_str(raw, err)
	match toks.find_first(|t| is_positional(t.kind)) {
		Ok(tok) => return Err("use `$name` placeholders named after the fields of the parameter record, not `${Lex.token_text(raw, tok)}` (at ${Lex.position(raw, tok.start)})")
		Err(_) => {}
	}
	stmt = parse_one(raw, toks)?
	{ text, names } = Lex.number_placeholders(raw, toks)
	param_problem(names, param_fields.map(|f| f.name))?
	result = Check.analyze(stmt, catalog, param_fields, Lex.named_at(toks))
	match result.problems {
		[first, ..] => return Err(first)
		[] => {}
	}
	row_problem(result.outputs, row_fields, catalog)?
	unverified =
		match result.outputs {
			Known(outputs) => row_fields.keep_if(|f| outputs.any(|o| o.name == f.name and o.type == Unknown)).map(|f| f.name)
			Unknown => row_fields.map(|f| f.name)
		}
	Ok({ text, params: names, unverified })
}

## Run Postgres's grammar over `raw` and return the one statement's tree.
## The grammar sees [Lex.grammar_text], so a syntax error's cursor and every
## location in the tree still point into `raw`.
parse_one : Str, List(Lex.Token) -> Try(Node, Str)
parse_one = |raw, toks| {
	bytes = raw.to_utf8()
	match Parse.parse(Lex.grammar_text(raw, toks)) {
		Ok([stmt]) => Ok(stmt)
		Ok([]) => Ok(Node.Null)
		Ok(_) => Err("cannot insert multiple commands into a prepared statement")
		Err(problem) if problem.cursor == 0 => Err(problem.message)
		Err(problem) => Err("${problem.message} (${Lex.position(raw, Lex.cursor_offset(bytes, problem.cursor))})")
	}
}

## The first mismatch between the placeholders and the parameter record.
param_problem : List(Str), List(Str) -> Try({}, Str)
param_problem = |placeholders, fields| {
	for name in placeholders {
		if !fields.contains(name) {
			return Err("`$${name}` is not a field of the parameter record${Check.suggestion(name, fields)}")
		}
	}
	for name in fields {
		if !placeholders.contains(name) {
			return Err("the parameter record has a field `${name}`, but the query has no `$${name}`")
		}
	}
	Ok({})
}

## The first mismatch between the result columns and the row type's fields.
row_problem : [Known(List(Check.Output)), Unknown], List(RowFormat.Field), Catalog -> Try({}, Str)
row_problem = |analysis, fields, catalog|
	match analysis {
		Known(outputs) => {
			for field in fields {
				match outputs.keep_if(|o| o.name == field.name) {
					[] => {
						returned = if outputs.is_empty() "no columns" else Str.join_with(outputs.map(|o| "`${o.name}`"), ", ")
						return Err("the row has a field `${field.name}`, but the query returns no column by that name (it returns ${returned})${Check.suggestion(field.name, outputs.map(|o| o.name))}")
					}
					[output] => {
						match output.type {
							Known(type) if !Check.fits(catalog, type, field.kind) => return Err("column `${field.name}` is `${type}`, but its field is `${field.kind}`")
							_ => {}
						}
						if output.nullable == Yes and !field.nullable {
							return Err("column `${field.name}` can be NULL, so its field needs to be `Try(${field.kind}, [Null])`")
						}
					}
					_ => return Err("the query returns more than one column named `${field.name}`")
				}
			}
			Ok({})
		}
		Unknown => Ok({})
	}

is_positional : Lex.Kind -> Bool
is_positional = |kind|
	match kind {
		Positional(_) => Bool.True
		_ => Bool.False
	}

test_catalog : Catalog
test_catalog = Catalog.parse("CREATE TABLE public.students (id integer NOT NULL, name text NOT NULL, phone text, school_id integer NOT NULL);") ?? Catalog.none

field : Str, Str, Bool -> RowFormat.Field
field = |name, kind, nullable| { name, kind, nullable }

checked : Str, List(Str), List(RowFormat.Field) -> Try({ text : Str, params : List(Str) }, Str)
checked = |sql, param_names, fields| check(sql, test_catalog, param_names.map(|name| field(name, "Str", Bool.False)), fields).map_ok(|r| { text: r.text, params: r.params })

typed : Str, List(RowFormat.Field) -> Try({ text : Str, params : List(Str) }, Str)
typed = |sql, params| check(sql, test_catalog, params, []).map_ok(|r| { text: r.text, params: r.params })

expect checked("select id, name from students where school_id = $school_id and name <> $name", ["name", "school_id"], [field("id", "I32", Bool.False), field("name", "Str", Bool.False)]) == Ok({ text: "select id, name from students where school_id = $1 and name <> $2", params: ["school_id", "name"] })
expect checked("select id from students where id = $1", ["id"], [field("id", "I32", Bool.False)]) == Err("use `$name` placeholders named after the fields of the parameter record, not `$1` (at line 1, column 36)")
expect checked("select id from students where school_id = $schol_id", ["school_id"], []) == Err("`$schol_id` is not a field of the parameter record (did you mean `school_id`?)")
expect checked("select id from students where id = $id", ["id", "name"], []) == Err("the parameter record has a field `name`, but the query has no `$name`")
expect checked("select id from students", [], [field("id", "I32", Bool.False), field("email", "Str", Bool.False)]) == Err("the row has a field `email`, but the query returns no column by that name (it returns `id`)")
expect checked("select id, name from students", [], [field("nmae", "Str", Bool.False)]) == Err("the row has a field `nmae`, but the query returns no column by that name (it returns `id`, `name`) (did you mean `name`?)")
expect checked("select phone from students", [], [field("phone", "Str", Bool.False)]) == Err("column `phone` can be NULL, so its field needs to be `Try(Str, [Null])`")
expect checked("select phone from students", [], [field("phone", "Str", Bool.True)]) == Ok({ text: "select phone from students", params: [] })
expect checked("select count(*) as n from students", [], [field("n", "I32", Bool.False)]) == Err("column `n` is `bigint`, but its field is `I32`")
expect checked("select id from student", [], [field("id", "I32", Bool.False)]) == Err("table `student` does not exist in the schema (did you mean `students`?)")
expect checked("insert into students (id, name, school_id) values ($id, $name, $school_id)", ["id", "name", "school_id"], []) == Ok({ text: "insert into students (id, name, school_id) values ($1, $2, $3)", params: ["id", "name", "school_id"] })
expect checked("insert into students (id, name) values ($id, $name)", ["id", "name"], []) == Err("column `school_id` is NOT NULL and has no default, but the insert leaves it out")
expect checked("select 'oops", [], []) == Err("unterminated string constant at line 1, column 8")
expect checked("select id form students", [], []) == Err("syntax error at or near \"students\" (line 1, column 16)")
expect checked("select id from students where name = $a_long_name and", ["a_long_name"], []) == Err("syntax error at end of input (line 1, column 54)")
expect checked("select id from students where\n  name = $n ored", ["n"], []) == Err("syntax error at or near \"ored\" (line 2, column 13)")
expect checked("select 'é', id frm students", [], []) == Err("syntax error at or near \"students\" (line 1, column 21)")
expect checked("select id from students; select id from students", [], []) == Err("cannot insert multiple commands into a prepared statement")
expect checked("select id from students;", [], [field("id", "I32", Bool.False)]) == Ok({ text: "select id from students;", params: [] })
expect typed("select id from students where school_id = $school_id", [field("school_id", "Str", Bool.False)]) == Ok({ text: "select id from students where school_id = $1", params: ["school_id"] })
expect typed("select id from students where school_id = $school_id", [field("school_id", "Dec", Bool.False)]) == Err("column `school_id` is `integer`, but `$school_id` is `Dec`")
expect typed("select id from students r where $name = r.name", [field("name", "I32", Bool.False)]) == Err("column `name` is `text`, but `$name` is `I32`")
expect typed("select id from students where school_id = $o + 1", [field("o", "Dec", Bool.False)]) == Err("`$o` is `Dec`, but `+` takes `integer` there")
expect typed("select id from students where school_id = $o + 1", [field("o", "I32", Bool.False)]) == Ok({ text: "select id from students where school_id = $1 + 1", params: ["o"] })
expect typed("select id from students where school_id::text = $o", [field("o", "Bool", Bool.False)]) == Err("`$o` is `Bool`, but `=` takes `text` there")
expect typed("insert into students (id, name, phone, school_id) values ($id, $name, $phone, $school_id)", [field("id", "I32", Bool.False), field("name", "Str", Bool.True), field("phone", "Str", Bool.True), field("school_id", "I64", Bool.False)]) == Err("column `name` is NOT NULL, but `$name` is `Try(Str, [Null])`")
expect typed("update students set phone = $phone, name = $name where id = $id", [field("phone", "Str", Bool.True), field("name", "Bool", Bool.False), field("id", "I32", Bool.False)]) == Err("column `name` is `text`, but `$name` is `Bool`")
expect typed("update students set phone = $phone where id = $id", [field("phone", "Str", Bool.True), field("id", "I32", Bool.False)]) == Ok({ text: "update students set phone = $1 where id = $2", params: ["phone", "id"] })
expect typed("select id from students where id = any($ids)", [field("ids", "List(I32)", Bool.False)]) == Ok({ text: "select id from students where id = any($1)", params: ["ids"] })
expect typed("select id from students where id = any($ids)", [field("ids", "List(Bool)", Bool.False)]) == Err("column `id` is `integer`, so `$ids` must be a list of it, but it is `List(Bool)`")
expect typed("select id from students where id in ($a, $b)", [field("a", "I32", Bool.False), field("b", "Bool", Bool.False)]) == Err("column `id` is `integer`, but `$b` is `Bool`")
expect typed("select id from students where ($name::text is null or name = $name)", [field("name", "Str", Bool.True)]) == Ok({ text: "select id from students where ($1::text is null or name = $1)", params: ["name"] })
expect typed("select id from students where lower(name) = lower($n)", [field("n", "I32", Bool.False)]) == Err("`$n` is `I32`, but `lower` takes `text` there")
expect typed("select id from students where lower(name) = lower($n)", [field("n", "Str", Bool.False)]) == Ok({ text: "select id from students where lower(name) = lower($1)", params: ["n"] })
expect typed("select id from students where lower(name) = $n", [field("n", "Bool", Bool.False)]) == Err("`$n` is `Bool`, but `=` takes `text` there")
expect typed("select id from students where ($min::integer is null or id >= $min)", [field("min", "Dec", Bool.True)]) == Err("`$min` is `Dec`, but the cast takes `integer` there")
expect typed("select id from students where name = $id::text", [field("id", "I32", Bool.False)]) == Ok({ text: "select id from students where name = $1::text", params: ["id"] })
expect check("select id from students", Catalog.none, [], [field("id", "I32", Bool.False)]) == Ok({ text: "select id from students", params: [], unverified: ["id"] })
expect check("select id, name from students", test_catalog, [], [field("id", "I32", Bool.False), field("name", "Str", Bool.False)]).map_ok(|r| r.unverified) == Ok([])
expect check("select id from students", Catalog.parse("") ?? Catalog.none, [], []) == Err("table `students` does not exist in the schema")

# Numbers fit a field that holds every value of them, and a domain that
# bounds its integers lets a narrower one take them.
domain_catalog : Catalog
domain_catalog =
	Catalog.parse(
		\\CREATE DOMAIN public.u8 AS smallint CONSTRAINT u8_check CHECK (((VALUE >= 0) AND (VALUE <= 255)));
		\\CREATE DOMAIN public.percent AS integer CHECK (VALUE BETWEEN 0 AND 100);
		\\CREATE DOMAIN public.signed AS integer CHECK (VALUE >= '-5'::integer) CHECK (VALUE <= 5);
		\\CREATE TABLE public.pixels (red public.u8 NOT NULL, done public.percent NOT NULL, tilt public.signed NOT NULL, big bigint NOT NULL, small smallint NOT NULL);
	)
	?? Catalog.none

in_domains : Str, List(RowFormat.Field), List(RowFormat.Field) -> Try({}, Str)
in_domains = |sql, params, fields| check(sql, domain_catalog, params, fields).map_ok(|_| {})

expect in_domains("select red, done, tilt from pixels", [], [field("red", "U8", Bool.False), field("done", "U8", Bool.False), field("tilt", "I8", Bool.False)]) == Ok({})
expect in_domains("select red from pixels", [], [field("red", "I8", Bool.False)]) == Err("column `red` is `u8`, but its field is `I8`")
expect in_domains("select small from pixels", [], [field("small", "U8", Bool.False)]) == Err("column `small` is `smallint`, but its field is `U8`")
expect in_domains("select big from pixels", [], [field("big", "I32", Bool.False)]) == Err("column `big` is `bigint`, but its field is `I32`")
expect in_domains("select small, big from pixels", [], [field("small", "I32", Bool.False), field("big", "Dec", Bool.False)]) == Ok({})
expect in_domains("select red + 1 as r from pixels", [], [field("r", "I32", Bool.False)]) == Ok({})
expect in_domains("update pixels set red = $red where big = $big", [field("red", "U8", Bool.False), field("big", "I32", Bool.False)], []) == Ok({})
expect in_domains("update pixels set red = $red", [field("red", "I16", Bool.False)], []) == Err("column `red` is `u8`, but `$red` is `I16`")
expect in_domains("update pixels set small = $s", [field("s", "I32", Bool.False)], []) == Err("column `small` is `smallint`, but `$s` is `I32`")
