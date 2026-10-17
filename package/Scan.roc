# Derived from PostgreSQL 18.6, src/backend/parser/scan.l.
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

## Postgres 18's lexer, `src/backend/parser/scan.l`, rule for rule, as a
## default server runs it: `standard_conforming_strings` on and UTF-8.
##
## Where two rules could match, the longest match wins, and between matches
## of the same length the rule listed first in `scan.l` wins, as in flex.
## Errors carry the server's message, SQLSTATE and cursor position.
##
## Comments come back as tokens too, so a caller can find them. The grammar
## skips them. They still count as whitespace between the parts of a
## continued string constant, as on the server.
import Keywords

Scan :: [].{
	Kind : [
		## An identifier, folded to lower case and cut to 63 bytes.
		Ident(Str),
		## `U&"..."`, before its escapes are applied.
		UIdent(Str),
		## An index into [Keywords.all].
		Keyword(U64),
		## A number that is not an `I32`, as written: a decimal, an exponent,
		## or an integer too large for `I32`.
		FConst(Str),
		IConst(I32),
		## A string constant's value, with its escapes applied.
		SConst(Str),
		## `U&'...'`, before its escapes are applied.
		UsConst(Str),
		## `B'...'`, as `b` and the digits.
		BConst(Str),
		## `X'...'`, as `x` and the digits.
		XConst(Str),
		Op(Str),
		Param(I32),
		Typecast,
		DotDot,
		ColonEquals,
		EqualsGreater,
		LessEquals,
		GreaterEquals,
		NotEquals,
		## A character that is a token of its own, such as `(` or `;`.
		Char(U8),
		SqlComment,
		CComment,
	]

	Token : { kind : Scan.Kind, start : U64, end : U64 }

	## An error as the server reports it: the message, the SQLSTATE, and the
	## cursor as a 1-based character position, 0 when there is none.
	Problem : { message : Str, code : Str, cursor : U64 }

	## Split `sql` into tokens. Offsets are bytes. Like the server, which
	## reads the query as a C string, the text ends at the first NUL byte.
	tokens : Str -> Try(List(Scan.Token), Scan.Problem)
	tokens = |sql| {
		result = Scan.scan(sql)
		match result.problem {
			Clean => Ok(result.tokens)
			Failed(problem) => Err(problem)
		}
	}

	## The tokens up to the first error, the error if there is one, and the
	## text as the lexer saw it. The server lexes as the grammar asks for
	## tokens, so an error in the lexer only counts once the grammar gets
	## that far, and a syntax error before it wins.
	scan : Str -> { tokens : List(Scan.Token), problem : [Clean, Failed(Scan.Problem)], bytes : List(U8) }
	scan = |sql| {
		all = sql.to_utf8()
		bytes =
			match all.find_first_index(|b| b == 0) {
				Ok(n) => all.take_first(n)
				Err(_) => all
			}
		len = bytes.len()
		var $i = 0
		var $out = []
		var $problem = Clean
		while $i < len {
			b = at(bytes, $i)
			next = at(bytes, $i + 1)
			if is_space(b) {
				$i = $i + 1
			} else if b == '-' and next == '-' {
				end = line_end(bytes, $i)
				$out = $out.append({ kind: SqlComment, start: $i, end })
				$i = end
			} else if b == '/' and next == '*' {
				match comment_end(bytes, $i) {
					Ok(end) => {
						$out = $out.append({ kind: CComment, start: $i, end })
						$i = end
					}
					Err(p) => {
						$problem = Failed(p)
						$i = len
					}
				}
			} else {
				match token_at(bytes, $i) {
					Ok(tok) => {
						$out = $out.append(tok)
						$i = tok.end
					}
					Err(p) => {
						$problem = Failed(p)
						$i = len
					}
				}
			}
		}
		{ tokens: $out, problem: $problem, bytes }
	}

	## `yyerror` for callers: the message, then the text from `loc` to `end`,
	## or "at end of input" when `loc` is the end of `bytes`.
	error_at : List(U8), Str, U64, U64 -> Scan.Problem
	error_at = |bytes, message, loc, end| yyerror(bytes, message, loc, end)

	## A byte offset as the server's cursor: the 1-based character position.
	cursor_at : List(U8), U64 -> U64
	cursor_at = |bytes, loc| cursor(bytes, loc)

	## An identifier cut to 63 bytes without splitting a character.
	truncate_identifier : List(U8) -> Str
	truncate_identifier = |ident| truncate(ident)

	## A code point as UTF-8.
	utf8_of : U64 -> List(U8)
	utf8_of = |cp| utf8(cp)

	## The grammar's name for a token, as libpg_query's scanner reports it:
	## `IDENT`, `SCONST`, a keyword's token such as `SELECT` or `NULL_P`,
	## `ASCII_40` for `(`, and so on.
	token_name : Scan.Kind -> Str
	token_name = |kind|
		match kind {
			Ident(_) => "IDENT"
			UIdent(_) => "UIDENT"
			Keyword(k) => Keywords.get(k).token
			FConst(_) => "FCONST"
			IConst(_) => "ICONST"
			SConst(_) => "SCONST"
			UsConst(_) => "USCONST"
			BConst(_) => "BCONST"
			XConst(_) => "XCONST"
			Op(_) => "Op"
			Param(_) => "PARAM"
			Typecast => "TYPECAST"
			DotDot => "DOT_DOT"
			ColonEquals => "COLON_EQUALS"
			EqualsGreater => "EQUALS_GREATER"
			LessEquals => "LESS_EQUALS"
			GreaterEquals => "GREATER_EQUALS"
			NotEquals => "NOT_EQUALS"
			Char(c) => "ASCII_${c.to_str()}"
			SqlComment => "SQL_COMMENT"
			CComment => "C_COMMENT"
		}
}

## One token that is not whitespace or a comment, starting at `i`.
token_at : List(U8), U64 -> Try(Scan.Token, Scan.Problem)
token_at = |bytes, i| {
	b = at(bytes, i)
	n1 = at(bytes, i + 1)
	n2 = at(bytes, i + 2)
	if (b == 'b' or b == 'B') and n1 == '\'' {
		string(bytes, i, 2, Bit)
	} else if (b == 'x' or b == 'X') and n1 == '\'' {
		string(bytes, i, 2, Hex)
	} else if (b == 'n' or b == 'N') and n1 == '\'' {
		# National character: the keyword NCHAR, then the string on its own.
		Ok({ kind: Keyword(nchar), start: i, end: i + 1 })
	} else if (b == 'e' or b == 'E') and n1 == '\'' {
		string(bytes, i, 2, Escape)
	} else if (b == 'u' or b == 'U') and n1 == '&' {
		if n2 == '\'' {
			string(bytes, i, 3, Unicode)
		} else if n2 == '"' {
			quoted_ident(bytes, i, 3, Bool.True)
		} else {
			# `u&` that starts nothing: the `u` alone is an identifier.
			Ok({ kind: Ident("u"), start: i, end: i + 1 })
		}
	} else if b == '\'' {
		string(bytes, i, 1, Standard)
	} else if b == '"' {
		quoted_ident(bytes, i, 1, Bool.False)
	} else if b == '$' {
		dollar(bytes, i)
	} else if is_ident_start(b) {
		Ok(identifier(bytes, i))
	} else if is_digit(b) or (b == '.' and is_digit(n1)) {
		number(bytes, i)
	} else if b == ':' {
		if n1 == ':' {
			Ok({ kind: Typecast, start: i, end: i + 2 })
		} else if n1 == '=' {
			Ok({ kind: ColonEquals, start: i, end: i + 2 })
		} else {
			Ok({ kind: Char(b), start: i, end: i + 1 })
		}
	} else if b == '.' {
		if n1 == '.' {
			Ok({ kind: DotDot, start: i, end: i + 2 })
		} else {
			Ok({ kind: Char(b), start: i, end: i + 1 })
		}
	} else if is_op_char(b) {
		operator(bytes, i)
	} else {
		# The rest of `self`, and `other`: any character on its own.
		Ok({ kind: Char(b), start: i, end: i + 1 })
	}
}

## An identifier or a keyword.
identifier : List(U8), U64 -> Scan.Token
identifier = |bytes, i| {
	end = ident_cont_end(bytes, i + 1)
	kind =
		match Keywords.lookup(text(bytes, i, end)) {
			Ok(k) => Keyword(k)
			Err(_) => Ident(truncate(bytes.sublist({ start: i, len: end - i }).map(ascii_lower)))
		}
	{ kind, start: i, end }
}

## The kinds of string constant, by their opening.
StrMode : [Standard, Escape, Unicode, Bit, Hex]

## A string constant starting at `start`, after an opening of `prefix`
## bytes: `'`, `E'`, `U&'`, `B'` or `X'`.
string : List(U8), U64, U64, StrMode -> Try(Scan.Token, Scan.Problem)
string = |bytes, start, prefix, mode| {
	len = bytes.len()
	doubles = match mode {
		Bit | Hex => Bool.False
		_ => Bool.True
	}
	escapes = match mode {
		Escape => Bool.True
		_ => Bool.False
	}
	var $lit =
		match mode {
			Bit => ['b']
			Hex => ['x']
			_ => []
		}
	var $p = start + prefix
	var $non_ascii = Bool.False
	var $closed = Bool.False
	while !$closed {
		if $p >= len {
			return Err(yyerror(bytes, unterminated(mode), start, len))
		}
		c = at(bytes, $p)
		if c == '\'' {
			if doubles and at(bytes, $p + 1) == '\'' {
				$lit = $lit.append('\'')
				$p = $p + 2
			} else {
				match continuation(bytes, $p + 1) {
					Ok(after) => {
						$p = after
					}
					Err(_) => {
						$closed = Bool.True
					}
				}
			}
		} else if escapes and c == '\\' {
			step = escape(bytes, $p)?
			$lit = $lit.concat(step.add)
			$non_ascii = $non_ascii or step.non_ascii
			$p = step.next
		} else {
			$lit = $lit.append(c)
			$p = $p + 1
		}
	}
	end = $p + 1
	if $non_ascii {
		verify_utf8($lit)?
	}
	value = Str.from_utf8_lossy($lit)
	kind =
		match mode {
			Standard | Escape => SConst(value)
			Unicode => UsConst(value)
			Bit => BConst(value)
			Hex => XConst(value)
		}
	Ok({ kind, start, end })
}

unterminated : StrMode -> Str
unterminated = |mode|
	match mode {
		Bit => "unterminated bit string literal"
		Hex => "unterminated hexadecimal string literal"
		_ => "unterminated quoted string"
	}

## After a closing quote at `p - 1`: whitespace with a newline in it, then
## another quote, continues the same constant. `Ok` is the position after
## that quote. Comments count as whitespace: `--` ones before the first
## newline, and ones followed by a newline after it.
continuation : List(U8), U64 -> Try(U64, [NoContinuation])
continuation = |bytes, p| {
	len = bytes.len()
	var $j = p
	var $seen_newline = Bool.False
	while Bool.True {
		if $j >= len {
			return Err(NoContinuation)
		}
		c = at(bytes, $j)
		if !$seen_newline {
			if c == ' ' or c == '\t' or c == 12 or c == 11 {
				$j = $j + 1
			} else if c == '-' and at(bytes, $j + 1) == '-' {
				$j = line_end(bytes, $j)
			} else if c == '\n' or c == '\r' {
				$j = $j + 1
				$seen_newline = Bool.True
			} else {
				return Err(NoContinuation)
			}
		} else if is_space(c) {
			$j = $j + 1
		} else if c == '-' and at(bytes, $j + 1) == '-' {
			$j = line_end(bytes, $j)
			if $j >= len {
				return Err(NoContinuation)
			}
			$j = $j + 1
		} else if c == '\'' {
			return Ok($j + 1)
		} else {
			return Err(NoContinuation)
		}
	}
}

## One backslash escape of an `E'...'` string, at `p`: the bytes it adds,
## whether they need the final UTF-8 check, and where scanning goes on.
escape : List(U8), U64 -> Try({ add : List(U8), non_ascii : Bool, next : U64 }, Scan.Problem)
escape = |bytes, p| {
	len = bytes.len()
	e = at(bytes, p + 1)
	if p + 1 >= len {
		# A backslash right before the end is kept, and the string is then
		# unterminated.
		Ok({ add: ['\\'], non_ascii: Bool.False, next: p + 1 })
	} else if e >= '0' and e <= '7' {
		n = run_len(bytes, p + 1, 3, is_oct)
		v = (digits_value(bytes, p + 1, n, 8) % 256).to_u8_wrap()
		Ok({ add: [v], non_ascii: v == 0 or v >= 128, next: p + 1 + n })
	} else if e == 'x' and is_hex(at(bytes, p + 2)) {
		n = run_len(bytes, p + 2, 2, is_hex)
		v = digits_value(bytes, p + 2, n, 16).to_u8_wrap()
		Ok({ add: [v], non_ascii: v == 0 or v >= 128, next: p + 2 + n })
	} else if e == 'u' or e == 'U' {
		first = unicode_escape(bytes, p)?
		if first.cp >= 0xD800 and first.cp <= 0xDBFF {
			q = first.next
			if q >= len {
				return Err(yyerror(bytes, "invalid Unicode surrogate pair", q, q))
			}
			if at(bytes, q) == '\\' and (at(bytes, q + 1) == 'u' or at(bytes, q + 1) == 'U') {
				second = unicode_escape(bytes, q)?
				if second.cp < 0xDC00 or second.cp > 0xDFFF {
					return Err(yyerror(bytes, "invalid Unicode surrogate pair", q, second.next))
				}
				cp = (first.cp - 0xD800) * 1024 + 0x10000 + (second.cp - 0xDC00)
				Ok({ add: utf8(cp), non_ascii: Bool.False, next: second.next })
			} else {
				Err(yyerror(bytes, "invalid Unicode surrogate pair", q, q + 1))
			}
		} else if first.cp >= 0xDC00 and first.cp <= 0xDFFF {
			Err(yyerror(bytes, "invalid Unicode surrogate pair", p, first.next))
		} else if first.cp == 0 or first.cp > 0x10FFFF {
			Err(yyerror(bytes, "invalid Unicode escape value", p, first.next))
		} else {
			Ok({ add: utf8(first.cp), non_ascii: Bool.False, next: first.next })
		}
	} else {
		v =
			match e {
				'b' => 8
				'f' => 12
				'n' => '\n'
				'r' => '\r'
				't' => '\t'
				'v' => 11
				_ => e
			}
		Ok({ add: [v], non_ascii: v == e and (e == 0 or e >= 128), next: p + 2 })
	}
}

## `\uXXXX` or `\UXXXXXXXX` at `p`. Fewer hex digits is an error.
unicode_escape : List(U8), U64 -> Try({ cp : U64, next : U64 }, Scan.Problem)
unicode_escape = |bytes, p| {
	need = if at(bytes, p + 1) == 'u' 4 else 8
	n = run_len(bytes, p + 2, need, is_hex)
	if n < need {
		Err({ message: "invalid Unicode escape", code: "22025", cursor: cursor(bytes, p) })
	} else {
		Ok({ cp: digits_value(bytes, p + 2, n, 16), next: p + 2 + n })
	}
}

## The server's check of a string made with escapes: valid UTF-8 without a
## NUL byte. The message shows the bytes of the first bad character.
verify_utf8 : List(U8) -> Try({}, Scan.Problem)
verify_utf8 = |lit| {
	nul = lit.find_first_index(|b| b == 0) ?? lit.len()
	bad =
		match Str.from_utf8(lit) {
			Ok(_) => lit.len()
			Err(BadUtf8(info)) => info.index
		}
	at_byte = if nul < bad nul else bad
	if at_byte >= lit.len() {
		Ok({})
	} else {
		lead = at(lit, at_byte)
		char_len = if lead < 0x80 1 else if lead >= 0xC0 and lead < 0xE0 2 else if lead >= 0xE0 and lead < 0xF0 3 else if lead >= 0xF0 and lead < 0xF8 4 else 1
		shown = lit.sublist({ start: at_byte, len: char_len })
		parts : List(Str)
		parts = shown.map(|b| "0x${hex2(b)}")
		hex = Str.join_with(parts, " ")
		Err({ message: "invalid byte sequence for encoding \"UTF8\": ${hex}", code: "22021", cursor: 0 })
	}
}

## A quoted identifier, `"..."` or `U&"..."`, starting at `start`.
quoted_ident : List(U8), U64, U64, Bool -> Try(Scan.Token, Scan.Problem)
quoted_ident = |bytes, start, prefix, unicode| {
	len = bytes.len()
	var $lit = []
	var $p = start + prefix
	var $closed = Bool.False
	while !$closed {
		if $p >= len {
			return Err(yyerror(bytes, "unterminated quoted identifier", start, len))
		}
		c = at(bytes, $p)
		if c == '"' {
			if at(bytes, $p + 1) == '"' {
				$lit = $lit.append('"')
				$p = $p + 2
			} else {
				$closed = Bool.True
			}
		} else {
			$lit = $lit.append(c)
			$p = $p + 1
		}
	}
	end = $p + 1
	if $lit.is_empty() {
		return Err(yyerror(bytes, "zero-length delimited identifier", start, end))
	}
	kind = if unicode UIdent(Str.from_utf8_lossy($lit)) else Ident(truncate($lit))
	Ok({ kind, start, end })
}

## `$`: a parameter, a dollar quote, or the character alone.
dollar : List(U8), U64 -> Try(Scan.Token, Scan.Problem)
dollar = |bytes, i| {
	if is_digit(at(bytes, i + 1)) {
		param(bytes, i)
	} else {
		d = delimiter_len(bytes, i)
		if d > 0 {
			dollar_quote(bytes, i, d)
		} else {
			Ok({ kind: Char('$'), start: i, end: i + 1 })
		}
	}
}

## `$1`. Letters right after the digits are an error.
param : List(U8), U64 -> Try(Scan.Token, Scan.Problem)
param = |bytes, i| {
	n = run_len(bytes, i + 1, bytes.len(), is_digit)
	end = i + 1 + n
	if is_ident_start(at(bytes, end)) {
		return Err(yyerror(bytes, "trailing junk after parameter", i, ident_cont_end(bytes, end)))
	}
	match int_value(bytes, i + 1, end) {
		Ok(v) => Ok({ kind: Param(v), start: i, end })
		Err(_) => Err(yyerror(bytes, "parameter number too large", i, end))
	}
}

## The length of a `$$` or `$tag$` delimiter at `p`, or 0.
delimiter_len : List(U8), U64 -> U64
delimiter_len = |bytes, p| {
	if at(bytes, p + 1) == '$' {
		2
	} else if is_ident_start(at(bytes, p + 1)) {
		tag_end = run_end(bytes, p + 2, is_dolq_cont)
		if at(bytes, tag_end) == '$' tag_end + 1 - p else 0
	} else {
		0
	}
}

## A dollar-quoted string whose opening delimiter of `d` bytes is at `start`.
## A different delimiter inside is text, all but its last `$`, which may
## start the closing one.
dollar_quote : List(U8), U64, U64 -> Try(Scan.Token, Scan.Problem)
dollar_quote = |bytes, start, d| {
	len = bytes.len()
	delim = bytes.sublist({ start, len: d })
	var $lit = []
	var $p = start + d
	var $end = 0
	while $end == 0 {
		if $p >= len {
			return Err(yyerror(bytes, "unterminated dollar-quoted string", start, len))
		}
		c = at(bytes, $p)
		if c == '$' {
			m = delimiter_len(bytes, $p)
			if m > 0 and bytes.sublist({ start: $p, len: m }) == delim {
				$end = $p + m
			} else if m > 0 {
				$lit = $lit.concat(bytes.sublist({ start: $p, len: m - 1 }))
				$p = $p + m - 1
			} else if is_ident_start(at(bytes, $p + 1)) {
				tag_end = run_end(bytes, $p + 2, is_dolq_cont)
				$lit = $lit.concat(bytes.sublist({ start: $p, len: tag_end - $p }))
				$p = tag_end
			} else {
				$lit = $lit.append('$')
				$p = $p + 1
			}
		} else {
			$lit = $lit.append(c)
			$p = $p + 1
		}
	}
	Ok({ kind: SConst(Str.from_utf8_lossy($lit)), start, end: $end })
}

## What a number rule does with its match.
NumAction : [Integer, Float, IntegerBefore(U64), Junk(Str)]

## A number starting at `i`: the longest match of the numeric rules, the
## earlier rule on a tie.
number : List(U8), U64 -> Try(Scan.Token, Scan.Problem)
number = |bytes, i| {
	b = at(bytes, i)
	n1 = at(bytes, i + 1)
	d = dec_len(bytes, i)
	var $cands = []
	if d > 0 {
		$cands = $cands.append({ len: d, rule: 26, action: Integer })
	}
	if b == '0' {
		if n1 == 'x' or n1 == 'X' {
			h = based_len(bytes, i + 2, is_hex)
			if h > 0 {
				$cands = $cands.append({ len: 2 + h, rule: 27, action: Integer })
			}
			$cands = $cands.append({ len: if at(bytes, i + 2) == '_' 3 else 2, rule: 30, action: Junk("invalid hexadecimal integer") })
		} else if n1 == 'o' or n1 == 'O' {
			o = based_len(bytes, i + 2, is_oct)
			if o > 0 {
				$cands = $cands.append({ len: 2 + o, rule: 28, action: Integer })
			}
			$cands = $cands.append({ len: if at(bytes, i + 2) == '_' 3 else 2, rule: 31, action: Junk("invalid octal integer") })
		} else if n1 == 'b' or n1 == 'B' {
			n = based_len(bytes, i + 2, is_bin)
			if n > 0 {
				$cands = $cands.append({ len: 2 + n, rule: 29, action: Integer })
			}
			$cands = $cands.append({ len: if at(bytes, i + 2) == '_' 3 else 2, rule: 32, action: Junk("invalid binary integer") })
		}
	}
	# {numeric}: digits and a point, maybe more digits, or a point and digits.
	# `frac` is where the digits after the point start.
	frac = if d > 0 i + d + 1 else i + 1
	has_point = (d > 0 and at(bytes, i + d) == '.') or d == 0
	f = if has_point dec_len(bytes, frac) else 0
	numeric = if d > 0 and has_point frac + f - i else if d == 0 1 + f else 0
	if numeric > 0 {
		$cands = $cands.append({ len: numeric, rule: 33, action: Float })
	}
	if d > 0 and at(bytes, i + d) == '.' and at(bytes, i + d + 1) == '.' {
		$cands = $cands.append({ len: d + 2, rule: 34, action: IntegerBefore(d) })
	}
	# {real} and {realfail}: an exponent after an integer or a numeric.
	base = if numeric > 0 numeric else d
	e_at = i + base
	e = at(bytes, e_at)
	var $exp_start = 0
	var $exp_len = 0
	if base > 0 and (e == 'e' or e == 'E') {
		sign = if at(bytes, e_at + 1) == '+' or at(bytes, e_at + 1) == '-' 1 else 0
		x = dec_len(bytes, e_at + 1 + sign)
		if x > 0 {
			$cands = $cands.append({ len: base + 1 + sign + x, rule: 35, action: Float })
			$exp_start = e_at + 1 + sign
			$exp_len = x
		}
		if sign == 1 {
			$cands = $cands.append({ len: base + 2, rule: 36, action: Junk("trailing junk after numeric literal") })
		}
	}
	# The junk rules: an identifier right after any match of {decinteger},
	# {numeric} or {real}.
	$cands = add_junk(bytes, i, digit_ends(bytes, i, d), 37, $cands)
	if numeric > 0 {
		point_end = if d > 0 [frac] else []
		$cands = add_junk(bytes, i, point_end.concat(digit_ends(bytes, frac, f)), 38, $cands)
	}
	if $exp_len > 0 {
		$cands = add_junk(bytes, i, digit_ends(bytes, $exp_start, $exp_len), 39, $cands)
	}
	best = $cands.fold(
		{ len: 0, rule: 99, action: Float },
		|acc, c| if c.len > acc.len or (c.len == acc.len and c.rule < acc.rule) c else acc,
	)
	end = i + best.len
	match best.action {
		Integer => Ok(integer_token(bytes, i, end))
		Float => Ok({ kind: FConst(text(bytes, i, end)), start: i, end })
		IntegerBefore(n) => Ok(integer_token(bytes, i, i + n))
		Junk(message) => Err(yyerror(bytes, message, i, end))
	}
}

## A match of a numeric rule: its length, the rule's place in `scan.l`, and
## what it does.
NumCand : { len : U64, rule : U64, action : NumAction }

## A junk rule's match for every position in `ends` where an identifier
## starts: from `i` to the end of that identifier.
add_junk : List(U8), U64, List(U64), U64, List(NumCand) -> List(NumCand)
add_junk = |bytes, i, ends, rule, cands| {
	var $out = cands
	for k in ends {
		if is_ident_start(at(bytes, k)) {
			$out = $out.append({ len: ident_cont_end(bytes, k) - i, rule, action: Junk("trailing junk after numeric literal") })
		}
	}
	$out
}

## `ICONST` when the literal fits an `I32`, `FCONST` otherwise.
integer_token : List(U8), U64, U64 -> Scan.Token
integer_token = |bytes, start, end| {
	kind =
		match int_value(bytes, start, end) {
			Ok(v) => IConst(v)
			Err(_) => FConst(text(bytes, start, end))
		}
	{ kind, start, end }
}

## The value of an integer literal with an optional `0x`, `0o` or `0b`
## prefix and `_` separators, if it fits an `I32`.
int_value : List(U8), U64, U64 -> Try(I32, [TooLarge])
int_value = |bytes, start, end| {
	p1 = at(bytes, start + 1)
	radix = if at(bytes, start) != '0' 10 else if p1 == 'x' or p1 == 'X' 16 else if p1 == 'o' or p1 == 'O' 8 else if p1 == 'b' or p1 == 'B' 2 else 10
	from = if radix == 10 start else start + 2
	var $v = 0.U64
	var $p = from
	while $p < end {
		c = at(bytes, $p)
		if c != '_' {
			$v = $v * radix + digit_of(c)
			if $v > 2147483647 {
				return Err(TooLarge)
			}
		}
		$p = $p + 1
	}
	$v.to_i32_try().map_err(|_| TooLarge)
}

## The end of a comment starting with `/*` at `start`. Comments nest.
comment_end : List(U8), U64 -> Try(U64, Scan.Problem)
comment_end = |bytes, start| {
	len = bytes.len()
	var $p = start + 2
	var $depth = 0.I64
	while Bool.True {
		if $p >= len {
			return Err(yyerror(bytes, "unterminated /* comment", start, len))
		}
		c = at(bytes, $p)
		if c == '/' and at(bytes, $p + 1) == '*' {
			$depth = $depth + 1
			$p = $p + 2
		} else if c == '*' {
			stars_end = run_end(bytes, $p, |s| s == '*')
			if at(bytes, stars_end) == '/' {
				if $depth <= 0 {
					return Ok(stars_end + 1)
				}
				$depth = $depth - 1
				$p = stars_end + 1
			} else {
				$p = stars_end
			}
		} else {
			$p = $p + 1
		}
	}
}

## An operator at `i`: a run of operator characters, cut where a comment
## starts, without trailing `+` and `-` unless it holds a character that no
## SQL operator has.
operator : List(U8), U64 -> Try(Scan.Token, Scan.Problem)
operator = |bytes, i| {
	run = run_end(bytes, i, is_op_char)
	l = run - i
	b = at(bytes, i)
	if l == 1 {
		kind = if is_self(b) Char(b) else Op(text(bytes, i, run))
		return Ok({ kind, start: i, end: run })
	}
	if l == 2 {
		match special(b, at(bytes, i + 1)) {
			Ok(kind) => {
				return Ok({ kind, start: i, end: run })
			}
			Err(_) => {}
		}
	}
	var $n = l
	var $k = i + 1
	while $k + 1 < run {
		if (at(bytes, $k) == '/' and at(bytes, $k + 1) == '*') or (at(bytes, $k) == '-' and at(bytes, $k + 1) == '-') {
			$n = $k - i
			$k = run
		} else {
			$k = $k + 1
		}
	}
	last = at(bytes, i + $n - 1)
	if $n > 1 and (last == '+' or last == '-') {
		qualifying = bytes.sublist({ start: i, len: $n - 1 }).any(|c| c == '~' or c == '!' or c == '@' or c == '#' or c == '^' or c == '&' or c == '|' or c == '`' or c == '?' or c == '%')
		if !qualifying {
			$n = $n - 1
			while $n > 1 and (at(bytes, i + $n - 1) == '+' or at(bytes, i + $n - 1) == '-') {
				$n = $n - 1
			}
		}
	}
	if $n < l {
		if $n == 1 and is_self(b) {
			return Ok({ kind: Char(b), start: i, end: i + 1 })
		}
		if $n == 2 {
			match special(b, at(bytes, i + 1)) {
				Ok(kind) => {
					return Ok({ kind, start: i, end: i + 2 })
				}
				Err(_) => {}
			}
		}
	}
	if $n >= 64 {
		return Err(yyerror(bytes, "operator too long", i, i + $n))
	}
	Ok({ kind: Op(text(bytes, i, i + $n)), start: i, end: i + $n })
}

## The two-character operators with tokens of their own.
special : U8, U8 -> Try(Scan.Kind, [NotSpecial])
special = |a, b|
	if a == '=' and b == '>' {
		Ok(EqualsGreater)
	} else if a == '>' and b == '=' {
		Ok(GreaterEquals)
	} else if a == '<' and b == '=' {
		Ok(LessEquals)
	} else if (a == '<' and b == '>') or (a == '!' and b == '=') {
		Ok(NotEquals)
	} else {
		Err(NotSpecial)
	}

## The server's `yyerror`: the message, then the text from `loc` to the end
## of the current match, or "at end of input" when `loc` is the end.
yyerror : List(U8), Str, U64, U64 -> Scan.Problem
yyerror = |bytes, message, loc, end| {
	full = if loc >= bytes.len() "${message} at end of input" else "${message} at or near \"${text(bytes, loc, end)}\""
	{ message: full, code: "42601", cursor: cursor(bytes, loc) }
}

## A byte offset as the server's cursor: the 1-based character position.
cursor : List(U8), U64 -> U64
cursor = |bytes, loc|
	bytes.take_first(loc).fold(1, |n, b| if b >= 0x80 and b < 0xC0 n else n + 1)

## An identifier cut to 63 bytes without splitting a character.
truncate : List(U8) -> Str
truncate = |ident| {
	if ident.len() < 64 {
		Str.from_utf8_lossy(ident)
	} else {
		var $n = 63
		while $n > 0 and at(ident, $n) >= 0x80 and at(ident, $n) < 0xC0 {
			$n = $n - 1
		}
		Str.from_utf8_lossy(ident.take_first($n))
	}
}

## A code point as UTF-8.
utf8 : U64 -> List(U8)
utf8 = |cp|
	if cp < 0x80 {
		[cp.to_u8_wrap()]
	} else if cp < 0x800 {
		[(0xC0 + cp // 64).to_u8_wrap(), (0x80 + cp % 64).to_u8_wrap()]
	} else if cp < 0x10000 {
		[(0xE0 + cp // 4096).to_u8_wrap(), (0x80 + (cp // 64) % 64).to_u8_wrap(), (0x80 + cp % 64).to_u8_wrap()]
	} else {
		[(0xF0 + cp // 262144).to_u8_wrap(), (0x80 + (cp // 4096) % 64).to_u8_wrap(), (0x80 + (cp // 64) % 64).to_u8_wrap(), (0x80 + cp % 64).to_u8_wrap()]
	}

## {decinteger}: digits with single `_` between them.
dec_len : List(U8), U64 -> U64
dec_len = |bytes, p| {
	if !is_digit(at(bytes, p)) {
		return 0
	}
	var $j = p + 1
	var $more = Bool.True
	while $more {
		c = at(bytes, $j)
		if is_digit(c) {
			$j = $j + 1
		} else if c == '_' and is_digit(at(bytes, $j + 1)) {
			$j = $j + 2
		} else {
			$more = Bool.False
		}
	}
	$j - p
}

## `(_?{digit})+` after a `0x`, `0o` or `0b` prefix.
based_len : List(U8), U64, (U8 -> Bool) -> U64
based_len = |bytes, p, is_digit_of| {
	var $j = p
	var $more = Bool.True
	while $more {
		c = at(bytes, $j)
		if is_digit_of(c) {
			$j = $j + 1
		} else if c == '_' and is_digit_of(at(bytes, $j + 1)) {
			$j = $j + 2
		} else {
			$more = Bool.False
		}
	}
	$j - p
}

## The positions right after each digit of a run of `len` bytes at `p`:
## everywhere a prefix of it ends in a digit.
digit_ends : List(U8), U64, U64 -> List(U64)
digit_ends = |bytes, p, len| {
	var $ends = []
	var $j = p
	while $j < p + len {
		if is_digit(at(bytes, $j)) {
			$ends = $ends.append($j + 1)
		}
		$j = $j + 1
	}
	$ends
}

digits_value : List(U8), U64, U64, U64 -> U64
digits_value = |bytes, p, n, radix|
	bytes.sublist({ start: p, len: n }).fold(0, |v, c| v * radix + digit_of(c))

digit_of : U8 -> U64
digit_of = |c|
	if c >= '0' and c <= '9' {
		(c - '0').to_u64()
	} else if c >= 'a' and c <= 'f' {
		(c - 'a').to_u64() + 10
	} else if c >= 'A' and c <= 'F' {
		(c - 'A').to_u64() + 10
	} else {
		0
	}

hex2 : U8 -> Str
hex2 = |b| {
	digits = "0123456789abcdef".to_utf8()
	Str.from_utf8_lossy([at(digits, (b // 16).to_u64()), at(digits, (b % 16).to_u64())])
}

## How many bytes from `p`, at most `max`, satisfy `pred`.
run_len : List(U8), U64, U64, (U8 -> Bool) -> U64
run_len = |bytes, p, max, pred| {
	var $n = 0
	while $n < max and p + $n < bytes.len() and pred(at(bytes, p + $n)) {
		$n = $n + 1
	}
	$n
}

## The end of the run of bytes from `p` that satisfy `pred`.
run_end : List(U8), U64, (U8 -> Bool) -> U64
run_end = |bytes, p, pred| p + run_len(bytes, p, bytes.len(), pred)

ident_cont_end : List(U8), U64 -> U64
ident_cont_end = |bytes, p| run_end(bytes, p, is_ident_cont)

line_end : List(U8), U64 -> U64
line_end = |bytes, p| run_end(bytes, p, |c| c != '\n' and c != '\r')

at : List(U8), U64 -> U8
at = |bytes, i| bytes.get(i) ?? 0

text : List(U8), U64, U64 -> Str
text = |bytes, start, end| Str.from_utf8_lossy(bytes.sublist({ start, len: end - start }))

ascii_lower : U8 -> U8
ascii_lower = |b| if b >= 'A' and b <= 'Z' b + 32 else b

is_space : U8 -> Bool
is_space = |b| b == ' ' or b == '\t' or b == '\n' or b == '\r' or b == 12 or b == 11

is_digit : U8 -> Bool
is_digit = |b| b >= '0' and b <= '9'

is_hex : U8 -> Bool
is_hex = |b| is_digit(b) or (b >= 'a' and b <= 'f') or (b >= 'A' and b <= 'F')

is_oct : U8 -> Bool
is_oct = |b| b >= '0' and b <= '7'

is_bin : U8 -> Bool
is_bin = |b| b == '0' or b == '1'

is_ident_start : U8 -> Bool
is_ident_start = |b| (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z') or b == '_' or b >= 128

is_ident_cont : U8 -> Bool
is_ident_cont = |b| is_ident_start(b) or is_digit(b) or b == '$'

is_dolq_cont : U8 -> Bool
is_dolq_cont = |b| is_ident_start(b) or is_digit(b)

## `self`: the characters that are tokens of their own.
is_self : U8 -> Bool
is_self = |b|
	b == ',' or b == '(' or b == ')' or b == '[' or b == ']' or b == '.' or b == ';' or b == ':' or b == '+' or b == '-' or b == '*' or b == '/' or b == '%' or b == '^' or b == '<' or b == '>' or b == '='

is_op_char : U8 -> Bool
is_op_char = |b|
	b == '~' or b == '!' or b == '@' or b == '#' or b == '^' or b == '&' or b == '|' or b == '`' or b == '?' or b == '+' or b == '-' or b == '*' or b == '/' or b == '%' or b == '<' or b == '>' or b == '='

names : Str -> List(Str)
names = |sql|
	match Scan.tokens(sql) {
		Ok(toks) => toks.map(|t| Scan.token_name(t.kind))
		Err(p) => [p.message]
	}

expect names("select 1") == ["SELECT", "ICONST"]
expect names("select 'it''s' || $q$x$q$ -- c") == ["SELECT", "SCONST", "Op", "SCONST", "SQL_COMMENT"]
expect names("a<=b<>c!=d=>e>=f=-1") == ["IDENT", "LESS_EQUALS", "IDENT", "NOT_EQUALS", "IDENT", "NOT_EQUALS", "IDENT", "EQUALS_GREATER", "IDENT", "GREATER_EQUALS", "IDENT", "ASCII_61", "ASCII_45", "ICONST"]
expect names("x::int, 1..10, a := 2") == ["IDENT", "TYPECAST", "INT_P", "ASCII_44", "ICONST", "DOT_DOT", "ICONST", "ASCII_44", "IDENT", "COLON_EQUALS", "ICONST"]
expect names("$school_id") == ["ASCII_36", "IDENT"]
expect names("select 0x1Fz") == ["trailing junk after numeric literal at or near \"0x1Fz\""]
expect names("select 'oops") == ["unterminated quoted string at or near \"'oops\""]
expect names("2147483647 2147483648 0x7FFFFFFF 1_000 1.5e3 .5") == ["ICONST", "FCONST", "ICONST", "ICONST", "FCONST", "FCONST"]
expect Scan.tokens("E'\\u00e9' 'a'\n'b'").map_ok(|toks| toks.map(|t| t.kind)) == Ok([SConst("é"), SConst("ab")])

## The keyword NCHAR, which the lexer puts before an `N'...'` string.
nchar : U64
nchar = Keywords.lookup("nchar") ?? 0
