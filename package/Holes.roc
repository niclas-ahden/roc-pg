## The SQL of an interpolated query as the checker reads it. The checker
## takes `$name` placeholders, so each interpolation becomes one, named
## after its position.
Holes :: [].{
	## The placeholder of the interpolation at `index`, counted from 0.
	name : U64 -> Str
	name = |index| "interpolation${(index + 1).to_str()}"

	## The placeholders of the interpolations between `segments`.
	names : List(Str) -> List(Str)
	names = |segments| segments.drop_first(1).map_with_index(|_, index| Holes.name(index))

	## The SQL with a placeholder in each interpolation. A space keeps the
	## placeholder's name from running into a word right after it.
	sql : List(Str) -> Str
	sql = |segments|
		segments.drop_first(1).fold_with_index(
			segments.first() ?? "",
			|acc, segment, index| {
				gap = if starts_with_word(segment) " " else ""
				"${acc}$${Holes.name(index)}${gap}${segment}"
			},
		)

	## The checker names a placeholder `$interpolation1`. The message points
	## at the interpolation instead. A `$name` the query wrote itself is no
	## field of a record here, as there is none.
	message : Str, List(Str) -> Str
	message = |text, placeholders|
		match text.split_first(" is not a field of the parameter record") {
			Ok({ before, after: _ }) => "${before} is a placeholder, but this query takes its values as `\${...}` interpolations"
			Err(_) => placeholders.fold_with_index(text, |acc, placeholder, index| acc.replace_each("`$${placeholder}`", "interpolation ${(index + 1).to_str()}"))
		}
}

starts_with_word : Str -> Bool
starts_with_word = |text|
	match text.to_utf8().first() {
		Ok(byte) => (byte >= 'a' and byte <= 'z') or (byte >= 'A' and byte <= 'Z') or (byte >= '0' and byte <= '9') or byte == '_' or byte >= 128
		Err(_) => Bool.False
	}

expect Holes.sql(["select ", " + 1, ", "x from t"]) == "select $interpolation1 + 1, $interpolation2 x from t"
expect Holes.sql(["select ", ""]) == "select $interpolation1"
expect Holes.names(["a", "b", "c"]) == ["interpolation1", "interpolation2"]
expect Holes.message("column `age` is `integer`, but `$interpolation1` is `Dec`", ["interpolation1"]) == "column `age` is `integer`, but interpolation 1 is `Dec`"
expect Holes.message("`$min_age` is not a field of the parameter record (did you mean `interpolation1`?)", ["interpolation1"]) == "`$min_age` is a placeholder, but this query takes its values as `\${...}` interpolations"
