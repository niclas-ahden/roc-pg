## What the generated grammar actions in [Actions] run on: the parser's
## value stack, Postgres's list and string functions, and errors reported
## the way the server reports them.
import Node
import Scan

Rt :: [].{
	## A value on the parser's stack: a node, a list, a string, a number or
	## a boolean, as in the grammar's `%union`.
	Value : [NodeValue(Node), ListValue(List(Node)), TextValue(Node.Text), IntValue(I64), BoolValue(Bool)]

	## What an action needs besides its values: the statement's bytes, and
	## the last token the parser read, which `parser_yyerror` quotes.
	Ctx : { bytes : List(U8), last_start : U64, last_end : U64 }

	## A `ListCell *`: a position in a list, or none.
	Cell : { list : List(Node), index : U64 }

	no_cell : Rt.Cell
	no_cell = { list: [], index: 0 }

	cell : List(Node), U64 -> Rt.Cell
	cell = |list, index| { list, index }

	cell_is_set : Rt.Cell -> Bool
	cell_is_set = |c| c.index < c.list.len()

	## ---- the value stack ----

	node_at : List(Rt.Value), U64 -> Node
	node_at = |values, i|
		match values.get(i) {
			Ok(NodeValue(n)) => n
			Ok(ListValue(l)) => NodeList(l)
			_ => Null
		}

	list_at : List(Rt.Value), U64 -> List(Node)
	list_at = |values, i|
		match values.get(i) {
			Ok(ListValue(l)) => l
			Ok(NodeValue(NodeList(l))) => l
			_ => []
		}

	text_at : List(Rt.Value), U64 -> Node.Text
	text_at = |values, i|
		match values.get(i) {
			Ok(TextValue(t)) => t
			_ => Err(Null)
		}

	int_at : List(Rt.Value), U64 -> I64
	int_at = |values, i|
		match values.get(i) {
			Ok(IntValue(n)) => n
			Ok(BoolValue(b)) => if b 1 else 0
			_ => 0
		}

	bool_at : List(Rt.Value), U64 -> Bool
	bool_at = |values, i|
		match values.get(i) {
			Ok(BoolValue(b)) => b
			Ok(IntValue(n)) => n != 0
			_ => Bool.False
		}

	of_node : Node -> Rt.Value
	of_node = |n| NodeValue(n)

	of_list : List(Node) -> Rt.Value
	of_list = |l| ListValue(l)

	of_text : Node.Text -> Rt.Value
	of_text = |t| TextValue(t)

	of_int : I64 -> Rt.Value
	of_int = |n| IntValue(n)

	of_bool : Bool -> Rt.Value
	of_bool = |b| BoolValue(b)

	## `@n`: the location of the n-th symbol, -1 when it has none.
	location : List(I64), U64 -> I64
	location = |locations, i| locations.get(i) ?? -1

	## ---- lists, as `pg_list.h` defines them: NIL is the empty list ----

	list_node : List(Node) -> Node
	list_node = |l| if l.is_empty() Null else NodeList(l)

	node_list : Node -> List(Node)
	node_list = |n|
		match n {
			NodeList(l) => l
			_ => []
		}

	list_make1 : Node -> List(Node)
	list_make1 = |a| [a]

	list_make2 : Node, Node -> List(Node)
	list_make2 = |a, b| [a, b]

	list_make3 : Node, Node, Node -> List(Node)
	list_make3 = |a, b, c| [a, b, c]

	list_make4 : Node, Node, Node, Node -> List(Node)
	list_make4 = |a, b, c, d| [a, b, c, d]

	list_make5 : Node, Node, Node, Node, Node -> List(Node)
	list_make5 = |a, b, c, d, e| [a, b, c, d, e]

	lappend : List(Node), Node -> List(Node)
	lappend = |l, x| l.append(x)

	lcons : Node, List(Node) -> List(Node)
	lcons = |x, l| l.prepend(x)

	list_concat : List(Node), List(Node) -> List(Node)
	list_concat = |a, b| a.concat(b)

	list_copy : List(Node) -> List(Node)
	list_copy = |l| l

	list_copy_tail : List(Node), I64 -> List(Node)
	list_copy_tail = |l, n| l.drop_first(n.to_u64_wrap())

	list_truncate : List(Node), I64 -> List(Node)
	list_truncate = |l, n| l.take_first(n.to_u64_wrap())

	list_length : List(Node) -> I64
	list_length = |l| l.len().to_i64_wrap()

	linitial : List(Node) -> Node
	linitial = |l| l.get(0) ?? Null

	lsecond : List(Node) -> Node
	lsecond = |l| l.get(1) ?? Null

	lthird : List(Node) -> Node
	lthird = |l| l.get(2) ?? Null

	lfourth : List(Node) -> Node
	lfourth = |l| l.get(3) ?? Null

	llast : List(Node) -> Node
	llast = |l| l.last() ?? Null

	list_nth : List(Node), I64 -> Node
	list_nth = |l, n| l.get(n.to_u64_wrap()) ?? Null

	list_delete_first : List(Node) -> List(Node)
	list_delete_first = |l| l.drop_first(1)

	list_delete_last : List(Node) -> List(Node)
	list_delete_last = |l| l.drop_last(1)

	## `list[index] = value`, as a new list.
	list_set : List(Node), U64, Node -> List(Node)
	list_set = |l, index, value| l.set(index, value) ?? l

	min : I64, I64 -> I64
	min = |a, b| if a < b a else b

	max : I64, I64 -> I64
	max = |a, b| if a > b a else b

	## ---- strings ----

	## The text of a `char *` that is known to be set.
	text_str : Node.Text -> Str
	text_str = |t| t ?? ""

	text_is_set : Node.Text -> Bool
	text_is_set = |t|
		match t {
			Ok(_) => Bool.True
			Err(_) => Bool.False
		}

	## `strcmp`: negative, zero or positive, comparing bytes.
	strcmp : Node.Text, Node.Text -> I64
	strcmp = |a, b| compare_bytes(Rt.text_str(a).to_utf8(), Rt.text_str(b).to_utf8())

	## `pg_strcasecmp`: `strcmp` with ASCII letters folded to lower case.
	pg_strcasecmp : Node.Text, Node.Text -> I64
	pg_strcasecmp = |a, b| compare_bytes(Rt.text_str(a).to_utf8().map(ascii_lower), Rt.text_str(b).to_utf8().map(ascii_lower))

	strlen : Node.Text -> I64
	strlen = |t| Rt.text_str(t).to_utf8().len().to_i64_wrap()

	## `s[i]`, or 0 past the end, as C's terminating NUL.
	char_at : Node.Text, I64 -> I64
	char_at = |t, i| (Rt.text_str(t).to_utf8().get(i.to_u64_wrap()) ?? 0).to_i64()

	char_str : I64 -> Str
	char_str = |c| Str.from_utf8_lossy([c.to_u8_wrap()])

	## A `%d` in an error message.
	int_str : I64 -> Str
	int_str = |n| n.to_str()

	## ---- bits, as C computes them on a two's complement int ----

	bit_or : I64, I64 -> I64
	bit_or = |x, y| x.bitwise_or(y)

	bit_and : I64, I64 -> I64
	bit_and = |x, y| x.bitwise_and(y)

	bit_not : I64 -> I64
	bit_not = |x| x.bitwise_not()

	shift_left : I64, I64 -> I64
	shift_left = |x, n| x.shl_wrap(n.to_u8_wrap())

	## ---- nodes ----

	## Two node pointers compared in C: here, the same value.
	same_node : Node, Node -> Bool
	same_node = |a, b| a == b

	## `equal`: the same tree, as Postgres compares trees ([Node.equal]).
	equal : Node, Node -> Bool
	equal = |a, b| Node.equal(a, b)

	## ---- errors ----

	## `ereport(ERROR, errcode(code), errmsg(message), parser_errposition(location))`:
	## a location of -1 means no cursor.
	error : Rt.Ctx, Str, Node.Text, I64 -> Scan.Problem
	error = |ctx, code, message, position| {
		cursor = if position < 0 0 else Scan.cursor_at(ctx.bytes, position.to_u64_wrap())
		{ message: Rt.text_str(message), code, cursor }
	}

	## `parser_yyerror(message)`: the message at or near the last token read.
	yyerror : Rt.Ctx, Node.Text -> Scan.Problem
	yyerror = |ctx, message| Scan.error_at(ctx.bytes, Rt.text_str(message), ctx.last_start, ctx.last_end)
}

compare_bytes : List(U8), List(U8) -> I64
compare_bytes = |a, b| {
	var $i = 0
	var $result = 0.I64
	var $done = Bool.False
	while !$done {
		x = a.get($i) ?? 0
		y = b.get($i) ?? 0
		if x != y {
			$result = x.to_i64() - y.to_i64()
			$done = Bool.True
		} else if x == 0 {
			$done = Bool.True
		} else {
			$i = $i + 1
		}
	}
	$result
}

ascii_lower : U8 -> U8
ascii_lower = |c| if c >= 'A' and c <= 'Z' c + 32 else c
