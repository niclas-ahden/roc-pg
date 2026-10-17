#!/usr/bin/env roc
## Writes `package/Grammar.roc`: the parse tables bison makes of Postgres's
## grammar, the grammar's token numbers, and the length and left-hand side
## of each rule.
##
## It needs the Postgres source in `local/` (see PARSER.md) and
## bison on the path:
##
##     nix shell nixpkgs#bison -c roc tools/grammar.roc
##
## Each table is a text of three characters per entry, 32 entries per line,
## so the tables cost a string literal at compile time and each lookup
## decodes one entry.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
}

import pf.Stdout
import pf.Cmd
import pf.Path
import pf.OsStr

pg_dir = "local/postgres-18.6"

out_dir = "local/gram"

## Added to every entry so the smallest (-5941) is not negative.
offset : I64
offset = 8192

per_line : U64
per_line = 32

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	Path.create_all!(Path.utf8(out_dir))?
	gram_y = "${pg_dir}/src/backend/parser/gram.y"
	Cmd.exec!(OsStr.from_str("bison"), ["-Wnone", "-d", "-o", "${out_dir}/gram.c", gram_y].map(OsStr.from_str)) ? |_| BisonFailed
	c = Path.read_utf8!(Path.utf8("${out_dir}/gram.c"))?
	h = Path.read_utf8!(Path.utf8("${out_dir}/gram.h"))?
	kwlist = Path.read_utf8!(Path.utf8("${pg_dir}/src/include/parser/kwlist.h"))?
	copyright = Path.read_utf8!(Path.utf8("${pg_dir}/COPYRIGHT"))?

	numbers = token_numbers(h)
	keyword_tokens = keyword_token_names(kwlist).map(|name| number_of(numbers, name))
	named = |name| number_of(numbers, name)

	tables = [
		("translate", array(c, "yytranslate")?),
		("pact", array(c, "yypact")?),
		("defact", array(c, "yydefact")?),
		("pgoto", array(c, "yypgoto")?),
		("defgoto", array(c, "yydefgoto")?),
		("table", array(c, "yytable")?),
		("check", array(c, "yycheck")?),
		("r1", array(c, "yyr1")?),
		("r2", array(c, "yyr2")?),
	]
	names = string_array(c, "yytname")?

	header_lines : List(Str)
	header_lines = copyright.trim_end().split_on("\n").map(|line| if line.is_empty() "#" else "# ${line}")
	header = Str.join_with(header_lines, "\n")
	var $out = "# Derived from PostgreSQL 18.6, src/backend/parser/gram.y, by bison.\n#\n${header}\n\n"
	$out = $out.concat(
		\\## Postgres 18.6's grammar as the parse tables bison 3.8 makes of
		\\## `src/backend/parser/gram.y`, for [Parse]. Written by
		\\## `tools/grammar.roc`, do not edit.
		\\Grammar :: [].{
		\\
	)
	for (name, value) in [
		("final_state", define(c, "YYFINAL")?),
		("last", define(c, "YYLAST")?),
		("ntokens", define(c, "YYNTOKENS")?),
		("max_token", define(c, "YYMAXUTOK")?),
		("pact_ninf", define(c, "YYPACT_NINF")?),
		("table_ninf", define(c, "YYTABLE_NINF")?),
	] {
		$out = $out.concat("\t${name} : I64\n\t${name} = ${value.to_str()}\n\n")
	}
	for (field, token) in [
		("ident", "IDENT"),
		("uident", "UIDENT"),
		("fconst", "FCONST"),
		("sconst", "SCONST"),
		("usconst", "USCONST"),
		("bconst", "BCONST"),
		("xconst", "XCONST"),
		("op", "Op"),
		("iconst", "ICONST"),
		("param", "PARAM"),
		("typecast", "TYPECAST"),
		("dot_dot", "DOT_DOT"),
		("colon_equals", "COLON_EQUALS"),
		("equals_greater", "EQUALS_GREATER"),
		("less_equals", "LESS_EQUALS"),
		("greater_equals", "GREATER_EQUALS"),
		("not_equals", "NOT_EQUALS"),
		("format_la", "FORMAT_LA"),
		("not_la", "NOT_LA"),
		("nulls_la", "NULLS_LA"),
		("with_la", "WITH_LA"),
		("without_la", "WITHOUT_LA"),
		("mode_type_name", "MODE_TYPE_NAME"),
	] {
		$out = $out.concat("\t${field}_token : I64\n\t${field}_token = ${named(token).to_str()}\n\n")
	}
	$out = $out.concat("\t## The token number of each keyword, in the order of [Keywords.all].\n\tkeyword_token : U64 -> I64\n\tkeyword_token = |k| keyword_tokens.get(k) ?? 0\n\n")
	$out = $out.concat("\t## A grammar symbol's name, as bison prints it.\n\tsymbol_name : I64 -> Str\n\tsymbol_name = |s| symbol_names.get(s.to_u64_wrap()) ?? \"?\"\n\n")
	for (name, _) in tables {
		$out = $out.concat("\t${name} : I64 -> I64\n\t${name} = |i| entry(${name}_bytes, i)\n\n")
	}
	$out = $out.concat("}\n\n")
	keyword_list : List(Str)
	keyword_list = keyword_tokens.map(|n| n.to_str())
	$out = $out.concat("keyword_tokens : List(I64)\nkeyword_tokens = [${Str.join_with(keyword_list, ", ")}]\n\n")
	name_lines : List(Str)
	name_lines = names.map(|n| "\t${Str.inspect(n)},")
	$out = $out.concat("symbol_names : List(Str)\nsymbol_names = [\n${Str.join_with(name_lines, "\n")}\n]\n\n")
	for (name, values) in tables {
		$out = $out.concat("${name}_bytes : List(U8)\n${name}_bytes = ${name}_text.to_utf8()\n\n${name}_text : Str\n${name}_text =\n${encode(values)}\n\n")
	}
	$out = $out.concat(decoder)
	Path.write_utf8!(Path.utf8("package/Grammar.roc"), $out)?
	sizes : List(Str)
	sizes = tables.map(|(n, v)| "${n} ${v.len().to_str()}")
	Stdout.line!("wrote package/Grammar.roc: ${Str.join_with(sizes, ", ")}")
}

## `#define NAME value` in bison's output.
define : Str, Str -> Try(I64, [MissingDefine(Str)])
define = |c, name| {
	after = c.split_first("#define ${name} ").map_ok(|s| s.after) ? |_| MissingDefine(name)
	line = after.split_first("\n").map_ok(|s| s.before) ?? after
	I64.from_str(line.trim().replace_each("(", "").replace_each(")", "")).map_err(|_| MissingDefine(name))
}

## The numbers of a `static const ... name[] = { ... };` table.
array : Str, Str -> Try(List(I64), [MissingTable(Str)])
array = |c, name| {
	after = c.split_first(" ${name}[] =").map_ok(|s| s.after) ? |_| MissingTable(name)
	body = after.split_first("{").map_ok(|s| s.after) ? |_| MissingTable(name)
	inside = body.split_first("}").map_ok(|s| s.before) ? |_| MissingTable(name)
	numbers : List(I64)
	numbers = inside.split_on(",").map(|s| s.trim()).keep_if(|s| !s.is_empty()).map(|s| I64.from_str(s) ?? 0)
	Ok(numbers)
}

## The strings of `yytname`, unquoted.
string_array : Str, Str -> Try(List(Str), [MissingTable(Str)])
string_array = |c, name| {
	after = c.split_first(" ${name}[] =").map_ok(|s| s.after) ? |_| MissingTable(name)
	body = after.split_first("{").map_ok(|s| s.after) ? |_| MissingTable(name)
	inside = (body.split_first("\n};").map_ok(|s| s.before) ? |_| MissingTable(name)).to_utf8()
	var $names = []
	var $i = 0
	while $i < inside.len() {
		if inside.get($i) == Ok('"') {
			var $j = $i + 1
			var $cur = []
			while $j < inside.len() and inside.get($j) != Ok('"') {
				b = inside.get($j) ?? 0
				if b == '\\' {
					$cur = $cur.append(inside.get($j + 1) ?? 0)
					$j = $j + 2
				} else {
					$cur = $cur.append(b)
					$j = $j + 1
				}
			}
			$names = $names.append(Str.from_utf8_lossy($cur))
			$i = $j + 1
		} else if inside.get($i) == Ok('Y') and inside.get($i + 1) == Ok('Y') {
			# YY_NULLPTR ends the list.
			$i = inside.len()
		} else {
			$i = $i + 1
		}
	}
	Ok($names)
}

## `NAME = 258,` lines of the token enum in bison's header.
token_numbers : Str -> List((Str, I64))
token_numbers = |h| {
	enum_body = (h.split_first("enum yytokentype").map_ok(|s| s.after) ?? "").split_first("};").map_ok(|s| s.before) ?? ""
	enum_body.split_on("\n").fold(
		[],
		|acc, line| {
			code = (line.split_first("/*").map_ok(|s| s.before) ?? line).trim().drop_suffix(",")
			match code.split_first(" = ") {
				Ok({ before, after }) =>
					match I64.from_str(after.trim()) {
						Ok(n) => acc.append((before.trim(), n))
						Err(_) => acc
					}
				Err(_) => acc
			}
		},
	)
}

number_of : List((Str, I64)), Str -> I64
number_of = |numbers, name|
	match numbers.find_first(|(n, _)| n == name) {
		Ok((_, v)) => v
		Err(_) => crash "no token ${name} in gram.h"
	}

## The token names of `PG_KEYWORD("abort", ABORT_P, ...)` lines, in order.
keyword_token_names : Str -> List(Str)
keyword_token_names = |kwlist|
	kwlist.split_on("\n").fold(
		[],
		|acc, line|
			if line.starts_with("PG_KEYWORD(") {
				fields = line.split_on(",")
				acc.append((fields.get(1) ?? "").trim())
			} else {
				acc
			},
	)

## Three characters per entry, 32 entries per line, as a multiline string.
encode : List(I64) -> Str
encode = |values| {
	digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-_".to_utf8()
	var $lines = []
	var $cur = []
	for v in values {
		u = (v + offset).to_u64_wrap()
		$cur = $cur.concat([digits.get(u // 4096) ?? '0', digits.get((u // 64) % 64) ?? '0', digits.get(u % 64) ?? '0'])
		if $cur.len() == per_line * 3 {
			$lines = $lines.append(Str.from_utf8_lossy($cur))
			$cur = []
		}
	}
	if !$cur.is_empty() {
		$lines = $lines.append(Str.from_utf8_lossy($cur))
	}
	prefixed : List(Str)
	prefixed = $lines.map(|l| "\t\\\\${l}")
	Str.join_with(prefixed, "\n")
}

decoder =
	\\## Entry `i` of a table text: three characters in base 64, 32 per line
	\\## of 97 bytes with its newline, less the offset.
	\\entry : List(U8), I64 -> I64
	\\entry = |bytes, i| {
	\\	k = i.to_u64_wrap()
	\\	p = (k // 32) * 97 + (k % 32) * 3
	\\	(digit(bytes, p) * 4096 + digit(bytes, p + 1) * 64 + digit(bytes, p + 2)) - 8192
	\\}
	\\
	\\digit : List(U8), U64 -> I64
	\\digit = |bytes, p| {
	\\	c = bytes.get(p) ?? '0'
	\\	if c >= '0' and c <= '9' {
	\\		(c - '0').to_i64()
	\\	} else if c >= 'A' and c <= 'Z' {
	\\		(c - 'A').to_i64() + 10
	\\	} else if c >= 'a' and c <= 'z' {
	\\		(c - 'a').to_i64() + 36
	\\	} else if c == '-' {
	\\		62
	\\	} else {
	\\		63
	\\	}
	\\}
	\\
