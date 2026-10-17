## Exercise optimization through the real C parser and translation/writeback
## pipeline, including the barriers that prevent observable reordering.
import CParse
import Translate

expect {
	r = translation("{ return NULL; }")
	r.problems.is_empty() and r.code.contains("Null") and !r.code.contains("Node.null")
}

translation : Str -> Translate.Output
translation = |source| {
	env = {
		consts: { defines: Dict.empty(), enums: Dict.empty() },
		errcodes: Dict.empty(),
		structs: Dict.from_list([
			("N", [{ name: "x", type: "int", attrs: [] }, { name: "y", type: "int", attrs: [] }, { name: "child", type: "Node *", attrs: [] }]),
			("M", [{ name: "x", type: "int", attrs: [] }]),
		]),
		sigs: Dict.from_list([
			("effect", { roc: "effect", params: [], returns: Int, fails: Bool.True, inout: [], outs: [] }),
			("observe", { roc: "observe", params: [NodePtr("N")], returns: Void, fails: Bool.False, inout: [], outs: [] }),
			("mutate", { roc: "mutate", params: [NodePtr("N")], returns: Void, fails: Bool.False, inout: [0], outs: [] }),
		]),
		members: Dict.empty(),
		node_types: ["N", "M"],
	}
	body = CParse.statement(source) ?? Empty
	Translate.function(env, { name: "test", params: [{ name: "n", type: "N *" }, { name: "v", type: "int" }], returns: "N *", body }, { roc: "test", params: [NodePtr("N"), Int], returns: NodePtr("N"), fails: Bool.True, inout: [], outs: [] })
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = v; p->y = 2; return p; }")
	r.problems.is_empty() and r.code.contains("p = Node.N({ ..Node.n_default, x: v_arg, y: 2 })") and !r.code.contains("var $")
}

expect {
	r = translation("{ n->x = v; n->y = 2; return n; }")
	r.problems.is_empty() and r.code.contains("$n = Node.N({ ..Node.n_of($n), x: v_arg, y: 2 })")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = effect(); p->y = 2; return p; }")
	r.problems.is_empty() and r.code.split_on("Node.N(").len() == 4
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; p->y = p->x; return p; }")
	r.problems.is_empty() and r.code.split_on("Node.N(").len() == 3 and r.code.contains("Node.n_of($p).x")
}

expect {
	r = translation("{ N *p = makeNode(N); N *q = p; p->x = 1; p->y = 2; return q; }")
	r.problems.is_empty() and !r.code.contains("x: 1, y: 2") and r.code.split_on("Node.N(").len() == 4
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; observe(p); p->y = 2; return p; }")
	r.problems.is_empty() and r.code.split_on("Node.N(").len() == 3 and !r.code.contains("x: 1, y: 2")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; if (v) p->y = 2; return p; }")
	r.problems.is_empty() and r.code.contains("var $p") and !r.code.contains("x: 1, y: 2")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; mutate(&p); p->y = 2; return p; }")
	r.problems.is_empty() and r.code.contains("$p = written.a0") and !r.code.contains("x: 1, y: 2")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; ((M *)p)->x = 2; return p; }")
	r.problems.is_empty() and r.code.contains("Node.M({ ..Node.m_of($p), x: 2 })")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; p->x = 2; return p; }")
	r.problems.is_empty() and r.code.split_on("Node.N(").len() == 3
}

expect {
	r = translation("{ N *p = makeNode(N); p->child = n; p->x = v; p->y = 2; return p; }")
	r.problems.is_empty() and r.code.split_on("Node.N(").len() == 2 and r.code.contains("child: n_arg, x: v_arg, y: 2")
}

expect {
	r = translation("{ N *p = makeNode(N); p->x = 1; while (v) { p->y = 2; v--; } return p; }")
	r.problems.is_empty() and r.code.contains("var $p") and !r.code.contains("x: 1, y: 2")
}

expect {
	r = translation("{ N *p = makeNode(N); N *q = p; q->x = 1; q->y = 2; return p; }")
	r.problems.is_empty() and !r.code.contains("x: 1, y: 2") and r.code.contains("$p = $q")
}

# Code after an error report never runs, and roc warns about it. The error
# becomes the final value.
expect {
	r = translation("{ if (v) return n; ereport(ERROR, (errmsg(\"no\"))); return NULL; }")
	r.problems.is_empty() and r.code.contains("\tErr(Rt.error(ctx, \"XX000\", Ok(\"no\"), (0 - 1)))\n}") and !r.code.contains("Ok(Null)")
}

# A switch whose every case leaves, default included, ends the function.
expect {
	r = translation("{ switch (v) { case 1: return n; default: ereport(ERROR, (errmsg(\"no\"))); } return NULL; }")
	r.problems.is_empty() and !r.code.contains("return ") and r.code.contains("\t\tOk(n_arg)\n") and !r.code.contains("Ok(Null)")
}

# A case that breaks, or a missing default, lets control reach the code after.
expect {
	r = translation("{ switch (v) { case 1: if (v) break; return n; default: return n; } return NULL; }")
	r.problems.is_empty() and r.code.contains("return Ok(n_arg)") and r.code.contains("\tOk(Null)\n}")
}

expect {
	r = translation("{ switch (v) { case 1: return n; } return NULL; }")
	r.problems.is_empty() and r.code.contains("return Ok(n_arg)") and r.code.contains("\tOk(Null)\n}")
}
