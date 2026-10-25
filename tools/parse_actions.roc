## Parse every grammar action in `local/gram/gram.c`, and the helper
## functions in the given C files, with [CParse], and report what it cannot
## read. `show N` prints the parse of rule N. A development check for the
## generator.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
}

import pf.Stdout
import pf.Path
import pf.OsStr
import GramC
import CParse

main! : List(OsStr) => Try({}, _)
main! = |args| {
	words = args.map(OsStr.display)
	gram_c = Path.read_utf8!(Path.utf8("local/gram/gram.c"))?
	actions = GramC.actions(gram_c)?
	if words.contains("show") {
		for action in actions {
			if words.contains(action.rule.to_str()) {
				parsed = CParse.statement(action.code)
				text = match parsed {
					Ok(s) => CParse.show(s)
					Err(m) => "error ${m}"
				}
				Stdout.line!("rule ${action.rule.to_str()} ${action.rule_text}\n  ${text}")?
			}
		}
		return Ok({})
	}
	var $failed = 0.U64
	for action in actions {
		match CParse.statement(action.code) {
			Ok(_) => {}
			Err(message) => {
				$failed = $failed + 1
				if $failed <= 25 {
					Stdout.line!("rule ${action.rule.to_str()} (${action.rule_text}): ${message}")?
				}
			}
		}
	}
	Stdout.line!("${actions.len().to_str()} actions, ${$failed.to_str()} not parsed")?
	for file in words.keep_if(|w| w.ends_with(".c") or w.ends_with(".y")) {
		source = Path.read_utf8!(Path.utf8(file))?
		r = CParse.functions(source)
		Stdout.line!("${file}: ${r.funcs.len().to_str()} functions, ${r.failed.len().to_str()} not read")?
		for f in r.failed {
			Stdout.line!("    ${f.name}: ${f.error}")?
		}
	}
	Ok({})
}
