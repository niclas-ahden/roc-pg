## Picks the function or operator a call means, from the candidates in
## [Builtins], the way the server does (`func_select_candidate` and
## `oper_select_candidate`, "Type Conversion" in Postgres's manual), and
## works out the type it returns.
##
## It only answers when it is sure. An argument whose type the analysis
## does not know could change the server's pick, so with one the answer
## stands only when every candidate that could apply returns the same type.
## When the rules leave more than one candidate, there is no answer either,
## as the server would refuse the call as ambiguous.
import Builtins
import Dump

Overload :: [].{
	## An argument as the resolution sees it: of a known type, of no type
	## yet (a string literal, NULL or a parameter, Postgres's `unknown`), or
	## of a type the analysis does not know.
	Arg : [Known(Str), Untyped, Unsure]

	## Why there is no pick. `NoSuchName` and `NoMatch` are certain: no
	## function or operator by that name exists, or none takes the arguments
	## (of known types) it is given, and the server refuses the call too.
	## `NoChoice` is not: the pick is ambiguous, or depends on a type the
	## analysis does not know.
	Miss : [NoSuchName, NoMatch, NoChoice]

	## The pick: the parameter types it takes, with polymorphic ones resolved
	## where the arguments tell (`""` where they do not), and what it
	## returns.
	Choice : {
		name : Str,
		params : List(Str),
		result : [Known(Str), Unknown],
		strict : Bool,
		kind : [Plain, Aggregate, Window],
		set : Bool,
		## The columns of a function with several output parameters.
		outputs : List({ name : Str, type : Str }),
	}

	## The function `name` called with `args`, from the built in ones and
	## `schema_functions`, those of the app's schema. `enums` are the
	## schema's enum types, for `anyenum`.
	function : Str, List(Overload.Arg), List(Str), List(Dump.Function) -> Try(Overload.Choice, Overload.Miss)
	function = |name, args, enums, schema_functions| Overload.function_from(name, args, enums, Bool.True, schema_functions)

	## [Overload.function], from the built in functions only when
	## `builtins`, as for a call that names no schema or `pg_catalog`.
	function_from : Str, List(Overload.Arg), List(Str), Bool, List(Dump.Function) -> Try(Overload.Choice, Overload.Miss)
	function_from = |name, args, enums, builtins, schema_functions| {
		arity = args.len()
		builtin = if builtins lines_named(Builtins.functions, name).keep_oks(builtin_declared) else []
		declared = builtin.concat(schema_functions.keep_if(|f| f.name == name).map(schema_declared))
		candidates = declared.keep_oks(|d| function_candidate(d, arity))
		args_known = args.map(|a| known_arg(a, enums))
		if declared.is_empty() {
			Err(NoSuchName)
		} else if candidates.is_empty() {
			Err(NoMatch)
		} else {
			choose(candidates, args_known, enums, [])
		}
	}

	## The operator `name` between `left` and `right`, or before `right`
	## when `left` is `Prefix`.
	operator : Str, [Prefix, Infix(Overload.Arg)], Overload.Arg, List(Str) -> Try(Overload.Choice, Overload.Miss)
	operator = |name, left, right, enums| {
		args =
			match left {
				Prefix => [right]
				Infix(l) => [l, right]
			}
		args_known = args.map(|a| known_arg(a, enums))
		candidates = lines_named(Builtins.operators, name).keep_oks(|fields| operator_candidate(name, fields, left == Prefix))
		# One side of no type is taken to be the other side's type, if a
		# candidate takes both as that.
		same_type =
			match args_known {
				[Known(t), Untyped] | [Untyped, Known(t)] => candidates.keep_if(|c| c.params == [t, t])
				_ => []
			}
		choose(candidates, args_known, enums, same_type)
	}

	## The type values of `args` share where they must be of one type, as in
	## the columns of a `union` or `values`, the results of a `case`, the
	## arguments of `coalesce`, `greatest` and `least` and the elements of an
	## `array[...]`. It is Postgres's `select_common_type`: one type when all
	## are of it, `text` when all are untyped literals, and otherwise the
	## first known type, moved on to a later one that it converts to
	## implicitly and not back, unless it is its category's preferred type.
	## Then every value must convert to it implicitly.
	##
	## `Mismatch(a, b)` when two are of different categories, which the
	## server refuses, `NoConversion(from, to)` when one does not convert, and
	## `Unsure` when a type is one this does not know, such as a domain.
	common : List(Overload.Arg), List(Str) -> Try(Str, [Mismatch(Str, Str), NoConversion(Str, Str), Unsure])
	common = |args, enums| {
		if args.any(|a| a == Unsure) {
			return Err(Unsure)
		}
		known = args.keep_oks(
			|a|
				match a {
					Known(t) => Ok(t)
					_ => Err(Untyped)
				},
		)
		first =
			match known.first() {
				Ok(t) => t
				Err(_) => return Ok("text")
			}
		if args.all(|a| a == Known(first)) {
			return Ok(first)
		}
		# A domain is taken as its base type, which this does not know.
		if known.any(|t| !is_builtin_type(t, enums)) {
			return Err(Unsure)
		}
		var $picked = first
		for next in known.drop_first(1) {
			if next != $picked {
				if Overload.category(next, enums) != Overload.category($picked, enums) {
					return Err(Mismatch($picked, next))
				}
				if !is_preferred($picked) and can_coerce($picked, next, enums) and !can_coerce(next, $picked, enums) {
					$picked = next
				}
			}
		}
		match known.find_first(|t| !can_coerce(t, $picked, enums)) {
			Ok(t) => Err(NoConversion(t, $picked))
			Err(_) => Ok($picked)
		}
	}

	## Whether a value of type `from` can be stored in a column of type `to`,
	## as in an insert or `set col = value`: the types an implicit or an
	## assignment cast leads to, and any string type, which takes the text of
	## any value. A type [Builtins] does not know is taken to fit.
	can_assign : Str, Str, List(Str) -> Bool
	can_assign = |from, to, enums|
		if from == to or !is_builtin_type(from, enums) or !is_builtin_type(to, enums) {
			Bool.True
		} else if from.ends_with("[]") and to.ends_with("[]") {
			Overload.can_assign(from.drop_suffix("[]"), to.drop_suffix("[]"), enums)
		} else if Overload.category(to, enums) == 'S' {
			Bool.True
		} else {
			can_coerce(from, to, enums) or has_line(Builtins.casts, [from, to])
		}

	## The category (`typcategory`) of a type: `A` for arrays, `E` for the
	## app's enums, `U` for a type [Builtins] does not know.
	category : Str, List(Str) -> U8
	category = |type, enums|
		if type.ends_with("[]") {
			'A'
		} else if enums.contains(type) {
			'E'
		} else {
			match type_field(type, 1) {
				Ok(cat) => cat.first() ?? 'U'
				Err(_) => 'U'
			}
		}
}

Candidate : { name : Str, params : List(Str), result : Str, strict : Bool, kind : [Plain, Aggregate, Window], set : Bool, outputs : List({ name : Str, type : Str }) }

## A known type that [Builtins] does not know, a domain say, could coerce
## in ways this cannot see, so it counts as unsure.
known_arg : Overload.Arg, List(Str) -> Overload.Arg
known_arg = |arg, enums|
	match arg {
		Known(t) =>
			if is_builtin_type(t, enums) {
				Known(t)
			} else {
				Unsure
			}
		other => other
	}

is_builtin_type : Str, List(Str) -> Bool
is_builtin_type = |type, enums|
	if type.ends_with("[]") {
		is_builtin_type(type.drop_suffix("[]"), enums)
	} else {
		enums.contains(type) or type_field(type, 0).is_ok()
	}

## A function as the catalogs declare it, before a call's arity picks how
## many arguments it takes.
Declared : { name : Str, args : List(Str), defaults : U64, variadic : Bool, result : Str, strict : Bool, kind : [Plain, Aggregate, Window], set : Bool, outputs : List({ name : Str, type : Str }) }

## A line of [Builtins.functions]. A `d` flag is followed by how many
## arguments have defaults.
builtin_declared : List(Str) -> Try(Declared, [NotAFunction])
builtin_declared = |fields|
	match fields {
		[name, arg_text, result, flags, output_text] => {
			defaults =
				match flags.split_on("d") {
					[_, count, ..] => U64.from_str(count) ?? 0
					_ => 0
				}
			kind = if flags.contains("a") Aggregate else if flags.contains("w") Window else Plain
			Ok({ name, args: arg_text.split_on(",").drop_if(|a| a == ""), defaults, variadic: flags.contains("v"), result, strict: flags.contains("s"), kind, set: flags.contains("r"), outputs: output_columns(output_text) })
		}
		_ => Err(NotAFunction)
	}

## A function of the app's schema. One with several output columns returns
## `record`.
schema_declared : Dump.Function -> Declared
schema_declared = |f| { name: f.name, args: f.args, defaults: f.defaults, variadic: f.variadic, result: f.result, strict: f.strict, kind: if f.aggregate Aggregate else Plain, set: f.set, outputs: f.outputs }

## The declared function as a candidate for a call with `arity` arguments.
## A variadic function takes one or more of its last parameter's element
## type, and trailing arguments that have defaults may be left out.
function_candidate : Declared, U64 -> Try(Candidate, [WrongArity])
function_candidate = |d, arity| {
	params : Try(List(Str), [WrongArity])
	params =
		if d.variadic {
			fixed = d.args.drop_last(1)
			element = variadic_element(d.args.last() ?? "any")
			if arity > fixed.len() {
				Ok(fixed.concat(List.repeat(element, arity - fixed.len())))
			} else {
				Err(WrongArity)
			}
		} else if arity <= d.args.len() and arity + d.defaults >= d.args.len() {
			Ok(d.args.take_first(arity))
		} else {
			Err(WrongArity)
		}
	params.map_ok(|p| { name: d.name, params: p, result: d.result, strict: d.strict, kind: d.kind, set: d.set, outputs: d.outputs })
}

## `name:type` pairs split by `;`.
output_columns : Str -> List({ name : Str, type : Str })
output_columns = |text|
	text.split_on(";").keep_oks(
		|pair|
			match pair.split_on(":") {
				[name, type] => Ok({ name, type })
				_ => Err(NotAColumn)
			},
	)

variadic_element : Str -> Str
variadic_element = |type|
	match type {
		"anyarray" => "anyelement"
		"anycompatiblearray" => "anycompatible"
		_ => type.drop_suffix("[]")
	}

operator_candidate : Str, List(Str), Bool -> Try(Candidate, [WrongArity])
operator_candidate = |name, fields, prefix|
	match fields {
		[_, left, right, result, flags] =>
			if prefix and left == "" {
				Ok({ name, params: [right], result, strict: flags.contains("s"), kind: Plain, set: Bool.False, outputs: [] })
			} else if !prefix and left != "" {
				Ok({ name, params: [left, right], result, strict: flags.contains("s"), kind: Plain, set: Bool.False, outputs: [] })
			} else {
				Err(WrongArity)
			}
		_ => Err(WrongArity)
	}

## The server's rules, in its order. `first` are the candidates to try
## before the others, the operator rule for one side of no type.
choose : List(Candidate), List(Overload.Arg), List(Str), List(Candidate) -> Try(Overload.Choice, Overload.Miss)
choose = |candidates, args, enums, first| {
	if args.any(|a| a == Unsure) {
		# The server knows that type, and might pick any of these.
		return agreed(candidates.keep_if(|c| coercible(c, args, enums)), args, enums)
	}
	exact = candidates.keep_if(|c| exact_matches(c, args) == args.len())
	if exact.len() == 1 {
		return pick(exact, args, enums)
	}
	if first.len() == 1 {
		return pick(first, args, enums)
	}
	# Only now ask the casts table about every candidate, which an exact
	# match, the common case, does not need.
	choose_viable(candidates.keep_if(|c| coercible(c, args, enums)), args, enums)
}

## The rest of [choose], once neither an exact match nor `first` decides.
choose_viable : List(Candidate), List(Overload.Arg), List(Str) -> Try(Overload.Choice, Overload.Miss)
choose_viable = |viable, args, enums| {
	if viable.is_empty() {
		# Every argument is of a known type or of none, and no candidate takes them.
		Err(NoMatch)
	} else if viable.len() == 1 {
		pick(viable, args, enums)
	} else {
		most_exact = keep_most(viable, |c| exact_matches(c, args))
		if most_exact.len() == 1 {
			pick(most_exact, args, enums)
		} else {
			most_preferred = keep_most(most_exact, |c| preferred_matches(c, args, enums))
			if most_preferred.len() == 1 or !args.any(|a| a == Untyped) {
				pick(most_preferred, args, enums)
			} else {
				by_category = untyped_categories(most_preferred, args, enums)
				if by_category.len() == 1 {
					pick(by_category, args, enums)
				} else {
					pick(assume_known_type(by_category, args, enums), args, enums)
				}
			}
		}
	}
}

## The one candidate left, or none.
pick : List(Candidate), List(Overload.Arg), List(Str) -> Try(Overload.Choice, Overload.Miss)
pick = |candidates, args, enums|
	match candidates {
		[only] => Ok(choice(only, args, enums))
		_ => Err(NoChoice)
	}

## An answer only when every candidate would give the same one.
agreed : List(Candidate), List(Overload.Arg), List(Str) -> Try(Overload.Choice, Overload.Miss)
agreed = |candidates, args, enums|
	match candidates.map(|c| choice(c, args, enums)) {
		[first, .. as rest] if rest.all(|c| c.result == first.result and c.strict == first.strict and c.kind == first.kind and c.set == first.set and c.outputs == first.outputs) => {
			# Which parameter types apply is not known.
			Ok({ ..first, params: first.params.map(|_| "") })
		}
		_ => Err(NoChoice)
	}

keep_most : List(Candidate), (Candidate -> U64) -> List(Candidate)
keep_most = |candidates, score| {
	scored = candidates.map(|c| (c, score(c)))
	best = scored.fold(0, |acc, (_, s)| if s > acc s else acc)
	scored.keep_if(|(_, s)| s == best).map(|(c, _)| c)
}

## How many arguments are exactly of their parameter's type.
exact_matches : Candidate, List(Overload.Arg) -> U64
exact_matches = |candidate, args|
	pairs(candidate, args).count_if(
		|(param, arg)|
			match arg {
				Known(t) => t == param
				_ => Bool.False
			},
	)

## How many arguments that need a coercion get a preferred type of their
## own category.
preferred_matches : Candidate, List(Overload.Arg), List(Str) -> U64
preferred_matches = |candidate, args, enums|
	pairs(candidate, args).count_if(
		|(param, arg)|
			match arg {
				Known(t) if t != param => is_preferred(param) and Overload.category(param, enums) == Overload.category(t, enums)
				_ => Bool.False
			},
	)

## At each argument of no type: the string category when a candidate takes
## one there, else the one category all take, keeping the candidates that
## take it, and only those taking its preferred type when one does.
untyped_categories : List(Candidate), List(Overload.Arg), List(Str) -> List(Candidate)
untyped_categories = |candidates, args, enums| {
	var $left = candidates
	var $i = 0
	for arg in args {
		if arg == Untyped {
			at = |c| c.params.get($i) ?? ""
			cats = $left.map(|c| Overload.category(at(c), enums))
			chosen =
				if cats.contains('S') {
					Ok('S')
				} else {
					match cats.first() {
						Ok(first) if cats.all(|c| c == first) => Ok(first)
						_ => Err(Ambiguous)
					}
				}
			match chosen {
				Ok(cat) => {
					in_cat = $left.keep_if(|c| Overload.category(at(c), enums) == cat)
					preferred = in_cat.keep_if(|c| is_preferred(at(c)))
					$left = if preferred.is_empty() in_cat else preferred
				}
				Err(_) => {
					return []
				}
			}
		}
		$i = $i + 1
	}
	$left
}

## When every argument of a known type has the same type, take the ones of
## no type to be of it too.
assume_known_type : List(Candidate), List(Overload.Arg), List(Str) -> List(Candidate)
assume_known_type = |candidates, args, enums| {
	known = args.keep_oks(
		|a|
			match a {
				Known(t) => Ok(t)
				_ => Err(NotKnown)
			},
	)
	match known {
		[first, ..] if known.all(|t| t == first) =>
			candidates.keep_if(
				|c|
					pairs(c, args).all(
						|(param, arg)|
							match arg {
								Untyped => can_coerce(first, param, enums)
								_ => Bool.True
							},
					),
			)
		_ => []
	}
}

pairs : Candidate, List(Overload.Arg) -> List((Str, Overload.Arg))
pairs = |candidate, args| List.map2(candidate.params, args, |p, a| (p, a))

## Whether every argument can become its parameter's type implicitly.
coercible : Candidate, List(Overload.Arg), List(Str) -> Bool
coercible = |candidate, args, enums|
	pairs(candidate, args).all(
		|(param, arg)|
			match arg {
				Known(t) => can_coerce(t, param, enums)
				Untyped | Unsure => !["record", "void"].contains(param)
			},
	)
	and polymorphic_consistent(candidate, args)

## Whether a value of type `from` can be passed where `to` is taken without
## a cast.
can_coerce : Str, Str, List(Str) -> Bool
can_coerce = |from, to, enums|
	if from == to or to == "any" {
		Bool.True
	} else {
		match to {
			"anyelement" | "anycompatible" => Bool.True
			"anynonarray" | "anycompatiblenonarray" => !from.ends_with("[]")
			"anyarray" | "anycompatiblearray" => from.ends_with("[]")
			"anyenum" => enums.contains(from)
			"anyrange" | "anycompatiblerange" => Overload.category(from, enums) == 'R'
			"anymultirange" | "anycompatiblemultirange" => from.ends_with("multirange")
			_ =>
				if from.ends_with("[]") and to.ends_with("[]") {
					can_coerce(from.drop_suffix("[]"), to.drop_suffix("[]"), enums)
				} else {
					has_line(Builtins.casts, [from, to, "i"])
				}
		}
	}

## Whether the arguments of the `anyelement` family agree on one element
## type, as the server requires.
polymorphic_consistent : Candidate, List(Overload.Arg) -> Bool
polymorphic_consistent = |candidate, args| {
	bound = element_bindings(candidate, args, ["anyelement", "anynonarray", "anyenum"], ["anyarray"])
	match bound {
		[first, ..] => bound.all(|t| t == first)
		[] => Bool.True
	}
}

## The element types the arguments give the polymorphic parameters.
element_bindings : Candidate, List(Overload.Arg), List(Str), List(Str) -> List(Str)
element_bindings = |candidate, args, element_params, array_params|
	pairs(candidate, args).keep_oks(
		|(param, arg)|
			match arg {
				Known(t) if element_params.contains(param) => Ok(t)
				Known(t) if array_params.contains(param) and t.ends_with("[]") => Ok(t.drop_suffix("[]"))
				_ => Err(Unbound)
			},
	)

## The candidate as a choice, with polymorphic types resolved from the
## arguments where they can be.
choice : Candidate, List(Overload.Arg), List(Str) -> Overload.Choice
choice = |candidate, args, _enums| {
	element = one_binding(element_bindings(candidate, args, ["anyelement", "anynonarray", "anyenum"], ["anyarray"]))
	compatible = one_binding(element_bindings(candidate, args, ["anycompatible", "anycompatiblenonarray"], ["anycompatiblearray"]))
	resolve = |type|
		match type {
			"anyelement" | "anynonarray" | "anyenum" => element
			"anyarray" => element.map_ok(|t| "${t}[]")
			"anycompatible" | "anycompatiblenonarray" => compatible
			"anycompatiblearray" => compatible.map_ok(|t| "${t}[]")
			"any" | "record" | "void" | "anyrange" | "anymultirange" | "anycompatiblerange" | "anycompatiblemultirange" | "unknown" => Err(Unbound)
			concrete => Ok(concrete)
		}
	result =
		match resolve(candidate.result) {
			Ok(t) => Known(t)
			Err(_) => Unknown
		}
	{
		name: candidate.name,
		params: candidate.params.map(|p| resolve(p) ?? ""),
		result,
		strict: candidate.strict,
		kind: candidate.kind,
		set: candidate.set,
		outputs: candidate.outputs,
	}
}

one_binding : List(Str) -> Try(Str, [Unbound])
one_binding = |bound|
	match bound {
		[first, ..] if bound.all(|t| t == first) => Ok(first)
		_ => Err(Unbound)
	}

is_preferred : Str -> Bool
is_preferred = |type| type_field(type, 2) == Ok(['p'])

## The lines of `table` whose first field is `name`, split into fields.
lines_named : List(U8), Str -> List(List(Str))
lines_named = |table, name| {
	key = name.to_utf8()
	var $out = []
	var $at = first_line(table, key)
	while $at < table.len() and compare_key(table, $at, key) == Same {
		end = next_line(table, $at)
		line = table.sublist({ start: $at, len: end - $at - 1 })
		$out = $out.append(Str.split_on(Str.from_utf8_lossy(line), "\t"))
		$at = end
	}
	$out
}

## The start of the first line of `table` whose first field is `key`, or
## where it would be. The lines are sorted by their first field, so this is
## a binary search.
first_line : List(U8), List(U8) -> U64
first_line = |table, key| {
	var $lo = 0
	var $hi = table.len()
	while $lo < $hi {
		start = line_start(table, ($lo + $hi) // 2)
		if compare_key(table, start, key) == Before {
			$lo = next_line(table, start)
		} else {
			$hi = start
		}
	}
	$lo
}

## Whether `table` has a line whose first fields are `fields`, each one
## matched whole. Unlike [lines_named] it splits no line, so a lookup costs
## no allocation. Choosing an operator asks this for every candidate, and
## splitting the lines made that most of the time a query took to check.
has_line : List(U8), List(Str) -> Bool
has_line = |table, fields| {
	key = (fields.first() ?? "").to_utf8()
	wanted = Str.join_with(fields, "\t").to_utf8()
	var $at = first_line(table, key)
	while $at < table.len() and compare_key(table, $at, key) == Same {
		if starts_with_fields(table, $at, wanted) {
			return Bool.True
		}
		$at = next_line(table, $at)
	}
	Bool.False
}

## Whether the line at `start` begins with the fields in `wanted`, so that
## a field ends right after them.
starts_with_fields : List(U8), U64, List(U8) -> Bool
starts_with_fields = |table, start, wanted| {
	var $i = 0
	while $i < wanted.len() {
		if table.get(start + $i) != wanted.get($i) {
			return Bool.False
		}
		$i = $i + 1
	}
	match table.get(start + wanted.len()) {
		Ok(b) => b == '\t' or b == '\n'
		Err(_) => Bool.True
	}
}

## Field `n` of the line of `type` in [Builtins.types], read in place.
type_field : Str, U64 -> Try(List(U8), [NotFound])
type_field = |type, n| {
	table = Builtins.types
	key = type.to_utf8()
	start = first_line(table, key)
	if start >= table.len() or compare_key(table, start, key) != Same {
		return Err(NotFound)
	}
	end = next_line(table, start)
	var $from = start
	var $field = 0
	var $at = start
	# Past the end of the table counts as the end of the line, so the last
	# field of a last line without a newline ends too.
	while $at < end {
		b = table.get($at) ?? '\n'
		if b == '\t' or b == '\n' {
			if $field == n {
				return Ok(table.sublist({ start: $from, len: $at - $from }))
			}
			$field = $field + 1
			$from = $at + 1
		}
		$at = $at + 1
	}
	Err(NotFound)
}

## The start of the line holding byte `i`.
line_start : List(U8), U64 -> U64
line_start = |table, i| {
	var $at = i
	while $at > 0 and table.get($at - 1) != Ok('\n') {
		$at = $at - 1
	}
	$at
}

## The start of the line after the one starting at `start`.
next_line : List(U8), U64 -> U64
next_line = |table, start| {
	var $at = start
	while $at < table.len() and table.get($at) != Ok('\n') {
		$at = $at + 1
	}
	$at + 1
}

## How the first field of the line at `start` sorts against `key`.
compare_key : List(U8), U64, List(U8) -> [Before, Same, After]
compare_key = |table, start, key| {
	var $i = 0
	while Bool.True {
		b = table.get(start + $i) ?? '\t'
		field_ended = b == '\t' or b == '\n'
		key_ended = $i >= key.len()
		if field_ended and key_ended {
			return Same
		} else if field_ended {
			return Before
		} else if key_ended {
			return After
		} else {
			k = key.get($i) ?? 0
			if b < k {
				return Before
			} else if b > k {
				return After
			}
		}
		$i = $i + 1
	}
}

enums = ["access_level"]

type_of : Try(Overload.Choice, Overload.Miss) -> Str
type_of = |found|
	match found {
		Ok({ result: Known(t), .. }) => t
		Ok(_) => "unknown"
		Err(_) => "none"
	}

expect type_of(Overload.function("sum", [Known("integer")], enums, [])) == "bigint"
expect type_of(Overload.function("sum", [Known("numeric")], enums, [])) == "numeric"
expect type_of(Overload.function("avg", [Known("integer")], enums, [])) == "numeric"
expect type_of(Overload.function("count", [], enums, [])) == "bigint"
expect type_of(Overload.function("lower", [Known("text")], enums, [])) == "text"
expect type_of(Overload.function("lower", [Known("character varying")], enums, [])) == "text"
expect type_of(Overload.function("lower", [Untyped], enums, [])) == "text"
expect type_of(Overload.function("lower", [Unsure], enums, [])) == "none"
expect type_of(Overload.function("length", [Known("text")], enums, [])) == "integer"
expect type_of(Overload.function("now", [], enums, [])) == "timestamp with time zone"
expect type_of(Overload.function("array_agg", [Known("integer")], enums, [])) == "integer[]"
expect type_of(Overload.function("unnest", [Known("text[]")], enums, [])) == "text"
expect type_of(Overload.function("max", [Known("access_level")], enums, [])) == "access_level"
expect type_of(Overload.function("concat", [Known("text"), Known("integer")], enums, [])) == "text"
expect type_of(Overload.function("extract", [Untyped, Known("timestamp with time zone")], enums, [])) == "numeric"
expect type_of(Overload.function("round", [Known("numeric"), Known("integer")], enums, [])) == "numeric"
expect type_of(Overload.function("round", [Known("double precision")], enums, [])) == "double precision"
expect type_of(Overload.function("generate_series", [Known("integer"), Known("integer")], enums, [])) == "integer"
expect type_of(Overload.function("no_such_function", [], enums, [])) == "none"
expect type_of(Overload.operator("+", Infix(Known("integer")), Known("integer"), enums)) == "integer"
expect type_of(Overload.operator("+", Infix(Known("integer")), Known("bigint"), enums)) == "bigint"
expect type_of(Overload.operator("*", Infix(Known("integer")), Known("numeric"), enums)) == "numeric"
expect type_of(Overload.operator("+", Infix(Untyped), Known("integer"), enums)) == "integer"
expect type_of(Overload.operator("-", Prefix, Known("integer"), enums)) == "integer"
expect type_of(Overload.operator("||", Infix(Known("text")), Untyped, enums)) == "text"
expect type_of(Overload.operator("||", Infix(Known("text")), Known("integer"), enums)) == "text"
expect type_of(Overload.operator("->>", Infix(Known("jsonb")), Untyped, enums)) == "text"
expect type_of(Overload.operator("->", Infix(Known("jsonb")), Known("integer"), enums)) == "jsonb"
expect type_of(Overload.operator("-", Infix(Known("timestamp with time zone")), Known("interval"), enums)) == "timestamp with time zone"
expect type_of(Overload.operator("-", Infix(Known("date")), Known("date"), enums)) == "integer"
expect Overload.category("integer", enums) == 'N'
expect Overload.category("text[]", enums) == 'A'
expect Overload.category("access_level", enums) == 'E'
expect Overload.can_assign("numeric", "integer", enums)
expect Overload.can_assign("integer", "text", enums)
expect Overload.can_assign("access_level", "text", enums)
expect !Overload.can_assign("text", "integer", enums)
expect !Overload.can_assign("text", "access_level", enums)
expect !Overload.can_assign("boolean", "integer", enums)
expect Overload.can_assign("integer[]", "bigint[]", enums)
expect Overload.can_assign("citext", "integer", enums)

# select_common_type: the first type, moved on to one it converts to.
expect Overload.common([Known("integer"), Known("integer")], enums) == Ok("integer")
expect Overload.common([Known("integer"), Known("bigint")], enums) == Ok("bigint")
expect Overload.common([Known("bigint"), Known("integer")], enums) == Ok("bigint")
expect Overload.common([Known("integer"), Known("numeric"), Known("bigint")], enums) == Ok("numeric")
expect Overload.common([Known("integer"), Known("double precision"), Known("numeric")], enums) == Ok("double precision")
expect Overload.common([Untyped, Known("integer")], enums) == Ok("integer")
expect Overload.common([Untyped, Untyped], enums) == Ok("text")
expect Overload.common([Known("character varying"), Known("text")], enums) == Ok("character varying")
expect Overload.common([Known("text"), Known("character varying")], enums) == Ok("text")
expect Overload.common([Known("integer"), Known("boolean")], enums) == Err(Mismatch("integer", "boolean"))
expect Overload.common([Known("integer"), Known("text")], enums) == Err(Mismatch("integer", "text"))
expect Overload.common([Known("integer"), Unsure], enums) == Err(Unsure)
expect Overload.common([Known("some_domain"), Known("integer")], enums) == Err(Unsure)
expect Overload.common([Known("timestamp without time zone"), Known("timestamp with time zone")], enums) == Ok("timestamp with time zone")
