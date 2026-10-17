# Derived from PostgreSQL 18.6, src/backend/parser/parser.c and the parser
# skeleton bison generates for src/backend/parser/gram.y.
#
# PostgreSQL Database Management System
# (also known as Postgres, formerly known as Postgres95)
#
# Portions Copyright (c) 1996-2026, PostgreSQL Global Development Group
#
# Portions Copyright (c) 1994, The Regents of the University of California
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without a written agreement
# is hereby granted, provided that the above copyright notice and this
# paragraph and the following two paragraphs appear in all copies.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
# DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

## Postgres 18's raw parser: the filter between lexer and grammar from
## `parser.c`, then the grammar's LALR(1) tables ([Grammar]) run the way
## bison's own parser runs them. So a statement is accepted or refused
## exactly as the server's grammar does, and a syntax error names the same
## token.
##
## The grammar's actions ([Actions]) build the parse tree, the same raw
## tree the server's parser makes, and raise the errors the grammar raises
## beyond syntax errors.
import Scan
import Keywords
import Grammar
import Actions
import Node
import Rt

Parse :: [].{
	## A token as the grammar sees it: its number, its value, where it
	## starts, and where the text a syntax error quotes ends.
	Token : { number : I64, kind : Scan.Kind, start : U64, end : U64 }

	## Check `sql`, one or more statements, against the grammar.
	check : Str -> Try({}, Scan.Problem)
	check = |sql| parse(sql).map_ok(|_| {})

	## Parse `sql`, one or more statements, into their raw parse trees: a
	## `RawStmt` node per statement, as `raw_parser` returns them.
	parse : Str -> Try(List(Node), Scan.Problem)
	parse = |sql| {
		scanned = Scan.scan(sql)
		toks = scanned.tokens.keep_if(|t| is_not_comment(t.kind))
		source = { bytes: scanned.bytes, toks, problem: scanned.problem }
		run(source)
	}
}

## The lexer's output with comments dropped, and the error it stopped at.
Source : { bytes : List(U8), toks : List(Scan.Token), problem : [Clean, Failed(Scan.Problem)] }

is_not_comment : Scan.Kind -> Bool
is_not_comment = |kind|
	match kind {
		SqlComment | CComment => Bool.False
		_ => Bool.True
	}

## The lexer's token at `j`: `Ok(Ok(token))`, `Ok(Err(End))` past the last
## one, or the lexer's error when it stopped there.
core_token : Source, U64 -> Try(Try(Scan.Token, [End]), Scan.Problem)
core_token = |source, j|
	match source.toks.get(j) {
		Ok(tok) => Ok(Ok(tok))
		Err(_) =>
			match source.problem {
				Clean => Ok(Err(End))
				Failed(p) => Err(p)
			}
	}

## The grammar's token number of a lexer token.
token_number : Scan.Kind -> I64
token_number = |kind|
	match kind {
		Ident(_) => Grammar.ident_token
		UIdent(_) => Grammar.uident_token
		Keyword(k) => Grammar.keyword_token(k)
		FConst(_) => Grammar.fconst_token
		IConst(_) => Grammar.iconst_token
		SConst(_) => Grammar.sconst_token
		UsConst(_) => Grammar.usconst_token
		BConst(_) => Grammar.bconst_token
		XConst(_) => Grammar.xconst_token
		Op(_) => Grammar.op_token
		Param(_) => Grammar.param_token
		Typecast => Grammar.typecast_token
		DotDot => Grammar.dot_dot_token
		ColonEquals => Grammar.colon_equals_token
		EqualsGreater => Grammar.equals_greater_token
		LessEquals => Grammar.less_equals_token
		GreaterEquals => Grammar.greater_equals_token
		NotEquals => Grammar.not_equals_token
		Char(c) => c.to_i64()
		SqlComment | CComment => 0
	}

## `base_yylex`: the grammar token at lexer token `j`, and the index of the
## lexer token after it. `Ok(Err(End))` is the end of input.
next_token : Source, U64 -> Try({ token : Try(Parse.Token, [End]), next : U64 }, Scan.Problem)
next_token = |source, j| {
	cur = core_token(source, j)?
	match cur {
		Err(End) => Ok({ token: Err(End), next: j })
		Ok(tok) => {
			number = token_number(tok.kind)
			plain = { number, kind: tok.kind, start: tok.start, end: tok.end }
			match tok.kind {
				Keyword(k) =>
					if needs_lookahead(k) {
						after = core_token(source, j + 1)?
						replaced =
							match after {
								Ok(next_tok) => lookahead_number(k, next_tok.kind, number)
								Err(End) => number
							}
						Ok({ token: Ok({ ..plain, number: replaced }), next: j + 1 })
					} else {
						Ok({ token: Ok(plain), next: j + 1 })
					}
				UIdent(value) => unicode_token(source, j, tok, value, Bool.True)
				UsConst(value) => unicode_token(source, j, tok, value, Bool.False)
				_ => Ok({ token: Ok(plain), next: j + 1 })
			}
		}
	}
}

needs_lookahead : U64 -> Bool
needs_lookahead = |k| k == kw_format or k == kw_not or k == kw_nulls or k == kw_with or k == kw_without

## FORMAT JSON, NOT BETWEEN/IN/LIKE/ILIKE/SIMILAR, NULLS FIRST/LAST,
## WITH TIME/ORDINALITY and WITHOUT TIME get tokens of their own.
lookahead_number : U64, Scan.Kind, I64 -> I64
lookahead_number = |k, next_kind, number| {
	next_kw =
		match next_kind {
			Keyword(n) => n
			_ => 999999
		}
	if k == kw_format and next_kw == kw_json {
		Grammar.format_la_token
	} else if k == kw_not and (next_kw == kw_between or next_kw == kw_in or next_kw == kw_like or next_kw == kw_ilike or next_kw == kw_similar) {
		Grammar.not_la_token
	} else if k == kw_nulls and (next_kw == kw_first or next_kw == kw_last) {
		Grammar.nulls_la_token
	} else if k == kw_with and (next_kw == kw_time or next_kw == kw_ordinality) {
		Grammar.with_la_token
	} else if k == kw_without and next_kw == kw_time {
		Grammar.without_la_token
	} else {
		number
	}
}

## `U&"..."` or `U&'...'`, maybe followed by `UESCAPE 'c'`: the escapes
## applied, as an IDENT or an SCONST.
unicode_token : Source, U64, Scan.Token, Str, Bool -> Try({ token : Try(Parse.Token, [End]), next : U64 }, Scan.Problem)
unicode_token = |source, j, tok, value, is_ident| {
	after = core_token(source, j + 1)?
	has_uescape =
		match after {
			Ok(next_tok) =>
				match next_tok.kind {
					Keyword(k) => k == kw_uescape
					_ => Bool.False
				}
			Err(End) => Bool.False
		}
	if has_uescape {
		third = core_token(source, j + 2)?
		len = source.bytes.len()
		{ esc, third_end } =
			match third {
				Ok(t) =>
					match t.kind {
						SConst(s) => {
							chars = s.to_utf8()
							if chars.len() == 1 and uescape_char_ok(chars.get(0) ?? 0) {
								{ esc: chars.get(0) ?? 0, third_end: t.end }
							} else {
								return Err(Scan.error_at(source.bytes, "invalid Unicode escape character", t.start, t.end))
							}
						}
						_ => return Err(Scan.error_at(source.bytes, "UESCAPE must be followed by a simple string literal", t.start, t.end))
					}
				Err(End) => return Err(Scan.error_at(source.bytes, "UESCAPE must be followed by a simple string literal", len, len))
			}
		unescaped = udeescape(source.bytes, value.to_utf8(), esc, tok.start)?
		Ok({ token: Ok(unicode_result(unescaped, is_ident, tok.start, third_end)), next: j + 3 })
	} else {
		unescaped = udeescape(source.bytes, value.to_utf8(), '\\', tok.start)?
		Ok({ token: Ok(unicode_result(unescaped, is_ident, tok.start, tok.end)), next: j + 1 })
	}
}

unicode_result : List(U8), Bool, U64, U64 -> Parse.Token
unicode_result = |bytes, is_ident, start, end|
	if is_ident {
		{ number: Grammar.ident_token, kind: Ident(Scan.truncate_identifier(bytes)), start, end }
	} else {
		{ number: Grammar.sconst_token, kind: SConst(Str.from_utf8_lossy(bytes)), start, end }
	}

## `check_uescapechar`: anything but a hex digit, `+`, a quote or a space.
uescape_char_ok : U8 -> Bool
uescape_char_ok = |c|
	!(is_hex(c) or c == '+' or c == '\'' or c == '"' or c == ' ' or c == '\t' or c == '\n' or c == '\r' or c == 11 or c == 12)

## `str_udeescape`: apply `\XXXX` and `\+XXXXXX` escapes (with `esc` in
## place of the backslash). Errors point at the escape, counted from the
## token at `position` as if the value were the text after `U&"`.
udeescape : List(U8), List(U8), U8, U64 -> Try(List(U8), Scan.Problem)
udeescape = |source, value, esc, position| {
	len = value.len()
	var $out = []
	var $i = 0
	var $pair_first = 0
	while $i < len {
		c = value.get($i) ?? 0
		if c == esc {
			next = value.get($i + 1) ?? 0
			if next == esc {
				if $pair_first != 0 {
					return Err(invalid_pair(source, $i, position))
				}
				$out = $out.append(esc)
				$i = $i + 2
			} else {
				digits = if all_hex(value, $i + 1, 4) 4 else if next == '+' and all_hex(value, $i + 2, 6) 6 else 0
				if digits == 0 {
					return Err({ message: "invalid Unicode escape", code: "42601", cursor: Scan.cursor_at(source, $i + position + 3) })
				}
				from = if digits == 4 $i + 1 else $i + 2
				u = hex_value(value, from, digits)
				if u == 0 or u > 0x10FFFF {
					return Err({ message: "invalid Unicode escape value", code: "42601", cursor: Scan.cursor_at(source, $i + position + 3) })
				}
				second = u >= 0xDC00 and u <= 0xDFFF
				var $cp = u
				if $pair_first != 0 {
					if second {
						$cp = ($pair_first - 0xD800) * 1024 + 0x10000 + (u - 0xDC00)
						$pair_first = 0
					} else {
						return Err(invalid_pair(source, $i, position))
					}
				} else if second {
					return Err(invalid_pair(source, $i, position))
				}
				if $cp >= 0xD800 and $cp <= 0xDBFF {
					$pair_first = $cp
				} else {
					$out = $out.concat(Scan.utf8_of($cp))
				}
				$i = from + digits
			}
		} else {
			if $pair_first != 0 {
				return Err(invalid_pair(source, $i, position))
			}
			$out = $out.append(c)
			$i = $i + 1
		}
	}
	if $pair_first != 0 {
		return Err(invalid_pair(source, $i, position))
	}
	Ok($out)
}

all_hex : List(U8), U64, U64 -> Bool
all_hex = |bytes, p, n| {
	var $k = 0
	var $ok = Bool.True
	while $ok and $k < n {
		$ok = is_hex(bytes.get(p + $k) ?? 0)
		$k = $k + 1
	}
	$ok
}

hex_value : List(U8), U64, U64 -> U64
hex_value = |bytes, p, n| bytes.sublist({ start: p, len: n }).fold(0, |v, c| v * 16 + hex_digit(c))

hex_digit : U8 -> U64
hex_digit = |c|
	if c >= '0' and c <= '9' {
		(c - '0').to_u64()
	} else if c >= 'a' and c <= 'f' {
		(c - 'a').to_u64() + 10
	} else {
		(c - 'A').to_u64() + 10
	}

is_hex : U8 -> Bool
is_hex = |c| (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F')

## Bison's `yyparse` over the tables, stopping at the first error as the
## server does. Next to the states it keeps each symbol's value and
## location, and runs a rule's action when it reduces by the rule.
run : Source -> Try(List(Node), Scan.Problem)
run = |source| {
	var $states = [0.I64]
	var $values = [Rt.of_node(Node.Null)]
	var $locations = [-1.I64]
	var $look = NoToken
	var $j = 0
	var $last_start = 0
	var $last_end = 0
	while Bool.True {
		state = $states.last() ?? 0
		if state == Grammar.final_state {
			return Ok(Rt.list_at($values, 1))
		}
		pact = Grammar.pact(state)
		var $rule = 0.I64
		if pact == Grammar.pact_ninf {
			$rule = Grammar.defact(state)
			if $rule == 0 {
				return Err(syntax_error(source, $look))
			}
		} else {
			if is_empty($look) {
				fetched = next_token(source, $j)?
				$look = Have(fetched.token)
				$j = fetched.next
				{ start, end } =
					match fetched.token {
						Ok(tok) => { start: tok.start, end: tok.end }
						Err(End) => { start: source.bytes.len(), end: source.bytes.len() }
					}
				$last_start = start
				$last_end = end
			}
			symbol = symbol_of($look)
			idx = pact + symbol
			if idx < 0 or idx > Grammar.last or Grammar.check(idx) != symbol {
				$rule = Grammar.defact(state)
				if $rule == 0 {
					return Err(syntax_error(source, $look))
				}
			} else {
				action = Grammar.table(idx)
				if action <= 0 {
					if action == Grammar.table_ninf {
						return Err(syntax_error(source, $look))
					}
					$rule = 0 - action
				} else {
					$states = $states.append(action)
					$values = $values.append(token_value($look))
					$locations = $locations.append(token_location($look))
					$look = NoToken
				}
			}
		}
		if $rule != 0 {
			keep = $states.len() - Grammar.r2($rule).to_u64_wrap()
			rhs_locations = $locations.drop_first(keep)
			# `YYLLOC_DEFAULT`: the first location on the right-hand side
			# that is set.
			location = rhs_locations.find_first(|l| l >= 0) ?? -1
			ctx = { bytes: source.bytes, last_start: $last_start, last_end: $last_end }
			value = Actions.run($rule.to_u64_wrap(), ctx, $values.drop_first(keep), rhs_locations, location)?
			$states = $states.take_first(keep)
			$values = $values.take_first(keep).append(value)
			$locations = $locations.take_first(keep).append(location)
			top = $states.last() ?? 0
			lhs = Grammar.r1($rule) - Grammar.ntokens
			i = Grammar.pgoto(lhs) + top
			goto = if i >= 0 and i <= Grammar.last and Grammar.check(i) == top Grammar.table(i) else Grammar.defgoto(lhs)
			$states = $states.append(goto)
		}
	}
}

## The value a token carries into the grammar: its text for names,
## keywords, operators and literals other than integers, its number for
## integers and parameters. A bit string keeps the `b` or `x` in front
## that the grammar expects.
token_value : Look -> Rt.Value
token_value = |look|
	match look {
		Have(Ok(tok)) =>
			match tok.kind {
				Ident(s) | FConst(s) | SConst(s) | UsConst(s) | UIdent(s) | Op(s) | BConst(s) | XConst(s) => Rt.of_text(Ok(s))
				Keyword(k) => Rt.of_text(Ok(Keywords.get(k).name))
				IConst(n) | Param(n) => Rt.of_int(n.to_i64())
				_ => Rt.of_node(Node.Null)
			}
		_ => Rt.of_node(Node.Null)
	}

## Where a token starts, as a byte offset.
token_location : Look -> I64
token_location = |look|
	match look {
		Have(Ok(tok)) => tok.start.to_i64_wrap()
		_ => -1
	}

## The lookahead: none read yet, or a token or the end of input.
Look : [NoToken, Have(Try(Parse.Token, [End]))]

## `YYTRANSLATE`: the grammar symbol of the lookahead.
symbol_of : Look -> I64
symbol_of = |look|
	match look {
		Have(Ok(tok)) =>
			if tok.number <= 0 {
				0
			} else if tok.number > Grammar.max_token {
				2
			} else {
				Grammar.translate(tok.number)
			}
		_ => 0
	}

## "syntax error at or near" the lookahead, or "at end of input".
syntax_error : Source, Look -> Scan.Problem
syntax_error = |source, look| {
	len = source.bytes.len()
	match look {
		Have(Ok(tok)) => Scan.error_at(source.bytes, "syntax error", tok.start, tok.end)
		_ => Scan.error_at(source.bytes, "syntax error", len, len)
	}
}

kw : Str -> U64
kw = |word| Keywords.lookup(word) ?? 0

kw_format : U64
kw_format = kw("format")

kw_json : U64
kw_json = kw("json")

kw_not : U64
kw_not = kw("not")

kw_between : U64
kw_between = kw("between")

kw_in : U64
kw_in = kw("in")

kw_like : U64
kw_like = kw("like")

kw_ilike : U64
kw_ilike = kw("ilike")

kw_similar : U64
kw_similar = kw("similar")

kw_nulls : U64
kw_nulls = kw("nulls")

kw_first : U64
kw_first = kw("first")

kw_last : U64
kw_last = kw("last")

kw_with : U64
kw_with = kw("with")

kw_time : U64
kw_time = kw("time")

kw_ordinality : U64
kw_ordinality = kw("ordinality")

kw_without : U64
kw_without = kw("without")

kw_uescape : U64
kw_uescape = kw("uescape")

expect Parse.check("select 1") == Ok({})
expect Parse.check("select a from t where b not in (1, 2) order by c nulls first") == Ok({})
expect Parse.check("select 1 2").map_err(|p| p.message) == Err("syntax error at or near \"2\"")
expect Parse.check("select from where").map_err(|p| p.message) == Err("syntax error at or near \"where\"")
expect Parse.check("select 1 2 'oops").map_err(|p| p.message) == Err("syntax error at or near \"2\"")
expect Parse.check("select (").map_err(|p| p.message) == Err("syntax error at end of input")
expect Parse.check("select U&'d\\0061t' UESCAPE '\\'") == Ok({})

## "invalid Unicode surrogate pair" at offset `i` of a `U&` value.
invalid_pair : List(U8), U64, U64 -> Scan.Problem
invalid_pair = |source, i, position| { message: "invalid Unicode surrogate pair", code: "42601", cursor: Scan.cursor_at(source, i + position + 3) }

is_empty : Look -> Bool
is_empty = |look|
	match look {
		NoToken => Bool.True
		Have(_) => Bool.False
	}
