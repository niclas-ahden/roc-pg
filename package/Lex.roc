## A lexer for PostgreSQL's SQL syntax, used at compile time to check query
## literals and to read `schema.sql`.
##
## It follows the server's lexical rules: string constants in every prefix
## form (`'..'`, `E'..'`, `B'..'`, `X'..'`, `N'..'`, `U&'..'`), dollar quotes
## (`$$..$$`, `$tag$..$tag$`), quoted identifiers, nested block comments,
## operators, and `::` casts. On top of that, `$name` is a named parameter
## of this package, while `$1` stays a positional one.
Lex :: [].{
	Kind : [
		## An unquoted identifier or keyword, lowercased like the server does.
		Word(Str),
		## A double quoted identifier, case kept.
		Quoted(Str),
		## A string constant of any form.
		Text,
		Number,
		## `$name`, a named parameter.
		Named(Str),
		## `$1`, a positional parameter.
		Positional(U64),
		Op(Str),
		Punct(U8),
	]

	Token : { kind : Lex.Kind, start : U64, end : U64 }

	LexErr : [UnterminatedString(U64), UnterminatedQuotedIdent(U64), UnterminatedComment(U64), UnterminatedDollarQuote(U64)]

	## Split `sql` into tokens, dropping whitespace and comments.
	tokens : Str -> Try(List(Lex.Token), Lex.LexErr)
	tokens = |sql| {
		bytes = sql.to_utf8()
		len = bytes.len()
		var $i = 0
		var $out = []
		while $i < len {
			b = at(bytes, $i)
			next = at(bytes, $i + 1)
			if is_space(b) {
				$i = $i + 1
			} else if b == '-' and next == '-' {
				$i = line_end(bytes, $i)
			} else if b == '/' and next == '*' {
				$i = comment_end(bytes, $i)?
			} else if b == '\'' {
				end = string_end(bytes, $i + 1, Bool.False) ? |_| UnterminatedString($i)
				$out = $out.append({ kind: Text, start: $i, end })
				$i = end
			} else if (b == 'e' or b == 'E') and next == '\'' {
				end = string_end(bytes, $i + 2, Bool.True) ? |_| UnterminatedString($i)
				$out = $out.append({ kind: Text, start: $i, end })
				$i = end
			} else if (b == 'b' or b == 'B' or b == 'x' or b == 'X' or b == 'n' or b == 'N') and next == '\'' {
				end = string_end(bytes, $i + 2, Bool.False) ? |_| UnterminatedString($i)
				$out = $out.append({ kind: Text, start: $i, end })
				$i = end
			} else if (b == 'u' or b == 'U') and next == '&' and at(bytes, $i + 2) == '\'' {
				end = string_end(bytes, $i + 3, Bool.False) ? |_| UnterminatedString($i)
				$out = $out.append({ kind: Text, start: $i, end })
				$i = end
			} else if (b == 'u' or b == 'U') and next == '&' and at(bytes, $i + 2) == '"' {
				end = quoted_end(bytes, $i + 3) ? |_| UnterminatedQuotedIdent($i)
				$out = $out.append({ kind: Quoted(unquote(bytes, $i + 3, end)), start: $i, end })
				$i = end
			} else if b == '"' {
				end = quoted_end(bytes, $i + 1) ? |_| UnterminatedQuotedIdent($i)
				$out = $out.append({ kind: Quoted(unquote(bytes, $i + 1, end)), start: $i, end })
				$i = end
			} else if b == '$' {
				if is_digit(next) {
					end = digits_end(bytes, $i + 1)
					n = U64.from_str(text(bytes, $i + 1, end)) ?? 0
					$out = $out.append({ kind: Positional(n), start: $i, end })
					$i = end
				} else if next == '$' {
					end = dollar_quote_end(bytes, $i + 2, "$$")?
					$out = $out.append({ kind: Text, start: $i, end })
					$i = end
				} else if is_ident_start(next) {
					name_end = tag_end(bytes, $i + 1)
					if at(bytes, name_end) == '$' {
						delimiter = text(bytes, $i, name_end + 1)
						end = dollar_quote_end(bytes, name_end + 1, delimiter)?
						$out = $out.append({ kind: Text, start: $i, end })
						$i = end
					} else {
						$out = $out.append({ kind: Named(text(bytes, $i + 1, name_end)), start: $i, end: name_end })
						$i = name_end
					}
				} else {
					$out = $out.append({ kind: Op("$"), start: $i, end: $i + 1 })
					$i = $i + 1
				}
			} else if is_ident_start(b) {
				end = ident_end(bytes, $i)
				$out = $out.append({ kind: Word(text(bytes, $i, end).with_ascii_lowercased()), start: $i, end })
				$i = end
			} else if is_digit(b) or (b == '.' and is_digit(next)) {
				end = number_end(bytes, $i)
				$out = $out.append({ kind: Number, start: $i, end })
				$i = end
			} else if b == ':' {
				if next == ':' {
					$out = $out.append({ kind: Op("::"), start: $i, end: $i + 2 })
					$i = $i + 2
				} else if next == '=' {
					$out = $out.append({ kind: Op(":="), start: $i, end: $i + 2 })
					$i = $i + 2
				} else {
					$out = $out.append({ kind: Punct(b), start: $i, end: $i + 1 })
					$i = $i + 1
				}
			} else if b == '(' or b == ')' or b == '[' or b == ']' or b == ',' or b == ';' or b == '.' {
				$out = $out.append({ kind: Punct(b), start: $i, end: $i + 1 })
				$i = $i + 1
			} else if is_op_char(b) {
				end = operator_end(bytes, $i)
				$out = $out.append({ kind: Op(text(bytes, $i, end)), start: $i, end })
				$i = end
			} else {
				$out = $out.append({ kind: Op(text(bytes, $i, $i + 1)), start: $i, end: $i + 1 })
				$i = $i + 1
			}
		}
		Ok($out)
	}

	## Replace every `$name` with `$1`, `$2`, ... in order of first use, and
	## return the names in that order. Everything else is kept byte for byte.
	number_placeholders : Str, List(Lex.Token) -> { text : Str, names : List(Str) }
	number_placeholders = |sql, toks| {
		bytes = sql.to_utf8()
		var $names = []
		var $out = []
		var $copied = 0
		for tok in toks {
			match tok.kind {
				Named(name) => {
					index =
						match $names.find_first_index(|n| n == name) {
							Ok(found) => found + 1
							Err(_) => {
								$names = $names.append(name)
								$names.len()
							}
						}
					$out = $out.concat(bytes.sublist({ start: $copied, len: tok.start - $copied })).concat("$${index.to_str()}".to_utf8())
					$copied = tok.end
				}
				_ => {}
			}
		}
		$out = $out.concat(bytes.drop_first($copied))
		{ text: Str.from_utf8_lossy($out), names: $names }
	}

	## The text for Postgres's grammar, which only knows numbered parameters:
	## every `$name` becomes `$1`, padded with spaces to the same length. So
	## every byte offset, a syntax error's cursor and each parameter's
	## location in the parse tree, still points into `sql`.
	grammar_text : Str, List(Lex.Token) -> Str
	grammar_text = |sql, toks| {
		bytes = sql.to_utf8()
		var $out = []
		var $copied = 0
		for tok in toks {
			match tok.kind {
				Named(_) => {
					$out = $out.concat(bytes.sublist({ start: $copied, len: tok.start - $copied })).concat("$1".to_utf8())
					var $pad = tok.end - tok.start - 2
					while $pad > 0 {
						$out = $out.append(' ')
						$pad = $pad - 1
					}
					$copied = tok.end
				}
				_ => {}
			}
		}
		Str.from_utf8_lossy($out.concat(bytes.drop_first($copied)))
	}

	## Each `$name` and the byte offset it starts at, which is the location of
	## its parameter in the parse tree of [Lex.grammar_text].
	named_at : List(Lex.Token) -> List({ at : I64, name : Str })
	named_at = |toks|
		toks.keep_oks(
			|tok|
				match tok.kind {
					Named(name) => Ok({ at: tok.start.to_i64_wrap(), name })
					_ => Err(NotNamed)
				},
		)

	## "line 2, column 7" for a byte offset into `sql`.
	position : Str, U64 -> Str
	position = |sql, offset| {
		before = sql.to_utf8().take_first(offset)
		var $line = 1.U64
		var $column = 1.U64
		for b in before {
			if b == '\n' {
				$line = $line + 1
				$column = 1.U64
			} else {
				$column = $column + 1
			}
		}
		"line ${$line.to_str()}, column ${$column.to_str()}"
	}

	## The byte offset of a server cursor, a 1-based character position.
	cursor_offset : List(U8), U64 -> U64
	cursor_offset = |bytes, cursor| {
		var $chars = 0
		var $i = 0
		while $i < bytes.len() {
			b = bytes.get($i) ?? 0
			if b < 0x80 or b >= 0xC0 {
				$chars = $chars + 1
				if $chars == cursor {
					return $i
				}
			}
			$i = $i + 1
		}
		bytes.len()
	}

	## The source text of a token.
	token_text : Str, Lex.Token -> Str
	token_text = |sql, tok| text(sql.to_utf8(), tok.start, tok.end)

	## Render a lexer error for a message.
	err_to_str : Str, Lex.LexErr -> Str
	err_to_str = |sql, err|
		match err {
			UnterminatedString(at_offset) => "unterminated string constant at ${Lex.position(sql, at_offset)}"
			UnterminatedQuotedIdent(at_offset) => "unterminated quoted identifier at ${Lex.position(sql, at_offset)}"
			UnterminatedComment(at_offset) => "unterminated /* comment at ${Lex.position(sql, at_offset)}"
			UnterminatedDollarQuote(at_offset) => "unterminated dollar-quoted string at ${Lex.position(sql, at_offset)}"
		}
}

at : List(U8), U64 -> U8
at = |bytes, i| bytes.get(i) ?? 0

text : List(U8), U64, U64 -> Str
text = |bytes, start, end| Str.from_utf8_lossy(bytes.sublist({ start, len: end - start }))

is_space : U8 -> Bool
is_space = |b| b == ' ' or b == '\t' or b == '\n' or b == '\r' or b == 12

is_digit : U8 -> Bool
is_digit = |b| b >= '0' and b <= '9'

is_ident_start : U8 -> Bool
is_ident_start = |b| (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z') or b == '_' or b >= 128

is_ident_char : U8 -> Bool
is_ident_char = |b| is_ident_start(b) or is_digit(b) or b == '$'

## Characters that make up operators, per the server's lexer.
is_op_char : U8 -> Bool
is_op_char = |b|
	b == '+' or b == '-' or b == '*' or b == '/' or b == '<' or b == '>' or b == '=' or b == '~' or b == '!' or b == '@' or b == '#' or b == '%' or b == '^' or b == '&' or b == '|' or b == '`' or b == '?'

ident_end : List(U8), U64 -> U64
ident_end = |bytes, start| {
	var $i = start
	while is_ident_char(at(bytes, $i)) and $i < bytes.len() {
		$i = $i + 1
	}
	$i
}

## The end of a dollar quote tag or a named parameter: identifier characters
## without `$`, which ends the tag.
tag_end : List(U8), U64 -> U64
tag_end = |bytes, start| {
	var $i = start
	while (is_ident_start(at(bytes, $i)) or is_digit(at(bytes, $i))) and $i < bytes.len() {
		$i = $i + 1
	}
	$i
}

digits_end : List(U8), U64 -> U64
digits_end = |bytes, start| {
	var $i = start
	while is_digit(at(bytes, $i)) and $i < bytes.len() {
		$i = $i + 1
	}
	$i
}

## Numbers: digits with `_` separators, a decimal point, an exponent, and the
## `0x`, `0o`, `0b` prefixes. Anything alphanumeric glued to it is included,
## which the server rejects anyway.
number_end : List(U8), U64 -> U64
number_end = |bytes, start| {
	var $i = start
	while $i < bytes.len() {
		b = at(bytes, $i)
		if is_digit(b) or (b >= 'a' and b <= 'z') or (b >= 'A' and b <= 'Z') or b == '_' {
			if (b == 'e' or b == 'E') and (at(bytes, $i + 1) == '+' or at(bytes, $i + 1) == '-') and is_digit(at(bytes, $i + 2)) {
				$i = $i + 2
			} else {
				$i = $i + 1
			}
		} else if b == '.' and at(bytes, $i + 1) != '.' {
			$i = $i + 1
		} else {
			break
		}
	}
	$i
}

line_end : List(U8), U64 -> U64
line_end = |bytes, start| {
	var $i = start
	while $i < bytes.len() and at(bytes, $i) != '\n' {
		$i = $i + 1
	}
	$i
}

## Block comments nest in SQL.
comment_end : List(U8), U64 -> Try(U64, [UnterminatedComment(U64), ..others])
comment_end = |bytes, start| {
	var $i = start + 2
	var $depth = 1
	while $depth > 0 {
		if $i >= bytes.len() {
			return Err(UnterminatedComment(start))
		}
		if at(bytes, $i) == '/' and at(bytes, $i + 1) == '*' {
			$depth = $depth + 1
			$i = $i + 2
		} else if at(bytes, $i) == '*' and at(bytes, $i + 1) == '/' {
			$depth = $depth - 1
			$i = $i + 2
		} else {
			$i = $i + 1
		}
	}
	Ok($i)
}

## After the opening quote: `''` is a quote, and with `escapes` (an `E'..'`
## string) a backslash escapes the next byte.
string_end : List(U8), U64, Bool -> Try(U64, [UnterminatedString(U64), ..others])
string_end = |bytes, start, escapes| {
	var $i = start
	while Bool.True {
		if $i >= bytes.len() {
			return Err(UnterminatedString(start))
		}
		b = at(bytes, $i)
		if escapes and b == '\\' {
			$i = $i + 2
		} else if b == '\'' {
			if at(bytes, $i + 1) == '\'' {
				$i = $i + 2
			} else {
				return Ok($i + 1)
			}
		} else {
			$i = $i + 1
		}
	}
}

## After the opening double quote: `""` is a double quote.
quoted_end : List(U8), U64 -> Try(U64, [UnterminatedQuotedIdent(U64), ..others])
quoted_end = |bytes, start| {
	var $i = start
	while Bool.True {
		if $i >= bytes.len() {
			return Err(UnterminatedQuotedIdent(start))
		}
		if at(bytes, $i) == '"' {
			if at(bytes, $i + 1) == '"' {
				$i = $i + 2
			} else {
				return Ok($i + 1)
			}
		} else {
			$i = $i + 1
		}
	}
}

## The name inside a quoted identifier, `""` turned back into `"`.
unquote : List(U8), U64, U64 -> Str
unquote = |bytes, start, end| text(bytes, start, end - 1).replace_each("\"\"", "\"")

## After an opening `$tag$`: up to and including the same delimiter.
dollar_quote_end : List(U8), U64, Str -> Try(U64, [UnterminatedDollarQuote(U64), ..others])
dollar_quote_end = |bytes, start, delimiter| {
	delim = delimiter.to_utf8()
	var $i = start
	while $i + delim.len() <= bytes.len() {
		if bytes.sublist({ start: $i, len: delim.len() }) == delim {
			return Ok($i + delim.len())
		}
		$i = $i + 1
	}
	Err(UnterminatedDollarQuote(start - delim.len()))
}

## A run of operator characters. `--` and `/*` start a comment inside it, and
## like the server, a multi-character operator only ends in `+` or `-` when it
## also holds one of `~ ! @ # % ^ & | \` ?`, so `=-1` is `=` then `-1`.
operator_end : List(U8), U64 -> U64
operator_end = |bytes, start| {
	var $i = start
	while $i < bytes.len() and is_op_char(at(bytes, $i)) {
		if $i > start and ((at(bytes, $i) == '-' and at(bytes, $i + 1) == '-') or (at(bytes, $i) == '/' and at(bytes, $i + 1) == '*')) {
			break
		}
		if at(bytes, $i) == '-' and at(bytes, $i + 1) == '-' {
			break
		}
		$i = $i + 1
	}
	var $end = $i
	run = bytes.sublist({ start, len: $end - start })
	special = run.any(|b| b == '~' or b == '!' or b == '@' or b == '#' or b == '%' or b == '^' or b == '&' or b == '|' or b == '`' or b == '?')
	while $end - start > 1 and !special and (at(bytes, $end - 1) == '+' or at(bytes, $end - 1) == '-') {
		$end = $end - 1
	}
	if $end == start start + 1 else $end
}

kinds : Str -> List(Lex.Kind)
kinds = |sql|
	match Lex.tokens(sql) {
		Ok(toks) => toks.map(|t| t.kind)
		Err(_) => []
	}

expect kinds("SELECT a, \"B\"\"c\" FROM t") == [Word("select"), Word("a"), Punct(','), Quoted("B\"c"), Word("from"), Word("t")]
expect kinds("x = $school_id and y = $1") == [Word("x"), Op("="), Named("school_id"), Word("and"), Word("y"), Op("="), Positional(1)]
expect kinds("'it''s $x' || E'a\\'b' || $$ $y $$ || $q$ ' $z $q$") == [Text, Op("||"), Text, Op("||"), Text, Op("||"), Text]
expect kinds("a::text -- $c\n/* $d /* nested */ $e */ b") == [Word("a"), Op("::"), Word("text"), Word("b")]
expect kinds("x=-1 and y <> 2.5e-3 and z >= .5") == [Word("x"), Op("="), Op("-"), Number, Word("and"), Word("y"), Op("<>"), Number, Word("and"), Word("z"), Op(">="), Number]
expect kinds("arr[1:2] and a @> b and 1_000") == [Word("arr"), Punct('['), Number, Punct(':'), Number, Punct(']'), Word("and"), Word("a"), Op("@>"), Word("b"), Word("and"), Number]
expect kinds("U&\"d\\0061t\" and b'101' and x'ff' and n'x'") == [Quoted("d\\0061t"), Word("and"), Text, Word("and"), Text, Word("and"), Text]
expect Lex.tokens("select 'oops") == Err(UnterminatedString(7))
expect Lex.tokens("select /* oops") == Err(UnterminatedComment(7))
expect Lex.tokens("select $a$ oops") == Err(UnterminatedDollarQuote(7))

expect {
	sql = "select * from t where a = $a and b = $b::int or c = $a and d = '$x' and e = $$ $y $$"
	toks = Lex.tokens(sql) ?? []
	Lex.number_placeholders(sql, toks) == { text: "select * from t where a = $1 and b = $2::int or c = $1 and d = '$x' and e = $$ $y $$", names: ["a", "b"] }
}

expect Lex.position("select\n  x", 9) == "line 2, column 3"
