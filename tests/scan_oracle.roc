## [Scan] against Postgres's own lexer. The golden file holds statements and
## what the server's lexer (through libpg_query, see `local/oracle`) makes
## of them: the tokens, or the error. It is made locally and never
## committed, since it holds Postgres's own test queries.
##
##     roc tests/scan_oracle.roc local/golden/regress-tokens.jsonl
##
## libpg_query differs from the server in two known ways, and a mismatch of
## either kind is counted apart, to be checked against a real server: it
## accepts `$1abc`, which the server calls trailing junk, and it ends a
## string constant at a comment, where the server lets the constant continue
## on the next line.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../package/internals.roc",
}

import pf.Stdout
import pf.File
import pf.Path
import pf.OsStr
import pg.Scan
import pg.Keywords

GoldenToken : { s : U64, e : U64, t : Str, k : Str }

Golden : {
	file : Str,
	n : U64,
	sql : Str,
	tokens : Try(List(GoldenToken), [Null]),
	error : Try({ message : Str, cursor : U64 }, [Null]),
}

## How many mismatches to print.
shown : U64
shown = 40

main! : List(OsStr) => Try({}, _)
main! = |args| {
	path =
		match args {
			[file] => OsStr.display(file)
			_ => "local/golden/regress-tokens.jsonl"
		}
	if !(Path.exists!(Path.utf8(path)) ?? Bool.False) {
		Stdout.line!("skipped: no golden file at ${path}")?
		return Ok({})
	}
	reader = File.open_reader_with_capacity!(Path.utf8(path), 1048576)?
	var $total = 0.U64
	var $same = 0.U64
	var $differ = 0.U64
	var $diverge = 0.U64
	var $done = Bool.False
	while !$done {
		line = reader.read_line!()?
		if line.is_empty() {
			$done = Bool.True
		} else {
			golden : Golden
			golden = Json.parse(Str.from_utf8_lossy(line)) ? |_| BadGoldenLine($total)
			$total = $total + 1
			match compare(golden) {
				Same => {
					$same = $same + 1
				}
				Diverges(report) => {
					$diverge = $diverge + 1
					if $diverge <= 10 {
						Stdout.line!("divergence (check with a server) ${report}")?
					}
				}
				Differs(report) => {
					$differ = $differ + 1
					if $differ <= shown {
						Stdout.line!(report)?
					}
				}
			}
		}
	}
	Stdout.line!("${$total.to_str()} statements: ${$same.to_str()} same, ${$differ.to_str()} different, ${$diverge.to_str()} known libpg_query divergences")?
	if $differ > 0 Err(ScanMismatches($differ)) else Ok({})
}

compare : Golden -> [Same, Differs(Str), Diverges(Str)]
compare = |golden| {
	ours = Scan.tokens(golden.sql)
	expected = golden_lines(golden)
	got = our_lines(ours)
	if expected == got {
		Same
	} else {
		first = first_difference(expected, got)
		report = "${golden.file}:${golden.n.to_str()} ${excerpt(golden.sql)}\n    expected ${first.expected}\n    got      ${first.got}"
		if known_divergence(golden, ours) Diverges(report) else Differs(report)
	}
}

golden_lines : Golden -> List(Str)
golden_lines = |golden|
	match golden.error {
		Ok(err) => ["error ${err.message} @${err.cursor.to_str()}"]
		Err(Null) =>
			match golden.tokens {
				Ok(toks) => toks.map(|t| "${t.s.to_str()}-${t.e.to_str()} ${t.t} ${t.k}")
				Err(Null) => []
			}
	}

our_lines : Try(List(Scan.Token), Scan.Problem) -> List(Str)
our_lines = |result|
	match result {
		Err(p) => ["error ${p.message} @${p.cursor.to_str()}"]
		Ok(toks) => toks.map(|t| "${t.start.to_str()}-${t.end.to_str()} ${Scan.token_name(t.kind)} ${keyword_kind(t.kind)}")
	}

keyword_kind : Scan.Kind -> Str
keyword_kind = |kind|
	match kind {
		Keyword(k) =>
			match Keywords.get(k).category {
				Unreserved => "UNRESERVED_KEYWORD"
				ColName => "COL_NAME_KEYWORD"
				TypeFuncName => "TYPE_FUNC_NAME_KEYWORD"
				Reserved => "RESERVED_KEYWORD"
			}
		_ => "NO_KEYWORD"
	}

first_difference : List(Str), List(Str) -> { expected : Str, got : Str }
first_difference = |expected, got| {
	var $i = 0
	while $i < expected.len() and $i < got.len() and expected.get($i) == got.get($i) {
		$i = $i + 1
	}
	{
		expected: "#${$i.to_str()} ${expected.get($i) ?? "(end)"}",
		got: "#${$i.to_str()} ${got.get($i) ?? "(end)"}",
	}
}

## The two known differences between libpg_query and the server.
known_divergence : Golden, Try(List(Scan.Token), Scan.Problem) -> Bool
known_divergence = |golden, ours|
	match ours {
		Err(p) => p.message.starts_with("trailing junk after parameter") and no_error(golden)
		Ok(toks) => {
			comments =
				match golden.tokens {
					Ok(golden_toks) => golden_toks.keep_if(|t| t.t == "SQL_COMMENT")
					Err(Null) => []
				}
			toks.any(
				|t|
					is_string(t.kind) and comments.any(|c| c.s > t.start and c.e < t.end),
			)
		}
	}

is_string : Scan.Kind -> Bool
is_string = |kind|
	match kind {
		SConst(_) | UsConst(_) | BConst(_) | XConst(_) => Bool.True
		_ => Bool.False
	}

excerpt : Str -> Str
excerpt = |sql| {
	bytes = sql.to_utf8()
	one_line = Str.from_utf8_lossy(bytes.map(|b| if b == '\n' or b == '\r' or b == '\t' ' ' else b))
	if bytes.len() > 160 "${Str.from_utf8_lossy(one_line.to_utf8().take_first(160))}..." else one_line
}

no_error : Golden -> Bool
no_error = |golden|
	match golden.error {
		Ok(_) => Bool.False
		Err(Null) => Bool.True
	}
