## Write one canonical parse result per JSONL input {"sql": "..."}.
## Build this before and after a parser refactor and compare the outputs.
## Both accepted trees and rejected statements (including error locations)
## are covered without requiring a running database or libpg_query.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../package/internals.roc",
}

import pf.File
import pf.Path
import pf.Stdout
import pf.OsStr
import pg.Parse
import NodeJson

Input : { sql : Str }

main! : List(OsStr) => Try({}, _)
main! = |args| {
	path = args.last().map_ok(OsStr.display) ? |_| MissingCorpusPath
	reader = File.open_reader_with_capacity!(Path.utf8(path), 1048576)?
	var $line_number = 0.U64
	var $done = Bool.False
	while !$done {
		line = reader.read_line!()?
		if line.is_empty() {
			$done = Bool.True
		} else {
			$line_number = $line_number + 1
			input : Input
			input = Json.parse(Str.from_utf8_lossy(line).trim_end()) ? |_| InvalidCorpusLine($line_number)
			result = match Parse.parse(input.sql) {
				Ok(statements) => "ok ${NodeJson.stmts(statements)}"
				Err(problem) => "error ${Str.inspect(problem)}"
			}
			Stdout.line!(result)?
		}
	}
	Ok({})
}
