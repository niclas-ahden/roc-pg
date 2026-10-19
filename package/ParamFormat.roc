## Turns a record of named values into query parameters, through Roc's
## builtin encoding protocol.
##
## Each field becomes the parameter of the `$name` that shares its name.
## Numbers, `Str`, `Bool` and `Dec` go as text, `Try(T, [Null])` sends NULL
## for `Err(Null)`, and a `List(T)` becomes a Postgres array. A record inside
## the record is not a parameter.
import Param
import Numeric

ParamFormat := [Text].{
	rename_field : ParamFormat, Str -> Str
	rename_field = |_, name| name

	State : { params : List((Str, Param.Param)), name : Str, depth : U64, in_list : Bool, items : List(Param.Param) }

	Err : [ParamsNotARecord, NestedParam(Str)]

	## The named parameters of `params`, in field order.
	encode : params, (params, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(List((Str, Param.Param)), [ParamsNotARecord, NestedParam(Str), ..others])
	encode = |params, write|
		match write(params, { params: [], name: "", depth: 0, in_list: Bool.False, items: [] }) {
			Ok(state) => Ok(state.params)
			Err(ParamsNotARecord) => Err(ParamsNotARecord)
			Err(NestedParam(name)) => Err(NestedParam(name))
		}

	## One value that is not a record, such as an interpolated one, as a
	## parameter.
	encode_value : value, (value, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(Param.Param, ParamFormat.Err)
	encode_value = |value, write| {
		state = write(value, { params: [], name: "", depth: 1, in_list: Bool.False, items: [] })?
		match state.params {
			[(_, param)] => Ok(param)
			_ => Err(ParamsNotARecord)
		}
	}

	## The parameters in the order of the query's placeholders. `from_quote`
	## has already checked that the record has a field for each of them.
	bind : List(Str), List((Str, Param.Param)) -> List(Param.Param)
	bind = |names, named|
		names.map(
			|name|
				match named.find_first(|(n, _)| n == name) {
					Ok((_, param)) => param
					Err(_) => crash "roc-pg-insane-in-the-membrane: the parameter record has no field `${name}`, which `Sql.from_quote` should have refused"
				},
		)

	encode_record : ParamFormat.State, U64, (ParamFormat.State, (ParamFormat.State, Str, (ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)
	encode_record = |state, _, write_fields|
		if state.depth > 0 or state.in_list {
			Err(NestedParam(state.name))
		} else {
			done = write_fields({ ..state, depth: 1 }, |acc, name, write_value| write_value({ ..acc, name }))?
			Ok({ ..done, depth: 0, name: "" })
		}

	encode_list : ParamFormat.State, U64, (ParamFormat.State, (ParamFormat.State, (ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)) -> Try(ParamFormat.State, ParamFormat.Err)
	encode_list = |state, _, write_items|
		if state.in_list {
			Err(NestedParam(state.name))
		} else {
			inner = write_items({ ..state, in_list: Bool.True, items: [] }, |acc, write_item| write_item(acc))?
			add({ ..inner, in_list: Bool.False, items: [] }, Param.list(inner.items))
		}

	encode_null : ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_null = |state| add(state, Param.null)

	encode_str : Str, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_str = |value, state| add(state, Param.str(value))

	encode_bool : Bool, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_bool = |value, state| add(state, Param.bool(value))

	encode_u8 : U8, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_u8 = |value, state| add(state, Param.u8(value))

	encode_u16 : U16, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_u16 = |value, state| add(state, Param.u16(value))

	encode_u32 : U32, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_u32 = |value, state| add(state, Param.u32(value))

	encode_u64 : U64, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_u64 = |value, state| add(state, Param.u64(value))

	encode_i8 : I8, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_i8 = |value, state| add(state, Param.i8(value))

	encode_i16 : I16, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_i16 = |value, state| add(state, Param.i16(value))

	encode_i32 : I32, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_i32 = |value, state| add(state, Param.i32(value))

	encode_i64 : I64, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_i64 = |value, state| add(state, Param.i64(value))

	encode_dec : Dec, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_dec = |value, state| add(state, Param.dec(value))

	encode_f32 : F32, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_f32 = |value, state| add(state, Param.f32(value))

	encode_f64 : F64, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_f64 = |value, state| add(state, Param.f64(value))

	## A [Numeric] parameter, which no format of Roc's own writes.
	encode_numeric : ParamFormat, Numeric, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err)
	encode_numeric = |_, value, state| add(state, Param.numeric(value))
}

## Inside a list the value is an element, otherwise it is the parameter of
## the field being written.
add : ParamFormat.State, Param.Param -> Try(ParamFormat.State, ParamFormat.Err)
add = |state, param|
	if state.in_list {
		Ok({ ..state, items: state.items.append(param) })
	} else if state.depth == 0 {
		Err(ParamsNotARecord)
	} else {
		Ok({ ..state, params: state.params.append((state.name, param)) })
	}

encode_all : params -> Try(List((Str, Param.Param)), ParamFormat.Err)
	where [params.encoder_for : ParamFormat -> (params, ParamFormat.State -> Try(ParamFormat.State, ParamFormat.Err))]
encode_all = |params| {
	Params : params
	ParamFormat.encode(params, Params.encoder_for(ParamFormat.Text))
}

wire : List((Str, Param.Param)) -> List((Str, List([Null, Value(List(U8))])))
wire = |named| named.map(|(name, param)| (name, Param.encode([param]).param_values))

expect {
	phone : Try(Str, [Null])
	phone = Err(Null)
	got = encode_all({ school_id: 7.I32, handle: "ada", phone, tags: ["a", "b"], active: Bool.True })
	match got {
		Ok(named) =>
			wire(named).map(|(name, _)| name).len() == 5
			and wire(named).contains(("school_id", [Value("7".to_utf8())]))
			and wire(named).contains(("phone", [Null]))
			and wire(named).contains(("tags", [Value("{\"a\",\"b\"}".to_utf8())]))
			and wire(named).contains(("active", [Value("t".to_utf8())]))
		Err(_) => Bool.False
	}
}

expect encode_all({}).map_ok(wire) == Ok([])
expect encode_all(7.I32).map_ok(wire) == Err(ParamsNotARecord)
expect encode_all({ inner: { x: 1.I32 } }).map_ok(wire) == Err(NestedParam("inner"))

expect Param.encode(ParamFormat.bind(["b", "a"], [("a", Param.i32(1)), ("b", Param.str("x"))])).param_values == [Value("x".to_utf8()), Value("1".to_utf8())]
