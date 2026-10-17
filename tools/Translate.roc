## Postgres's grammar actions and parser helpers, translated from C to typed
## Roc over the node types of `Node.roc`.
##
## C pointers become values: a node pointer is a `Node`, a `List *` is a
## `List(Node)`, a `char *` is a `Try(Str, [Null])`. Writing a field
## rebuilds the node in its variable, so the translation is faithful as long
## as the C does not write through a pointer that is also stored elsewhere.
## The cases where it would are reported, not translated.
import CParse
import CleanLocals
import Consts
import Structs

Translate :: [].{
	## A C type as the translation sees it.
	CType : [NodePtr(Str), ListPtr, CharPtr, Int, Boolean, Cell, Void]

	## A function's signature: its Roc name, parameters, return type, whether
	## it can fail, and parameters written back or written out.
	Sig : { roc : Str, params : List(Translate.CType), returns : Translate.CType, fails : Bool, inout : List(U64), outs : List(U64) }

	## Everything the translation looks names up in.
	Env : {
		consts : Consts.Table,
		errcodes : Dict(Str, Str),
		structs : Dict(Str, List(Structs.Field)),
		sigs : Dict(Str, Translate.Sig),
		members : Dict(Str, Translate.CType),
		node_types : List(Str),
	}

	## What came out: Roc code, and the problems found on the way.
	Output : { code : Str, problems : List(Str) }

	## A grammar action: the rule's number and length, and the C code.
	action : Translate.Env, U64, U64, Str, CParse.Stmt -> Translate.Output
	action = |env, rule, len, rule_text, body| translate_action(env, rule, len, rule_text, body)

	## A body ready for interning. Extra parameters and their arguments are
	## exclusively I64 literals, extracted only in explicitly Int contexts.
	ActionTemplate : { params : List(Str), body : Str, args : List(Str), problems : List(Str) }

	action_template : Translate.Env, U64, U64, Str, CParse.Stmt -> Translate.ActionTemplate
	action_template = |env, rule, len, rule_text, body| translate_action_body(env, rule, len, rule_text, body, Bool.True)

	## A helper function, under the signature the generator gave it.
	function : Translate.Env, CParse.Func, Translate.Sig -> Translate.Output
	function = |env, func, sig| translate_function(env, func, sig)

	## The C type of a type as written, such as `const char *`.
	ctype : Str -> Translate.CType
	ctype = |text| ctype_of(text)

	## The Roc type and the zero value of a C type.
	roc_type_of : Str -> Str
	roc_type_of = |text| roc_type(ctype_of(text))

	zero_of : Str -> Str
	zero_of = |text| zero(ctype_of(text))

	## The Roc name of a C name: `makeColumnRef` is `make_column_ref`.
	snake : Str -> Str
	snake = |name| snake_case(name)
}

## ---- types ----

ctype_of : Str -> Translate.CType
ctype_of = |text| {
	words = text.replace_each("*", " * ").split_on(" ").map(|w| w.trim()).keep_if(|w| !w.is_empty() and w != "const" and w != "struct" and w != "union" and w != "volatile" and w != "static" and w != "unsigned" and w != "signed" and w != "inline")
	stars = words.keep_if(|w| w == "*").len()
	base = words.find_first(|w| w != "*") ?? "int"
	if stars == 0 and base == "ValUnion" {
		return NodePtr("ValUnion")
	}
	if stars == 0 {
		if base == "bool" {
			Boolean
		} else if base == "void" {
			Void
		} else {
			Int
		}
	} else if base == "List" {
		ListPtr
	} else if base == "char" {
		CharPtr
	} else if base == "ListCell" {
		Cell
	} else if base == "Node" or base == "Expr" or base == "void" or base == "Bitmapset" {
		NodePtr("Node")
	} else {
		NodePtr(base)
	}
}

## The Roc type of a C type.
roc_type : Translate.CType -> Str
roc_type = |t|
	match t {
		NodePtr(_) => "Node"
		ListPtr => "List(Node)"
		CharPtr => "Node.Text"
		Int => "I64"
		Boolean => "Bool"
		Cell => "Rt.Cell"
		Void => "{}"
	}

## The zero value of a type, which `palloc0` and `makeNode` fill in.
## Keep null inline in action expressions: a shared Node constant makes
## repeated compile-time parsing slower on the current compiler.
zero : Translate.CType -> Str
zero = |t|
	match t {
		NodePtr(_) => "Null"
		ListPtr => "[]"
		CharPtr => "Err(Null)"
		Int => "0.I64"
		Boolean => "Bool.False"
		Cell => "Rt.no_cell"
		Void => "{}"
	}

## ---- names ----

snake_case : Str -> Str
snake_case = |name| {
	bytes = name.to_utf8()
	var $out = []
	var $i = 0
	while $i < bytes.len() {
		c = bytes.get($i) ?? 0
		prev = if $i == 0 0 else bytes.get($i - 1) ?? 0
		next = bytes.get($i + 1) ?? 0
		if c >= 'A' and c <= 'Z' {
			lower_prev = (prev >= 'a' and prev <= 'z') or (prev >= '0' and prev <= '9')
			upper_run_end = (prev >= 'A' and prev <= 'Z') and (next >= 'a' and next <= 'z')
			if $i > 0 and prev != '_' and (lower_prev or upper_run_end) {
				$out = $out.append('_')
			}
			$out = $out.append(c + 32)
		} else {
			$out = $out.append(c)
		}
		$i = $i + 1
	}
	fixed = Str.from_utf8_lossy($out)
	if reserved.contains(fixed) "${fixed}_" else fixed
}

## Words Roc reserves, which a C name must not become.
reserved : List(Str)
reserved = ["if", "then", "else", "when", "is", "as", "import", "expect", "dbg", "crash", "var", "return", "for", "in", "while", "break", "match", "where", "targets", "exposing", "module", "package", "app", "platform", "and", "or", "not"]

## A node type's accessor, such as `Node.res_target_of`.
accessor : Str -> Str
accessor = |type| "Node.${snake_case(type)}_of"

## A node type's tag, such as `ResTarget` for `ResTarget` and `AExpr` for
## `A_Expr`.
tag_of : Str -> Str
tag_of = |type| type.replace_each("_", "")

## A struct field's Roc name.
field_name : Str -> Str
field_name = |name| snake_case(name)

## ---- translation state ----

## A local, and when it was read out of a list, the list slot it stands for.
Local : { c : Str, roc : Str, type : Translate.CType, alias : Try(Slot, [NoAlias]) }

## A node that local `source` points to, kept at `target` too: stored there,
## or read from there. With a guard, only when the guard holds.
Store : { source : Str, target : Target, guard : Try(Str, [Always]) }

## A list element: the list as an assignable target, its current value, and
## the index.
Slot : { list : Target, list_code : Str, index : Str }

## Loops over list cells: the cell's C name, its index variable, the copy
## of the list the loop walks, the code that reads the list itself, and the
## list as a target an element can be written back to.
Loop : { cell : Str, index : Str, list : Str, list_read : Str, list_lvalue : Try(Target, [NotLvalue]), list_type : Translate.CType }

St : {
	env : Translate.Env,
	locals : List(Local),
	names : List(Str),
	loops : List(Loop),
	problems : List(Str),
	where_ : Str,
	fails : Bool,
	kind : [Action({ len : U64 }), Function],
	## Locals put into a list, which a later write through them cannot reach.
	published : List(Str),
	## Where a local node was stored, to store it again when it changes,
	## and the condition under which it was, if any.
	stores : List(Store),
	result_type : Translate.CType,
	parameterize : Bool,
	literals : List({ name : Str, code : Str }),
}

problem : St, Str -> St
problem = |st, message| { ..st, problems: st.problems.append("${st.where_}: ${message}") }

## A fresh Roc variable name for a C local.
fresh : St, Str -> { st : St, roc : Str }
fresh = |st, c_name| {
	base = snake_case(c_name)
	var $candidate = base
	var $n = 2.U64
	while st.names.contains($candidate) {
		$candidate = "${base}_${$n.to_str()}"
		$n = $n + 1
	}
	{ st: { ..st, names: st.names.append($candidate) }, roc: $candidate }
}

lookup : St, Str -> Try(Local, [NotLocal])
lookup = |st, name| st.locals.find_last(|l| l.c == name).map_err(|_| NotLocal)

## ---- expressions ----

Code : { code : Str, type : Translate.CType }

## Translate an expression, converting it to `want` when given.
expr : St, CParse.Expr, Try(Translate.CType, [Any]) -> { st : St, out : Code }
expr = |st, e, want| {
	r = expr_raw(st, e, want)
	converted = match want {
		Ok(t) => { st: r.st, out: convert(r.out, t, e) }
		Err(Any) => r
	}
	# Never guess a literal's type from its spelling. In particular a Num
	# under Any, a bool conversion, a pointer cast or a structural stack
	# index is not an I64 slot. Each occurrence gets its own parameter.
	if st.parameterize and want == Ok(Int) and converted.out.type == Int {
		constant = match e {
			Num(text) => Consts.number(text).is_ok()
			CharLit(_) => Bool.True
			Ident(name) =>
				# NodeTag constants use a string representation, not I64.
				if name.starts_with("T_") or lookup(st, name).is_ok() Bool.False else match Consts.resolve(st.env.consts, name) {
					Ok(Int(_)) => Bool.True
					_ => Bool.False
				}
			_ => Bool.False
		}
		if constant {
			named = fresh(converted.st, "literal_${converted.st.literals.len().to_str()}")
			return {
				st: { ..named.st, literals: named.st.literals.append({ name: named.roc, code: converted.out.code }) },
				out: { code: named.roc, type: Int },
			}
		}
	}
	converted
}

## Alias metadata retains expression text without carrying translator state.
## Keep its constants inline: allocating literal slots here would lose their
## declarations and could capture an unrelated later slot with the same name.
retained_expr : St, CParse.Expr, Try(Translate.CType, [Any]) -> Code
retained_expr = |st, e, want| expr({ ..st, parameterize: Bool.False }, e, want).out

## A value converted between C types that share a representation or that
## C converts implicitly.
convert : Code, Translate.CType, CParse.Expr -> Code
convert = |c, to, e| {
	if is_null_literal(e) {
		return { code: zero(to), type: to }
	}
	match (c.type, to) {
		(NodePtr(_), NodePtr(_)) => { code: c.code, type: to }
		(ListPtr, NodePtr(_)) => { code: "Rt.list_node(${c.code})", type: to }
		(NodePtr(_), ListPtr) => { code: "Rt.node_list(${c.code})", type: to }
		(Int, Boolean) => { code: "(${c.code} != 0)", type: to }
		(Boolean, Int) => { code: if c.code == "Bool.True" "1" else if c.code == "Bool.False" "0" else "(if ${c.code} 1 else 0)", type: to }
		_ => c
	}
}

is_null_literal : CParse.Expr -> Bool
is_null_literal = |e|
	match e {
		Ident("NULL") | Ident("NIL") => Bool.True
		Cast(_, inner) => is_null_literal(inner)
		_ => Bool.False
	}

expr_raw : St, CParse.Expr, Try(Translate.CType, [Any]) -> { st : St, out : Code }
expr_raw = |st, e, want|
	match e {
		Num(text) =>
			match Consts.number(text) {
				Ok(n) => { st, out: { code: int_literal(n), type: Int } }
				Err(_) => { st: problem(st, "number ${text}"), out: { code: "0", type: Int } }
			}
		CharLit(c) => { st, out: { code: int_literal(c.to_i64()), type: Int } }
		StrLit(bytes) => { st, out: { code: "Ok(${roc_string(bytes)})", type: CharPtr } }
		Ident(name) => ident(st, name, want)
		Cast(type_text, inner) => {
			to = ctype_of(type_text)
			r = expr(st, inner, Err(Any))
			if to == Void {
				r
			} else {
				{ st: r.st, out: convert(r.out, to, inner) }
			}
		}
		Field(Index(Ident("yyvsp"), k), member) => rhs(st, k, member)
		Index(Ident("yylsp"), k) =>
			match rhs_number(st, k) {
				Ok(n) => { st, out: { code: "l${n.to_str()}", type: Int } }
				Err(_) => { st: problem(st, "location index"), out: { code: "0", type: Int } }
			}
		Field(Ident("yyval"), member) => { st, out: { code: "$result", type: member_type(st, member) } }
		Field(target, name) => field_read(st, target, name)
		Call(Ident(name), args) => call(st, name, args, want)
		Prefix("+", inner) => expr(st, inner, want)
		Prefix("!", inner) => {
			r = condition(st, inner)
			{ st: r.st, out: { code: "!(${r.code})", type: Boolean } }
		}
		Prefix("-", inner) => {
			r = expr(st, inner, Ok(Int))
			{ st: r.st, out: { code: "(0 - ${r.out.code})", type: Int } }
		}
		Prefix("~", inner) => {
			r = expr(st, inner, Ok(Int))
			{ st: r.st, out: { code: "Rt.bit_not(${r.out.code})", type: Int } }
		}
		Binary(op, a, b) => binary(st, op, a, b)
		Cond(c, a, b) => {
			rc = condition(st, c)
			ra = expr(rc.st, a, want)
			rb = expr(ra.st, b, Ok(ra.out.type))
			{ st: rb.st, out: { code: "(if ${rc.code} ${ra.out.code} else ${rb.out.code})", type: ra.out.type } }
		}
		Index(target, i) => {
			rt = expr(st, target, Err(Any))
			ri = expr(rt.st, i, Ok(Int))
			match rt.out.type {
				CharPtr => { st: ri.st, out: { code: "Rt.char_at(${rt.out.code}, ${ri.out.code})", type: Int } }
				_ => { st: problem(ri.st, "indexing a non-string"), out: { code: "0", type: Int } }
			}
		}
		_ => { st: problem(st, "unsupported expression ${CParse.show(ExprStmt(e))}"), out: { code: "crash \"untranslated\"", type: Int } }
	}

int_literal : I64 -> Str
int_literal = |n| if n < 0 "(${n.to_str()})" else n.to_str()

## A Roc string literal of some bytes.
roc_string : List(U8) -> Str
roc_string = |bytes| {
	var $out = ['"']
	var $i = 0
	while $i < bytes.len() {
		c = bytes.get($i) ?? 0
		if c == '"' or c == '\\' {
			$out = $out.concat(['\\', c])
		} else if c == '$' and bytes.get($i + 1) == Ok('{') {
			$out = $out.concat(['\\', '$'])
		} else if c == '\n' {
			$out = $out.concat(['\\', 'n'])
		} else if c == '\t' {
			$out = $out.concat(['\\', 't'])
		} else {
			$out = $out.append(c)
		}
		$i = $i + 1
	}
	Str.from_utf8_lossy($out.append('"'))
}

## The member type of `$$` or a `$n`.
member_type : St, Str -> Translate.CType
member_type = |st, member| st.env.members.get(member) ?? NodePtr("Node")

## `$n` from `yyvsp[k].member`.
rhs : St, CParse.Expr, Str -> { st : St, out : Code }
rhs = |st, k, member|
	match rhs_number(st, k) {
		Ok(n) => { st, out: { code: "$a${n.to_str()}", type: member_type(st, member) } }
		Err(_) => { st: problem(st, "value index"), out: { code: "Null", type: NodePtr("Node") } }
	}

## `n` for bison's offset `k` of a rule of length `len`: `yyvsp[k]` is `$(k + len)`.
rhs_number : St, CParse.Expr -> Try(I64, [NotConstant])
rhs_number = |st, k| {
	offset =
		match k {
			Num(text) => I64.from_str(text).map_err(|_| NotConstant)?
			Prefix("-", Num(text)) => 0 - (I64.from_str(text).map_err(|_| NotConstant)?)
			_ => return Err(NotConstant)
		}
	len =
		match st.kind {
			Action({ len: l }) => l.to_i64_wrap()
			Function => 0
		}
	Ok(offset + len)
}

ident : St, Str, Try(Translate.CType, [Any]) -> { st : St, out : Code }
ident = |st, name, want| {
	match lookup(st, name) {
		Ok(local) => return { st, out: { code: "$${local.roc}", type: local.type } }
		Err(_) => {}
	}
	if name == "NULL" or name == "NIL" {
		t = want ?? NodePtr("Node")
		{ st, out: { code: zero(t), type: t } }
	} else if name == "true" or name == "TRUE" {
		{ st, out: { code: "Bool.True", type: Boolean } }
	} else if name == "false" or name == "FALSE" {
		{ st, out: { code: "Bool.False", type: Boolean } }
	} else if name == "yyloc" {
		{ st, out: { code: "loc", type: Int } }
	} else if name == "yyscanner" {
		{ st, out: { code: "ctx", type: Void } }
	} else if name.starts_with("T_") {
		{ st, out: { code: "\"${Str.from_utf8_lossy(name.to_utf8().drop_first(2))}\"", type: Int } }
	} else {
		match Consts.resolve(st.env.consts, name) {
			Ok(Int(n)) => { st, out: { code: int_literal(n), type: Int } }
			Ok(Text(s)) => { st, out: { code: "Ok(${roc_string(s.to_utf8())})", type: CharPtr } }
			Err(_) => { st: problem(st, "unknown name ${name}"), out: { code: "0", type: Int } }
		}
	}
}

## `x->f`: the field of the node `x` points at.
field_read : St, CParse.Expr, Str -> { st : St, out : Code }
field_read = |st, target, name| {
	r = expr(st, target, Err(Any))
	match r.out.type {
		NodePtr(type) =>
			if name == "type" and field_type(r.st, type, "type").is_err() {
				# The node tag every node starts with.
				{ st: r.st, out: { code: "Node.tag(${r.out.code})", type: Int } }
			} else if type == "ValUnion" {
				# A member of A_Const's value union: the node it holds.
				match union_member(name) {
					Ok(member) => { st: r.st, out: { code: r.out.code, type: NodePtr(member) } }
					Err(_) => { st: problem(r.st, "union member ${name}"), out: { code: "Null", type: NodePtr("Node") } }
				}
			} else if type == "Node" {
				{ st: problem(r.st, "field ${name} of an untyped node"), out: { code: "Null", type: NodePtr("Node") } }
			} else {
				match field_type(r.st, type, name) {
					Ok(ft) => { st: r.st, out: { code: "${accessor(type)}(${r.out.code}).${field_name(name)}", type: ft } }
					Err(_) => { st: problem(r.st, "no field ${name} in ${type}"), out: { code: "Null", type: NodePtr("Node") } }
				}
			}
		_ => { st: problem(r.st, "field ${name} of a non-node"), out: { code: "Null", type: NodePtr("Node") } }
	}
}

field_type : St, Str, Str -> Try(Translate.CType, [NoField])
field_type = |st, type, name| {
	fields = st.env.structs.get(type) ? |_| NoField
	f = fields.find_first(|x| x.name == name) ? |_| NoField
	# A struct held in place, such as `CreateStmt base`, is a node of its own.
	if !f.type.contains("*") and st.env.structs.contains(f.type) and f.type != "ValUnion" {
		Ok(NodePtr(f.type))
	} else {
		Ok(ctype_of(f.type))
	}
}

## The member of `A_Const`'s value union, as the node type it holds.
union_member : Str -> Try(Str, [NotMember])
union_member = |name|
	if name == "ival" {
		Ok("Integer")
	} else if name == "fval" {
		Ok("Float")
	} else if name == "boolval" {
		Ok("Boolean")
	} else if name == "sval" {
		Ok("String")
	} else if name == "bsval" {
		Ok("BitString")
	} else if name == "node" {
		Ok("Node")
	} else {
		Err(NotMember)
	}

## A C condition as a Roc `Bool`: a pointer is true when not NULL, a number
## when not 0.
condition : St, CParse.Expr -> { st : St, code : Str }
condition = |st, e| {
	r = expr(st, e, Err(Any))
	code =
		match r.out.type {
			Boolean => r.out.code
			Int => "(${r.out.code} != 0)"
			NodePtr(_) => "!Node.is_null(${r.out.code})"
			ListPtr => "!(${r.out.code}).is_empty()"
			CharPtr => "Rt.text_is_set(${r.out.code})"
			Cell => "Rt.cell_is_set(${r.out.code})"
			Void => "Bool.True"
		}
	{ st: r.st, code }
}

binary : St, Str, CParse.Expr, CParse.Expr -> { st : St, out : Code }
binary = |st, op, a, b| {
	if op == "&&" or op == "||" {
		ra = condition(st, a)
		rb = condition(ra.st, b)
		word = if op == "&&" "and" else "or"
		return { st: rb.st, out: { code: "(${ra.code} ${word} ${rb.code})", type: Boolean } }
	}
	if op == "==" or op == "!=" {
		negate = op == "!="
		# Comparisons with NULL or NIL.
		null_side = if is_null_literal(b) Ok(a) else if is_null_literal(a) Ok(b) else Err(NoNull)
		match null_side {
			Ok(other) => {
				r = expr(st, other, Err(Any))
				test =
					match r.out.type {
						NodePtr(_) => "Node.is_null(${r.out.code})"
						ListPtr => "(${r.out.code}).is_empty()"
						CharPtr => "!Rt.text_is_set(${r.out.code})"
						Cell => "!Rt.cell_is_set(${r.out.code})"
						_ => "(${r.out.code} == 0)"
					}
				return { st: r.st, out: { code: if negate "!(${test})" else test, type: Boolean } }
			}
			Err(_) => {}
		}
		ra = expr(st, a, Err(Any))
		rb = expr(ra.st, b, Ok(ra.out.type))
		code =
			match ra.out.type {
				NodePtr(_) => "Rt.same_node(${ra.out.code}, ${rb.out.code})"
				_ => "(${ra.out.code} == ${rb.out.code})"
			}
		return { st: rb.st, out: { code: if negate "!(${code})" else code, type: Boolean } }
	}
	ra = expr(st, a, Ok(Int))
	rb = expr(ra.st, b, Ok(Int))
	if op == "<" or op == ">" or op == "<=" or op == ">=" {
		{ st: rb.st, out: { code: "(${ra.out.code} ${op} ${rb.out.code})", type: Boolean } }
	} else if op == "+" or op == "-" or op == "*" {
		{ st: rb.st, out: { code: "(${ra.out.code} ${op} ${rb.out.code})", type: Int } }
	} else if op == "/" {
		{ st: rb.st, out: { code: "(${ra.out.code} // ${rb.out.code})", type: Int } }
	} else if op == "%" {
		{ st: rb.st, out: { code: "(${ra.out.code} % ${rb.out.code})", type: Int } }
	} else if op == "|" {
		{ st: rb.st, out: { code: "Rt.bit_or(${ra.out.code}, ${rb.out.code})", type: Int } }
	} else if op == "&" {
		{ st: rb.st, out: { code: "Rt.bit_and(${ra.out.code}, ${rb.out.code})", type: Int } }
	} else if op == "<<" {
		{ st: rb.st, out: { code: "Rt.shift_left(${ra.out.code}, ${rb.out.code})", type: Int } }
	} else {
		{ st: problem(rb.st, "operator ${op}"), out: { code: "0", type: Int } }
	}
}

## ---- calls ----

## The type name in a macro's type argument, such as `makeNode(ColumnRef)`.
type_arg : CParse.Expr -> Str
type_arg = |e|
	match e {
		Ident(name) => name
		SizeOf(text) => text.replace_each("struct ", "").trim()
		_ => "?"
	}

call : St, Str, List(CParse.Expr), Try(Translate.CType, [Any]) -> { st : St, out : Code }
call = |st, name, args, want| {
	arg0 = args.get(0) ?? Ident("?")
	arg1 = args.get(1) ?? Ident("?")
	if name == "makeNode" or ((name == "palloc" or name == "palloc0") and is_sizeof(arg0)) {
		type = type_arg(arg0)
		{ st, out: { code: "Node.${tag_of(type)}(Node.${snake_case(type)}_default)", type: NodePtr(type) } }
	} else if name == "castNode" {
		r = expr(st, arg1, Err(Any))
		{ st: r.st, out: { code: r.out.code, type: NodePtr(type_arg(arg0)) } }
	} else if name == "IsA" {
		r = expr(st, arg0, Err(Any))
		{ st: r.st, out: { code: "(Node.tag(${r.out.code}) == \"${type_arg(arg1)}\")", type: Boolean } }
	} else if name == "nodeTag" {
		r = expr(st, arg0, Err(Any))
		{ st: r.st, out: { code: "Node.tag(${r.out.code})", type: Int } }
	} else if name == "lfirst_node" or name == "linitial_node" or name == "lsecond_node" or name == "llast_node" or name == "list_nth_node" {
		inner = name.drop_suffix("_node")
		r = call(st, inner, args.drop_first(1), want)
		{ st: r.st, out: { code: r.out.code, type: NodePtr(type_arg(arg0)) } }
	} else if name == "lfirst" {
		match cell_of(st, arg0) {
			Ok(lp) => { st, out: { code: "(${lp.list}.get(${lp.index}) ?? Null)", type: NodePtr("Node") } }
			Err(_) => { st: problem(st, "lfirst of an unknown cell"), out: { code: "Null", type: NodePtr("Node") } }
		}
	} else if name == "lnext" {
		match cell_of(st, arg1) {
			Ok(lp) => { st, out: { code: "Rt.cell(${lp.list}, ${lp.index} + 1)", type: Cell } }
			Err(_) => { st: problem(st, "lnext of an unknown cell"), out: { code: "Rt.no_cell", type: Cell } }
		}
	} else if name == "foreach_current_index" {
		match cell_of(st, arg0) {
			Ok(lp) => { st, out: { code: "${lp.index}.to_i64_wrap()", type: Int } }
			Err(_) => { st: problem(st, "index of an unknown cell"), out: { code: "0", type: Int } }
		}
	} else if name == "intVal" or name == "strVal" or name == "boolVal" {
		r = expr(st, arg0, Err(Any))
		accessor_code =
			if name == "intVal" {
				{ code: "Node.integer_of(${r.out.code}).ival", type: Int }
			} else if name == "strVal" {
				{ code: "Node.string_of(${r.out.code}).sval", type: CharPtr }
			} else {
				{ code: "Node.boolean_of(${r.out.code}).boolval", type: Boolean }
			}
		{ st: r.st, out: accessor_code }
	} else if name == "pstrdup" or name == "_" or name == "copyObject" {
		expr(st, arg0, want)
	} else if name == "Min" or name == "Max" {
		ra = expr(st, arg0, Ok(Int))
		rb = expr(ra.st, arg1, Ok(Int))
		{ st: rb.st, out: { code: "Rt.${if name == "Min" "min" else "max"}(${ra.out.code}, ${rb.out.code})", type: Int } }
	} else if name == "INTERVAL_MASK" {
		r = expr(st, arg0, Ok(Int))
		{ st: r.st, out: { code: "Rt.shift_left(1, ${r.out.code})", type: Int } }
	} else if name == "psprintf" {
		format(st, args)
	} else {
		st_pub = if name == "lappend" or name == "lcons" or name.starts_with("list_make") args.fold(st, |acc, a| publish_arg(acc, a)) else st
		match st.env.sigs.get(name) {
			Ok(sig) => call_sig(st_pub, sig, args)
			Err(_) => { st: problem(st, "unknown function ${name}"), out: { code: "Null", type: NodePtr("Node") } }
		}
	}
}

is_sizeof : CParse.Expr -> Bool
is_sizeof = |e|
	match e {
		SizeOf(_) => Bool.True
		_ => Bool.False
	}

## A call to a function with a signature: arguments converted to the
## parameter types, `ctx` for `yyscanner`, `?` when it can fail.
call_sig : St, Translate.Sig, List(CParse.Expr) -> { st : St, out : Code }
call_sig = |st, sig, args| {
	var $st = st
	var $codes = []
	var $i = 0
	for a in args {
		param = sig.params.get($i) ?? NodePtr("Node")
		if param == Void {
			$codes = $codes.append("ctx")
		} else {
			r = expr($st, a, Ok(param))
			$st = r.st
			$codes = $codes.append(r.out.code)
		}
		$i = $i + 1
	}
	suffix = if sig.fails "?" else ""
	# A helper that fails without a `yyscanner` of its own still reports
	# errors against the statement.
	extra = if sig.fails and !sig.params.contains(Void) and !sig.roc.starts_with("Rt.") ["ctx"] else []
	call_code = "${sig.roc}(${Str.join_with($codes.concat(extra), ", ")})${suffix}"
	if sig.fails and !$st.fails {
		$st = problem($st, "a call that can fail in a function that cannot")
	}
	{ st: $st, out: { code: call_code, type: sig.returns } }
}

## `psprintf` and `errmsg` formats: `%s`, `%d`, `%u`, `%c` and `%%`, as
## Roc string interpolation.
format : St, List(CParse.Expr) -> { st : St, out : Code }
format = |st, args| {
	fmt_bytes =
		match args.get(0) {
			Ok(StrLit(b)) => b
			_ => []
		}
	var $st = st
	var $out = []
	var $arg = 1
	var $i = 0
	while $i < fmt_bytes.len() {
		c = fmt_bytes.get($i) ?? 0
		if c == '%' {
			spec = fmt_bytes.get($i + 1) ?? 0
			if spec == '%' {
				$out = $out.append('%')
			} else {
				a = args.get($arg) ?? Ident("?")
				r = expr($st, a, Err(Any))
				$st = r.st
				piece =
					match (spec, r.out.type) {
						('s', CharPtr) => "\${Rt.text_str(${r.out.code})}"
						('c', _) => "\${Rt.char_str(${r.out.code})}"
						(_, _) => "\${Rt.int_str(${r.out.code})}"
					}
				$out = $out.concat(piece.to_utf8())
				$arg = $arg + 1
			}
			$i = $i + 2
		} else {
			if c == '"' or c == '\\' {
				$out = $out.concat(['\\', c])
			} else if c == '$' and fmt_bytes.get($i + 1) == Ok('{') {
				$out = $out.concat(['\\', '$'])
			} else if c == '\n' {
				$out = $out.concat(['\\', 'n'])
			} else {
				$out = $out.append(c)
			}
			$i = $i + 1
		}
	}
	{ st: $st, out: { code: "Ok(\"${Str.from_utf8_lossy($out)}\")", type: CharPtr } }
}

## The loop a `ListCell *` belongs to.
cell_of : St, CParse.Expr -> Try(Loop, [NoCell])
cell_of = |st, e|
	match e {
		Ident(name) => st.loops.find_last(|lp| lp.cell == name).map_err(|_| NoCell)
		_ => Err(NoCell)
	}

## ---- lvalues and assignment ----

## Where an assignment goes: a variable, and the path of node fields in it.
Target : { root : Str, root_type : Translate.CType, path : List({ type : Str, field : Str }), type : Translate.CType, local : Try(Str, [NotLocal]) }

lvalue : St, CParse.Expr -> Try(Target, [NotLvalue])
lvalue = |st, e|
	match e {
		Ident(name) =>
			match lookup(st, name) {
				Ok(local) => Ok({ root: "$${local.roc}", root_type: local.type, path: [], type: local.type, local: Ok(local.c) })
				Err(_) => Err(NotLvalue)
			}
		Field(Ident("yyval"), member) => {
			t = member_type(st, member)
			Ok({ root: "$result", root_type: t, path: [], type: t, local: Err(NotLocal) })
		}
		Field(Index(Ident("yyvsp"), k), member) =>
			match rhs_number(st, k) {
				Ok(n) => {
					t = member_type(st, member)
					Ok({ root: "$a${n.to_str()}", root_type: t, path: [], type: t, local: Ok(value_local(n)) })
				}
				Err(_) => Err(NotLvalue)
			}
		Cast(type_text, inner) => {
			base = lvalue(st, inner)?
			Ok({ ..base, type: ctype_of(type_text) })
		}
		Call(Ident("castNode"), [Ident(type), inner]) => {
			base = lvalue(st, inner)?
			Ok({ ..base, type: NodePtr(type) })
		}
		Field(target, name) => {
			base = lvalue(st, target)?
			match base.type {
				NodePtr(type) =>
					if type == "Node" {
						Err(NotLvalue)
					} else {
						ft = field_type(st, type, name) ? |_| NotLvalue
						Ok({ ..base, path: base.path.append({ type, field: name }), type: ft })
					}
				_ => Err(NotLvalue)
			}
		}
		_ => Err(NotLvalue)
	}

## The Roc statement that assigns `value` to a target.
assign_code : Target, Str -> Str
assign_code = |target, value| "${target.root} = ${rebuild(target.root, target.path, value)}"

## The new value of a variable after setting the field at `path`.
rebuild : Str, List({ type : Str, field : Str }), Str -> Str
rebuild = |current, path, value|
	match path {
		[] => value
		[first, .. as rest] => {
			rec = "${accessor(first.type)}(${current})"
			inner = rebuild("${rec}.${field_name(first.field)}", rest, value)
			"Node.${tag_of(first.type)}({ ..${rec}, ${field_name(first.field)}: ${inner} })"
		}
	}

## ---- statements ----

Lines : List(Str)

indent : Lines -> Lines
indent = |lines| lines.map(|l| "\t${l}")

## Fuse only uninterrupted, independent writes. The ordinary lowering remains
## authoritative for alias propagation and diagnostics; any writeback is a
## barrier. Calls, field reads and control flow are deliberately not moved.
Batch : { st : St, lines : Lines, count : U64 }

batch : St, List(CParse.Stmt) -> Batch
batch = |st, items| {
	first = items.first() ?? Empty
	initial = stmt(st, first)
	seed =
		match first {
			Decl(type_text, [{ name, init: Ok(Call(Ident("makeNode"), [Ident(type)])) }]) =>
				if ctype_of(type_text) == NodePtr(type) {
					match lookup(initial.st, name) {
						Ok(local) => Ok({ root: "$${local.roc}", c: name, type, base: "Node.${snake_case(type)}_default", prefix: "var " })
						Err(_) => Err(NoBatch)
					}
				} else {
					Err(NoBatch)
				}
			ExprStmt(Assign("=", left, _)) =>
				match lvalue(st, left) {
					Ok({ root, path: [{ type, field: _ }], local: Ok(c), .. }) =>
						Ok({ root, c, type, base: "${accessor(type)}(${root})", prefix: "" })
					_ => Err(NoBatch)
				}
			_ => Err(NoBatch)
		}
	match seed {
		Err(_) => { st: initial.st, lines: initial.lines, count: 1 }
		Ok(s) => {
			is_decl = s.prefix == "var "
			var $st = if is_decl initial.st else st
			var $count = if is_decl 1.U64 else 0.U64
			var $fields = []
			var $names = []
			while $count < items.len() {
				match items.get($count) {
					Ok(ExprStmt(Assign("=", left, right))) => {
						if !independent_value(right, s.c) { break }
						if $st.stores.any(|store|
							(store.source == s.c or (store.target.local == Ok(s.c) and store.target.path.is_empty())) and
							match lookup($st, store.source) {
								Ok({ type: NodePtr(_), .. }) => Bool.True
								_ => Bool.False
							}) { break }
						match lvalue($st, left) {
							Ok(target) =>
								match target.path {
									[{ type, field }] => {
										if target.root != s.root or type != s.type or $names.contains(field) { break }
										r = assignment($st, "=", left, right)
										# A propagated alias or a diagnostic must remain at its
										# original statement, not disappear into a record literal.
										if r.lines.len() != 1 or r.st.problems != $st.problems { break }
										value = expr($st, right, Ok(target.type))
										$fields = $fields.append("${field_name(field)}: ${value.out.code}")
										$names = $names.append(field)
										$st = r.st
										$count = $count + 1
									}
									_ => break
								}
							Err(_) => break
						}
					}
					_ => break
				}
			}
			if $count <= 1 {
				{ st: initial.st, lines: initial.lines, count: 1 }
			} else {
				{ st: $st, count: $count, lines: ["${s.prefix}${s.root} = Node.${tag_of(s.type)}({ ..${s.base}, ${Str.join_with($fields, ", ")} })"] }
			}
		}
	}
}

independent_value : CParse.Expr, Str -> Bool
independent_value = |e, root|
	match e {
		Ident(name) => name != root
		Num(_) | CharLit(_) | StrLit(_) => Bool.True
		# These are immutable parser input reads, not arbitrary node accessors.
		Field(Index(Ident("yyvsp"), _), _) | Index(Ident("yylsp"), _) => Bool.True
		_ => Bool.False
	}

stmt : St, CParse.Stmt -> { st : St, lines : Lines }
stmt = |st, s|
	match s {
		Block(all) => {
			# Nothing after a statement that leaves can run.
			items =
				match all.find_first_index(leaves) {
					Ok(last) => all.take_first(last + 1)
					Err(_) => all
				}
			saved = st.locals
			var $st = st
			var $lines = []
			var $i = 0.U64
			while $i < items.len() {
				r = batch($st, items.drop_first($i))
				$st = r.st
				$lines = $lines.concat(r.lines)
				$i = $i + r.count
			}
			# Stores into a local declared in the block end with it.
			kept = $st.stores.keep_if(|x| store_in_scope(saved, x))
			{ st: { ..$st, locals: saved, stores: kept }, lines: $lines }
		}
		Empty => { st, lines: [] }
		Decl(type_text, decls) => {
			t = ctype_of(type_text)
			if t == Cell {
				# List cells only exist as the loops over them.
				return { st, lines: [] }
			}
			var $st = st
			var $lines = []
			for d in decls {
				named = fresh($st, d.name)
				alias =
					match d.init {
						Ok(init) => slot_of($st, init)
						Err(_) => Err(NoAlias)
					}
				init_code =
					match d.init {
						Ok(init) => {
							r = expr(named.st, init, Ok(t))
							$st = r.st
							r.out.code
						}
						Err(_) => {
							$st = named.st
							zero(t)
						}
					}
				$st = { ..$st, locals: $st.locals.append({ c: d.name, roc: named.roc, type: t, alias }) }
				match d.init {
					Ok(init) => {
						$st = { ..$st, stores: $st.stores.concat(read_from($st, d.name, init)) }
					}
					Err(_) => {}
				}
				annotation = if t == Cell "" else ""
				$lines = $lines.append("var $${named.roc}${annotation} = ${init_code}")
			}
			{ st: $st, lines: $lines }
		}
		ExprStmt(e) => expression_statement(st, e)
		If(c, then, els) => {
			rc = condition(st, c)
			rt = stmt(rc.st, then)
			match els {
				Ok(e) => {
					re = stmt(rt.st, e)
					{ st: re.st, lines: ["if ${rc.code} {"].concat(indent(rt.lines)).concat(["} else {"]).concat(indent(re.lines)).append("}") }
				}
				Err(_) => { st: rt.st, lines: ["if ${rc.code} {"].concat(indent(rt.lines)).append("}") }
			}
		}
		While(c, body) => {
			rc = condition(st, c)
			rb = stmt(rc.st, body)
			{ st: rb.st, lines: ["while ${rc.code} {"].concat(indent(rb.lines)).append("}") }
		}
		For(init, c, step, body) => {
			ri = stmt(st, init)
			rc =
				match c {
					Ok(cond_e) => condition(ri.st, cond_e)
					Err(_) => { st: ri.st, code: "Bool.True" }
				}
			rb = stmt(rc.st, body)
			rs =
				match step {
					Ok(step_e) => expression_statement(rb.st, step_e)
					Err(_) => { st: rb.st, lines: [] }
				}
			{ st: rs.st, lines: ri.lines.append("while ${rc.code} {").concat(indent(rb.lines.concat(rs.lines))).append("}") }
		}
		Foreach(name, args, body) => foreach(st, name, args, body)
		Return(Ok(e)) => {
			r = expr(st, e, Ok(st.result_type))
			wrapped = if st.fails "Ok(${r.out.code})" else r.out.code
			{ st: r.st, lines: ["return ${wrapped}"] }
		}
		Return(Err(Void)) => { st, lines: [if st.fails "return Ok({})" else "return {}"] }
		Break => { st, lines: ["break"] }
		Continue => { st: problem(st, "continue"), lines: [] }
		DoWhile(_, _) => { st: problem(st, "do while"), lines: [] }
		Switch(subject, cases) => switch(st, subject, cases)
	}

## Whether control never gets past `s` to the statement after it: every path
## ends in a `return` or in an error report, which the translation turns into
## one. roc warns about code after such a statement, so a block stops there.
## Loops never count, and a `switch` only with a `default` and no case that
## can `break` out of it.
leaves : CParse.Stmt -> Bool
leaves = |s|
	match s {
		Return(_) => Bool.True
		ExprStmt(Call(Ident("ereport"), [Ident("ERROR"), ..])) => Bool.True
		ExprStmt(Call(Ident("elog"), [Ident("ERROR"), ..])) => Bool.True
		ExprStmt(Call(Ident("parser_yyerror"), [_])) => Bool.True
		ExprStmt(Call(Ident("base_yyerror"), [_, _, _])) => Bool.True
		Block(items) => items.any(leaves)
		If(_, then, Ok(els)) => leaves(then) and leaves(els)
		Switch(_, cases) => cases.any(|c| c.is_default) and cases.all(|c| c.body.any(leaves) and !c.body.any(breaks))
		_ => Bool.False
	}

## Whether `s` can `break` out of the statement around it. Loops and nested
## `switch` statements keep their own.
breaks : CParse.Stmt -> Bool
breaks = |s|
	match s {
		Break => Bool.True
		Block(items) => items.any(breaks)
		If(_, then, Ok(els)) => breaks(then) or breaks(els)
		If(_, then, Err(_)) => breaks(then)
		_ => Bool.False
	}

## The list slot an expression reads, such as `lfirst(cell)` in a loop,
## `llast(list)` or `linitial(list)`, through casts: a local initialized
## from it stands for that element.
slot_of : St, CParse.Expr -> Try(Slot, [NoAlias])
slot_of = |st, e|
	match e {
		Cast(_, inner) => slot_of(st, inner)
		Call(Ident("castNode"), [_, inner]) => slot_of(st, inner)
		Call(Ident("lfirst"), [Ident(cell)]) | Call(Ident("lfirst_node"), [_, Ident(cell)]) =>
			match cell_of(st, Ident(cell)) {
				Ok(lp) =>
					match lp.list_lvalue {
						Ok(target) => Ok({ list: target, list_code: lp.list_read, index: lp.index })
						Err(_) => Err(NoAlias)
					}
				Err(_) => Err(NoAlias)
			}
		Call(Ident(name), [list]) | Call(Ident(name), [_, list]) =>
			if name == "llast" or name == "llast_node" or name == "linitial" or name == "linitial_node" or name == "lsecond" or name == "lsecond_node" {
				match lvalue(st, list) {
					Ok(target) => {
						read = retained_expr(st, list, Ok(ListPtr)).code
						index = if name.starts_with("llast") "(${read}.len() - 1)" else if name.starts_with("lsecond") "1" else "0"
						Ok({ list: target, list_code: read, index })
					}
					Err(_) => Err(NoAlias)
				}
			} else {
				Err(NoAlias)
			}
		_ => Err(NoAlias)
	}

expression_statement : St, CParse.Expr -> { st : St, lines : Lines }
expression_statement = |st, e|
	match e {
		Assign("=", Field(Call(Ident("pg_yyget_extra"), _), "parsetree"), value) => {
			r = expr(st, value, Ok(st.result_type))
			{ st: r.st, lines: ["$result = ${r.out.code}"] }
		}
		Assign("=", left, Assign(op2, mid, right)) => {
			first = expression_statement(st, Assign(op2, mid, right))
			second = expression_statement(first.st, Assign("=", left, mid))
			{ st: second.st, lines: first.lines.concat(second.lines) }
		}
		Assign(op, left, right) => assignment(st, op, left, right)
		Postfix(op, target) => assignment(st, if op == "++" "+=" else "-=", target, Num("1"))
		Prefix("++", target) => assignment(st, "+=", target, Num("1"))
		Prefix("--", target) => assignment(st, "-=", target, Num("1"))
		Cast("void", _) => { st, lines: [] }
		Call(Ident("Assert"), _) => { st, lines: [] }
		Call(Ident("ereport"), args) => ereport(st, args)
		Call(Ident("elog"), args) => elog(st, args)
		Call(Ident("parser_yyerror"), [msg]) => yyerror(st, msg)
		Call(Ident("base_yyerror"), [_, _, msg]) => yyerror(st, msg)
		Call(Ident(name), args) =>
			match st.env.sigs.get(name) {
				Ok(sig) =>
					if !sig.inout.is_empty() or !sig.outs.is_empty() {
						write_back_call(st, sig, args)
					} else {
						r = expr(st, e, Err(Any))
						{ st: r.st, lines: ["_ = ${r.out.code}"] }
					}
				Err(_) => {
					r = expr(st, e, Err(Any))
					{ st: r.st, lines: ["_ = ${r.out.code}"] }
				}
			}
		_ => {
			r = expr(st, e, Err(Any))
			{ st: r.st, lines: ["_ = ${r.out.code}"] }
		}
	}

assignment : St, Str, CParse.Expr, CParse.Expr -> { st : St, lines : Lines }
assignment = |st, op, left, right|
	match lvalue(st, left) {
		Err(_) =>
			# `linitial(list) = x`: set a list element.
			match slot_of(st, left) {
				Ok(slot) =>
					if op == "=" {
						r = expr(st, right, Ok(NodePtr("Node")))
						{ st: r.st, lines: [assign_code(slot.list, "Rt.list_set(${slot.list_code}, ${slot.index}, ${r.out.code})")] }
					} else {
						{ st: problem(st, "compound assignment to a list element"), lines: [] }
					}
				Err(_) => { st: problem(st, "assignment to something that is not a variable or field: ${CParse.show(ExprStmt(left))}"), lines: [] }
			}
		Ok(target) => {
			value_expr = if op == "=" right else Binary(op.drop_suffix("="), left, right)
			r = expr(st, value_expr, Ok(target.type))
			lines = [assign_code(target, r.out.code)]
			if target.path.is_empty() {
				# The local now points somewhere else: it no longer stands for a
				# list element (unless the new value is one), the places it was
				# stored keep the old node, and it shares the new one with where
				# the new one came from.
				{ st: record_store(rebind(r.st, target, right), target, right), lines }
			} else {
				st2 = record_store(r.st, target, right)
				match target.local {
					Ok(c) => {
						st3 = if st2.published.contains(c) problem(st2, "field written after ${c} was put in a list") else st2
						after = after_write(st3, c, [])
						{ st: after.st, lines: lines.concat(after.lines) }
					}
					Err(_) => { st: st2, lines }
				}
			}
		}
	}

## A local assigned a new value stands for the list element it reads, if
## any, and is no longer the node stored where it was stored before.
rebind : St, Target, CParse.Expr -> St
rebind = |st, target, right|
	match target.local {
		Ok(c) => {
			alias = slot_of(st, right)
			{ ..st, locals: st.locals.map(|l| if l.c == c { ..l, alias } else l), stores: st.stores.keep_if(|s| s.source != c and s.target.local != Ok(c)).concat(read_from(st, c, right)) }
		}
		Err(_) => st
	}

## `x = local`, `x->f = local` and `$$ = local`: where a local node is
## stored, so that writing through the local later can store it again, as
## the shared pointer would in C.
record_store : St, Target, CParse.Expr -> St
record_store = |st, target, right|
	match stored_local(st, right) {
		Ok(name) =>
			if target.local == Ok(name) {
				st
			} else {
				match lookup(st, name) {
					Ok(_) => { ..st, stores: st.stores.append({ source: name, target, guard: Err(Always) }) }
					Err(_) => st
				}
			}
		Err(_) => st
	}

stored_local : St, CParse.Expr -> Try(Str, [NotStored])
stored_local = |st, e|
	match e {
		Ident(name) => Ok(name)
		Field(Index(Ident("yyvsp"), k), _) => rhs_number(st, k).map_ok(|n| value_local(n)).map_err(|_| NotStored)
		Cast(_, inner) => stored_local(st, inner)
		Call(Ident("castNode"), [_, inner]) => stored_local(st, inner)
		_ => Err(NotStored)
	}

publish : St, Str -> St
publish = |st, name|
	match lookup(st, name) {
		Ok(_) => { ..st, published: st.published.append(name) }
		Err(_) => st
	}

## After a node reached through local `c` changed: put it back into the
## list element it stands for, and store it again wherever it was stored,
## following those stores in turn.
after_write : St, Str, List(Str) -> { st : St, lines : Lines }
after_write = |st, c, visited| {
	if visited.contains(c) {
		return { st, lines: [] }
	}
	seen = visited.append(c)
	match lookup(st, c) {
		Err(_) => { st, lines: [] }
		Ok(local) => {
			slot_lines =
				match local.alias {
					Ok(slot) => [assign_code(slot.list, "Rt.list_set(${slot.list_code}, ${slot.index}, $${local.roc})")]
					Err(_) => []
				}
			var $st = st
			var $lines = slot_lines
			for s in st.stores.keep_if(|x| x.source == c) {
				assign = assign_code(s.target, "$${local.roc}")
				$lines =
					match s.guard {
						Err(Always) => $lines.append(assign)
						Ok(guard) => $lines.concat(["if ${guard} {", "\t${assign}", "}"])
					}
				# The place it went into changed too, so the places that one went
				# into, in turn.
				match s.target.local {
					Ok(m) => {
						more = after_write($st, m, seen)
						$st = more.st
						$lines = $lines.concat(more.lines)
					}
					Err(_) => {}
				}
			}
			{ st: $st, lines: $lines }
		}
	}
}

## A call to a hand-ported function that writes some arguments back.
write_back_call : St, Translate.Sig, List(CParse.Expr) -> { st : St, lines : Lines }
write_back_call = |st, sig, args| {
	var $st = st
	var $codes = []
	var $i = 0
	for a in args {
		param = sig.params.get($i) ?? NodePtr("Node")
		arg_no = $i.to_u64()
		if param == Void {
			$codes = $codes.append("ctx")
		} else if sig.outs.contains(arg_no) {
			# An out-parameter: whether the caller asked for it.
			$codes = $codes.append(if is_null_literal(a) "Bool.False" else "Bool.True")
		} else {
			r = expr($st, strip_address(a), Ok(param))
			$st = r.st
			$codes = $codes.append(r.out.code)
		}
		$i = $i + 1
	}
	suffix = if sig.fails "?" else ""
	var $lines = ["written = ${sig.roc}(${Str.join_with($codes, ", ")})${suffix}"]
	var $k = 0.U64
	for a in args {
		k = $k
		if sig.inout.contains(k) or sig.outs.contains(k) {
			if !is_null_literal(a) {
				written = "written.a${k.to_str()}"
				match lvalue($st, strip_address(a)) {
					Ok(target) => {
						$lines = $lines.append(assign_code(target, written))
						# The call changed the node the argument points at: wherever
						# that node is also kept changes too.
						match target.local {
							Ok(c) => {
								after = after_write($st, c, [])
								$st = after.st
								$lines = $lines.concat(after.lines)
							}
							Err(_) => {}
						}
					}
					Err(_) =>
						match slot_of($st, strip_address(a)) {
							Ok(slot) => {
								$lines = $lines.append(assign_code(slot.list, "Rt.list_set(${slot.list_code}, ${slot.index}, ${written})"))
							}
							Err(_) => {
								$st = problem($st, "written-back argument that is neither a variable nor a list element")
							}
						}
				}
			}
		}
		$k = $k + 1
	}
	# Nothing written back when every such argument was NULL.
	final_lines = if $lines.len() == 1 [($lines.first() ?? "").replace_first("written = ", "_ = ")] else $lines
	{ st: $st, lines: final_lines }
}

strip_address : CParse.Expr -> CParse.Expr
strip_address = |e|
	match e {
		Prefix("&", inner) => inner
		_ => e
	}

## `foreach(cell, list)`, `for_each_from(cell, list, n)`, and
## `foreach_node(Type, var, list)`.
foreach : St, Str, List(CParse.Expr), CParse.Stmt -> { st : St, lines : Lines }
foreach = |st, name, args, body| {
	shape =
		if name == "foreach" {
			match args {
				[Ident(cell), list] => Ok({ cell, list, from: "0", value_var: Err(NoVar) })
				_ => Err(BadForeach)
			}
		} else if name == "for_each_from" {
			match args {
				[Ident(cell), list, Num(n)] => Ok({ cell, list, from: n, value_var: Err(NoVar) })
				_ => Err(BadForeach)
			}
		} else if name == "foreach_node" or name == "foreach_ptr" {
			match args {
				[Ident(type), Ident(var_name), list] => Ok({ cell: "${var_name}__cell", list, from: "0", value_var: Ok((type, var_name)) })
				_ => Err(BadForeach)
			}
		} else {
			Err(BadForeach)
		}
	match shape {
		Err(_) => { st: problem(st, "loop macro ${name}"), lines: [] }
		Ok(sh) => {
			rl = expr(st, sh.list, Ok(ListPtr))
			idx = fresh(rl.st, "${sh.cell}_index")
			list_var = fresh(idx.st, "${sh.cell}_list")
			list_lvalue = lvalue(list_var.st, sh.list)
			loop_entry = { cell: sh.cell, index: "$${idx.roc}", list: "$${list_var.roc}", list_read: rl.out.code, list_lvalue, list_type: ListPtr }
			st_in = { ..list_var.st, loops: list_var.st.loops.append(loop_entry) }
			var $st_body = st_in
			var $pre = []
			match sh.value_var {
				Ok((type, var_name)) => {
					named = fresh($st_body, var_name)
					alias =
						match list_lvalue {
							Ok(target) => Ok({ list: target, list_code: rl.out.code, index: loop_entry.index })
							Err(_) => Err(NoAlias)
						}
					$st_body = { ..named.st, locals: named.st.locals.append({ c: var_name, roc: named.roc, type: NodePtr(type), alias }) }
					$pre = ["var $${named.roc} = (${loop_entry.list}.get(${loop_entry.index}) ?? Null)"]
				}
				Err(_) => {}
			}
			rb = stmt($st_body, body)
			lines = [
				"var ${loop_entry.list} = ${rl.out.code}",
				"var ${loop_entry.index} = ${sh.from}",
				"while ${loop_entry.index} < ${loop_entry.list}.len() {",
			].concat(indent($pre.concat(rb.lines).append("${loop_entry.index} = ${loop_entry.index} + 1"))).append("}")
			{ st: { ..rb.st, loops: st.loops, locals: st.locals }, lines }
		}
	}
}

## `switch` over constants or over `nodeTag(x)`, each case ending in `break`
## or `return`.
switch : St, CParse.Expr, List({ labels : List(CParse.Expr), is_default : Bool, body : List(CParse.Stmt) }) -> { st : St, lines : Lines }
switch = |st, subject, cases| {
	rs = expr(st, subject, Err(Any))
	var $st = rs.st
	var $lines = ["match ${rs.out.code} {"]
	var $default_lines = ["\t_ => {}"]
	for c in cases {
		body = c.body.keep_if(|s| !is_break(s))
		# Cases for node types the parser never makes cannot match.
		labels = c.labels.keep_if(|label| label_reachable($st, label))
		if c.is_default {
			r = stmt($st, Block(body))
			$st = r.st
			$default_lines = ["\t_ => {"].concat(indent(indent(r.lines))).append("\t}")
		} else if !labels.is_empty() {
			pats = labels.map(|label| label_pattern($st, label))
			r = stmt($st, Block(body))
			$st = r.st
			$lines = $lines.append("\t${Str.join_with(pats, " | ")} => {").concat(indent(indent(r.lines))).append("\t}")
		}
	}
	{ st: $st, lines: $lines.concat($default_lines).append("}") }
}

## A case label that can match: not a node type the parser never makes.
label_reachable : St, CParse.Expr -> Bool
label_reachable = |st, label|
	match label {
		Ident(name) =>
			if name.starts_with("T_") {
				type = Str.from_utf8_lossy(name.to_utf8().drop_first(2))
				type == "List" or st.env.node_types.contains(type)
			} else {
				Bool.True
			}
		_ => Bool.True
	}

label_pattern : St, CParse.Expr -> Str
label_pattern = |st, label|
	match label {
		Ident(name) =>
			if name.starts_with("T_") {
				"\"${Str.from_utf8_lossy(name.to_utf8().drop_first(2))}\""
			} else {
				match Consts.resolve(st.env.consts, name) {
					Ok(Int(n)) => n.to_str()
					_ => "_"
				}
			}
		CharLit(c) => c.to_str()
		Num(n) => n
		_ => "_"
	}

## ---- errors ----

## `ereport(ERROR, errcode(...), errmsg(...), parser_errposition(loc))`.
ereport : St, List(CParse.Expr) -> { st : St, lines : Lines }
ereport = |st, args|
	match args {
		[Ident(level), .. as rest] =>
			if level != "ERROR" {
				{ st, lines: [] }
			} else {
				parts =
					match rest {
						[Comma(items)] => items
						_ => rest
					}
				var $code = "XX000"
				var $message = Ok({ code: "Ok(\"\")", type: CharPtr })
				var $position = "(0 - 1)"
				var $st = st
				for p in parts {
					match p {
						Call(Ident("errcode"), [Ident(errcode)]) => {
							$code = st.env.errcodes.get(errcode) ?? "XX000"
						}
						Call(Ident("errmsg"), fargs) | Call(Ident("errmsg_internal"), fargs) => {
							r = format($st, fargs)
							$st = r.st
							$message = Ok(r.out)
						}
						Call(Ident("parser_errposition"), [loc]) | Call(Ident("scanner_errposition"), [loc, _]) => {
							r = expr($st, loc, Ok(Int))
							$st = r.st
							$position = r.out.code
						}
						_ => {}
					}
				}
				msg = ($message ?? { code: "Ok(\"\")", type: CharPtr }).code
				if !$st.fails {
					$st = problem($st, "an error raised in a function that cannot fail")
				}
				{ st: $st, lines: ["return Err(Rt.error(ctx, \"${$code}\", ${msg}, ${$position}))"] }
			}
		_ => { st: problem(st, "ereport without a level"), lines: [] }
	}

elog : St, List(CParse.Expr) -> { st : St, lines : Lines }
elog = |st, args|
	match args {
		[Ident("ERROR"), .. as rest] => {
			r = format(st, rest)
			{ st: r.st, lines: ["return Err(Rt.error(ctx, \"XX000\", ${r.out.code}, (0 - 1)))"] }
		}
		_ => { st, lines: [] }
	}

## `parser_yyerror("msg")`: the message at or near the last token read.
yyerror : St, CParse.Expr -> { st : St, lines : Lines }
yyerror = |st, msg| {
	r = expr(st, msg, Ok(CharPtr))
	{ st: r.st, lines: ["return Err(Rt.yyerror(ctx, ${r.out.code}))"] }
}

## ---- actions and functions ----

translate_action : Translate.Env, U64, U64, Str, CParse.Stmt -> Translate.Output
translate_action = |env, rule, len, rule_text, body| {
	t = translate_action_body(env, rule, len, rule_text, body, Bool.False)
	{ code: "## ${rule_text}\nrule_${rule.to_str()} : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)\nrule_${rule.to_str()} = |${Str.join_with(t.params, ", ")}| ${t.body}", problems: t.problems }
}

translate_action_body : Translate.Env, U64, U64, Str, CParse.Stmt, Bool -> Translate.ActionTemplate
translate_action_body = |env, rule, len, rule_text, body, parameterize| {
	code_text = CParse.show(body)
	result_member = member_of(code_text, "yyval.")
	result_type = env.members.get(result_member) ?? NodePtr("Node")
	st0 = {
		env,
		locals: numbers_to(len).map(|n| { c: value_local(n.to_i64_wrap()), roc: "a${n.to_str()}", type: NodePtr("Node"), alias: Err(NoAlias) }),
		names: ["result", "ctx", "v", "l", "loc", "written"],
		loops: [],
		problems: [],
		where_: "rule ${rule.to_str()} (${rule_text})",
		fails: Bool.True,
		kind: Action({ len: len }),
		published: [],
		stores: [],
		result_type,
		parameterize,
		literals: [],
	}
	r = stmt(st0, body)
	# The values and locations the action uses.
	uses = numbers_to(len).keep_if(|n| code_text.contains("(index yyvsp ${offset_text(n, len)})") or code_text.contains("(index yylsp ${offset_text(n, len)})"))
	value_lines = uses.keep_if(|n| code_text.contains("(index yyvsp ${offset_text(n, len)})")).map(
		|n| {
			member = member_of_rhs(code_text, offset_text(n, len))
			t = env.members.get(member) ?? NodePtr("Node")
			"var $a${n.to_str()} = Rt.${unwrap_fn(t)}(v, ${(n - 1).to_str()})"
		},
	)
	location_lines = uses.keep_if(|n| code_text.contains("(index yylsp ${offset_text(n, len)})")).map(|n| "l${n.to_str()} = Rt.location(l, ${(n - 1).to_str()})")
	result_init =
		if len > 0 and code_text.contains("yyval") {
			"var $result = Rt.${unwrap_fn(result_type)}(v, 0)"
		} else {
			"var $result = ${zero(result_type)}"
		}
	# An action that always fails ends in its error, not in its result.
	tail = if leaves(body) (tail_value(r.lines) ?? r.lines) else r.lines.append("Ok(Rt.${wrap_fn(result_type)}($result))")
	tail_text = Str.join_with(tail, "\n")
	used = |lines| lines.keep_if(|line| uses_word(tail_text, (line.split_first(" = ").map_ok(|s| s.before) ?? "").drop_prefix("var ")))
	body_lines = used(value_lines).concat(used(location_lines)).concat(used([result_init])).concat(tail)
	body_text = Str.join_with(body_lines, "\n")
	param = |name| if uses_word(body_text, name) name else "_${name}"
	params = ["ctx", "v", "l", "loc"].map(param).concat(r.st.literals.map(|literal| param(literal.name)))
	{
		params,
		body: Str.join_with(["{"].concat(indent(CleanLocals.with_names(body_lines, params))).append("}"), "\n"),
		args: r.st.literals.map(|literal| literal.code),
		problems: r.st.problems,
	}
}

offset_text : U64, U64 -> Str
offset_text = |n, len| {
	offset = n.to_i64_wrap() - len.to_i64_wrap()
	if offset < 0 "(- ${(0 - offset).to_str()})" else offset.to_str()
}

## The union member after `prefix` in the S-expression of an action, such
## as `node` in `(. yyval node)`.
member_of : Str, Str -> Str
member_of = |code_text, _prefix|
	match code_text.split_first("(. yyval ") {
		Ok({ after, .. }) => after.split_first(")").map_ok(|s| s.before) ?? "node"
		Err(_) => "node"
	}

member_of_rhs : Str, Str -> Str
member_of_rhs = |code_text, offset|
	match code_text.split_first("(. (index yyvsp ${offset}) ") {
		Ok({ after, .. }) => after.split_first(")").map_ok(|s| s.before) ?? "node"
		Err(_) => "node"
	}

unwrap_fn : Translate.CType -> Str
unwrap_fn = |t|
	match t {
		NodePtr(_) => "node_at"
		ListPtr => "list_at"
		CharPtr => "text_at"
		Int => "int_at"
		Boolean => "bool_at"
		_ => "node_at"
	}

wrap_fn : Translate.CType -> Str
wrap_fn = |t|
	match t {
		NodePtr(_) => "of_node"
		ListPtr => "of_list"
		CharPtr => "of_text"
		Int => "of_int"
		Boolean => "of_bool"
		_ => "of_node"
	}

translate_function : Translate.Env, CParse.Func, Translate.Sig -> Translate.Output
translate_function = |env, func, sig| {
	param_types = func.params.map(|p| ctype_of(p.type))
	st0 = {
		env,
		locals: [],
		names: ["ctx", "written"],
		loops: [],
		problems: [],
		where_: "function ${func.name}",
		fails: sig.fails,
		kind: Function,
		published: [],
		stores: [],
		result_type: sig.returns,
		parameterize: Bool.False,
		literals: [],
	}
	var $st = st0
	var $params = []
	var $copies = []
	var $i = 0
	for p in func.params {
		t = param_types.get($i) ?? NodePtr("Node")
		if t == Void or p.type.contains("core_yyscan_t") {
			$params = $params.append("ctx")
		} else {
			named = fresh($st, p.name)
			$st = { ..named.st, locals: named.st.locals.append({ c: p.name, roc: named.roc, type: t, alias: Err(NoAlias) }) }
			$params = $params.append("${named.roc}_arg")
			$copies = $copies.append("var $${named.roc} = ${named.roc}_arg")
		}
		$i = $i + 1
	}
	r = stmt($st, func.body)
	ret = if sig.fails "Try(${roc_type(sig.returns)}, Scan.Problem)" else roc_type(sig.returns)
	has_scanner = func.params.any(|p| p.type.contains("core_yyscan_t"))
	param_sig_c = func.params.map(|p| if p.type.contains("core_yyscan_t") "Rt.Ctx" else roc_type(ctype_of(p.type)))
	param_sig = if sig.fails and !has_scanner param_sig_c.append("Rt.Ctx") else param_sig_c
	all_params = if sig.fails and !has_scanner $params.append("ctx") else $params
	body_text = Str.join_with(r.lines, "\n")
	# Parameters the body never uses get no copy, and an underscore.
	used_params = all_params.map(|p| if p == "ctx" { if uses_word(body_text, "ctx") p else "_ctx" } else if uses_word(body_text, "\$${p.drop_suffix("_arg")}") p else "_${p}")
	used_copies = $copies.keep_if(|c| uses_word(body_text, (c.split_first(" = ").map_ok(|s| s.before) ?? "").drop_prefix("var ")))
	tail =
		match tail_value(r.lines) {
			Ok(lines) => lines
			Err(_) =>
				if !leaves(func.body) and (sig.returns == Void or r.lines.is_empty()) {
					r.lines.append(if sig.fails "Ok({})" else "{}")
				} else {
					r.lines
				}
		}
	lines = ["${sig.roc} : ${Str.join_with(param_sig, ", ")} -> ${ret}", "${sig.roc} = |${Str.join_with(used_params, ", ")}| {"]
		.concat(indent(CleanLocals.with_names(used_copies.concat(tail), used_params)))
		.append("}")
	{ code: Str.join_with(lines, "\n"), problems: r.st.problems }
}

## The lines with their final `return` dropped, also through a trailing
## `if`/`else` or `match` whose every branch ends in one. roc warns about a
## `return` that is already the function's final expression.
tail_value : Lines -> Try(Lines, [NotReturning])
tail_value = |lines| {
	last = lines.last() ? |_| NotReturning
	if last.starts_with("return ") {
		return Ok(lines.drop_last(1).append(last.drop_prefix("return ")))
	}
	if last != "}" {
		return Err(NotReturning)
	}
	# The block's own lines are the only unindented ones in it.
	var $else_at = lines.len()
	var $if_at = lines.len()
	var $i = lines.len() - 1
	while $i > 0 and $if_at == lines.len() {
		$i = $i - 1
		line = lines.get($i) ?? ""
		if !line.starts_with("\t") {
			if line == "} else {" and $else_at == lines.len() {
				$else_at = $i
			} else if line.starts_with("if ") and $else_at < lines.len() {
				$if_at = $i
			} else if line.starts_with("match ") and $else_at == lines.len() {
				return match_tail(lines, $i)
			} else {
				return Err(NotReturning)
			}
		}
	}
	if $if_at == lines.len() {
		return Err(NotReturning)
	}
	unindent = |ls| ls.map(|l| l.drop_prefix("\t"))
	then_lines = tail_value(unindent(lines.sublist({ start: $if_at + 1, len: $else_at - $if_at - 1 })))?
	else_lines = tail_value(unindent(lines.sublist({ start: $else_at + 1, len: lines.len() - $else_at - 2 })))?
	Ok(lines.sublist({ start: 0, len: $if_at + 1 }).concat(indent(then_lines)).append("} else {").concat(indent(else_lines)).append("}"))
}

## The trailing `match` that starts at `start`, the final `return` of each
## arm dropped. An arm is `\tpattern => {`, its lines, then `\t}`.
match_tail : Lines, U64 -> Try(Lines, [NotReturning])
match_tail = |lines, start| {
	var $out = lines.take_first(start + 1)
	var $arm = []
	for line in lines.sublist({ start: start + 1, len: lines.len() - start - 2 }) {
		if line.starts_with("\t\t") {
			$arm = $arm.append(line.drop_prefix("\t\t"))
		} else if line == "\t}" {
			$out = $out.concat(indent(indent(tail_value($arm)?))).append(line)
			$arm = []
		} else if line.starts_with("\t") and line.ends_with(" => {") {
			$out = $out.append(line)
		} else {
			return Err(NotReturning)
		}
	}
	Ok($out.append("}"))
}

publish_arg : St, CParse.Expr -> St
publish_arg = |st, a|
	match stored_local(st, a) {
		Ok(n) => publish(st, n)
		Err(_) => st
	}

## 1 up to `n`.
numbers_to : U64 -> List(U64)
numbers_to = |n| {
	var $out = []
	var $i = 1
	while $i <= n {
		$out = $out.append($i)
		$i = $i + 1
	}
	$out
}

is_break : CParse.Stmt -> Bool
is_break = |s|
	match s {
		Break => Bool.True
		_ => Bool.False
	}

## Whether `word` occurs in `text` as a whole name, not inside a longer one.
uses_word : Str, Str -> Bool
uses_word = |text, word| {
	bytes = text.to_utf8()
	w = word.to_utf8()
	var $i = 0
	var $found = Bool.False
	while !$found and $i + w.len() <= bytes.len() {
		if bytes.sublist({ start: $i, len: w.len() }) == w {
			before = if $i == 0 ' ' else bytes.get($i - 1) ?? ' '
			after = bytes.get($i + w.len()) ?? ' '
			if !is_name_char(before) and !is_name_char(after) {
				$found = Bool.True
			}
		}
		$i = $i + 1
	}
	$found
}

is_name_char : U8 -> Bool
is_name_char = |c| (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (c >= '0' and c <= '9') or c == '_' or c == '$'

## A store whose local and target local are both declared in `locals`.
store_in_scope : List(Local), Store -> Bool
store_in_scope = |locals, store| {
	source_in = locals.any(|l| l.c == store.source)
	target_in =
		match store.target.local {
			Ok(c) => locals.any(|l| l.c == c)
			Err(_) => Bool.True
		}
	source_in and target_in
}

## The name `$n` goes by among the locals, so that it is tracked like one:
## where it is stored, and what a write through it must update.
value_local : I64 -> Str
value_local = |n| "$${n.to_str()}"

## A local set to a node that is kept somewhere else too, such as
## `n = $1` or `n = $1->constructor`: that place shares the node, so a
## write through the local must store it there again. A choice between two
## places, `c ? a->f : b->g`, stores it under a guard.
read_from : St, Str, CParse.Expr -> List(Store)
read_from = |st, c, e|
	match e {
		Cast(_, inner) => read_from(st, c, inner)
		Call(Ident("castNode"), [_, inner]) => read_from(st, c, inner)
		Ident(_) | Field(_, _) =>
			match lvalue(st, e) {
				Ok(target) =>
					match (target.local, target.type) {
						(Ok(other), NodePtr(_)) => if other == c [] else [{ source: c, target, guard: Err(Always) }]
						_ => []
					}
				Err(_) => []
			}
		Cond(test, a, b) => {
			code = retained_expr(st, test, Ok(Boolean)).code
			yes = read_from(st, c, a).map(|s| { ..s, guard: Ok(code) })
			no = read_from(st, c, b).map(|s| { ..s, guard: Ok("!(${code})") })
			yes.concat(no)
		}
		_ => []
	}
