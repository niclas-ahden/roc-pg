## An exact decimal number of any size, as Postgres's `numeric` holds it.
##
## Use [Dec] for most decimal numbers: it is a fixed size, fast, and holds
## 18 digits after the point and about 20 before it, which a sum of money
## or a measurement rarely outgrows. Use `Numeric` only for a value that
## needs more, such as one with more decimal places than 18, or one too
## large for a `Dec`. A `numeric` column decodes into either, and into a
## `Dec` with its digits past the 18th rounded off.
##
## A `Numeric` keeps its scale, the number of digits after its point, as
## Postgres does: `1.50` has a scale of 2 and prints as `1.50`. Two numbers
## of different scales are equal when their values are. `plus`, `minus`
## and `times` are exact, and `div_by` gives the digits Postgres's `/`
## gives (see [Numeric.div_by]). So `a + b` reads as on the server.
##
## ```
## total = Numeric.from_str("0.1234567890123456789")? + Numeric.from_str("1")?
## expect total.to_str() == "1.1234567890123456789"
## ```
Numeric :: { negative : Bool, digits : List(U8), scale : U64 }.{
	## A literal of type `Numeric`, as in `price : Numeric` and
	## `price = 19.99`. The compiler calls this.
	from_numeral : Numeral -> Try(Numeric, [InvalidNumeral(Str)])
	from_numeral = |numeral| {
		whole = from_base256(numeral.digits_before_pt())
		fraction = from_base256(numeral.digits_after_pt())
		count = numeral.digits_after_pt_count()
		padded = List.repeat(0, count - fraction.len().min(count)).concat(fraction)
		Ok(normal(numeral.is_negative(), whole.concat(padded), count))
	}

	## Read a number such as `-12.50`, `0.000001` or `1.5e3`, which is
	## `1500`. Fails on anything else, `NaN` and the infinities included.
	from_str : Str -> Try(Numeric, [BadNumStr])
	from_str = |text| {
		negative = text.starts_with("-")
		unsigned = text.drop_prefix("-").drop_prefix("+")
		{ before: mantissa, after: exponent_text } = unsigned.split_first("e") ?? (unsigned.split_first("E") ?? { before: unsigned, after: "0" })
		exponent = I64.from_str(exponent_text) ? |_| BadNumStr
		{ before, after } = mantissa.split_first(".") ?? { before: mantissa, after: "" }
		whole = decimal_digits(before)?
		fraction = decimal_digits(after)?
		if whole.is_empty() and fraction.is_empty() {
			return Err(BadNumStr)
		}
		all = whole.concat(fraction)
		scale = fraction.len().to_i64_wrap() - exponent
		if scale >= 0 {
			Ok(normal(negative, all, scale.to_u64_wrap()))
		} else {
			Ok(normal(negative, all.concat(List.repeat(0, (-scale).to_u64_wrap())), 0))
		}
	}

	## The number as Postgres writes it: an optional `-`, digits, and as many
	## digits after the point as its scale.
	to_str : Numeric -> Str
	to_str = |n| {
		padded = List.repeat(0, (n.scale + 1) - n.digits.len().min(n.scale + 1)).concat(n.digits)
		split = padded.len() - n.scale
		whole = text_of(padded.take_first(split))
		sign = if n.negative "-" else ""
		if n.scale == 0 {
			"${sign}${whole}"
		} else {
			"${sign}${whole}.${text_of(padded.drop_first(split))}"
		}
	}

	from_i128 : I128 -> Numeric
	from_i128 = |n| Numeric.from_str(n.to_str()) ?? Numeric.{ negative: Bool.False, digits: [], scale: 0 }

	from_dec : Dec -> Numeric
	from_dec = |d| Numeric.from_str(d.to_str()) ?? Numeric.{ negative: Bool.False, digits: [], scale: 0 }

	## The number as a [Dec], its digits past the 18th after the point
	## rounded off, half away from zero. Fails when it is too large.
	to_dec : Numeric -> Try(Dec, [OutOfRange])
	to_dec = |n| {
		rounded = if n.scale > 18 round_to(n, 18) else n
		padded = List.repeat(0, (rounded.scale + 1) - rounded.digits.len().min(rounded.scale + 1)).concat(rounded.digits)
		split = padded.len() - rounded.scale
		value = Dec.from_dec_digits((padded.take_first(split), padded.drop_first(split))) ? |_| OutOfRange
		Ok(if rounded.negative -value else value)
	}

	## The number of digits after the point.
	scale : Numeric -> U64
	scale = |n| n.scale

	is_zero : Numeric -> Bool
	is_zero = |n| n.digits.is_empty()

	is_negative : Numeric -> Bool
	is_negative = |n| n.negative

	negate : Numeric -> Numeric
	negate = |n| if n.digits.is_empty() n else { ..n, negative: !n.negative }

	abs : Numeric -> Numeric
	abs = |n| { ..n, negative: Bool.False }

	## Whether two numbers have the same value, whatever their scales.
	is_eq : Numeric, Numeric -> Bool
	is_eq = |a, b| Numeric.order_relative_to(a, b) == Same

	order_relative_to : Numeric, Numeric -> [Before, Same, After]
	order_relative_to = |a, b|
		match (a.negative, b.negative) {
			(Bool.True, Bool.False) => Before
			(Bool.False, Bool.True) => After
			(both, _) => {
				common = a.scale.max(b.scale)
				magnitude = compare(scaled(a, common), scaled(b, common))
				if !both {
					magnitude
				} else {
					match magnitude {
						Before => After
						After => Before
						Same => Same
					}
				}
			}
		}

	is_lt : Numeric, Numeric -> Bool
	is_lt = |a, b| Numeric.order_relative_to(a, b) == Before

	is_lte : Numeric, Numeric -> Bool
	is_lte = |a, b| Numeric.order_relative_to(a, b) != After

	is_gt : Numeric, Numeric -> Bool
	is_gt = |a, b| Numeric.order_relative_to(a, b) == After

	is_gte : Numeric, Numeric -> Bool
	is_gte = |a, b| Numeric.order_relative_to(a, b) != Before

	## The exact sum, of the larger of the two scales.
	plus : Numeric, Numeric -> Numeric
	plus = |a, b| {
		common = a.scale.max(b.scale)
		x = scaled(a, common)
		y = scaled(b, common)
		if a.negative == b.negative {
			normal(a.negative, add(x, y), common)
		} else {
			match compare(x, y) {
				Before => normal(b.negative, subtract(y, x), common)
				_ => normal(a.negative, subtract(x, y), common)
			}
		}
	}

	## The exact difference, of the larger of the two scales.
	minus : Numeric, Numeric -> Numeric
	minus = |a, b| Numeric.plus(a, Numeric.negate(b))

	## The exact product, whose scale is the sum of the two.
	times : Numeric, Numeric -> Numeric
	times = |a, b| normal(a.negative != b.negative, multiply(a.digits, b.digits), a.scale + b.scale)

	## `a / b` as Postgres's `/` gives it: to as many digits after the point
	## as give at least 16 significant digits, and no fewer than either
	## number has, rounded half away from zero (`select_div_scale` in
	## `numeric.c`). `1 / 3` is `0.33333333333333333333`.
	div_by : Numeric, Numeric -> Try(Numeric, [DivByZero])
	div_by = |a, b| {
		if b.digits.is_empty() {
			return Err(DivByZero)
		}
		places = division_scale(a, b)
		# a / b at `places` digits, and one more to round on.
		numerator = a.digits.concat(List.repeat(0, b.scale + places + 1))
		denominator = b.digits.concat(List.repeat(0, a.scale))
		quotient = divide(numerator, denominator)
		last = quotient.last() ?? 0
		truncated = quotient.drop_last(1)
		rounded = if last >= 5 add(truncated, [1]) else truncated
		Ok(normal(a.negative != b.negative, rounded, places))
	}

	## Round to `places` digits after the point, half away from zero.
	round : Numeric, U64 -> Numeric
	round = |n, places| if places >= n.scale scaled_up(n, places) else round_to(n, places)

	parser_for : format -> (state -> Try({ value : Numeric, rest : state }, err))
		where [format.parse_numeric : format, state -> Try({ value : Numeric, rest : state }, err)]
	parser_for = |format| |state| format.parse_numeric(state)

	encoder_for : format -> (Numeric, state -> Try(state, err))
		where [format.encode_numeric : format, Numeric, state -> Try(state, err)]
	encoder_for = |format| |value, state| format.encode_numeric(value, state)
}

## `digits` without leading zeros, and a zero that is not negative.
normal : Bool, List(U8), U64 -> Numeric
normal = |negative, digits, scale| {
	trimmed = digits.drop_first(digits.find_first_index(|d| d != 0) ?? digits.len())
	Numeric.{ negative: negative and !trimmed.is_empty(), digits: trimmed, scale }
}

## The digits of `n` with zeros added to reach `scale` digits after the
## point, which must be at least its own.
scaled : Numeric, U64 -> List(U8)
scaled = |n, scale| if n.digits.is_empty() [] else n.digits.concat(List.repeat(0, scale - n.scale))

scaled_up : Numeric, U64 -> Numeric
scaled_up = |n, scale| { ..n, digits: scaled(n, scale), scale }

## `n` rounded to `places` digits after the point, fewer than it has.
round_to : Numeric, U64 -> Numeric
round_to = |n, places| {
	dropped = n.scale - places
	padded = List.repeat(0, (dropped + 1) - n.digits.len().min(dropped + 1)).concat(n.digits)
	kept = padded.drop_last(dropped)
	next = padded.get(kept.len()) ?? 0
	normal(n.negative, if next >= 5 add(kept, [1]) else kept, places)
}

## The scale Postgres gives `a / b`: `select_div_scale`, which reads the
## numbers in base 10000, as `numeric` stores them.
division_scale : Numeric, Numeric -> U64
division_scale = |a, b| {
	(weight_a, first_a) = leading(a)
	(weight_b, first_b) = leading(b)
	quotient_weight = if first_a <= first_b weight_a - weight_b - 1 else weight_a - weight_b
	wanted = 16 - quotient_weight * 4
	at_least = [wanted, a.scale.to_i64_wrap(), b.scale.to_i64_wrap(), 0].fold(0, |acc, s| if s > acc s else acc)
	(if at_least > 1000 1000 else at_least).to_u64_wrap()
}

## The base 10000 weight of a number's first nonzero digit group, and that
## group's value: `(0, 0)` for zero.
leading : Numeric -> (I64, U64)
leading = |n|
	if n.digits.is_empty() {
		(0, 0)
	} else {
		# The power of ten of the first digit, and of the group it is in.
		exponent = n.digits.len().to_i64_wrap() - 1 - n.scale.to_i64_wrap()
		weight = if exponent >= 0 exponent // 4 else -((-exponent + 3) // 4)
		in_group = (exponent - weight * 4).to_u64_wrap() + 1
		# Digits past the last one are zeros: 0.001 is the group 0010.
		digits = n.digits.take_first(in_group).concat(List.repeat(0, in_group - n.digits.len().min(in_group)))
		group = digits.fold(0, |acc, d| acc * 10 + d.to_u64())
		(weight, group)
	}

compare : List(U8), List(U8) -> [Before, Same, After]
compare = |a, b|
	if a.len() != b.len() {
		if a.len() < b.len() Before else After
	} else {
		List.map2(a, b, |x, y| (x, y)).fold(
			Same,
			|acc, (x, y)|
				if acc != Same {
					acc
				} else if x < y {
					Before
				} else if x > y {
					After
				} else {
					Same
				},
		)
	}

add : List(U8), List(U8) -> List(U8)
add = |a, b| {
	var $out = []
	var $carry = 0.U8
	var $i = 0
	while $i < a.len() or $i < b.len() or $carry > 0 {
		x = if $i < a.len() a.get(a.len() - 1 - $i) ?? 0 else 0
		y = if $i < b.len() b.get(b.len() - 1 - $i) ?? 0 else 0
		sum = x + y + $carry
		$out = $out.append(sum % 10)
		$carry = sum // 10
		$i = $i + 1
	}
	reversed($out)
}

## `a - b`, where `a` is at least `b`.
subtract : List(U8), List(U8) -> List(U8)
subtract = |a, b| {
	var $out = []
	var $borrow = 0.U8
	var $i = 0
	while $i < a.len() {
		x = a.get(a.len() - 1 - $i) ?? 0
		y = (if $i < b.len() b.get(b.len() - 1 - $i) ?? 0 else 0) + $borrow
		if x >= y {
			$out = $out.append(x - y)
			$borrow = 0
		} else {
			$out = $out.append(x + 10 - y)
			$borrow = 1
		}
		$i = $i + 1
	}
	strip(reversed($out))
}

multiply : List(U8), List(U8) -> List(U8)
multiply = |a, b| {
	if a.is_empty() or b.is_empty() {
		return []
	}
	var $sums = List.repeat(0.U64, a.len() + b.len())
	var $i = 0
	while $i < a.len() {
		x = (a.get(a.len() - 1 - $i) ?? 0).to_u64()
		var $j = 0
		while $j < b.len() {
			y = (b.get(b.len() - 1 - $j) ?? 0).to_u64()
			$sums = $sums.update($i + $j, |s| s + x * y) ?? $sums
			$j = $j + 1
		}
		$i = $i + 1
	}
	var $out = []
	var $carry = 0.U64
	for s in $sums {
		total = s + $carry
		$out = $out.append((total % 10).to_u8_wrap())
		$carry = total // 10
	}
	while $carry > 0 {
		$out = $out.append(($carry % 10).to_u8_wrap())
		$carry = $carry // 10
	}
	strip(reversed($out))
}

## `a // b` by long division, `b` not zero.
divide : List(U8), List(U8) -> List(U8)
divide = |a, b| {
	var $out = []
	var $rest = []
	for digit in a {
		$rest = strip($rest.append(digit))
		var $q = 0.U8
		while compare($rest, b) != Before {
			$rest = subtract($rest, b)
			$q = $q + 1
		}
		$out = $out.append($q)
	}
	strip($out)
}

reversed : List(U8) -> List(U8)
reversed = |list| {
	var $out = []
	var $i = list.len()
	while $i > 0 {
		$i = $i - 1
		$out = $out.append(list.get($i) ?? 0)
	}
	$out
}

strip : List(U8) -> List(U8)
strip = |digits| digits.drop_first(digits.find_first_index(|d| d != 0) ?? digits.len())

## The decimal digits of a number given in base 256, most significant
## first.
from_base256 : List(U8) -> List(U8)
from_base256 = |bytes| {
	var $number = strip(bytes)
	var $out = []
	while !$number.is_empty() {
		var $quotient = []
		var $remainder = 0.U64
		for byte in $number {
			current = $remainder * 256 + byte.to_u64()
			$quotient = $quotient.append((current // 10).to_u8_wrap())
			$remainder = current % 10
		}
		$out = $out.append($remainder.to_u8_wrap())
		$number = strip($quotient)
	}
	reversed($out)
}

decimal_digits : Str -> Try(List(U8), [BadNumStr])
decimal_digits = |text| {
	var $out = []
	for byte in text.to_utf8() {
		if byte < '0' or byte > '9' {
			return Err(BadNumStr)
		}
		$out = $out.append(byte - '0')
	}
	Ok($out)
}

text_of : List(U8) -> Str
text_of = |digits| Str.from_utf8_lossy(digits.map(|d| d + '0'))

n : Str -> Numeric
n = |text| Numeric.from_str(text) ?? crash "not a number: ${text}"

expect n("12.50").to_str() == "12.50"
expect n("-0.05").to_str() == "-0.05"
expect n("0").to_str() == "0"
expect n("-0.00").to_str() == "0.00"
expect n("1.5e3").to_str() == "1500"
expect n("1.25e-3").to_str() == "0.00125"
expect Numeric.from_str("NaN") == Err(BadNumStr)
expect Numeric.from_str("1.2.3") == Err(BadNumStr)
expect Numeric.from_str(".") == Err(BadNumStr)
expect n(".5").to_str() == "0.5"
expect n("1.50") == n("1.5")
expect n("-2") < n("1") and n("1.01") > n("1.009") and n("-1.5") < n("-1.4")
expect (n("0.1234567890123456789") + n("1")).to_str() == "1.1234567890123456789"
expect (n("1.5") - n("2.25")).to_str() == "-0.75"
expect (n("-1.5") + n("1.5")).to_str() == "0.0"
expect (n("99999999999999999999999") + n("1")).to_str() == "100000000000000000000000"
expect (n("1.5") * n("-0.20")).to_str() == "-0.300"
expect (n("123456789012345678901234567890") * n("10")).to_str() == "1234567890123456789012345678900"

# Division gives the digits Postgres gives.
expect n("1").div_by(n("3")).map_ok(|q| q.to_str()) == Ok("0.33333333333333333333")
expect n("2").div_by(n("3")).map_ok(|q| q.to_str()) == Ok("0.66666666666666666667")
expect n("10").div_by(n("4")).map_ok(|q| q.to_str()) == Ok("2.5000000000000000")
expect n("1").div_by(n("8")).map_ok(|q| q.to_str()) == Ok("0.12500000000000000000")
expect n("100000").div_by(n("3")).map_ok(|q| q.to_str()) == Ok("33333.333333333333")
expect n("1.000").div_by(n("3")).map_ok(|q| q.to_str()) == Ok("0.33333333333333333333")
expect n("-7").div_by(n("2")).map_ok(|q| q.to_str()) == Ok("-3.5000000000000000")
expect n("1").div_by(n("0")) == Err(DivByZero)
expect n("12345678901234567890").div_by(n("0.001")).map_ok(|q| q.to_str()) == Ok("12345678901234567890000.000")

expect n("1.005").round(2).to_str() == "1.01"
expect n("-1.005").round(2).to_str() == "-1.01"
expect n("1.5").round(3).to_str() == "1.500"
expect n("0.1234567890123456789").to_dec() == Ok(0.123456789012345679)
expect n("-2.5").to_dec() == Ok(-2.5)
expect n("999999999999999999999999").to_dec() == Err(OutOfRange)
expect Numeric.from_i128(-42).to_str() == "-42"
expect Numeric.from_dec(1.25).to_str() == "1.25"
expect {
	price : Numeric
	price = 19.990
	price.to_str() == "19.990"
}
expect {
	tiny : Numeric
	tiny = -0.000000000000000000001
	tiny.to_str() == "-0.000000000000000000001"
}
