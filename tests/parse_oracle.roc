## [Parse] against Postgres's own parser, over a golden file of statements
## and what the server's parser (through libpg_query, see `local/oracle`)
## makes of each: the raw parse tree as libpg_query's JSON, or the error
## and where it was raised. The golden file is made locally and never
## committed.
##
##     roc tests/parse_oracle.roc [--all] local/golden/regress-parse.jsonl
##
## It shows the first 25 differences, or all of them with `--all`.
##
## A statement passes when both refuse it with the same error at the same
## place, or both accept it and the trees, written as JSON by [NodeJson],
## are the same text. Where libpg_query itself parts from the server, the
## statement counts apart, with the reason ([libpg_query_differs]).
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../package/internals.roc",
}

import pf.Stdout
import pf.File
import pf.Path
import pf.OsStr
import pg.Parse
import NodeJson

Golden : {
	file : Str,
	n : U64,
	sql : Str,
	error : Try({ message : Str, cursor : U64, origin : Str }, [Null]),
}

main! : List(OsStr) => Try({}, _)
main! = |args| {
	path = args.last().map_ok(OsStr.display) ?? "local/golden/regress-parse.jsonl"
	shown = if args.any(|a| OsStr.display(a) == "--all") 1000000 else 25
	if !(Path.exists!(Path.utf8(path)) ?? Bool.False) {
		Stdout.line!("skipped: no golden file at ${path}")?
		return Ok({})
	}
	reader = File.open_reader_with_capacity!(Path.utf8(path), 1048576)?
	var $total = 0.U64
	var $same = 0.U64
	var $differ = 0.U64
	var $trees = 0.U64
	var $known = 0.U64
	var $done = Bool.False
	while !$done {
		line = reader.read_line!()?
		if line.is_empty() {
			$done = Bool.True
		} else {
			text = Str.from_utf8_lossy(line).trim_end()
			golden : Golden
			golden = Json.parse(text) ? |_| BadGoldenLine($total)
			$total = $total + 1
			expected = expected_of(golden, text)
			got =
				match Parse.parse(golden.sql) {
					Ok(stmts) => NodeJson.stmts(stmts)
					Err(p) => "error ${p.message} @${p.cursor.to_str()}"
				}
			if expected == got {
				$same = $same + 1
			} else if libpg_query_differs(expected, got) {
				$known = $known + 1
			} else {
				$differ = $differ + 1
				is_tree = !expected.starts_with("error ") and !got.starts_with("error ")
				if is_tree {
					$trees = $trees + 1
				}
				if $differ <= shown {
					Stdout.line!("${golden.file}:${golden.n.to_str()} ${excerpt(golden.sql, 0, 160)}\n${difference(expected, got)}")?
				}
			}
		}
	}
	Stdout.line!("${$total.to_str()} statements: ${$same.to_str()} same, ${$known.to_str()} where libpg_query differs from Postgres, ${$differ.to_str()} different (${$trees.to_str()} of them both accepted with different trees)")?
	if $differ > 0 Err(ParseMismatches($differ)) else Ok({})
}

## The error, or the `stmts` array of the golden tree as it stands in the
## line, which the tree's writer puts between `"tree":` and the error.
expected_of : Golden, Str -> Str
expected_of = |golden, line|
	match golden.error {
		Ok(err) => "error ${err.message} @${err.cursor.to_str()}"
		Err(Null) => {
			tree = ((line.split_first(",\"tree\":").map_ok(|s| s.after) ?? "").split_last(",\"error\":").map_ok(|s| s.before)) ?? ""
			stmts = tree.split_first("\"stmts\":").map_ok(|s| s.after) ?? ""
			Str.from_utf8_lossy(stmts.to_utf8().drop_last(1))
		}
	}

## Where two outputs part, with some text around it.
difference : Str, Str -> Str
difference = |expected, got| {
	a = expected.to_utf8()
	b = got.to_utf8()
	var $i = 0
	while $i < a.len() and $i < b.len() and a.get($i) == b.get($i) {
		$i = $i + 1
	}
	from = if $i > 100 $i - 100 else 0
	"    expected ...${excerpt(expected, from, 260)}\n    got      ...${excerpt(got, from, 260)}"
}

excerpt : Str, U64, U64 -> Str
excerpt = |text, from, len| {
	bytes = text.to_utf8().drop_first(from)
	one_line = bytes.map(|b| if b == '\n' or b == '\r' or b == '\t' ' ' else b)
	if one_line.len() > len "${Str.from_utf8_lossy(one_line.take_first(len))}..." else Str.from_utf8_lossy(one_line)
}

## Where libpg_query, the oracle, parts from the server it is built from,
## so our parser, which follows the server, cannot agree with it:
##
## - Its patch 09 accepts junk after a parameter, as in `$1a`, which the
##   server refuses with "trailing junk after parameter".
libpg_query_differs : Str, Str -> Bool
libpg_query_differs = |expected, got|
	!expected.starts_with("error ") and got.starts_with("error trailing junk after parameter ")
