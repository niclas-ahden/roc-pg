## Reads a query's parse tree and checks it against a [Catalog]: that its
## tables and columns exist, that parameters fit the columns they meet, and
## what its result columns are called, what type they have and whether they
## can be NULL.
##
## It never rejects what it does not understand. An expression it cannot
## type is "unknown", a relation it cannot read makes its columns unknown,
## and unknown things are not checked. Only what it is sure of becomes a
## problem.
import Catalog
import Enums
import Overload
import PgType
import Lex
import Node
import Parse

Check :: [].{
	## A result column. `nullable` is `Yes` when the column can be NULL,
	## `No` when it cannot, and `Unknown` when the analysis cannot tell.
	Output : { name : Str, type : [Known(Str), Unknown], nullable : [Yes, No, Unknown] }

	Result : { outputs : [Known(List(Check.Output)), Unknown], problems : List(Str) }

	## A field of the parameter record, like a `RowFormat.Field`: `kind` is
	## `Str`, `I32`, `List(I32)` and so on, and `nullable` is whether it is a
	## `Try(_, [Null])`.
	Param : { name : Str, kind : Str, nullable : Bool }

	## Analyze one statement: a node of [Parse.parse] over the text
	## [Lex.grammar_text] makes. `params` are the fields of the parameter
	## record, and `names` says which `$name` stands at each parameter's
	## location ([Lex.named_at]).
	##
	## A parameter is checked against the column it meets: `col = $name`,
	## `col in ($a, $b)`, `col = any($names)`, `set col = $name` and the
	## values of an `insert`. It must fit the column's type, and one that can
	## be NULL cannot go into a `NOT NULL` column.
	analyze : Node, Catalog, List(Check.Param), List({ at : I64, name : Str }) -> Check.Result
	analyze = |stmt, catalog, params, names| {
		result = statement(stmt, { catalog, ctes: [], outer: [], params, names, grouped: Bool.False, group: NoGroup, enums: catalog.enums() })
		{ ..result, problems: result.problems.fold([], |acc, p| if acc.contains(p) acc else acc.append(p)) }
	}

	## Whether a result column of `type`, as the analysis gives it, fits a
	## row field that decodes as `kind`: the field takes every value the
	## column can hold (see [PgType.field_holds]), the bounds of a domain
	## such as `u8` included.
	fits : Catalog, Str, Str -> Bool
	fits = |catalog, type, kind| PgType.field_holds(kind, values_in(catalog, type), base_in(catalog, type))

	## A hint for a name that is probably a misspelling of one of `names`,
	## such as `` (did you mean `school_id`?)``, or "" when none is close.
	suggestion : Str, List(Str) -> Str
	suggestion = |name, names| {
		limit = if name.to_utf8().len() <= 4 1 else 2
		var $best = ""
		var $best_distance = limit + 1
		for candidate in names {
			d = distance(name, candidate)
			if d < $best_distance and candidate != name {
				$best = candidate
				$best_distance = d
			}
		}
		if $best == "" "" else " (did you mean `${$best}`?)"
	}
}

## How many single byte edits (insert, delete, replace, swap two neighbours)
## turn `a_str` into `b_str`.
distance : Str, Str -> U64
distance = |a_str, b_str| {
	a = a_str.to_utf8()
	b = b_str.to_utf8()
	var $prev2 = []
	var $prev = []
	var $j = 0
	while $j <= b.len() {
		$prev = $prev.append($j)
		$j = $j + 1
	}
	var $i = 1
	while $i <= a.len() {
		ca = a.get($i - 1) ?? 0
		var $cur = [$i]
		var $k = 1
		while $k <= b.len() {
			cb = b.get($k - 1) ?? 0
			cost = if ca == cb 0 else 1
			edit = smaller(smaller(($prev.get($k) ?? 0) + 1, ($cur.get($k - 1) ?? 0) + 1), ($prev.get($k - 1) ?? 0) + cost)
			swapped = $i > 1 and $k > 1 and ca == (b.get($k - 2) ?? 0) and (a.get($i - 2) ?? 0) == cb
			$cur = $cur.append(if swapped smaller(edit, ($prev2.get($k - 2) ?? 0) + 1) else edit)
			$k = $k + 1
		}
		$prev2 = $prev
		$prev = $cur
		$i = $i + 1
	}
	$prev.get(b.len()) ?? 0
}

smaller : U64, U64 -> U64
smaller = |x, y| if x < y x else y

Cols : [Known(List(Check.Output)), Unknown]

## `grouped` is whether the select being read has a `group by`, which
## decides whether an aggregate can see no rows. `group` is what grouping
## lets the expressions being read refer to. `enums` are the schema's enum
## types.
Env : { catalog : Catalog, ctes : List({ name : Str, columns : Cols }), outer : List(Rel), params : List(Check.Param), names : List({ at : I64, name : Str }), grouped : Bool, group : Group, enums : List(Str) }

## What the select whose select list, `having` and `order by` are being
## read groups by: its `group by` expressions, the columns among them by
## relation and column name, the relations whose primary key is grouped by,
## all of whose columns may be read, and the expressions some grouping set
## leaves out, which are NULL in its rows. `NoGroup` for every other clause.
Group : [NoGroup, Group({ exprs : List(Node), keys : List((Str, Str)), covered : List(Str), partial : List(Node) })]

## What one walk over an expression learns, bottom up, so that each node
## is read once however deep the expression is.
##
## - `output`: its name, type and nullability as a result column.
## - `arg`: it as an argument for picking a function or operator.
## - `problems`: columns that do not exist, calls that nothing takes,
##   parameters that do not fit, and what subqueries in it find.
## - `aggregate`: whether it calls an aggregate outside a subquery.
## - `ungrouped`: the column references in it that the select's grouping
##   does not allow, as written.
Typed : { output : Check.Output, arg : Overload.Arg, problems : List(Str), aggregate : Bool, ungrouped : List(Str) }

## A relation of a query. `hidden` are the columns an unqualified reference
## does not see, because a `using` or `natural` join merged them into the
## same column of the other side.
## `not_null` are the columns a `where` clause keeps only rows where they
## are not NULL. `source` is the catalog's table for a table or view.
Rel : { alias : Str, table : Str, columns : Cols, nullable : Bool, hidden : List(Str), not_null : List(Str), source : Try(Catalog.Table, [NotATable]) }

Lookup : [Found(Check.Output), Missing(Str), Unsure]

no_outputs : Check.Result
no_outputs = { outputs: Unknown, problems: [] }

## The type a bounded domain is of, or `type` itself.
base_in : Catalog, Str -> Str
base_in = |catalog, type|
	if type.ends_with("[]") {
		"${base_in(catalog, type.drop_suffix("[]"))}[]"
	} else {
		catalog.domain(type).map_ok(|d| d.base) ?? type
	}

## The values a column of `type` holds, those of a bounded domain's range.
values_in : Catalog, Str -> PgType.Values
values_in = |catalog, type|
	match catalog.domain(type) {
		Ok(d) => Integers(d.low, d.high)
		Err(_) => PgType.values(type)
	}

## An argument as picking a function or operator sees it: a bounded
## domain is its base type.
base_arg : Overload.Arg, Env -> Overload.Arg
base_arg = |arg, env|
	match arg {
		Known(t) => Known(base_in(env.catalog, t))
		other => other
	}

statement : Node, Env -> Check.Result
statement = |node, outer_env| {
	# Grouping is the business of the select it belongs to.
	env = { ..outer_env, group: NoGroup }
	match node {
		RawStmt(raw) => statement(raw.stmt, env)
		SelectStmt(s) => select_stmt(s, env)
		InsertStmt(s) => insert_stmt(s, env)
		UpdateStmt(s) => update_stmt(s, env)
		DeleteStmt(s) => delete_stmt(s, env)
		MergeStmt(s) => merge_stmt(s, env)
		_ => no_outputs
	}
}

## The common table expressions of a `with` clause, added to `env`.
with_env : Node, Env -> { env : Env, problems : List(Str) }
with_env = |node, env|
	match node {
		WithClause(w) => {
			var $env = env
			var $problems = []
			for item in w.ctes {
				match item {
					CommonTableExpr(cte) => {
						name = cte.ctename ?? ""
						# A recursive query reads itself, so it is known before its body is.
						self_env = { ..$env, ctes: $env.ctes.append({ name, columns: Unknown }) }
						result = statement(cte.ctequery, self_env)
						$env = { ..$env, ctes: $env.ctes.append({ name, columns: rename(result.outputs, names_of(cte.aliascolnames)) }) }
						$problems = $problems.concat(result.problems)
					}
					_ => {}
				}
			}
			{ env: $env, problems: $problems }
		}
		_ => { env, problems: [] }
	}

## Give outputs the names of a column alias list, by position.
rename : Cols, List(Str) -> Cols
rename = |outputs, aliases|
	if aliases.is_empty() {
		outputs
	} else {
		match outputs {
			Known(list) => Known(list.map_with_index(|o, i| { ..o, name: aliases.get(i) ?? o.name }))
			Unknown => Known(aliases.map(|name| { name, type: Unknown, nullable: Unknown }))
		}
	}

select_stmt : Node.SelectStmt, Env -> Check.Result
select_stmt = |s, env| {
	{ env: inner, problems: with_problems } = with_env(s.with_clause, env)
	result =
		if s.op != Enums.setop_none {
			set_operation(s, inner)
		} else if !s.values_lists.is_empty() {
			values_select(s.values_lists, inner)
		} else {
			simple_select(s, inner)
		}
	{ ..result, problems: with_problems.concat(result.problems) }
}

## Selects joined by `union`, `intersect` or `except`, read a pair at a
## time as Postgres's `transformSetOperationTree` reads them. The columns
## are named after the left one's and take the type both share.
set_operation : Node.SelectStmt, Env -> Check.Result
set_operation = |s, env| {
	tree = set_tree(s, env)
	outputs =
		match tree.columns {
			Known(columns) => Known(columns.map(|c| c.output))
			Unknown => Unknown
		}
	{ outputs, problems: tree.problems }
}

## A column of one side of a set operation, and it as an argument for
## picking the type both sides share.
SetColumn : { output : Check.Output, arg : Overload.Arg }

set_tree : Node.SelectStmt, Env -> { columns : [Known(List(SetColumn)), Unknown], problems : List(Str) }
set_tree = |s, env|
	if s.op == Enums.setop_none {
		result = select_stmt(s, env)
		# A string literal, NULL or a parameter in a branch has no type yet.
		untyped =
			s.target_list.map(
				|target|
					match target {
						ResTarget({ val: ParamRef(_), .. }) => Bool.True
						ResTarget({ val: AConst(c), .. }) =>
							match c.val {
								String(_) => Bool.True
								_ => c.isnull
							}
						_ => Bool.False
					},
			)
		stars = s.target_list.any(
			|target|
				match target {
					ResTarget(t) => star_of(t.val).is_ok()
					_ => Bool.False
				},
		)
		columns =
			match result.outputs {
				Known(outputs) => Known(outputs.map_with_index(|o, i| { output: o, arg: if !stars and untyped.get(i) == Ok(Bool.True) Untyped else type_arg(o.type) }))
				Unknown => Unknown
			}
		{ columns, problems: result.problems }
	} else {
		side = |node|
			match node {
				SelectStmt(inner) => set_tree(inner, env)
				_ => { columns: Unknown, problems: [] }
			}
		left = side(s.larg)
		right = side(s.rarg)
		context = if s.op == Enums.setop_union "UNION" else if s.op == Enums.setop_intersect "INTERSECT" else "EXCEPT"
		problems = left.problems.concat(right.problems)
		match (left.columns, right.columns) {
			(Known(l), Known(r)) =>
				if l.len() != r.len() {
					{ columns: Unknown, problems: problems.append("each ${context} query must have the same number of columns") }
				} else {
					pairs = List.map2(l, r, |a, b| (a, b)).map(
						|(a, b)| {
							shared = shared_type(context, [a.arg, b.arg], env)
							# A row of an intersect is in both sides, and NULL only when it is
							# in both. A row of an except is the left side's.
							nullable =
								if s.op == Enums.setop_union {
									merge_nullable([a.output.nullable, b.output.nullable])
								} else if s.op == Enums.setop_intersect {
									if a.output.nullable == No or b.output.nullable == No No else merge_nullable([a.output.nullable, b.output.nullable])
								} else {
									a.output.nullable
								}
							{ column: { output: { name: a.output.name, type: shared.type, nullable }, arg: type_arg(shared.type) }, problems: shared.problems }
						},
					)
					{ columns: Known(pairs.map(|p| p.column)), problems: problems.concat(pairs.fold([], |acc, p| acc.concat(p.problems))) }
				}
			(Known(l), Unknown) =>
				# The other side could change each column's type and NULL.
				{ columns: Known(l.map(|c| { output: { ..c.output, type: Unknown, nullable: Unknown }, arg: Unsure })), problems }
			_ => { columns: Unknown, problems }
		}
	}

## `Yes` when any can be NULL, `No` when none can.
merge_nullable : List([Yes, No, Unknown]) -> [Yes, No, Unknown]
merge_nullable = |all|
	if all.any(|n| n == Yes) {
		Yes
	} else if all.all(|n| n == No) {
		No
	} else {
		Unknown
	}

## `values (...), ...`, whose columns are `column1`, `column2`, ...
values_select : List(Node), Env -> Check.Result
values_select = |lists, env| {
	rows = lists.map(
		|row|
			match row {
				NodeList(items) => items
				_ => []
			},
	)
	cells = rows.map(|items| items.map(|item| typed(item, [], env)))
	problems = cells.fold([], |acc, row| row.fold(acc, |inner, cell| inner.concat(cell.problems)))
	width = cells.first().map_ok(|row| row.len()) ?? 0
	if cells.any(|row| row.len() != width) {
		return { outputs: Unknown, problems: problems.append("VALUES lists must all be the same length") }
	}
	columns = (cells.first() ?? []).map_with_index(
		|_, i| {
			column = cells.keep_oks(|row| row.get(i))
			shared = shared_type("VALUES", column.map(|cell| cell.arg), env)
			{ output: { name: "column${(i + 1).to_str()}", type: shared.type, nullable: merge_nullable(column.map(|cell| cell.output.nullable)) }, problems: shared.problems }
		},
	)
	outputs = if cells.is_empty() Unknown else Known(columns.map(|c| c.output))
	{ outputs, problems: problems.concat(columns.fold([], |acc, c| acc.concat(c.problems))) }
}

simple_select : Node.SelectStmt, Env -> Check.Result
simple_select = |s, outer_env| {
	plain = { ..outer_env, grouped: Bool.False, group: NoGroup }
	{ rels, problems: from_problems } = from_list(s.from_clause, plain)
	grouping = group_of(s, rels)
	# An empty grouping set, like the one `rollup` adds, makes a row of all
	# the rows: when there are none, its aggregates see none.
	clause_env = { ..plain, grouped: !s.group_clause.is_empty() and !grouping.empty }
	env = { ..clause_env, group: grouping.group }
	# The rows `where` keeps have no NULL in the columns it rules NULL out.
	selected = target_list(s.target_list, narrowed(rels, s.where_clause), env)
	aliases = s.target_list.keep_oks(
		|target|
			match target {
				ResTarget(t) => t.name.map_err(|_| NoAlias)
				_ => Err(NoAlias)
			},
	)
	having = typed(s.having_clause, rels, env)
	distinct = s.distinct_clause.map(|item| output_ref(item, aliases, rels, env))
	sorted = s.sort_clause.map(|item| output_ref(item, aliases, rels, env))
	clause_problems =
		expression_problems(s.where_clause, rels, clause_env)
			.concat(s.group_clause.fold([], |acc, item| acc.concat(output_ref(item, aliases, rels, clause_env).problems)))
			.concat(having.problems)
			.concat(distinct.fold([], |acc, item| acc.concat(item.problems)))
			.concat(sorted.fold([], |acc, item| acc.concat(item.problems)))
			.concat(s.window_clause.fold([], |acc, item| acc.concat(expression_problems(item, rels, clause_env))))
			.concat(expression_problems(s.limit_count, rels, clause_env))
			.concat(expression_problems(s.limit_offset, rels, clause_env))
	# A select that groups, by `group by` or by calling an aggregate, reads a
	# column outside an aggregate only when it is grouped by, or its table's
	# primary key is, or the whole expression it is in is.
	grouped = !s.group_clause.is_empty() or selected.aggregate or having.aggregate
	ungrouped = if grouped selected.ungrouped.concat(having.ungrouped).concat(sorted.concat(distinct).fold([], |acc, item| acc.concat(item.ungrouped))) else []
	group_problems = ungrouped.map(|ref| "column `${ref}` must appear in `group by` or be used in an aggregate")
	{ outputs: selected.outputs, problems: from_problems.concat(selected.problems).concat(clause_problems).concat(group_problems) }
}

## The relation of this query a column reference reads, if it reads one.
owner : Ref, List(Rel) -> Try(Rel, [NotOwned])
owner = |ref, rels|
	match ref.qualifier {
		Some(alias) =>
			match find_rel(rels, alias) {
				Ok(rel) => Ok(rel)
				Err(_) => Err(NotOwned)
			}
		None =>
			match rels.keep_if(|r| visible_names(r).contains(ref.name)) {
				[one] => Ok(one)
				_ => Err(NotOwned)
			}
	}

## What a select groups by, for reading its select list, `having` and
## `order by`, and whether one of its grouping sets is empty.
group_of : Node.SelectStmt, List(Rel) -> { group : Group, empty : Bool }
group_of = |s, rels| {
	selected = s.target_list.keep_oks(
		|t|
			match t {
				ResTarget(r) => Ok(r)
				_ => Err(NotATarget)
			},
	)
	# A position or an output alias in `group by` means that select item.
	item_expr = |item|
		match item {
			AConst({ val: Integer(i), .. }) => (selected.get((i.ival - 1).to_u64_wrap()) ?? { name: Err(Null), indirection: [], val: item, location: 0 }).val
			ColumnRef({ fields: [String({ sval: Ok(name) })], .. }) =>
				match selected.find_first(|t| t.name == Ok(name)) {
					Ok(t) if !has_column_named(rels, name) => t.val
					_ => item
				}
			_ => item
		}
	items = s.group_clause.map(|item| grouping_sets(item, item_expr))
	all = items.fold([], |acc, i| acc.concat(i.all))
	every = items.fold([], |acc, i| acc.concat(i.every))
	keys_of = |exprs|
		exprs.keep_oks(
			|g|
				match g {
					ColumnRef(c) =>
						match column_ref(c) {
							Ok(ref) =>
								match owner(ref, rels) {
									Ok(r) => Ok((r.alias, ref.name))
									Err(_) => Err(NotOwned)
								}
							Err(_) => Err(NotOwned)
						}
					_ => Err(NotOwned)
				},
		)
	# Any column of any grouping set may be read, but only those every set
	# groups by make a table's primary key grouped.
	common_keys = keys_of(every)
	covered = rels.keep_if(
		|r|
			match r.source {
				Ok(table) if !table.primary_key.is_empty() and r.columns != Unknown => table.primary_key.all(|col| common_keys.contains((r.alias, col)))
				_ => Bool.False
			},
	).map(|r| r.alias)
	partial = all.drop_if(|e| every.any(|c| Node.equal(c, e)))
	{
		group: Group({ exprs: all, keys: keys_of(all), covered, partial }),
		empty: !items.is_empty() and items.all(|i| i.empty),
	}
}

## What one `group by` item groups by, as `expand_grouping_sets` expands
## it: every expression a set of it holds, those all its sets hold, and
## whether one of its sets is empty. `rollup` and `cube` always have the
## empty set among theirs.
grouping_sets : Node, (Node -> Node) -> { all : List(Node), every : List(Node), empty : Bool }
grouping_sets = |item, item_expr|
	match item {
		GroupingSet(g) => {
			parts = g.content.map(|part| grouping_sets(part, item_expr))
			all = parts.fold([], |acc, p| acc.concat(p.all))
			if g.kind == Enums.grouping_set_empty {
				{ all: [], every: [], empty: Bool.True }
			} else if g.kind == Enums.grouping_set_simple {
				{ all, every: all, empty: g.content.is_empty() }
			} else if g.kind == Enums.grouping_set_sets {
				every =
					match parts.first() {
						Ok(first) => first.every.keep_if(|e| parts.all(|p| p.every.any(|c| Node.equal(c, e))))
						Err(_) => []
					}
				{ all, every, empty: parts.any(|p| p.empty) }
			} else {
				{ all, every: [], empty: Bool.True }
			}
		}
		_ => {
			expr = item_expr(item)
			{ all: [expr], every: [expr], empty: Bool.False }
		}
	}

has_column_named : List(Rel), Str -> Bool
has_column_named = |rels, name| rels.any(|r| visible_names(r).contains(name))

## An `order by`, `group by` or `distinct on` item, which may also name an
## output column by its alias, or one by its position.
output_ref : Node, List(Str), List(Rel), Env -> Typed
output_ref = |item, aliases, rels, env| {
	inner =
		match item {
			SortBy(sort) => sort.node
			_ => item
		}
	match inner {
		ColumnRef({ fields: [only], .. }) if aliases.contains(string_of(only) ?? "") => leaf(unknown_output)
		AConst(_) => { ..typed(inner, rels, env), ungrouped: [] }
		_ => typed(inner, rels, env)
	}
}

## The relations of a `from` list.
from_list : List(Node), Env -> { rels : List(Rel), problems : List(Str) }
from_list = |items, env| {
	var $rels = []
	var $problems = []
	for item in items {
		# A lateral item can read the relations before it.
		{ rels, problems } = from_item(item, { ..env, outer: $rels.concat(env.outer) })
		$rels = $rels.concat(rels)
		$problems = $problems.concat(problems)
	}
	{ rels: $rels, problems: $problems }
}

from_item : Node, Env -> { rels : List(Rel), problems : List(Str) }
from_item = |node, env|
	match node {
		RangeVar(r) => {
			found = table_columns(r, env)
			{ rels: [{ ..aliased(r.relname ?? "", found.columns, r.alias), source: found.source }], problems: found.problems }
		}
		RangeSubselect(r) => {
			result = statement(r.subquery, env)
			{ rels: [aliased("(subquery)", result.outputs, r.alias)], problems: result.problems }
		}
		RangeFunction(r) => range_function(r, env)
		RangeTableSample(t) => {
			sampled = from_item(t.relation, env)
			{ ..sampled, problems: sampled.problems.concat(t.args.concat([t.repeatable]).fold([], |acc, e| acc.concat(expression_problems(e, [], env)))) }
		}
		RangeTableFunc(t) => {
			# xmltable(...): its columns are declared, NULL unless `not null`.
			columns = t.columns.keep_oks(
				|c|
					match c {
						RangeTableFuncCol(col) =>
							Ok(
								if col.for_ordinality {
									{ name: col.colname ?? "", type: Known("integer"), nullable: No }
								} else {
									{ name: col.colname ?? "", type: type_of(col.type_name), nullable: if col.is_not_null No else Yes }
								},
							)
						_ => Err(NotAColumn)
					},
			)
			exprs = [t.docexpr, t.rowexpr].concat(t.namespaces).concat(
				t.columns.fold(
					[],
					|acc, c|
						match c {
							RangeTableFuncCol(col) => acc.concat([col.colexpr, col.coldefexpr])
							_ => acc
						},
				),
			)
			{ rels: [aliased("xmltable", Known(columns), t.alias)], problems: exprs.fold([], |acc, e| acc.concat(expression_problems(e, [], env))) }
		}
		JsonTable(j) => {
			problems = [j.context_item].concat(j.passing).fold([], |acc, e| acc.concat(expression_problems(e, [], env)))
			{ rels: [aliased("json_table", Known(json_table_columns(j.columns)), j.alias)], problems }
		}
		JoinExpr(j) => join(j, env)
		# A relation this does not read still has a name, and columns that
		# are not known.
		_ => { rels: [aliased("?", Unknown, Null)], problems: [] }
	}

## A function in `from`, or several in `rows from (...)`. A function that
## returns one column of a scalar type gives a column named after the
## alias, or after the function without one. One that returns a record
## takes its columns from a column definition list, `as t(a int, b text)`.
## `with ordinality` adds a column that counts the rows.
range_function : Node.RangeFunction, Env -> { rels : List(Rel), problems : List(Str) }
range_function = |r, env| {
	parts = r.functions.map(
		|f|
			match f {
				NodeList([c, NodeList(defs), ..]) => (c, defs)
				NodeList([c, ..]) => (c, [])
				other => (other, [])
			},
	)
	func_name = |node|
		match node {
			FuncCall(f) => names_of(f.funcname).last() ?? "?"
			_ => "?"
		}
	name = parts.first().map_ok(|(c, _)| func_name(c)) ?? "?"
	single = parts.len() == 1
	walked = parts.map(
		|(c, defs)| {
			found =
				match c {
					FuncCall(f) => call(f, [], env)
					other => { typed: typed(other, [], env), choice: Err(NoChoice) }
				}
			declared = if single and defs.is_empty() r.coldeflist else defs
			columns =
				if !declared.is_empty() {
					Known(
						declared.keep_oks(
							|d|
								match d {
									ColumnDef(col) => Ok({ name: col.colname ?? "", type: type_of(col.type_name), nullable: Unknown })
									_ => Err(NotAColumn)
								},
						),
					)
				} else {
					match found.choice {
						Ok({ outputs: [_, ..] as outputs, .. }) => Known(outputs.map(|o| { name: o.name, type: Known(o.type), nullable: Unknown }))
						# A function that returns a table's row type, as `returns setof t`.
						Ok({ result: Known(type), .. }) if row_type_columns(type, env) != Unknown => row_type_columns(type, env)
						Ok({ result: Known(type), .. }) if Overload.category(type, env.enums) != 'C' => {
							column =
								match r.alias {
									Alias(a) if single => a.aliasname ?? name
									_ => func_name(c)
								}
							Known([{ name: column, type: Known(type), nullable: Unknown }])
						}
						_ => Unknown
					}
				}
			{ columns, problems: found.typed.problems }
		},
	)
	problems = walked.fold([], |acc, w| acc.concat(w.problems))
	columns =
		if walked.all(|w| w.columns != Unknown) {
			counted = if r.ordinality [{ name: "ordinality", type: Known("bigint"), nullable: No }] else []
			Known(walked.fold([], |acc, w| acc.concat(known_list(w.columns))).concat(counted))
		} else {
			Unknown
		}
	{ rels: [aliased(name, columns, r.alias)], problems }
}

## The columns of the table or view whose row type `type` is.
row_type_columns : Str, Env -> Cols
row_type_columns = |type, env|
	match env.catalog.table(type) {
		Ok({ columns: Known(columns), .. }) => Known(columns.map(|c| { name: c.name, type: Known(c.type), nullable: Unknown }))
		_ => Unknown
	}

## The columns of `json_table(... columns (...))`, those of nested paths
## among them. A value the path does not find is NULL.
json_table_columns : List(Node) -> List(Check.Output)
json_table_columns = |columns|
	columns.fold(
		[],
		|acc, c|
			match c {
				JsonTableColumn(col) =>
					if col.coltype == Enums.jtc_nested {
						acc.concat(json_table_columns(col.columns))
					} else if col.coltype == Enums.jtc_for_ordinality {
						acc.append({ name: col.name ?? "", type: Known("integer"), nullable: No })
					} else {
						acc.append({ name: col.name ?? "", type: type_of(col.type_name), nullable: if col.coltype == Enums.jtc_exists Unknown else Yes })
					}
				_ => acc
			},
	)

## A relation named `table`, or after its alias, with the alias's column
## names.
aliased : Str, Cols, Node -> Rel
aliased = |table, columns, alias|
	match alias {
		Alias(a) => { alias: a.aliasname ?? table, table, columns: rename(columns, names_of(a.colnames)), nullable: Bool.False, hidden: [], not_null: [], source: Err(NotATable) }
		_ => { alias: table, table, columns, nullable: Bool.False, hidden: [], not_null: [], source: Err(NotATable) }
	}

## Both sides of a join, marked NULL where an outer join can make them so.
join : Node.JoinExpr, Env -> { rels : List(Rel), problems : List(Str) }
join = |j, env| {
	left = from_item(j.larg, env)
	right = from_item(j.rarg, { ..env, outer: left.rels.concat(env.outer) })
	merged =
		if j.is_natural {
			left_names = left.rels.fold([], |acc, r| acc.concat(visible_names(r)))
			right.rels.fold([], |acc, r| acc.concat(visible_names(r))).keep_if(|n| left_names.contains(n))
		} else {
			names_of(j.using_clause)
		}
	hide = |rels| rels.map(|r| { ..r, hidden: r.hidden.concat(merged) })
	nulled = |rels| rels.map(|r| { ..r, nullable: Bool.True })
	# A merged column is the right side's in a right join, the left side's
	# otherwise.
	rels =
		if j.jointype == Enums.join_left {
			left.rels.concat(nulled(hide(right.rels)))
		} else if j.jointype == Enums.join_full {
			nulled(left.rels).concat(nulled(hide(right.rels)))
		} else if j.jointype == Enums.join_right {
			nulled(hide(left.rels)).concat(right.rels)
		} else {
			left.rels.concat(hide(right.rels))
		}
	problems = left.problems.concat(right.problems).concat(expression_problems(j.quals, rels, env))
	{ rels, problems }
}

## A table's columns from the query's CTEs or the catalog, and the
## catalog's table. A name with a schema is that schema's table, one
## without is a CTE or the table of the first schema on the search path
## that has one, as `RangeVarGetRelid` finds it. An unknown name is a
## problem only when the catalog has tables to compare with.
table_columns : Node.RangeVar, Env -> { columns : Cols, source : Try(Catalog.Table, [NotATable]), problems : List(Str) }
table_columns = |r, env| {
	name = r.relname ?? ""
	schema =
		match r.schemaname {
			Ok(s) => Qualified(s)
			Err(_) => Unqualified
		}
	cte = if schema == Unqualified env.ctes.find_first(|c| c.name == name) else Err(NotFound)
	match cte {
		Ok(found) => { columns: found.columns, source: Err(NotATable), problems: [] }
		Err(_) =>
			match env.catalog.find_table(schema, name) {
				Ok(table) => {
					columns =
						match table.columns {
							Known(defined) => Known(defined.map(|c| { name: c.name, type: Known(c.type), nullable: if c.not_null No else Yes }))
							View(view) => {
								# A view's columns are what its query returns. Problems inside it
								# are not this query's.
								result = statement(view.query, { ..env, ctes: [], outer: [], params: [], grouped: Bool.False })
								rename(result.outputs, view.aliases)
							}
							Unknown => Unknown
						}
					{ columns, source: Ok(table), problems: [] }
				}
				Err(_) =>
					if env.catalog.is_none() {
						{ columns: Unknown, source: Err(NotATable), problems: [] }
					} else {
						{ columns: Unknown, source: Err(NotATable), problems: [missing_table(schema, name, env)] }
					}
			}
	}
}

## "table `x` does not exist in the schema", with the closest name of a
## table it could have meant.
missing_table : [Qualified(Str), Unqualified], Str, Env -> Str
missing_table = |schema, name, env|
	match schema {
		Qualified(s) => {
			names = env.catalog.tables().keep_if(|t| t.schema == s).map(|t| t.name)
			"table `${s}.${name}` does not exist in the schema${Check.suggestion(name, names)}"
		}
		Unqualified => {
			path = env.catalog.search_path()
			names = env.catalog.tables().keep_if(|t| path.contains(t.schema)).map(|t| t.name).concat(env.ctes.map(|c| c.name))
			elsewhere = env.catalog.tables().keep_if(|t| t.name == name).map(|t| "${t.schema}.${t.name}")
			hint =
				match elsewhere {
					[first, ..] => " (did you mean `${first}`? Its schema is not on the search path)"
					[] => Check.suggestion(name, names)
				}
			"table `${name}` does not exist in the schema${hint}"
		}
	}

## The outputs of a select or `returning` list, with what its items found.
Targets : { outputs : Cols, problems : List(Str), aggregate : Bool, ungrouped : List(Str) }

## The outputs of a select or `returning` list.
target_list : List(Node), List(Rel), Env -> Targets
target_list = |items, rels, env|
	items.fold(
		{ outputs: Known([]), problems: [], aggregate: Bool.False, ungrouped: [] },
		|acc, target| {
			item = target_item(target, rels, env)
			outputs =
				match (acc.outputs, item.outputs) {
					(Known(so_far), Known(more)) => Known(so_far.concat(more))
					_ => Unknown
				}
			{ outputs, problems: acc.problems.concat(item.problems), aggregate: acc.aggregate or item.aggregate, ungrouped: acc.ungrouped.concat(item.ungrouped) }
		},
	)

## One item of a select list, which `*` and `alias.*` expand into many.
target_item : Node, List(Rel), Env -> Targets
target_item = |target, rels, env| {
	columns = |outputs, problems| { outputs, problems, aggregate: Bool.False, ungrouped: [] }
	match target {
		ResTarget(t) =>
			match star_of(t.val) {
				Ok(AllRels) => {
					all = rels.map(rel_outputs)
					if all.all(|o| o != Unknown) {
						columns(Known(all.fold([], |acc, o| acc.concat(known_list(o)))), [])
					} else {
						columns(Unknown, [])
					}
				}
				Ok(OneRel(alias)) =>
					match find_rel(rels.concat(env.outer), alias) {
						Ok(rel) => columns(rel_outputs(rel), [])
						Err(_) => columns(Unknown, ["`${alias}.*` names no table of the query"])
					}
				Err(_) => {
					value = typed(t.val, rels, env)
					named =
						match t.name {
							Ok(name) => { ..value.output, name }
							Err(_) => value.output
						}
					{ outputs: Known([named]), problems: value.problems, aggregate: value.aggregate, ungrouped: value.ungrouped }
				}
			}
		_ => columns(Unknown, [])
	}
}

## `*` for every relation, or `alias.*` for one.
star_of : Node -> Try([AllRels, OneRel(Str)], [NotAStar])
star_of = |node|
	match node {
		ColumnRef(c) =>
			match c.fields {
				[AStar(_)] => Ok(AllRels)
				[.., qualifier, AStar(_)] =>
					match string_of(qualifier) {
						Ok(alias) => Ok(OneRel(alias))
						Err(_) => Err(NotAStar)
					}
				_ => Err(NotAStar)
			}
		_ => Err(NotAStar)
	}

## The columns of a relation as outputs, without those a join merged away.
rel_outputs : Rel -> Cols
rel_outputs = |rel|
	match rel.columns {
		Known(list) => Known(list.drop_if(|o| rel.hidden.contains(o.name)).map(|o| rel_column(rel, o)))
		Unknown => Unknown
	}

## A column of a relation as the query sees it: NULL where an outer join
## can make it so, and not NULL where the `where` clause rules NULL out.
rel_column : Rel, Check.Output -> Check.Output
rel_column = |rel, column|
	if rel.not_null.contains(column.name) {
		{ ..column, nullable: No }
	} else if rel.nullable {
		{ ..column, nullable: Yes }
	} else {
		column
	}

## The columns a `where` clause keeps only rows where they are not NULL:
## the operand of `is not null`, and a column a comparison, `= any`, `in`,
## `like`, `similar` or `between` reads directly, in conditions joined by
## `and`. Those operators are NULL for a NULL operand, which `where` drops.
## Not `all`, which is true for an empty array whatever it compares.
not_null_refs : Node -> List(Node.ColumnRef)
not_null_refs = |node| {
	direct = |operands|
		operands.keep_oks(
			|operand|
				match operand {
					ColumnRef(c) => Ok(c)
					_ => Err(NotAColumn)
				},
		)
	match node {
		BoolExpr(b) if b.boolop == Enums.and_expr => b.args.fold([], |acc, arg| acc.concat(not_null_refs(arg)))
		NullTest(t) if t.nulltesttype == Enums.is_not_null => direct([t.arg])
		AExpr(a) =>
			if a.kind == Enums.aexpr_op and comparison_ops.contains(op_name(a)) {
				direct([a.lexpr, a.rexpr])
			} else if [Enums.aexpr_op_any, Enums.aexpr_in, Enums.aexpr_like, Enums.aexpr_ilike, Enums.aexpr_similar].contains(a.kind) {
				direct([a.lexpr])
			} else if a.kind >= Enums.aexpr_between and a.kind <= Enums.aexpr_not_between_sym {
				direct([a.lexpr])
			} else {
				[]
			}
		_ => []
	}
}

## The relations with the columns `where` rules NULL out marked.
narrowed : List(Rel), Node -> List(Rel)
narrowed = |rels, where_clause|
	not_null_refs(where_clause).fold(
		rels,
		|acc, c|
			match column_ref(c) {
				Ok(ref) =>
					match owner(ref, acc) {
						Ok(rel) => acc.map(|r| if r.alias == rel.alias { ..r, not_null: r.not_null.append(ref.name) } else r)
						Err(_) => acc
					}
				Err(_) => acc
			},
	)

known_list : Cols -> List(Check.Output)
known_list = |outputs|
	match outputs {
		Known(list) => list
		Unknown => []
	}

visible_names : Rel -> List(Str)
visible_names = |rel| known_list(rel.columns).map(|c| c.name).drop_if(|name| rel.hidden.contains(name))

unknown_output : Check.Output
unknown_output = { name: "?column?", type: Unknown, nullable: Unknown }

## A row constructor, which is never NULL itself.
row_output : Check.Output
row_output = { ..unknown_output, name: "row", nullable: No }

## The problems in an expression. See [Typed].
expression_problems : Node, List(Rel), Env -> List(Str)
expression_problems = |node, rels, env| typed(node, rels, env).problems

## Walk an expression once. The name in its output is the one Postgres
## gives a result column that has no alias.
typed : Node, List(Rel), Env -> Typed
typed = |node, rels, env| grouped_by(walk(node, rels, env), node, env)

## What the select's grouping makes of `node`, which the walk found
## `walked`.
grouped_by : Typed, Node, Env -> Typed
grouped_by = |walked, node, env|
	match env.group {
		# An expression the select groups by may be read whole. It is NULL in
		# the rows of a grouping set that leaves it out.
		Group(g) if g.exprs.any(|e| Node.equal(e, node)) =>
			if g.partial.any(|e| Node.equal(e, node)) {
				{ ..walked, output: { ..walked.output, nullable: Yes }, ungrouped: [] }
			} else {
				{ ..walked, ungrouped: [] }
			}
		_ => walked
	}

walk : Node, List(Rel), Env -> Typed
walk = |node, rels, env| {
	sub = |child| typed(child, rels, env)
	subs = |children| children.map(sub)
	match node {
		ColumnRef(c) =>
			match column_ref(c) {
				Ok(ref) => {
					lookup = resolve(ref, rels, env)
					output =
						match lookup {
							Found(found) => { ..found, name: ref.name }
							_ => { ..unknown_output, name: ref.name }
						}
					problems =
						match lookup {
							Missing(problem) => [problem]
							_ => []
						}
					{ ..leaf(output), problems, ungrouped: ungrouped_column(ref, rels, env) }
				}
				Err(_) => leaf(unknown_output)
			}
		ParamRef(_) => { ..leaf(unknown_output), arg: Untyped }
		AConst(c) =>
			if c.isnull {
				{ ..leaf({ ..unknown_output, nullable: Yes }), arg: Untyped }
			} else {
				value = leaf({ ..unknown_output, type: const_type(c.val), nullable: No })
				match c.val {
					String(_) => { ..value, arg: Untyped }
					_ => value
				}
			}
		TypeCast(t) => {
			inner = sub(t.arg)
			name = if inner.output.name == "?column?" type_last_name(t.type_name) else inner.output.name
			value = over({ name, type: type_of(t.type_name), nullable: inner.output.nullable }, [inner])
			{ ..value, problems: cast_param_problems(t, env).concat(inner.problems) }
		}
		CollateClause(c) => {
			inner = sub(c.arg)
			over(inner.output, [inner])
		}
		FuncCall(f) => call(f, rels, env).typed
		SubLink(s) => sublink(s, rels, env)
		CoalesceExpr(c) => {
			args = subs(c.args)
			shared = shared_type("COALESCE", args.map(|a| a.arg), env)
			adding(over({ name: "coalesce", type: shared.type, nullable: first_non_null(args.map(|a| a.output)) }, args), shared.problems)
		}
		MinMaxExpr(m) => {
			args = subs(m.args)
			greatest = m.op == Enums.is_greatest
			name = if greatest "greatest" else "least"
			shared = shared_type(if greatest "GREATEST" else "LEAST", args.map(|a| a.arg), env)
			adding(over({ name, type: shared.type, nullable: first_non_null(args.map(|a| a.output)) }, args), shared.problems)
		}
		CaseExpr(c) => {
			arms = c.args.map(
				|arm|
					match arm {
						CaseWhen(w) => { condition: sub(w.expr), result: Ok(sub(w.result)) }
						other => { condition: sub(other), result: Err(NotAnArm) }
					},
			)
			otherwise = sub(c.defresult)
			results = arms.keep_oks(|arm| arm.result)
			default_output = if c.defresult == Null { ..unknown_output, nullable: Yes } else otherwise.output
			all = results.map(|r| r.output).append(default_output)
			# The default comes first in picking the type, as in Postgres.
			default_arg = if c.defresult == Null Untyped else otherwise.arg
			shared = shared_type("CASE", [default_arg].concat(results.map(|r| r.arg)), env)
			# A branch that reads a column that can be NULL may only run when it
			# is not, as in `case when x is null then 0 else x end`. So only a
			# bare NULL, or no `else`, makes the case NULL for sure.
			nullable =
				if all.all(|o| o.nullable == No) {
					No
				} else if all.any(|o| o.nullable == Yes and o.type == Unknown) {
					Yes
				} else {
					Unknown
				}
			children = [sub(c.arg)].concat(arms.fold([], |acc, arm| acc.append(arm.condition).concat(arm.result.map_ok(|r| [r]) ?? []))).append(otherwise)
			adding(over({ name: "case", type: shared.type, nullable }, children), shared.problems)
		}
		AArrayExpr(a) => {
			elements = subs(a.elements)
			shared = if elements.is_empty() { type: Unknown, problems: [] } else shared_type("ARRAY", elements.map(|e| e.arg), env)
			# An array of arrays has more dimensions, not another type.
			type =
				match shared.type {
					Known(t) => Known(if t.ends_with("[]") t else "${t}[]")
					Unknown => Unknown
				}
			adding(over({ ..unknown_output, name: "array", type, nullable: No }, elements), shared.problems)
		}
		RowExpr(r) => over(row_output, subs(r.args))
		AExpr(a) => operator(a, rels, env)
		BoolExpr(b) => {
			args = subs(b.args)
			over({ ..unknown_output, type: Known("boolean"), nullable: all_not_null(args.map(|a| a.output)) }, args)
		}
		NullTest(t) => over({ ..unknown_output, type: Known("boolean"), nullable: No }, [sub(t.arg)])
		BooleanTest(t) => over({ ..unknown_output, type: Known("boolean"), nullable: No }, [sub(t.arg)])
		SQLValueFunction(v) => leaf(sql_value_output(v))
		GroupingFunc(g) => { ..over({ name: "grouping", type: Known("integer"), nullable: No }, subs(g.args)), ungrouped: [] }
		NamedArgExpr(n) => over(unknown_output, [sub(n.arg)])
		NodeList(items) => over(unknown_output, subs(items))
		CaseWhen(w) => over(unknown_output, [sub(w.expr), sub(w.result)])
		AIndirection(i) => over(unknown_output, [sub(i.arg)].concat(subs(i.indirection)))
		AIndices(i) => over(unknown_output, [sub(i.lidx), sub(i.uidx)])
		SortBy(s) => over(unknown_output, [sub(s.node)])
		WindowDef(w) => over(unknown_output, subs(w.partition_clause.concat(w.order_clause).concat([w.start_offset, w.end_offset])))
		ResTarget(t) => over(unknown_output, [sub(t.val)])
		MultiAssignRef(m) => over(unknown_output, [sub(m.source)])
		GroupingSet(g) => over(unknown_output, subs(g.content))
		JsonValueExpr(v) => over(unknown_output, [sub(v.raw_expr)])
		_ => leaf(unknown_output)
	}
}

## An expression with nothing under it.
leaf : Check.Output -> Typed
leaf = |output| { output, arg: type_arg(output.type), problems: [], aggregate: Bool.False, ungrouped: [] }

## An expression over `children`, with what they found.
over : Check.Output, List(Typed) -> Typed
over = |output, children| {
	output,
	arg: type_arg(output.type),
	problems: children.fold([], |acc, c| acc.concat(c.problems)),
	aggregate: children.any(|c| c.aggregate),
	ungrouped: children.fold([], |acc, c| acc.concat(c.ungrouped)),
}

## An expression of `type` as an argument for picking a function or
## operator.
type_arg : [Known(Str), Unknown] -> Overload.Arg
type_arg = |type|
	match type {
		Known(t) => Known(t)
		Unknown => Unsure
	}

## A column reference, as written, when the select groups and does not
## group by it or its table's primary key.
ungrouped_column : Ref, List(Rel), Env -> List(Str)
ungrouped_column = |ref, rels, env|
	match env.group {
		Group(g) =>
			match owner(ref, rels) {
				Ok(rel) if !g.keys.contains((rel.alias, ref.name)) and !g.covered.contains(rel.alias) =>
					match ref.qualifier {
						Some(q) => ["${q}.${ref.name}"]
						None => [ref.name]
					}
				_ => []
			}
		NoGroup => []
	}

## The type of a constant. An integer too big for `integer` is a `Float`
## node in the raw tree.
const_type : Node -> [Known(Str), Unknown]
const_type = |val|
	match val {
		Integer(_) => Known("integer")
		Float(f) => {
			text = f.fval ?? ""
			if text.contains(".") or text.contains("e") or text.contains("E") Known("numeric") else Known("bigint")
		}
		String(_) => Known("text")
		Boolean(_) => Known("boolean")
		_ => Unknown
	}

## The type values must share in `context`, such as `CASE` or `UNION`, and
## the server's refusal when they have none. See [Overload.common]. One
## that does not convert is refused only when no extension could bring a
## cast for it.
shared_type : Str, List(Overload.Arg), Env -> { type : [Known(Str), Unknown], problems : List(Str) }
shared_type = |context, args, env|
	match Overload.common(args.map(|a| base_arg(a, env)), env.enums) {
		Ok(t) => { type: Known(t), problems: [] }
		Err(Mismatch(a, b)) => { type: Unknown, problems: ["${context} types ${a} and ${b} cannot be matched"] }
		Err(NoConversion(from, to)) => { type: Known(to), problems: if refuses_calls(env) ["${context} could not convert type ${from} to ${to}"] else [] }
		Err(Unsure) => { type: Unknown, problems: [] }
	}

## `value` with more problems of its own, before those under it.
adding : Typed, List(Str) -> Typed
adding = |value, problems| { ..value, problems: problems.concat(value.problems) }

## `coalesce`, `greatest` and `least` are NULL only when every argument is.
first_non_null : List(Check.Output) -> [Yes, No, Unknown]
first_non_null = |args|
	if args.any(|a| a.nullable == No) {
		No
	} else if args.all(|a| a.nullable == Yes) {
		Yes
	} else {
		Unknown
	}

all_not_null : List(Check.Output) -> [Yes, No, Unknown]
all_not_null = |args| if args.all(|a| a.nullable == No) No else Unknown

comparison_ops = ["=", "<>", "!=", "<", ">", "<=", ">="]

## An operator, `any`, `all`, `in`, `like`, `between`, `nullif` and `is
## [not] distinct from`.
operator : Node.AExpr, List(Rel), Env -> Typed
operator = |a, rels, env| {
	# A row compares field by field, so what its fields can be decides.
	operand = |node|
		match node {
			RowExpr(r) => {
				fields = r.args.map(|arg| typed(arg, rels, env))
				{ value: grouped_by(over(row_output, fields), node, env), fields: fields.map(|f| f.output) }
			}
			_ => {
				value = typed(node, rels, env)
				{ value, fields: [value.output] }
			}
		}
	side = |node|
		match node {
			Null => []
			NodeList(items) => items.map(operand)
			other => [operand(other)]
		}
	left_sides = side(a.lexpr)
	right_sides = side(a.rexpr)
	lefts = left_sides.map(|o| o.value)
	rights = right_sides.map(|o| o.value)
	operands = lefts.concat(rights)
	outputs = operands.map(|o| o.output)
	fields = left_sides.concat(right_sides).fold([], |acc, o| acc.concat(o.fields))
	comparison = comparison_ops.contains(op_name(a))
	# A comparison is boolean whatever operator it picks, so the pick is
	# only needed to refuse one that nothing takes.
	choice = if a.kind == Enums.aexpr_op and (!comparison or refuses_calls(env)) operator_choice(a, lefts, rights, env) else Err(NoChoice)
	output =
		if a.kind == Enums.aexpr_nullif {
			# nullif(a, b)
			{ name: "nullif", type: lefts.first().map_ok(|l| l.output.type) ?? Unknown, nullable: Yes }
		} else if a.kind == Enums.aexpr_distinct or a.kind == Enums.aexpr_not_distinct {
			# is [not] distinct from
			{ ..unknown_output, type: Known("boolean"), nullable: No }
		} else if a.kind == Enums.aexpr_op_any or a.kind == Enums.aexpr_op_all {
			# An array can hold NULLs, which make the answer NULL when nothing
			# else decides it.
			{ ..unknown_output, type: Known("boolean"), nullable: Unknown }
		} else if a.kind != Enums.aexpr_op or comparison {
			# Comparisons, in, like, similar and between.
			{ ..unknown_output, type: Known("boolean"), nullable: all_not_null(fields) }
		} else {
			match choice {
				Ok(c) => { ..unknown_output, type: c.result, nullable: operator_nullable(c, outputs, env) }
				Err(_) => unknown_output
			}
		}
	value = over(output, operands)
	own = operator_call_problems(a, lefts, rights, choice, env).concat(in_problems(a, lefts, rights, env)).concat(comparison_problems(a, rels, env)).concat(operator_param_problems(a, lefts, rights, choice, env))
	{ ..value, problems: own.concat(value.problems) }
}

op_name : Node.AExpr -> Str
op_name = |a| names_of(a.name).last() ?? ""

## The argument of an operand list that holds one operand.
single_arg : List(Typed) -> Overload.Arg
single_arg = |operands|
	match operands {
		[only] => only.arg
		_ => Unsure
	}

## The operator the server would pick for `a`.
operator_choice : Node.AExpr, List(Typed), List(Typed), Env -> Try(Overload.Choice, Overload.Miss)
operator_choice = |a, lefts, rights, env|
	match a.lexpr {
		Null => Overload.operator(op_name(a), Prefix, base_arg(single_arg(rights), env), env.enums)
		_ => Overload.operator(op_name(a), Infix(base_arg(single_arg(lefts), env)), base_arg(single_arg(rights), env), env.enums)
	}

## A strict operator is NULL when an operand is. On numbers, strings,
## dates, times, intervals, booleans and bit strings it is not NULL
## otherwise: it fails instead, on an overflow say.
operator_nullable : Overload.Choice, List(Check.Output), Env -> [Yes, No, Unknown]
operator_nullable = |choice, operands, env| {
	total = |type|
		match type {
			Known(t) => ['N', 'S', 'D', 'T', 'B', 'V'].contains(Overload.category(t, env.enums))
			Unknown => Bool.False
		}
	if choice.strict and operands.any(|o| o.nullable == Yes) {
		Yes
	} else if choice.strict and operands.all(|o| o.nullable == No) and total(choice.result) and choice.params.all(|p| p != "" and total(Known(p))) {
		No
	} else {
		Unknown
	}
}

## The function the server would pick for `f`, whose arguments are `args`.
## Named arguments and `variadic` are left to the server.
function_choice : Node.FuncCall, List(Typed), Env -> Try(Overload.Choice, Overload.Miss)
function_choice = |f, args, env| {
	named =
		f.args.any(
			|arg|
				match arg {
					NamedArgExpr(_) => Bool.True
					_ => Bool.False
				},
		)
	if named or f.func_variadic {
		Err(NoChoice)
	} else {
		# A call that names a schema reaches only its functions, one that does
		# not those of the search path, after the built in ones.
		schema =
			match names_of(f.funcname) {
				[.., s, _] => Qualified(s)
				_ => Unqualified
			}
		builtins = schema == Unqualified or schema == Qualified("pg_catalog")
		Overload.function_from(names_of(f.funcname).last() ?? "", args.map(|a| base_arg(a.arg, env)), env.enums, builtins, env.catalog.functions_in(schema))
	}
}

## A function call, and the function the server would pick for it.
call : Node.FuncCall, List(Rel), Env -> { typed : Typed, choice : Try(Overload.Choice, Overload.Miss) }
call = |f, rels, env| {
	args = f.args.map(|arg| typed(arg, rels, env))
	rest = f.agg_order.concat([f.agg_filter, f.over]).map(|n| typed(n, rels, env))
	choice = function_choice(f, args, env)
	name = names_of(f.funcname).last() ?? "?column?"
	outputs = args.map(|a| a.output)
	output =
		match choice {
			Ok(c) => {
				nullable =
					match c.kind {
						Aggregate => aggregate_nullable(name, outputs, f, env)
						Window => window_nullable(name, outputs)
						Plain => function_nullable(name, c, outputs)
					}
				{ name, type: c.result, nullable }
			}
			Err(_) => { name, type: Unknown, nullable: Unknown }
		}
	value = over(output, args.concat(rest))
	aggregate_call =
		match choice {
			Ok({ kind: Aggregate, .. }) => f.over == Null
			_ => Bool.False
		}
	ungrouped =
		match choice {
			# A function this does not know could be an aggregate.
			Err(_) => []
			Ok(_) => if aggregate_call [] else value.ungrouped
		}
	problems = function_call_problems(f, args, choice, env).concat(function_param_problems(f, choice, env)).concat(value.problems)
	{ typed: { ..value, problems, aggregate: aggregate_call or value.aggregate, ungrouped }, choice }
}

## Functions that return NULL only for a NULL argument.
total_functions = ["abs", "age", "array_to_string", "ascii", "btrim", "cardinality", "ceil", "ceiling", "char_length", "character_length", "chr", "clock_timestamp", "date_part", "date_trunc", "exp", "extract", "floor", "gen_random_uuid", "initcap", "left", "length", "ln", "log", "lower", "lpad", "ltrim", "make_date", "md5", "mod", "now", "octet_length", "position", "power", "quote_ident", "quote_literal", "random", "repeat", "replace", "reverse", "right", "round", "rpad", "rtrim", "sign", "split_part", "sqrt", "statement_timestamp", "string_to_array", "strpos", "timezone", "to_char", "to_hex", "to_json", "to_jsonb", "transaction_timestamp", "trunc", "upper"]

## Functions that never return NULL.
never_null_functions = ["concat", "json_build_array", "json_build_object", "jsonb_build_array", "jsonb_build_object", "num_nonnulls", "num_nulls"]

function_nullable : Str, Overload.Choice, List(Check.Output) -> [Yes, No, Unknown]
function_nullable = |name, choice, args|
	if never_null_functions.contains(name) {
		No
	} else if choice.strict and args.any(|a| a.nullable == Yes) {
		Yes
	} else if total_functions.contains(name) and args.all(|a| a.nullable == No) {
		No
	} else {
		Unknown
	}

## Aggregates that gather their input into one value, never NULL for rows.
collecting_aggregates = ["array_agg", "json_agg", "jsonb_agg"]

## Aggregates that are NULL for no rows, or rows that are all NULL.
folding_aggregates = ["avg", "bit_and", "bit_or", "bit_xor", "bool_and", "bool_or", "every", "max", "min", "string_agg", "sum"]

## An aggregate sees no rows when the select has no `group by` and finds
## none, or when its `filter` keeps none. `count` counts them as 0, the
## others are NULL.
aggregate_nullable : Str, List(Check.Output), Node.FuncCall, Env -> [Yes, No, Unknown]
aggregate_nullable = |name, args, f, env| {
	folding = folding_aggregates.contains(name)
	collecting = collecting_aggregates.contains(name)
	windowed = f.over != Null
	if name == "count" or name == "regr_count" {
		No
	} else if !folding and !collecting {
		Unknown
	} else if folding and args.any(|a| a.nullable == Yes) {
		Yes
	} else if windowed {
		Unknown
	} else if !env.grouped or f.agg_filter != Null {
		Yes
	} else if collecting or args.all(|a| a.nullable == No) {
		No
	} else {
		Unknown
	}
}

window_nullable : Str, List(Check.Output) -> [Yes, No, Unknown]
window_nullable = |name, args|
	match name {
		"row_number" | "rank" | "dense_rank" | "percent_rank" | "cume_dist" | "ntile" => No
		# Without a default, lag and lead are NULL past the partition's edge.
		"lag" | "lead" => if args.len() < 3 Yes else Unknown
		_ => Unknown
	}

## A subquery in an expression, read once for its value and its problems.
sublink : Node.SubLink, List(Rel), Env -> Typed
sublink = |s, rels, env| {
	test = typed(s.testexpr, rels, env)
	result = statement(s.subselect, { ..env, outer: rels.concat(env.outer) })
	first =
		match result.outputs {
			Known([output, ..]) => output
			_ => unknown_output
		}
	output =
		if s.sub_link_type == Enums.exists_sublink {
			{ name: "exists", type: Known("boolean"), nullable: No }
		} else if s.sub_link_type == Enums.expr_sublink {
			# A scalar subquery is NULL when it finds no row.
			{ ..first, nullable: Yes }
		} else if s.sub_link_type == Enums.array_sublink {
			type =
				match first.type {
					Known(t) => Known("${t}[]")
					Unknown => Unknown
				}
			{ name: "array", type, nullable: No }
		} else {
			{ name: "?column?", type: Known("boolean"), nullable: Unknown }
		}
	# What the subquery reads is grouped or not in its own select.
	{ ..over(output, [test]), problems: test.problems.concat(result.problems), ungrouped: test.ungrouped }
}

sql_value_output : Node.SQLValueFunction -> Check.Output
sql_value_output = |v| {
	{ name, type } =
		if v.op == Enums.svfop_current_date {
			{ name: "current_date", type: "date" }
		} else if v.op == Enums.svfop_current_time or v.op == Enums.svfop_current_time_n {
			{ name: "current_time", type: "time with time zone" }
		} else if v.op == Enums.svfop_current_timestamp or v.op == Enums.svfop_current_timestamp_n {
			{ name: "current_timestamp", type: "timestamp with time zone" }
		} else if v.op == Enums.svfop_localtime or v.op == Enums.svfop_localtime_n {
			{ name: "localtime", type: "time without time zone" }
		} else if v.op == Enums.svfop_localtimestamp or v.op == Enums.svfop_localtimestamp_n {
			{ name: "localtimestamp", type: "timestamp without time zone" }
		} else if v.op == Enums.svfop_current_role {
			{ name: "current_role", type: "name" }
		} else if v.op == Enums.svfop_current_user {
			{ name: "current_user", type: "name" }
		} else if v.op == Enums.svfop_user {
			{ name: "user", type: "name" }
		} else if v.op == Enums.svfop_session_user {
			{ name: "session_user", type: "name" }
		} else if v.op == Enums.svfop_current_catalog {
			{ name: "current_catalog", type: "name" }
		} else {
			{ name: "current_schema", type: "name" }
		}
	# current_schema is NULL when the search path names no schema that exists.
	{ name, type: Known(type), nullable: if v.op == Enums.svfop_current_schema Unknown else No }
}

## The type a `TypeName` names, spelled like [Catalog] spells column types.
type_of : Node -> [Known(Str), Unknown]
type_of = |node|
	match Catalog.type_name(node) {
		"" => Unknown
		type => Known(type)
	}

## The last name of a `TypeName` as the grammar spells it (`int4`), which
## Postgres names a cast's column after.
type_last_name : Node -> Str
type_last_name = |node|
	match node {
		TypeName(t) => names_of(t.names).last() ?? "?column?"
		_ => "?column?"
	}

Ref : { qualifier : [None, Some(Str)], name : Str }

## A column reference: `col`, `alias.col`, `schema.table.col` or
## `db.schema.table.col`. Not `*`.
column_ref : Node.ColumnRef -> Try(Ref, [NotARef])
column_ref = |c|
	match c.fields.map(string_of) {
		[Ok(name)] => Ok({ qualifier: None, name })
		[.., Ok(qualifier), Ok(name)] => Ok({ qualifier: Some(qualifier), name })
		_ => Err(NotARef)
	}

## Find the column a reference names.
resolve : Ref, List(Rel), Env -> Lookup
resolve = |ref, rels, env|
	match ref.qualifier {
		Some(alias) =>
			match find_rel(rels, alias) {
				Ok(rel) => column_in(rel, ref.name)
				Err(_) =>
					match find_rel(env.outer, alias) {
						Ok(rel) => column_in(rel, ref.name)
						Err(_) => Unsure
					}
			}
		None => {
			matches = rels.keep_if(|r| visible_names(r).contains(ref.name))
			match matches {
				[one] => column_in(one, ref.name)
				[_, _, ..] => Missing("column `${ref.name}` is ambiguous: it is in ${Str.join_with(matches.map(|r| "`${r.alias}`"), " and ")}")
				[] =>
					# A bare relation name is a whole row, not a column.
					if rels.any(|r| r.columns == Unknown or r.alias == ref.name) {
						Unsure
					} else {
						outer = env.outer.keep_if(|r| visible_names(r).contains(ref.name))
						match outer {
							[first, ..] => column_in(first, ref.name)
							[] =>
								if rels.is_empty() or env.outer.any(|r| r.columns == Unknown or r.alias == ref.name) {
									Unsure
								} else {
									Missing("column `${ref.name}` does not exist in ${Str.join_with(rels.map(|r| "`${r.alias}`"), " or ")}${Check.suggestion(ref.name, rels.fold([], |acc, r| acc.concat(visible_names(r))))}")
								}
						}
					}
			}
		}
	}

find_rel : List(Rel), Str -> Try(Rel, [NotFound])
find_rel = |rels, alias| rels.find_first(|r| r.alias == alias)

column_in : Rel, Str -> Lookup
column_in = |rel, name|
	match rel.columns {
		Known(list) =>
			match list.find_first(|c| c.name == name) {
				Ok(col) => Found(rel_column(rel, col))
				Err(_) =>
					if rel.alias == rel.table {
						Missing("column `${name}` does not exist in `${rel.table}`${Check.suggestion(name, list.map(|c| c.name))}")
					} else {
						Missing("column `${rel.alias}.${name}` does not exist in `${rel.table}`${Check.suggestion(name, list.map(|c| c.name))}")
					}
			}
		Unknown => Unsure
	}

missing_column : Rel, Str -> Try(Str, [Exists])
missing_column = |rel, name|
	match column_in(rel, name) {
		Missing(problem) => Ok(problem)
		_ => Err(Exists)
	}

## Whether a call no function or operator takes is refused. Only with a
## schema that creates no extension: an extension brings functions,
## operators and casts this does not know, and without a schema the
## database may have functions of its own.
refuses_calls : Env -> Bool
refuses_calls = |env| !env.catalog.is_none() and env.catalog.extensions().is_empty()

## How an argument reads in a message: its type, or `unknown` for a string
## literal, NULL or a parameter.
arg_text : Overload.Arg -> Str
arg_text = |arg|
	match arg {
		Known(t) => t
		Untyped => "unknown"
		Unsure => "?"
	}

## A call of a function that does not exist, or that no function of its
## name takes.
function_call_problems : Node.FuncCall, List(Typed), Try(Overload.Choice, Overload.Miss), Env -> List(Str)
function_call_problems = |f, args, choice, env|
	if !refuses_calls(env) {
		[]
	} else {
		name = names_of(f.funcname).last() ?? ""
		match choice {
			Err(NoSuchName) => ["function `${name}` does not exist"]
			Err(NoMatch) => ["function `${name}(${Str.join_with(args.map(|arg| arg_text(arg.arg)), ", ")})` does not exist"]
			_ => []
		}
	}

## An operator between types no operator of its name takes, as in
## `text_col = int_col`.
operator_call_problems : Node.AExpr, List(Typed), List(Typed), Try(Overload.Choice, Overload.Miss), Env -> List(Str)
operator_call_problems = |a, lefts, rights, choice, env|
	if !refuses_calls(env) or a.kind != Enums.aexpr_op {
		[]
	} else {
		match choice {
			Err(NoMatch) | Err(NoSuchName) => {
				right = arg_text(single_arg(rights))
				written =
					match a.lexpr {
						Null => "${op_name(a)} ${right}"
						_ => "${arg_text(single_arg(lefts))} ${op_name(a)} ${right}"
					}
				["operator `${written}` does not exist"]
			}
			_ => []
		}
	}

## An item of `x in (...)` that no operator compares with `x`, as in
## `text_col in (1, 2)`. The server compares them one by one when they
## share no type.
in_problems : Node.AExpr, List(Typed), List(Typed), Env -> List(Str)
in_problems = |a, lefts, rights, env|
	if !refuses_calls(env) or a.kind != Enums.aexpr_in {
		[]
	} else {
		left = single_arg(lefts)
		rights.keep_oks(
			|item|
				match Overload.operator(op_name(a), Infix(base_arg(left, env)), base_arg(item.arg, env), env.enums) {
					Err(NoMatch) | Err(NoSuchName) => Ok("operator `${arg_text(left)} ${op_name(a)} ${arg_text(item.arg)}` does not exist")
					_ => Err(Fits)
				},
		)
	}

## Problems of parameter `p` where `what` takes `type`: the server gives
## the parameter that type, so its field must fit it.
param_type_problems : Node.ParamRef, Str, Str, Env -> List(Str)
param_type_problems = |p, type, what, env|
	match param_name(p, env) {
		Ok(name) =>
			match env.params.find_first(|q| q.name == name) {
				Ok(param) if type != "" and !param_fits(type, param.kind, env) => ["`$${name}` is `${param.kind}`, but ${what} takes `${type}` there"]
				_ => []
			}
		Err(_) => []
	}

## Problems of parameters that are operands of an operator other than a
## comparison with a column, which [comparison_problems] reads.
operator_param_problems : Node.AExpr, List(Typed), List(Typed), Try(Overload.Choice, Overload.Miss), Env -> List(Str)
operator_param_problems = |a, lefts, rights, choice, env|
	if env.params.is_empty() or a.kind != Enums.aexpr_op {
		[]
	} else if comparison_ops.contains(op_name(a)) {
		# A parameter compared with an expression of a known type.
		match (a.lexpr, a.rexpr) {
			(ParamRef(_), ColumnRef(_)) | (ColumnRef(_), ParamRef(_)) => []
			(ParamRef(p), _) => compared_param_problems(p, rights, a, env)
			(_, ParamRef(p)) => compared_param_problems(p, lefts, a, env)
			_ => []
		}
	} else {
		match choice {
			Ok(c) => {
				operands = if a.lexpr == Null [a.rexpr] else [a.lexpr, a.rexpr]
				List.map2(operands, c.params, |operand, type| (operand, type)).fold(
					[],
					|acc, (operand, type)|
						match operand {
							ParamRef(p) => acc.concat(param_type_problems(p, type, "`${op_name(a)}`", env))
							_ => acc
						},
				)
			}
			Err(_) => []
		}
	}

## A parameter compared with an expression of a known type takes it.
compared_param_problems : Node.ParamRef, List(Typed), Node.AExpr, Env -> List(Str)
compared_param_problems = |p, others, a, env|
	match others {
		[other] =>
			match other.output.type {
				Known(type) => param_type_problems(p, type, "`${op_name(a)}`", env)
				Unknown => []
			}
		_ => []
	}

## Problems of parameters passed to a function.
function_param_problems : Node.FuncCall, Try(Overload.Choice, Overload.Miss), Env -> List(Str)
function_param_problems = |f, choice, env|
	if env.params.is_empty() {
		[]
	} else {
		match choice {
			Ok(c) =>
				List.map2(f.args, c.params, |arg, type| (arg, type)).fold(
					[],
					|acc, (arg, type)|
						match arg {
							ParamRef(p) => acc.concat(param_type_problems(p, type, "`${c.name}`", env))
							_ => acc
						},
				)
			Err(_) => []
		}
	}

## Problems of a parameter cast to a type, as in `$x::integer`. A cast to a
## string type takes the text of any value.
cast_param_problems : Node.TypeCast, Env -> List(Str)
cast_param_problems = |t, env|
	match (t.arg, type_of(t.type_name)) {
		(ParamRef(p), Known(type)) if Overload.category(type, env.enums) != 'S' => param_type_problems(p, type, "the cast", env)
		_ => []
	}

comparison_problems : Node.AExpr, List(Rel), Env -> List(Str)
comparison_problems = |a, rels, env|
	if env.params.is_empty() {
		[]
	} else if a.kind == Enums.aexpr_op and comparison_ops.contains(op_name(a)) {
		match (a.lexpr, a.rexpr) {
			(ColumnRef(c), ParamRef(p)) => column_param_problems(c, p, Scalar, rels, env)
			(ParamRef(p), ColumnRef(c)) => column_param_problems(c, p, Scalar, rels, env)
			_ => []
		}
	} else if a.kind == Enums.aexpr_op_any or a.kind == Enums.aexpr_op_all {
		match (a.lexpr, a.rexpr) {
			(ColumnRef(c), ParamRef(p)) => column_param_problems(c, p, Array, rels, env)
			_ => []
		}
	} else if a.kind == Enums.aexpr_in or (a.kind >= Enums.aexpr_between and a.kind <= Enums.aexpr_not_between_sym) {
		match (a.lexpr, a.rexpr) {
			(ColumnRef(c), NodeList(items)) =>
				items.fold(
					[],
					|acc, item|
						match item {
							ParamRef(p) => acc.concat(column_param_problems(c, p, Scalar, rels, env))
							_ => acc
						},
				)
			_ => []
		}
	} else {
		[]
	}

## Problems of parameter `p` compared with the column `c` names, as a value
## or, in `any(...)`, as an array of values.
column_param_problems : Node.ColumnRef, Node.ParamRef, [Scalar, Array], List(Rel), Env -> List(Str)
column_param_problems = |c, p, shape, rels, env|
	match (column_ref(c), param_name(p, env)) {
		(Ok(ref), Ok(name)) =>
			match resolve(ref, rels, env) {
				Found(column) =>
					match shape {
						Scalar => param_problems(name, ref.name, column, Bool.False, env)
						Array => array_param_problems(name, ref.name, column, env)
					}
				_ => []
			}
		_ => []
	}

## The name of the parameter at `p`'s location.
param_name : Node.ParamRef, Env -> Try(Str, [NotFound])
param_name = |p, env| env.names.find_first(|n| n.at == p.location).map_ok(|n| n.name)

## Problems of parameter `name` meeting `column`: a type it does not fit,
## and, when the value is stored in the column, NULL where the column takes
## none.
param_problems : Str, Str, Check.Output, Bool, Env -> List(Str)
param_problems = |name, column_name, column, stored, env|
	match env.params.find_first(|p| p.name == name) {
		Ok(param) => {
			type_problem =
				match column.type {
					Known(type) if !param_fits(type, param.kind, env) => ["column `${column_name}` is `${type}`, but `$${name}` is `${param.kind}`"]
					_ => []
				}
			null_problem =
				if stored and param.nullable and column.nullable == No {
					["column `${column_name}` is NOT NULL, but `$${name}` is `Try(${param.kind}, [Null])`"]
				} else {
					[]
				}
			type_problem.concat(null_problem)
		}
		Err(_) => []
	}

## Problems of parameter `name` in `column = any($name)`, which needs a list
## of values that fit the column.
array_param_problems : Str, Str, Check.Output, Env -> List(Str)
array_param_problems = |name, column_name, column, env|
	match (env.params.find_first(|p| p.name == name), column.type) {
		(Ok(param), Known(type)) if !param_fits("${type}[]", param.kind, env) => ["column `${column_name}` is `${type}`, so `$${name}` must be a list of it, but it is `${param.kind}`"]
		_ => []
	}

## Whether a parameter that encodes as `kind` fits where the server takes
## `type`: the type holds every value of it (see [PgType.column_holds]).
param_fits : Str, Str, Env -> Bool
param_fits = |type, kind, env| PgType.column_holds(base_in(env.catalog, type), values_in(env.catalog, type), kind)

## The target of an insert, update or delete.
target_rel : Node, Env -> { rel : Rel, problems : List(Str) }
target_rel = |node, env|
	match node {
		RangeVar(r) => {
			found = table_columns(r, { ..env, ctes: [] })
			{ rel: { ..aliased(r.relname ?? "", found.columns, r.alias), source: found.source }, problems: found.problems }
		}
		_ => { rel: aliased("?", Unknown, Null), problems: [] }
	}

## A `returning` list over `rels`, the first of which is the target. `old`
## and `new`, or the names `with (old as o, new as n)` gives them, are the
## target's row before and after: NULL for a row that was not there
## before, as an insert's, or is not after, as a delete's.
returning_list : Node, List(Rel), { old_absent : Bool, new_absent : Bool }, Env -> Check.Result
returning_list = |node, rels, absent, env|
	match node {
		ReturningClause(r) => {
			named = |option, default|
				r.options.keep_oks(
					|o|
						match o {
							ReturningOption(ro) if ro.option == option => ro.value.map_err(|_| NoName)
							_ => Err(NoName)
						},
				).first() ?? default
			versions =
				match rels.first() {
					Ok(target) => [
						{ ..target, alias: named(Enums.returning_option_old, "old"), nullable: absent.old_absent, not_null: [] },
						{ ..target, alias: named(Enums.returning_option_new, "new"), nullable: absent.new_absent, not_null: [] },
					]
					Err(_) => []
				}
			# Only a qualified reference or `old.*` reads them, as one reads the
			# relations of an outer query.
			{ outputs, problems, .. } = target_list(r.exprs, rels, { ..env, outer: versions.concat(env.outer) })
			{ outputs, problems }
		}
		_ => { outputs: Known([]), problems: [] }
	}

## `set col = expr, ...` of an update or of `on conflict do update`: the
## columns must exist, and a parameter stored in one must fit it.
set_problems : List(Node), Rel, List(Rel), Env -> List(Str)
set_problems = |items, target, rels, env| {
	assignments = items.keep_oks(
		|item|
			match item {
				ResTarget(t) => Ok(t)
				_ => Err(NotATarget)
			},
	)
	# A column to set is named without the alias.
	missing = assignments.keep_oks(|t| missing_column({ ..target, alias: target.table }, t.name ?? ""))
	params = assignments.fold(
		[],
		|acc, t|
			match (t.val, t.indirection) {
				(ParamRef(p), []) =>
					match (param_name(p, env), column_in(target, t.name ?? "")) {
						(Ok(name), Found(column)) => acc.concat(param_problems(name, t.name ?? "", column, Bool.True, env))
						_ => acc
					}
				_ => acc
			},
	)
	values = assignments.map(|t| (t, typed(t.val, rels, env)))
	stored = values.fold(
		[],
		|acc, (t, value)|
			match (t.indirection, column_in(target, t.name ?? "")) {
				([], Found(column)) => acc.concat(value_problems(t.val, value.output, t.name ?? "", column, env))
				_ => acc
			},
	)
	inside = values.fold([], |acc, (_, value)| acc.concat(value.problems))
	missing.concat(params).concat(stored).concat(inside)
}

## Problems of `value` stored in `column`: a type the column cannot take
## on assignment, or NULL where it takes none. Parameters are checked by
## [param_problems], and a string literal is parsed by the server. `output`
## is what the walk found of `value`.
value_problems : Node, Check.Output, Str, Check.Output, Env -> List(Str)
value_problems = |value, output, column_name, column, env| {
	fits =
		match (output.type, column.type) {
			(Known(from), Known(to)) if !Overload.can_assign(base_in(env.catalog, from), base_in(env.catalog, to), env.enums) => ["column `${column_name}` is `${to}`, but the value is `${from}`"]
			_ => []
		}
	match value {
		ParamRef(_) => []
		SetToDefault(_) => []
		AConst(c) =>
			if c.isnull {
				if column.nullable == No ["column `${column_name}` is NOT NULL, but the value is NULL"] else []
			} else {
				match c.val {
					String(_) => []
					_ => fits
				}
			}
		_ => fits
	}
}

## What an insert stores: `values` rows, each value with what the walk
## found of it, `default values`, or the result of a query.
InsertSource : [Values(List(List((Node, Typed)))), DefaultValues, Query(Check.Result)]

insert_source : Node, Env -> InsertSource
insert_source = |source, env|
	match source {
		SelectStmt(sel) if sel.op == Enums.setop_none and !sel.values_lists.is_empty() =>
			Values(
				sel.values_lists.map(
					|row|
						match row {
							NodeList(items) => items.map(|item| (item, typed(item, [], env)))
							_ => []
						},
				),
			)
		Null => DefaultValues
		query => Query(statement(query, env))
	}

## Problems of the shape of what an insert stores: as many values as it
## names columns, values that fit their columns, and every column that is
## `NOT NULL` without a default given one. A table with a trigger may fill
## in a column itself, so it is not held to the last rule.
insert_shape_problems : InsertSource, List(Str), Rel, Env -> List(Str)
insert_shape_problems = |source, listed, target, env| {
	table_columns_list = known_list(target.columns)
	columns = if listed.is_empty() table_columns_list.map(|c| c.name) else listed
	{ widths, value_problems: stored } =
		match source {
			Values(rows) => {
				stored_problems = rows.fold(
					[],
					|acc, items|
						items.map_with_index(|item, i| (item, i)).fold(
							acc,
							|inner, ((item, value), i)|
								match columns.get(i) {
									Ok(col) =>
										match column_in(target, col) {
											Found(column) => inner.concat(value_problems(item, value.output, col, column, env))
											_ => inner
										}
									Err(_) => inner
								},
						),
				)
				{ widths: rows.map(|items| items.len()), value_problems: stored_problems }
			}
			DefaultValues => { widths: [0], value_problems: [] }
			Query(result) =>
				match result.outputs {
					Known(outputs) => {
						stored_problems = outputs.map_with_index(|o, i| (o, i)).fold(
							[],
							|acc, (o, i)|
								match (o.type, columns.get(i).map_ok(|col| (col, column_in(target, col)))) {
									(Known(from), Ok((col, Found({ type: Known(to), .. })))) if !Overload.can_assign(base_in(env.catalog, from), base_in(env.catalog, to), env.enums) =>
										acc.append("column `${col}` is `${to}`, but the query gives `${from}`")
									_ => acc
								},
						)
						{ widths: [outputs.len()], value_problems: stored_problems }
					}
					Unknown => { widths: [], value_problems: [] }
				}
		}
	count_problems =
		widths.keep_oks(
			|width|
				if !listed.is_empty() and width != listed.len() {
					Ok("the insert names ${listed.len().to_str()} columns but gives ${width.to_str()} values")
				} else if listed.is_empty() and target.columns != Unknown and width > table_columns_list.len() {
					Ok("the insert gives ${width.to_str()} values but `${target.table}` has ${table_columns_list.len().to_str()} columns")
				} else {
					Err(Fits)
				},
		)
	missing_problems =
		match (target.source, widths.first()) {
			(Ok({ columns: Known(catalog_columns), triggers: Bool.False, .. }), Ok(width)) => {
				given = if listed.is_empty() catalog_columns.take_first(width).map(|c| c.name) else listed
				catalog_columns
					.keep_if(|c| c.not_null and !c.has_default and !given.contains(c.name))
					.map(|c| "column `${c.name}` is NOT NULL and has no default, but the insert leaves it out")
			}
			_ => []
		}
	count_problems.concat(stored).concat(missing_problems)
}

## `merge into target using source on ... when ... then ...`: the target
## and source, the join condition, and each clause's condition, update and
## insert, checked like those of an update and an insert.
merge_stmt : Node.MergeStmt, Env -> Check.Result
merge_stmt = |s, env| {
	{ env: inner, problems: with_problems } = with_env(s.with_clause, env)
	{ rel: target, problems: table_problems } = target_rel(s.relation, inner)
	{ rels: source, problems: source_problems } = from_item(s.source_relation, inner)
	all = [target].concat(source)
	join_problems = expression_problems(s.join_condition, all, inner)
	clause_problems = s.merge_when_clauses.fold(
		[],
		|acc, clause|
			match clause {
				MergeWhenClause(w) => {
					condition = expression_problems(w.condition, all, inner)
					action =
						if w.command_type == Enums.cmd_update {
							set_problems(w.target_list, target, all, inner)
						} else if w.command_type == Enums.cmd_insert {
							merge_insert_problems(w, target, source, inner)
						} else {
							[]
						}
					acc.concat(condition).concat(action)
				}
				_ => acc
			},
	)
	clauses = s.merge_when_clauses.keep_oks(
		|clause|
			match clause {
				MergeWhenClause(w) => Ok(w)
				_ => Err(NotAClause)
			},
	)
	# A target row no source row matches has no source columns.
	by_source = clauses.any(|w| w.match_kind == Enums.merge_when_not_matched_by_source)
	returned = [target].concat(if by_source source.map(|r| { ..r, nullable: Bool.True, not_null: [] }) else source)
	absent = { old_absent: clauses.any(|w| w.command_type == Enums.cmd_insert), new_absent: clauses.any(|w| w.command_type == Enums.cmd_delete) }
	returning = returning_list(s.returning_clause, returned, absent, inner)
	{ outputs: returning.outputs, problems: with_problems.concat(table_problems).concat(source_problems).concat(join_problems).concat(clause_problems).concat(returning.problems) }
}

## `insert (cols) values (...)` of a merge, whose values read the source.
merge_insert_problems : Node.MergeWhenClause, Rel, List(Rel), Env -> List(Str)
merge_insert_problems = |w, target, source, env| {
	listed = w.target_list.keep_oks(
		|col|
			match col {
				ResTarget(t) => t.name.map_err(|_| NoName)
				_ => Err(NoName)
			},
	)
	columns = if listed.is_empty() known_list(target.columns).map(|c| c.name) else listed
	missing = listed.keep_oks(|c| missing_column({ ..target, alias: target.table }, c))
	count =
		if !listed.is_empty() and w.values.len() != listed.len() {
			["the insert names ${listed.len().to_str()} columns but gives ${w.values.len().to_str()} values"]
		} else {
			[]
		}
	walked = w.values.map(|value| (value, typed(value, source, env)))
	stored = walked.map_with_index(|pair, i| (pair, i)).fold(
		[],
		|acc, ((value, found), i)|
			match columns.get(i).map_ok(|col| (col, column_in(target, col))) {
				Ok((col, Found(column))) => {
					params =
						match value {
							ParamRef(p) =>
								match param_name(p, env) {
									Ok(name) => param_problems(name, col, column, Bool.True, env)
									Err(_) => []
								}
							_ => []
						}
					acc.concat(params).concat(value_problems(value, found.output, col, column, env))
				}
				_ => acc
			},
	)
	inside = walked.fold([], |acc, (_, found)| acc.concat(found.problems))
	missing.concat(count).concat(stored).concat(inside)
}

insert_stmt : Node.InsertStmt, Env -> Check.Result
insert_stmt = |s, env| {
	{ env: inner, problems: with_problems } = with_env(s.with_clause, env)
	{ rel: target, problems: table_problems } = target_rel(s.relation, inner)
	listed = s.cols.keep_oks(
		|col|
			match col {
				ResTarget(t) => t.name.map_err(|_| NoName)
				_ => Err(NoName)
			},
	)
	column_problems = listed.keep_oks(|c| missing_column({ ..target, alias: target.table }, c))
	source = insert_source(s.select_stmt, inner)
	shape_problems = insert_shape_problems(source, listed, target, inner)
	source_problems =
		match source {
			Values(rows) => values_problems(rows, listed, target, inner).concat(rows.fold([], |acc, row| row.fold(acc, |inner_acc, (_, value)| inner_acc.concat(value.problems))))
			DefaultValues => []
			Query(result) => result.problems
		}
	excluded = { ..target, alias: "excluded" }
	conflict_problems =
		match s.on_conflict_clause {
			OnConflictClause(c) => set_problems(c.target_list, target, [target, excluded], inner).concat(expression_problems(c.where_clause, [target, excluded], inner))
			_ => []
		}
	# An insert has no row before. `on conflict do update` does, but only
	# for the rows it updates.
	returning = returning_list(s.returning_clause, [target], { old_absent: Bool.True, new_absent: Bool.False }, inner)
	{ outputs: returning.outputs, problems: with_problems.concat(table_problems).concat(column_problems).concat(shape_problems).concat(source_problems).concat(conflict_problems).concat(returning.problems) }
}

## Problems of the parameters in `values ($a, $b), ...` of an insert into
## `target`, whose listed columns are `listed` (all of them when empty).
values_problems : List(List((Node, Typed))), List(Str), Rel, Env -> List(Str)
values_problems = |rows, listed, target, env| {
	columns = if listed.is_empty() known_list(target.columns).map(|c| c.name) else listed
	rows.fold(
		[],
		|acc, items|
			items.map_with_index(|(item, _), index| (item, index)).fold(
				acc,
				|inner, (item, index)|
					match (item, columns.get(index)) {
						(ParamRef(p), Ok(col)) =>
							match (param_name(p, env), column_in(target, col)) {
								(Ok(name), Found(column)) => inner.concat(param_problems(name, col, column, Bool.True, env))
								_ => inner
							}
						_ => inner
					},
			),
	)
}

update_stmt : Node.UpdateStmt, Env -> Check.Result
update_stmt = |s, env| {
	{ env: inner, problems: with_problems } = with_env(s.with_clause, env)
	{ rel: target, problems: table_problems } = target_rel(s.relation, inner)
	{ rels, problems: from_problems } = from_list(s.from_clause, inner)
	all = [target].concat(rels)
	assignment_problems = set_problems(s.target_list, target, all, inner)
	where_problems = expression_problems(s.where_clause, all, inner)
	returning = returning_list(s.returning_clause, all, { old_absent: Bool.False, new_absent: Bool.False }, inner)
	{ outputs: returning.outputs, problems: with_problems.concat(table_problems).concat(from_problems).concat(assignment_problems).concat(where_problems).concat(returning.problems) }
}

delete_stmt : Node.DeleteStmt, Env -> Check.Result
delete_stmt = |s, env| {
	{ env: inner, problems: with_problems } = with_env(s.with_clause, env)
	{ rel: target, problems: table_problems } = target_rel(s.relation, inner)
	{ rels, problems: using_problems } = from_list(s.using_clause, inner)
	all = [target].concat(rels)
	where_problems = expression_problems(s.where_clause, all, inner)
	returning = returning_list(s.returning_clause, all, { old_absent: Bool.False, new_absent: Bool.True }, inner)
	{ outputs: returning.outputs, problems: with_problems.concat(table_problems).concat(using_problems).concat(where_problems).concat(returning.problems) }
}

string_of : Node -> Try(Str, [NotAString])
string_of = |node|
	match node {
		String(s) =>
			match s.sval {
				Ok(text) => Ok(text)
				Err(_) => Err(NotAString)
			}
		_ => Err(NotAString)
	}

names_of : List(Node) -> List(Str)
names_of = |nodes| nodes.keep_oks(string_of)

is_set : Node.Text -> Bool
is_set = |text|
	match text {
		Ok(_) => Bool.True
		Err(_) => Bool.False
	}

test_schema =
	\\CREATE TABLE public.students (
	\\    id integer NOT NULL,
	\\    name text NOT NULL,
	\\    phone text,
	\\    school_id integer NOT NULL
	\\);
	\\CREATE TABLE public.schools (
	\\    id integer NOT NULL,
	\\    name text NOT NULL
	\\);
	\\ALTER TABLE ONLY public.schools ADD CONSTRAINT schools_pkey PRIMARY KEY (id);
	\\CREATE VIEW public.school_names AS
	\\ SELECT o.id, o.name, count(r.id) AS students FROM public.schools o LEFT JOIN public.students r ON r.school_id = o.id GROUP BY o.id, o.name;
	\\CREATE FUNCTION public.student_label(r_id integer, suffix text DEFAULT '') RETURNS text
	\\    LANGUAGE sql STRICT AS $$ select 'x' $$;
	\\CREATE FUNCTION public.school_members(o_id integer) RETURNS TABLE(student_id integer, student_name text)
	\\    LANGUAGE sql AS $$ select 1, 'a' $$;

test_catalog : Catalog
test_catalog = Catalog.parse(test_schema) ?? Catalog.none

check : Str -> Check.Result
check = |sql| check_in(test_catalog, sql)

check_in : Catalog, Str -> Check.Result
check_in = |catalog, sql| {
	toks = Lex.tokens(sql) ?? []
	match Parse.parse(Lex.grammar_text(sql, toks)) {
		Ok([stmt]) => Check.analyze(stmt, catalog, [], Lex.named_at(toks))
		_ => { outputs: Unknown, problems: ["not one statement"] }
	}
}

outputs : Str -> List(Str)
outputs = |sql| outputs_in(test_catalog, sql)

outputs_in : Catalog, Str -> List(Str)
outputs_in = |catalog, sql|
	match check_in(catalog, sql).outputs {
		Known(list) =>
			list.map(
				|o| {
					type =
						match o.type {
							Known(t) => t
							Unknown => "?"
						}
					nullable =
						match o.nullable {
							Yes => " null"
							No => ""
							Unknown => " null?"
						}
					"${o.name} ${type}${nullable}"
				},
			)
		Unknown => ["unknown"]
	}

problems : Str -> List(Str)
problems = |sql| check(sql).problems

expect outputs("select id, name, phone from students where school_id = $o") == ["id integer", "name text", "phone text null"]
expect problems("select id, name, phone from students where school_id = $o") == []
expect outputs("select r.id, o.name as school from students r left join schools o on o.id = r.school_id") == ["id integer", "school text null"]
expect outputs("select r.id, o.name from schools o right join students r on o.id = r.school_id") == ["id integer", "name text null"]
expect problems("select r.phnoe from students r") == ["column `r.phnoe` does not exist in `students` (did you mean `phone`?)"]
expect problems("select nme from students") == ["column `nme` does not exist in `students` (did you mean `name`?)"]
expect outputs("select * from schools") == ["id integer", "name text"]
expect outputs("select o.* from schools o") == ["id integer", "name text"]
expect outputs("select count(*) as n from students") == ["n bigint"]
expect outputs("select count(*) from students") == ["count bigint"]
expect outputs("select coalesce(phone, '') as phone from students") == ["phone text"]
expect problems("select x from nope") == ["table `nope` does not exist in the schema"]
expect problems("insert into students (id, nme, school_id) values ($a, $b, $c) returning id") == ["column `nme` does not exist in `students` (did you mean `name`?)", "column `name` is NOT NULL and has no default, but the insert leaves it out"]
expect outputs("insert into students (id, name) values ($a, $b) returning id") == ["id integer"]
expect outputs("insert into students (id, name) values ($a, $b)") == []
expect problems("update students set phoen = $p where id = $id") == ["column `phoen` does not exist in `students` (did you mean `phone`?)"]
expect problems("update students r set phone = $p from schools o where o.id = r.school_id and o.nmae = $n") == ["column `o.nmae` does not exist in `schools` (did you mean `name`?)"]
expect outputs("with recent as (select id from students) select id from recent") == ["id integer"]
expect outputs("with recent (rid) as (select id from students) select rid from recent") == ["rid integer"]
expect outputs("select id from students union select id from schools") == ["id integer"]
expect outputs("select (select name from schools o where o.id = r.school_id) as school_name from students r") == ["school_name text null"]
expect problems("select (select nme from schools o where o.id = r.school_id) as school_name from students r") == ["column `nme` does not exist in `o` (did you mean `name`?)"]
expect outputs("select id, name::text, school_id::bigint as school from students") == ["id integer", "name text", "school bigint"]
expect problems("select id from students r join schools o on o.id = r.school_id") == ["column `id` is ambiguous: it is in `r` and `o`"]
expect outputs("select t.n from (select count(*) as n from students) t") == ["n bigint"]
expect outputs("select x.id from unnest($ids) as x(id)") == ["id ? null?"]
expect outputs("delete from students where id = $id returning id, phone") == ["id integer", "phone text null"]
expect outputs("select 1") == ["?column? integer"]
expect outputs("select '1'::integer, null::text as t") == ["int4 integer", "t text null"]
expect problems("select id from students order by name desc limit 1") == []
expect problems("select r.id from students r where r.school_id in (select o.id from schools o where o.name = $n)") == []
expect problems("insert into schools (id, name) values ($id, $name) on conflict (id) do update set name = excluded.name, nmae = excluded.nmae") == ["column `nmae` does not exist in `schools` (did you mean `name`?)", "column `excluded.nmae` does not exist in `schools` (did you mean `name`?)"]
expect outputs("select distinct on (school_id) id, name from students order by school_id, id") == ["id integer", "name text"]
expect outputs("select id, exists (select 1 from schools) as any_school from students") == ["id integer", "any_school boolean"]

# What the tree adds over reading tokens.
expect problems("select id from students where schol_id = $o") == ["column `schol_id` does not exist in `students` (did you mean `school_id`?)"]
expect problems("select id from students join schools using (id)") == []
expect outputs("select id from students join schools using (id)") == ["id integer"]
expect outputs("select * from students natural join schools") == ["id integer", "name text", "phone text null", "school_id integer"]
expect problems("select name as n from students order by n") == []
expect problems("select r from students r") == []
expect outputs("select greatest(id, school_id) as g, nullif(name, '') as n from students") == ["g integer", "n text null"]
expect outputs("select case when phone is null then 'none' else phone end as p from students") == ["p text null?"]
expect outputs("select case when id > 1 then name end as n from students") == ["n text null"]
expect outputs("select array(select id from schools) as ids, current_date") == ["ids integer[]", "current_date date"]
expect outputs("values (1, 'a'), (2, null)") == ["column1 integer", "column2 text null"]
expect outputs("select id from students except select school_id from students") == ["id integer"]
expect Check.fits(test_catalog, "integer", "I32")
expect !Check.fits(test_catalog, "bigint", "I32")
expect Check.fits(test_catalog, "bigint", "I64")
expect Check.fits(test_catalog, "numeric", "Dec")
expect !Check.fits(test_catalog, "numeric", "F64")
expect Check.fits(test_catalog, "text", "Str")
expect Check.suggestion("schol_id", ["id", "school_id"]) == " (did you mean `school_id`?)"
expect Check.suggestion("phnoe", ["name", "phone"]) == " (did you mean `phone`?)"
expect Check.suggestion("email", ["id", "name"]) == ""
expect Check.suggestion("nm", ["name"]) == ""
expect Check.fits(test_catalog, "bigint", "Str")
expect !Check.fits(test_catalog, "text", "I32")
expect Check.fits(test_catalog, "text[]", "List(Str)")
expect !Check.fits(test_catalog, "text[]", "I32")
expect Check.fits(test_catalog, "access_level", "Str")
expect Check.fits(test_catalog, "some_domain", "I32")

# Function calls and operators, typed from Postgres's catalog.
expect outputs("select sum(id) as total, avg(id) as mean, max(name) as last from students") == ["total bigint null", "mean numeric null", "last text null"]
expect outputs("select school_id, sum(id) as total, max(phone) as p from students group by school_id") == ["school_id integer", "total bigint", "p text null"]
expect outputs("select school_id, array_agg(phone) as phones from students group by school_id") == ["school_id integer", "phones text[]"]
expect outputs("select count(phone) filter (where id > 1) as n, sum(id) filter (where id > 1) as s from students group by school_id") == ["n bigint", "s bigint null"]
expect outputs("select lower(name), length(phone), upper(phone) as u from students") == ["lower text", "length integer null", "u text null"]
expect outputs("select id + 1 as next, id * 1.5 as scaled, -id as neg, name || '!' as shout from students") == ["next integer", "scaled numeric", "neg integer", "shout text"]
expect outputs("select phone || 'x' as p, now() - interval '1 day' as yesterday from students") == ["p text null", "yesterday timestamp with time zone"]
expect outputs("select concat(name, phone) as c, extract(year from now()) as y from students") == ["c text", "y numeric"]
expect outputs("select row_number() over (order by id) as n, lag(name) over (order by id) as prev from students") == ["n bigint", "prev text null"]
expect outputs("select g from generate_series(1, 3) g") == ["g integer null?"]
expect outputs("select n from generate_series(1, 3) as g(n)") == ["n integer null?"]
expect outputs("select no_such_function(id) as x from students") == ["x ? null?"]

# Views, and functions of the schema and Postgres's catalog.
expect outputs("select name, students from school_names") == ["name text", "students bigint"]
expect problems("select nmae from school_names") == ["column `nmae` does not exist in `school_names` (did you mean `name`?)"]
expect outputs("select student_label(id) as l, student_label(id, '!') as m from students") == ["l text null?", "m text null?"]
expect outputs("select student_name from school_members(1)") == ["student_name text null?"]
expect outputs("select key, value from jsonb_each('{}'::jsonb)") == ["key text null?", "value jsonb null?"]
expect outputs("select jsonb_set('{}'::jsonb, '{a}', '1') as j") == ["j jsonb null?"]

# Calls no function or operator takes.
expect problems("select lower(id) from students") == ["function `lower(integer)` does not exist"]
expect problems("select lowr(name) from students") == ["function `lowr` does not exist"]
expect problems("select lower(name, name) from students") == ["function `lower(text, text)` does not exist"]
expect problems("select id from students where name = school_id") == ["operator `text = integer` does not exist"]
expect problems("select id from students where name = 'x' and school_id = '1' and id + 1.5 > 2") == []
expect problems("select student_label(id), student_label(id, 'x'), lower(name), -id, not true from students") == []
expect problems("select count(*), max(name), string_agg(name, ', ') from students") == []

# Grouping.
expect problems("select school_id, name from students group by school_id") == ["column `name` must appear in `group by` or be used in an aggregate"]
expect problems("select school_id, count(*) from students group by school_id") == []
expect problems("select school_id, count(*) from students group by 1") == []
expect problems("select school_id as o, count(*) from students group by o") == []
expect problems("select name, count(*) from students") == ["column `name` must appear in `group by` or be used in an aggregate"]
expect problems("select o.id, o.name, count(r.id) from schools o join students r on r.school_id = o.id group by o.id") == []
expect problems("select r.id, r.name, count(*) from students r group by r.id") == ["column `r.name` must appear in `group by` or be used in an aggregate"]
expect problems("select lower(name), count(*) from students group by lower(name)") == []
expect problems("select lower(name), count(*) from students group by name") == []
expect problems("select school_id from students group by school_id having count(*) > 1 order by school_id") == []
expect problems("select school_id, count(*) from students group by school_id order by name") == ["column `name` must appear in `group by` or be used in an aggregate"]
expect problems("select school_id, sum(id) over (), row_number() over (order by school_id) from students group by school_id") == ["column `id` must appear in `group by` or be used in an aggregate"]
expect problems("select school_id, sum(sum(id)) over () from students group by school_id") == []
expect problems("select id, name from students") == []

# Columns `where` rules NULL out.
expect outputs("select phone from students where phone is not null") == ["phone text"]
expect outputs("select r.phone from students r where r.id > 1 and r.phone like '+46%'") == ["phone text"]
expect outputs("select phone from students where phone is not null or id > 1") == ["phone text null"]
expect outputs("select o.name from students r left join schools o on o.id = r.school_id where o.name = 'x'") == ["name text"]
expect outputs("select phone from students where phone is distinct from 'x'") == ["phone text null"]

# Merge.
expect problems("merge into schools o using students r on o.id = r.school_id when matched then update set name = r.name when not matched then insert (id, name) values (r.school_id, r.name)") == []
expect problems("merge into schools o using students r on o.id = r.schol_id when matched then update set nmae = r.name") == ["column `r.schol_id` does not exist in `students` (did you mean `school_id`?)", "column `nmae` does not exist in `schools` (did you mean `name`?)"]
expect problems("merge into schools o using students r on o.id = r.school_id when not matched then insert (id, name) values (true, r.name)") == ["column `id` is `integer`, but the value is `boolean`"]
expect problems("merge into schools o using students r on o.id = r.school_id when not matched then insert (id, name) values (r.school_id)") == ["the insert names 2 columns but gives 1 values"]
expect outputs("merge into schools o using students r on o.id = r.school_id when matched then delete returning o.id, r.phone") == ["id integer", "phone text null"]

# Each node is read once, so a long expression costs no more than its length.
expect outputs("select ${Str.join_with(List.repeat("id", 20), " + ")} as x, coalesce(${Str.join_with(List.repeat("phone", 20), " || ")}, '') as y from students") == ["x integer", "y text"]

# NULL that a row, an array or an empty array can bring.
expect outputs("select id = any(array[1]) as a, (id, school_id) = (1, 2) as b, (id, phone) = (1, 'x') as c from students") == ["a boolean null?", "b boolean", "c boolean null?"]
expect outputs("select phone from students where phone = any(array['x'])") == ["phone text"]
expect outputs("select phone from students where phone <> all(array['x'])") == ["phone text null"]

# Grouping sets: a column some set leaves out is NULL in that set's rows,
# and with an empty set the aggregates can see no rows.
expect outputs("select school_id, count(*) as n from students group by rollup(school_id)") == ["school_id integer null", "n bigint"]
expect outputs("select school_id, sum(id) as s from students group by grouping sets ((school_id), ())") == ["school_id integer null", "s bigint null"]
expect outputs("select school_id, name from students group by grouping sets ((school_id), (name))") == ["school_id integer null", "name text null"]
expect outputs("select school_id, name, count(*) as n from students group by school_id, rollup(name)") == ["school_id integer", "name text null", "n bigint"]
expect problems("select school_id, name from students group by rollup(school_id)") == ["column `name` must appear in `group by` or be used in an aggregate"]
expect problems("select school_id, name from students group by grouping sets ((school_id), (name))") == []
expect problems("select o.id, o.name from schools o group by rollup(o.id)") == ["column `o.name` must appear in `group by` or be used in an aggregate"]
expect problems("select o.id, o.name from schools o group by o.id, rollup(o.name)") == []

# `old` and `new` in a `returning` list, and a merge's unmatched rows.
expect outputs("update students set phone = $p where id = $id returning old.phone as before, new.name as after") == ["before text null", "after text"]
expect outputs("delete from students where id = $id returning old.name as n, new.name as m") == ["n text", "m text null"]
expect outputs("insert into schools (id, name) values ($i, $n) returning old.name as o, new.name as n, name") == ["o text null", "n text", "name text"]
expect outputs("update schools set name = $n where id = $i returning with (old as before) before.name as was, before.*") == ["was text", "id integer", "name text"]
expect outputs("merge into schools o using students r on r.school_id = o.id when matched then update set name = r.name returning r.name as student") == ["student text"]
expect outputs("merge into schools o using students r on r.school_id = o.id when not matched by source then delete returning r.name as student") == ["student text null"]

# The type values share, as select_common_type picks it.
expect outputs("select id from students union select 1.5") == ["id numeric"]
expect outputs("select 'a' as x union select 'b'") == ["x text"]
expect outputs("select id from students union all select school_id from students union select 2::bigint") == ["id bigint"]
expect problems("select id from students union select name from students") == ["UNION types integer and text cannot be matched"]
expect problems("select 1 union select 1, 2") == ["each UNION query must have the same number of columns"]
expect outputs("select phone from students intersect select name from students") == ["phone text"]
expect outputs("select phone from students except select name from students") == ["phone text null"]
expect outputs("select case when id > 1 then 1 else 2.5 end as c, coalesce(school_id, 1.5) as d from students") == ["c numeric", "d numeric"]
expect problems("select case when id > 1 then 1 else true end from students") == ["CASE types boolean and integer cannot be matched"]
expect problems("select greatest(id, name), coalesce(phone, 1) from students") == ["GREATEST types integer and text cannot be matched", "COALESCE types text and integer cannot be matched"]
expect outputs("select array[id, school_id] as a, array['x', name] as b, array[array[1, 2]] as m from students") == ["a integer[]", "b text[]", "m integer[]"]
expect problems("select array[id, name] from students") == ["ARRAY types integer and text cannot be matched"]
expect outputs("values (1, 'a'), (2.5, null)") == ["column1 numeric", "column2 text null"]
expect problems("values (1), (2, 3)") == ["VALUES lists must all be the same length"]
expect problems("values (1), ('x'), (true)") == ["VALUES types integer and boolean cannot be matched"]
expect problems("select id from students where name in ('a', 1) and id not in (1, 2, $x) and id in (select school_id from students)") == ["operator `text = integer` does not exist"]

# Relations of a `from` list besides tables and subqueries.
expect outputs("select r.name from students r tablesample bernoulli (10)") == ["name text"]
expect problems("select r.nmae from students r tablesample system (1) repeatable (7)") == ["column `r.nmae` does not exist in `students` (did you mean `name`?)"]
expect outputs("select x.a, x.n from xmltable('/r' passing ('<r/>'::xml) columns a text path 'a', n for ordinality, b int not null) as x") == ["a text null", "n integer"]
expect outputs("select j.id, j.tag, j.n from json_table('[]'::jsonb, '$[*]' columns (n for ordinality, id int path '$.id', nested path '$.tags[*]' columns (tag text path '$'))) as j") == ["id integer null", "tag text null", "n integer"]
expect outputs("select t.a, t.b from json_to_record('{}'::json) as t(a int, b text)") == ["a integer null?", "b text null?"]
expect outputs("select g, ordinality from generate_series(1, 3) with ordinality as g") == ["g integer null?", "ordinality bigint"]
expect outputs("select a, b from rows from (generate_series(1, 2), unnest(array['x'])) as t(a, b)") == ["a integer null?", "b text null?"]

schemas_catalog : Catalog
schemas_catalog =
	Catalog.parse(
		\\CREATE TABLE public.users (id integer NOT NULL, name text NOT NULL);
		\\CREATE TABLE app.users (id bigint NOT NULL, email text NOT NULL);
		\\CREATE TABLE app.posts (id bigint NOT NULL, title text NOT NULL);
		\\CREATE FUNCTION app.greet(who text) RETURNS text LANGUAGE sql STRICT AS $$ select 'hi ' || who $$;
		\\CREATE FUNCTION public.add_one(integer, integer) RETURNS integer LANGUAGE sql AS $$ select $1 + $2 $$;
		\\CREATE AGGREGATE public.total(integer) (SFUNC = public.add_one, STYPE = integer);
		\\CREATE FUNCTION public.everyone() RETURNS SETOF public.users LANGUAGE sql AS $$ select * from public.users $$;
	)
	?? Catalog.none

# Tables and functions by schema and search path.
expect outputs_in(schemas_catalog, "select id, name from users") == ["id integer", "name text"]
expect outputs_in(schemas_catalog, "select id, email from app.users") == ["id bigint", "email text"]
expect outputs_in(schemas_catalog.with_search_path(["app", "public"]), "select id, email from users") == ["id bigint", "email text"]
expect check_in(schemas_catalog, "select title from posts").problems == ["table `posts` does not exist in the schema (did you mean `app.posts`? Its schema is not on the search path)"]
expect check_in(schemas_catalog, "select id from app.user").problems == ["table `app.user` does not exist in the schema (did you mean `users`?)"]
expect check_in(schemas_catalog, "select app.greet(name) from users").problems == []
expect check_in(schemas_catalog, "select greet(name) from users").problems == ["function `greet` does not exist"]
expect outputs_in(schemas_catalog.with_search_path(["app"]), "select greet(email) as g from users") == ["g text null?"]
expect check_in(schemas_catalog, "select app.lower(name) from users").problems == ["function `lower` does not exist"]
expect outputs_in(schemas_catalog, "select pg_catalog.lower(name) as l, total(id) as t from users") == ["l text", "t integer null?"]
expect outputs_in(schemas_catalog, "select e.name from everyone() e") == ["name text null?"]
