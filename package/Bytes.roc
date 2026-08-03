## Big-endian byte encoding and direct-style decoding helpers.
##
## Decoding is deliberately written in direct style (`take_*` functions that
## return the value plus the remaining bytes) rather than as a combinator
## library, so no closures are stored in data structures.
Bytes :: [].{
	# ---- Encoding ----

	sequence : List(List(U8)) -> List(U8)
	sequence = |parts| parts.fold([], |acc, part| acc.concat(part))

	u8 : U8 -> List(U8)
	u8 = |value| [value]

	i16 : I16 -> List(U8)
	i16 = |value| {
		v = value.to_u16_wrap()
		[v.shr_zf_wrap(8).to_u8_wrap(), v.to_u8_wrap()]
	}

	i32 : I32 -> List(U8)
	i32 = |value| {
		v = value.to_u32_wrap()
		[
			v.shr_zf_wrap(24).to_u8_wrap(),
			v.shr_zf_wrap(16).to_u8_wrap(),
			v.shr_zf_wrap(8).to_u8_wrap(),
			v.to_u8_wrap(),
		]
	}

	c_str : Str -> List(U8)
	c_str = |value| Bytes.null_terminate(value.to_utf8())

	null_terminate : List(U8) -> List(U8)
	null_terminate = |bytes| bytes.append(0)

	# ---- Decoding ----

	take_u8 : List(U8) -> Try({ val : U8, rest : List(U8) }, [UnexpectedEnd, ..])
	take_u8 = |bytes|
		match bytes.get(0) {
			Ok(b) => Ok({ val: b, rest: bytes.drop_first(1) })
			Err(_) => Err(UnexpectedEnd)
		}

	take_u16 : List(U8) -> Try({ val : U16, rest : List(U8) }, [UnexpectedEnd, ..])
	take_u16 = |bytes| {
		b0 = bytes.get(0).map_err(|_| UnexpectedEnd)?
		b1 = bytes.get(1).map_err(|_| UnexpectedEnd)?
		val = b0.to_u16().shl_wrap(8).bitwise_or(b1.to_u16())
		Ok({ val, rest: bytes.drop_first(2) })
	}

	take_u32 : List(U8) -> Try({ val : U32, rest : List(U8) }, [UnexpectedEnd, ..])
	take_u32 = |bytes| {
		b0 = bytes.get(0).map_err(|_| UnexpectedEnd)?
		b1 = bytes.get(1).map_err(|_| UnexpectedEnd)?
		b2 = bytes.get(2).map_err(|_| UnexpectedEnd)?
		b3 = bytes.get(3).map_err(|_| UnexpectedEnd)?
		val = 
			b0.to_u32().shl_wrap(24)
				.bitwise_or(b1.to_u32().shl_wrap(16))
				.bitwise_or(b2.to_u32().shl_wrap(8))
				.bitwise_or(b3.to_u32())
		Ok({ val, rest: bytes.drop_first(4) })
	}

	take_i16 : List(U8) -> Try({ val : I16, rest : List(U8) }, [UnexpectedEnd, ..])
	take_i16 = |bytes| {
		{ val, rest } = Bytes.take_u16(bytes)?
		Ok({ val: val.to_i16_wrap(), rest })
	}

	take_i32 : List(U8) -> Try({ val : I32, rest : List(U8) }, [UnexpectedEnd, ..])
	take_i32 = |bytes| {
		{ val, rest } = Bytes.take_u32(bytes)?
		Ok({ val: val.to_i32_wrap(), rest })
	}

	## Take `count` bytes.
	take : List(U8), U64 -> Try({ val : List(U8), rest : List(U8) }, [UnexpectedEnd, ..])
	take = |bytes, count|
		if bytes.len() < count {
			Err(UnexpectedEnd)
		} else {
			Ok({ val: bytes.take_first(count), rest: bytes.drop_first(count) })
		}

	## Take a null-terminated string (the terminator is consumed, not returned).
	take_c_str : List(U8) -> Try({ val : Str, rest : List(U8) }, [TerminatorNotFound, BadUtf8, ..])
	take_c_str = |bytes|
		match bytes.split_first(0) {
			Ok({ before, after }) =>
				match Str.from_utf8(before) {
					Ok(val) => Ok({ val, rest: after })
					Err(_) => Err(BadUtf8)
				}
			Err(_) => Err(TerminatorNotFound)
		}
}

# Encoding is big-endian and two's complement.
expect Bytes.i16(258) == [1, 2]
expect Bytes.i16(-1) == [255, 255]
expect Bytes.i32(16909060) == [1, 2, 3, 4]
expect Bytes.i32(-1) == [255, 255, 255, 255]
expect Bytes.c_str("hi") == [104, 105, 0]
expect Bytes.sequence([[1, 2], [], [3]]) == [1, 2, 3]

# Decoding consumes from the front and returns the rest.
expect Bytes.take_u8([7, 8]) == Ok({ val: 7, rest: [8] })
expect Bytes.take_u16([1, 2, 3]) == Ok({ val: 258, rest: [3] })
expect Bytes.take_u32([1, 2, 3, 4, 5]) == Ok({ val: 16909060, rest: [5] })
expect Bytes.take_i32([255, 255, 255, 255]) == Ok({ val: -1, rest: [] })
expect Bytes.take([1, 2, 3], 2) == Ok({ val: [1, 2], rest: [3] })
expect Bytes.take([1, 2, 3], 5) == Err(UnexpectedEnd)
expect Bytes.take_c_str([104, 105, 0, 7]) == Ok({ val: "hi", rest: [7] })
expect Bytes.take_c_str([104, 105]) == Err(TerminatorNotFound)

# Round trips
expect Bytes.take_i32(Bytes.i32(-123456789)) == Ok({ val: -123456789, rest: [] })
expect Bytes.take_i16(Bytes.i16(-32000)) == Ok({ val: -32000, rest: [] })
