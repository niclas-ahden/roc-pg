## Runtime speed of the two lexers over the statements of a golden file.
##
##     roc build --opt=speed tests/lex_bench.roc
##     ./lex_bench scan local/golden/regress-tokens.jsonl
##     ./lex_bench lex local/golden/regress-tokens.jsonl
##     ./lex_bench none local/golden/regress-tokens.jsonl
##
## `none` only reads and decodes the file, so the difference to it is the
## lexing.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../package/internals.roc",
}

import pf.Stdout
import pf.File
import pf.Path
import pf.OsStr
import pg.Scan
import pg.Lex

main! : List(OsStr) => Try({}, _)
main! = |args| {
	n_args = args.len()
	mode = args.get(n_args - 2).map_ok(OsStr.display) ?? "scan"
	path = args.get(n_args - 1).map_ok(OsStr.display) ?? "local/golden/regress-tokens.jsonl"
	reader = File.open_reader_with_capacity!(Path.utf8(path), 1048576)?
	var $statements = 0.U64
	var $tokens = 0.U64
	var $done = Bool.False
	while !$done {
		line = reader.read_line!()?
		if line.is_empty() {
			$done = Bool.True
		} else {
			row : { sql : Str }
			row = Json.parse(Str.from_utf8_lossy(line)) ? |_| BadLine($statements)
			$statements = $statements + 1
			n =
				match mode {
					"scan" =>
						match Scan.tokens(row.sql) {
							Ok(toks) => toks.len()
							Err(_) => 0
						}
					"lex" =>
						match Lex.tokens(row.sql) {
							Ok(toks) => toks.len()
							Err(_) => 0
						}
					_ => 0
				}
			$tokens = $tokens + n
		}
	}
	Stdout.line!("${mode}: ${$statements.to_str()} statements, ${$tokens.to_str()} tokens")
}
