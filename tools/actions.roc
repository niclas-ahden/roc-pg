#!/usr/bin/env roc
## Writes `package/Node.roc`, the parse tree's node types,
## `tests/NodeJson.roc`, which writes a tree as libpg_query's JSON, and
## `package/Actions.roc`, Postgres's grammar actions and the helpers they
## call, translated from C to Roc. Run `tools/grammar.roc` first: it runs
## bison, whose `local/gram/gram.c` holds the actions numbered by rule.
##
##     roc tools/actions.roc
##
## What cannot be translated is printed and written to
## `local/gram/problems.txt`, with where it is in `gram.y`. Then nothing
## else is written, and the program exits with an error.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
}

import pf.Stdout
import pf.Stderr
import pf.Path
import pf.OsStr
import GramC
import CParse
import Consts
import Structs
import Translate
import Walk
import TreeJson
import RuleBodies

src = "local/postgres-18.6/src"

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	gram_c = read!("local/gram/gram.c")?
	gram_y = read!("${src}/backend/parser/gram.y")?
	copyright = read!("local/postgres-18.6/COPYRIGHT")?
	sections = gram_y.split_on("\n%%\n")
	# The C between bison's `%{` and `%}` markers, and the declarations after.
	prologue = (sections.get(0) ?? "").replace_each("%{", "").replace_each("%}", "")
	epilogue = sections.get(2) ?? ""

	# Constants: gram.y's own, then the headers, the first definition winning.
	header_paths = [
		"include/nodes/parsenodes.h",
		"include/nodes/primnodes.h",
		"include/nodes/nodes.h",
		"include/nodes/value.h",
		"include/nodes/lockoptions.h",
		"include/nodes/pg_list.h",
		"include/catalog/pg_class.h",
		"include/catalog/pg_trigger.h",
		"include/catalog/pg_attribute.h",
		"include/catalog/pg_am.h",
		"include/catalog/index.h",
		"include/commands/trigger.h",
		"include/utils/datetime.h",
		"include/utils/timestamp.h",
		"include/utils/xml.h",
		"include/c.h",
		"include/postgres_ext.h",
		"include/storage/lockdefs.h",
		"include/common/relpath.h",
	]
	var $headers = [prologue]
	for p in header_paths {
		$headers = $headers.append(read!("${src}/${p}")?)
	}
	consts = Consts.collect($headers)
	errcodes = Consts.errcodes(read!("${src}/backend/utils/errcodes.txt")?)

	structs_list = Structs.collect([read!("${src}/include/nodes/parsenodes.h")?, read!("${src}/include/nodes/primnodes.h")?, read!("${src}/include/nodes/value.h")?, prologue])
	structs = structs_list.fold(Dict.empty(), |acc, s| if acc.contains(s.name) acc else acc.insert(s.name, s.fields))

	# The grammar actions.
	lengths = GramC.rule_lengths(gram_c)?
	var $problems = Consts.unresolved($headers, consts).map(|entry| "enum value not evaluated: ${entry}")
	var $actions = []
	for a in GramC.actions(gram_c)? {
		match CParse.statement(a.code) {
			Ok(body) => {
				$actions = $actions.append({ rule: a.rule, rule_text: a.rule_text, body, code: a.code, line: a.line })
			}
			Err(message) => {
				$problems = $problems.append(action_problem(a, "C not read: ${message}"))
			}
		}
	}

	# The helper functions they may call, gram.y's own first.
	helper_sources = [epilogue, read!("${src}/backend/nodes/makefuncs.c")?, read!("${src}/backend/nodes/value.c")?, read!("${src}/backend/commands/define.c")?, read!("${src}/backend/nodes/nodeFuncs.c")?]
	parsed_helpers = helper_sources.map(CParse.functions)
	all_funcs = parsed_helpers.fold(Dict.empty(), |acc, r| r.funcs.fold(acc, |d, f| if d.contains(f.name) d else d.insert(f.name, f)))
	unread_funcs = parsed_helpers.fold([], |acc, r| acc.concat(r.failed))

	# Every helper the actions reach, following calls.
	var $wanted = []
	# The hand-written helpers call these translated ones.
	var $queue = $actions.fold(["exprLocation", "makeSimpleA_Expr", "makeRangeVar", "makeTypeCast"], |acc, a| acc.concat(Walk.calls(a.body)))
	while !$queue.is_empty() {
		name = $queue.first() ?? ""
		$queue = $queue.drop_first(1)
		if !$wanted.contains(name) and !hand_sigs.contains(name) and !native_sigs.contains(name) and !special.contains(name) {
			match all_funcs.get(name) {
				Ok(f) => {
					$wanted = $wanted.append(name)
					$queue = $queue.concat(Walk.calls(f.body))
				}
				Err(_) =>
					match unread_funcs.find_first(|u| u.name == name) {
						Ok(u) => {
							$problems = $problems.append("helper ${name}: C not read: ${u.error}")
						}
						Err(_) => {}
					}
			}
		}
	}
	funcs = $wanted.keep_oks(|name| all_funcs.get(name))

	# Which helpers can fail: those that raise an error, or call one that can.
	var $failing = funcs.keep_if(|f| raises(f.body)).map(|f| f.name).concat(hand_sigs.to_list().keep_if(|(_, s)| s.fails).map(|(n, _)| n))
	var $changed = Bool.True
	while $changed {
		$changed = Bool.False
		for f in funcs {
			if !$failing.contains(f.name) and Walk.calls(f.body).any(|c| $failing.contains(c)) {
				$failing = $failing.append(f.name)
				$changed = Bool.True
			}
		}
	}
	translated_sigs = funcs.fold(
		Dict.empty(),
		|acc, f| {
			params = f.params.map(|p| if p.type.contains("core_yyscan_t") Void else Translate.ctype(p.type))
			acc.insert(f.name, { roc: Translate.snake(f.name), params, returns: Translate.ctype(f.returns), fails: $failing.contains(f.name), inout: [], outs: [] })
		},
	)
	sigs = hand_sigs.to_list().concat(native_sigs.to_list()).fold(translated_sigs, |acc, (n, s)| acc.insert(n, s))

	# The node types: every struct the code makes, and those the helpers
	# ported by hand use.
	made = $actions.fold([], |acc, a| acc.concat(Walk.made(a.body))).concat(funcs.fold([], |acc, f| acc.concat(Walk.made(f.body)))).concat(hand_types)
	var $types = []
	for t in made {
		if !$types.contains(t) and structs.contains(t) {
			$types = $types.append(t)
		}
	}
	# Structs held in place in those types, such as `CreateStmt base`, are
	# nodes too.
	var $grow = Bool.True
	while $grow {
		$grow = Bool.False
		for t in $types {
			for f in structs.get(t) ?? [] {
				if is_embedded(f.type, structs) and !$types.contains(f.type) {
					$types = $types.append(f.type)
					$grow = Bool.True
				}
			}
		}
	}
	types = $types.sort_with(|a, b| compare_str(a, b))

	members = union_members(prologue)
	env = { consts, errcodes, structs, sigs, members, node_types: types }

	# Translate before interning: literal slots carry the translator's
	# resolved I64 type, and all other code must match exactly. Each dispatch
	# arm keeps its grammar label even when the implementation is shared.
	var $rules = RuleBodies.empty({})
	for a in $actions {
		len = lengths.get(a.rule) ?? 0
		out = Translate.action_template(env, a.rule, len, a.rule_text, a.body)
		$rules = RuleBodies.add($rules, a.rule, a.rule_text, out)
		$problems = $problems.concat(out.problems.map(|p| action_problem(a, p)))
	}
	var $func_code = []
	for f in funcs {
		sig = translated_sigs.get(f.name) ?? { roc: "", params: [], returns: Void, fails: Bool.False, inout: [], outs: [] }
		out = Translate.function(env, f, sig)
		$func_code = $func_code.append(out.code)
		$problems = $problems.concat(out.problems)
	}
	hand = fill_constants(read!("tools/actions_hand.roc")?, consts)?

	header = license(copyright)
	node_roc = node_module(header, types, structs)
	enums = Consts.enum_types($headers, consts)
	json = TreeJson.source(header, read!("tools/node_json_hand.roc")?, types, structs, enums)
	actions_roc = Str.join_with(
		[
			header,
			"## Postgres 18.6's grammar actions, sharing identical typed bodies from",
			"## `src/backend/parser/gram.y`, and the helper functions they call,",
			"## translated from C by `tools/actions.roc`. Do not edit: change the",
			"## translator, or `tools/actions_hand.roc` for the helpers ported by hand.",
			"import Node",
			"import Rt",
			"import Scan",
			"",
			"Actions :: [].{",
			"\t## Run the action of rule `rule` on the values and locations of its",
			"\t## right-hand side. `loc` is the rule's own location.",
			"\trun : U64, Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)",
			"\trun = |rule, ctx, v, l, loc|",
			"\t\tmatch rule {",
		]
			.concat($rules.dispatch)
			.concat(["\t\t\t_ => Ok(v.get(0) ?? Rt.of_node(Null))", "\t\t}", "}", ""])
			.concat($rules.code.map(|c| "${c}\n"))
			.concat($func_code.map(|c| "${c}\n"))
			.append(hand),
		"\n",
	)
	problems = $problems.concat(json.unknown.map(|u| "JSON: field type not written: ${u}"))
	Path.write_utf8!(Path.utf8("local/gram/problems.txt"), Str.join_with(problems, "\n\n"))?
	Stdout.line!("${$actions.len().to_str()} actions (${$rules.code.len().to_str()} distinct bodies), ${funcs.len().to_str()} helpers translated, ${types.len().to_str()} node types, ${problems.len().to_str()} problems (local/gram/problems.txt)")?
	if !problems.is_empty() {
		# Code with a gap in it is never written over the package's.
		for p in problems {
			Stderr.line!("\n${p}")?
		}
		return Err(Untranslated(problems.len()))
	}
	Path.write_utf8!(Path.utf8("package/Node.roc"), node_roc)?
	Path.write_utf8!(Path.utf8("package/Actions.roc"), actions_roc)?
	Path.write_utf8!(Path.utf8("package/Enums.roc"), enums_module(header, types, structs, enums))?
	Path.write_utf8!(Path.utf8("tests/NodeJson.roc"), json.code)?
	Ok({})
}

## A problem with one grammar action: where it is in `gram.y`, the rule,
## and the start of its C code.
action_problem : { rule : U64, rule_text : Str, code : Str, line : U64, ..}, Str -> Str
action_problem = |a, message| {
	# The translator names the rule itself, and CParse counts lines from the
	# start of the action.
	unnamed = message.drop_prefix("rule ${a.rule.to_str()} (${a.rule_text}): ")
	text =
		match unnamed.drop_prefix("C not read: line ").split_first(": ") {
			Ok({ before, after }) if unnamed.starts_with("C not read: line ") =>
				match U64.from_str(before) {
					Ok(n) => "C not read at gram.y:${(a.line + n - 1).to_str()}: ${after}"
					Err(_) => unnamed
				}
			_ => unnamed
		}
	lines =a.code.split_on("\n").map(|l| l.trim()).keep_if(|l| !l.is_empty())
	shown = lines.take_first(6).map(|l| "    ${l}")
	more = if lines.len() > 6 ["    ..."] else []
	Str.join_with(["gram.y:${a.line.to_str()}: rule ${a.rule.to_str()} (${a.rule_text}): ${text}"].concat(shown).concat(more), "\n")
}

read! : Str => Try(Str, [ReadFailed(Str)])
read! = |path| Path.read_utf8!(Path.utf8(path)).map_err(|_| ReadFailed(path))

## Calls the translator handles itself.
special : List(Str)
special = ["makeNode", "palloc", "palloc0", "castNode", "IsA", "nodeTag", "lfirst", "lfirst_node", "linitial_node", "lsecond_node", "llast_node", "list_nth_node", "lnext", "foreach_current_index", "intVal", "strVal", "boolVal", "pstrdup", "_", "copyObject", "INTERVAL_MASK", "psprintf", "ereport", "elog", "errcode", "errmsg", "errmsg_internal", "errdetail", "errhint", "errdetail_internal", "errhint_internal", "parser_errposition", "scanner_errposition", "Assert", "pg_yyget_extra", "parser_yyerror", "base_yyerror", "sizeof"]

## Whether a function raises an error itself.
raises : CParse.Stmt -> Bool
raises = |body| {
	calls = Walk.calls(body)
	calls.contains("ereport") or calls.contains("elog") or calls.contains("parser_yyerror") or calls.contains("base_yyerror")
}

sig : Str, List(Translate.CType), Translate.CType, Bool, List(U64), List(U64) -> Translate.Sig
sig = |roc, params, returns, fails, inout, outs| { roc, params, returns, fails, inout, outs }

## The helpers ported by hand, in `tools/actions_hand.roc`.
hand_sigs : Dict(Str, Translate.Sig)
hand_sigs = Dict.from_list(
	[
		("makeIntConst", sig("make_int_const", [Int, Int], NodePtr("Node"), Bool.False, [], [])),
		("makeFloatConst", sig("make_float_const", [CharPtr, Int], NodePtr("Node"), Bool.False, [], [])),
		("makeStringConst", sig("make_string_const", [CharPtr, Int], NodePtr("Node"), Bool.False, [], [])),
		("makeBitStringConst", sig("make_bit_string_const", [CharPtr, Int], NodePtr("Node"), Bool.False, [], [])),
		("makeBoolAConst", sig("make_bool_a_const", [Boolean, Int], NodePtr("Node"), Bool.False, [], [])),
		("makeNullAConst", sig("make_null_a_const", [Int], NodePtr("Node"), Bool.False, [], [])),
		("makeAConst", sig("make_a_const", [NodePtr("Node"), Int], NodePtr("Node"), Bool.False, [], [])),
		("doNegate", sig("do_negate", [NodePtr("Node"), Int], NodePtr("Node"), Bool.False, [], [])),
		("insertSelectOptions", sig("insert_select_options", [NodePtr("SelectStmt"), ListPtr, ListPtr, NodePtr("SelectLimit"), NodePtr("WithClause"), Void], Void, Bool.True, [0], [])),
		("SplitColQualList", sig("split_col_qual_list", [ListPtr, ListPtr, NodePtr("CollateClause"), Void], Void, Bool.True, [], [1, 2])),
		("processCASbits", sig("process_cas_bits", [Int, Int, CharPtr, Boolean, Boolean, Boolean, Boolean, Boolean, Void], Void, Bool.True, [], [3, 4, 5, 6, 7])),
		("preprocess_pubobj_list", sig("preprocess_pubobj_list", [ListPtr, Void], Void, Bool.True, [0], [])),
		("updateRawStmtEnd", sig("update_raw_stmt_end", [NodePtr("RawStmt"), Int], Void, Bool.False, [0], [])),
		("NameListToString", sig("name_list_to_string", [ListPtr], CharPtr, Bool.False, [], [])),
		("doNegateFloat", sig("do_negate_float_node", [NodePtr("Float")], Void, Bool.False, [0], [])),
	],
)

## Node types the hand-ported helpers use.
hand_types : List(Str)
hand_types = ["A_Const", "Integer", "Float", "String", "Boolean", "BitString", "A_Star", "SelectStmt", "RawStmt", "Constraint", "CollateClause", "PublicationObjSpec", "PublicationTable", "LockingClause", "SelectLimit", "RangeVar", "A_Expr"]

## Postgres's list and string functions, in `Rt`.
native_sigs : Dict(Str, Translate.Sig)
native_sigs = {
	n = NodePtr("Node")
	Dict.from_list(
		[
			("lappend", sig("Rt.lappend", [ListPtr, n], ListPtr, Bool.False, [], [])),
			("lcons", sig("Rt.lcons", [n, ListPtr], ListPtr, Bool.False, [], [])),
			("list_make1", sig("Rt.list_make1", [n], ListPtr, Bool.False, [], [])),
			("list_make2", sig("Rt.list_make2", [n, n], ListPtr, Bool.False, [], [])),
			("list_make3", sig("Rt.list_make3", [n, n, n], ListPtr, Bool.False, [], [])),
			("list_make4", sig("Rt.list_make4", [n, n, n, n], ListPtr, Bool.False, [], [])),
			("list_make5", sig("Rt.list_make5", [n, n, n, n, n], ListPtr, Bool.False, [], [])),
			("list_concat", sig("Rt.list_concat", [ListPtr, ListPtr], ListPtr, Bool.False, [], [])),
			("list_copy", sig("Rt.list_copy", [ListPtr], ListPtr, Bool.False, [], [])),
			("list_copy_tail", sig("Rt.list_copy_tail", [ListPtr, Int], ListPtr, Bool.False, [], [])),
			("list_truncate", sig("Rt.list_truncate", [ListPtr, Int], ListPtr, Bool.False, [], [])),
			("list_length", sig("Rt.list_length", [ListPtr], Int, Bool.False, [], [])),
			("linitial", sig("Rt.linitial", [ListPtr], n, Bool.False, [], [])),
			("lsecond", sig("Rt.lsecond", [ListPtr], n, Bool.False, [], [])),
			("lthird", sig("Rt.lthird", [ListPtr], n, Bool.False, [], [])),
			("lfourth", sig("Rt.lfourth", [ListPtr], n, Bool.False, [], [])),
			("llast", sig("Rt.llast", [ListPtr], n, Bool.False, [], [])),
			("list_nth", sig("Rt.list_nth", [ListPtr, Int], n, Bool.False, [], [])),
			("list_delete_first", sig("Rt.list_delete_first", [ListPtr], ListPtr, Bool.False, [], [])),
			("list_delete_last", sig("Rt.list_delete_last", [ListPtr], ListPtr, Bool.False, [], [])),
			("strcmp", sig("Rt.strcmp", [CharPtr, CharPtr], Int, Bool.False, [], [])),
			("pg_strcasecmp", sig("Rt.pg_strcasecmp", [CharPtr, CharPtr], Int, Bool.False, [], [])),
			("strlen", sig("Rt.strlen", [CharPtr], Int, Bool.False, [], [])),
			("equal", sig("Rt.equal", [n, n], Boolean, Bool.False, [], [])),
		],
	)
}

## `@NAME@` in the hand-ported code, filled in with the constant's value.
fill_constants : Str, Consts.Table -> Try(Str, [UnknownConstant(Str)])
fill_constants = |text, consts| {
	parts = text.split_on("@")
	var $out = parts.first() ?? ""
	var $i = 1
	while $i < parts.len() {
		name = parts.get($i) ?? ""
		after = parts.get($i + 1) ?? ""
		value =
			match Consts.resolve(consts, name) {
				Ok(Int(n)) => if n < 0 "(${n.to_str()})" else n.to_str()
				_ => return Err(UnknownConstant(name))
			}
		$out = "${$out}${value}${after}"
		$i = $i + 2
	}
	Ok($out)
}

## The `%union` members: each member's name and C type.
union_members : Str -> Dict(Str, Translate.CType)
union_members = |prologue| {
	body = ((prologue.split_first("%union").map_ok(|s| s.after) ?? "").split_first("{").map_ok(|s| s.after) ?? "").split_first("}").map_ok(|s| s.before) ?? ""
	body.split_on(";").fold(
		Dict.empty(),
		|acc, decl| {
			d = decl.split_on("\n").keep_if(|line| !line.trim().starts_with("/*")).map(|line| line.trim())
			text = Str.join_with(d, " ").replace_each("\t", " ").trim()
			if text.is_empty() {
				acc
			} else {
				words = text.replace_each("*", " * ").split_on(" ").keep_if(|w| !w.is_empty())
				name = words.last() ?? ""
				type_text = Str.join_with(words.drop_last(1), " ")
				acc.insert(name, Translate.ctype(type_text))
			}
		},
	)
}

license : Str -> Str
license = |copyright| {
	lines : List(Str)
	lines = copyright.trim_end().split_on("\n").map(|line| if line.is_empty() "#" else "# ${line}")
	"# Derived from PostgreSQL 18.6, src/backend/parser/gram.y and the node\n# headers and functions it uses.\n#\n${Str.join_with(lines, "\n")}\n"
}

## `package/Enums.roc`: a named constant for each value of the enums that
## node fields have, such as `Enums.object_table` for `OBJECT_TABLE`.
enums_module : Str, List(Str), Dict(Str, List(Structs.Field)), Dict(Str, List((Str, I64))) -> Str
enums_module = |header, types, structs, enums| {
	used = types.fold(
		[],
		|acc, t|
			(structs.get(t) ?? []).fold(
				acc,
				|a, f| {
					base = f.type.replace_each("const ", "").replace_each("enum ", "").trim()
					if enums.contains(base) and !a.contains(base) a.append(base) else a
				},
			),
	)
	blocks = used.sort_with(compare_str).map(
		|e| {
			constants = (enums.get(e) ?? []).map(|(name, value)| "\t${Translate.snake(name)} : I64\n\t${Translate.snake(name)} = ${value.to_str()}\n")
			"\t# `${e}`\n\n${Str.join_with(constants, "\n")}"
		},
	)
	Str.join_with(
		[
			header,
			"## The values of the C enums that fields of the parse tree hold, by their",
			"## C names in snake case: `Enums.object_table` is `OBJECT_TABLE`. Written",
			"## by `tools/actions.roc`, do not edit.",
			"Enums :: [].{",
			Str.join_with(blocks, "\n"),
			"}",
			"",
		],
		"\n",
	)
}

## `package/Node.roc`: one tag and record per node type.
node_module : Str, List(Str), Dict(Str, List(Structs.Field)) -> Str
node_module = |header, types, structs| {
	tags : List(Str)
	tags = types.map(|t| "\t${tag(t)}(Node.${tag(t)}),")
	records : List(Str)
	records = types.map(
		|t| {
			fields = structs.get(t) ?? []
			fields_text : List(Str)
			fields_text = fields.map(|f| "${Translate.snake(f.name)} : ${if is_embedded(f.type, structs) "Node" else Translate.roc_type_of(f.type)}")
			defaults : List(Str)
			# Sharing the constant here avoids duplicating the large Node type.
			# Action expressions use inline Null instead: reading the constant
			# repeatedly during compile-time parsing is substantially slower.
			defaults = fields.map(|f| {
				zero = match Translate.ctype(f.type) {
					NodePtr(_) => "Node.null"
					_ => Translate.zero_of(f.type)
				}
				"${Translate.snake(f.name)}: ${if is_embedded(f.type, structs) "Node.${tag(f.type)}(Node.${Translate.snake(f.type)}_default)" else zero}"
			})
			snake = Translate.snake(t)
			record_type = if fields.is_empty() "{}" else "{ ${Str.join_with(fields_text, ", ")} }"
			record_default = if fields.is_empty() "{}" else "{ ${Str.join_with(defaults, ", ")} }"
			Str.join_with(
				[
					"\t## `${t}`",
					"\t${tag(t)} : ${record_type}",
					"",
					"\t${snake}_default : Node.${tag(t)}",
					"\t${snake}_default = ${record_default}",
					"",
					"\t${snake}_of : Node -> Node.${tag(t)}",
					"\t${snake}_of = |n|",
					"\t\tmatch n {",
					"\t\t\t${tag(t)}(r) => r",
					"\t\t\t_ => crash \"expected ${t}, got \${Node.tag(n)}\"",
					"\t\t}",
					"",
				],
				"\n",
			)
		},
	)
	tag_arms : List(Str)
	tag_arms = types.map(|t| "\t\t\t${tag(t)}(_) => \"${t}\"")
	Str.join_with(
		[
			header,
			"## The nodes of Postgres 18.6's raw parse tree, one tag per node type of",
			"## `src/include/nodes`, with the node's fields as a record. A pointer to",
			"## a node is a `Node`, with `Null` for NULL; a `List *` is a list, empty",
			"## for NIL; a `char *` is a `Node.Text`. Written by `tools/actions.roc`,",
			"## do not edit.",
			"Node := [",
			"\tNull,",
			"\tNodeList(List(Node)),",
		]
			.concat(tags)
			.concat(["].{", "\t## The immutable null node, shared by record defaults.", "\tnull : Node", "\tnull = Null", "", "\t## A `char *`: the text, or NULL.", "\tText : Try(Str, [Null])", ""])
			.concat(records)
			.concat(
				[
					"\t## The node's type as named in C, such as `SelectStmt`, `List` for",
					"\t## a list, and the empty string for NULL.",
					"\ttag : Node -> Str",
					"\ttag = |n|",
					"\t\tmatch n {",
					"\t\t\tNull => \"\"",
					"\t\t\tNodeList(_) => \"List\"",
				],
			)
			.concat(tag_arms)
			.concat(["\t\t}", "", "\t## Two trees alike, as Postgres's `equal` compares them."])
			.concat(["\tis_eq : Node, Node -> Bool", "\tis_eq = |a, b|", "\t\tmatch (a, b) {", "\t\t\t(Null, Null) => Bool.True", "\t\t\t(NodeList(x), NodeList(y)) => x == y"])
			.concat(types.map(|t| "\t\t\t(${tag(t)}(x), ${tag(t)}(y)) => x == y"))
			.concat(["\t\t\t_ => Bool.False", "\t\t}", "", "\tis_null : Node -> Bool", "\tis_null = |n|", "\t\tmatch n {", "\t\t\tNull => Bool.True", "\t\t\t_ => Bool.False", "\t\t}", ""])
			.concat(equal_code(types, structs))
			.concat(["}", ""]),
		"\n",
	)
}

tag : Str -> Str
tag = |type| type.replace_each("_", "")

compare_str : Str, Str -> [Before, Same, After]
compare_str = |a, b| {
	x = a.to_utf8()
	y = b.to_utf8()
	var $i = 0
	var $result = Same
	var $done = Bool.False
	while !$done {
		match (x.get($i), y.get($i)) {
			(Ok(p), Ok(q)) =>
				if p < q {
					$result = Before
					$done = Bool.True
				} else if p > q {
					$result = After
					$done = Bool.True
				} else {
					$i = $i + 1
				}
			(Err(_), Ok(_)) => {
				$result = Before
				$done = Bool.True
			}
			(Ok(_), Err(_)) => {
				$result = After
				$done = Bool.True
			}
			_ => {
				$done = Bool.True
			}
		}
	}
	$result
}

## A struct held in place rather than through a pointer.
is_embedded : Str, Dict(Str, List(Structs.Field)) -> Bool
is_embedded = |type, structs| !type.contains("*") and type != "ValUnion" and structs.contains(type)

## `Node.equal`, Postgres's `equal`: trees alike apart from the fields it
## does not compare, which are locations, how a call was written
## (`CoercionForm`) and fields marked `equal_ignore`. A field marked
## `equal_ignore_if_zero` counts only when set on both sides.
equal_code : List(Str), Dict(Str, List(Structs.Field)) -> List(Str)
equal_code = |types, structs| {
	arms = types.map(
		|t| {
			checks = (structs.get(t) ?? []).keep_oks(|f| field_equal(f, structs))
			if checks.is_empty() {
				"\t\t\t(${tag(t)}(_), ${tag(t)}(_)) => Bool.True"
			} else {
				"\t\t\t(${tag(t)}(x), ${tag(t)}(y)) => ${Str.join_with(checks, " and ")}"
			}
		},
	)
	[
		"\t## Postgres's `equal`: two trees alike, not counting locations, how a",
		"\t## call was written (`CoercionForm`), and fields marked `equal_ignore`.",
		"\tequal : Node, Node -> Bool",
		"\tequal = |a, b|",
		"\t\tmatch (a, b) {",
		"\t\t\t(Null, Null) => Bool.True",
		"\t\t\t(Null, NodeList(y)) => y.is_empty()",
		"\t\t\t(NodeList(x), Null) => x.is_empty()",
		"\t\t\t(NodeList(x), NodeList(y)) => Node.list_equal(x, y)",
	]
		.concat(arms)
		.concat(
			[
				"\t\t\t_ => Bool.False",
				"\t\t}",
				"",
				"\tlist_equal : List(Node), List(Node) -> Bool",
				"\tlist_equal = |x, y| {",
				"\t\tif x.len() != y.len() {",
				"\t\t\treturn Bool.False",
				"\t\t}",
				"\t\tvar $i = 0",
				"\t\twhile $i < x.len() {",
				"\t\t\tif !Node.equal(x.get($i) ?? Null, y.get($i) ?? Null) {",
				"\t\t\t\treturn Bool.False",
				"\t\t\t}",
				"\t\t\t$i = $i + 1",
				"\t\t}",
				"\t\tBool.True",
				"\t}",
			],
		)
}

field_equal : Structs.Field, Dict(Str, List(Structs.Field)) -> Try(Str, [Skip])
field_equal = |f, structs| {
	name = Translate.snake(f.name)
	if f.type == "ParseLoc" or f.type == "CoercionForm" or f.attrs.contains("equal_ignore") {
		Err(Skip)
	} else if f.attrs.contains("equal_ignore_if_zero") {
		Ok("(x.${name} == 0 or y.${name} == 0 or x.${name} == y.${name})")
	} else if is_embedded(f.type, structs) {
		Ok("Node.equal(x.${name}, y.${name})")
	} else {
		match Translate.ctype(f.type) {
			NodePtr(_) => Ok("Node.equal(x.${name}, y.${name})")
			ListPtr => Ok("Node.list_equal(x.${name}, y.${name})")
			_ => Ok("x.${name} == y.${name}")
		}
	}
}
