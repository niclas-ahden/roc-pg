## Decodes a result row into the record type the caller asks for, through
## Roc's builtin parser protocol (the one `Json.parse` uses), and reads the
## shape of that record type at compile time.
##
## `Text` decodes. Columns are matched to fields by name, a column the
## record does not name is skipped, a field the query does not return fails
## with `MissingRequiredField(name)`, and `Try(T, [Null])` takes NULL.
## Values arrive in Postgres text format.
##
## `Nulls` and `Kinds` fill in no real values. They read the record type
## instead: the compiler hands `parse_record_field` the field names, and
## each field's parser then calls the scalar method for its type. `Nulls`
## answers every `parse_null` with "this is NULL" to find the fields that
## take NULL, `Kinds` answers "not NULL" so the parser goes on to the inner
## type. One format serves both, so a query needs one `parser_for` of its
## row type, not two.
import PgResult
import Numeric

RowFormat := [Text, Nulls, Kinds].{
	## One field of a record type. `kind` is `Str`, `I32`, `Bool`, `Dec`,
	## `List(I32)` and so on.
	Field : { name : Str, kind : Str, nullable : Bool }

	State : {
		columns : List(Str),
		values : List([Null, Present(List(U8))]),
		pos : U64,
		items : List([Null, Present(Str)]),
		in_list : Bool,
		started : Bool,
		fields : List(RowFormat.Field),
		current : U64,
	}

	Err : [PgDecodeErr(Str), MissingRequiredField(Str)]

	## Decode one row with the parser the compiler derived for the row type.
	decode : List(Str), List([Null, Present(List(U8))]), (RowFormat.State -> Try({ value : row, rest : RowFormat.State }, RowFormat.Err)) -> Try(row, RowFormat.Err)
	decode = |columns, values, parse| {
		parsed = parse({ ..initial, columns, values })?
		Ok(parsed.value)
	}

	## The fields of a record type, from its parser in the `Nulls` and the
	## `Kinds` mode.
	shape : (RowFormat.State -> Try({ value : a, rest : RowFormat.State }, RowFormat.Err)), (RowFormat.State -> Try({ value : a, rest : RowFormat.State }, RowFormat.Err)) -> Try(List(RowFormat.Field), [NestedRecord])
	shape = |parse_nulls, parse_kinds| {
		nulls = parse_nulls(initial) ? |_| NestedRecord
		kinds = parse_kinds(initial) ? |_| NestedRecord
		Ok(
			kinds.rest.fields.map(
				|field| {
					nullable = nulls.rest.fields.any(|f| f.name == field.name and f.nullable)
					{ ..field, nullable }
				},
			),
		)
	}

	## The kind of a type that is not a record, such as an interpolated
	## value's, from its parser in the `Nulls` and the `Kinds` mode. The
	## field's `name` is empty.
	value_shape : (RowFormat.State -> Try({ value : a, rest : RowFormat.State }, RowFormat.Err)), (RowFormat.State -> Try({ value : a, rest : RowFormat.State }, RowFormat.Err)) -> Try(RowFormat.Field, [NestedRecord])
	value_shape = |parse_nulls, parse_kinds| {
		# Started, so a record type fails at `parse_record_start`.
		one = { ..initial, started: Bool.True, fields: [{ name: "", kind: "", nullable: Bool.False }] }
		nulls = parse_nulls(one) ? |_| NestedRecord
		kinds = parse_kinds(one) ? |_| NestedRecord
		match (kinds.rest.fields.first(), nulls.rest.fields.first()) {
			(Ok(field), Ok(null_field)) => Ok({ ..field, nullable: null_field.nullable })
			_ => Err(NestedRecord)
		}
	}

	rename_field : RowFormat, Str -> Str
	rename_field = |_, name| name

	parse_record_start : RowFormat, RowFormat.State -> Try([Counted({ len : U64, rest : RowFormat.State }), Uncounted(RowFormat.State)], [PgDecodeErr(Str)])
	parse_record_start = |_, state|
		if state.started {
			Err(PgDecodeErr("column ${column_name(state)}: a record field inside a row is not supported"))
		} else {
			Ok(Uncounted({ ..state, started: Bool.True }))
		}

	parse_record_field : RowFormat,
	Encoding.FieldName.FieldNames(_shape),
	RowFormat.State -> Try(
		[
			Field({ field : Encoding.FieldName(_shape), rest : RowFormat.State }),
			TryField({ name : Str, rest : RowFormat.State }),
			TryFieldCaseless({ name : Str, rest : RowFormat.State }),
			Continue(RowFormat.State),
			Done(RowFormat.State),
		],
		[PgDecodeErr(Str)],
	)
	parse_record_field = |format, names, state|
		match format {
			Text =>
				match state.columns.get(state.pos) {
					Ok(name) => Ok(TryField({ name, rest: state }))
					Err(_) => Ok(Done(state))
				}
			Nulls | Kinds => {
				# The first call learns every field name. Each call after that
				# hands out the next one, which `pos` counts.
				current =
					if state.fields.is_empty() and state.pos == 0 {
						{ ..state, fields: names.iter().fold([], |acc, name| acc.append({ name: name.name(), kind: "", nullable: Bool.False })) }
					} else {
						state
					}
				match current.fields.get(current.pos) {
					Ok(field) => Ok(TryField({ name: field.name, rest: { ..current, current: current.pos, pos: current.pos + 1 } }))
					Err(_) => Ok(Done(current))
				}
			}
		}

	parse_record_after_field : RowFormat, RowFormat.State -> Try([Continue(RowFormat.State), Done(RowFormat.State)], [PgDecodeErr(Str)])
	parse_record_after_field = |_, state| Ok(Continue(state))

	skip_record_field : RowFormat, RowFormat.State -> Try(RowFormat.State, [PgDecodeErr(Str)])
	skip_record_field = |format, state|
		match format {
			Text => Ok(advance(state))
			Nulls | Kinds => Ok(state)
		}

	## `Try(T, [Null])` asks this first. `Err` means "not NULL, read a `T`".
	parse_null : RowFormat, RowFormat.State -> Try(RowFormat.State, [PgDecodeErr(Str)])
	parse_null = |format, state|
		match format {
			Text =>
				if state.in_list {
					match state.items {
						[Null, ..] => Ok(pop_item(state))
						_ => Err(PgDecodeErr("not null"))
					}
				} else {
					match state.values.get(state.pos) {
						Ok(Null) => Ok(advance(state))
						_ => Err(PgDecodeErr("not null"))
					}
				}
			Nulls => Ok({ ..state, fields: state.fields.update(state.current, |f| { ..f, nullable: Bool.True }) ?? state.fields })
			Kinds => Err(PgDecodeErr("not null"))
		}

	## Arrays. Reading a shape, one element is enough to learn its type.
	parse_list_start : RowFormat, RowFormat.State -> Try([Counted({ len : U64, rest : RowFormat.State }), Uncounted(RowFormat.State)], [PgDecodeErr(Str)])
	parse_list_start = |format, state|
		match format {
			Text => {
				{ value: array, rest: _ } = current_text(state, "a List")?
				items = PgResult.array_elements(array) ? |_| PgDecodeErr("column ${column_name(state)}: ${quote(array)} is not a one-dimensional array")
				if items.is_empty() {
					Ok(Counted({ len: 0, rest: advance(state) }))
				} else {
					Ok(Counted({ len: items.len(), rest: { ..state, items, in_list: Bool.True } }))
				}
			}
			Nulls | Kinds => Ok(Counted({ len: 1, rest: { ..state, in_list: Bool.True } }))
		}

	parse_list_next : RowFormat, RowFormat.State -> Try([Item(RowFormat.State), Done(RowFormat.State)], [PgDecodeErr(Str)])
	parse_list_next = |_, state| Ok(Done(state))

	parse_list_after_item : RowFormat, RowFormat.State -> Try([Continue(RowFormat.State), Done(RowFormat.State)], [PgDecodeErr(Str)])
	parse_list_after_item = |_, state| Ok(Done(state))

	parse_str : RowFormat, RowFormat.State -> Try({ value : Str, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_str = |format, state|
		match format {
			Text => current_text(state, "a Str")
			_ => Ok({ value: "", rest: kind(state, "Str") })
		}

	parse_bool : RowFormat, RowFormat.State -> Try({ value : Bool, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_bool = |format, state|
		match format {
			Text => {
				{ value, rest } = current_text(state, "a Bool")?
				if value == "t" {
					Ok({ value: Bool.True, rest })
				} else if value == "f" {
					Ok({ value: Bool.False, rest })
				} else {
					Err(PgDecodeErr("column ${column_name(state)}: ${quote(value)} is not a Bool"))
				}
			}
			_ => Ok({ value: Bool.False, rest: kind(state, "Bool") })
		}

	parse_u8 : RowFormat, RowFormat.State -> Try({ value : U8, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_u8 = |format, state| number(format, state, "U8", "a U8", U8.from_str, 0)

	parse_u16 : RowFormat, RowFormat.State -> Try({ value : U16, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_u16 = |format, state| number(format, state, "U16", "a U16", U16.from_str, 0)

	parse_u32 : RowFormat, RowFormat.State -> Try({ value : U32, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_u32 = |format, state| number(format, state, "U32", "a U32", U32.from_str, 0)

	parse_u64 : RowFormat, RowFormat.State -> Try({ value : U64, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_u64 = |format, state| number(format, state, "U64", "a U64", U64.from_str, 0)

	parse_i8 : RowFormat, RowFormat.State -> Try({ value : I8, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_i8 = |format, state| number(format, state, "I8", "an I8", I8.from_str, 0)

	parse_i16 : RowFormat, RowFormat.State -> Try({ value : I16, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_i16 = |format, state| number(format, state, "I16", "an I16", I16.from_str, 0)

	parse_i32 : RowFormat, RowFormat.State -> Try({ value : I32, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_i32 = |format, state| number(format, state, "I32", "an I32", I32.from_str, 0)

	parse_i64 : RowFormat, RowFormat.State -> Try({ value : I64, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_i64 = |format, state| number(format, state, "I64", "an I64", I64.from_str, 0)

	parse_dec : RowFormat, RowFormat.State -> Try({ value : Dec, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_dec = |format, state| number(format, state, "Dec", "a Dec", PgResult.dec_from_text, 0)

	## A [Numeric] field, which no format of Roc's own reads.
	parse_numeric : RowFormat, RowFormat.State -> Try({ value : Numeric, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_numeric = |format, state| number(format, state, "Numeric", "a Numeric", Numeric.from_str, Numeric.from_i128(0))

	parse_f32 : RowFormat, RowFormat.State -> Try({ value : F32, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_f32 = |format, state| number(format, state, "F32", "an F32", F32.from_str, 0)

	parse_f64 : RowFormat, RowFormat.State -> Try({ value : F64, rest : RowFormat.State }, [PgDecodeErr(Str)])
	parse_f64 = |format, state| number(format, state, "F64", "an F64", F64.from_str, 0)
}

initial : RowFormat.State
initial = { columns: [], values: [], pos: 0, items: [], in_list: Bool.False, started: Bool.False, fields: [], current: 0 }

column_name : RowFormat.State -> Str
column_name = |state| state.columns.get(state.pos) ?? "?"

quote : Str -> Str
quote = |value| "'${value}'"

advance : RowFormat.State -> RowFormat.State
advance = |state| { ..state, pos: state.pos + 1, items: [], in_list: Bool.False }

## Take the next array element. After the last one, the array's column is done.
pop_item : RowFormat.State -> RowFormat.State
pop_item = |state| {
	rest = state.items.drop_first(1)
	if rest.is_empty() advance(state) else { ..state, items: rest }
}

## Note the scalar the current field decodes as. Inside an array it is the
## element type, and the array is done after its one element.
kind : RowFormat.State, Str -> RowFormat.State
kind = |state, name| {
	full = if state.in_list "List(${name})" else name
	updated = state.fields.update(state.current, |f| { ..f, kind: full }) ?? state.fields
	{ ..state, fields: updated, in_list: Bool.False }
}

## The text of the current value, and the state after it.
current_text : RowFormat.State, Str -> Try({ value : Str, rest : RowFormat.State }, [PgDecodeErr(Str), ..others])
current_text = |state, wanted|
	if state.in_list {
		match state.items {
			[Present(value), ..] => Ok({ value, rest: pop_item(state) })
			_ => Err(PgDecodeErr("column ${column_name(state)}: an array element is NULL, but the element type is ${wanted}, not Try(_, [Null])"))
		}
	} else {
		match state.values.get(state.pos) {
			Ok(Present(bytes)) =>
				match Str.from_utf8(bytes) {
					Ok(value) => Ok({ value, rest: advance(state) })
					Err(_) => Err(PgDecodeErr("column ${column_name(state)}: the value is not UTF-8"))
				}
			Ok(Null) => Err(PgDecodeErr("column ${column_name(state)} is NULL, but the field is ${wanted}, not Try(_, [Null])"))
			Err(_) => Err(PgDecodeErr("no value for column ${column_name(state)}"))
		}
	}

number : RowFormat, RowFormat.State, Str, Str, (Str -> Try(n, _)), n -> Try({ value : n, rest : RowFormat.State }, [PgDecodeErr(Str), ..others])
number = |format, state, kind_name, wanted, from_str, zero|
	match format {
		Text => {
			{ value: text, rest } = current_text(state, wanted)?
			match from_str(text) {
				Ok(value) => Ok({ value, rest })
				Err(_) => Err(PgDecodeErr("column ${column_name(state)}: ${quote(text)} is not ${wanted}"))
			}
		}
		_ => Ok({ value: zero, rest: kind(state, kind_name) })
	}

present : Str -> [Null, Present(List(U8))]
present = |text| Present(text.to_utf8())

expect {
	Row : { id : I32, name : Str, phone : Try(Str, [Null]), active : Bool }
	row : Try(Row, _)
	row = RowFormat.decode(["id", "name", "phone", "active", "school"], [present("7"), present("Ada"), Null, present("t"), present("HQ")], Row.parser_for(RowFormat.Text))
	row == Ok({ id: 7, name: "Ada", phone: Err(Null), active: Bool.True })
}

expect {
	Row : { id : I32, phone : Try(Str, [Null]) }
	row : Try(Row, _)
	row = RowFormat.decode(["phone", "id"], [present("070"), present("7")], Row.parser_for(RowFormat.Text))
	row == Ok({ id: 7, phone: Ok("070") })
}

expect {
	Row : { id : I32, name : Str }
	row : Try(Row, _)
	row = RowFormat.decode(["id", "name"], [present("7"), Null], Row.parser_for(RowFormat.Text))
	row == Err(PgDecodeErr("column name is NULL, but the field is a Str, not Try(_, [Null])"))
}

expect {
	Row : { id : I32, email : Str }
	row : Try(Row, _)
	row = RowFormat.decode(["id"], [present("7")], Row.parser_for(RowFormat.Text))
	row == Err(MissingRequiredField("email"))
}

expect {
	Row : { id : I32 }
	row : Try(Row, _)
	row = RowFormat.decode(["id"], [present("x7")], Row.parser_for(RowFormat.Text))
	row == Err(PgDecodeErr("column id: 'x7' is not an I32"))
}

expect {
	Row : { tags : List(Str), ids : List(I64), none : List(I32), maybe : List(Try(Str, [Null])), after : I32 }
	row : Try(Row, _)
	row = RowFormat.decode(
		["tags", "ids", "none", "maybe", "after"],
		[present("{a,\"b c\"}"), present("{1,2}"), present("{}"), present("{x,NULL}"), present("9")],
		Row.parser_for(RowFormat.Text),
	)
	row == Ok({ tags: ["a", "b c"], ids: [1, 2], none: [], maybe: [Ok("x"), Err(Null)], after: 9 })
}

expect {
	Row : { id : I32, name : Str, phone : Try(Str, [Null]), active : Bool, tags : List(Str), total : Dec }
	RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds))
	== Ok(
		[
			{ name: "active", kind: "Bool", nullable: Bool.False },
			{ name: "id", kind: "I32", nullable: Bool.False },
			{ name: "name", kind: "Str", nullable: Bool.False },
			{ name: "phone", kind: "Str", nullable: Bool.True },
			{ name: "tags", kind: "List(Str)", nullable: Bool.False },
			{ name: "total", kind: "Dec", nullable: Bool.False },
		],
	)
}

expect {
	Empty : {}
	RowFormat.shape(Empty.parser_for(RowFormat.Nulls), Empty.parser_for(RowFormat.Kinds)) == Ok([])
}

expect {
	Nested : { id : I32, inner : { x : I32 } }
	RowFormat.shape(Nested.parser_for(RowFormat.Nulls), Nested.parser_for(RowFormat.Kinds)) == Err(NestedRecord)
}

expect {
	Row : { total : Numeric, parts : List(Numeric) }
	row : Try(Row, _)
	row = RowFormat.decode(["total", "parts"], [present("1.2345678901234567890123"), present("{1.5,-2}")], Row.parser_for(RowFormat.Text))
	match row {
		Ok(r) => r.total.to_str() == "1.2345678901234567890123" and r.parts.map(|p| p.to_str()) == ["1.5", "-2"]
		Err(_) => Bool.False
	}
}

expect {
	Row : { total : Numeric, maybe : Try(Numeric, [Null]) }
	RowFormat.shape(Row.parser_for(RowFormat.Nulls), Row.parser_for(RowFormat.Kinds)) == Ok([{ name: "maybe", kind: "Numeric", nullable: Bool.True }, { name: "total", kind: "Numeric", nullable: Bool.False }])
}
