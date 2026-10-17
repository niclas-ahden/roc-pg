## Regression tests for typed action sharing, from C source through lowering
## and dispatch generation. These do not depend on the Postgres source tree.
import CParse
import Consts
import Translate
import RuleBodies

env : Translate.Env
env = {
	consts: Consts.collect(["#define FIRST 11\n#define SECOND 22\n#define T_PLAssignStmt 7\n"]),
	errcodes: Dict.empty(),
	structs: Dict.from_list([("PLAssignStmt", [{ name: "nnames", type: "int", attrs: [] }])]),
	sigs: Dict.empty(),
	members: Dict.from_list([("ival", Int), ("boolean", Boolean), ("str", CharPtr), ("node", NodePtr("Node"))]),
	node_types: ["PLAssignStmt"],
}

template : Str -> Translate.ActionTemplate
template = |source|
	match CParse.statement(source) {
		Ok(body) => Translate.action_template(env, 5, 2, "test: TOKEN value", body)
		Err(message) => crash message
	}

shared : Translate.ActionTemplate, Translate.ActionTemplate -> RuleBodies.State
shared = |a, b| RuleBodies.add(RuleBodies.add(RuleBodies.empty({}), 5, "first", a), 6, "second", b)

expect {
	a = template("{ yyval.ival = FIRST; }")
	b = template("{ yyval.ival = SECOND; }")
	a.problems.is_empty() and b.problems.is_empty() and a.args == ["11"] and b.args == ["22"] and shared(a, b).code.len() == 1
}

expect {
	a = template("{ int FIRST = 3; yyval.ival = FIRST; }")
	a.problems.is_empty() and a.args == ["3"]
}

expect {
	a = template("{ yyval.ival = 'a'; }")
	b = template("{ yyval.ival = 'b'; }")
	a.args == ["97"] and b.args == ["98"] and shared(a, b).code.len() == 1
}

expect {
	a = template("{ yyval.ival = T_PLAssignStmt; }")
	a.args.is_empty()
}

# Conditional aliases are lowered once as values and again as saved guards.
# The saved guard must not capture the later `nnames` argument.
expect {
	body = CParse.statement("{ PLAssignStmt *p = yyvsp[0].ival == 1 ? (PLAssignStmt *) yyvsp[-1].node : (PLAssignStmt *) yyvsp[-2].node; p->nnames = 7; yyval.node = yyvsp[-1].node; }") ?? Empty
	a = Translate.action_template(env, 5, 3, "conditional alias", body)
	a.problems.is_empty() and a.args == ["1", "7"] and a.body.contains(" == 1)") and !a.body.contains(" == literal_1")
}

# The motivating grammar rules differ only in the nnames field.
expect {
	a = template("{ PLAssignStmt *n = (PLAssignStmt *) yyvsp[0].node; n->nnames = 1; yyval.node = (Node *) n; }")
	b = template("{ PLAssignStmt *n = (PLAssignStmt *) yyvsp[0].node; n->nnames = 2; yyval.node = (Node *) n; }")
	a.problems.is_empty() and b.problems.is_empty() and a.args == ["1"] and b.args == ["2"] and shared(a, b).code.len() == 1
}

# Repeated equal literals still occupy separate positions: neither position
# may accidentally receive the other's value in a later rule.
expect {
	a = template("{ int first = 1; int second = 1; yyval.ival = first + second; }")
	b = template("{ int first = 2; int second = 3; yyval.ival = first + second; }")
	a.problems.is_empty() and b.problems.is_empty() and a.args == ["1", "1"] and b.args == ["2", "3"] and shared(a, b).code.len() == 1
}

expect {
	a = template("{ yyval.str = \"number 1 and name_2\"; }")
	b = template("{ yyval.str = \"number 2 and name_2\"; }")
	a.args.is_empty() and b.args.is_empty() and shared(a, b).code.len() == 2
}

# Different bindings and their types remain in the template.
expect {
	a = template("{ int value_1 = 1; yyval.ival = value_1; }")
	b = template("{ int value_2 = 1; yyval.ival = value_2; }")
	shared(a, b).code.len() == 2
}

expect {
	a = template("{ int value = 1; yyval.ival = value; }")
	b = template("{ bool value = 1; yyval.ival = value; }")
	a.args == ["1"] and b.args.is_empty() and shared(a, b).code.len() == 2
}

# Extracting pure literals from branches is safe, but extracting or merging
# the branches themselves is not.
expect {
	a = template("{ if (yyvsp[0].boolean) yyval.ival = 1; else yyval.ival = 2; }")
	b = template("{ if (yyvsp[0].boolean) yyval.ival = 3; else yyval.ival = 4; }")
	a.args == ["1", "2"] and b.args == ["3", "4"] and shared(a, b).code.len() == 1
}

expect {
	a = template("{ if (yyvsp[0].boolean) yyval.ival = 1; }")
	b = template("{ while (yyvsp[0].boolean) yyval.ival = 1; }")
	shared(a, b).code.len() == 2
}

# Literal switch labels are patterns, not runtime I64 arguments.
expect {
	a = template("{ switch (yyvsp[0].ival) { case 1: yyval.ival = 7; break; default: yyval.ival = 8; } }")
	b = template("{ switch (yyvsp[0].ival) { case 2: yyval.ival = 7; break; default: yyval.ival = 8; } }")
	a.args == ["7", "8"] and b.args == ["7", "8"] and shared(a, b).code.len() == 2
}

# Parameter names cannot capture C locals, including locals declared later.
expect {
	a = template("{ int literal_0 = 1; int later = 2; yyval.ival = literal_0 + later; }")
	a.problems.is_empty() and a.params.contains("literal_0_2") and a.body.contains("literal_0 = literal_0_2")
}

# Boolean and pointer-context numbers are deliberately not I64 slots.
expect {
	a = template("{ yyval.boolean = 1; yyval.node = (Node *) 0; }")
	a.args.is_empty()
}

# Source spelling is normalized only by the C number parser.
expect {
	a = template("{ yyval.ival = 0x2a; }")
	b = template("{ yyval.ival = 42; }")
	a.args == ["42"] and b.args == ["42"] and shared(a, b).code.len() == 1
}

# Stack offsets are structural: shifting an RHS read cannot become an
# integer value parameter and accidentally share a different binding.
expect {
	a = template("{ yyval.ival = yyvsp[0].ival; }")
	b = template("{ yyval.ival = yyvsp[-1].ival; }")
	a.args.is_empty() and b.args.is_empty() and shared(a, b).code.len() == 2
}

# The slots' positions are unchanged across arithmetic and signed literals.
expect {
	a = template("{ yyval.ival = -1; }")
	b = template("{ yyval.ival = -2; }")
	a.args == ["1"] and b.args == ["2"] and shared(a, b).code.len() == 1
}

# The original non-template API remains available to callers that need an
# ordinary rule; it cannot accidentally refer to template parameters.
expect {
	match CParse.statement("{ yyval.ival = 42; }") {
		Ok(body) => {
			out = Translate.action(env, 5, 2, "first", body)
			out.problems.is_empty() and out.code.contains("$result = 42") and !out.code.contains("literal_")
		}
		Err(_) => Bool.False
	}
}

# An action that always fails ends in its error: no result, and no literal
# slots for the code after the error that never runs.
expect {
	a = template("{ ereport(ERROR, (errmsg(\"no\"))); yyval.ival = FIRST; }")
	a.problems.is_empty() and a.args.is_empty() and !a.body.contains("result") and !a.body.contains("return ") and a.body.contains("\tErr(Rt.error(ctx, \"XX000\", Ok(\"no\"), (0 - 1)))\n}")
}
