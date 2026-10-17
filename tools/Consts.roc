## The named constants that Postgres's parser code uses: `enum` values and
## `#define` macros from its headers, and the SQLSTATE of each `ERRCODE_`
## name from `errcodes.txt`.
import CParse

Consts :: [].{
	Value : [Int(I64), Text(Str)]

	## `#define NAME value` lines and `enum { ... }` blocks of C sources.
	## An earlier source wins over a later one that defines the same name.
	## Values are kept as their text and evaluated by [Consts.resolve].
	Table : { defines : Dict(Str, Str), enums : Dict(Str, I64) }

	collect : List(Str) -> Consts.Table
	collect = |sources| {
		# All the defines first, since an enum value may use a define from a
		# later header.
		defines = sources.fold(
			Dict.empty(),
			|acc, source| defines_of(source).fold(acc, |d, (name, value)| if d.contains(name) d else d.insert(name, value)),
		)
		sources.fold(
			{ defines, enums: Dict.empty() },
			|table, source| {
				with_enums = enums_of(source, table).fold(
					table.enums,
					|acc, (name, value)| if acc.contains(name) acc else acc.insert(name, value),
				)
				{ ..table, enums: with_enums }
			},
		)
	}

	## The value of a constant, if it has one that is a number or a string.
	resolve : Consts.Table, Str -> Try(Consts.Value, [Unknown(Str)])
	resolve = |table, name| resolve_depth(table, name, 0)

	## The enum entries of `sources` whose value is an expression that
	## does not evaluate, as `NAME = text`. Each would otherwise silently
	## take the value after the previous entry.
	unresolved : List(Str), Consts.Table -> List(Str)
	unresolved = |sources, table| sources.fold([], |acc, source| enum_blocks(source, table).fold(acc, |a, b| a.concat(b.unresolved)))

	## A C integer literal: decimal, hex or octal, with any suffix.
	number : Str -> Try(I64, [NotNumber])
	number = |text| c_number(text)

	## Each enum type's constants and their values, by the type's name. The
	## first definition of a name wins.
	enum_types : List(Str), Consts.Table -> Dict(Str, List((Str, I64)))
	enum_types = |sources, table|
		sources.fold(
			Dict.empty(),
			|acc, source| enum_blocks(source, table).fold(acc, |d, b| if b.name.is_empty() or d.contains(b.name) d else d.insert(b.name, b.values)),
		)

	## `ERRCODE_NAME` to SQLSTATE, from `errcodes.txt`.
	errcodes : Str -> Dict(Str, Str)
	errcodes = |text|
		text.split_on("\n").fold(
			Dict.empty(),
			|acc, line| {
				fields = line.split_on(" ").keep_if(|f| !f.is_empty()).map(|f| f.trim())
				code = fields.get(0) ?? ""
				name = fields.get(2) ?? ""
				if code.to_utf8().len() == 5 and name.starts_with("ERRCODE_") acc.insert(name, code) else acc
			},
		)
}

## Constants of the C library and of headers generated at build time.
builtin : List((Str, Consts.Value))
builtin = [
	("INT_MAX", Int(2147483647)),
	("INT_MIN", Int(-2147483648)),
	("LONG_MAX", Int(9223372036854775807)),
	("INT16_MAX", Int(32767)),
	("INT32_MAX", Int(2147483647)),
	("TEXTOID", Int(25)),
]

resolve_depth : Consts.Table, Str, U64 -> Try(Consts.Value, [Unknown(Str)])
resolve_depth = |table, name, depth| {
	if depth > 20 {
		return Err(Unknown(name))
	}
	match builtin.find_first(|(n, _)| n == name) {
		Ok((_, v)) => return Ok(v)
		Err(_) => {}
	}
	match table.enums.get(name) {
		Ok(v) => return Ok(Int(v))
		Err(_) => {}
	}
	text = table.defines.get(name) ? |_| Unknown(name)
	expr = CParse.expression_text(text) ? |_| Unknown(name)
	evaluate(table, expr, depth + 1).map_err(|_| Unknown(name))
}

## A constant expression, with names looked up in the table.
evaluate : Consts.Table, CParse.Expr, U64 -> Try(Consts.Value, [Unknown(Str)])
evaluate = |table, expr, depth|
	match expr {
		Num(text) => c_number(text).map_ok(|n| Int(n)).map_err(|_| Unknown(text))
		CharLit(c) => Ok(Int(c.to_i64()))
		StrLit(bytes) => Ok(Text(Str.from_utf8_lossy(bytes)))
		Ident(name) => resolve_depth(table, name, depth)
		Cast(_, inner) => evaluate(table, inner, depth)
		Prefix("-", inner) => {
			v = int_of(evaluate(table, inner, depth)?)?
			Ok(Int(0 - v))
		}
		Prefix("~", inner) => {
			v = int_of(evaluate(table, inner, depth)?)?
			Ok(Int(-1 - v))
		}
		Binary(op, a, b) => {
			x = int_of(evaluate(table, a, depth)?)?
			y = int_of(evaluate(table, b, depth)?)?
			Ok(Int(binary(op, x, y)))
		}
		Call(Ident(name), [arg]) =>
			if name == "INTERVAL_MASK" {
				v = int_of(evaluate(table, arg, depth)?)?
				Ok(Int(shift_left(1, v)))
			} else {
				# `Type(x)`: a C++ style cast.
				evaluate(table, arg, depth)
			}
		_ => Err(Unknown("expression"))
	}

int_of : Consts.Value -> Try(I64, [Unknown(Str)])
int_of = |v|
	match v {
		Int(n) => Ok(n)
		Text(t) => Err(Unknown(t))
	}

binary : Str, I64, I64 -> I64
binary = |op, x, y|
	if op == "+" {
		x + y
	} else if op == "-" {
		x - y
	} else if op == "*" {
		x * y
	} else if op == "|" {
		bit_or(x, y)
	} else if op == "&" {
		bit_and(x, y)
	} else if op == "<<" {
		shift_left(x, y)
	} else {
		0
	}

shift_left : I64, I64 -> I64
shift_left = |x, n| if n <= 0 x else shift_left(x * 2, n - 1)

## Bitwise or and and, on the non-negative values flags use.
bit_or : I64, I64 -> I64
bit_or = |x, y| bit_combine(x, y, Bool.True)

bit_and : I64, I64 -> I64
bit_and = |x, y| bit_combine(x, y, Bool.False)

bit_combine : I64, I64, Bool -> I64
bit_combine = |x, y, is_or| {
	var $a = x
	var $b = y
	var $bit = 1.I64
	var $out = 0.I64
	while $a > 0 or $b > 0 {
		abit = $a % 2
		bbit = $b % 2
		on = if is_or abit == 1 or bbit == 1 else abit == 1 and bbit == 1
		if on {
			$out = $out + $bit
		}
		$a = $a // 2
		$b = $b // 2
		$bit = $bit * 2
	}
	$out
}

## A C integer literal: decimal, hex or octal, with any suffix.
c_number : Str -> Try(I64, [NotNumber])
c_number = |text| {
	bytes = drop_last_while(text.to_utf8(), |c| c == 'L' or c == 'l' or c == 'U' or c == 'u')
	if bytes.starts_with(['0', 'x']) or bytes.starts_with(['0', 'X']) {
		Ok(bytes.drop_first(2).fold(0, |v, c| v * 16 + hex_digit(c)))
	} else if bytes.len() > 1 and bytes.get(0) == Ok('0') {
		Ok(bytes.drop_first(1).fold(0, |v, c| v * 8 + (c - '0').to_i64()))
	} else {
		I64.from_str(Str.from_utf8_lossy(bytes)).map_err(|_| NotNumber)
	}
}

hex_digit : U8 -> I64
hex_digit = |c|
	if c >= '0' and c <= '9' {
		(c - '0').to_i64()
	} else if c >= 'a' and c <= 'f' {
		(c - 'a').to_i64() + 10
	} else {
		(c - 'A').to_i64() + 10
	}

## `#define NAME value` lines, without macros that take arguments.
defines_of : Str -> List((Str, Str))
defines_of = |source|
	strip_comments(source).replace_each("\\\n", " ").split_on("\n").fold(
		[],
		|acc, line| {
			trimmed = line.trim().replace_each("\t", " ")
			if trimmed.starts_with("#define ") {
				rest = trimmed.drop_prefix("#define ").trim()
				name_bytes = take_while(rest.to_utf8(), |c| (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_')
				name = Str.from_utf8_lossy(name_bytes)
				after = Str.from_utf8_lossy(rest.to_utf8().drop_first(name_bytes.len()))
				if after.starts_with("(") or name.is_empty() or after.trim().is_empty() or after.trim().ends_with("\\") {
					acc
				} else {
					acc.append((name, after.trim()))
				}
			} else {
				acc
			}
		},
	)

## The values of every `enum { ... }` block.
enums_of : Str, Consts.Table -> List((Str, I64))
enums_of = |source, table| enum_blocks(source, table).fold([], |acc, block| acc.concat(block.values))

## Each `enum { ... }` block: the name it is known by, the typedef name
## after its closing brace or else its tag, and its values.
enum_blocks : Str, Consts.Table -> List({ name : Str, values : List((Str, I64)), unresolved : List(Str) })
enum_blocks = |source, table| {
	text = strip_comments(source)
	blocks = text.split_on("enum").drop_first(1)
	blocks.fold(
		[],
		|acc, block| {
			# `enum Name {` or `enum {`, and nothing else before the brace.
			head = block.split_first("{").map_ok(|s| s.before) ?? ";"
			if head.contains(";") or head.contains("(") or head.contains(")") or head.contains("=") {
				acc
			} else {
				rest = block.split_first("{").map_ok(|s| s.after) ?? ""
				body = rest.split_first("}").map_ok(|s| s.before) ?? ""
				after = ((rest.split_first("}").map_ok(|s| s.after) ?? "").split_first(";").map_ok(|s| s.before) ?? "").trim()
				name = if after.is_empty() head.trim() else after
				var $next = 0.I64
				var $values = []
				var $unresolved = []
				for item in body.split_on(",") {
					entry = item.trim()
					if !entry.is_empty() and !entry.starts_with("#") {
						entry_name = (entry.split_first("=").map_ok(|s| s.before) ?? entry).trim()
						value =
							match entry.split_first("=") {
								Ok({ after: value_text, .. }) =>
									match CParse.expression_text(value_text.trim()).map_ok(|expr| evaluate(table, expr, 0)) {
										Ok(Ok(Int(v))) => v
										_ => {
											$unresolved = $unresolved.append("${entry_name} = ${value_text.trim()}")
											$next
										}
									}
								Err(_) => $next
							}
						if entry_name.to_utf8().all(|c| (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_') {
							$values = $values.append((entry_name, value))
						}
						$next = value + 1
					}
				}
				acc.append({ name, values: $values, unresolved: $unresolved })
			}
		},
	)
}

## C comments removed.
strip_comments : Str -> Str
strip_comments = |source| {
	bytes = source.to_utf8()
	var $out = []
	var $i = 0
	while $i < bytes.len() {
		c = bytes.get($i) ?? 0
		if c == '/' and bytes.get($i + 1) == Ok('*') {
			var $j = $i + 2
			while $j + 1 < bytes.len() and !(bytes.get($j) == Ok('*') and bytes.get($j + 1) == Ok('/')) {
				$j = $j + 1
			}
			$i = $j + 2
		} else if c == '/' and bytes.get($i + 1) == Ok('/') {
			while $i < bytes.len() and bytes.get($i) != Ok('\n') {
				$i = $i + 1
			}
		} else {
			$out = $out.append(c)
			$i = $i + 1
		}
	}
	Str.from_utf8_lossy($out)
}

take_while : List(U8), (U8 -> Bool) -> List(U8)
take_while = |bytes, pred| {
	var $n = 0
	while $n < bytes.len() and pred(bytes.get($n) ?? 0) {
		$n = $n + 1
	}
	bytes.take_first($n)
}

drop_last_while : List(U8), (U8 -> Bool) -> List(U8)
drop_last_while = |bytes, pred| {
	var $n = bytes.len()
	while $n > 0 and pred(bytes.get($n - 1) ?? 0) {
		$n = $n - 1
	}
	bytes.take_first($n)
}
