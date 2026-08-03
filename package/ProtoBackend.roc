## Decoders for the messages the Postgres server sends to the client.
##
## Written in direct style: each decoder takes the (already length-framed)
## message payload and returns a decoded value, threading the remaining bytes
## explicitly. See Bytes.take_* helpers.
import Bytes

ProtoBackend :: [].{
	KeyData : { process_id : I32, secret_key : I32 }

	Status : [Idle, TransactionBlock, FailedTransactionBlock]

	RowField : {
		name : Str,
		data_type_oid : I32,
		format_code : I16,
	}

	Error : {
		localized_severity : Str,
		code : Str,
		message : Str,
		detail : [NoField, Field(Str)],
		hint : [NoField, Field(Str)],
		position : [NoField, Field(Str)],
		ewhere : [NoField, Field(Str)],
		schema_name : [NoField, Field(Str)],
		table_name : [NoField, Field(Str)],
		column_name : [NoField, Field(Str)],
		data_type_name : [NoField, Field(Str)],
		constraint_name : [NoField, Field(Str)],
		file : [NoField, Field(Str)],
		line : [NoField, Field(Str)],
		routine : [NoField, Field(Str)],
	}

	Message : [
		AuthOk,
		AuthCleartextPassword,
		AuthUnsupported(I32),
		ParameterStatus({ name : Str, value : Str }),
		BackendKeyData(KeyData),
		ReadyForQuery(Status),
		ErrorResponse(ProtoBackend.Error),
		NoticeResponse,
		ParseComplete,
		BindComplete,
		NoData,
		RowDescription(List(RowField)),
		ParameterDescription,
		DataRow(List([Null, Present(List(U8))])),
		PortalSuspended,
		CommandComplete(Str),
		EmptyQueryResponse,
		CloseComplete,
	]

	## Parse the 5-byte message header: tag byte plus payload length.
	header : List(U8) -> Try({ msg_type : U8, len : U64 }, _)
	header = |bytes| {
		{ val: msg_type, rest } = Bytes.take_u8(bytes)?
		{ val: len, rest: _ } = Bytes.take_i32(rest)?
		# The length includes its own four bytes, so anything smaller is
		# corrupt and would otherwise underflow into a huge read.
		if len < 4 {
			Err(InvalidMessageLength(len))
		} else {
			Ok({ msg_type, len: (len - 4).to_u64_wrap() })
		}
	}

	## Parse a message payload given its header tag byte.
	message : U8, List(U8) -> Try(ProtoBackend.Message, _)
	message = |msg_type, payload|
		match msg_type {
			'R' => auth_request(payload)
			'S' => param_status(payload)
			'K' => backend_key_data(payload)
			'Z' => ready_for_query(payload)
			'E' => error_response(payload)
			'1' => Ok(ParseComplete)
			'2' => Ok(BindComplete)
			'N' => Ok(NoticeResponse)
			'n' => Ok(NoData)
			'T' => row_description(payload)
			't' => Ok(ParameterDescription)
			'D' => data_row(payload)
			's' => Ok(PortalSuspended)
			'C' => command_complete(payload)
			'I' => Ok(EmptyQueryResponse)
			'3' => Ok(CloseComplete)
			other => Err(UnrecognizedBackendMessage(other))
		}
}

auth_request = |payload| {
	{ val: auth_type, rest: _ } = Bytes.take_i32(payload)?
	match auth_type {
		0 => Ok(AuthOk)
		3 => Ok(AuthCleartextPassword)
		# Carry the code so e.g. md5 (5) and scram-sha-256 (10) are
		# distinguishable in the resulting UnsupportedAuth error.
		other => Ok(AuthUnsupported(other))
	}
}

param_status = |payload| {
	{ val: name, rest } = Bytes.take_c_str(payload)?
	{ val: value, rest: _ } = Bytes.take_c_str(rest)?
	Ok(ParameterStatus({ name, value }))
}

backend_key_data = |payload| {
	{ val: process_id, rest } = Bytes.take_i32(payload)?
	{ val: secret_key, rest: _ } = Bytes.take_i32(rest)?
	Ok(BackendKeyData({ process_id, secret_key }))
}

ready_for_query = |payload| {
	{ val: status, rest: _ } = Bytes.take_u8(payload)?
	match status {
		'I' => Ok(ReadyForQuery(Idle))
		'T' => Ok(ReadyForQuery(TransactionBlock))
		'E' => Ok(ReadyForQuery(FailedTransactionBlock))
		other => Err(UnrecognizedBackendStatus(other))
	}
}

## Error/notice fields arrive as (tag byte, c-string) pairs, terminated by 0.
read_str_fields = |bytes, collected| {
	{ val: field_id, rest } = Bytes.take_u8(bytes)?
	if field_id == 0 {
		Ok(collected)
	} else {
		{ val: value, rest: rest2 } = Bytes.take_c_str(rest)?
		read_str_fields(rest2, collected.append({ field_id, value }))
	}
}

find_field : List({ field_id : U8, value : Str }), U8 -> [NoField, Field(Str)]
find_field = |fields, wanted|
	match fields.find_first(|f| f.field_id == wanted) {
		Ok(f) => Field(f.value)
		Err(_) => NoField
	}

error_response = |payload| {
	fields = read_str_fields(payload, [])?

	localized_severity = 
		match find_field(fields, 'S') {
			Field(v) => v
			NoField => ""
		}
	code = 
		match find_field(fields, 'C') {
			Field(v) => v
			NoField => ""
		}
	msg = 
		match find_field(fields, 'M') {
			Field(v) => v
			NoField => ""
		}

	Ok(
		ErrorResponse({
			localized_severity,
			code,
			message: msg,
			detail: find_field(fields, 'D'),
			hint: find_field(fields, 'H'),
			position: find_field(fields, 'P'),
			ewhere: find_field(fields, 'W'),
			schema_name: find_field(fields, 's'),
			table_name: find_field(fields, 't'),
			column_name: find_field(fields, 'c'),
			data_type_name: find_field(fields, 'd'),
			constraint_name: find_field(fields, 'n'),
			file: find_field(fields, 'F'),
			line: find_field(fields, 'L'),
			routine: find_field(fields, 'R'),
		}),
	)
}

row_description = |payload| {
	{ val: field_count, rest } = Bytes.take_i16(payload)?
	read_row_fields(rest, field_count.to_u64_wrap(), [])
}

read_row_fields = |bytes, remaining, collected|
	if remaining == 0 {
		Ok(RowDescription(collected))
	} else {
		{ val: name, rest: r1 } = Bytes.take_c_str(bytes)?
		# table oid (i32) and attribute number (i16): unused
		{ val: _, rest: r2 } = Bytes.take_i32(r1)?
		{ val: _, rest: r3 } = Bytes.take_i16(r2)?
		{ val: data_type_oid, rest: r4 } = Bytes.take_i32(r3)?
		# data type size (i16) and type modifier (i32): unused
		{ val: _, rest: r5 } = Bytes.take_i16(r4)?
		{ val: _, rest: r6 } = Bytes.take_i32(r5)?
		{ val: format_code, rest: r7 } = Bytes.take_i16(r6)?
		read_row_fields(r7, remaining - 1, collected.append({ name, data_type_oid, format_code }))
	}

data_row = |payload| {
	{ val: column_count, rest } = Bytes.take_i16(payload)?
	read_columns(rest, column_count.to_u64_wrap(), [])
}

read_columns = |bytes, remaining, collected|
	if remaining == 0 {
		Ok(DataRow(collected))
	} else {
		{ val: value_len, rest } = Bytes.take_i32(bytes)?
		# A negative length means the value is NULL
		if value_len < 0 {
			read_columns(rest, remaining - 1, collected.append(Null))
		} else {
			{ val: bytes_val, rest: rest2 } = Bytes.take(rest, value_len.to_u64_wrap())?
			read_columns(rest2, remaining - 1, collected.append(Present(bytes_val)))
		}
	}

command_complete = |payload| {
	{ val, rest: _ } = Bytes.take_c_str(payload)?
	Ok(CommandComplete(val))
}

# Header: tag byte plus i32 length, which includes itself but not the tag.
expect ProtoBackend.header([82, 0, 0, 0, 8]) == Ok({ msg_type: 82, len: 4 })
expect ProtoBackend.header([82, 0, 0, 0, 3]) == Err(InvalidMessageLength(3))

# 'R' with an auth type this client does not speak keeps the code around.
expect ProtoBackend.message('R', [0, 0, 0, 10]) == Ok(AuthUnsupported(10))

# 'Z' payloads carry the transaction status.
expect ProtoBackend.message('Z', ['I']) == Ok(ReadyForQuery(Idle))
expect ProtoBackend.message('Z', ['E']) == Ok(ReadyForQuery(FailedTransactionBlock))

# 'K' carries the backend key as two big-endian i32s.
expect ProtoBackend.message('K', [0, 0, 0, 5, 0, 0, 0, 9]) == Ok(BackendKeyData({ process_id: 5, secret_key: 9 }))

# 'D' carries column values with i32 lengths, -1 meaning NULL.
expect
	ProtoBackend.message('D', [0, 2, 255, 255, 255, 255, 0, 0, 0, 2, 104, 105])
		== Ok(DataRow([Null, Present([104, 105])]))
