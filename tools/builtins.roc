#!/usr/bin/env roc
## Writes `package/Builtins.roc`: the types, functions, operators and
## casts of Postgres's catalog, from the `.dat` files the server
## is built from, for typing function calls and operators the way the
## server does.
##
## It needs the Postgres 18.6 source in `local/postgres-18.6`, from
## `nix build nixpkgs#postgresql_18.src`:
##
##     roc tools/builtins.roc
##
## Types are spelled as `pg_dump` spells column types (`integer`,
## `timestamp with time zone`, `text[]`), so they compare with the
## catalog's. Each table is text, one entry per line sorted by its first
## field, so it costs a string literal at compile time and a lookup is a
## binary search.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Path
import pf.OsStr
import pg.Catalog

pg_dir = "local/postgres-18.6"

catalog_dir = "${pg_dir}/src/include/catalog"

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	types = records(Path.read_utf8!(Path.utf8("${catalog_dir}/pg_type.dat"))?)
	procs = records(Path.read_utf8!(Path.utf8("${catalog_dir}/pg_proc.dat"))?)
	operators = records(Path.read_utf8!(Path.utf8("${catalog_dir}/pg_operator.dat"))?)
	casts = records(Path.read_utf8!(Path.utf8("${catalog_dir}/pg_cast.dat"))?)
	copyright = Path.read_utf8!(Path.utf8("${pg_dir}/COPYRIGHT"))?

	type_lines = types.keep_oks(type_line)
	# A strict function's name, for the strictness of the operator it runs.
	strict_procs = procs.keep_if(|p| field(p, "proisstrict", "t") == "t").map(|p| field(p, "proname", ""))
	system_functions = Catalog.parse(Path.read_utf8!(Path.utf8("${pg_dir}/src/backend/catalog/system_functions.sql"))?) ? |_| BadSystemFunctions
	function_lines = procs.keep_oks(|p| function_line(p, system_functions.functions()))
	operator_lines = operators.keep_oks(|o| operator_line(o, strict_procs))
	cast_lines = casts.keep_if(|c| ["i", "a"].contains(field(c, "castcontext", ""))).keep_oks(cast_line)

	notice = Str.join_with(copyright.split_on("\n").map(|l| if l == "" "#" else "# ${l}"), "\n")
	out = Str.join_with(
		[
			"# Derived from PostgreSQL 18.6, src/include/catalog: pg_type.dat,",
			"# pg_proc.dat, pg_operator.dat and pg_cast.dat.",
			"#",
			notice,
			"",
			"## The types, functions, operators and casts of Postgres 18.6's",
			"## catalog. Types are spelled as `pg_dump` spells column types. Each table",
			"## is text, one entry per line, fields split by tabs, lines sorted by their",
			"## first field. Written by `tools/builtins.roc`, do not edit.",
			"##",
			"## - [Builtins.types]: name, category (`typcategory`), `p` when preferred.",
			"##   Arrays are not listed: `x[]` is in category `A`.",
			"## - [Builtins.functions]: name, argument types split by commas, result",
			"##   type, then flags: `s` strict, `a` aggregate, `w` window, `r` returns a",
			"##   set, `v` the last argument is variadic, `d` and a count: that many",
			"##   trailing arguments have defaults. Last, the columns of a function with",
			"##   several output parameters, `name:type` split by `;`.",
			"## - [Builtins.operators]: name, left type (empty for a prefix operator),",
			"##   right type, result type, then `s` when strict.",
			"## - [Builtins.casts]: source type, target type, then `i` for a cast that",
			"##   applies implicitly, `a` for one that applies only on assignment.",
			"Builtins :: [].{",
			"\ttypes : List(U8)",
			"\ttypes = types_text.to_utf8()",
			"",
			"\tfunctions : List(U8)",
			"\tfunctions = functions_text.to_utf8()",
			"",
			"\toperators : List(U8)",
			"\toperators = operators_text.to_utf8()",
			"",
			"\tcasts : List(U8)",
			"\tcasts = casts_text.to_utf8()",
			"}",
			"",
			text_constant("types_text", type_lines),
			text_constant("functions_text", function_lines),
			text_constant("operators_text", operator_lines),
			text_constant("casts_text", cast_lines),
		],
		"\n",
	)
	Path.write_utf8!(Path.utf8("package/Builtins.roc"), out)?
	Stdout.line!("wrote package/Builtins.roc: ${type_lines.len().to_str()} types, ${function_lines.len().to_str()} functions, ${operator_lines.len().to_str()} operators, ${cast_lines.len().to_str()} casts")
}

## A multiline string constant of `lines`, sorted by bytes.
text_constant : Str, List(Str) -> Str
text_constant = |name, lines| {
	sorted = lines.sort_with(compare_bytes)
	body = Str.join_with(sorted.map(|l| "\t\\\\${l}"), "\n")
	"${name} : Str\n${name} =\n${body}\n"
}

compare_bytes : Str, Str -> [Before, Same, After]
compare_bytes = |a, b| {
	x = a.to_utf8()
	y = b.to_utf8()
	var $i = 0
	while $i < x.len() and $i < y.len() {
		p = x.get($i) ?? 0
		q = y.get($i) ?? 0
		if p < q {
			return Before
		}
		if p > q {
			return After
		}
		$i = $i + 1
	}
	if x.len() < y.len() {
		Before
	} else if x.len() > y.len() {
		After
	} else {
		Same
	}
}

Record : List((Str, Str))

field : Record, Str, Str -> Str
field = |record, key, default|
	match record.find_first(|(k, _)| k == key) {
		Ok((_, value)) => value
		Err(_) => default
	}

## Types no query can hand a function or get from one.
internal_types = ["internal", "cstring", "trigger", "event_trigger", "language_handler", "fdw_handler", "index_am_handler", "tsm_handler", "table_am_handler", "pg_ddl_command", "opaque"]

## A type of a `.dat` file, spelled as `pg_dump` spells it.
dump_name : Str -> Str
dump_name = |name|
	if name.starts_with("_") {
		"${dump_name(name.drop_prefix("_"))}[]"
	} else {
		match name {
			"bool" => "boolean"
			"int2" => "smallint"
			"int4" => "integer"
			"int8" => "bigint"
			"float4" => "real"
			"float8" => "double precision"
			"varchar" => "character varying"
			"bpchar" => "character"
			"varbit" => "bit varying"
			"timestamp" => "timestamp without time zone"
			"timestamptz" => "timestamp with time zone"
			"time" => "time without time zone"
			"timetz" => "time with time zone"
			_ => name
		}
	}

type_line : Record -> Try(Str, [Skip])
type_line = |t| {
	name = field(t, "typname", "")
	if name == "" or internal_types.contains(name) {
		Err(Skip)
	} else {
		preferred = if field(t, "typispreferred", "f") == "t" "p" else ""
		Ok("${dump_name(name)}\t${field(t, "typcategory", "U")}\t${preferred}")
	}
}

function_line : Record, List(Catalog.Function) -> Try(Str, [Skip])
function_line = |p, with_defaults| {
	name = field(p, "proname", "")
	kind = field(p, "prokind", "f")
	args = field(p, "proargtypes", "").split_on(" ").drop_if(|a| a == "").map(dump_name)
	result = field(p, "prorettype", "")
	if name == "" or kind == "p" or internal_types.contains(result) or args.any(|a| internal_types.contains(a)) {
		Err(Skip)
	} else {
		# `system_functions.sql` redefines some functions with defaults.
		defaults =
			match with_defaults.find_first(|f| f.name == name and f.args == args and f.defaults > 0) {
				Ok(f) => "d${f.defaults.to_str()}"
				Err(_) => ""
			}
		flags = Str.join_with(
			[
				if field(p, "proisstrict", "t") == "t" "s" else "",
				if kind == "a" "a" else "",
				if kind == "w" "w" else "",
				if field(p, "proretset", "f") == "t" "r" else "",
				if field(p, "provariadic", "0") != "0" "v" else "",
				defaults,
			],
			"",
		)
		Ok("${name}\t${Str.join_with(args, ",")}\t${dump_name(result)}\t${flags}\t${outputs(p)}")
	}
}

## The columns of a function with several output parameters, as
## `name:type` split by `;`: the `o`, `b` and `t` entries of `proargmodes`.
outputs : Record -> Str
outputs = |p| {
	types = array_field(p, "proallargtypes")
	modes = array_field(p, "proargmodes")
	names = array_field(p, "proargnames")
	columns = modes.map_with_index(|mode, i| (mode, i)).keep_oks(
		|(mode, i)|
			if ["o", "b", "t"].contains(mode) {
				Ok("${names.get(i) ?? "column${(i + 1).to_str()}"}:${dump_name(types.get(i) ?? "")}")
			} else {
				Err(NotAnOutput)
			},
	)
	if columns.len() > 1 Str.join_with(columns, ";") else ""
}

## A `{a,b,c}` value.
array_field : Record, Str -> List(Str)
array_field = |record, key| field(record, key, "").drop_prefix("{").drop_suffix("}").split_on(",").drop_if(|v| v == "")

operator_line : Record, List(Str) -> Try(Str, [Skip])
operator_line = |o, strict_procs| {
	name = field(o, "oprname", "")
	left = field(o, "oprleft", "0")
	right = field(o, "oprright", "0")
	result = field(o, "oprresult", "")
	if name == "" or [left, right, result].any(|t| internal_types.contains(t)) {
		Err(Skip)
	} else {
		strict = if strict_procs.contains(field(o, "oprcode", "")) "s" else ""
		left_name = if left == "0" "" else dump_name(left)
		Ok("${name}\t${left_name}\t${dump_name(right)}\t${dump_name(result)}\t${strict}")
	}
}

cast_line : Record -> Try(Str, [Skip])
cast_line = |c| {
	source = field(c, "castsource", "")
	target = field(c, "casttarget", "")
	if source == "" or target == "" {
		Err(Skip)
	} else {
		Ok("${dump_name(source)}\t${dump_name(target)}\t${field(c, "castcontext", "")}")
	}
}

## The records of a `.dat` file: `{ key => 'value', ... }`, with `#`
## comments between them and `\` escaping a byte inside a value.
records : Str -> List(Record)
records = |text| {
	bytes = text.to_utf8()
	var $out = []
	var $current = []
	var $key = []
	var $i = 0
	var $in_record = Bool.False
	while $i < bytes.len() {
		b = bytes.get($i) ?? 0
		if b == '#' and !$in_record {
			while $i < bytes.len() and bytes.get($i) != Ok('\n') {
				$i = $i + 1
			}
		} else if b == '{' {
			$in_record = Bool.True
			$current = []
			$key = []
			$i = $i + 1
		} else if b == '}' {
			$in_record = Bool.False
			$out = $out.append($current)
			$i = $i + 1
		} else if $in_record and b == '\'' {
			var $value = []
			$i = $i + 1
			while $i < bytes.len() and bytes.get($i) != Ok('\'') {
				c = bytes.get($i) ?? 0
				if c == '\\' {
					$value = $value.append(bytes.get($i + 1) ?? 0)
					$i = $i + 2
				} else {
					$value = $value.append(c)
					$i = $i + 1
				}
			}
			$current = $current.append((Str.from_utf8_lossy($key), Str.from_utf8_lossy($value)))
			$key = []
			$i = $i + 1
		} else if $in_record and ((b >= 'a' and b <= 'z') or (b >= '0' and b <= '9') or b == '_') {
			$key = $key.append(b)
			$i = $i + 1
		} else {
			$i = $i + 1
		}
	}
	$out
}
