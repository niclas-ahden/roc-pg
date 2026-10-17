## Your database's tables, views, enum types, domains and functions, which
## checked queries are checked against. It is read from a schema dump:
##
## ```sh
## pg_dump --schema-only --no-owner mydb > schema.sql
## ```
##
## Read the dump with [Catalog.from_schema] and wrap it in a type that
## connections carry:
##
## ```
## import "schema.sql" as schema_sql : Str
##
## catalog : Catalog
## catalog = Catalog.from_schema(schema_sql)
##
## Schema := [].{
##     catalog : {} -> Catalog
##     catalog = |{}| catalog
## }
##
## Db : Client.Client(Tcp.Stream, Schema)
## ```
##
## Dump the schema again after each migration. Each statement that
## describes a table, a view, an enum, a domain or a function is read with
## Postgres's own grammar. Everything else in the dump (indexes, sequences,
## grants, comments) is skipped. A statement it reads that the grammar
## refuses stops the build, as the dump is then not what `pg_dump` wrote.
import Enums
import Lex
import Node
import Parse

Catalog :: { tables : List(Catalog.Table), enums : List(Catalog.Enum), functions : List(Catalog.Function), extensions : List(Str), none : Bool, search_path : List(Str) }.{
	## A table or a view. A view's columns are the ones its query returns,
	## which the analysis works out when a query reads it. `primary_key` is
	## empty for a table without one. `triggers` is whether a trigger is
	## defined on the table, which may fill in a column an insert leaves out.
	Table : { name : Str, schema : Str, columns : [Known(List(Catalog.Column)), View({ query : Node, aliases : List(Str) }), Unknown], primary_key : List(Str), triggers : Bool }

	## `type` is the column's type as `pg_dump` spells it, without a schema
	## or a length: `integer`, `character varying`, `timestamp without time
	## zone`, `access_level`, `integer[]`. A column of a domain has the
	## domain's base type, and is `NOT NULL` when the domain is. `has_default`
	## is whether an insert may leave it out: it has a default, is an identity
	## or is generated.
	Column : { name : Str, type : Str, not_null : Bool, has_default : Bool }

	Enum : { name : Str, schema : Str, labels : List(Str) }

	## A function of the schema. `args` are the types it takes, the last
	## `defaults` of which may be left out. A function with several `OUT`
	## parameters or `returns table` returns `record`, and `outputs` are its
	## columns. `aggregate` is whether it is one, made by `create aggregate`.
	Function : { name : Str, schema : Str, args : List(Str), defaults : U64, variadic : Bool, result : Str, set : Bool, strict : Bool, outputs : List({ name : Str, type : Str }), aggregate : Bool }

	## No schema, the catalog of [NoSchema]. Queries are checked for syntax
	## and parameters, but any table, column or function goes. A dump without
	## tables is not this: its queries can name no table.
	none : Catalog
	none = Catalog.{ tables: [], enums: [], functions: [], extensions: [], none: Bool.True, search_path: default_search_path }

	## The schemas a name without one is looked for in, in order, as the
	## server's `search_path` setting lists them. `["public"]` unless set
	## with [Catalog.with_search_path].
	search_path : Catalog -> List(Str)
	search_path = |catalog| catalog.search_path

	## The catalog for connections whose `search_path` is `schemas`, such
	## as `["app", "public"]`. A table, view or function named without a
	## schema is the one in the first of them that has it, after
	## `pg_catalog`, as the server picks it. The setting must be the same on
	## the server, by `alter role ... set search_path` or the `search_path`
	## connection parameter.
	with_search_path : Catalog, List(Str) -> Catalog
	with_search_path = |catalog, schemas| { ..catalog, search_path: schemas }

	is_none : Catalog -> Bool
	is_none = |catalog| catalog.none

	tables : Catalog -> List(Catalog.Table)
	tables = |catalog| catalog.tables

	## The names of the enum types.
	enums : Catalog -> List(Str)
	enums = |catalog| catalog.enums.map(|e| e.name)

	## The labels of enum type `name`, in their order.
	enum_labels : Catalog, Str -> Try(List(Str), [NotFound])
	enum_labels = |catalog, name|
		match in_path(catalog, catalog.enums, |e| e.name == name, |e| e.schema) {
			Ok(e) => Ok(e.labels)
			Err(_) => Err(NotFound)
		}

	functions : Catalog -> List(Catalog.Function)
	functions = |catalog| catalog.functions

	## The functions a call reaches: those of `schema` when the call names
	## one, else those of every schema on the search path.
	functions_in : Catalog, [Qualified(Str), Unqualified] -> List(Catalog.Function)
	functions_in = |catalog, schema|
		match schema {
			Qualified(s) => catalog.functions.keep_if(|f| f.schema == s)
			Unqualified => catalog.functions.keep_if(|f| catalog.search_path.contains(f.schema) or f.schema == "pg_catalog")
		}

	## The extensions the dump creates, other than `plpgsql`. Their functions,
	## operators and types are not in the dump.
	extensions : Catalog -> List(Str)
	extensions = |catalog| catalog.extensions

	## The table or view `name` in the first schema of the search path that
	## has one.
	table : Catalog, Str -> Try(Catalog.Table, [NotFound])
	table = |catalog, name| Catalog.find_table(catalog, Unqualified, name)

	## The table or view `name` of `schema`, or found on the search path.
	find_table : Catalog, [Qualified(Str), Unqualified], Str -> Try(Catalog.Table, [NotFound])
	find_table = |catalog, schema, name|
		match schema {
			Qualified(s) => catalog.tables.find_first(|t| t.name == name and t.schema == s)
			Unqualified => in_path(catalog, catalog.tables, |t| t.name == name, |t| t.schema)
		}

	## Read a schema dump, as a top-level constant over an imported file (see
	## the example above). It runs while the app builds, so a file that is
	## not valid SQL stops the build.
	from_schema : Str -> Catalog
	from_schema = |sql|
		match Catalog.parse(sql) {
			Ok(catalog) => catalog
			Err(BadSchema(message)) => crash "schema.sql: ${message}"
		}

	## Read a schema dump. Fails when the text does not lex as SQL, or when a
	## statement that describes the schema is not valid SQL.
	parse : Str -> Try(Catalog, [BadSchema(Str)])
	parse = |dump| {
		sql = without_meta_commands(dump)
		toks = Lex.tokens(sql) ? |err| BadSchema(Lex.err_to_str(sql, err))
		var $tables = []
		var $enums = []
		var $domains = []
		var $functions = []
		var $extensions = []
		# A table altered or given a trigger is matched by its schema too.
		same = |t, rel| t.name == rel.name and t.schema == rel.schema
		for statement in statements(sql, toks) {
			if wanted(statement.kinds) {
				match Parse.parse(statement.text) {
					Ok([RawStmt(raw)]) =>
						match raw.stmt {
							CreateStmt(s) => {
								$tables = $tables.append(create_table(s, $tables))
							}
							CreateForeignTableStmt({ base: CreateStmt(s), .. }) => {
								$tables = $tables.append(create_table(s, $tables))
							}
							ViewStmt(v) => {
								{ name, schema } = relation_name(v.view)
								$tables = $tables.append({ name, schema, columns: View({ query: v.query, aliases: names_of(v.aliases) }), primary_key: [], triggers: Bool.False })
							}
							CreateTableAsStmt(c) if c.objtype == Enums.object_matview =>
								match c.into {
									IntoClause(into) => {
										{ name, schema } = relation_name(into.rel)
										$tables = $tables.append({ name, schema, columns: View({ query: c.query, aliases: names_of(into.col_names) }), primary_key: [], triggers: Bool.False })
									}
									_ => {}
								}
							AlterTableStmt(a) => {
								rel = relation_name(a.relation)
								$tables = $tables.map(|t| if same(t, rel) alter_table(t, a.cmds) else t)
							}
							CreateEnumStmt(e) => {
								{ name, schema } = qualified_name(e.type_name)
								$enums = $enums.append({ name, schema, labels: names_of(e.vals) })
							}
							CreateDomainStmt(d) => {
								{ name, schema } = qualified_name(d.domainname)
								not_null = d.constraints.any(|c| constraint_type(c) == Enums.constr_notnull)
								has_default = d.constraints.any(|c| constraint_type(c) == Enums.constr_default)
								$domains = $domains.append({ name, schema, base: Catalog.type_name(d.type_name), not_null, has_default })
							}
							CreateFunctionStmt(f) if !f.is_procedure => {
								$functions = $functions.append(create_function(f))
							}
							DefineStmt(d) if d.kind == Enums.object_aggregate => {
								$functions = $functions.append(create_aggregate(d, $functions))
							}
							CreateTrigStmt(trigger) => {
								rel = relation_name(trigger.relation)
								$tables = $tables.map(|t| if same(t, rel) { ..t, triggers: Bool.True } else t)
							}
							CreateExtensionStmt(e) if e.extname != Ok("plpgsql") => {
								$extensions = $extensions.append(e.extname ?? "")
							}
							_ => {}
						}
					Ok(_) => {}
					Err(problem) => {
						at = statement.start + Lex.cursor_offset(statement.text.to_utf8(), problem.cursor)
						return Err(BadSchema("${problem.message} (${Lex.position(sql, at)})"))
					}
				}
			}
		}
		domains = $domains
		resolved = $tables.map(
			|t|
				match t.columns {
					Known(columns) => { ..t, columns: Known(columns.map(|c| resolve_domain(c, domains))) }
					_ => t
				},
		)
		Ok(Catalog.{ tables: resolved, enums: $enums, functions: $functions, extensions: $extensions, none: Bool.False, search_path: default_search_path })
	}

	## The type a `TypeName` node names, spelled as `pg_dump` spells column
	## types: `pg_catalog.int4` is `integer`, `varchar(255)` is `character
	## varying`, `public.access_level` is `access_level`, `int[]` is `integer[]`.
	type_name : Node -> Str
	type_name = |node|
		match node {
			TypeName(t) => {
				base = canonical_type(names_of(t.names).last() ?? "")
				if t.array_bounds.is_empty() base else "${base}[]"
			}
			_ => ""
		}
}

## The server's default `search_path` without `"$user"`, a schema named
## after the user, which a schema dump does not tell.
default_search_path : List(Str)
default_search_path = ["public"]

## The first of `items` that `matches` in the search path's order, with
## `pg_catalog` first.
in_path : Catalog, List(a), (a -> Bool), (a -> Str) -> Try(a, [NotFound])
in_path = |catalog, items, matches, schema_of| {
	found = items.keep_if(matches)
	["pg_catalog"].concat(catalog.search_path()).fold(
		Err(NotFound),
		|acc, schema|
			match acc {
				Ok(_) => acc
				Err(_) => found.find_first(|item| schema_of(item) == schema)
			},
	)
}

## A name of a type or a function: `public.access_level` or `access_level`,
## which the dump means in `public`.
qualified_name : List(Node) -> { name : Str, schema : Str }
qualified_name = |nodes| {
	names = names_of(nodes)
	match names {
		[.., schema, name] => { name, schema }
		[name] => { name, schema: "public" }
		_ => { name: "", schema: "" }
	}
}

## The grammar's internal name of a built in type, as `pg_dump` writes it.
canonical_type : Str -> Str
canonical_type = |name|
	match name {
		"int2" => "smallint"
		"int4" => "integer"
		"int8" => "bigint"
		"float4" => "real"
		"float8" => "double precision"
		"bool" => "boolean"
		"varchar" => "character varying"
		"bpchar" => "character"
		"varbit" => "bit varying"
		"timestamp" => "timestamp without time zone"
		"timestamptz" => "timestamp with time zone"
		"time" => "time without time zone"
		"timetz" => "time with time zone"
		"decimal" => "numeric"
		_ => name
	}

Domain : { name : Str, schema : Str, base : Str, not_null : Bool, has_default : Bool }

resolve_domain : Catalog.Column, List(Domain) -> Catalog.Column
resolve_domain = |column, domains|
	match domains.find_first(|d| d.name == column.type) {
		Ok(domain) => { ..column, type: domain.base, not_null: column.not_null or domain.not_null, has_default: column.has_default or domain.has_default }
		Err(_) => column
	}

## `pg_dump` 17.6 and later put psql's `\restrict` and `\unrestrict` around
## the dump. They are not SQL. Their lines are blanked rather than dropped,
## so a position in an error is still a position in the file.
without_meta_commands : Str -> Str
without_meta_commands = |sql| Str.join_with(sql.split_on("\n").map(|line| if line.starts_with("\\") "" else line), "\n")

## The statements of a dump: the text of each, where it starts and its
## tokens' kinds. A `;` ends a statement unless it is inside parentheses or
## the `begin atomic ... end` body of a function or procedure, which psql
## finds by counting `begin`, `case` and `end` in a statement that starts
## with `create [or replace] function` or `procedure`.
statements : Str, List(Lex.Token) -> List({ text : Str, start : U64, kinds : List(Lex.Kind) })
statements = |sql, toks| {
	bytes = sql.to_utf8()
	var $out = []
	var $current = []
	var $parens = 0.U64
	var $begins = 0.U64
	var $routine = Bool.False
	for tok in toks.append({ kind: Punct(';'), start: bytes.len(), end: bytes.len() }) {
		# The `;` added at the end ends the last statement whatever is open.
		at_end = tok.start == bytes.len() and tok.end == bytes.len()
		if tok.kind == Punct(';') and (($parens == 0 and $begins == 0) or at_end) {
			match ($current.first(), $current.last()) {
				(Ok(first), Ok(last)) => {
					text = Str.from_utf8_lossy(bytes.sublist({ start: first.start, len: last.end - first.start }))
					$out = $out.append({ text, start: first.start, kinds: $current.map(|t| t.kind) })
				}
				_ => {}
			}
			$current = []
			$routine = Bool.False
		} else {
			$current = $current.append(tok)
			# The first four words tell.
			if $current.len() <= 4 {
				$routine = creates_routine($current.map(|t| t.kind))
			}
			if tok.kind == Punct('(') {
				$parens = $parens + 1
			} else if tok.kind == Punct(')') and $parens > 0 {
				$parens = $parens - 1
			} else if $parens == 0 and $routine {
				if tok.kind == Word("begin") {
					$begins = $begins + 1
				} else if tok.kind == Word("case") and $begins > 0 {
					$begins = $begins + 1
				} else if tok.kind == Word("end") and $begins > 0 {
					$begins = $begins - 1
				}
			}
		}
	}
	$out
}

creates_routine : List(Lex.Kind) -> Bool
creates_routine = |kinds|
	match kinds {
		[Word("create"), Word("function"), ..] | [Word("create"), Word("procedure"), ..] => Bool.True
		[Word("create"), Word("or"), Word("replace"), Word("function"), ..] | [Word("create"), Word("or"), Word("replace"), Word("procedure"), ..] => Bool.True
		_ => Bool.False
	}

## Whether a statement can describe a table, a view, an enum, a domain, a
## function, an aggregate, a trigger or an extension. Only those are
## parsed, which keeps reading a dump cheap.
wanted : List(Lex.Kind) -> Bool
wanted = |kinds|
	match kinds {
		[Word("create"), Word("table"), ..] | [Word("create"), Word("unlogged"), Word("table"), ..] | [Word("create"), Word("foreign"), Word("table"), ..] => Bool.True
		[Word("create"), Word("view"), ..] | [Word("create"), Word("or"), Word("replace"), Word("view"), ..] => Bool.True
		[Word("create"), Word("materialized"), Word("view"), ..] => Bool.True
		[Word("create"), Word("type"), ..] => kinds.contains(Word("enum"))
		[Word("create"), Word("domain"), ..] => Bool.True
		[Word("create"), Word("function"), ..] | [Word("create"), Word("or"), Word("replace"), Word("function"), ..] => Bool.True
		[Word("create"), Word("aggregate"), ..] | [Word("create"), Word("or"), Word("replace"), Word("aggregate"), ..] => Bool.True
		[Word("alter"), Word("table"), ..] => kinds.contains(Word("primary")) or kinds.contains(Word("null")) or kinds.contains(Word("column"))
		[Word("create"), Word("trigger"), ..] | [Word("create"), Word("constraint"), Word("trigger"), ..] | [Word("create"), Word("or"), Word("replace"), Word("trigger"), ..] => Bool.True
		[Word("create"), Word("extension"), ..] => Bool.True
		_ => Bool.False
	}

relation_name : Node -> { name : Str, schema : Str }
relation_name = |node|
	match node {
		RangeVar(r) => { name: r.relname ?? "", schema: r.schemaname ?? "public" }
		_ => { name: "", schema: "" }
	}

## A table's columns and primary key. A table that inherits, a partition
## and a table made `like` another one start with that one's columns, read
## earlier in the dump (`pg_dump` writes parents first). A column of its
## own with the name of one of those adds its constraints to it. A table of
## a composite type, or of a parent this has not read, has columns this
## does not know.
create_table : Node.CreateStmt, List(Catalog.Table) -> Catalog.Table
create_table = |s, earlier| {
	{ name, schema } = relation_name(s.relation)
	constraints = s.table_elts.concat(s.constraints).concat(s.nnconstraints)
	primary_key = constraints.fold([], |acc, c| if constraint_type(c) == Enums.constr_primary acc.concat(constraint_keys(c)) else acc)
	not_null = constraints.fold([], |acc, c| if constraint_type(c) == Enums.constr_notnull acc.concat(constraint_keys(c)) else acc)
	parent_columns = |node|
		match node {
			RangeVar(_) => {
				rel = relation_name(node)
				match earlier.find_first(|t| t.name == rel.name and t.schema == rel.schema) {
					Ok({ columns: Known(columns), .. }) => Ok(columns)
					_ => Err(Unread)
				}
			}
			_ => Err(Unread)
		}
	inherited = s.inh_relations.map(parent_columns)
	columns =
		if s.of_typename != Null or inherited.any(
			|p|
				match p {
					Ok(_) => Bool.False
					Err(_) => Bool.True
				},
		) {
			Unknown
		} else {
			start = inherited.fold([], |acc, p| acc.concat(p ?? []))
			s.table_elts.fold(
				Known(start),
				|acc, elt|
					match (acc, elt) {
						(Known(so_far), ColumnDef(c)) => {
							own = column(c)
							if so_far.any(|existing| existing.name == own.name) {
								Known(so_far.map(|existing| if existing.name == own.name { ..existing, not_null: existing.not_null or own.not_null, has_default: existing.has_default or own.has_default } else existing))
							} else {
								Known(so_far.append(own))
							}
						}
						(Known(so_far), TableLikeClause(like)) =>
							match parent_columns(like.relation) {
								Ok(copied) => Known(so_far.concat(copied.map(|c| { ..c, has_default: c.has_default and like.options.bitwise_and(like_defaults) != 0 })))
								Err(_) => Unknown
							}
						(Known(so_far), Constraint(_)) => Known(so_far)
						_ => Unknown
					},
			)
		}
	marked =
		match columns {
			Known(list) => Known(list.map(|c| if primary_key.contains(c.name) or not_null.contains(c.name) { ..c, not_null: Bool.True } else c))
			other => other
		}
	{ name, schema, columns: marked, primary_key, triggers: Bool.False }
}

## `including defaults`, `identity` and `generated` of a `like` clause, the
## options that copy what lets an insert leave a column out
## (`CREATE_TABLE_LIKE_DEFAULTS`, `_GENERATED` and `_IDENTITY`).
like_defaults : I64
like_defaults = 8 + 16 + 32

column : Node.ColumnDef -> Catalog.Column
column = |c| {
	not_null = c.is_not_null or c.constraints.any(|con| constraint_type(con) == Enums.constr_notnull or constraint_type(con) == Enums.constr_primary)
	# A default, an identity or a generated column.
	has_default = c.raw_default != Null or c.identity != 0 or c.generated != 0 or c.constraints.any(|con| [Enums.constr_default, Enums.constr_identity, Enums.constr_generated].contains(constraint_type(con)))
	{ name: c.colname ?? "", type: Catalog.type_name(c.type_name), not_null, has_default }
}

constraint_type : Node -> I64
constraint_type = |node|
	match node {
		Constraint(c) => c.contype
		_ => -1
	}

constraint_keys : Node -> List(Str)
constraint_keys = |node|
	match node {
		Constraint(c) => names_of(c.keys)
		_ => []
	}

## `add constraint ... primary key (cols)`, `alter column c set not null`,
## `alter column c set default ...`, `alter column c add generated ... as
## identity` and `add column`.
alter_table : Catalog.Table, List(Node) -> Catalog.Table
alter_table = |table, cmds|
	cmds.fold(
		table,
		|t, cmd|
			match cmd {
				AlterTableCmd(c) =>
					if c.subtype == Enums.at_add_constraint and constraint_type(c.def) == Enums.constr_primary {
						keys = constraint_keys(c.def)
						{ ..set_not_null(t, keys), primary_key: t.primary_key.concat(keys) }
					} else if c.subtype == Enums.at_set_not_null {
						set_not_null(t, [c.name ?? ""])
					} else if (c.subtype == Enums.at_column_default and c.def != Null) or c.subtype == Enums.at_add_identity {
						set_has_default(t, c.name ?? "")
					} else if c.subtype == Enums.at_add_column {
						match (t.columns, c.def) {
							(Known(columns), ColumnDef(def)) => { ..t, columns: Known(columns.append(column(def))) }
							_ => t
						}
					} else {
						t
					}
				_ => t
			},
	)

set_has_default : Catalog.Table, Str -> Catalog.Table
set_has_default = |table, name|
	match table.columns {
		Known(columns) => { ..table, columns: Known(columns.map(|c| if c.name == name { ..c, has_default: Bool.True } else c)) }
		_ => table
	}

set_not_null : Catalog.Table, List(Str) -> Catalog.Table
set_not_null = |table, names|
	match table.columns {
		Known(columns) => { ..table, columns: Known(columns.map(|c| if names.contains(c.name) { ..c, not_null: Bool.True } else c)) }
		_ => table
	}

create_function : Node.CreateFunctionStmt -> Catalog.Function
create_function = |f| {
	params = f.parameters.keep_oks(
		|p|
			match p {
				FunctionParameter(param) => Ok(param)
				_ => Err(NotAParameter)
			},
	)
	# IN, INOUT, VARIADIC and the default mode take an argument. OUT, INOUT
	# and TABLE give a column.
	inputs = params.keep_if(|p| [Enums.func_param_in, Enums.func_param_inout, Enums.func_param_variadic, Enums.func_param_default].contains(p.mode))
	outputs = params.keep_if(|p| [Enums.func_param_out, Enums.func_param_inout, Enums.func_param_table].contains(p.mode)).map(|p| { name: p.name ?? "", type: Catalog.type_name(p.arg_type) })
	declared = Catalog.type_name(f.return_type)
	result =
		match outputs {
			[] => declared
			[only] => only.type
			_ => "record"
		}
	set =
		match f.return_type {
			TypeName(t) => t.setof
			_ => Bool.False
		}
	strict = f.options.any(
		|o|
			match o {
				DefElem(d) =>
					if d.defname == Ok("strict") {
						match d.arg {
							Boolean(b) => b.boolval
							_ => Bool.False
						}
					} else {
						Bool.False
					}
				_ => Bool.False
			},
	)
	{ name, schema } = qualified_name(f.funcname)
	{
		name,
		schema,
		args: inputs.map(|p| Catalog.type_name(p.arg_type)),
		defaults: inputs.count_if(|p| p.defexpr != Null),
		variadic: inputs.any(|p| p.mode == Enums.func_param_variadic),
		result,
		set,
		strict,
		outputs: if outputs.len() > 1 outputs else [],
		aggregate: Bool.False,
	}
}

## `create aggregate name (types) (sfunc = ..., stype = ...)`. It returns
## what its `finalfunc`, one read earlier in the dump, returns, or else its
## state type.
create_aggregate : Node.DefineStmt, List(Catalog.Function) -> Catalog.Function
create_aggregate = |d, earlier| {
	{ name, schema } = qualified_name(d.defnames)
	# The arguments, then the number of direct ones of an ordered-set
	# aggregate, or nothing in the old syntax.
	params =
		match d.args {
			[NodeList(items), ..] =>
				items.keep_oks(
					|p|
						match p {
							FunctionParameter(param) => Ok(param)
							_ => Err(NotAParameter)
						},
				)
			_ => []
		}
	option = |key|
		d.definition.keep_oks(
			|o|
				match o {
					DefElem(e) if e.defname == Ok(key) => Ok(e.arg)
					_ => Err(NotThere)
				},
		).first()
	state_type = option("stype").map_ok(Catalog.type_name) ?? ""
	result =
		match option("finalfunc") {
			Ok(TypeName(t)) => {
				final = qualified_name(t.names)
				earlier.find_first(|f| f.name == final.name and f.schema == final.schema).map_ok(|f| f.result) ?? ""
			}
			_ => state_type
		}
	{
		name,
		schema,
		args: params.map(|p| Catalog.type_name(p.arg_type)),
		defaults: 0,
		variadic: params.any(|p| p.mode == Enums.func_param_variadic),
		result,
		set: Bool.False,
		strict: Bool.False,
		outputs: [],
		aggregate: Bool.True,
	}
}

names_of : List(Node) -> List(Str)
names_of = |nodes|
	nodes.keep_oks(
		|node|
			match node {
				String(s) =>
					match s.sval {
						Ok(text) => Ok(text)
						Err(_) => Err(NotAString)
					}
				_ => Err(NotAString)
			},
	)

sample =
	\\\\restrict abc123
	\\CREATE TYPE public.access_level AS ENUM (
	\\    'Viewer',
	\\    'Editor'
	\\);
	\\CREATE DOMAIN public.email AS text NOT NULL CHECK (VALUE ~ '@');
	\\CREATE TABLE public.students (
	\\    id integer NOT NULL,
	\\    nickname text NOT NULL COLLATE public.nocase,
	\\    avatar_url text,
	\\    "group" integer,
	\\    handle character varying(255) DEFAULT ''::character varying NOT NULL,
	\\    seen_at timestamp(6) without time zone,
	\\    level public.access_level,
	\\    tags text[],
	\\    contact public.email,
	\\    CONSTRAINT students_x CHECK ((id <> 0))
	\\);
	\\CREATE TABLE public.schools (
	\\    code text,
	\\    name text NOT NULL
	\\);
	\\CREATE SEQUENCE public.schools_id_seq START WITH 1;
	\\ALTER TABLE ONLY public.schools
	\\    ADD CONSTRAINT schools_pkey PRIMARY KEY (code);
	\\ALTER TABLE ONLY public.schools ALTER COLUMN code SET DEFAULT 'x';
	\\CREATE VIEW public.active_students AS SELECT * FROM public.students;
	\\CREATE FUNCTION public.full_name(first text, last text DEFAULT '') RETURNS text
	\\    LANGUAGE sql STRICT
	\\    AS $$ select first || ' ' || last $$;
	\\CREATE FUNCTION public.school_stats(code text, OUT n bigint, OUT newest timestamp with time zone) RETURNS record
	\\    LANGUAGE sql AS $$ select 1, now() $$;
	\\\\unrestrict abc123

expect {
	catalog = Catalog.parse(sample) ?? Catalog.none
	catalog.enums() == ["access_level"]
	and catalog.enum_labels("access_level") == Ok(["Viewer", "Editor"])
	and catalog.table("students").map_ok(|t| t.columns)
	== Ok(
		Known(
			[
				{ name: "id", type: "integer", not_null: Bool.True, has_default: Bool.False },
				{ name: "nickname", type: "text", not_null: Bool.True, has_default: Bool.False },
				{ name: "avatar_url", type: "text", not_null: Bool.False, has_default: Bool.False },
				{ name: "group", type: "integer", not_null: Bool.False, has_default: Bool.False },
				{ name: "handle", type: "character varying", not_null: Bool.True, has_default: Bool.True },
				{ name: "seen_at", type: "timestamp without time zone", not_null: Bool.False, has_default: Bool.False },
				{ name: "level", type: "access_level", not_null: Bool.False, has_default: Bool.False },
				{ name: "tags", type: "text[]", not_null: Bool.False, has_default: Bool.False },
				{ name: "contact", type: "text", not_null: Bool.True, has_default: Bool.False },
			],
		),
	)
	and catalog.table("schools").map_ok(|t| (t.columns, t.primary_key)) == Ok((Known([{ name: "code", type: "text", not_null: Bool.True, has_default: Bool.True }, { name: "name", type: "text", not_null: Bool.True, has_default: Bool.False }]), ["code"]))
}

expect {
	catalog = Catalog.parse(sample) ?? Catalog.none
	match catalog.table("active_students") {
		Ok({ columns: View(_), .. }) => Bool.True
		_ => Bool.False
	}
}

expect {
	catalog = Catalog.parse(sample) ?? Catalog.none
	catalog.functions()
	== [
		{ name: "full_name", schema: "public", args: ["text", "text"], defaults: 1, variadic: Bool.False, result: "text", set: Bool.False, strict: Bool.True, outputs: [], aggregate: Bool.False },
		{ name: "school_stats", schema: "public", args: ["text"], defaults: 0, variadic: Bool.False, result: "record", set: Bool.False, strict: Bool.False, outputs: [{ name: "n", type: "bigint" }, { name: "newest", type: "timestamp with time zone" }], aggregate: Bool.False },
	]
}

expect {
	dump =
		\\CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;
		\\CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
		\\CREATE TABLE public.events (id bigint NOT NULL, at timestamp with time zone DEFAULT now() NOT NULL, n integer GENERATED ALWAYS AS (1) STORED);
		\\ALTER TABLE public.events ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (SEQUENCE NAME public.events_id_seq START WITH 1);
		\\CREATE TRIGGER stamp BEFORE INSERT ON public.events FOR EACH ROW EXECUTE FUNCTION public.stamp();
	catalog = Catalog.parse(dump) ?? Catalog.none
	catalog.extensions() == ["pgcrypto"]
	and catalog.table("events").map_ok(|t| (t.columns, t.triggers))
	== Ok(
		(
			Known(
				[
					{ name: "id", type: "bigint", not_null: Bool.True, has_default: Bool.True },
					{ name: "at", type: "timestamp with time zone", not_null: Bool.True, has_default: Bool.True },
					{ name: "n", type: "integer", not_null: Bool.False, has_default: Bool.True },
				],
			),
			Bool.True,
		),
	)
}

expect Catalog.parse("CREATE TABLE public.planets (\n    id integer NOT NULL,\n);").map_ok(|_| {}) == Err(BadSchema("syntax error at or near \")\" (line 3, column 1)"))
expect Catalog.parse("\\restrict abc\nCREATE TYPE public.mood AS ENUM ('ok');\nCREATE TABLE public.x (id integer,);").map_ok(|_| {}) == Err(BadSchema("syntax error at or near \")\" (line 3, column 35)"))
expect Catalog.parse("CREATE TABLE public.x (id integer); CREATE INDEX nope ON;").map_ok(|c| c.tables().len()) == Ok(1)
expect Catalog.parse("").map_ok(|c| c.is_none()) == Ok(Bool.False)
expect Catalog.none.is_none()

# Schemas: a name without one is looked for on the search path, and a
# statement of the dump changes the table of its own schema only.
expect {
	dump =
		\\CREATE TABLE public.users (id integer NOT NULL, name text);
		\\CREATE TABLE app.users (id bigint NOT NULL, email text);
		\\ALTER TABLE ONLY app.users ALTER COLUMN email SET NOT NULL;
		\\CREATE TRIGGER t BEFORE INSERT ON app.users FOR EACH ROW EXECUTE FUNCTION app.f();
	catalog = Catalog.parse(dump) ?? Catalog.none
	in_app = catalog.with_search_path(["app", "public"])
	columns = |c, schema| c.find_table(schema, "users").map_ok(|t| (t.schema, t.triggers, t.columns))
	columns(catalog, Unqualified) == Ok(("public", Bool.False, Known([{ name: "id", type: "integer", not_null: Bool.True, has_default: Bool.False }, { name: "name", type: "text", not_null: Bool.False, has_default: Bool.False }])))
	and columns(in_app, Unqualified) == Ok(("app", Bool.True, Known([{ name: "id", type: "bigint", not_null: Bool.True, has_default: Bool.False }, { name: "email", type: "text", not_null: Bool.True, has_default: Bool.False }])))
	and catalog.find_table(Qualified("app"), "users").map_ok(|t| t.schema) == Ok("app")
	and catalog.find_table(Qualified("other"), "users").map_ok(|t| t.schema) == Err(NotFound)
}

# A `begin atomic` body holds statements of its own.
expect {
	dump =
		\\CREATE FUNCTION public.answer() RETURNS integer
		\\    LANGUAGE sql
		\\    BEGIN ATOMIC
		\\ SELECT CASE WHEN true THEN 42 ELSE 0 END;
		\\ SELECT 1;
		\\END;
		\\CREATE TABLE public.after (id integer);
	catalog = Catalog.parse(dump) ?? Catalog.none
	catalog.functions().map(|f| (f.name, f.result)) == [("answer", "integer")]
	and catalog.tables().map(|t| t.name) == ["after"]
}

# Columns a table gets from another one, and other ways a dump makes them.
expect {
	dump =
		\\CREATE DOMAIN public.stamp AS timestamp with time zone DEFAULT now() NOT NULL;
		\\CREATE TABLE public.base (id integer NOT NULL, at public.stamp, note text DEFAULT 'x');
		\\CREATE TABLE public.child (extra text, note text NOT NULL) INHERITS (public.base);
		\\CREATE TABLE public.copy (LIKE public.base, more integer);
		\\CREATE TABLE public.copy_all (LIKE public.base INCLUDING ALL);
		\\CREATE TABLE public.part (id integer NOT NULL, region text) PARTITION BY LIST (region);
		\\CREATE TABLE public.part_eu PARTITION OF public.part (region NOT NULL) FOR VALUES IN ('eu');
		\\CREATE FOREIGN TABLE public.remote (id integer NOT NULL) SERVER elsewhere;
		\\CREATE TABLE public.orphan (id integer) INHERITS (public.missing);
	catalog = Catalog.parse(dump) ?? Catalog.none
	shape = |name|
		match catalog.table(name) {
			Ok({ columns: Known(columns), .. }) => columns.map(|c| "${c.name} ${c.type}${if c.not_null " not null" else ""}${if c.has_default " default" else ""}")
			_ => ["unknown"]
		}
	shape("base") == ["id integer not null", "at timestamp with time zone not null default", "note text default"]
	and shape("child") == ["id integer not null", "at timestamp with time zone not null default", "note text not null default", "extra text"]
	and shape("copy") == ["id integer not null", "at timestamp with time zone not null default", "note text", "more integer"]
	and shape("copy_all") == ["id integer not null", "at timestamp with time zone not null default", "note text default"]
	and shape("part_eu") == ["id integer not null", "region text not null"]
	and shape("remote") == ["id integer not null"]
	and shape("orphan") == ["unknown"]
}

# An aggregate of the schema.
expect {
	dump =
		\\CREATE FUNCTION public.add_one(integer, integer) RETURNS integer LANGUAGE sql AS $$ select $1 + $2 $$;
		\\CREATE FUNCTION public.shout(integer) RETURNS text LANGUAGE sql AS $$ select $1::text $$;
		\\CREATE AGGREGATE public.total(integer) (SFUNC = public.add_one, STYPE = integer);
		\\CREATE AGGREGATE public.loud(integer) (SFUNC = public.add_one, STYPE = integer, FINALFUNC = public.shout);
	catalog = Catalog.parse(dump) ?? Catalog.none
	catalog.functions().keep_if(|f| f.aggregate).map(|f| (f.name, f.args, f.result)) == [("total", ["integer"], "integer"), ("loud", ["integer"], "text")]
}
