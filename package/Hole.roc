## A value interpolated into a [Tagged] query. A number or string literal
## becomes one by itself (`${5}`, `${"Earth"}`). Any other value is written
## with its tag, as `${I32(min_age)}`.
##
## Values go in Postgres text format, so the server decides from where an
## interpolation appears what type it is, and turns down a value that is
## not of it when the query runs.
import Numeric
import Param

# TODO: If we go with this design, this should probably be renamed to `Param`.
Hole := [Null, Text(Str), Bool(Bool), I16(I16), I32(I32), I64(I64), F64(F64), Dec(Dec), Number(Numeric), Bytes(List(U8))].{
	from_numeral : Numeral -> Try(Hole, [InvalidNumeral(Str)])
	from_numeral = |numeral| Numeric.from_numeral(numeral).map_ok(|value| Number(value))

	from_quote : Str -> Try(Hole, [BadQuotedBytes(Str)])
	from_quote = |text| Ok(Text(text))

	to_param : Hole -> Param.Param
	to_param = |hole|
		match hole {
			Null => Param.null
			Text(value) => Param.str(value)
			Bool(value) => Param.bool(value)
			I16(value) => Param.i16(value)
			I32(value) => Param.i32(value)
			I64(value) => Param.i64(value)
			F64(value) => Param.f64(value)
			Dec(value) => Param.dec(value)
			Number(value) => Param.numeric(value)
			Bytes(value) => Param.bytes(value)
		}
}
