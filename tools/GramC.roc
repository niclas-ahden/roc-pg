## The grammar actions in the parser bison writes for `gram.y`: each rule's
## number, its `lhs: rhs` comment, and the C code of its action, with
## bison's `(yyvsp[k].member)`, `(yylsp[k])`, `(yyval.member)` and `(yyloc)`
## as they are.
GramC :: [].{
	## `line` is where the action starts in `gram.y`.
	Action : { rule : U64, rule_text : Str, code : Str, line : U64 }

	## The length of each rule, `yyr2`, indexed by rule number.
	rule_lengths : Str -> Try(List(U64), [GramC(Str)])
	rule_lengths = |gram_c| {
		after = gram_c.split_first(" yyr2[] =").map_ok(|s| s.after) ? |_| GramC("no yyr2 table in gram.c")
		body = (after.split_first("{").map_ok(|s| s.after) ?? "").split_first("}").map_ok(|s| s.before) ? |_| GramC("the yyr2 table in gram.c does not end")
		var $lengths = []
		for entry in body.split_on(",").map(|s| s.trim()).keep_if(|s| !s.is_empty()) {
			$lengths = $lengths.append(U64.from_str(entry) ? |_| GramC("yyr2 entry ${entry} is not a number"))
		}
		Ok($lengths)
	}

	actions : Str -> Try(List(GramC.Action), [GramC(Str)])
	actions = |gram_c| {
		after = gram_c.split_first("switch (yyn)\n    {\n").map_ok(|s| s.after) ? |_| GramC("no action switch in gram.c")
		body = after.split_first("\n      default: break;").map_ok(|s| s.before) ? |_| GramC("the action switch in gram.c does not end")
		var $out = []
		for part in "\n${body}".split_on("\n  case ").drop_first(1) {
			number_text = part.split_first(":").map_ok(|s| s.before) ?? ""
			rule = U64.from_str(number_text.trim()) ? |_| GramC("action case ${number_text} is not a rule number")
			rest = part.split_first(":").map_ok(|s| s.after) ?? ""
			rule_text = (rest.split_first("/*").map_ok(|s| s.after) ?? "").split_first("*/").map_ok(|s| s.before) ?? ""
			all_lines = rest.split_on("\n").drop_first(1)
			line_mark = (all_lines.find_first(|l| l.starts_with("#line ")) ? |_| GramC("rule ${rule.to_str()} has no #line")).drop_prefix("#line ")
			line = U64.from_str(line_mark.split_first(" ").map_ok(|s| s.before) ?? line_mark) ? |_| GramC("rule ${rule.to_str()}: #line ${line_mark}")
			lines = all_lines.keep_if(|l| !l.starts_with("#line") and l.trim() != "break;")
			$out = $out.append({ rule, rule_text: rule_text.trim(), code: Str.join_with(lines, "\n"), line })
		}
		Ok($out)
	}
}
