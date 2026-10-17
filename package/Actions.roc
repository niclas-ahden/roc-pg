# Derived from PostgreSQL 18.6, src/backend/parser/gram.y and the node
# headers and functions it uses.
#
# PostgreSQL Database Management System
# (also known as Postgres, formerly known as Postgres95)
#
# Portions Copyright (c) 1996-2026, PostgreSQL Global Development Group
#
# Portions Copyright (c) 1994, The Regents of the University of California
#
# Permission to use, copy, modify, and distribute this software and its
# documentation for any purpose, without fee, and without a written agreement
# is hereby granted, provided that the above copyright notice and this
# paragraph and the following two paragraphs appear in all copies.
#
# IN NO EVENT SHALL THE UNIVERSITY OF CALIFORNIA BE LIABLE TO ANY PARTY FOR
# DIRECT, INDIRECT, SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING
# LOST PROFITS, ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS
# DOCUMENTATION, EVEN IF THE UNIVERSITY OF CALIFORNIA HAS BEEN ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
#
# THE UNIVERSITY OF CALIFORNIA SPECIFICALLY DISCLAIMS ANY WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
# AND FITNESS FOR A PARTICULAR PURPOSE.  THE SOFTWARE PROVIDED HEREUNDER IS
# ON AN "AS IS" BASIS, AND THE UNIVERSITY OF CALIFORNIA HAS NO OBLIGATIONS TO
# PROVIDE MAINTENANCE, SUPPORT, UPDATES, ENHANCEMENTS, OR MODIFICATIONS.

## Postgres 18.6's grammar actions, sharing identical typed bodies from
## `src/backend/parser/gram.y`, and the helper functions they call,
## translated from C by `tools/actions.roc`. Do not edit: change the
## translator, or `tools/actions_hand.roc` for the helpers ported by hand.
import Node
import Rt
import Scan

Actions :: [].{
	## Run the action of rule `rule` on the values and locations of its
	## right-hand side. `loc` is the rule's own location.
	run : U64, Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
	run = |rule, ctx, v, l, loc|
		match rule {
			# parse_toplevel: stmtmulti
			2 => rule_2(ctx, v, l, loc)
			# parse_toplevel: MODE_TYPE_NAME Typename
			3 => rule_3(ctx, v, l, loc)
			# parse_toplevel: MODE_PLPGSQL_EXPR PLpgSQL_Expr
			4 => rule_4(ctx, v, l, loc)
			# parse_toplevel: MODE_PLPGSQL_ASSIGN1 PLAssignStmt
			5 => rule_5(ctx, v, l, loc, 1)
			# parse_toplevel: MODE_PLPGSQL_ASSIGN2 PLAssignStmt
			6 => rule_5(ctx, v, l, loc, 2)
			# parse_toplevel: MODE_PLPGSQL_ASSIGN3 PLAssignStmt
			7 => rule_5(ctx, v, l, loc, 3)
			# stmtmulti: stmtmulti ';' toplevel_stmt
			8 => rule_8(ctx, v, l, loc)
			# stmtmulti: toplevel_stmt
			9 => rule_9(ctx, v, l, loc)
			# stmt: %empty
			136 => rule_136(ctx, v, l, loc)
			# opt_single_name: ColId
			137 => rule_137(ctx, v, l, loc)
			# opt_single_name: %empty
			138 => rule_138(ctx, v, l, loc)
			# opt_qualified_name: any_name
			139 => rule_139(ctx, v, l, loc)
			# opt_qualified_name: %empty
			140 => rule_140(ctx, v, l, loc)
			# opt_concurrently: CONCURRENTLY
			141 => rule_141(ctx, v, l, loc)
			# opt_concurrently: %empty
			142 => rule_142(ctx, v, l, loc)
			# opt_drop_behavior: CASCADE
			143 => rule_143(ctx, v, l, loc, 1)
			# opt_drop_behavior: RESTRICT
			144 => rule_143(ctx, v, l, loc, 0)
			# opt_drop_behavior: %empty
			145 => rule_145(ctx, v, l, loc, 0)
			# CallStmt: CALL func_application
			146 => rule_146(ctx, v, l, loc)
			# CreateRoleStmt: CREATE ROLE RoleId opt_with OptRoleList
			147 => rule_147(ctx, v, l, loc, 0)
			# OptRoleList: OptRoleList CreateOptRoleElem
			151 => rule_151(ctx, v, l, loc)
			# OptRoleList: %empty
			152 => rule_140(ctx, v, l, loc)
			# AlterOptRoleList: AlterOptRoleList AlterOptRoleElem
			153 => rule_151(ctx, v, l, loc)
			# AlterOptRoleList: %empty
			154 => rule_140(ctx, v, l, loc)
			# AlterOptRoleElem: PASSWORD Sconst
			155 => rule_155(ctx, v, l, loc)
			# AlterOptRoleElem: PASSWORD NULL_P
			156 => rule_156(ctx, v, l, loc)
			# AlterOptRoleElem: ENCRYPTED PASSWORD Sconst
			157 => rule_157(ctx, v, l, loc)
			# AlterOptRoleElem: UNENCRYPTED PASSWORD Sconst
			158 => rule_158(ctx, v, l, loc)
			# AlterOptRoleElem: INHERIT
			159 => rule_159(ctx, v, l, loc)
			# AlterOptRoleElem: CONNECTION LIMIT SignedIconst
			160 => rule_160(ctx, v, l, loc)
			# AlterOptRoleElem: VALID UNTIL Sconst
			161 => rule_161(ctx, v, l, loc)
			# AlterOptRoleElem: USER role_list
			162 => rule_162(ctx, v, l, loc)
			# AlterOptRoleElem: IDENT
			163 => rule_163(ctx, v, l, loc, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
			# CreateOptRoleElem: AlterOptRoleElem
			164 => rule_164(ctx, v, l, loc)
			# CreateOptRoleElem: SYSID Iconst
			165 => rule_165(ctx, v, l, loc)
			# CreateOptRoleElem: ADMIN role_list
			166 => rule_166(ctx, v, l, loc)
			# CreateOptRoleElem: ROLE role_list
			167 => rule_162(ctx, v, l, loc)
			# CreateOptRoleElem: IN_P ROLE role_list
			168 => rule_168(ctx, v, l, loc)
			# CreateOptRoleElem: IN_P GROUP_P role_list
			169 => rule_168(ctx, v, l, loc)
			# CreateUserStmt: CREATE USER RoleId opt_with OptRoleList
			170 => rule_147(ctx, v, l, loc, 1)
			# AlterRoleStmt: ALTER ROLE RoleSpec opt_with AlterOptRoleList
			171 => rule_171(ctx, v, l, loc, 1)
			# AlterRoleStmt: ALTER USER RoleSpec opt_with AlterOptRoleList
			172 => rule_171(ctx, v, l, loc, 1)
			# opt_in_database: %empty
			173 => rule_138(ctx, v, l, loc)
			# opt_in_database: IN_P DATABASE name
			174 => rule_174(ctx, v, l, loc)
			# AlterRoleSetStmt: ALTER ROLE RoleSpec opt_in_database SetResetClause
			175 => rule_175(ctx, v, l, loc)
			# AlterRoleSetStmt: ALTER ROLE ALL opt_in_database SetResetClause
			176 => rule_176(ctx, v, l, loc)
			# AlterRoleSetStmt: ALTER USER RoleSpec opt_in_database SetResetClause
			177 => rule_175(ctx, v, l, loc)
			# AlterRoleSetStmt: ALTER USER ALL opt_in_database SetResetClause
			178 => rule_176(ctx, v, l, loc)
			# DropRoleStmt: DROP ROLE role_list
			179 => rule_179(ctx, v, l, loc)
			# DropRoleStmt: DROP ROLE IF_P EXISTS role_list
			180 => rule_180(ctx, v, l, loc)
			# DropRoleStmt: DROP USER role_list
			181 => rule_179(ctx, v, l, loc)
			# DropRoleStmt: DROP USER IF_P EXISTS role_list
			182 => rule_182(ctx, v, l, loc)
			# DropRoleStmt: DROP GROUP_P role_list
			183 => rule_179(ctx, v, l, loc)
			# DropRoleStmt: DROP GROUP_P IF_P EXISTS role_list
			184 => rule_180(ctx, v, l, loc)
			# CreateGroupStmt: CREATE GROUP_P RoleId opt_with OptRoleList
			185 => rule_147(ctx, v, l, loc, 2)
			# AlterGroupStmt: ALTER GROUP_P RoleSpec add_drop USER role_list
			186 => rule_186(ctx, v, l, loc)
			# add_drop: ADD_P
			187 => rule_143(ctx, v, l, loc, 1)
			# add_drop: DROP
			188 => rule_188(ctx, v, l, loc, 1)
			# CreateSchemaStmt: CREATE SCHEMA opt_single_name AUTHORIZATION RoleSpec OptSchemaEltList
			189 => rule_189(ctx, v, l, loc)
			# CreateSchemaStmt: CREATE SCHEMA ColId OptSchemaEltList
			190 => rule_190(ctx, v, l, loc)
			# CreateSchemaStmt: CREATE SCHEMA IF_P NOT EXISTS opt_single_name AUTHORIZATION RoleSpec OptSchemaEltList
			191 => rule_191(ctx, v, l, loc)
			# CreateSchemaStmt: CREATE SCHEMA IF_P NOT EXISTS ColId OptSchemaEltList
			192 => rule_192(ctx, v, l, loc)
			# OptSchemaEltList: OptSchemaEltList schema_stmt
			193 => rule_151(ctx, v, l, loc)
			# OptSchemaEltList: %empty
			194 => rule_140(ctx, v, l, loc)
			# VariableSetStmt: SET set_rest
			201 => rule_201(ctx, v, l, loc)
			# VariableSetStmt: SET LOCAL set_rest
			202 => rule_202(ctx, v, l, loc)
			# VariableSetStmt: SET SESSION set_rest
			203 => rule_203(ctx, v, l, loc)
			# set_rest: TRANSACTION transaction_mode_list
			204 => rule_204(ctx, v, l, loc, 3, 1)
			# set_rest: SESSION CHARACTERISTICS AS TRANSACTION transaction_mode_list
			205 => rule_205(ctx, v, l, loc, 3, 1)
			# generic_set: var_name TO var_list
			207 => rule_207(ctx, v, l, loc, 0)
			# generic_set: var_name '=' var_list
			208 => rule_207(ctx, v, l, loc, 0)
			# generic_set: var_name TO DEFAULT
			209 => rule_209(ctx, v, l, loc, 1, 1)
			# generic_set: var_name '=' DEFAULT
			210 => rule_209(ctx, v, l, loc, 1, 1)
			# set_rest_more: generic_set
			211 => rule_164(ctx, v, l, loc)
			# set_rest_more: var_name FROM CURRENT_P
			212 => rule_209(ctx, v, l, loc, 2, 1)
			# set_rest_more: TIME ZONE zone_value
			213 => rule_213(ctx, v, l, loc, 0, 1, 1)
			# set_rest_more: CATALOG_P Sconst
			214 => rule_214(ctx, v, l, loc)
			# set_rest_more: SCHEMA Sconst
			215 => rule_215(ctx, v, l, loc, 0)
			# set_rest_more: NAMES opt_encoding
			216 => rule_216(ctx, v, l, loc, 0, 1)
			# set_rest_more: ROLE NonReservedWord_or_Sconst
			217 => rule_217(ctx, v, l, loc, 0)
			# set_rest_more: SESSION AUTHORIZATION NonReservedWord_or_Sconst
			218 => rule_218(ctx, v, l, loc, 0)
			# set_rest_more: SESSION AUTHORIZATION DEFAULT
			219 => rule_219(ctx, v, l, loc, 1, 1)
			# set_rest_more: XML_P OPTION document_or_content
			220 => rule_220(ctx, v, l, loc, 0, 0, 1)
			# set_rest_more: TRANSACTION SNAPSHOT Sconst
			221 => rule_221(ctx, v, l, loc, 3)
			# var_name: ColId
			222 => rule_137(ctx, v, l, loc)
			# var_name: var_name '.' ColId
			223 => rule_223(ctx, v, l, loc)
			# var_list: var_value
			224 => rule_224(ctx, v, l, loc)
			# var_list: var_list ',' var_value
			225 => rule_225(ctx, v, l, loc)
			# var_value: opt_boolean_or_string
			226 => rule_226(ctx, v, l, loc)
			# var_value: NumericOnly
			227 => rule_227(ctx, v, l, loc)
			# iso_level: READ UNCOMMITTED
			228 => rule_228(ctx, v, l, loc)
			# iso_level: READ COMMITTED
			229 => rule_229(ctx, v, l, loc)
			# iso_level: REPEATABLE READ
			230 => rule_230(ctx, v, l, loc)
			# iso_level: SERIALIZABLE
			231 => rule_231(ctx, v, l, loc)
			# opt_boolean_or_string: TRUE_P
			232 => rule_232(ctx, v, l, loc)
			# opt_boolean_or_string: FALSE_P
			233 => rule_233(ctx, v, l, loc)
			# opt_boolean_or_string: ON
			234 => rule_234(ctx, v, l, loc)
			# opt_boolean_or_string: NonReservedWord_or_Sconst
			235 => rule_137(ctx, v, l, loc)
			# zone_value: Sconst
			236 => rule_226(ctx, v, l, loc)
			# zone_value: IDENT
			237 => rule_226(ctx, v, l, loc)
			# zone_value: ConstInterval Sconst opt_interval
			238 => rule_238(ctx, v, l, loc, 10, 11, 0)
			# zone_value: ConstInterval '(' Iconst ')' Sconst
			239 => rule_239(ctx, v, l, loc, 32767, 1)
			# zone_value: NumericOnly
			240 => rule_227(ctx, v, l, loc)
			# zone_value: DEFAULT
			241 => rule_241(ctx, v, l, loc)
			# zone_value: LOCAL
			242 => rule_241(ctx, v, l, loc)
			# opt_encoding: Sconst
			243 => rule_137(ctx, v, l, loc)
			# opt_encoding: DEFAULT
			244 => rule_244(ctx, v, l, loc)
			# opt_encoding: %empty
			245 => rule_138(ctx, v, l, loc)
			# NonReservedWord_or_Sconst: NonReservedWord
			246 => rule_137(ctx, v, l, loc)
			# NonReservedWord_or_Sconst: Sconst
			247 => rule_137(ctx, v, l, loc)
			# VariableResetStmt: RESET reset_rest
			248 => rule_248(ctx, v, l, loc)
			# reset_rest: generic_reset
			249 => rule_164(ctx, v, l, loc)
			# reset_rest: TIME ZONE
			250 => rule_250(ctx, v, l, loc, 4, 1)
			# reset_rest: TRANSACTION ISOLATION LEVEL
			251 => rule_251(ctx, v, l, loc, 4, 1)
			# reset_rest: SESSION AUTHORIZATION
			252 => rule_219(ctx, v, l, loc, 4, 1)
			# generic_reset: var_name
			253 => rule_209(ctx, v, l, loc, 4, 1)
			# generic_reset: ALL
			254 => rule_254(ctx, v, l, loc, 5, 1)
			# SetResetClause: SET set_rest
			255 => rule_248(ctx, v, l, loc)
			# SetResetClause: VariableResetStmt
			256 => rule_164(ctx, v, l, loc)
			# FunctionSetResetClause: SET set_rest_more
			257 => rule_248(ctx, v, l, loc)
			# FunctionSetResetClause: VariableResetStmt
			258 => rule_164(ctx, v, l, loc)
			# VariableShowStmt: SHOW var_name
			259 => rule_259(ctx, v, l, loc)
			# VariableShowStmt: SHOW TIME ZONE
			260 => rule_260(ctx, v, l, loc)
			# VariableShowStmt: SHOW TRANSACTION ISOLATION LEVEL
			261 => rule_261(ctx, v, l, loc)
			# VariableShowStmt: SHOW SESSION AUTHORIZATION
			262 => rule_262(ctx, v, l, loc)
			# VariableShowStmt: SHOW ALL
			263 => rule_263(ctx, v, l, loc)
			# ConstraintsSetStmt: SET CONSTRAINTS constraints_set_list constraints_set_mode
			264 => rule_264(ctx, v, l, loc)
			# constraints_set_list: ALL
			265 => rule_265(ctx, v, l, loc)
			# constraints_set_list: qualified_name_list
			266 => rule_139(ctx, v, l, loc)
			# constraints_set_mode: DEFERRED
			267 => rule_141(ctx, v, l, loc)
			# constraints_set_mode: IMMEDIATE
			268 => rule_268(ctx, v, l, loc)
			# CheckPointStmt: CHECKPOINT
			269 => rule_269(ctx, v, l, loc)
			# DiscardStmt: DISCARD ALL
			270 => rule_270(ctx, v, l, loc, 0)
			# DiscardStmt: DISCARD TEMP
			271 => rule_270(ctx, v, l, loc, 3)
			# DiscardStmt: DISCARD TEMPORARY
			272 => rule_270(ctx, v, l, loc, 3)
			# DiscardStmt: DISCARD PLANS
			273 => rule_270(ctx, v, l, loc, 1)
			# DiscardStmt: DISCARD SEQUENCES
			274 => rule_270(ctx, v, l, loc, 2)
			# AlterTableStmt: ALTER TABLE relation_expr alter_table_cmds
			275 => rule_275(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds
			276 => rule_276(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER TABLE relation_expr partition_cmd
			277 => rule_277(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER TABLE IF_P EXISTS relation_expr partition_cmd
			278 => rule_278(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER TABLE ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait
			279 => rule_279(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER TABLE ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait
			280 => rule_280(ctx, v, l, loc, 41)
			# AlterTableStmt: ALTER INDEX qualified_name alter_table_cmds
			281 => rule_275(ctx, v, l, loc, 20)
			# AlterTableStmt: ALTER INDEX IF_P EXISTS qualified_name alter_table_cmds
			282 => rule_276(ctx, v, l, loc, 20)
			# AlterTableStmt: ALTER INDEX qualified_name index_partition_cmd
			283 => rule_277(ctx, v, l, loc, 20)
			# AlterTableStmt: ALTER INDEX ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait
			284 => rule_279(ctx, v, l, loc, 20)
			# AlterTableStmt: ALTER INDEX ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait
			285 => rule_280(ctx, v, l, loc, 20)
			# AlterTableStmt: ALTER SEQUENCE qualified_name alter_table_cmds
			286 => rule_275(ctx, v, l, loc, 37)
			# AlterTableStmt: ALTER SEQUENCE IF_P EXISTS qualified_name alter_table_cmds
			287 => rule_276(ctx, v, l, loc, 37)
			# AlterTableStmt: ALTER VIEW qualified_name alter_table_cmds
			288 => rule_275(ctx, v, l, loc, 51)
			# AlterTableStmt: ALTER VIEW IF_P EXISTS qualified_name alter_table_cmds
			289 => rule_276(ctx, v, l, loc, 51)
			# AlterTableStmt: ALTER MATERIALIZED VIEW qualified_name alter_table_cmds
			290 => rule_290(ctx, v, l, loc, 23)
			# AlterTableStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name alter_table_cmds
			291 => rule_291(ctx, v, l, loc, 23)
			# AlterTableStmt: ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait
			292 => rule_292(ctx, v, l, loc, 23)
			# AlterTableStmt: ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait
			293 => rule_293(ctx, v, l, loc, 23)
			# AlterTableStmt: ALTER FOREIGN TABLE relation_expr alter_table_cmds
			294 => rule_290(ctx, v, l, loc, 18)
			# AlterTableStmt: ALTER FOREIGN TABLE IF_P EXISTS relation_expr alter_table_cmds
			295 => rule_291(ctx, v, l, loc, 18)
			# alter_table_cmds: alter_table_cmd
			296 => rule_224(ctx, v, l, loc)
			# alter_table_cmds: alter_table_cmds ',' alter_table_cmd
			297 => rule_225(ctx, v, l, loc)
			# partition_cmd: ATTACH PARTITION qualified_name PartitionBoundSpec
			298 => rule_298(ctx, v, l, loc, 59)
			# partition_cmd: DETACH PARTITION qualified_name opt_concurrently
			299 => rule_299(ctx, v, l, loc, 60)
			# partition_cmd: DETACH PARTITION qualified_name FINALIZE
			300 => rule_300(ctx, v, l, loc, 61)
			# index_partition_cmd: ATTACH PARTITION qualified_name
			301 => rule_300(ctx, v, l, loc, 59)
			# alter_table_cmd: ADD_P columnDef
			302 => rule_302(ctx, v, l, loc, 0)
			# alter_table_cmd: ADD_P IF_P NOT EXISTS columnDef
			303 => rule_303(ctx, v, l, loc, 0)
			# alter_table_cmd: ADD_P COLUMN columnDef
			304 => rule_304(ctx, v, l, loc, 0)
			# alter_table_cmd: ADD_P COLUMN IF_P NOT EXISTS columnDef
			305 => rule_305(ctx, v, l, loc, 0)
			# alter_table_cmd: ALTER opt_column ColId alter_column_default
			306 => rule_306(ctx, v, l, loc, 2)
			# alter_table_cmd: ALTER opt_column ColId DROP NOT NULL_P
			307 => rule_307(ctx, v, l, loc, 4)
			# alter_table_cmd: ALTER opt_column ColId SET NOT NULL_P
			308 => rule_307(ctx, v, l, loc, 5)
			# alter_table_cmd: ALTER opt_column ColId SET EXPRESSION AS '(' a_expr ')'
			309 => rule_309(ctx, v, l, loc, 6)
			# alter_table_cmd: ALTER opt_column ColId DROP EXPRESSION
			310 => rule_307(ctx, v, l, loc, 7)
			# alter_table_cmd: ALTER opt_column ColId DROP EXPRESSION IF_P EXISTS
			311 => rule_311(ctx, v, l, loc, 7)
			# alter_table_cmd: ALTER opt_column ColId SET STATISTICS set_statistics_value
			312 => rule_312(ctx, v, l, loc, 8)
			# alter_table_cmd: ALTER opt_column Iconst SET STATISTICS set_statistics_value
			313 => rule_313(ctx, v, l, loc, 0, 32767, 8)
			# alter_table_cmd: ALTER opt_column ColId SET reloptions
			314 => rule_314(ctx, v, l, loc, 9)
			# alter_table_cmd: ALTER opt_column ColId RESET reloptions
			315 => rule_314(ctx, v, l, loc, 10)
			# alter_table_cmd: ALTER opt_column ColId SET column_storage
			316 => rule_316(ctx, v, l, loc, 11)
			# alter_table_cmd: ALTER opt_column ColId SET column_compression
			317 => rule_316(ctx, v, l, loc, 12)
			# alter_table_cmd: ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
			318 => rule_318(ctx, v, l, loc, 3, 62)
			# alter_table_cmd: ALTER opt_column ColId alter_identity_column_option_list
			319 => rule_319(ctx, v, l, loc, 63)
			# alter_table_cmd: ALTER opt_column ColId DROP IDENTITY_P
			320 => rule_320(ctx, v, l, loc, 64)
			# alter_table_cmd: ALTER opt_column ColId DROP IDENTITY_P IF_P EXISTS
			321 => rule_311(ctx, v, l, loc, 64)
			# alter_table_cmd: DROP opt_column IF_P EXISTS ColId opt_drop_behavior
			322 => rule_322(ctx, v, l, loc, 13)
			# alter_table_cmd: DROP opt_column ColId opt_drop_behavior
			323 => rule_323(ctx, v, l, loc, 13)
			# alter_table_cmd: ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using
			324 => rule_324(ctx, v, l, loc, 24)
			# alter_table_cmd: ALTER opt_column ColId alter_generic_options
			325 => rule_319(ctx, v, l, loc, 25)
			# alter_table_cmd: ADD_P TableConstraint
			326 => rule_326(ctx, v, l, loc, 16)
			# alter_table_cmd: ALTER CONSTRAINT name ConstraintAttributeSpec
			327 => rule_327(ctx, v, l, loc, 19, 64, 128, 2, 1, 8, 4, 32, 16)
			# alter_table_cmd: ALTER CONSTRAINT name INHERIT
			328 => rule_328(ctx, v, l, loc, 19)
			# alter_table_cmd: VALIDATE CONSTRAINT name
			329 => rule_307(ctx, v, l, loc, 20)
			# alter_table_cmd: DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
			330 => rule_322(ctx, v, l, loc, 22)
			# alter_table_cmd: DROP CONSTRAINT name opt_drop_behavior
			331 => rule_323(ctx, v, l, loc, 22)
			# alter_table_cmd: SET WITHOUT OIDS
			332 => rule_332(ctx, v, l, loc, 31)
			# alter_table_cmd: CLUSTER ON name
			333 => rule_307(ctx, v, l, loc, 27)
			# alter_table_cmd: SET WITHOUT CLUSTER
			334 => rule_334(ctx, v, l, loc, 28)
			# alter_table_cmd: SET LOGGED
			335 => rule_332(ctx, v, l, loc, 29)
			# alter_table_cmd: SET UNLOGGED
			336 => rule_332(ctx, v, l, loc, 30)
			# alter_table_cmd: ENABLE_P TRIGGER name
			337 => rule_307(ctx, v, l, loc, 37)
			# alter_table_cmd: ENABLE_P ALWAYS TRIGGER name
			338 => rule_338(ctx, v, l, loc, 38)
			# alter_table_cmd: ENABLE_P REPLICA TRIGGER name
			339 => rule_338(ctx, v, l, loc, 39)
			# alter_table_cmd: ENABLE_P TRIGGER ALL
			340 => rule_332(ctx, v, l, loc, 41)
			# alter_table_cmd: ENABLE_P TRIGGER USER
			341 => rule_332(ctx, v, l, loc, 43)
			# alter_table_cmd: DISABLE_P TRIGGER name
			342 => rule_307(ctx, v, l, loc, 40)
			# alter_table_cmd: DISABLE_P TRIGGER ALL
			343 => rule_332(ctx, v, l, loc, 42)
			# alter_table_cmd: DISABLE_P TRIGGER USER
			344 => rule_332(ctx, v, l, loc, 44)
			# alter_table_cmd: ENABLE_P RULE name
			345 => rule_307(ctx, v, l, loc, 45)
			# alter_table_cmd: ENABLE_P ALWAYS RULE name
			346 => rule_338(ctx, v, l, loc, 46)
			# alter_table_cmd: ENABLE_P REPLICA RULE name
			347 => rule_338(ctx, v, l, loc, 47)
			# alter_table_cmd: DISABLE_P RULE name
			348 => rule_307(ctx, v, l, loc, 48)
			# alter_table_cmd: INHERIT qualified_name
			349 => rule_349(ctx, v, l, loc, 49)
			# alter_table_cmd: NO INHERIT qualified_name
			350 => rule_350(ctx, v, l, loc, 50)
			# alter_table_cmd: OF any_name
			351 => rule_351(ctx, v, l, loc, 51)
			# alter_table_cmd: NOT OF
			352 => rule_332(ctx, v, l, loc, 52)
			# alter_table_cmd: OWNER TO RoleSpec
			353 => rule_353(ctx, v, l, loc, 26)
			# alter_table_cmd: SET ACCESS METHOD set_access_method_name
			354 => rule_338(ctx, v, l, loc, 32)
			# alter_table_cmd: SET TABLESPACE name
			355 => rule_307(ctx, v, l, loc, 33)
			# alter_table_cmd: SET reloptions
			356 => rule_356(ctx, v, l, loc, 34)
			# alter_table_cmd: RESET reloptions
			357 => rule_356(ctx, v, l, loc, 35)
			# alter_table_cmd: REPLICA IDENTITY_P replica_identity
			358 => rule_358(ctx, v, l, loc, 53)
			# alter_table_cmd: ENABLE_P ROW LEVEL SECURITY
			359 => rule_332(ctx, v, l, loc, 54)
			# alter_table_cmd: DISABLE_P ROW LEVEL SECURITY
			360 => rule_332(ctx, v, l, loc, 55)
			# alter_table_cmd: FORCE ROW LEVEL SECURITY
			361 => rule_332(ctx, v, l, loc, 56)
			# alter_table_cmd: NO FORCE ROW LEVEL SECURITY
			362 => rule_332(ctx, v, l, loc, 57)
			# alter_table_cmd: alter_generic_options
			363 => rule_363(ctx, v, l, loc, 58)
			# alter_column_default: SET DEFAULT a_expr
			364 => rule_364(ctx, v, l, loc)
			# alter_column_default: DROP DEFAULT
			365 => rule_241(ctx, v, l, loc)
			# opt_collate_clause: COLLATE any_name
			366 => rule_366(ctx, v, l, loc)
			# opt_collate_clause: %empty
			367 => rule_136(ctx, v, l, loc)
			# alter_using: USING a_expr
			368 => rule_248(ctx, v, l, loc)
			# alter_using: %empty
			369 => rule_136(ctx, v, l, loc)
			# replica_identity: NOTHING
			370 => rule_370(ctx, v, l, loc, 110)
			# replica_identity: FULL
			371 => rule_370(ctx, v, l, loc, 102)
			# replica_identity: DEFAULT
			372 => rule_370(ctx, v, l, loc, 100)
			# replica_identity: USING INDEX name
			373 => rule_373(ctx, v, l, loc, 105)
			# reloptions: '(' reloption_list ')'
			374 => rule_374(ctx, v, l, loc)
			# opt_reloptions: WITH reloptions
			375 => rule_374(ctx, v, l, loc)
			# opt_reloptions: %empty
			376 => rule_140(ctx, v, l, loc)
			# reloption_list: reloption_elem
			377 => rule_224(ctx, v, l, loc)
			# reloption_list: reloption_list ',' reloption_elem
			378 => rule_225(ctx, v, l, loc)
			# reloption_elem: ColLabel '=' def_arg
			379 => rule_379(ctx, v, l, loc)
			# reloption_elem: ColLabel
			380 => rule_380(ctx, v, l, loc)
			# reloption_elem: ColLabel '.' ColLabel '=' def_arg
			381 => rule_381(ctx, v, l, loc, 0)
			# reloption_elem: ColLabel '.' ColLabel
			382 => rule_382(ctx, v, l, loc, 0)
			# alter_identity_column_option_list: alter_identity_column_option
			383 => rule_224(ctx, v, l, loc)
			# alter_identity_column_option_list: alter_identity_column_option_list alter_identity_column_option
			384 => rule_151(ctx, v, l, loc)
			# alter_identity_column_option: RESTART
			385 => rule_385(ctx, v, l, loc)
			# alter_identity_column_option: RESTART opt_with NumericOnly
			386 => rule_386(ctx, v, l, loc)
			# alter_identity_column_option: SET SeqOptElem
			387 => rule_387(ctx, v, l, loc, 0, 0, 0)
			# alter_identity_column_option: SET GENERATED generated_when
			388 => rule_388(ctx, v, l, loc)
			# set_statistics_value: SignedIconst
			389 => rule_389(ctx, v, l, loc)
			# set_statistics_value: DEFAULT
			390 => rule_241(ctx, v, l, loc)
			# set_access_method_name: ColId
			391 => rule_137(ctx, v, l, loc)
			# set_access_method_name: DEFAULT
			392 => rule_244(ctx, v, l, loc)
			# PartitionBoundSpec: FOR VALUES WITH '(' hash_partbound ')'
			393 => rule_393(ctx, v, l, loc, 104, 1, 0, 1, 0, 1, 1, 1)
			# PartitionBoundSpec: FOR VALUES IN_P '(' expr_list ')'
			394 => rule_394(ctx, v, l, loc, 108)
			# PartitionBoundSpec: FOR VALUES FROM '(' expr_list ')' TO '(' expr_list ')'
			395 => rule_395(ctx, v, l, loc, 114)
			# PartitionBoundSpec: DEFAULT
			396 => rule_396(ctx, v, l, loc)
			# hash_partbound_elem: NonReservedWord Iconst
			397 => rule_397(ctx, v, l, loc)
			# hash_partbound: hash_partbound_elem
			398 => rule_224(ctx, v, l, loc)
			# hash_partbound: hash_partbound ',' hash_partbound_elem
			399 => rule_225(ctx, v, l, loc)
			# AlterCompositeTypeStmt: ALTER TYPE_P any_name alter_type_cmds
			400 => rule_400(ctx, v, l, loc, 49)
			# alter_type_cmds: alter_type_cmd
			401 => rule_224(ctx, v, l, loc)
			# alter_type_cmds: alter_type_cmds ',' alter_type_cmd
			402 => rule_225(ctx, v, l, loc)
			# alter_type_cmd: ADD_P ATTRIBUTE TableFuncElement opt_drop_behavior
			403 => rule_403(ctx, v, l, loc, 0)
			# alter_type_cmd: DROP ATTRIBUTE IF_P EXISTS ColId opt_drop_behavior
			404 => rule_322(ctx, v, l, loc, 13)
			# alter_type_cmd: DROP ATTRIBUTE ColId opt_drop_behavior
			405 => rule_323(ctx, v, l, loc, 13)
			# alter_type_cmd: ALTER ATTRIBUTE ColId opt_set_data TYPE_P Typename opt_collate_clause opt_drop_behavior
			406 => rule_406(ctx, v, l, loc, 24)
			# ClosePortalStmt: CLOSE cursor_name
			407 => rule_407(ctx, v, l, loc)
			# ClosePortalStmt: CLOSE ALL
			408 => rule_408(ctx, v, l, loc)
			# CopyStmt: COPY opt_binary qualified_name opt_column_list copy_from opt_program copy_file_name copy_delimiter opt_with copy_options where_clause
			409 => rule_409(ctx, v, l, loc)
			# CopyStmt: COPY '(' PreparableStmt ')' TO opt_program copy_file_name opt_with copy_options
			410 => rule_410(ctx, v, l, loc)
			# copy_from: FROM
			411 => rule_141(ctx, v, l, loc)
			# copy_from: TO
			412 => rule_268(ctx, v, l, loc)
			# opt_program: PROGRAM
			413 => rule_141(ctx, v, l, loc)
			# opt_program: %empty
			414 => rule_142(ctx, v, l, loc)
			# copy_file_name: Sconst
			415 => rule_137(ctx, v, l, loc)
			# copy_file_name: STDIN
			416 => rule_244(ctx, v, l, loc)
			# copy_file_name: STDOUT
			417 => rule_244(ctx, v, l, loc)
			# copy_options: copy_opt_list
			418 => rule_139(ctx, v, l, loc)
			# copy_options: '(' copy_generic_opt_list ')'
			419 => rule_374(ctx, v, l, loc)
			# copy_opt_list: copy_opt_list copy_opt_item
			420 => rule_151(ctx, v, l, loc)
			# copy_opt_list: %empty
			421 => rule_140(ctx, v, l, loc)
			# copy_opt_item: BINARY
			422 => rule_422(ctx, v, l, loc)
			# copy_opt_item: FREEZE
			423 => rule_423(ctx, v, l, loc)
			# copy_opt_item: DELIMITER opt_as Sconst
			424 => rule_424(ctx, v, l, loc)
			# copy_opt_item: NULL_P opt_as Sconst
			425 => rule_425(ctx, v, l, loc)
			# copy_opt_item: CSV
			426 => rule_426(ctx, v, l, loc)
			# copy_opt_item: HEADER_P
			427 => rule_427(ctx, v, l, loc)
			# copy_opt_item: QUOTE opt_as Sconst
			428 => rule_428(ctx, v, l, loc)
			# copy_opt_item: ESCAPE opt_as Sconst
			429 => rule_429(ctx, v, l, loc)
			# copy_opt_item: FORCE QUOTE columnList
			430 => rule_430(ctx, v, l, loc)
			# copy_opt_item: FORCE QUOTE '*'
			431 => rule_431(ctx, v, l, loc)
			# copy_opt_item: FORCE NOT NULL_P columnList
			432 => rule_432(ctx, v, l, loc)
			# copy_opt_item: FORCE NOT NULL_P '*'
			433 => rule_433(ctx, v, l, loc)
			# copy_opt_item: FORCE NULL_P columnList
			434 => rule_434(ctx, v, l, loc)
			# copy_opt_item: FORCE NULL_P '*'
			435 => rule_435(ctx, v, l, loc)
			# copy_opt_item: ENCODING Sconst
			436 => rule_436(ctx, v, l, loc)
			# opt_binary: BINARY
			437 => rule_422(ctx, v, l, loc)
			# opt_binary: %empty
			438 => rule_136(ctx, v, l, loc)
			# copy_delimiter: opt_using DELIMITERS Sconst
			439 => rule_439(ctx, v, l, loc)
			# copy_delimiter: %empty
			440 => rule_136(ctx, v, l, loc)
			# copy_generic_opt_list: copy_generic_opt_elem
			443 => rule_224(ctx, v, l, loc)
			# copy_generic_opt_list: copy_generic_opt_list ',' copy_generic_opt_elem
			444 => rule_225(ctx, v, l, loc)
			# copy_generic_opt_elem: ColLabel copy_generic_opt_arg
			445 => rule_445(ctx, v, l, loc)
			# copy_generic_opt_arg: opt_boolean_or_string
			446 => rule_446(ctx, v, l, loc)
			# copy_generic_opt_arg: NumericOnly
			447 => rule_164(ctx, v, l, loc)
			# copy_generic_opt_arg: '*'
			448 => rule_448(ctx, v, l, loc)
			# copy_generic_opt_arg: DEFAULT
			449 => rule_449(ctx, v, l, loc)
			# copy_generic_opt_arg: '(' copy_generic_opt_arg_list ')'
			450 => rule_450(ctx, v, l, loc)
			# copy_generic_opt_arg: %empty
			451 => rule_136(ctx, v, l, loc)
			# copy_generic_opt_arg_list: copy_generic_opt_arg_list_item
			452 => rule_224(ctx, v, l, loc)
			# copy_generic_opt_arg_list: copy_generic_opt_arg_list ',' copy_generic_opt_arg_list_item
			453 => rule_225(ctx, v, l, loc)
			# copy_generic_opt_arg_list_item: opt_boolean_or_string
			454 => rule_446(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			455 => rule_455(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			456 => rule_456(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			457 => rule_457(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			458 => rule_458(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			459 => rule_459(ctx, v, l, loc)
			# CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
			460 => rule_460(ctx, v, l, loc)
			# OptTemp: TEMPORARY
			461 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: TEMP
			462 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: LOCAL TEMPORARY
			463 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: LOCAL TEMP
			464 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: GLOBAL TEMPORARY
			465 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: GLOBAL TEMP
			466 => rule_143(ctx, v, l, loc, 116)
			# OptTemp: UNLOGGED
			467 => rule_143(ctx, v, l, loc, 117)
			# OptTemp: %empty
			468 => rule_145(ctx, v, l, loc, 112)
			# OptTableElementList: TableElementList
			469 => rule_139(ctx, v, l, loc)
			# OptTableElementList: %empty
			470 => rule_140(ctx, v, l, loc)
			# OptTypedTableElementList: '(' TypedTableElementList ')'
			471 => rule_374(ctx, v, l, loc)
			# OptTypedTableElementList: %empty
			472 => rule_140(ctx, v, l, loc)
			# TableElementList: TableElement
			473 => rule_224(ctx, v, l, loc)
			# TableElementList: TableElementList ',' TableElement
			474 => rule_225(ctx, v, l, loc)
			# TypedTableElementList: TypedTableElement
			475 => rule_224(ctx, v, l, loc)
			# TypedTableElementList: TypedTableElementList ',' TypedTableElement
			476 => rule_225(ctx, v, l, loc)
			# TableElement: columnDef
			477 => rule_164(ctx, v, l, loc)
			# TableElement: TableLikeClause
			478 => rule_164(ctx, v, l, loc)
			# TableElement: TableConstraint
			479 => rule_164(ctx, v, l, loc)
			# TypedTableElement: columnOptions
			480 => rule_164(ctx, v, l, loc)
			# TypedTableElement: TableConstraint
			481 => rule_164(ctx, v, l, loc)
			# columnDef: ColId Typename opt_column_storage opt_column_compression create_generic_options ColQualList
			482 => rule_482(ctx, v, l, loc, 0, 0, 0)
			# columnOptions: ColId ColQualList
			483 => rule_483(ctx, v, l, loc, 0, 0, 0)
			# columnOptions: ColId WITH OPTIONS ColQualList
			484 => rule_484(ctx, v, l, loc, 0, 0, 0)
			# column_compression: COMPRESSION ColId
			485 => rule_485(ctx, v, l, loc)
			# column_compression: COMPRESSION DEFAULT
			486 => rule_486(ctx, v, l, loc)
			# opt_column_compression: column_compression
			487 => rule_137(ctx, v, l, loc)
			# opt_column_compression: %empty
			488 => rule_138(ctx, v, l, loc)
			# column_storage: STORAGE ColId
			489 => rule_485(ctx, v, l, loc)
			# column_storage: STORAGE DEFAULT
			490 => rule_486(ctx, v, l, loc)
			# opt_column_storage: column_storage
			491 => rule_137(ctx, v, l, loc)
			# opt_column_storage: %empty
			492 => rule_138(ctx, v, l, loc)
			# ColQualList: ColQualList ColConstraint
			493 => rule_151(ctx, v, l, loc)
			# ColQualList: %empty
			494 => rule_140(ctx, v, l, loc)
			# ColConstraint: CONSTRAINT name ColConstraintElem
			495 => rule_495(ctx, v, l, loc)
			# ColConstraint: ColConstraintElem
			496 => rule_164(ctx, v, l, loc)
			# ColConstraint: ConstraintAttr
			497 => rule_164(ctx, v, l, loc)
			# ColConstraint: COLLATE any_name
			498 => rule_366(ctx, v, l, loc)
			# ColConstraintElem: NOT NULL_P opt_no_inherit
			499 => rule_499(ctx, v, l, loc, 1)
			# ColConstraintElem: NULL_P
			500 => rule_500(ctx, v, l, loc, 0)
			# ColConstraintElem: UNIQUE opt_unique_null_treatment opt_definition OptConsTableSpace
			501 => rule_501(ctx, v, l, loc, 7)
			# ColConstraintElem: PRIMARY KEY opt_definition OptConsTableSpace
			502 => rule_502(ctx, v, l, loc, 6)
			# ColConstraintElem: CHECK '(' a_expr ')' opt_no_inherit
			503 => rule_503(ctx, v, l, loc, 5)
			# ColConstraintElem: DEFAULT b_expr
			504 => rule_504(ctx, v, l, loc, 2)
			# ColConstraintElem: GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
			505 => rule_505(ctx, v, l, loc, 3)
			# ColConstraintElem: GENERATED generated_when AS '(' a_expr ')' opt_virtual_or_stored
			506 => rule_506(ctx, v, l, loc, 4, 97)
			# ColConstraintElem: REFERENCES qualified_name opt_column_list key_match key_actions
			507 => rule_507(ctx, v, l, loc, 9)
			# opt_unique_null_treatment: NULLS_P DISTINCT
			508 => rule_141(ctx, v, l, loc)
			# opt_unique_null_treatment: NULLS_P NOT DISTINCT
			509 => rule_268(ctx, v, l, loc)
			# opt_unique_null_treatment: %empty
			510 => rule_510(ctx, v, l, loc)
			# generated_when: ALWAYS
			511 => rule_143(ctx, v, l, loc, 97)
			# generated_when: BY DEFAULT
			512 => rule_143(ctx, v, l, loc, 100)
			# opt_virtual_or_stored: STORED
			513 => rule_143(ctx, v, l, loc, 115)
			# opt_virtual_or_stored: VIRTUAL
			514 => rule_143(ctx, v, l, loc, 118)
			# opt_virtual_or_stored: %empty
			515 => rule_145(ctx, v, l, loc, 118)
			# ConstraintAttr: DEFERRABLE
			516 => rule_500(ctx, v, l, loc, 10)
			# ConstraintAttr: NOT DEFERRABLE
			517 => rule_500(ctx, v, l, loc, 11)
			# ConstraintAttr: INITIALLY DEFERRED
			518 => rule_500(ctx, v, l, loc, 12)
			# ConstraintAttr: INITIALLY IMMEDIATE
			519 => rule_500(ctx, v, l, loc, 13)
			# ConstraintAttr: ENFORCED
			520 => rule_500(ctx, v, l, loc, 14)
			# ConstraintAttr: NOT ENFORCED
			521 => rule_500(ctx, v, l, loc, 15)
			# TableLikeClause: LIKE qualified_name TableLikeOptionList
			522 => rule_522(ctx, v, l, loc, 0)
			# TableLikeOptionList: TableLikeOptionList INCLUDING TableLikeOption
			523 => rule_523(ctx, v, l, loc)
			# TableLikeOptionList: TableLikeOptionList EXCLUDING TableLikeOption
			524 => rule_524(ctx, v, l, loc)
			# TableLikeOptionList: %empty
			525 => rule_145(ctx, v, l, loc, 0)
			# TableLikeOption: COMMENTS
			526 => rule_143(ctx, v, l, loc, 1)
			# TableLikeOption: COMPRESSION
			527 => rule_143(ctx, v, l, loc, 2)
			# TableLikeOption: CONSTRAINTS
			528 => rule_143(ctx, v, l, loc, 4)
			# TableLikeOption: DEFAULTS
			529 => rule_143(ctx, v, l, loc, 8)
			# TableLikeOption: IDENTITY_P
			530 => rule_143(ctx, v, l, loc, 32)
			# TableLikeOption: GENERATED
			531 => rule_143(ctx, v, l, loc, 16)
			# TableLikeOption: INDEXES
			532 => rule_143(ctx, v, l, loc, 64)
			# TableLikeOption: STATISTICS
			533 => rule_143(ctx, v, l, loc, 128)
			# TableLikeOption: STORAGE
			534 => rule_143(ctx, v, l, loc, 256)
			# TableLikeOption: ALL
			535 => rule_143(ctx, v, l, loc, 2147483647)
			# TableConstraint: CONSTRAINT name ConstraintElem
			536 => rule_495(ctx, v, l, loc)
			# TableConstraint: ConstraintElem
			537 => rule_164(ctx, v, l, loc)
			# ConstraintElem: CHECK '(' a_expr ')' ConstraintAttributeSpec
			538 => rule_538(ctx, v, l, loc, 5)
			# ConstraintElem: NOT NULL_P ColId ConstraintAttributeSpec
			539 => rule_539(ctx, v, l, loc, 1)
			# ConstraintElem: UNIQUE opt_unique_null_treatment '(' columnList opt_without_overlaps ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec
			540 => rule_540(ctx, v, l, loc, 7)
			# ConstraintElem: UNIQUE ExistingIndex ConstraintAttributeSpec
			541 => rule_541(ctx, v, l, loc, 7)
			# ConstraintElem: PRIMARY KEY '(' columnList opt_without_overlaps ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec
			542 => rule_542(ctx, v, l, loc, 6)
			# ConstraintElem: PRIMARY KEY ExistingIndex ConstraintAttributeSpec
			543 => rule_543(ctx, v, l, loc, 6)
			# ConstraintElem: EXCLUDE access_method_clause '(' ExclusionConstraintList ')' opt_c_include opt_definition OptConsTableSpace OptWhereClause ConstraintAttributeSpec
			544 => rule_544(ctx, v, l, loc, 8)
			# ConstraintElem: FOREIGN KEY '(' columnList optionalPeriodName ')' REFERENCES qualified_name opt_column_and_period_list key_match key_actions ConstraintAttributeSpec
			545 => rule_545(ctx, v, l, loc, 9)
			# DomainConstraint: CONSTRAINT name DomainConstraintElem
			546 => rule_495(ctx, v, l, loc)
			# DomainConstraint: DomainConstraintElem
			547 => rule_164(ctx, v, l, loc)
			# DomainConstraintElem: CHECK '(' a_expr ')' ConstraintAttributeSpec
			548 => rule_548(ctx, v, l, loc, 5)
			# DomainConstraintElem: NOT NULL_P ConstraintAttributeSpec
			549 => rule_549(ctx, v, l, loc, 1)
			# opt_no_inherit: NO INHERIT
			550 => rule_141(ctx, v, l, loc)
			# opt_no_inherit: %empty
			551 => rule_142(ctx, v, l, loc)
			# opt_without_overlaps: WITHOUT OVERLAPS
			552 => rule_141(ctx, v, l, loc)
			# opt_without_overlaps: %empty
			553 => rule_142(ctx, v, l, loc)
			# opt_column_list: '(' columnList ')'
			554 => rule_374(ctx, v, l, loc)
			# opt_column_list: %empty
			555 => rule_140(ctx, v, l, loc)
			# columnList: columnElem
			556 => rule_224(ctx, v, l, loc)
			# columnList: columnList ',' columnElem
			557 => rule_225(ctx, v, l, loc)
			# optionalPeriodName: ',' PERIOD columnElem
			558 => rule_364(ctx, v, l, loc)
			# optionalPeriodName: %empty
			559 => rule_136(ctx, v, l, loc)
			# opt_column_and_period_list: '(' columnList optionalPeriodName ')'
			560 => rule_560(ctx, v, l, loc)
			# opt_column_and_period_list: %empty
			561 => rule_561(ctx, v, l, loc)
			# columnElem: ColId
			562 => rule_446(ctx, v, l, loc)
			# opt_c_include: INCLUDE '(' columnList ')'
			563 => rule_563(ctx, v, l, loc)
			# opt_c_include: %empty
			564 => rule_140(ctx, v, l, loc)
			# key_match: MATCH FULL
			565 => rule_143(ctx, v, l, loc, 102)
			# key_match: MATCH PARTIAL
			566 => rule_566(ctx, v, l, loc)
			# key_match: MATCH SIMPLE
			567 => rule_143(ctx, v, l, loc, 115)
			# key_match: %empty
			568 => rule_145(ctx, v, l, loc, 115)
			# ExclusionConstraintList: ExclusionConstraintElem
			569 => rule_569(ctx, v, l, loc)
			# ExclusionConstraintList: ExclusionConstraintList ',' ExclusionConstraintElem
			570 => rule_570(ctx, v, l, loc)
			# ExclusionConstraintElem: index_elem WITH any_operator
			571 => rule_571(ctx, v, l, loc)
			# ExclusionConstraintElem: index_elem WITH OPERATOR '(' any_operator ')'
			572 => rule_572(ctx, v, l, loc)
			# OptWhereClause: WHERE '(' a_expr ')'
			573 => rule_364(ctx, v, l, loc)
			# OptWhereClause: %empty
			574 => rule_136(ctx, v, l, loc)
			# key_actions: key_update
			575 => rule_575(ctx, v, l, loc, 97)
			# key_actions: key_delete
			576 => rule_576(ctx, v, l, loc, 97)
			# key_actions: key_update key_delete
			577 => rule_577(ctx, v, l, loc)
			# key_actions: key_delete key_update
			578 => rule_578(ctx, v, l, loc)
			# key_actions: %empty
			579 => rule_579(ctx, v, l, loc, 97, 97)
			# key_update: ON UPDATE key_action
			580 => rule_580(ctx, v, l, loc, 110)
			# key_delete: ON DELETE_P key_action
			581 => rule_364(ctx, v, l, loc)
			# key_action: NO ACTION
			582 => rule_582(ctx, v, l, loc, 97)
			# key_action: RESTRICT
			583 => rule_582(ctx, v, l, loc, 114)
			# key_action: CASCADE
			584 => rule_582(ctx, v, l, loc, 99)
			# key_action: SET NULL_P opt_column_list
			585 => rule_585(ctx, v, l, loc, 110)
			# key_action: SET DEFAULT opt_column_list
			586 => rule_585(ctx, v, l, loc, 100)
			# OptInherit: INHERITS '(' qualified_name_list ')'
			587 => rule_563(ctx, v, l, loc)
			# OptInherit: %empty
			588 => rule_140(ctx, v, l, loc)
			# OptPartitionSpec: PartitionSpec
			589 => rule_164(ctx, v, l, loc)
			# OptPartitionSpec: %empty
			590 => rule_136(ctx, v, l, loc)
			# PartitionSpec: PARTITION BY ColId '(' part_params ')'
			591 => rule_591(ctx, v, l, loc)
			# part_params: part_elem
			592 => rule_224(ctx, v, l, loc)
			# part_params: part_params ',' part_elem
			593 => rule_225(ctx, v, l, loc)
			# part_elem: ColId opt_collate opt_qualified_name
			594 => rule_594(ctx, v, l, loc)
			# part_elem: func_expr_windowless opt_collate opt_qualified_name
			595 => rule_595(ctx, v, l, loc)
			# part_elem: '(' a_expr ')' opt_collate opt_qualified_name
			596 => rule_596(ctx, v, l, loc)
			# table_access_method_clause: USING name
			597 => rule_485(ctx, v, l, loc)
			# table_access_method_clause: %empty
			598 => rule_138(ctx, v, l, loc)
			# OptWith: WITH reloptions
			599 => rule_374(ctx, v, l, loc)
			# OptWith: WITHOUT OIDS
			600 => rule_265(ctx, v, l, loc)
			# OptWith: %empty
			601 => rule_140(ctx, v, l, loc)
			# OnCommitOption: ON COMMIT DROP
			602 => rule_143(ctx, v, l, loc, 3)
			# OnCommitOption: ON COMMIT DELETE_P ROWS
			603 => rule_143(ctx, v, l, loc, 2)
			# OnCommitOption: ON COMMIT PRESERVE ROWS
			604 => rule_143(ctx, v, l, loc, 1)
			# OnCommitOption: %empty
			605 => rule_145(ctx, v, l, loc, 0)
			# OptTableSpace: TABLESPACE name
			606 => rule_485(ctx, v, l, loc)
			# OptTableSpace: %empty
			607 => rule_138(ctx, v, l, loc)
			# OptConsTableSpace: USING INDEX TABLESPACE name
			608 => rule_608(ctx, v, l, loc)
			# OptConsTableSpace: %empty
			609 => rule_138(ctx, v, l, loc)
			# ExistingIndex: USING INDEX name
			610 => rule_174(ctx, v, l, loc)
			# CreateStatsStmt: CREATE STATISTICS opt_qualified_name opt_name_list ON stats_params FROM from_list
			611 => rule_611(ctx, v, l, loc)
			# CreateStatsStmt: CREATE STATISTICS IF_P NOT EXISTS any_name opt_name_list ON stats_params FROM from_list
			612 => rule_612(ctx, v, l, loc)
			# stats_params: stats_param
			613 => rule_224(ctx, v, l, loc)
			# stats_params: stats_params ',' stats_param
			614 => rule_225(ctx, v, l, loc)
			# stats_param: ColId
			615 => rule_615(ctx, v, l, loc)
			# stats_param: func_expr_windowless
			616 => rule_616(ctx, v, l, loc)
			# stats_param: '(' a_expr ')'
			617 => rule_617(ctx, v, l, loc)
			# AlterStatsStmt: ALTER STATISTICS any_name SET STATISTICS set_statistics_value
			618 => rule_618(ctx, v, l, loc)
			# AlterStatsStmt: ALTER STATISTICS IF_P EXISTS any_name SET STATISTICS set_statistics_value
			619 => rule_619(ctx, v, l, loc)
			# CreateAsStmt: CREATE OptTemp TABLE create_as_target AS SelectStmt opt_with_data
			620 => rule_620(ctx, v, l, loc, 41)
			# CreateAsStmt: CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data
			621 => rule_621(ctx, v, l, loc, 41)
			# create_as_target: qualified_name opt_column_list table_access_method_clause OptWith OnCommitOption OptTableSpace
			622 => rule_622(ctx, v, l, loc)
			# opt_with_data: WITH DATA_P
			623 => rule_141(ctx, v, l, loc)
			# opt_with_data: WITH NO DATA_P
			624 => rule_268(ctx, v, l, loc)
			# opt_with_data: %empty
			625 => rule_510(ctx, v, l, loc)
			# CreateMatViewStmt: CREATE OptNoLog MATERIALIZED VIEW create_mv_target AS SelectStmt opt_with_data
			626 => rule_626(ctx, v, l, loc, 23)
			# CreateMatViewStmt: CREATE OptNoLog MATERIALIZED VIEW IF_P NOT EXISTS create_mv_target AS SelectStmt opt_with_data
			627 => rule_627(ctx, v, l, loc, 23)
			# create_mv_target: qualified_name opt_column_list table_access_method_clause opt_reloptions OptTableSpace
			628 => rule_628(ctx, v, l, loc, 0)
			# OptNoLog: UNLOGGED
			629 => rule_143(ctx, v, l, loc, 117)
			# OptNoLog: %empty
			630 => rule_145(ctx, v, l, loc, 112)
			# RefreshMatViewStmt: REFRESH MATERIALIZED VIEW opt_concurrently qualified_name opt_with_data
			631 => rule_631(ctx, v, l, loc)
			# CreateSeqStmt: CREATE OptTemp SEQUENCE qualified_name OptSeqOptList
			632 => rule_632(ctx, v, l, loc, 0)
			# CreateSeqStmt: CREATE OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList
			633 => rule_633(ctx, v, l, loc, 0)
			# AlterSeqStmt: ALTER SEQUENCE qualified_name SeqOptList
			634 => rule_634(ctx, v, l, loc)
			# AlterSeqStmt: ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList
			635 => rule_635(ctx, v, l, loc)
			# OptSeqOptList: SeqOptList
			636 => rule_139(ctx, v, l, loc)
			# OptSeqOptList: %empty
			637 => rule_140(ctx, v, l, loc)
			# OptParenthesizedSeqOptList: '(' SeqOptList ')'
			638 => rule_374(ctx, v, l, loc)
			# OptParenthesizedSeqOptList: %empty
			639 => rule_140(ctx, v, l, loc)
			# SeqOptList: SeqOptElem
			640 => rule_224(ctx, v, l, loc)
			# SeqOptList: SeqOptList SeqOptElem
			641 => rule_151(ctx, v, l, loc)
			# SeqOptElem: AS SimpleTypename
			642 => rule_642(ctx, v, l, loc)
			# SeqOptElem: CACHE NumericOnly
			643 => rule_643(ctx, v, l, loc)
			# SeqOptElem: CYCLE
			644 => rule_644(ctx, v, l, loc)
			# SeqOptElem: NO CYCLE
			645 => rule_645(ctx, v, l, loc)
			# SeqOptElem: INCREMENT opt_by NumericOnly
			646 => rule_646(ctx, v, l, loc)
			# SeqOptElem: LOGGED
			647 => rule_647(ctx, v, l, loc)
			# SeqOptElem: MAXVALUE NumericOnly
			648 => rule_648(ctx, v, l, loc)
			# SeqOptElem: MINVALUE NumericOnly
			649 => rule_649(ctx, v, l, loc)
			# SeqOptElem: NO MAXVALUE
			650 => rule_650(ctx, v, l, loc)
			# SeqOptElem: NO MINVALUE
			651 => rule_651(ctx, v, l, loc)
			# SeqOptElem: OWNED BY any_name
			652 => rule_652(ctx, v, l, loc)
			# SeqOptElem: SEQUENCE NAME_P any_name
			653 => rule_653(ctx, v, l, loc)
			# SeqOptElem: START opt_with NumericOnly
			654 => rule_654(ctx, v, l, loc)
			# SeqOptElem: RESTART
			655 => rule_385(ctx, v, l, loc)
			# SeqOptElem: RESTART opt_with NumericOnly
			656 => rule_386(ctx, v, l, loc)
			# SeqOptElem: UNLOGGED
			657 => rule_657(ctx, v, l, loc)
			# NumericOnly: FCONST
			660 => rule_660(ctx, v, l, loc)
			# NumericOnly: '+' FCONST
			661 => rule_661(ctx, v, l, loc)
			# NumericOnly: '-' FCONST
			662 => rule_662(ctx, v, l, loc)
			# NumericOnly: SignedIconst
			663 => rule_389(ctx, v, l, loc)
			# NumericOnly_list: NumericOnly
			664 => rule_224(ctx, v, l, loc)
			# NumericOnly_list: NumericOnly_list ',' NumericOnly
			665 => rule_225(ctx, v, l, loc)
			# CreatePLangStmt: CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name
			666 => rule_666(ctx, v, l, loc)
			# CreatePLangStmt: CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name HANDLER handler_name opt_inline_handler opt_validator
			667 => rule_667(ctx, v, l, loc)
			# opt_trusted: TRUSTED
			668 => rule_141(ctx, v, l, loc)
			# opt_trusted: %empty
			669 => rule_142(ctx, v, l, loc)
			# handler_name: name
			670 => rule_670(ctx, v, l, loc)
			# handler_name: name attrs
			671 => rule_671(ctx, v, l, loc)
			# opt_inline_handler: INLINE_P handler_name
			672 => rule_374(ctx, v, l, loc)
			# opt_inline_handler: %empty
			673 => rule_140(ctx, v, l, loc)
			# validator_clause: VALIDATOR handler_name
			674 => rule_374(ctx, v, l, loc)
			# validator_clause: NO VALIDATOR
			675 => rule_265(ctx, v, l, loc)
			# opt_validator: validator_clause
			676 => rule_139(ctx, v, l, loc)
			# opt_validator: %empty
			677 => rule_140(ctx, v, l, loc)
			# CreateTableSpaceStmt: CREATE TABLESPACE name OptTableSpaceOwner LOCATION Sconst opt_reloptions
			680 => rule_680(ctx, v, l, loc)
			# OptTableSpaceOwner: OWNER RoleSpec
			681 => rule_248(ctx, v, l, loc)
			# OptTableSpaceOwner: %empty
			682 => rule_136(ctx, v, l, loc)
			# DropTableSpaceStmt: DROP TABLESPACE name
			683 => rule_683(ctx, v, l, loc)
			# DropTableSpaceStmt: DROP TABLESPACE IF_P EXISTS name
			684 => rule_684(ctx, v, l, loc)
			# CreateExtensionStmt: CREATE EXTENSION name opt_with create_extension_opt_list
			685 => rule_685(ctx, v, l, loc)
			# CreateExtensionStmt: CREATE EXTENSION IF_P NOT EXISTS name opt_with create_extension_opt_list
			686 => rule_686(ctx, v, l, loc)
			# create_extension_opt_list: create_extension_opt_list create_extension_opt_item
			687 => rule_151(ctx, v, l, loc)
			# create_extension_opt_list: %empty
			688 => rule_140(ctx, v, l, loc)
			# create_extension_opt_item: SCHEMA name
			689 => rule_689(ctx, v, l, loc)
			# create_extension_opt_item: VERSION_P NonReservedWord_or_Sconst
			690 => rule_690(ctx, v, l, loc)
			# create_extension_opt_item: FROM NonReservedWord_or_Sconst
			691 => rule_691(ctx, v, l, loc)
			# create_extension_opt_item: CASCADE
			692 => rule_692(ctx, v, l, loc)
			# AlterExtensionStmt: ALTER EXTENSION name UPDATE alter_extension_opt_list
			693 => rule_693(ctx, v, l, loc)
			# alter_extension_opt_list: alter_extension_opt_list alter_extension_opt_item
			694 => rule_151(ctx, v, l, loc)
			# alter_extension_opt_list: %empty
			695 => rule_140(ctx, v, l, loc)
			# alter_extension_opt_item: TO NonReservedWord_or_Sconst
			696 => rule_690(ctx, v, l, loc)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop object_type_name name
			697 => rule_697(ctx, v, l, loc)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop object_type_any_name any_name
			698 => rule_698(ctx, v, l, loc)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop AGGREGATE aggregate_with_argtypes
			699 => rule_699(ctx, v, l, loc, 1)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop CAST '(' Typename AS Typename ')'
			700 => rule_700(ctx, v, l, loc, 5)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop DOMAIN_P Typename
			701 => rule_699(ctx, v, l, loc, 12)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop FUNCTION function_with_argtypes
			702 => rule_699(ctx, v, l, loc, 19)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop OPERATOR operator_with_argtypes
			703 => rule_699(ctx, v, l, loc, 25)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop OPERATOR CLASS any_name USING name
			704 => rule_704(ctx, v, l, loc, 24)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop OPERATOR FAMILY any_name USING name
			705 => rule_704(ctx, v, l, loc, 26)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop PROCEDURE function_with_argtypes
			706 => rule_699(ctx, v, l, loc, 29)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop ROUTINE function_with_argtypes
			707 => rule_699(ctx, v, l, loc, 34)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop TRANSFORM FOR Typename LANGUAGE name
			708 => rule_708(ctx, v, l, loc, 43)
			# AlterExtensionContentsStmt: ALTER EXTENSION name add_drop TYPE_P Typename
			709 => rule_699(ctx, v, l, loc, 49)
			# CreateFdwStmt: CREATE FOREIGN DATA_P WRAPPER name opt_fdw_options create_generic_options
			710 => rule_710(ctx, v, l, loc)
			# fdw_option: HANDLER handler_name
			711 => rule_711(ctx, v, l, loc)
			# fdw_option: NO HANDLER
			712 => rule_712(ctx, v, l, loc)
			# fdw_option: VALIDATOR handler_name
			713 => rule_713(ctx, v, l, loc)
			# fdw_option: NO VALIDATOR
			714 => rule_714(ctx, v, l, loc)
			# fdw_options: fdw_option
			715 => rule_224(ctx, v, l, loc)
			# fdw_options: fdw_options fdw_option
			716 => rule_151(ctx, v, l, loc)
			# opt_fdw_options: fdw_options
			717 => rule_139(ctx, v, l, loc)
			# opt_fdw_options: %empty
			718 => rule_140(ctx, v, l, loc)
			# AlterFdwStmt: ALTER FOREIGN DATA_P WRAPPER name opt_fdw_options alter_generic_options
			719 => rule_719(ctx, v, l, loc)
			# AlterFdwStmt: ALTER FOREIGN DATA_P WRAPPER name fdw_options
			720 => rule_720(ctx, v, l, loc)
			# create_generic_options: OPTIONS '(' generic_option_list ')'
			721 => rule_563(ctx, v, l, loc)
			# create_generic_options: %empty
			722 => rule_140(ctx, v, l, loc)
			# generic_option_list: generic_option_elem
			723 => rule_224(ctx, v, l, loc)
			# generic_option_list: generic_option_list ',' generic_option_elem
			724 => rule_225(ctx, v, l, loc)
			# alter_generic_options: OPTIONS '(' alter_generic_option_list ')'
			725 => rule_563(ctx, v, l, loc)
			# alter_generic_option_list: alter_generic_option_elem
			726 => rule_224(ctx, v, l, loc)
			# alter_generic_option_list: alter_generic_option_list ',' alter_generic_option_elem
			727 => rule_225(ctx, v, l, loc)
			# alter_generic_option_elem: generic_option_elem
			728 => rule_164(ctx, v, l, loc)
			# alter_generic_option_elem: SET generic_option_elem
			729 => rule_729(ctx, v, l, loc, 1)
			# alter_generic_option_elem: ADD_P generic_option_elem
			730 => rule_729(ctx, v, l, loc, 2)
			# alter_generic_option_elem: DROP generic_option_name
			731 => rule_731(ctx, v, l, loc, 3)
			# generic_option_elem: generic_option_name generic_option_arg
			732 => rule_445(ctx, v, l, loc)
			# generic_option_name: ColLabel
			733 => rule_137(ctx, v, l, loc)
			# generic_option_arg: Sconst
			734 => rule_446(ctx, v, l, loc)
			# CreateForeignServerStmt: CREATE SERVER name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options
			735 => rule_735(ctx, v, l, loc)
			# CreateForeignServerStmt: CREATE SERVER IF_P NOT EXISTS name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options
			736 => rule_736(ctx, v, l, loc)
			# opt_type: TYPE_P Sconst
			737 => rule_485(ctx, v, l, loc)
			# opt_type: %empty
			738 => rule_138(ctx, v, l, loc)
			# foreign_server_version: VERSION_P Sconst
			739 => rule_485(ctx, v, l, loc)
			# foreign_server_version: VERSION_P NULL_P
			740 => rule_244(ctx, v, l, loc)
			# opt_foreign_server_version: foreign_server_version
			741 => rule_137(ctx, v, l, loc)
			# opt_foreign_server_version: %empty
			742 => rule_138(ctx, v, l, loc)
			# AlterForeignServerStmt: ALTER SERVER name foreign_server_version alter_generic_options
			743 => rule_743(ctx, v, l, loc)
			# AlterForeignServerStmt: ALTER SERVER name foreign_server_version
			744 => rule_744(ctx, v, l, loc)
			# AlterForeignServerStmt: ALTER SERVER name alter_generic_options
			745 => rule_745(ctx, v, l, loc)
			# CreateForeignTableStmt: CREATE FOREIGN TABLE qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options
			746 => rule_746(ctx, v, l, loc, 112, 0)
			# CreateForeignTableStmt: CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options
			747 => rule_747(ctx, v, l, loc, 112, 0)
			# CreateForeignTableStmt: CREATE FOREIGN TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options
			748 => rule_748(ctx, v, l, loc, 112, 0)
			# CreateForeignTableStmt: CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options
			749 => rule_749(ctx, v, l, loc, 112, 0)
			# ImportForeignSchemaStmt: IMPORT_P FOREIGN SCHEMA name import_qualification FROM SERVER name INTO name create_generic_options
			750 => rule_750(ctx, v, l, loc)
			# import_qualification_type: LIMIT TO
			751 => rule_143(ctx, v, l, loc, 1)
			# import_qualification_type: EXCEPT
			752 => rule_143(ctx, v, l, loc, 2)
			# import_qualification: import_qualification_type '(' relation_expr_list ')'
			753 => rule_753(ctx, v, l, loc)
			# import_qualification: %empty
			754 => rule_754(ctx, v, l, loc, 0)
			# CreateUserMappingStmt: CREATE USER MAPPING FOR auth_ident SERVER name create_generic_options
			755 => rule_755(ctx, v, l, loc)
			# CreateUserMappingStmt: CREATE USER MAPPING IF_P NOT EXISTS FOR auth_ident SERVER name create_generic_options
			756 => rule_756(ctx, v, l, loc)
			# auth_ident: RoleSpec
			757 => rule_164(ctx, v, l, loc)
			# auth_ident: USER
			758 => rule_758(ctx, v, l, loc, 2)
			# DropUserMappingStmt: DROP USER MAPPING FOR auth_ident SERVER name
			759 => rule_759(ctx, v, l, loc)
			# DropUserMappingStmt: DROP USER MAPPING IF_P EXISTS FOR auth_ident SERVER name
			760 => rule_760(ctx, v, l, loc)
			# AlterUserMappingStmt: ALTER USER MAPPING FOR auth_ident SERVER name alter_generic_options
			761 => rule_761(ctx, v, l, loc)
			# CreatePolicyStmt: CREATE POLICY name ON qualified_name RowSecurityDefaultPermissive RowSecurityDefaultForCmd RowSecurityDefaultToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck
			762 => rule_762(ctx, v, l, loc)
			# AlterPolicyStmt: ALTER POLICY name ON qualified_name RowSecurityOptionalToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck
			763 => rule_763(ctx, v, l, loc)
			# RowSecurityOptionalExpr: USING '(' a_expr ')'
			764 => rule_364(ctx, v, l, loc)
			# RowSecurityOptionalExpr: %empty
			765 => rule_136(ctx, v, l, loc)
			# RowSecurityOptionalWithCheck: WITH CHECK '(' a_expr ')'
			766 => rule_766(ctx, v, l, loc)
			# RowSecurityOptionalWithCheck: %empty
			767 => rule_136(ctx, v, l, loc)
			# RowSecurityDefaultToRole: TO role_list
			768 => rule_374(ctx, v, l, loc)
			# RowSecurityDefaultToRole: %empty
			769 => rule_769(ctx, v, l, loc, 4, 1)
			# RowSecurityOptionalToRole: TO role_list
			770 => rule_374(ctx, v, l, loc)
			# RowSecurityOptionalToRole: %empty
			771 => rule_140(ctx, v, l, loc)
			# RowSecurityDefaultPermissive: AS IDENT
			772 => rule_772(ctx, v, l, loc, 0, 0)
			# RowSecurityDefaultPermissive: %empty
			773 => rule_510(ctx, v, l, loc)
			# RowSecurityDefaultForCmd: FOR row_security_cmd
			774 => rule_485(ctx, v, l, loc)
			# RowSecurityDefaultForCmd: %empty
			775 => rule_775(ctx, v, l, loc)
			# row_security_cmd: ALL
			776 => rule_776(ctx, v, l, loc)
			# row_security_cmd: SELECT
			777 => rule_777(ctx, v, l, loc)
			# row_security_cmd: INSERT
			778 => rule_778(ctx, v, l, loc)
			# row_security_cmd: UPDATE
			779 => rule_779(ctx, v, l, loc)
			# row_security_cmd: DELETE_P
			780 => rule_780(ctx, v, l, loc)
			# CreateAmStmt: CREATE ACCESS METHOD name TYPE_P am_type HANDLER handler_name
			781 => rule_781(ctx, v, l, loc)
			# am_type: INDEX
			782 => rule_143(ctx, v, l, loc, 105)
			# am_type: TABLE
			783 => rule_143(ctx, v, l, loc, 116)
			# CreateTrigStmt: CREATE opt_or_replace TRIGGER name TriggerActionTime TriggerEvents ON qualified_name TriggerReferencing TriggerForSpec TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')'
			784 => rule_784(ctx, v, l, loc)
			# CreateTrigStmt: CREATE opt_or_replace CONSTRAINT TRIGGER name AFTER TriggerEvents ON qualified_name OptConstrFromTable ConstraintAttributeSpec FOR EACH ROW TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')'
			785 => rule_785(ctx, v, l, loc, 0)
			# TriggerActionTime: BEFORE
			786 => rule_143(ctx, v, l, loc, 2)
			# TriggerActionTime: AFTER
			787 => rule_143(ctx, v, l, loc, 0)
			# TriggerActionTime: INSTEAD OF
			788 => rule_143(ctx, v, l, loc, 64)
			# TriggerEvents: TriggerOneEvent
			789 => rule_139(ctx, v, l, loc)
			# TriggerEvents: TriggerEvents OR TriggerOneEvent
			790 => rule_790(ctx, v, l, loc)
			# TriggerOneEvent: INSERT
			791 => rule_791(ctx, v, l, loc, 4)
			# TriggerOneEvent: DELETE_P
			792 => rule_791(ctx, v, l, loc, 8)
			# TriggerOneEvent: UPDATE
			793 => rule_791(ctx, v, l, loc, 16)
			# TriggerOneEvent: UPDATE OF columnList
			794 => rule_794(ctx, v, l, loc, 16)
			# TriggerOneEvent: TRUNCATE
			795 => rule_791(ctx, v, l, loc, 32)
			# TriggerReferencing: REFERENCING TriggerTransitions
			796 => rule_374(ctx, v, l, loc)
			# TriggerReferencing: %empty
			797 => rule_140(ctx, v, l, loc)
			# TriggerTransitions: TriggerTransition
			798 => rule_224(ctx, v, l, loc)
			# TriggerTransitions: TriggerTransitions TriggerTransition
			799 => rule_151(ctx, v, l, loc)
			# TriggerTransition: TransitionOldOrNew TransitionRowOrTable opt_as TransitionRelName
			800 => rule_800(ctx, v, l, loc)
			# TransitionOldOrNew: NEW
			801 => rule_141(ctx, v, l, loc)
			# TransitionOldOrNew: OLD
			802 => rule_268(ctx, v, l, loc)
			# TransitionRowOrTable: TABLE
			803 => rule_141(ctx, v, l, loc)
			# TransitionRowOrTable: ROW
			804 => rule_268(ctx, v, l, loc)
			# TransitionRelName: ColId
			805 => rule_137(ctx, v, l, loc)
			# TriggerForSpec: FOR TriggerForOptEach TriggerForType
			806 => rule_806(ctx, v, l, loc)
			# TriggerForSpec: %empty
			807 => rule_142(ctx, v, l, loc)
			# TriggerForType: ROW
			810 => rule_141(ctx, v, l, loc)
			# TriggerForType: STATEMENT
			811 => rule_268(ctx, v, l, loc)
			# TriggerWhen: WHEN '(' a_expr ')'
			812 => rule_364(ctx, v, l, loc)
			# TriggerWhen: %empty
			813 => rule_136(ctx, v, l, loc)
			# TriggerFuncArgs: TriggerFuncArg
			816 => rule_224(ctx, v, l, loc)
			# TriggerFuncArgs: TriggerFuncArgs ',' TriggerFuncArg
			817 => rule_225(ctx, v, l, loc)
			# TriggerFuncArgs: %empty
			818 => rule_140(ctx, v, l, loc)
			# TriggerFuncArg: Iconst
			819 => rule_819(ctx, v, l, loc)
			# TriggerFuncArg: FCONST
			820 => rule_446(ctx, v, l, loc)
			# TriggerFuncArg: Sconst
			821 => rule_446(ctx, v, l, loc)
			# TriggerFuncArg: ColLabel
			822 => rule_446(ctx, v, l, loc)
			# OptConstrFromTable: FROM qualified_name
			823 => rule_248(ctx, v, l, loc)
			# OptConstrFromTable: %empty
			824 => rule_136(ctx, v, l, loc)
			# ConstraintAttributeSpec: %empty
			825 => rule_145(ctx, v, l, loc, 0)
			# ConstraintAttributeSpec: ConstraintAttributeSpec ConstraintAttributeElem
			826 => rule_826(ctx, v, l, loc, 1, 8, 1, 8, 1, 2, 1, 2, 4, 8, 4, 8, 64, 128, 64, 128)
			# ConstraintAttributeElem: NOT DEFERRABLE
			827 => rule_143(ctx, v, l, loc, 1)
			# ConstraintAttributeElem: DEFERRABLE
			828 => rule_143(ctx, v, l, loc, 2)
			# ConstraintAttributeElem: INITIALLY IMMEDIATE
			829 => rule_143(ctx, v, l, loc, 4)
			# ConstraintAttributeElem: INITIALLY DEFERRED
			830 => rule_143(ctx, v, l, loc, 8)
			# ConstraintAttributeElem: NOT VALID
			831 => rule_143(ctx, v, l, loc, 16)
			# ConstraintAttributeElem: NO INHERIT
			832 => rule_143(ctx, v, l, loc, 32)
			# ConstraintAttributeElem: NOT ENFORCED
			833 => rule_143(ctx, v, l, loc, 64)
			# ConstraintAttributeElem: ENFORCED
			834 => rule_143(ctx, v, l, loc, 128)
			# CreateEventTrigStmt: CREATE EVENT TRIGGER name ON ColLabel EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')'
			835 => rule_835(ctx, v, l, loc)
			# CreateEventTrigStmt: CREATE EVENT TRIGGER name ON ColLabel WHEN event_trigger_when_list EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')'
			836 => rule_836(ctx, v, l, loc)
			# event_trigger_when_list: event_trigger_when_item
			837 => rule_224(ctx, v, l, loc)
			# event_trigger_when_list: event_trigger_when_list AND event_trigger_when_item
			838 => rule_225(ctx, v, l, loc)
			# event_trigger_when_item: ColId IN_P '(' event_trigger_value_list ')'
			839 => rule_839(ctx, v, l, loc)
			# event_trigger_value_list: SCONST
			840 => rule_670(ctx, v, l, loc)
			# event_trigger_value_list: event_trigger_value_list ',' SCONST
			841 => rule_841(ctx, v, l, loc)
			# AlterEventTrigStmt: ALTER EVENT TRIGGER name enable_trigger
			842 => rule_842(ctx, v, l, loc)
			# enable_trigger: ENABLE_P
			843 => rule_143(ctx, v, l, loc, 79)
			# enable_trigger: ENABLE_P REPLICA
			844 => rule_143(ctx, v, l, loc, 82)
			# enable_trigger: ENABLE_P ALWAYS
			845 => rule_143(ctx, v, l, loc, 65)
			# enable_trigger: DISABLE_P
			846 => rule_143(ctx, v, l, loc, 68)
			# CreateAssertionStmt: CREATE ASSERTION any_name CHECK '(' a_expr ')' ConstraintAttributeSpec
			847 => rule_847(ctx, v, l, loc)
			# DefineStmt: CREATE opt_or_replace AGGREGATE func_name aggr_args definition
			848 => rule_848(ctx, v, l, loc, 1)
			# DefineStmt: CREATE opt_or_replace AGGREGATE func_name old_aggr_definition
			849 => rule_849(ctx, v, l, loc, 1)
			# DefineStmt: CREATE OPERATOR any_operator definition
			850 => rule_850(ctx, v, l, loc, 25)
			# DefineStmt: CREATE TYPE_P any_name definition
			851 => rule_850(ctx, v, l, loc, 49)
			# DefineStmt: CREATE TYPE_P any_name
			852 => rule_852(ctx, v, l, loc, 49)
			# DefineStmt: CREATE TYPE_P any_name AS '(' OptTableFuncElementList ')'
			853 => rule_853(ctx, v, l, loc)
			# DefineStmt: CREATE TYPE_P any_name AS ENUM_P '(' opt_enum_val_list ')'
			854 => rule_854(ctx, v, l, loc)
			# DefineStmt: CREATE TYPE_P any_name AS RANGE definition
			855 => rule_855(ctx, v, l, loc)
			# DefineStmt: CREATE TEXT_P SEARCH PARSER any_name definition
			856 => rule_856(ctx, v, l, loc, 47)
			# DefineStmt: CREATE TEXT_P SEARCH DICTIONARY any_name definition
			857 => rule_856(ctx, v, l, loc, 46)
			# DefineStmt: CREATE TEXT_P SEARCH TEMPLATE any_name definition
			858 => rule_856(ctx, v, l, loc, 48)
			# DefineStmt: CREATE TEXT_P SEARCH CONFIGURATION any_name definition
			859 => rule_856(ctx, v, l, loc, 45)
			# DefineStmt: CREATE COLLATION any_name definition
			860 => rule_860(ctx, v, l, loc, 7)
			# DefineStmt: CREATE COLLATION IF_P NOT EXISTS any_name definition
			861 => rule_861(ctx, v, l, loc, 7)
			# DefineStmt: CREATE COLLATION any_name FROM any_name
			862 => rule_862(ctx, v, l, loc, 7)
			# DefineStmt: CREATE COLLATION IF_P NOT EXISTS any_name FROM any_name
			863 => rule_863(ctx, v, l, loc, 7)
			# definition: '(' def_list ')'
			864 => rule_374(ctx, v, l, loc)
			# def_list: def_elem
			865 => rule_224(ctx, v, l, loc)
			# def_list: def_list ',' def_elem
			866 => rule_225(ctx, v, l, loc)
			# def_elem: ColLabel '=' def_arg
			867 => rule_379(ctx, v, l, loc)
			# def_elem: ColLabel
			868 => rule_380(ctx, v, l, loc)
			# def_arg: func_type
			869 => rule_164(ctx, v, l, loc)
			# def_arg: reserved_keyword
			870 => rule_446(ctx, v, l, loc)
			# def_arg: qual_all_Op
			871 => rule_871(ctx, v, l, loc)
			# def_arg: NumericOnly
			872 => rule_164(ctx, v, l, loc)
			# def_arg: Sconst
			873 => rule_446(ctx, v, l, loc)
			# def_arg: NONE
			874 => rule_446(ctx, v, l, loc)
			# old_aggr_definition: '(' old_aggr_list ')'
			875 => rule_374(ctx, v, l, loc)
			# old_aggr_list: old_aggr_elem
			876 => rule_224(ctx, v, l, loc)
			# old_aggr_list: old_aggr_list ',' old_aggr_elem
			877 => rule_225(ctx, v, l, loc)
			# old_aggr_elem: IDENT '=' def_arg
			878 => rule_379(ctx, v, l, loc)
			# opt_enum_val_list: enum_val_list
			879 => rule_139(ctx, v, l, loc)
			# opt_enum_val_list: %empty
			880 => rule_140(ctx, v, l, loc)
			# enum_val_list: Sconst
			881 => rule_670(ctx, v, l, loc)
			# enum_val_list: enum_val_list ',' Sconst
			882 => rule_841(ctx, v, l, loc)
			# AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst
			883 => rule_883(ctx, v, l, loc)
			# AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst BEFORE Sconst
			884 => rule_884(ctx, v, l, loc)
			# AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst AFTER Sconst
			885 => rule_885(ctx, v, l, loc)
			# AlterEnumStmt: ALTER TYPE_P any_name RENAME VALUE_P Sconst TO Sconst
			886 => rule_886(ctx, v, l, loc)
			# AlterEnumStmt: ALTER TYPE_P any_name DROP VALUE_P Sconst
			887 => rule_887(ctx, v, l, loc)
			# opt_if_not_exists: IF_P NOT EXISTS
			888 => rule_141(ctx, v, l, loc)
			# opt_if_not_exists: %empty
			889 => rule_142(ctx, v, l, loc)
			# CreateOpClassStmt: CREATE OPERATOR CLASS any_name opt_default FOR TYPE_P Typename USING name opt_opfamily AS opclass_item_list
			890 => rule_890(ctx, v, l, loc)
			# opclass_item_list: opclass_item
			891 => rule_224(ctx, v, l, loc)
			# opclass_item_list: opclass_item_list ',' opclass_item
			892 => rule_225(ctx, v, l, loc)
			# opclass_item: OPERATOR Iconst any_operator opclass_purpose
			893 => rule_893(ctx, v, l, loc, 1)
			# opclass_item: OPERATOR Iconst operator_with_argtypes opclass_purpose
			894 => rule_894(ctx, v, l, loc, 1)
			# opclass_item: FUNCTION Iconst function_with_argtypes
			895 => rule_895(ctx, v, l, loc, 2)
			# opclass_item: FUNCTION Iconst '(' type_list ')' function_with_argtypes
			896 => rule_896(ctx, v, l, loc, 2)
			# opclass_item: STORAGE Typename
			897 => rule_897(ctx, v, l, loc, 3)
			# opt_default: DEFAULT
			898 => rule_141(ctx, v, l, loc)
			# opt_default: %empty
			899 => rule_142(ctx, v, l, loc)
			# opt_opfamily: FAMILY any_name
			900 => rule_374(ctx, v, l, loc)
			# opt_opfamily: %empty
			901 => rule_140(ctx, v, l, loc)
			# opclass_purpose: FOR SEARCH
			902 => rule_265(ctx, v, l, loc)
			# opclass_purpose: FOR ORDER BY any_name
			903 => rule_903(ctx, v, l, loc)
			# opclass_purpose: %empty
			904 => rule_140(ctx, v, l, loc)
			# CreateOpFamilyStmt: CREATE OPERATOR FAMILY any_name USING name
			905 => rule_905(ctx, v, l, loc)
			# AlterOpFamilyStmt: ALTER OPERATOR FAMILY any_name USING name ADD_P opclass_item_list
			906 => rule_906(ctx, v, l, loc)
			# AlterOpFamilyStmt: ALTER OPERATOR FAMILY any_name USING name DROP opclass_drop_list
			907 => rule_907(ctx, v, l, loc)
			# opclass_drop_list: opclass_drop
			908 => rule_224(ctx, v, l, loc)
			# opclass_drop_list: opclass_drop_list ',' opclass_drop
			909 => rule_225(ctx, v, l, loc)
			# opclass_drop: OPERATOR Iconst '(' type_list ')'
			910 => rule_910(ctx, v, l, loc, 1)
			# opclass_drop: FUNCTION Iconst '(' type_list ')'
			911 => rule_910(ctx, v, l, loc, 2)
			# DropOpClassStmt: DROP OPERATOR CLASS any_name USING name opt_drop_behavior
			912 => rule_912(ctx, v, l, loc, 24)
			# DropOpClassStmt: DROP OPERATOR CLASS IF_P EXISTS any_name USING name opt_drop_behavior
			913 => rule_913(ctx, v, l, loc, 24)
			# DropOpFamilyStmt: DROP OPERATOR FAMILY any_name USING name opt_drop_behavior
			914 => rule_912(ctx, v, l, loc, 26)
			# DropOpFamilyStmt: DROP OPERATOR FAMILY IF_P EXISTS any_name USING name opt_drop_behavior
			915 => rule_913(ctx, v, l, loc, 26)
			# DropOwnedStmt: DROP OWNED BY role_list opt_drop_behavior
			916 => rule_916(ctx, v, l, loc)
			# ReassignOwnedStmt: REASSIGN OWNED BY role_list TO RoleSpec
			917 => rule_917(ctx, v, l, loc)
			# DropStmt: DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior
			918 => rule_918(ctx, v, l, loc)
			# DropStmt: DROP object_type_any_name any_name_list opt_drop_behavior
			919 => rule_919(ctx, v, l, loc)
			# DropStmt: DROP drop_type_name IF_P EXISTS name_list opt_drop_behavior
			920 => rule_918(ctx, v, l, loc)
			# DropStmt: DROP drop_type_name name_list opt_drop_behavior
			921 => rule_919(ctx, v, l, loc)
			# DropStmt: DROP object_type_name_on_any_name name ON any_name opt_drop_behavior
			922 => rule_922(ctx, v, l, loc)
			# DropStmt: DROP object_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior
			923 => rule_923(ctx, v, l, loc)
			# DropStmt: DROP TYPE_P type_name_list opt_drop_behavior
			924 => rule_924(ctx, v, l, loc, 49)
			# DropStmt: DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior
			925 => rule_925(ctx, v, l, loc, 49)
			# DropStmt: DROP DOMAIN_P type_name_list opt_drop_behavior
			926 => rule_924(ctx, v, l, loc, 12)
			# DropStmt: DROP DOMAIN_P IF_P EXISTS type_name_list opt_drop_behavior
			927 => rule_925(ctx, v, l, loc, 12)
			# DropStmt: DROP INDEX CONCURRENTLY any_name_list opt_drop_behavior
			928 => rule_928(ctx, v, l, loc, 20)
			# DropStmt: DROP INDEX CONCURRENTLY IF_P EXISTS any_name_list opt_drop_behavior
			929 => rule_929(ctx, v, l, loc, 20)
			# object_type_any_name: TABLE
			930 => rule_143(ctx, v, l, loc, 41)
			# object_type_any_name: SEQUENCE
			931 => rule_143(ctx, v, l, loc, 37)
			# object_type_any_name: VIEW
			932 => rule_143(ctx, v, l, loc, 51)
			# object_type_any_name: MATERIALIZED VIEW
			933 => rule_143(ctx, v, l, loc, 23)
			# object_type_any_name: INDEX
			934 => rule_143(ctx, v, l, loc, 20)
			# object_type_any_name: FOREIGN TABLE
			935 => rule_143(ctx, v, l, loc, 18)
			# object_type_any_name: COLLATION
			936 => rule_143(ctx, v, l, loc, 7)
			# object_type_any_name: CONVERSION_P
			937 => rule_143(ctx, v, l, loc, 8)
			# object_type_any_name: STATISTICS
			938 => rule_143(ctx, v, l, loc, 39)
			# object_type_any_name: TEXT_P SEARCH PARSER
			939 => rule_143(ctx, v, l, loc, 47)
			# object_type_any_name: TEXT_P SEARCH DICTIONARY
			940 => rule_143(ctx, v, l, loc, 46)
			# object_type_any_name: TEXT_P SEARCH TEMPLATE
			941 => rule_143(ctx, v, l, loc, 48)
			# object_type_any_name: TEXT_P SEARCH CONFIGURATION
			942 => rule_143(ctx, v, l, loc, 45)
			# object_type_name: drop_type_name
			943 => rule_943(ctx, v, l, loc)
			# object_type_name: DATABASE
			944 => rule_143(ctx, v, l, loc, 9)
			# object_type_name: ROLE
			945 => rule_143(ctx, v, l, loc, 33)
			# object_type_name: SUBSCRIPTION
			946 => rule_143(ctx, v, l, loc, 38)
			# object_type_name: TABLESPACE
			947 => rule_143(ctx, v, l, loc, 42)
			# drop_type_name: ACCESS METHOD
			948 => rule_143(ctx, v, l, loc, 0)
			# drop_type_name: EVENT TRIGGER
			949 => rule_143(ctx, v, l, loc, 14)
			# drop_type_name: EXTENSION
			950 => rule_143(ctx, v, l, loc, 15)
			# drop_type_name: FOREIGN DATA_P WRAPPER
			951 => rule_143(ctx, v, l, loc, 16)
			# drop_type_name: opt_procedural LANGUAGE
			952 => rule_143(ctx, v, l, loc, 21)
			# drop_type_name: PUBLICATION
			953 => rule_143(ctx, v, l, loc, 30)
			# drop_type_name: SCHEMA
			954 => rule_143(ctx, v, l, loc, 36)
			# drop_type_name: SERVER
			955 => rule_143(ctx, v, l, loc, 17)
			# object_type_name_on_any_name: POLICY
			956 => rule_143(ctx, v, l, loc, 28)
			# object_type_name_on_any_name: RULE
			957 => rule_143(ctx, v, l, loc, 35)
			# object_type_name_on_any_name: TRIGGER
			958 => rule_143(ctx, v, l, loc, 44)
			# any_name_list: any_name
			959 => rule_569(ctx, v, l, loc)
			# any_name_list: any_name_list ',' any_name
			960 => rule_570(ctx, v, l, loc)
			# any_name: ColId
			961 => rule_670(ctx, v, l, loc)
			# any_name: ColId attrs
			962 => rule_671(ctx, v, l, loc)
			# attrs: '.' attr_name
			963 => rule_963(ctx, v, l, loc)
			# attrs: attrs '.' attr_name
			964 => rule_841(ctx, v, l, loc)
			# type_name_list: Typename
			965 => rule_224(ctx, v, l, loc)
			# type_name_list: type_name_list ',' Typename
			966 => rule_225(ctx, v, l, loc)
			# TruncateStmt: TRUNCATE opt_table relation_expr_list opt_restart_seqs opt_drop_behavior
			967 => rule_967(ctx, v, l, loc)
			# opt_restart_seqs: CONTINUE_P IDENTITY_P
			968 => rule_268(ctx, v, l, loc)
			# opt_restart_seqs: RESTART IDENTITY_P
			969 => rule_141(ctx, v, l, loc)
			# opt_restart_seqs: %empty
			970 => rule_142(ctx, v, l, loc)
			# CommentStmt: COMMENT ON object_type_any_name any_name IS comment_text
			971 => rule_971(ctx, v, l, loc)
			# CommentStmt: COMMENT ON COLUMN any_name IS comment_text
			972 => rule_972(ctx, v, l, loc, 6)
			# CommentStmt: COMMENT ON object_type_name name IS comment_text
			973 => rule_973(ctx, v, l, loc)
			# CommentStmt: COMMENT ON TYPE_P Typename IS comment_text
			974 => rule_974(ctx, v, l, loc, 49)
			# CommentStmt: COMMENT ON DOMAIN_P Typename IS comment_text
			975 => rule_974(ctx, v, l, loc, 12)
			# CommentStmt: COMMENT ON AGGREGATE aggregate_with_argtypes IS comment_text
			976 => rule_974(ctx, v, l, loc, 1)
			# CommentStmt: COMMENT ON FUNCTION function_with_argtypes IS comment_text
			977 => rule_974(ctx, v, l, loc, 19)
			# CommentStmt: COMMENT ON OPERATOR operator_with_argtypes IS comment_text
			978 => rule_974(ctx, v, l, loc, 25)
			# CommentStmt: COMMENT ON CONSTRAINT name ON any_name IS comment_text
			979 => rule_979(ctx, v, l, loc, 40)
			# CommentStmt: COMMENT ON CONSTRAINT name ON DOMAIN_P any_name IS comment_text
			980 => rule_980(ctx, v, l, loc, 13)
			# CommentStmt: COMMENT ON object_type_name_on_any_name name ON any_name IS comment_text
			981 => rule_981(ctx, v, l, loc)
			# CommentStmt: COMMENT ON PROCEDURE function_with_argtypes IS comment_text
			982 => rule_974(ctx, v, l, loc, 29)
			# CommentStmt: COMMENT ON ROUTINE function_with_argtypes IS comment_text
			983 => rule_974(ctx, v, l, loc, 34)
			# CommentStmt: COMMENT ON TRANSFORM FOR Typename LANGUAGE name IS comment_text
			984 => rule_984(ctx, v, l, loc, 43)
			# CommentStmt: COMMENT ON OPERATOR CLASS any_name USING name IS comment_text
			985 => rule_985(ctx, v, l, loc, 24)
			# CommentStmt: COMMENT ON OPERATOR FAMILY any_name USING name IS comment_text
			986 => rule_985(ctx, v, l, loc, 26)
			# CommentStmt: COMMENT ON LARGE_P OBJECT_P NumericOnly IS comment_text
			987 => rule_987(ctx, v, l, loc, 22)
			# CommentStmt: COMMENT ON CAST '(' Typename AS Typename ')' IS comment_text
			988 => rule_988(ctx, v, l, loc, 5)
			# comment_text: Sconst
			989 => rule_137(ctx, v, l, loc)
			# comment_text: NULL_P
			990 => rule_244(ctx, v, l, loc)
			# SecLabelStmt: SECURITY LABEL opt_provider ON object_type_any_name any_name IS security_label
			991 => rule_991(ctx, v, l, loc)
			# SecLabelStmt: SECURITY LABEL opt_provider ON COLUMN any_name IS security_label
			992 => rule_992(ctx, v, l, loc, 6)
			# SecLabelStmt: SECURITY LABEL opt_provider ON object_type_name name IS security_label
			993 => rule_993(ctx, v, l, loc)
			# SecLabelStmt: SECURITY LABEL opt_provider ON TYPE_P Typename IS security_label
			994 => rule_994(ctx, v, l, loc, 49)
			# SecLabelStmt: SECURITY LABEL opt_provider ON DOMAIN_P Typename IS security_label
			995 => rule_994(ctx, v, l, loc, 12)
			# SecLabelStmt: SECURITY LABEL opt_provider ON AGGREGATE aggregate_with_argtypes IS security_label
			996 => rule_994(ctx, v, l, loc, 1)
			# SecLabelStmt: SECURITY LABEL opt_provider ON FUNCTION function_with_argtypes IS security_label
			997 => rule_994(ctx, v, l, loc, 19)
			# SecLabelStmt: SECURITY LABEL opt_provider ON LARGE_P OBJECT_P NumericOnly IS security_label
			998 => rule_998(ctx, v, l, loc, 22)
			# SecLabelStmt: SECURITY LABEL opt_provider ON PROCEDURE function_with_argtypes IS security_label
			999 => rule_994(ctx, v, l, loc, 29)
			# SecLabelStmt: SECURITY LABEL opt_provider ON ROUTINE function_with_argtypes IS security_label
			1000 => rule_994(ctx, v, l, loc, 34)
			# opt_provider: FOR NonReservedWord_or_Sconst
			1001 => rule_485(ctx, v, l, loc)
			# opt_provider: %empty
			1002 => rule_138(ctx, v, l, loc)
			# security_label: Sconst
			1003 => rule_137(ctx, v, l, loc)
			# security_label: NULL_P
			1004 => rule_244(ctx, v, l, loc)
			# FetchStmt: FETCH fetch_args
			1005 => rule_1005(ctx, v, l, loc)
			# FetchStmt: MOVE fetch_args
			1006 => rule_1006(ctx, v, l, loc)
			# fetch_args: cursor_name
			1007 => rule_1007(ctx, v, l, loc, 0, 1)
			# fetch_args: from_in cursor_name
			1008 => rule_1008(ctx, v, l, loc, 0, 1)
			# fetch_args: NEXT opt_from_in cursor_name
			1009 => rule_1009(ctx, v, l, loc, 0, 1)
			# fetch_args: PRIOR opt_from_in cursor_name
			1010 => rule_1009(ctx, v, l, loc, 1, 1)
			# fetch_args: FIRST_P opt_from_in cursor_name
			1011 => rule_1009(ctx, v, l, loc, 2, 1)
			# fetch_args: LAST_P opt_from_in cursor_name
			1012 => rule_1012(ctx, v, l, loc, 2, 1)
			# fetch_args: ABSOLUTE_P SignedIconst opt_from_in cursor_name
			1013 => rule_1013(ctx, v, l, loc, 2)
			# fetch_args: RELATIVE_P SignedIconst opt_from_in cursor_name
			1014 => rule_1013(ctx, v, l, loc, 3)
			# fetch_args: SignedIconst opt_from_in cursor_name
			1015 => rule_1015(ctx, v, l, loc, 0)
			# fetch_args: ALL opt_from_in cursor_name
			1016 => rule_1009(ctx, v, l, loc, 0, 9223372036854775807)
			# fetch_args: FORWARD opt_from_in cursor_name
			1017 => rule_1009(ctx, v, l, loc, 0, 1)
			# fetch_args: FORWARD SignedIconst opt_from_in cursor_name
			1018 => rule_1013(ctx, v, l, loc, 0)
			# fetch_args: FORWARD ALL opt_from_in cursor_name
			1019 => rule_1019(ctx, v, l, loc, 0, 9223372036854775807)
			# fetch_args: BACKWARD opt_from_in cursor_name
			1020 => rule_1009(ctx, v, l, loc, 1, 1)
			# fetch_args: BACKWARD SignedIconst opt_from_in cursor_name
			1021 => rule_1013(ctx, v, l, loc, 1)
			# fetch_args: BACKWARD ALL opt_from_in cursor_name
			1022 => rule_1019(ctx, v, l, loc, 1, 9223372036854775807)
			# GrantStmt: GRANT privileges ON privilege_target TO grantee_list opt_grant_grant_option opt_granted_by
			1027 => rule_1027(ctx, v, l, loc)
			# RevokeStmt: REVOKE privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior
			1028 => rule_1028(ctx, v, l, loc)
			# RevokeStmt: REVOKE GRANT OPTION FOR privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior
			1029 => rule_1029(ctx, v, l, loc)
			# privileges: privilege_list
			1030 => rule_139(ctx, v, l, loc)
			# privileges: ALL
			1031 => rule_265(ctx, v, l, loc)
			# privileges: ALL PRIVILEGES
			1032 => rule_265(ctx, v, l, loc)
			# privileges: ALL '(' columnList ')'
			1033 => rule_1033(ctx, v, l, loc)
			# privileges: ALL PRIVILEGES '(' columnList ')'
			1034 => rule_1034(ctx, v, l, loc)
			# privilege_list: privilege
			1035 => rule_224(ctx, v, l, loc)
			# privilege_list: privilege_list ',' privilege
			1036 => rule_225(ctx, v, l, loc)
			# privilege: SELECT opt_column_list
			1037 => rule_1037(ctx, v, l, loc)
			# privilege: REFERENCES opt_column_list
			1038 => rule_1037(ctx, v, l, loc)
			# privilege: CREATE opt_column_list
			1039 => rule_1037(ctx, v, l, loc)
			# privilege: ALTER SYSTEM_P
			1040 => rule_1040(ctx, v, l, loc)
			# privilege: ColId opt_column_list
			1041 => rule_1041(ctx, v, l, loc)
			# parameter_name_list: parameter_name
			1042 => rule_670(ctx, v, l, loc)
			# parameter_name_list: parameter_name_list ',' parameter_name
			1043 => rule_841(ctx, v, l, loc)
			# parameter_name: ColId
			1044 => rule_137(ctx, v, l, loc)
			# parameter_name: parameter_name '.' ColId
			1045 => rule_223(ctx, v, l, loc)
			# privilege_target: qualified_name_list
			1046 => rule_1046(ctx, v, l, loc, 0, 41)
			# privilege_target: TABLE qualified_name_list
			1047 => rule_1047(ctx, v, l, loc, 0, 41)
			# privilege_target: SEQUENCE qualified_name_list
			1048 => rule_1047(ctx, v, l, loc, 0, 37)
			# privilege_target: FOREIGN DATA_P WRAPPER name_list
			1049 => rule_1049(ctx, v, l, loc, 0, 16)
			# privilege_target: FOREIGN SERVER name_list
			1050 => rule_1050(ctx, v, l, loc, 0, 17)
			# privilege_target: FUNCTION function_with_argtypes_list
			1051 => rule_1047(ctx, v, l, loc, 0, 19)
			# privilege_target: PROCEDURE function_with_argtypes_list
			1052 => rule_1047(ctx, v, l, loc, 0, 29)
			# privilege_target: ROUTINE function_with_argtypes_list
			1053 => rule_1047(ctx, v, l, loc, 0, 34)
			# privilege_target: DATABASE name_list
			1054 => rule_1047(ctx, v, l, loc, 0, 9)
			# privilege_target: DOMAIN_P any_name_list
			1055 => rule_1047(ctx, v, l, loc, 0, 12)
			# privilege_target: LANGUAGE name_list
			1056 => rule_1047(ctx, v, l, loc, 0, 21)
			# privilege_target: LARGE_P OBJECT_P NumericOnly_list
			1057 => rule_1050(ctx, v, l, loc, 0, 22)
			# privilege_target: PARAMETER parameter_name_list
			1058 => rule_1047(ctx, v, l, loc, 0, 27)
			# privilege_target: SCHEMA name_list
			1059 => rule_1047(ctx, v, l, loc, 0, 36)
			# privilege_target: TABLESPACE name_list
			1060 => rule_1047(ctx, v, l, loc, 0, 42)
			# privilege_target: TYPE_P any_name_list
			1061 => rule_1047(ctx, v, l, loc, 0, 49)
			# privilege_target: ALL TABLES IN_P SCHEMA name_list
			1062 => rule_1062(ctx, v, l, loc, 1, 41)
			# privilege_target: ALL SEQUENCES IN_P SCHEMA name_list
			1063 => rule_1062(ctx, v, l, loc, 1, 37)
			# privilege_target: ALL FUNCTIONS IN_P SCHEMA name_list
			1064 => rule_1062(ctx, v, l, loc, 1, 19)
			# privilege_target: ALL PROCEDURES IN_P SCHEMA name_list
			1065 => rule_1062(ctx, v, l, loc, 1, 29)
			# privilege_target: ALL ROUTINES IN_P SCHEMA name_list
			1066 => rule_1062(ctx, v, l, loc, 1, 34)
			# grantee_list: grantee
			1067 => rule_224(ctx, v, l, loc)
			# grantee_list: grantee_list ',' grantee
			1068 => rule_225(ctx, v, l, loc)
			# grantee: RoleSpec
			1069 => rule_164(ctx, v, l, loc)
			# grantee: GROUP_P RoleSpec
			1070 => rule_248(ctx, v, l, loc)
			# opt_grant_grant_option: WITH GRANT OPTION
			1071 => rule_141(ctx, v, l, loc)
			# opt_grant_grant_option: %empty
			1072 => rule_142(ctx, v, l, loc)
			# GrantRoleStmt: GRANT privilege_list TO role_list opt_granted_by
			1073 => rule_1073(ctx, v, l, loc)
			# GrantRoleStmt: GRANT privilege_list TO role_list WITH grant_role_opt_list opt_granted_by
			1074 => rule_1074(ctx, v, l, loc)
			# RevokeRoleStmt: REVOKE privilege_list FROM role_list opt_granted_by opt_drop_behavior
			1075 => rule_1075(ctx, v, l, loc)
			# RevokeRoleStmt: REVOKE ColId OPTION FOR privilege_list FROM role_list opt_granted_by opt_drop_behavior
			1076 => rule_1076(ctx, v, l, loc)
			# grant_role_opt_list: grant_role_opt_list ',' grant_role_opt
			1077 => rule_225(ctx, v, l, loc)
			# grant_role_opt_list: grant_role_opt
			1078 => rule_224(ctx, v, l, loc)
			# grant_role_opt: ColLabel grant_role_opt_value
			1079 => rule_445(ctx, v, l, loc)
			# grant_role_opt_value: OPTION
			1080 => rule_1080(ctx, v, l, loc)
			# grant_role_opt_value: TRUE_P
			1081 => rule_1080(ctx, v, l, loc)
			# grant_role_opt_value: FALSE_P
			1082 => rule_1082(ctx, v, l, loc)
			# opt_granted_by: GRANTED BY RoleSpec
			1083 => rule_364(ctx, v, l, loc)
			# opt_granted_by: %empty
			1084 => rule_136(ctx, v, l, loc)
			# AlterDefaultPrivilegesStmt: ALTER DEFAULT PRIVILEGES DefACLOptionList DefACLAction
			1085 => rule_1085(ctx, v, l, loc)
			# DefACLOptionList: DefACLOptionList DefACLOption
			1086 => rule_151(ctx, v, l, loc)
			# DefACLOptionList: %empty
			1087 => rule_140(ctx, v, l, loc)
			# DefACLOption: IN_P SCHEMA name_list
			1088 => rule_1088(ctx, v, l, loc)
			# DefACLOption: FOR ROLE role_list
			1089 => rule_1089(ctx, v, l, loc)
			# DefACLOption: FOR USER role_list
			1090 => rule_1089(ctx, v, l, loc)
			# DefACLAction: GRANT privileges ON defacl_privilege_target TO grantee_list opt_grant_grant_option
			1091 => rule_1091(ctx, v, l, loc, 2)
			# DefACLAction: REVOKE privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior
			1092 => rule_1092(ctx, v, l, loc, 2)
			# DefACLAction: REVOKE GRANT OPTION FOR privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior
			1093 => rule_1093(ctx, v, l, loc, 2)
			# defacl_privilege_target: TABLES
			1094 => rule_143(ctx, v, l, loc, 41)
			# defacl_privilege_target: FUNCTIONS
			1095 => rule_143(ctx, v, l, loc, 19)
			# defacl_privilege_target: ROUTINES
			1096 => rule_143(ctx, v, l, loc, 19)
			# defacl_privilege_target: SEQUENCES
			1097 => rule_143(ctx, v, l, loc, 37)
			# defacl_privilege_target: TYPES_P
			1098 => rule_143(ctx, v, l, loc, 49)
			# defacl_privilege_target: SCHEMAS
			1099 => rule_143(ctx, v, l, loc, 36)
			# defacl_privilege_target: LARGE_P OBJECTS_P
			1100 => rule_143(ctx, v, l, loc, 22)
			# IndexStmt: CREATE opt_unique INDEX opt_concurrently opt_single_name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_unique_null_treatment opt_reloptions OptTableSpace where_clause
			1101 => rule_1101(ctx, v, l, loc, 0, 0, 0, 0)
			# IndexStmt: CREATE opt_unique INDEX opt_concurrently IF_P NOT EXISTS name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_unique_null_treatment opt_reloptions OptTableSpace where_clause
			1102 => rule_1102(ctx, v, l, loc, 0, 0, 0, 0)
			# opt_unique: UNIQUE
			1103 => rule_141(ctx, v, l, loc)
			# opt_unique: %empty
			1104 => rule_142(ctx, v, l, loc)
			# access_method_clause: USING name
			1105 => rule_485(ctx, v, l, loc)
			# access_method_clause: %empty
			1106 => rule_1106(ctx, v, l, loc)
			# index_params: index_elem
			1107 => rule_224(ctx, v, l, loc)
			# index_params: index_params ',' index_elem
			1108 => rule_225(ctx, v, l, loc)
			# index_elem_options: opt_collate opt_qualified_name opt_asc_desc opt_nulls_order
			1109 => rule_1109(ctx, v, l, loc)
			# index_elem_options: opt_collate any_name reloptions opt_asc_desc opt_nulls_order
			1110 => rule_1110(ctx, v, l, loc)
			# index_elem: ColId index_elem_options
			1111 => rule_1111(ctx, v, l, loc)
			# index_elem: func_expr_windowless index_elem_options
			1112 => rule_1112(ctx, v, l, loc)
			# index_elem: '(' a_expr ')' index_elem_options
			1113 => rule_1113(ctx, v, l, loc)
			# opt_include: INCLUDE '(' index_including_params ')'
			1114 => rule_563(ctx, v, l, loc)
			# opt_include: %empty
			1115 => rule_140(ctx, v, l, loc)
			# index_including_params: index_elem
			1116 => rule_224(ctx, v, l, loc)
			# index_including_params: index_including_params ',' index_elem
			1117 => rule_225(ctx, v, l, loc)
			# opt_collate: COLLATE any_name
			1118 => rule_374(ctx, v, l, loc)
			# opt_collate: %empty
			1119 => rule_140(ctx, v, l, loc)
			# opt_asc_desc: ASC
			1120 => rule_143(ctx, v, l, loc, 1)
			# opt_asc_desc: DESC
			1121 => rule_143(ctx, v, l, loc, 2)
			# opt_asc_desc: %empty
			1122 => rule_145(ctx, v, l, loc, 0)
			# opt_nulls_order: NULLS_LA FIRST_P
			1123 => rule_143(ctx, v, l, loc, 1)
			# opt_nulls_order: NULLS_LA LAST_P
			1124 => rule_143(ctx, v, l, loc, 2)
			# opt_nulls_order: %empty
			1125 => rule_145(ctx, v, l, loc, 0)
			# CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS func_return opt_createfunc_opt_list opt_routine_body
			1126 => rule_1126(ctx, v, l, loc)
			# CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS TABLE '(' table_func_column_list ')' opt_createfunc_opt_list opt_routine_body
			1127 => rule_1127(ctx, v, l, loc)
			# CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body
			1128 => rule_1128(ctx, v, l, loc)
			# CreateFunctionStmt: CREATE opt_or_replace PROCEDURE func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body
			1129 => rule_1129(ctx, v, l, loc)
			# opt_or_replace: OR REPLACE
			1130 => rule_141(ctx, v, l, loc)
			# opt_or_replace: %empty
			1131 => rule_142(ctx, v, l, loc)
			# func_args: '(' func_args_list ')'
			1132 => rule_374(ctx, v, l, loc)
			# func_args: '(' ')'
			1133 => rule_265(ctx, v, l, loc)
			# func_args_list: func_arg
			1134 => rule_224(ctx, v, l, loc)
			# func_args_list: func_args_list ',' func_arg
			1135 => rule_225(ctx, v, l, loc)
			# function_with_argtypes_list: function_with_argtypes
			1136 => rule_224(ctx, v, l, loc)
			# function_with_argtypes_list: function_with_argtypes_list ',' function_with_argtypes
			1137 => rule_225(ctx, v, l, loc)
			# function_with_argtypes: func_name func_args
			1138 => rule_1138(ctx, v, l, loc)
			# function_with_argtypes: type_func_name_keyword
			1139 => rule_1139(ctx, v, l, loc)
			# function_with_argtypes: ColId
			1140 => rule_1139(ctx, v, l, loc)
			# function_with_argtypes: ColId indirection
			1141 => rule_1141(ctx, v, l, loc)
			# func_args_with_defaults: '(' func_args_with_defaults_list ')'
			1142 => rule_374(ctx, v, l, loc)
			# func_args_with_defaults: '(' ')'
			1143 => rule_265(ctx, v, l, loc)
			# func_args_with_defaults_list: func_arg_with_default
			1144 => rule_224(ctx, v, l, loc)
			# func_args_with_defaults_list: func_args_with_defaults_list ',' func_arg_with_default
			1145 => rule_225(ctx, v, l, loc)
			# func_arg: arg_class param_name func_type
			1146 => rule_1146(ctx, v, l, loc)
			# func_arg: param_name arg_class func_type
			1147 => rule_1147(ctx, v, l, loc)
			# func_arg: param_name func_type
			1148 => rule_1148(ctx, v, l, loc, 100)
			# func_arg: arg_class func_type
			1149 => rule_1149(ctx, v, l, loc)
			# func_arg: func_type
			1150 => rule_1150(ctx, v, l, loc, 100)
			# arg_class: IN_P
			1151 => rule_143(ctx, v, l, loc, 105)
			# arg_class: OUT_P
			1152 => rule_143(ctx, v, l, loc, 111)
			# arg_class: INOUT
			1153 => rule_143(ctx, v, l, loc, 98)
			# arg_class: IN_P OUT_P
			1154 => rule_143(ctx, v, l, loc, 98)
			# arg_class: VARIADIC
			1155 => rule_143(ctx, v, l, loc, 118)
			# func_return: func_type
			1157 => rule_164(ctx, v, l, loc)
			# func_type: Typename
			1158 => rule_164(ctx, v, l, loc)
			# func_type: type_function_name attrs '%' TYPE_P
			1159 => rule_1159(ctx, v, l, loc)
			# func_type: SETOF type_function_name attrs '%' TYPE_P
			1160 => rule_1160(ctx, v, l, loc)
			# func_arg_with_default: func_arg
			1161 => rule_164(ctx, v, l, loc)
			# func_arg_with_default: func_arg DEFAULT a_expr
			1162 => rule_1162(ctx, v, l, loc)
			# func_arg_with_default: func_arg '=' a_expr
			1163 => rule_1162(ctx, v, l, loc)
			# aggr_arg: func_arg
			1164 => rule_1164(ctx, v, l, loc, 100, 105, 118)
			# aggr_args: '(' '*' ')'
			1165 => rule_1165(ctx, v, l, loc, 1)
			# aggr_args: '(' aggr_args_list ')'
			1166 => rule_1166(ctx, v, l, loc, 1)
			# aggr_args: '(' ORDER BY aggr_args_list ')'
			1167 => rule_1167(ctx, v, l, loc, 0)
			# aggr_args: '(' aggr_args_list ORDER BY aggr_args_list ')'
			1168 => rule_1168(ctx, v, l, loc)
			# aggr_args_list: aggr_arg
			1169 => rule_224(ctx, v, l, loc)
			# aggr_args_list: aggr_args_list ',' aggr_arg
			1170 => rule_225(ctx, v, l, loc)
			# aggregate_with_argtypes: func_name aggr_args
			1171 => rule_1171(ctx, v, l, loc)
			# aggregate_with_argtypes_list: aggregate_with_argtypes
			1172 => rule_224(ctx, v, l, loc)
			# aggregate_with_argtypes_list: aggregate_with_argtypes_list ',' aggregate_with_argtypes
			1173 => rule_225(ctx, v, l, loc)
			# opt_createfunc_opt_list: %empty
			1175 => rule_140(ctx, v, l, loc)
			# createfunc_opt_list: createfunc_opt_item
			1176 => rule_224(ctx, v, l, loc)
			# createfunc_opt_list: createfunc_opt_list createfunc_opt_item
			1177 => rule_151(ctx, v, l, loc)
			# common_func_opt_item: CALLED ON NULL_P INPUT_P
			1178 => rule_1178(ctx, v, l, loc)
			# common_func_opt_item: RETURNS NULL_P ON NULL_P INPUT_P
			1179 => rule_1179(ctx, v, l, loc)
			# common_func_opt_item: STRICT_P
			1180 => rule_1179(ctx, v, l, loc)
			# common_func_opt_item: IMMUTABLE
			1181 => rule_1181(ctx, v, l, loc)
			# common_func_opt_item: STABLE
			1182 => rule_1182(ctx, v, l, loc)
			# common_func_opt_item: VOLATILE
			1183 => rule_1183(ctx, v, l, loc)
			# common_func_opt_item: EXTERNAL SECURITY DEFINER
			1184 => rule_1184(ctx, v, l, loc)
			# common_func_opt_item: EXTERNAL SECURITY INVOKER
			1185 => rule_1185(ctx, v, l, loc)
			# common_func_opt_item: SECURITY DEFINER
			1186 => rule_1184(ctx, v, l, loc)
			# common_func_opt_item: SECURITY INVOKER
			1187 => rule_1185(ctx, v, l, loc)
			# common_func_opt_item: LEAKPROOF
			1188 => rule_1188(ctx, v, l, loc)
			# common_func_opt_item: NOT LEAKPROOF
			1189 => rule_1189(ctx, v, l, loc)
			# common_func_opt_item: COST NumericOnly
			1190 => rule_1190(ctx, v, l, loc)
			# common_func_opt_item: ROWS NumericOnly
			1191 => rule_1191(ctx, v, l, loc)
			# common_func_opt_item: SUPPORT any_name
			1192 => rule_1192(ctx, v, l, loc)
			# common_func_opt_item: FunctionSetResetClause
			1193 => rule_1193(ctx, v, l, loc)
			# common_func_opt_item: PARALLEL ColId
			1194 => rule_1194(ctx, v, l, loc)
			# createfunc_opt_item: AS func_as
			1195 => rule_1195(ctx, v, l, loc)
			# createfunc_opt_item: LANGUAGE NonReservedWord_or_Sconst
			1196 => rule_1196(ctx, v, l, loc)
			# createfunc_opt_item: TRANSFORM transform_type_list
			1197 => rule_1197(ctx, v, l, loc)
			# createfunc_opt_item: WINDOW
			1198 => rule_1198(ctx, v, l, loc)
			# createfunc_opt_item: common_func_opt_item
			1199 => rule_164(ctx, v, l, loc)
			# func_as: Sconst
			1200 => rule_670(ctx, v, l, loc)
			# func_as: Sconst ',' Sconst
			1201 => rule_1201(ctx, v, l, loc)
			# ReturnStmt: RETURN a_expr
			1202 => rule_1202(ctx, v, l, loc)
			# opt_routine_body: ReturnStmt
			1203 => rule_164(ctx, v, l, loc)
			# opt_routine_body: BEGIN_P ATOMIC routine_body_stmt_list END_P
			1204 => rule_1204(ctx, v, l, loc)
			# opt_routine_body: %empty
			1205 => rule_136(ctx, v, l, loc)
			# routine_body_stmt_list: routine_body_stmt_list routine_body_stmt ';'
			1206 => rule_1206(ctx, v, l, loc)
			# routine_body_stmt_list: %empty
			1207 => rule_140(ctx, v, l, loc)
			# transform_type_list: FOR TYPE_P Typename
			1210 => rule_1210(ctx, v, l, loc)
			# transform_type_list: transform_type_list ',' FOR TYPE_P Typename
			1211 => rule_1211(ctx, v, l, loc)
			# opt_definition: WITH definition
			1212 => rule_374(ctx, v, l, loc)
			# opt_definition: %empty
			1213 => rule_140(ctx, v, l, loc)
			# table_func_column: param_name func_type
			1214 => rule_1148(ctx, v, l, loc, 116)
			# table_func_column_list: table_func_column
			1215 => rule_224(ctx, v, l, loc)
			# table_func_column_list: table_func_column_list ',' table_func_column
			1216 => rule_225(ctx, v, l, loc)
			# AlterFunctionStmt: ALTER FUNCTION function_with_argtypes alterfunc_opt_list opt_restrict
			1217 => rule_1217(ctx, v, l, loc, 19)
			# AlterFunctionStmt: ALTER PROCEDURE function_with_argtypes alterfunc_opt_list opt_restrict
			1218 => rule_1217(ctx, v, l, loc, 29)
			# AlterFunctionStmt: ALTER ROUTINE function_with_argtypes alterfunc_opt_list opt_restrict
			1219 => rule_1217(ctx, v, l, loc, 34)
			# alterfunc_opt_list: common_func_opt_item
			1220 => rule_224(ctx, v, l, loc)
			# alterfunc_opt_list: alterfunc_opt_list common_func_opt_item
			1221 => rule_151(ctx, v, l, loc)
			# RemoveFuncStmt: DROP FUNCTION function_with_argtypes_list opt_drop_behavior
			1224 => rule_1224(ctx, v, l, loc, 19)
			# RemoveFuncStmt: DROP FUNCTION IF_P EXISTS function_with_argtypes_list opt_drop_behavior
			1225 => rule_1225(ctx, v, l, loc, 19)
			# RemoveFuncStmt: DROP PROCEDURE function_with_argtypes_list opt_drop_behavior
			1226 => rule_1224(ctx, v, l, loc, 29)
			# RemoveFuncStmt: DROP PROCEDURE IF_P EXISTS function_with_argtypes_list opt_drop_behavior
			1227 => rule_1225(ctx, v, l, loc, 29)
			# RemoveFuncStmt: DROP ROUTINE function_with_argtypes_list opt_drop_behavior
			1228 => rule_1224(ctx, v, l, loc, 34)
			# RemoveFuncStmt: DROP ROUTINE IF_P EXISTS function_with_argtypes_list opt_drop_behavior
			1229 => rule_1225(ctx, v, l, loc, 34)
			# RemoveAggrStmt: DROP AGGREGATE aggregate_with_argtypes_list opt_drop_behavior
			1230 => rule_1224(ctx, v, l, loc, 1)
			# RemoveAggrStmt: DROP AGGREGATE IF_P EXISTS aggregate_with_argtypes_list opt_drop_behavior
			1231 => rule_1225(ctx, v, l, loc, 1)
			# RemoveOperStmt: DROP OPERATOR operator_with_argtypes_list opt_drop_behavior
			1232 => rule_1224(ctx, v, l, loc, 25)
			# RemoveOperStmt: DROP OPERATOR IF_P EXISTS operator_with_argtypes_list opt_drop_behavior
			1233 => rule_1225(ctx, v, l, loc, 25)
			# oper_argtypes: '(' Typename ')'
			1234 => rule_1234(ctx, v, l, loc)
			# oper_argtypes: '(' Typename ',' Typename ')'
			1235 => rule_1235(ctx, v, l, loc)
			# oper_argtypes: '(' NONE ',' Typename ')'
			1236 => rule_1236(ctx, v, l, loc)
			# oper_argtypes: '(' Typename ',' NONE ')'
			1237 => rule_1237(ctx, v, l, loc)
			# any_operator: all_Op
			1238 => rule_670(ctx, v, l, loc)
			# any_operator: ColId '.' any_operator
			1239 => rule_1239(ctx, v, l, loc)
			# operator_with_argtypes_list: operator_with_argtypes
			1240 => rule_224(ctx, v, l, loc)
			# operator_with_argtypes_list: operator_with_argtypes_list ',' operator_with_argtypes
			1241 => rule_225(ctx, v, l, loc)
			# operator_with_argtypes: any_operator oper_argtypes
			1242 => rule_1242(ctx, v, l, loc)
			# DoStmt: DO dostmt_opt_list
			1243 => rule_1243(ctx, v, l, loc)
			# dostmt_opt_list: dostmt_opt_item
			1244 => rule_224(ctx, v, l, loc)
			# dostmt_opt_list: dostmt_opt_list dostmt_opt_item
			1245 => rule_151(ctx, v, l, loc)
			# dostmt_opt_item: Sconst
			1246 => rule_1246(ctx, v, l, loc)
			# dostmt_opt_item: LANGUAGE NonReservedWord_or_Sconst
			1247 => rule_1196(ctx, v, l, loc)
			# CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITH FUNCTION function_with_argtypes cast_context
			1248 => rule_1248(ctx, v, l, loc)
			# CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITHOUT FUNCTION cast_context
			1249 => rule_1249(ctx, v, l, loc)
			# CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITH INOUT cast_context
			1250 => rule_1250(ctx, v, l, loc)
			# cast_context: AS IMPLICIT_P
			1251 => rule_143(ctx, v, l, loc, 0)
			# cast_context: AS ASSIGNMENT
			1252 => rule_143(ctx, v, l, loc, 1)
			# cast_context: %empty
			1253 => rule_145(ctx, v, l, loc, 3)
			# DropCastStmt: DROP CAST opt_if_exists '(' Typename AS Typename ')' opt_drop_behavior
			1254 => rule_1254(ctx, v, l, loc, 5)
			# opt_if_exists: IF_P EXISTS
			1255 => rule_141(ctx, v, l, loc)
			# opt_if_exists: %empty
			1256 => rule_142(ctx, v, l, loc)
			# CreateTransformStmt: CREATE opt_or_replace TRANSFORM FOR Typename LANGUAGE name '(' transform_element_list ')'
			1257 => rule_1257(ctx, v, l, loc)
			# transform_element_list: FROM SQL_P WITH FUNCTION function_with_argtypes ',' TO SQL_P WITH FUNCTION function_with_argtypes
			1258 => rule_1258(ctx, v, l, loc)
			# transform_element_list: TO SQL_P WITH FUNCTION function_with_argtypes ',' FROM SQL_P WITH FUNCTION function_with_argtypes
			1259 => rule_1259(ctx, v, l, loc)
			# transform_element_list: FROM SQL_P WITH FUNCTION function_with_argtypes
			1260 => rule_1260(ctx, v, l, loc)
			# transform_element_list: TO SQL_P WITH FUNCTION function_with_argtypes
			1261 => rule_1261(ctx, v, l, loc)
			# DropTransformStmt: DROP TRANSFORM opt_if_exists FOR Typename LANGUAGE name opt_drop_behavior
			1262 => rule_1262(ctx, v, l, loc, 43)
			# ReindexStmt: REINDEX opt_reindex_option_list reindex_target_relation opt_concurrently qualified_name
			1263 => rule_1263(ctx, v, l, loc)
			# ReindexStmt: REINDEX opt_reindex_option_list SCHEMA opt_concurrently name
			1264 => rule_1264(ctx, v, l, loc, 2)
			# ReindexStmt: REINDEX opt_reindex_option_list reindex_target_all opt_concurrently opt_single_name
			1265 => rule_1265(ctx, v, l, loc)
			# reindex_target_relation: INDEX
			1266 => rule_143(ctx, v, l, loc, 0)
			# reindex_target_relation: TABLE
			1267 => rule_143(ctx, v, l, loc, 1)
			# reindex_target_all: SYSTEM_P
			1268 => rule_143(ctx, v, l, loc, 3)
			# reindex_target_all: DATABASE
			1269 => rule_143(ctx, v, l, loc, 4)
			# opt_reindex_option_list: '(' utility_option_list ')'
			1270 => rule_374(ctx, v, l, loc)
			# opt_reindex_option_list: %empty
			1271 => rule_140(ctx, v, l, loc)
			# AlterTblSpcStmt: ALTER TABLESPACE name SET reloptions
			1272 => rule_1272(ctx, v, l, loc)
			# AlterTblSpcStmt: ALTER TABLESPACE name RESET reloptions
			1273 => rule_1273(ctx, v, l, loc)
			# RenameStmt: ALTER AGGREGATE aggregate_with_argtypes RENAME TO name
			1274 => rule_1274(ctx, v, l, loc, 1)
			# RenameStmt: ALTER COLLATION any_name RENAME TO name
			1275 => rule_1275(ctx, v, l, loc, 7)
			# RenameStmt: ALTER CONVERSION_P any_name RENAME TO name
			1276 => rule_1275(ctx, v, l, loc, 8)
			# RenameStmt: ALTER DATABASE name RENAME TO name
			1277 => rule_1277(ctx, v, l, loc, 9)
			# RenameStmt: ALTER DOMAIN_P any_name RENAME TO name
			1278 => rule_1275(ctx, v, l, loc, 12)
			# RenameStmt: ALTER DOMAIN_P any_name RENAME CONSTRAINT name TO name
			1279 => rule_1279(ctx, v, l, loc, 13)
			# RenameStmt: ALTER FOREIGN DATA_P WRAPPER name RENAME TO name
			1280 => rule_1280(ctx, v, l, loc, 16)
			# RenameStmt: ALTER FUNCTION function_with_argtypes RENAME TO name
			1281 => rule_1274(ctx, v, l, loc, 19)
			# RenameStmt: ALTER GROUP_P RoleId RENAME TO RoleId
			1282 => rule_1277(ctx, v, l, loc, 33)
			# RenameStmt: ALTER opt_procedural LANGUAGE name RENAME TO name
			1283 => rule_1283(ctx, v, l, loc, 21)
			# RenameStmt: ALTER OPERATOR CLASS any_name USING name RENAME TO name
			1284 => rule_1284(ctx, v, l, loc, 24)
			# RenameStmt: ALTER OPERATOR FAMILY any_name USING name RENAME TO name
			1285 => rule_1284(ctx, v, l, loc, 26)
			# RenameStmt: ALTER POLICY name ON qualified_name RENAME TO name
			1286 => rule_1286(ctx, v, l, loc, 28)
			# RenameStmt: ALTER POLICY IF_P EXISTS name ON qualified_name RENAME TO name
			1287 => rule_1287(ctx, v, l, loc, 28)
			# RenameStmt: ALTER PROCEDURE function_with_argtypes RENAME TO name
			1288 => rule_1274(ctx, v, l, loc, 29)
			# RenameStmt: ALTER PUBLICATION name RENAME TO name
			1289 => rule_1289(ctx, v, l, loc, 30)
			# RenameStmt: ALTER ROUTINE function_with_argtypes RENAME TO name
			1290 => rule_1274(ctx, v, l, loc, 34)
			# RenameStmt: ALTER SCHEMA name RENAME TO name
			1291 => rule_1277(ctx, v, l, loc, 36)
			# RenameStmt: ALTER SERVER name RENAME TO name
			1292 => rule_1289(ctx, v, l, loc, 17)
			# RenameStmt: ALTER SUBSCRIPTION name RENAME TO name
			1293 => rule_1289(ctx, v, l, loc, 38)
			# RenameStmt: ALTER TABLE relation_expr RENAME TO name
			1294 => rule_1294(ctx, v, l, loc, 41)
			# RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME TO name
			1295 => rule_1295(ctx, v, l, loc, 41)
			# RenameStmt: ALTER SEQUENCE qualified_name RENAME TO name
			1296 => rule_1294(ctx, v, l, loc, 37)
			# RenameStmt: ALTER SEQUENCE IF_P EXISTS qualified_name RENAME TO name
			1297 => rule_1295(ctx, v, l, loc, 37)
			# RenameStmt: ALTER VIEW qualified_name RENAME TO name
			1298 => rule_1294(ctx, v, l, loc, 51)
			# RenameStmt: ALTER VIEW IF_P EXISTS qualified_name RENAME TO name
			1299 => rule_1295(ctx, v, l, loc, 51)
			# RenameStmt: ALTER MATERIALIZED VIEW qualified_name RENAME TO name
			1300 => rule_1300(ctx, v, l, loc, 23)
			# RenameStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME TO name
			1301 => rule_1301(ctx, v, l, loc, 23)
			# RenameStmt: ALTER INDEX qualified_name RENAME TO name
			1302 => rule_1294(ctx, v, l, loc, 20)
			# RenameStmt: ALTER INDEX IF_P EXISTS qualified_name RENAME TO name
			1303 => rule_1295(ctx, v, l, loc, 20)
			# RenameStmt: ALTER FOREIGN TABLE relation_expr RENAME TO name
			1304 => rule_1300(ctx, v, l, loc, 18)
			# RenameStmt: ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME TO name
			1305 => rule_1301(ctx, v, l, loc, 18)
			# RenameStmt: ALTER TABLE relation_expr RENAME opt_column name TO name
			1306 => rule_1306(ctx, v, l, loc, 6, 41)
			# RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
			1307 => rule_1307(ctx, v, l, loc, 6, 41)
			# RenameStmt: ALTER VIEW qualified_name RENAME opt_column name TO name
			1308 => rule_1306(ctx, v, l, loc, 6, 51)
			# RenameStmt: ALTER VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name
			1309 => rule_1307(ctx, v, l, loc, 6, 51)
			# RenameStmt: ALTER MATERIALIZED VIEW qualified_name RENAME opt_column name TO name
			1310 => rule_1310(ctx, v, l, loc, 6, 23)
			# RenameStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name
			1311 => rule_1311(ctx, v, l, loc, 6, 23)
			# RenameStmt: ALTER TABLE relation_expr RENAME CONSTRAINT name TO name
			1312 => rule_1312(ctx, v, l, loc, 40)
			# RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name
			1313 => rule_1313(ctx, v, l, loc, 40)
			# RenameStmt: ALTER FOREIGN TABLE relation_expr RENAME opt_column name TO name
			1314 => rule_1310(ctx, v, l, loc, 6, 18)
			# RenameStmt: ALTER FOREIGN TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
			1315 => rule_1311(ctx, v, l, loc, 6, 18)
			# RenameStmt: ALTER RULE name ON qualified_name RENAME TO name
			1316 => rule_1286(ctx, v, l, loc, 35)
			# RenameStmt: ALTER TRIGGER name ON qualified_name RENAME TO name
			1317 => rule_1286(ctx, v, l, loc, 44)
			# RenameStmt: ALTER EVENT TRIGGER name RENAME TO name
			1318 => rule_1318(ctx, v, l, loc, 14)
			# RenameStmt: ALTER ROLE RoleId RENAME TO RoleId
			1319 => rule_1277(ctx, v, l, loc, 33)
			# RenameStmt: ALTER USER RoleId RENAME TO RoleId
			1320 => rule_1277(ctx, v, l, loc, 33)
			# RenameStmt: ALTER TABLESPACE name RENAME TO name
			1321 => rule_1277(ctx, v, l, loc, 42)
			# RenameStmt: ALTER STATISTICS any_name RENAME TO name
			1322 => rule_1275(ctx, v, l, loc, 39)
			# RenameStmt: ALTER TEXT_P SEARCH PARSER any_name RENAME TO name
			1323 => rule_1323(ctx, v, l, loc, 47)
			# RenameStmt: ALTER TEXT_P SEARCH DICTIONARY any_name RENAME TO name
			1324 => rule_1323(ctx, v, l, loc, 46)
			# RenameStmt: ALTER TEXT_P SEARCH TEMPLATE any_name RENAME TO name
			1325 => rule_1323(ctx, v, l, loc, 48)
			# RenameStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name RENAME TO name
			1326 => rule_1323(ctx, v, l, loc, 45)
			# RenameStmt: ALTER TYPE_P any_name RENAME TO name
			1327 => rule_1275(ctx, v, l, loc, 49)
			# RenameStmt: ALTER TYPE_P any_name RENAME ATTRIBUTE name TO name opt_drop_behavior
			1328 => rule_1328(ctx, v, l, loc, 4, 49)
			# opt_set_data: SET DATA_P
			1331 => rule_143(ctx, v, l, loc, 1)
			# opt_set_data: %empty
			1332 => rule_145(ctx, v, l, loc, 0)
			# AlterObjectDependsStmt: ALTER FUNCTION function_with_argtypes opt_no DEPENDS ON EXTENSION name
			1333 => rule_1333(ctx, v, l, loc, 19)
			# AlterObjectDependsStmt: ALTER PROCEDURE function_with_argtypes opt_no DEPENDS ON EXTENSION name
			1334 => rule_1333(ctx, v, l, loc, 29)
			# AlterObjectDependsStmt: ALTER ROUTINE function_with_argtypes opt_no DEPENDS ON EXTENSION name
			1335 => rule_1333(ctx, v, l, loc, 34)
			# AlterObjectDependsStmt: ALTER TRIGGER name ON qualified_name opt_no DEPENDS ON EXTENSION name
			1336 => rule_1336(ctx, v, l, loc, 44)
			# AlterObjectDependsStmt: ALTER MATERIALIZED VIEW qualified_name opt_no DEPENDS ON EXTENSION name
			1337 => rule_1337(ctx, v, l, loc, 23)
			# AlterObjectDependsStmt: ALTER INDEX qualified_name opt_no DEPENDS ON EXTENSION name
			1338 => rule_1338(ctx, v, l, loc, 20)
			# opt_no: NO
			1339 => rule_141(ctx, v, l, loc)
			# opt_no: %empty
			1340 => rule_142(ctx, v, l, loc)
			# AlterObjectSchemaStmt: ALTER AGGREGATE aggregate_with_argtypes SET SCHEMA name
			1341 => rule_1341(ctx, v, l, loc, 1)
			# AlterObjectSchemaStmt: ALTER COLLATION any_name SET SCHEMA name
			1342 => rule_1342(ctx, v, l, loc, 7)
			# AlterObjectSchemaStmt: ALTER CONVERSION_P any_name SET SCHEMA name
			1343 => rule_1342(ctx, v, l, loc, 8)
			# AlterObjectSchemaStmt: ALTER DOMAIN_P any_name SET SCHEMA name
			1344 => rule_1342(ctx, v, l, loc, 12)
			# AlterObjectSchemaStmt: ALTER EXTENSION name SET SCHEMA name
			1345 => rule_1345(ctx, v, l, loc, 15)
			# AlterObjectSchemaStmt: ALTER FUNCTION function_with_argtypes SET SCHEMA name
			1346 => rule_1341(ctx, v, l, loc, 19)
			# AlterObjectSchemaStmt: ALTER OPERATOR operator_with_argtypes SET SCHEMA name
			1347 => rule_1341(ctx, v, l, loc, 25)
			# AlterObjectSchemaStmt: ALTER OPERATOR CLASS any_name USING name SET SCHEMA name
			1348 => rule_1348(ctx, v, l, loc, 24)
			# AlterObjectSchemaStmt: ALTER OPERATOR FAMILY any_name USING name SET SCHEMA name
			1349 => rule_1348(ctx, v, l, loc, 26)
			# AlterObjectSchemaStmt: ALTER PROCEDURE function_with_argtypes SET SCHEMA name
			1350 => rule_1341(ctx, v, l, loc, 29)
			# AlterObjectSchemaStmt: ALTER ROUTINE function_with_argtypes SET SCHEMA name
			1351 => rule_1341(ctx, v, l, loc, 34)
			# AlterObjectSchemaStmt: ALTER TABLE relation_expr SET SCHEMA name
			1352 => rule_1352(ctx, v, l, loc, 41)
			# AlterObjectSchemaStmt: ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name
			1353 => rule_1353(ctx, v, l, loc, 41)
			# AlterObjectSchemaStmt: ALTER STATISTICS any_name SET SCHEMA name
			1354 => rule_1342(ctx, v, l, loc, 39)
			# AlterObjectSchemaStmt: ALTER TEXT_P SEARCH PARSER any_name SET SCHEMA name
			1355 => rule_1355(ctx, v, l, loc, 47)
			# AlterObjectSchemaStmt: ALTER TEXT_P SEARCH DICTIONARY any_name SET SCHEMA name
			1356 => rule_1355(ctx, v, l, loc, 46)
			# AlterObjectSchemaStmt: ALTER TEXT_P SEARCH TEMPLATE any_name SET SCHEMA name
			1357 => rule_1355(ctx, v, l, loc, 48)
			# AlterObjectSchemaStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name SET SCHEMA name
			1358 => rule_1355(ctx, v, l, loc, 45)
			# AlterObjectSchemaStmt: ALTER SEQUENCE qualified_name SET SCHEMA name
			1359 => rule_1352(ctx, v, l, loc, 37)
			# AlterObjectSchemaStmt: ALTER SEQUENCE IF_P EXISTS qualified_name SET SCHEMA name
			1360 => rule_1353(ctx, v, l, loc, 37)
			# AlterObjectSchemaStmt: ALTER VIEW qualified_name SET SCHEMA name
			1361 => rule_1352(ctx, v, l, loc, 51)
			# AlterObjectSchemaStmt: ALTER VIEW IF_P EXISTS qualified_name SET SCHEMA name
			1362 => rule_1353(ctx, v, l, loc, 51)
			# AlterObjectSchemaStmt: ALTER MATERIALIZED VIEW qualified_name SET SCHEMA name
			1363 => rule_1363(ctx, v, l, loc, 23)
			# AlterObjectSchemaStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name SET SCHEMA name
			1364 => rule_1364(ctx, v, l, loc, 23)
			# AlterObjectSchemaStmt: ALTER FOREIGN TABLE relation_expr SET SCHEMA name
			1365 => rule_1363(ctx, v, l, loc, 18)
			# AlterObjectSchemaStmt: ALTER FOREIGN TABLE IF_P EXISTS relation_expr SET SCHEMA name
			1366 => rule_1364(ctx, v, l, loc, 18)
			# AlterObjectSchemaStmt: ALTER TYPE_P any_name SET SCHEMA name
			1367 => rule_1342(ctx, v, l, loc, 49)
			# AlterOperatorStmt: ALTER OPERATOR operator_with_argtypes SET '(' operator_def_list ')'
			1368 => rule_1368(ctx, v, l, loc)
			# operator_def_list: operator_def_elem
			1369 => rule_224(ctx, v, l, loc)
			# operator_def_list: operator_def_list ',' operator_def_elem
			1370 => rule_225(ctx, v, l, loc)
			# operator_def_elem: ColLabel '=' NONE
			1371 => rule_380(ctx, v, l, loc)
			# operator_def_elem: ColLabel '=' operator_def_arg
			1372 => rule_379(ctx, v, l, loc)
			# operator_def_elem: ColLabel
			1373 => rule_380(ctx, v, l, loc)
			# operator_def_arg: func_type
			1374 => rule_164(ctx, v, l, loc)
			# operator_def_arg: reserved_keyword
			1375 => rule_446(ctx, v, l, loc)
			# operator_def_arg: qual_all_Op
			1376 => rule_871(ctx, v, l, loc)
			# operator_def_arg: NumericOnly
			1377 => rule_164(ctx, v, l, loc)
			# operator_def_arg: Sconst
			1378 => rule_446(ctx, v, l, loc)
			# AlterTypeStmt: ALTER TYPE_P any_name SET '(' operator_def_list ')'
			1379 => rule_1379(ctx, v, l, loc)
			# AlterOwnerStmt: ALTER AGGREGATE aggregate_with_argtypes OWNER TO RoleSpec
			1380 => rule_1380(ctx, v, l, loc, 1)
			# AlterOwnerStmt: ALTER COLLATION any_name OWNER TO RoleSpec
			1381 => rule_1381(ctx, v, l, loc, 7)
			# AlterOwnerStmt: ALTER CONVERSION_P any_name OWNER TO RoleSpec
			1382 => rule_1381(ctx, v, l, loc, 8)
			# AlterOwnerStmt: ALTER DATABASE name OWNER TO RoleSpec
			1383 => rule_1383(ctx, v, l, loc, 9)
			# AlterOwnerStmt: ALTER DOMAIN_P any_name OWNER TO RoleSpec
			1384 => rule_1381(ctx, v, l, loc, 12)
			# AlterOwnerStmt: ALTER FUNCTION function_with_argtypes OWNER TO RoleSpec
			1385 => rule_1380(ctx, v, l, loc, 19)
			# AlterOwnerStmt: ALTER opt_procedural LANGUAGE name OWNER TO RoleSpec
			1386 => rule_1386(ctx, v, l, loc, 21)
			# AlterOwnerStmt: ALTER LARGE_P OBJECT_P NumericOnly OWNER TO RoleSpec
			1387 => rule_1387(ctx, v, l, loc, 22)
			# AlterOwnerStmt: ALTER OPERATOR operator_with_argtypes OWNER TO RoleSpec
			1388 => rule_1380(ctx, v, l, loc, 25)
			# AlterOwnerStmt: ALTER OPERATOR CLASS any_name USING name OWNER TO RoleSpec
			1389 => rule_1389(ctx, v, l, loc, 24)
			# AlterOwnerStmt: ALTER OPERATOR FAMILY any_name USING name OWNER TO RoleSpec
			1390 => rule_1389(ctx, v, l, loc, 26)
			# AlterOwnerStmt: ALTER PROCEDURE function_with_argtypes OWNER TO RoleSpec
			1391 => rule_1380(ctx, v, l, loc, 29)
			# AlterOwnerStmt: ALTER ROUTINE function_with_argtypes OWNER TO RoleSpec
			1392 => rule_1380(ctx, v, l, loc, 34)
			# AlterOwnerStmt: ALTER SCHEMA name OWNER TO RoleSpec
			1393 => rule_1383(ctx, v, l, loc, 36)
			# AlterOwnerStmt: ALTER TYPE_P any_name OWNER TO RoleSpec
			1394 => rule_1381(ctx, v, l, loc, 49)
			# AlterOwnerStmt: ALTER TABLESPACE name OWNER TO RoleSpec
			1395 => rule_1383(ctx, v, l, loc, 42)
			# AlterOwnerStmt: ALTER STATISTICS any_name OWNER TO RoleSpec
			1396 => rule_1381(ctx, v, l, loc, 39)
			# AlterOwnerStmt: ALTER TEXT_P SEARCH DICTIONARY any_name OWNER TO RoleSpec
			1397 => rule_1397(ctx, v, l, loc, 46)
			# AlterOwnerStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name OWNER TO RoleSpec
			1398 => rule_1397(ctx, v, l, loc, 45)
			# AlterOwnerStmt: ALTER FOREIGN DATA_P WRAPPER name OWNER TO RoleSpec
			1399 => rule_1399(ctx, v, l, loc, 16)
			# AlterOwnerStmt: ALTER SERVER name OWNER TO RoleSpec
			1400 => rule_1383(ctx, v, l, loc, 17)
			# AlterOwnerStmt: ALTER EVENT TRIGGER name OWNER TO RoleSpec
			1401 => rule_1386(ctx, v, l, loc, 14)
			# AlterOwnerStmt: ALTER PUBLICATION name OWNER TO RoleSpec
			1402 => rule_1383(ctx, v, l, loc, 30)
			# AlterOwnerStmt: ALTER SUBSCRIPTION name OWNER TO RoleSpec
			1403 => rule_1383(ctx, v, l, loc, 38)
			# CreatePublicationStmt: CREATE PUBLICATION name opt_definition
			1404 => rule_1404(ctx, v, l, loc)
			# CreatePublicationStmt: CREATE PUBLICATION name FOR ALL TABLES opt_definition
			1405 => rule_1405(ctx, v, l, loc)
			# CreatePublicationStmt: CREATE PUBLICATION name FOR pub_obj_list opt_definition
			1406 => rule_1406(ctx, v, l, loc)
			# PublicationObjSpec: TABLE relation_expr opt_column_list OptWhereClause
			1407 => rule_1407(ctx, v, l, loc, 0)
			# PublicationObjSpec: TABLES IN_P SCHEMA ColId
			1408 => rule_1408(ctx, v, l, loc, 1)
			# PublicationObjSpec: TABLES IN_P SCHEMA CURRENT_SCHEMA
			1409 => rule_1409(ctx, v, l, loc, 2)
			# PublicationObjSpec: ColId opt_column_list OptWhereClause
			1410 => rule_1410(ctx, v, l, loc, 3)
			# PublicationObjSpec: ColId indirection opt_column_list OptWhereClause
			1411 => rule_1411(ctx, v, l, loc, 3)
			# PublicationObjSpec: extended_relation_expr opt_column_list OptWhereClause
			1412 => rule_1412(ctx, v, l, loc, 3)
			# PublicationObjSpec: CURRENT_SCHEMA
			1413 => rule_1413(ctx, v, l, loc, 3)
			# pub_obj_list: PublicationObjSpec
			1414 => rule_224(ctx, v, l, loc)
			# pub_obj_list: pub_obj_list ',' PublicationObjSpec
			1415 => rule_225(ctx, v, l, loc)
			# AlterPublicationStmt: ALTER PUBLICATION name SET definition
			1416 => rule_1416(ctx, v, l, loc)
			# AlterPublicationStmt: ALTER PUBLICATION name ADD_P pub_obj_list
			1417 => rule_1417(ctx, v, l, loc, 0)
			# AlterPublicationStmt: ALTER PUBLICATION name SET pub_obj_list
			1418 => rule_1417(ctx, v, l, loc, 2)
			# AlterPublicationStmt: ALTER PUBLICATION name DROP pub_obj_list
			1419 => rule_1417(ctx, v, l, loc, 1)
			# CreateSubscriptionStmt: CREATE SUBSCRIPTION name CONNECTION Sconst PUBLICATION name_list opt_definition
			1420 => rule_1420(ctx, v, l, loc)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name SET definition
			1421 => rule_1421(ctx, v, l, loc, 0)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name CONNECTION Sconst
			1422 => rule_1422(ctx, v, l, loc, 1)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name REFRESH PUBLICATION opt_definition
			1423 => rule_1423(ctx, v, l, loc, 5)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name ADD_P PUBLICATION name_list opt_definition
			1424 => rule_1424(ctx, v, l, loc, 3)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name DROP PUBLICATION name_list opt_definition
			1425 => rule_1424(ctx, v, l, loc, 4)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name SET PUBLICATION name_list opt_definition
			1426 => rule_1424(ctx, v, l, loc, 2)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name ENABLE_P
			1427 => rule_1427(ctx, v, l, loc, 6)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name DISABLE_P
			1428 => rule_1428(ctx, v, l, loc, 6)
			# AlterSubscriptionStmt: ALTER SUBSCRIPTION name SKIP definition
			1429 => rule_1421(ctx, v, l, loc, 7)
			# DropSubscriptionStmt: DROP SUBSCRIPTION name opt_drop_behavior
			1430 => rule_1430(ctx, v, l, loc)
			# DropSubscriptionStmt: DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior
			1431 => rule_1431(ctx, v, l, loc)
			# RuleStmt: CREATE opt_or_replace RULE name AS ON event TO qualified_name where_clause DO opt_instead RuleActionList
			1432 => rule_1432(ctx, v, l, loc)
			# RuleActionList: NOTHING
			1433 => rule_265(ctx, v, l, loc)
			# RuleActionList: RuleActionStmt
			1434 => rule_224(ctx, v, l, loc)
			# RuleActionList: '(' RuleActionMulti ')'
			1435 => rule_374(ctx, v, l, loc)
			# RuleActionMulti: RuleActionMulti ';' RuleActionStmtOrEmpty
			1436 => rule_1436(ctx, v, l, loc)
			# RuleActionMulti: RuleActionStmtOrEmpty
			1437 => rule_1437(ctx, v, l, loc)
			# RuleActionStmtOrEmpty: RuleActionStmt
			1443 => rule_164(ctx, v, l, loc)
			# RuleActionStmtOrEmpty: %empty
			1444 => rule_136(ctx, v, l, loc)
			# event: SELECT
			1445 => rule_143(ctx, v, l, loc, 1)
			# event: UPDATE
			1446 => rule_143(ctx, v, l, loc, 2)
			# event: DELETE_P
			1447 => rule_143(ctx, v, l, loc, 4)
			# event: INSERT
			1448 => rule_143(ctx, v, l, loc, 3)
			# opt_instead: INSTEAD
			1449 => rule_141(ctx, v, l, loc)
			# opt_instead: ALSO
			1450 => rule_268(ctx, v, l, loc)
			# opt_instead: %empty
			1451 => rule_142(ctx, v, l, loc)
			# NotifyStmt: NOTIFY ColId notify_payload
			1452 => rule_1452(ctx, v, l, loc)
			# notify_payload: ',' Sconst
			1453 => rule_485(ctx, v, l, loc)
			# notify_payload: %empty
			1454 => rule_138(ctx, v, l, loc)
			# ListenStmt: LISTEN ColId
			1455 => rule_1455(ctx, v, l, loc)
			# UnlistenStmt: UNLISTEN ColId
			1456 => rule_1456(ctx, v, l, loc)
			# UnlistenStmt: UNLISTEN '*'
			1457 => rule_1457(ctx, v, l, loc)
			# TransactionStmt: ABORT_P opt_transaction opt_transaction_chain
			1458 => rule_1458(ctx, v, l, loc, 3, 1)
			# TransactionStmt: START TRANSACTION transaction_mode_list_or_empty
			1459 => rule_1459(ctx, v, l, loc, 1, 1)
			# TransactionStmt: COMMIT opt_transaction opt_transaction_chain
			1460 => rule_1458(ctx, v, l, loc, 2, 1)
			# TransactionStmt: ROLLBACK opt_transaction opt_transaction_chain
			1461 => rule_1458(ctx, v, l, loc, 3, 1)
			# TransactionStmt: SAVEPOINT ColId
			1462 => rule_1462(ctx, v, l, loc, 4)
			# TransactionStmt: RELEASE SAVEPOINT ColId
			1463 => rule_1463(ctx, v, l, loc, 5)
			# TransactionStmt: RELEASE ColId
			1464 => rule_1462(ctx, v, l, loc, 5)
			# TransactionStmt: ROLLBACK opt_transaction TO SAVEPOINT ColId
			1465 => rule_1465(ctx, v, l, loc, 6)
			# TransactionStmt: ROLLBACK opt_transaction TO ColId
			1466 => rule_1466(ctx, v, l, loc, 6)
			# TransactionStmt: PREPARE TRANSACTION Sconst
			1467 => rule_1467(ctx, v, l, loc, 7)
			# TransactionStmt: COMMIT PREPARED Sconst
			1468 => rule_1467(ctx, v, l, loc, 8)
			# TransactionStmt: ROLLBACK PREPARED Sconst
			1469 => rule_1467(ctx, v, l, loc, 9)
			# TransactionStmtLegacy: BEGIN_P opt_transaction transaction_mode_list_or_empty
			1470 => rule_1459(ctx, v, l, loc, 0, 1)
			# TransactionStmtLegacy: END_P opt_transaction opt_transaction_chain
			1471 => rule_1458(ctx, v, l, loc, 2, 1)
			# transaction_mode_item: ISOLATION LEVEL iso_level
			1475 => rule_1475(ctx, v, l, loc)
			# transaction_mode_item: READ ONLY
			1476 => rule_1476(ctx, v, l, loc)
			# transaction_mode_item: READ WRITE
			1477 => rule_1477(ctx, v, l, loc)
			# transaction_mode_item: DEFERRABLE
			1478 => rule_1478(ctx, v, l, loc)
			# transaction_mode_item: NOT DEFERRABLE
			1479 => rule_1479(ctx, v, l, loc)
			# transaction_mode_list: transaction_mode_item
			1480 => rule_224(ctx, v, l, loc)
			# transaction_mode_list: transaction_mode_list ',' transaction_mode_item
			1481 => rule_225(ctx, v, l, loc)
			# transaction_mode_list: transaction_mode_list transaction_mode_item
			1482 => rule_151(ctx, v, l, loc)
			# transaction_mode_list_or_empty: %empty
			1484 => rule_140(ctx, v, l, loc)
			# opt_transaction_chain: AND CHAIN
			1485 => rule_141(ctx, v, l, loc)
			# opt_transaction_chain: AND NO CHAIN
			1486 => rule_268(ctx, v, l, loc)
			# opt_transaction_chain: %empty
			1487 => rule_142(ctx, v, l, loc)
			# ViewStmt: CREATE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option
			1488 => rule_1488(ctx, v, l, loc)
			# ViewStmt: CREATE OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option
			1489 => rule_1489(ctx, v, l, loc)
			# ViewStmt: CREATE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option
			1490 => rule_1490(ctx, v, l, loc, 0)
			# ViewStmt: CREATE OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option
			1491 => rule_1491(ctx, v, l, loc, 0)
			# opt_check_option: WITH CHECK OPTION
			1492 => rule_143(ctx, v, l, loc, 2)
			# opt_check_option: WITH CASCADED CHECK OPTION
			1493 => rule_143(ctx, v, l, loc, 2)
			# opt_check_option: WITH LOCAL CHECK OPTION
			1494 => rule_143(ctx, v, l, loc, 1)
			# opt_check_option: %empty
			1495 => rule_145(ctx, v, l, loc, 0)
			# LoadStmt: LOAD file_name
			1496 => rule_1496(ctx, v, l, loc)
			# CreatedbStmt: CREATE DATABASE name opt_with createdb_opt_list
			1497 => rule_1497(ctx, v, l, loc)
			# createdb_opt_list: createdb_opt_items
			1498 => rule_139(ctx, v, l, loc)
			# createdb_opt_list: %empty
			1499 => rule_140(ctx, v, l, loc)
			# createdb_opt_items: createdb_opt_item
			1500 => rule_224(ctx, v, l, loc)
			# createdb_opt_items: createdb_opt_items createdb_opt_item
			1501 => rule_151(ctx, v, l, loc)
			# createdb_opt_item: createdb_opt_name opt_equal NumericOnly
			1502 => rule_379(ctx, v, l, loc)
			# createdb_opt_item: createdb_opt_name opt_equal opt_boolean_or_string
			1503 => rule_1503(ctx, v, l, loc)
			# createdb_opt_item: createdb_opt_name opt_equal DEFAULT
			1504 => rule_380(ctx, v, l, loc)
			# createdb_opt_name: IDENT
			1505 => rule_137(ctx, v, l, loc)
			# createdb_opt_name: CONNECTION LIMIT
			1506 => rule_1506(ctx, v, l, loc)
			# createdb_opt_name: ENCODING
			1507 => rule_137(ctx, v, l, loc)
			# createdb_opt_name: LOCATION
			1508 => rule_137(ctx, v, l, loc)
			# createdb_opt_name: OWNER
			1509 => rule_137(ctx, v, l, loc)
			# createdb_opt_name: TABLESPACE
			1510 => rule_137(ctx, v, l, loc)
			# createdb_opt_name: TEMPLATE
			1511 => rule_137(ctx, v, l, loc)
			# AlterDatabaseStmt: ALTER DATABASE name WITH createdb_opt_list
			1514 => rule_1514(ctx, v, l, loc)
			# AlterDatabaseStmt: ALTER DATABASE name createdb_opt_list
			1515 => rule_1515(ctx, v, l, loc)
			# AlterDatabaseStmt: ALTER DATABASE name SET TABLESPACE name
			1516 => rule_1516(ctx, v, l, loc)
			# AlterDatabaseStmt: ALTER DATABASE name REFRESH COLLATION VERSION_P
			1517 => rule_1517(ctx, v, l, loc)
			# AlterDatabaseSetStmt: ALTER DATABASE name SetResetClause
			1518 => rule_1518(ctx, v, l, loc)
			# DropdbStmt: DROP DATABASE name
			1519 => rule_1519(ctx, v, l, loc)
			# DropdbStmt: DROP DATABASE IF_P EXISTS name
			1520 => rule_1520(ctx, v, l, loc)
			# DropdbStmt: DROP DATABASE name opt_with '(' drop_option_list ')'
			1521 => rule_1521(ctx, v, l, loc)
			# DropdbStmt: DROP DATABASE IF_P EXISTS name opt_with '(' drop_option_list ')'
			1522 => rule_1522(ctx, v, l, loc)
			# drop_option_list: drop_option
			1523 => rule_224(ctx, v, l, loc)
			# drop_option_list: drop_option_list ',' drop_option
			1524 => rule_225(ctx, v, l, loc)
			# drop_option: FORCE
			1525 => rule_1525(ctx, v, l, loc)
			# AlterCollationStmt: ALTER COLLATION any_name REFRESH VERSION_P
			1526 => rule_1526(ctx, v, l, loc)
			# AlterSystemStmt: ALTER SYSTEM_P SET generic_set
			1527 => rule_1527(ctx, v, l, loc)
			# AlterSystemStmt: ALTER SYSTEM_P RESET generic_reset
			1528 => rule_1527(ctx, v, l, loc)
			# CreateDomainStmt: CREATE DOMAIN_P any_name opt_as Typename ColQualList
			1529 => rule_1529(ctx, v, l, loc)
			# AlterDomainStmt: ALTER DOMAIN_P any_name alter_column_default
			1530 => rule_1530(ctx, v, l, loc, 84)
			# AlterDomainStmt: ALTER DOMAIN_P any_name DROP NOT NULL_P
			1531 => rule_1531(ctx, v, l, loc, 78)
			# AlterDomainStmt: ALTER DOMAIN_P any_name SET NOT NULL_P
			1532 => rule_1531(ctx, v, l, loc, 79)
			# AlterDomainStmt: ALTER DOMAIN_P any_name ADD_P DomainConstraint
			1533 => rule_1533(ctx, v, l, loc, 67)
			# AlterDomainStmt: ALTER DOMAIN_P any_name DROP CONSTRAINT name opt_drop_behavior
			1534 => rule_1534(ctx, v, l, loc, 88)
			# AlterDomainStmt: ALTER DOMAIN_P any_name DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
			1535 => rule_1535(ctx, v, l, loc, 88)
			# AlterDomainStmt: ALTER DOMAIN_P any_name VALIDATE CONSTRAINT name
			1536 => rule_1536(ctx, v, l, loc, 86)
			# AlterTSDictionaryStmt: ALTER TEXT_P SEARCH DICTIONARY any_name definition
			1539 => rule_1539(ctx, v, l, loc)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ADD_P MAPPING FOR name_list any_with any_name_list
			1540 => rule_1540(ctx, v, l, loc, 0)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list any_with any_name_list
			1541 => rule_1541(ctx, v, l, loc, 1)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING REPLACE any_name any_with any_name
			1542 => rule_1542(ctx, v, l, loc, 2)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list REPLACE any_name any_with any_name
			1543 => rule_1543(ctx, v, l, loc, 3)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING FOR name_list
			1544 => rule_1544(ctx, v, l, loc, 4)
			# AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING IF_P EXISTS FOR name_list
			1545 => rule_1545(ctx, v, l, loc, 4)
			# CreateConversionStmt: CREATE opt_default CONVERSION_P any_name FOR Sconst TO Sconst FROM any_name
			1548 => rule_1548(ctx, v, l, loc)
			# ClusterStmt: CLUSTER '(' utility_option_list ')' qualified_name cluster_index_specification
			1549 => rule_1549(ctx, v, l, loc)
			# ClusterStmt: CLUSTER '(' utility_option_list ')'
			1550 => rule_1550(ctx, v, l, loc)
			# ClusterStmt: CLUSTER opt_verbose qualified_name cluster_index_specification
			1551 => rule_1551(ctx, v, l, loc)
			# ClusterStmt: CLUSTER opt_verbose
			1552 => rule_1552(ctx, v, l, loc)
			# ClusterStmt: CLUSTER opt_verbose name ON qualified_name
			1553 => rule_1553(ctx, v, l, loc)
			# cluster_index_specification: USING name
			1554 => rule_485(ctx, v, l, loc)
			# cluster_index_specification: %empty
			1555 => rule_138(ctx, v, l, loc)
			# VacuumStmt: VACUUM opt_full opt_freeze opt_verbose opt_analyze opt_vacuum_relation_list
			1556 => rule_1556(ctx, v, l, loc)
			# VacuumStmt: VACUUM '(' utility_option_list ')' opt_vacuum_relation_list
			1557 => rule_1557(ctx, v, l, loc)
			# AnalyzeStmt: analyze_keyword opt_verbose opt_vacuum_relation_list
			1558 => rule_1558(ctx, v, l, loc)
			# AnalyzeStmt: analyze_keyword '(' utility_option_list ')' opt_vacuum_relation_list
			1559 => rule_1559(ctx, v, l, loc)
			# utility_option_list: utility_option_elem
			1560 => rule_224(ctx, v, l, loc)
			# utility_option_list: utility_option_list ',' utility_option_elem
			1561 => rule_225(ctx, v, l, loc)
			# utility_option_elem: utility_option_name utility_option_arg
			1564 => rule_445(ctx, v, l, loc)
			# utility_option_name: NonReservedWord
			1565 => rule_137(ctx, v, l, loc)
			# utility_option_name: analyze_keyword
			1566 => rule_1566(ctx, v, l, loc)
			# utility_option_name: FORMAT_LA
			1567 => rule_1567(ctx, v, l, loc)
			# utility_option_arg: opt_boolean_or_string
			1568 => rule_446(ctx, v, l, loc)
			# utility_option_arg: NumericOnly
			1569 => rule_164(ctx, v, l, loc)
			# utility_option_arg: %empty
			1570 => rule_136(ctx, v, l, loc)
			# opt_analyze: analyze_keyword
			1571 => rule_141(ctx, v, l, loc)
			# opt_analyze: %empty
			1572 => rule_142(ctx, v, l, loc)
			# opt_verbose: VERBOSE
			1573 => rule_141(ctx, v, l, loc)
			# opt_verbose: %empty
			1574 => rule_142(ctx, v, l, loc)
			# opt_full: FULL
			1575 => rule_141(ctx, v, l, loc)
			# opt_full: %empty
			1576 => rule_142(ctx, v, l, loc)
			# opt_freeze: FREEZE
			1577 => rule_141(ctx, v, l, loc)
			# opt_freeze: %empty
			1578 => rule_142(ctx, v, l, loc)
			# opt_name_list: '(' name_list ')'
			1579 => rule_374(ctx, v, l, loc)
			# opt_name_list: %empty
			1580 => rule_140(ctx, v, l, loc)
			# vacuum_relation: relation_expr opt_name_list
			1581 => rule_1581(ctx, v, l, loc, 0)
			# vacuum_relation_list: vacuum_relation
			1582 => rule_224(ctx, v, l, loc)
			# vacuum_relation_list: vacuum_relation_list ',' vacuum_relation
			1583 => rule_225(ctx, v, l, loc)
			# opt_vacuum_relation_list: vacuum_relation_list
			1584 => rule_139(ctx, v, l, loc)
			# opt_vacuum_relation_list: %empty
			1585 => rule_140(ctx, v, l, loc)
			# ExplainStmt: EXPLAIN ExplainableStmt
			1586 => rule_1586(ctx, v, l, loc)
			# ExplainStmt: EXPLAIN analyze_keyword opt_verbose ExplainableStmt
			1587 => rule_1587(ctx, v, l, loc)
			# ExplainStmt: EXPLAIN VERBOSE ExplainableStmt
			1588 => rule_1588(ctx, v, l, loc)
			# ExplainStmt: EXPLAIN '(' utility_option_list ')' ExplainableStmt
			1589 => rule_1589(ctx, v, l, loc)
			# PrepareStmt: PREPARE name prep_type_clause AS PreparableStmt
			1600 => rule_1600(ctx, v, l, loc)
			# prep_type_clause: '(' type_list ')'
			1601 => rule_374(ctx, v, l, loc)
			# prep_type_clause: %empty
			1602 => rule_140(ctx, v, l, loc)
			# ExecuteStmt: EXECUTE name execute_param_clause
			1608 => rule_1608(ctx, v, l, loc)
			# ExecuteStmt: CREATE OptTemp TABLE create_as_target AS EXECUTE name execute_param_clause opt_with_data
			1609 => rule_1609(ctx, v, l, loc, 41)
			# ExecuteStmt: CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS EXECUTE name execute_param_clause opt_with_data
			1610 => rule_1610(ctx, v, l, loc, 41)
			# execute_param_clause: '(' expr_list ')'
			1611 => rule_374(ctx, v, l, loc)
			# execute_param_clause: %empty
			1612 => rule_140(ctx, v, l, loc)
			# DeallocateStmt: DEALLOCATE name
			1613 => rule_1613(ctx, v, l, loc)
			# DeallocateStmt: DEALLOCATE PREPARE name
			1614 => rule_1614(ctx, v, l, loc)
			# DeallocateStmt: DEALLOCATE ALL
			1615 => rule_1615(ctx, v, l, loc, 1)
			# DeallocateStmt: DEALLOCATE PREPARE ALL
			1616 => rule_1615(ctx, v, l, loc, 1)
			# InsertStmt: opt_with_clause INSERT INTO insert_target insert_rest opt_on_conflict returning_clause
			1617 => rule_1617(ctx, v, l, loc)
			# insert_target: qualified_name
			1618 => rule_164(ctx, v, l, loc)
			# insert_target: qualified_name AS ColId
			1619 => rule_1619(ctx, v, l, loc)
			# insert_rest: SelectStmt
			1620 => rule_1620(ctx, v, l, loc)
			# insert_rest: OVERRIDING override_kind VALUE_P SelectStmt
			1621 => rule_1621(ctx, v, l, loc)
			# insert_rest: '(' insert_column_list ')' SelectStmt
			1622 => rule_1622(ctx, v, l, loc)
			# insert_rest: '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt
			1623 => rule_1623(ctx, v, l, loc)
			# insert_rest: DEFAULT VALUES
			1624 => rule_1624(ctx, v, l, loc)
			# override_kind: USER
			1625 => rule_143(ctx, v, l, loc, 1)
			# override_kind: SYSTEM_P
			1626 => rule_143(ctx, v, l, loc, 2)
			# insert_column_list: insert_column_item
			1627 => rule_224(ctx, v, l, loc)
			# insert_column_list: insert_column_list ',' insert_column_item
			1628 => rule_225(ctx, v, l, loc)
			# insert_column_item: ColId opt_indirection
			1629 => rule_1629(ctx, v, l, loc)
			# opt_on_conflict: ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list where_clause
			1630 => rule_1630(ctx, v, l, loc, 2)
			# opt_on_conflict: ON CONFLICT opt_conf_expr DO NOTHING
			1631 => rule_1631(ctx, v, l, loc, 1)
			# opt_on_conflict: %empty
			1632 => rule_136(ctx, v, l, loc)
			# opt_conf_expr: '(' index_params ')' where_clause
			1633 => rule_1633(ctx, v, l, loc)
			# opt_conf_expr: ON CONSTRAINT name
			1634 => rule_1634(ctx, v, l, loc)
			# opt_conf_expr: %empty
			1635 => rule_136(ctx, v, l, loc)
			# returning_clause: RETURNING returning_with_clause target_list
			1636 => rule_1636(ctx, v, l, loc)
			# returning_clause: %empty
			1637 => rule_136(ctx, v, l, loc)
			# returning_with_clause: WITH '(' returning_options ')'
			1638 => rule_563(ctx, v, l, loc)
			# returning_with_clause: %empty
			1639 => rule_140(ctx, v, l, loc)
			# returning_options: returning_option
			1640 => rule_224(ctx, v, l, loc)
			# returning_options: returning_options ',' returning_option
			1641 => rule_225(ctx, v, l, loc)
			# returning_option: returning_option_kind AS ColId
			1642 => rule_1642(ctx, v, l, loc)
			# returning_option_kind: OLD
			1643 => rule_143(ctx, v, l, loc, 0)
			# returning_option_kind: NEW
			1644 => rule_143(ctx, v, l, loc, 1)
			# DeleteStmt: opt_with_clause DELETE_P FROM relation_expr_opt_alias using_clause where_or_current_clause returning_clause
			1645 => rule_1645(ctx, v, l, loc)
			# using_clause: USING from_list
			1646 => rule_374(ctx, v, l, loc)
			# using_clause: %empty
			1647 => rule_140(ctx, v, l, loc)
			# LockStmt: LOCK_P opt_table relation_expr_list opt_lock opt_nowait
			1648 => rule_1648(ctx, v, l, loc)
			# opt_lock: IN_P lock_type MODE
			1649 => rule_1649(ctx, v, l, loc)
			# opt_lock: %empty
			1650 => rule_145(ctx, v, l, loc, 8)
			# lock_type: ACCESS SHARE
			1651 => rule_143(ctx, v, l, loc, 1)
			# lock_type: ROW SHARE
			1652 => rule_143(ctx, v, l, loc, 2)
			# lock_type: ROW EXCLUSIVE
			1653 => rule_143(ctx, v, l, loc, 3)
			# lock_type: SHARE UPDATE EXCLUSIVE
			1654 => rule_143(ctx, v, l, loc, 4)
			# lock_type: SHARE
			1655 => rule_143(ctx, v, l, loc, 5)
			# lock_type: SHARE ROW EXCLUSIVE
			1656 => rule_143(ctx, v, l, loc, 6)
			# lock_type: EXCLUSIVE
			1657 => rule_143(ctx, v, l, loc, 7)
			# lock_type: ACCESS EXCLUSIVE
			1658 => rule_143(ctx, v, l, loc, 8)
			# opt_nowait: NOWAIT
			1659 => rule_141(ctx, v, l, loc)
			# opt_nowait: %empty
			1660 => rule_142(ctx, v, l, loc)
			# opt_nowait_or_skip: NOWAIT
			1661 => rule_143(ctx, v, l, loc, 2)
			# opt_nowait_or_skip: SKIP LOCKED
			1662 => rule_143(ctx, v, l, loc, 1)
			# opt_nowait_or_skip: %empty
			1663 => rule_145(ctx, v, l, loc, 0)
			# UpdateStmt: opt_with_clause UPDATE relation_expr_opt_alias SET set_clause_list from_clause where_or_current_clause returning_clause
			1664 => rule_1664(ctx, v, l, loc)
			# set_clause_list: set_clause
			1665 => rule_139(ctx, v, l, loc)
			# set_clause_list: set_clause_list ',' set_clause
			1666 => rule_1666(ctx, v, l, loc)
			# set_clause: set_target '=' a_expr
			1667 => rule_1667(ctx, v, l, loc)
			# set_clause: '(' set_target_list ')' '=' a_expr
			1668 => rule_1668(ctx, v, l, loc, 1, 1)
			# set_target: ColId opt_indirection
			1669 => rule_1629(ctx, v, l, loc)
			# set_target_list: set_target
			1670 => rule_224(ctx, v, l, loc)
			# set_target_list: set_target_list ',' set_target
			1671 => rule_225(ctx, v, l, loc)
			# MergeStmt: opt_with_clause MERGE INTO relation_expr_opt_alias USING table_ref ON a_expr merge_when_list returning_clause
			1672 => rule_1672(ctx, v, l, loc)
			# merge_when_list: merge_when_clause
			1673 => rule_224(ctx, v, l, loc)
			# merge_when_list: merge_when_list merge_when_clause
			1674 => rule_151(ctx, v, l, loc)
			# merge_when_clause: merge_when_tgt_matched opt_merge_when_condition THEN merge_update
			1675 => rule_1675(ctx, v, l, loc)
			# merge_when_clause: merge_when_tgt_matched opt_merge_when_condition THEN merge_delete
			1676 => rule_1675(ctx, v, l, loc)
			# merge_when_clause: merge_when_tgt_not_matched opt_merge_when_condition THEN merge_insert
			1677 => rule_1675(ctx, v, l, loc)
			# merge_when_clause: merge_when_tgt_matched opt_merge_when_condition THEN DO NOTHING
			1678 => rule_1678(ctx, v, l, loc, 7)
			# merge_when_clause: merge_when_tgt_not_matched opt_merge_when_condition THEN DO NOTHING
			1679 => rule_1678(ctx, v, l, loc, 7)
			# merge_when_tgt_matched: WHEN MATCHED
			1680 => rule_143(ctx, v, l, loc, 0)
			# merge_when_tgt_matched: WHEN NOT MATCHED BY SOURCE
			1681 => rule_143(ctx, v, l, loc, 1)
			# merge_when_tgt_not_matched: WHEN NOT MATCHED
			1682 => rule_143(ctx, v, l, loc, 2)
			# merge_when_tgt_not_matched: WHEN NOT MATCHED BY TARGET
			1683 => rule_143(ctx, v, l, loc, 2)
			# opt_merge_when_condition: AND a_expr
			1684 => rule_248(ctx, v, l, loc)
			# opt_merge_when_condition: %empty
			1685 => rule_136(ctx, v, l, loc)
			# merge_update: UPDATE SET set_clause_list
			1686 => rule_1686(ctx, v, l, loc, 2, 0)
			# merge_delete: DELETE_P
			1687 => rule_1687(ctx, v, l, loc, 4, 0)
			# merge_insert: INSERT merge_values_clause
			1688 => rule_1688(ctx, v, l, loc, 3, 0)
			# merge_insert: INSERT OVERRIDING override_kind VALUE_P merge_values_clause
			1689 => rule_1689(ctx, v, l, loc, 3)
			# merge_insert: INSERT '(' insert_column_list ')' merge_values_clause
			1690 => rule_1690(ctx, v, l, loc, 3, 0)
			# merge_insert: INSERT '(' insert_column_list ')' OVERRIDING override_kind VALUE_P merge_values_clause
			1691 => rule_1691(ctx, v, l, loc, 3)
			# merge_insert: INSERT DEFAULT VALUES
			1692 => rule_1687(ctx, v, l, loc, 3, 0)
			# merge_values_clause: VALUES '(' expr_list ')'
			1693 => rule_563(ctx, v, l, loc)
			# DeclareCursorStmt: DECLARE cursor_name cursor_options CURSOR opt_hold FOR SelectStmt
			1694 => rule_1694(ctx, v, l, loc, 256)
			# cursor_name: name
			1695 => rule_137(ctx, v, l, loc)
			# cursor_options: %empty
			1696 => rule_145(ctx, v, l, loc, 0)
			# cursor_options: cursor_options NO SCROLL
			1697 => rule_1697(ctx, v, l, loc, 4)
			# cursor_options: cursor_options SCROLL
			1698 => rule_1697(ctx, v, l, loc, 2)
			# cursor_options: cursor_options BINARY
			1699 => rule_1697(ctx, v, l, loc, 1)
			# cursor_options: cursor_options ASENSITIVE
			1700 => rule_1697(ctx, v, l, loc, 16)
			# cursor_options: cursor_options INSENSITIVE
			1701 => rule_1697(ctx, v, l, loc, 8)
			# opt_hold: %empty
			1702 => rule_145(ctx, v, l, loc, 0)
			# opt_hold: WITH HOLD
			1703 => rule_143(ctx, v, l, loc, 32)
			# opt_hold: WITHOUT HOLD
			1704 => rule_143(ctx, v, l, loc, 0)
			# select_with_parens: '(' select_no_parens ')'
			1707 => rule_248(ctx, v, l, loc)
			# select_with_parens: '(' select_with_parens ')'
			1708 => rule_248(ctx, v, l, loc)
			# select_no_parens: simple_select
			1709 => rule_164(ctx, v, l, loc)
			# select_no_parens: select_clause sort_clause
			1710 => rule_1710(ctx, v, l, loc)
			# select_no_parens: select_clause opt_sort_clause for_locking_clause opt_select_limit
			1711 => rule_1711(ctx, v, l, loc)
			# select_no_parens: select_clause opt_sort_clause select_limit opt_for_locking_clause
			1712 => rule_1712(ctx, v, l, loc)
			# select_no_parens: with_clause select_clause
			1713 => rule_1713(ctx, v, l, loc)
			# select_no_parens: with_clause select_clause sort_clause
			1714 => rule_1714(ctx, v, l, loc)
			# select_no_parens: with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit
			1715 => rule_1715(ctx, v, l, loc)
			# select_no_parens: with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause
			1716 => rule_1716(ctx, v, l, loc)
			# select_clause: simple_select
			1717 => rule_164(ctx, v, l, loc)
			# select_clause: select_with_parens
			1718 => rule_164(ctx, v, l, loc)
			# simple_select: SELECT opt_all_clause opt_target_list into_clause from_clause where_clause group_clause having_clause window_clause
			1719 => rule_1719(ctx, v, l, loc)
			# simple_select: SELECT distinct_clause target_list into_clause from_clause where_clause group_clause having_clause window_clause
			1720 => rule_1720(ctx, v, l, loc)
			# simple_select: values_clause
			1721 => rule_164(ctx, v, l, loc)
			# simple_select: TABLE relation_expr
			1722 => rule_1722(ctx, v, l, loc, 1, 1)
			# simple_select: select_clause UNION set_quantifier select_clause
			1723 => rule_1723(ctx, v, l, loc, 1, 1)
			# simple_select: select_clause INTERSECT set_quantifier select_clause
			1724 => rule_1723(ctx, v, l, loc, 2, 1)
			# simple_select: select_clause EXCEPT set_quantifier select_clause
			1725 => rule_1723(ctx, v, l, loc, 3, 1)
			# with_clause: WITH cte_list
			1726 => rule_1726(ctx, v, l, loc)
			# with_clause: WITH_LA cte_list
			1727 => rule_1726(ctx, v, l, loc)
			# with_clause: WITH RECURSIVE cte_list
			1728 => rule_1728(ctx, v, l, loc)
			# cte_list: common_table_expr
			1729 => rule_224(ctx, v, l, loc)
			# cte_list: cte_list ',' common_table_expr
			1730 => rule_225(ctx, v, l, loc)
			# common_table_expr: name opt_name_list AS opt_materialized '(' PreparableStmt ')' opt_search_clause opt_cycle_clause
			1731 => rule_1731(ctx, v, l, loc)
			# opt_materialized: MATERIALIZED
			1732 => rule_143(ctx, v, l, loc, 1)
			# opt_materialized: NOT MATERIALIZED
			1733 => rule_143(ctx, v, l, loc, 2)
			# opt_materialized: %empty
			1734 => rule_145(ctx, v, l, loc, 0)
			# opt_search_clause: SEARCH DEPTH FIRST_P BY columnList SET ColId
			1735 => rule_1735(ctx, v, l, loc)
			# opt_search_clause: SEARCH BREADTH FIRST_P BY columnList SET ColId
			1736 => rule_1736(ctx, v, l, loc)
			# opt_search_clause: %empty
			1737 => rule_136(ctx, v, l, loc)
			# opt_cycle_clause: CYCLE columnList SET ColId TO AexprConst DEFAULT AexprConst USING ColId
			1738 => rule_1738(ctx, v, l, loc)
			# opt_cycle_clause: CYCLE columnList SET ColId USING ColId
			1739 => rule_1739(ctx, v, l, loc, 1, 1)
			# opt_cycle_clause: %empty
			1740 => rule_136(ctx, v, l, loc)
			# opt_with_clause: with_clause
			1741 => rule_164(ctx, v, l, loc)
			# opt_with_clause: %empty
			1742 => rule_136(ctx, v, l, loc)
			# into_clause: INTO OptTempTableName
			1743 => rule_1743(ctx, v, l, loc, 0)
			# into_clause: %empty
			1744 => rule_136(ctx, v, l, loc)
			# OptTempTableName: TEMPORARY opt_table qualified_name
			1745 => rule_1745(ctx, v, l, loc, 116)
			# OptTempTableName: TEMP opt_table qualified_name
			1746 => rule_1745(ctx, v, l, loc, 116)
			# OptTempTableName: LOCAL TEMPORARY opt_table qualified_name
			1747 => rule_1747(ctx, v, l, loc, 116)
			# OptTempTableName: LOCAL TEMP opt_table qualified_name
			1748 => rule_1747(ctx, v, l, loc, 116)
			# OptTempTableName: GLOBAL TEMPORARY opt_table qualified_name
			1749 => rule_1747(ctx, v, l, loc, 116)
			# OptTempTableName: GLOBAL TEMP opt_table qualified_name
			1750 => rule_1747(ctx, v, l, loc, 116)
			# OptTempTableName: UNLOGGED opt_table qualified_name
			1751 => rule_1745(ctx, v, l, loc, 117)
			# OptTempTableName: TABLE qualified_name
			1752 => rule_1752(ctx, v, l, loc, 112)
			# OptTempTableName: qualified_name
			1753 => rule_1753(ctx, v, l, loc, 112)
			# set_quantifier: ALL
			1756 => rule_143(ctx, v, l, loc, 1)
			# set_quantifier: DISTINCT
			1757 => rule_143(ctx, v, l, loc, 2)
			# set_quantifier: %empty
			1758 => rule_145(ctx, v, l, loc, 0)
			# distinct_clause: DISTINCT
			1759 => rule_1759(ctx, v, l, loc)
			# distinct_clause: DISTINCT ON '(' expr_list ')'
			1760 => rule_903(ctx, v, l, loc)
			# opt_distinct_clause: distinct_clause
			1763 => rule_139(ctx, v, l, loc)
			# opt_distinct_clause: opt_all_clause
			1764 => rule_265(ctx, v, l, loc)
			# opt_sort_clause: sort_clause
			1765 => rule_139(ctx, v, l, loc)
			# opt_sort_clause: %empty
			1766 => rule_140(ctx, v, l, loc)
			# sort_clause: ORDER BY sortby_list
			1767 => rule_563(ctx, v, l, loc)
			# sortby_list: sortby
			1768 => rule_224(ctx, v, l, loc)
			# sortby_list: sortby_list ',' sortby
			1769 => rule_225(ctx, v, l, loc)
			# sortby: a_expr USING qual_all_Op opt_nulls_order
			1770 => rule_1770(ctx, v, l, loc, 3)
			# sortby: a_expr opt_asc_desc opt_nulls_order
			1771 => rule_1771(ctx, v, l, loc, 1)
			# select_limit: limit_clause offset_clause
			1772 => rule_1772(ctx, v, l, loc)
			# select_limit: offset_clause limit_clause
			1773 => rule_1773(ctx, v, l, loc)
			# select_limit: limit_clause
			1774 => rule_164(ctx, v, l, loc)
			# select_limit: offset_clause
			1775 => rule_1775(ctx, v, l, loc, 0, 1, 1)
			# opt_select_limit: select_limit
			1776 => rule_164(ctx, v, l, loc)
			# opt_select_limit: %empty
			1777 => rule_136(ctx, v, l, loc)
			# limit_clause: LIMIT select_limit_value
			1778 => rule_1778(ctx, v, l, loc, 0, 1, 1)
			# limit_clause: LIMIT select_limit_value ',' select_offset_value
			1779 => rule_1779(ctx, v, l, loc)
			# limit_clause: FETCH first_or_next select_fetch_first_value row_or_rows ONLY
			1780 => rule_1780(ctx, v, l, loc, 0, 1, 1)
			# limit_clause: FETCH first_or_next select_fetch_first_value row_or_rows WITH TIES
			1781 => rule_1781(ctx, v, l, loc, 1, 1)
			# limit_clause: FETCH first_or_next row_or_rows ONLY
			1782 => rule_1782(ctx, v, l, loc, 1, 1, 0, 1, 1)
			# limit_clause: FETCH first_or_next row_or_rows WITH TIES
			1783 => rule_1783(ctx, v, l, loc, 1, 1, 1, 1)
			# offset_clause: OFFSET select_offset_value
			1784 => rule_248(ctx, v, l, loc)
			# offset_clause: OFFSET select_fetch_first_value row_or_rows
			1785 => rule_248(ctx, v, l, loc)
			# select_limit_value: a_expr
			1786 => rule_164(ctx, v, l, loc)
			# select_limit_value: ALL
			1787 => rule_1787(ctx, v, l, loc)
			# select_offset_value: a_expr
			1788 => rule_164(ctx, v, l, loc)
			# select_fetch_first_value: c_expr
			1789 => rule_164(ctx, v, l, loc)
			# select_fetch_first_value: '+' I_or_F_const
			1790 => rule_1790(ctx, v, l, loc, 0)
			# select_fetch_first_value: '-' I_or_F_const
			1791 => rule_1791(ctx, v, l, loc)
			# I_or_F_const: Iconst
			1792 => rule_1792(ctx, v, l, loc)
			# I_or_F_const: FCONST
			1793 => rule_1793(ctx, v, l, loc)
			# row_or_rows: ROW
			1794 => rule_143(ctx, v, l, loc, 0)
			# row_or_rows: ROWS
			1795 => rule_143(ctx, v, l, loc, 0)
			# first_or_next: FIRST_P
			1796 => rule_143(ctx, v, l, loc, 0)
			# first_or_next: NEXT
			1797 => rule_143(ctx, v, l, loc, 0)
			# group_clause: GROUP_P BY set_quantifier group_by_list
			1798 => rule_1798(ctx, v, l, loc, 2)
			# group_clause: %empty
			1799 => rule_1799(ctx, v, l, loc)
			# group_by_list: group_by_item
			1800 => rule_224(ctx, v, l, loc)
			# group_by_list: group_by_list ',' group_by_item
			1801 => rule_225(ctx, v, l, loc)
			# group_by_item: a_expr
			1802 => rule_164(ctx, v, l, loc)
			# group_by_item: empty_grouping_set
			1803 => rule_164(ctx, v, l, loc)
			# group_by_item: cube_clause
			1804 => rule_164(ctx, v, l, loc)
			# group_by_item: rollup_clause
			1805 => rule_164(ctx, v, l, loc)
			# group_by_item: grouping_sets_clause
			1806 => rule_164(ctx, v, l, loc)
			# empty_grouping_set: '(' ')'
			1807 => rule_1807(ctx, v, l, loc, 0)
			# rollup_clause: ROLLUP '(' expr_list ')'
			1808 => rule_1808(ctx, v, l, loc, 2)
			# cube_clause: CUBE '(' expr_list ')'
			1809 => rule_1808(ctx, v, l, loc, 3)
			# grouping_sets_clause: GROUPING SETS '(' group_by_list ')'
			1810 => rule_1810(ctx, v, l, loc, 4)
			# having_clause: HAVING a_expr
			1811 => rule_248(ctx, v, l, loc)
			# having_clause: %empty
			1812 => rule_136(ctx, v, l, loc)
			# for_locking_clause: for_locking_items
			1813 => rule_139(ctx, v, l, loc)
			# for_locking_clause: FOR READ ONLY
			1814 => rule_265(ctx, v, l, loc)
			# opt_for_locking_clause: for_locking_clause
			1815 => rule_139(ctx, v, l, loc)
			# opt_for_locking_clause: %empty
			1816 => rule_140(ctx, v, l, loc)
			# for_locking_items: for_locking_item
			1817 => rule_224(ctx, v, l, loc)
			# for_locking_items: for_locking_items for_locking_item
			1818 => rule_151(ctx, v, l, loc)
			# for_locking_item: for_locking_strength locked_rels_list opt_nowait_or_skip
			1819 => rule_1819(ctx, v, l, loc)
			# for_locking_strength: FOR UPDATE
			1820 => rule_143(ctx, v, l, loc, 4)
			# for_locking_strength: FOR NO KEY UPDATE
			1821 => rule_143(ctx, v, l, loc, 3)
			# for_locking_strength: FOR SHARE
			1822 => rule_143(ctx, v, l, loc, 2)
			# for_locking_strength: FOR KEY SHARE
			1823 => rule_143(ctx, v, l, loc, 1)
			# locked_rels_list: OF qualified_name_list
			1824 => rule_374(ctx, v, l, loc)
			# locked_rels_list: %empty
			1825 => rule_140(ctx, v, l, loc)
			# values_clause: VALUES '(' expr_list ')'
			1826 => rule_1826(ctx, v, l, loc)
			# values_clause: values_clause ',' '(' expr_list ')'
			1827 => rule_1827(ctx, v, l, loc)
			# from_clause: FROM from_list
			1828 => rule_374(ctx, v, l, loc)
			# from_clause: %empty
			1829 => rule_140(ctx, v, l, loc)
			# from_list: table_ref
			1830 => rule_224(ctx, v, l, loc)
			# from_list: from_list ',' table_ref
			1831 => rule_225(ctx, v, l, loc)
			# table_ref: relation_expr opt_alias_clause
			1832 => rule_1832(ctx, v, l, loc)
			# table_ref: relation_expr opt_alias_clause tablesample_clause
			1833 => rule_1833(ctx, v, l, loc)
			# table_ref: func_table func_alias_clause
			1834 => rule_1834(ctx, v, l, loc)
			# table_ref: LATERAL_P func_table func_alias_clause
			1835 => rule_1835(ctx, v, l, loc)
			# table_ref: xmltable opt_alias_clause
			1836 => rule_1836(ctx, v, l, loc)
			# table_ref: LATERAL_P xmltable opt_alias_clause
			1837 => rule_1837(ctx, v, l, loc)
			# table_ref: select_with_parens opt_alias_clause
			1838 => rule_1838(ctx, v, l, loc)
			# table_ref: LATERAL_P select_with_parens opt_alias_clause
			1839 => rule_1839(ctx, v, l, loc)
			# table_ref: joined_table
			1840 => rule_164(ctx, v, l, loc)
			# table_ref: '(' joined_table ')' alias_clause
			1841 => rule_1841(ctx, v, l, loc)
			# table_ref: json_table opt_alias_clause
			1842 => rule_1842(ctx, v, l, loc)
			# table_ref: LATERAL_P json_table opt_alias_clause
			1843 => rule_1843(ctx, v, l, loc)
			# joined_table: '(' joined_table ')'
			1844 => rule_248(ctx, v, l, loc)
			# joined_table: table_ref CROSS JOIN table_ref
			1845 => rule_1845(ctx, v, l, loc, 0)
			# joined_table: table_ref join_type JOIN table_ref join_qual
			1846 => rule_1846(ctx, v, l, loc)
			# joined_table: table_ref JOIN table_ref join_qual
			1847 => rule_1847(ctx, v, l, loc, 0)
			# joined_table: table_ref NATURAL join_type JOIN table_ref
			1848 => rule_1848(ctx, v, l, loc)
			# joined_table: table_ref NATURAL JOIN table_ref
			1849 => rule_1849(ctx, v, l, loc, 0)
			# alias_clause: AS ColId '(' name_list ')'
			1850 => rule_1850(ctx, v, l, loc)
			# alias_clause: AS ColId
			1851 => rule_1851(ctx, v, l, loc)
			# alias_clause: ColId '(' name_list ')'
			1852 => rule_1852(ctx, v, l, loc)
			# alias_clause: ColId
			1853 => rule_1853(ctx, v, l, loc)
			# opt_alias_clause: alias_clause
			1854 => rule_164(ctx, v, l, loc)
			# opt_alias_clause: %empty
			1855 => rule_136(ctx, v, l, loc)
			# opt_alias_clause_for_join_using: AS ColId
			1856 => rule_1851(ctx, v, l, loc)
			# opt_alias_clause_for_join_using: %empty
			1857 => rule_136(ctx, v, l, loc)
			# func_alias_clause: alias_clause
			1858 => rule_1858(ctx, v, l, loc)
			# func_alias_clause: AS '(' TableFuncElementList ')'
			1859 => rule_1859(ctx, v, l, loc)
			# func_alias_clause: AS ColId '(' TableFuncElementList ')'
			1860 => rule_1860(ctx, v, l, loc)
			# func_alias_clause: ColId '(' TableFuncElementList ')'
			1861 => rule_1861(ctx, v, l, loc)
			# func_alias_clause: %empty
			1862 => rule_561(ctx, v, l, loc)
			# join_type: FULL opt_outer
			1863 => rule_143(ctx, v, l, loc, 2)
			# join_type: LEFT opt_outer
			1864 => rule_143(ctx, v, l, loc, 1)
			# join_type: RIGHT opt_outer
			1865 => rule_143(ctx, v, l, loc, 3)
			# join_type: INNER_P
			1866 => rule_143(ctx, v, l, loc, 0)
			# join_qual: USING '(' name_list ')' opt_alias_clause_for_join_using
			1869 => rule_1869(ctx, v, l, loc)
			# join_qual: ON a_expr
			1870 => rule_248(ctx, v, l, loc)
			# relation_expr: qualified_name
			1871 => rule_1871(ctx, v, l, loc)
			# relation_expr: extended_relation_expr
			1872 => rule_164(ctx, v, l, loc)
			# extended_relation_expr: qualified_name '*'
			1873 => rule_1871(ctx, v, l, loc)
			# extended_relation_expr: ONLY qualified_name
			1874 => rule_1874(ctx, v, l, loc)
			# extended_relation_expr: ONLY '(' qualified_name ')'
			1875 => rule_1875(ctx, v, l, loc)
			# relation_expr_list: relation_expr
			1876 => rule_224(ctx, v, l, loc)
			# relation_expr_list: relation_expr_list ',' relation_expr
			1877 => rule_225(ctx, v, l, loc)
			# relation_expr_opt_alias: relation_expr
			1878 => rule_164(ctx, v, l, loc)
			# relation_expr_opt_alias: relation_expr ColId
			1879 => rule_1879(ctx, v, l, loc)
			# relation_expr_opt_alias: relation_expr AS ColId
			1880 => rule_1880(ctx, v, l, loc)
			# tablesample_clause: TABLESAMPLE func_name '(' expr_list ')' opt_repeatable_clause
			1881 => rule_1881(ctx, v, l, loc)
			# opt_repeatable_clause: REPEATABLE '(' a_expr ')'
			1882 => rule_364(ctx, v, l, loc)
			# opt_repeatable_clause: %empty
			1883 => rule_136(ctx, v, l, loc)
			# func_table: func_expr_windowless opt_ordinality
			1884 => rule_1884(ctx, v, l, loc)
			# func_table: ROWS FROM '(' rowsfrom_list ')' opt_ordinality
			1885 => rule_1885(ctx, v, l, loc)
			# rowsfrom_item: func_expr_windowless opt_col_def_list
			1886 => rule_1886(ctx, v, l, loc)
			# rowsfrom_list: rowsfrom_item
			1887 => rule_569(ctx, v, l, loc)
			# rowsfrom_list: rowsfrom_list ',' rowsfrom_item
			1888 => rule_570(ctx, v, l, loc)
			# opt_col_def_list: AS '(' TableFuncElementList ')'
			1889 => rule_563(ctx, v, l, loc)
			# opt_col_def_list: %empty
			1890 => rule_140(ctx, v, l, loc)
			# opt_ordinality: WITH_LA ORDINALITY
			1891 => rule_141(ctx, v, l, loc)
			# opt_ordinality: %empty
			1892 => rule_142(ctx, v, l, loc)
			# where_clause: WHERE a_expr
			1893 => rule_248(ctx, v, l, loc)
			# where_clause: %empty
			1894 => rule_136(ctx, v, l, loc)
			# where_or_current_clause: WHERE a_expr
			1895 => rule_248(ctx, v, l, loc)
			# where_or_current_clause: WHERE CURRENT_P OF cursor_name
			1896 => rule_1896(ctx, v, l, loc, 0)
			# where_or_current_clause: %empty
			1897 => rule_136(ctx, v, l, loc)
			# OptTableFuncElementList: TableFuncElementList
			1898 => rule_139(ctx, v, l, loc)
			# OptTableFuncElementList: %empty
			1899 => rule_140(ctx, v, l, loc)
			# TableFuncElementList: TableFuncElement
			1900 => rule_224(ctx, v, l, loc)
			# TableFuncElementList: TableFuncElementList ',' TableFuncElement
			1901 => rule_225(ctx, v, l, loc)
			# TableFuncElement: ColId Typename opt_collate_clause
			1902 => rule_1902(ctx, v, l, loc, 0, 0, 0)
			# xmltable: XMLTABLE '(' c_expr xmlexists_argument COLUMNS xmltable_column_list ')'
			1903 => rule_1903(ctx, v, l, loc)
			# xmltable: XMLTABLE '(' XMLNAMESPACES '(' xml_namespace_list ')' ',' c_expr xmlexists_argument COLUMNS xmltable_column_list ')'
			1904 => rule_1904(ctx, v, l, loc)
			# xmltable_column_list: xmltable_column_el
			1905 => rule_224(ctx, v, l, loc)
			# xmltable_column_list: xmltable_column_list ',' xmltable_column_el
			1906 => rule_225(ctx, v, l, loc)
			# xmltable_column_el: ColId Typename
			1907 => rule_1907(ctx, v, l, loc)
			# xmltable_column_el: ColId Typename xmltable_column_option_list
			1908 => rule_1908(ctx, v, l, loc, 0, 0, 0)
			# xmltable_column_el: ColId FOR ORDINALITY
			1909 => rule_1909(ctx, v, l, loc)
			# xmltable_column_option_list: xmltable_column_option_el
			1910 => rule_224(ctx, v, l, loc)
			# xmltable_column_option_list: xmltable_column_option_list xmltable_column_option_el
			1911 => rule_151(ctx, v, l, loc)
			# xmltable_column_option_el: IDENT b_expr
			1912 => rule_1912(ctx, v, l, loc, 0)
			# xmltable_column_option_el: DEFAULT b_expr
			1913 => rule_1913(ctx, v, l, loc)
			# xmltable_column_option_el: NOT NULL_P
			1914 => rule_1914(ctx, v, l, loc)
			# xmltable_column_option_el: NULL_P
			1915 => rule_1915(ctx, v, l, loc)
			# xmltable_column_option_el: PATH b_expr
			1916 => rule_1916(ctx, v, l, loc)
			# xml_namespace_list: xml_namespace_el
			1917 => rule_224(ctx, v, l, loc)
			# xml_namespace_list: xml_namespace_list ',' xml_namespace_el
			1918 => rule_225(ctx, v, l, loc)
			# xml_namespace_el: b_expr AS ColLabel
			1919 => rule_1919(ctx, v, l, loc)
			# xml_namespace_el: DEFAULT b_expr
			1920 => rule_1920(ctx, v, l, loc)
			# json_table: JSON_TABLE '(' json_value_expr ',' a_expr json_table_path_name_opt json_passing_clause_opt COLUMNS '(' json_table_column_definition_list ')' json_on_error_clause_opt ')'
			1921 => rule_1921(ctx, v, l, loc)
			# json_table_path_name_opt: AS name
			1922 => rule_485(ctx, v, l, loc)
			# json_table_path_name_opt: %empty
			1923 => rule_138(ctx, v, l, loc)
			# json_table_column_definition_list: json_table_column_definition
			1924 => rule_224(ctx, v, l, loc)
			# json_table_column_definition_list: json_table_column_definition_list ',' json_table_column_definition
			1925 => rule_225(ctx, v, l, loc)
			# json_table_column_definition: ColId FOR ORDINALITY
			1926 => rule_1926(ctx, v, l, loc, 0)
			# json_table_column_definition: ColId Typename json_table_column_path_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt
			1927 => rule_1927(ctx, v, l, loc, 1, 0, 0, 1)
			# json_table_column_definition: ColId Typename json_format_clause json_table_column_path_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt
			1928 => rule_1928(ctx, v, l, loc, 3)
			# json_table_column_definition: ColId Typename EXISTS json_table_column_path_clause_opt json_on_error_clause_opt
			1929 => rule_1929(ctx, v, l, loc, 2, 0, 0, 1, 1, 0)
			# json_table_column_definition: NESTED path_opt Sconst COLUMNS '(' json_table_column_definition_list ')'
			1930 => rule_1930(ctx, v, l, loc, 4, 1)
			# json_table_column_definition: NESTED path_opt Sconst AS name COLUMNS '(' json_table_column_definition_list ')'
			1931 => rule_1931(ctx, v, l, loc, 4)
			# json_table_column_path_clause_opt: PATH Sconst
			1934 => rule_1934(ctx, v, l, loc, 1)
			# json_table_column_path_clause_opt: %empty
			1935 => rule_136(ctx, v, l, loc)
			# Typename: SimpleTypename opt_array_bounds
			1936 => rule_1936(ctx, v, l, loc)
			# Typename: SETOF SimpleTypename opt_array_bounds
			1937 => rule_1937(ctx, v, l, loc)
			# Typename: SimpleTypename ARRAY '[' Iconst ']'
			1938 => rule_1938(ctx, v, l, loc)
			# Typename: SETOF SimpleTypename ARRAY '[' Iconst ']'
			1939 => rule_1939(ctx, v, l, loc)
			# Typename: SimpleTypename ARRAY
			1940 => rule_1940(ctx, v, l, loc, 1)
			# Typename: SETOF SimpleTypename ARRAY
			1941 => rule_1941(ctx, v, l, loc, 1)
			# opt_array_bounds: opt_array_bounds '[' ']'
			1942 => rule_1942(ctx, v, l, loc, 1)
			# opt_array_bounds: opt_array_bounds '[' Iconst ']'
			1943 => rule_1943(ctx, v, l, loc)
			# opt_array_bounds: %empty
			1944 => rule_140(ctx, v, l, loc)
			# SimpleTypename: GenericType
			1945 => rule_164(ctx, v, l, loc)
			# SimpleTypename: Numeric
			1946 => rule_164(ctx, v, l, loc)
			# SimpleTypename: Bit
			1947 => rule_164(ctx, v, l, loc)
			# SimpleTypename: Character
			1948 => rule_164(ctx, v, l, loc)
			# SimpleTypename: ConstDatetime
			1949 => rule_164(ctx, v, l, loc)
			# SimpleTypename: ConstInterval opt_interval
			1950 => rule_1950(ctx, v, l, loc)
			# SimpleTypename: ConstInterval '(' Iconst ')'
			1951 => rule_1951(ctx, v, l, loc, 32767, 1)
			# SimpleTypename: JsonType
			1952 => rule_164(ctx, v, l, loc)
			# ConstTypename: Numeric
			1953 => rule_164(ctx, v, l, loc)
			# ConstTypename: ConstBit
			1954 => rule_164(ctx, v, l, loc)
			# ConstTypename: ConstCharacter
			1955 => rule_164(ctx, v, l, loc)
			# ConstTypename: ConstDatetime
			1956 => rule_164(ctx, v, l, loc)
			# ConstTypename: JsonType
			1957 => rule_164(ctx, v, l, loc)
			# GenericType: type_function_name opt_type_modifiers
			1958 => rule_1958(ctx, v, l, loc)
			# GenericType: type_function_name attrs opt_type_modifiers
			1959 => rule_1959(ctx, v, l, loc)
			# opt_type_modifiers: '(' expr_list ')'
			1960 => rule_374(ctx, v, l, loc)
			# opt_type_modifiers: %empty
			1961 => rule_140(ctx, v, l, loc)
			# Numeric: INT_P
			1962 => rule_1962(ctx, v, l, loc)
			# Numeric: INTEGER
			1963 => rule_1962(ctx, v, l, loc)
			# Numeric: SMALLINT
			1964 => rule_1964(ctx, v, l, loc)
			# Numeric: BIGINT
			1965 => rule_1965(ctx, v, l, loc)
			# Numeric: REAL
			1966 => rule_1966(ctx, v, l, loc)
			# Numeric: FLOAT_P opt_float
			1967 => rule_1967(ctx, v, l, loc)
			# Numeric: DOUBLE_P PRECISION
			1968 => rule_1968(ctx, v, l, loc)
			# Numeric: DECIMAL_P opt_type_modifiers
			1969 => rule_1969(ctx, v, l, loc)
			# Numeric: DEC opt_type_modifiers
			1970 => rule_1969(ctx, v, l, loc)
			# Numeric: NUMERIC opt_type_modifiers
			1971 => rule_1969(ctx, v, l, loc)
			# Numeric: BOOLEAN_P
			1972 => rule_1972(ctx, v, l, loc)
			# opt_float: '(' Iconst ')'
			1973 => rule_1973(ctx, v, l, loc, 1, 24, 53)
			# opt_float: %empty
			1974 => rule_1974(ctx, v, l, loc)
			# Bit: BitWithLength
			1975 => rule_164(ctx, v, l, loc)
			# Bit: BitWithoutLength
			1976 => rule_164(ctx, v, l, loc)
			# ConstBit: BitWithLength
			1977 => rule_164(ctx, v, l, loc)
			# ConstBit: BitWithoutLength
			1978 => rule_1978(ctx, v, l, loc)
			# BitWithLength: BIT opt_varying '(' expr_list ')'
			1979 => rule_1979(ctx, v, l, loc)
			# BitWithoutLength: BIT opt_varying
			1980 => rule_1980(ctx, v, l, loc, 1, 1)
			# Character: CharacterWithLength
			1981 => rule_164(ctx, v, l, loc)
			# Character: CharacterWithoutLength
			1982 => rule_164(ctx, v, l, loc)
			# ConstCharacter: CharacterWithLength
			1983 => rule_164(ctx, v, l, loc)
			# ConstCharacter: CharacterWithoutLength
			1984 => rule_1978(ctx, v, l, loc)
			# CharacterWithLength: character '(' Iconst ')'
			1985 => rule_1985(ctx, v, l, loc)
			# CharacterWithoutLength: character
			1986 => rule_1986(ctx, v, l, loc, 0, 1, 1)
			# character: CHARACTER opt_varying
			1987 => rule_1987(ctx, v, l, loc)
			# character: CHAR_P opt_varying
			1988 => rule_1987(ctx, v, l, loc)
			# character: VARCHAR
			1989 => rule_1989(ctx, v, l, loc)
			# character: NATIONAL CHARACTER opt_varying
			1990 => rule_1990(ctx, v, l, loc)
			# character: NATIONAL CHAR_P opt_varying
			1991 => rule_1990(ctx, v, l, loc)
			# character: NCHAR opt_varying
			1992 => rule_1987(ctx, v, l, loc)
			# opt_varying: VARYING
			1993 => rule_141(ctx, v, l, loc)
			# opt_varying: %empty
			1994 => rule_142(ctx, v, l, loc)
			# ConstDatetime: TIMESTAMP '(' Iconst ')' opt_timezone
			1995 => rule_1995(ctx, v, l, loc)
			# ConstDatetime: TIMESTAMP opt_timezone
			1996 => rule_1996(ctx, v, l, loc)
			# ConstDatetime: TIME '(' Iconst ')' opt_timezone
			1997 => rule_1997(ctx, v, l, loc)
			# ConstDatetime: TIME opt_timezone
			1998 => rule_1998(ctx, v, l, loc)
			# ConstInterval: INTERVAL
			1999 => rule_1999(ctx, v, l, loc)
			# opt_timezone: WITH_LA TIME ZONE
			2000 => rule_141(ctx, v, l, loc)
			# opt_timezone: WITHOUT_LA TIME ZONE
			2001 => rule_268(ctx, v, l, loc)
			# opt_timezone: %empty
			2002 => rule_142(ctx, v, l, loc)
			# opt_interval: YEAR_P
			2003 => rule_2003(ctx, v, l, loc, 2)
			# opt_interval: MONTH_P
			2004 => rule_2003(ctx, v, l, loc, 1)
			# opt_interval: DAY_P
			2005 => rule_2003(ctx, v, l, loc, 3)
			# opt_interval: HOUR_P
			2006 => rule_2003(ctx, v, l, loc, 10)
			# opt_interval: MINUTE_P
			2007 => rule_2003(ctx, v, l, loc, 11)
			# opt_interval: interval_second
			2008 => rule_139(ctx, v, l, loc)
			# opt_interval: YEAR_P TO MONTH_P
			2009 => rule_2009(ctx, v, l, loc, 2, 1)
			# opt_interval: DAY_P TO HOUR_P
			2010 => rule_2009(ctx, v, l, loc, 3, 10)
			# opt_interval: DAY_P TO MINUTE_P
			2011 => rule_2011(ctx, v, l, loc, 3, 10, 11)
			# opt_interval: DAY_P TO interval_second
			2012 => rule_2012(ctx, v, l, loc, 3, 10, 11, 12)
			# opt_interval: HOUR_P TO MINUTE_P
			2013 => rule_2009(ctx, v, l, loc, 10, 11)
			# opt_interval: HOUR_P TO interval_second
			2014 => rule_2014(ctx, v, l, loc, 10, 11, 12)
			# opt_interval: MINUTE_P TO interval_second
			2015 => rule_2015(ctx, v, l, loc, 11, 12)
			# opt_interval: %empty
			2016 => rule_140(ctx, v, l, loc)
			# interval_second: SECOND_P
			2017 => rule_2003(ctx, v, l, loc, 12)
			# interval_second: SECOND_P '(' Iconst ')'
			2018 => rule_2018(ctx, v, l, loc, 12)
			# JsonType: JSON
			2019 => rule_2019(ctx, v, l, loc)
			# a_expr: c_expr
			2020 => rule_164(ctx, v, l, loc)
			# a_expr: a_expr TYPECAST Typename
			2021 => rule_2021(ctx, v, l, loc)
			# a_expr: a_expr COLLATE any_name
			2022 => rule_2022(ctx, v, l, loc)
			# a_expr: a_expr AT TIME ZONE a_expr
			2023 => rule_2023(ctx, v, l, loc, 3)
			# a_expr: a_expr AT LOCAL
			2024 => rule_2024(ctx, v, l, loc, 3, 1)
			# a_expr: '+' a_expr
			2025 => rule_1790(ctx, v, l, loc, 0)
			# a_expr: '-' a_expr
			2026 => rule_1791(ctx, v, l, loc)
			# a_expr: a_expr '+' a_expr
			2027 => rule_2027(ctx, v, l, loc, 0)
			# a_expr: a_expr '-' a_expr
			2028 => rule_2028(ctx, v, l, loc, 0)
			# a_expr: a_expr '*' a_expr
			2029 => rule_2029(ctx, v, l, loc, 0)
			# a_expr: a_expr '/' a_expr
			2030 => rule_2030(ctx, v, l, loc, 0)
			# a_expr: a_expr '%' a_expr
			2031 => rule_2031(ctx, v, l, loc, 0)
			# a_expr: a_expr '^' a_expr
			2032 => rule_2032(ctx, v, l, loc, 0)
			# a_expr: a_expr '<' a_expr
			2033 => rule_2033(ctx, v, l, loc, 0)
			# a_expr: a_expr '>' a_expr
			2034 => rule_2034(ctx, v, l, loc, 0)
			# a_expr: a_expr '=' a_expr
			2035 => rule_2035(ctx, v, l, loc, 0)
			# a_expr: a_expr LESS_EQUALS a_expr
			2036 => rule_2036(ctx, v, l, loc, 0)
			# a_expr: a_expr GREATER_EQUALS a_expr
			2037 => rule_2037(ctx, v, l, loc, 0)
			# a_expr: a_expr NOT_EQUALS a_expr
			2038 => rule_2038(ctx, v, l, loc, 0)
			# a_expr: a_expr qual_Op a_expr
			2039 => rule_2039(ctx, v, l, loc, 0)
			# a_expr: qual_Op a_expr
			2040 => rule_2040(ctx, v, l, loc, 0)
			# a_expr: a_expr AND a_expr
			2041 => rule_2041(ctx, v, l, loc)
			# a_expr: a_expr OR a_expr
			2042 => rule_2042(ctx, v, l, loc)
			# a_expr: NOT a_expr
			2043 => rule_2043(ctx, v, l, loc)
			# a_expr: NOT_LA a_expr
			2044 => rule_2043(ctx, v, l, loc)
			# a_expr: a_expr LIKE a_expr
			2045 => rule_2045(ctx, v, l, loc, 7)
			# a_expr: a_expr LIKE a_expr ESCAPE a_expr
			2046 => rule_2046(ctx, v, l, loc, 0, 7)
			# a_expr: a_expr NOT_LA LIKE a_expr
			2047 => rule_2047(ctx, v, l, loc, 7)
			# a_expr: a_expr NOT_LA LIKE a_expr ESCAPE a_expr
			2048 => rule_2048(ctx, v, l, loc, 0, 7)
			# a_expr: a_expr ILIKE a_expr
			2049 => rule_2049(ctx, v, l, loc, 8)
			# a_expr: a_expr ILIKE a_expr ESCAPE a_expr
			2050 => rule_2050(ctx, v, l, loc, 0, 8)
			# a_expr: a_expr NOT_LA ILIKE a_expr
			2051 => rule_2051(ctx, v, l, loc, 8)
			# a_expr: a_expr NOT_LA ILIKE a_expr ESCAPE a_expr
			2052 => rule_2052(ctx, v, l, loc, 0, 8)
			# a_expr: a_expr SIMILAR TO a_expr
			2053 => rule_2053(ctx, v, l, loc, 0, 9)
			# a_expr: a_expr SIMILAR TO a_expr ESCAPE a_expr
			2054 => rule_2054(ctx, v, l, loc, 0, 9)
			# a_expr: a_expr NOT_LA SIMILAR TO a_expr
			2055 => rule_2055(ctx, v, l, loc, 0, 9)
			# a_expr: a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr
			2056 => rule_2056(ctx, v, l, loc, 0, 9)
			# a_expr: a_expr IS NULL_P
			2057 => rule_2057(ctx, v, l, loc, 0)
			# a_expr: a_expr ISNULL
			2058 => rule_2057(ctx, v, l, loc, 0)
			# a_expr: a_expr IS NOT NULL_P
			2059 => rule_2057(ctx, v, l, loc, 1)
			# a_expr: a_expr NOTNULL
			2060 => rule_2057(ctx, v, l, loc, 1)
			# a_expr: row OVERLAPS row
			2061 => rule_2061(ctx, v, l, loc, 2, 2, 3)
			# a_expr: a_expr IS TRUE_P
			2062 => rule_2062(ctx, v, l, loc, 0)
			# a_expr: a_expr IS NOT TRUE_P
			2063 => rule_2062(ctx, v, l, loc, 1)
			# a_expr: a_expr IS FALSE_P
			2064 => rule_2062(ctx, v, l, loc, 2)
			# a_expr: a_expr IS NOT FALSE_P
			2065 => rule_2062(ctx, v, l, loc, 3)
			# a_expr: a_expr IS UNKNOWN
			2066 => rule_2062(ctx, v, l, loc, 4)
			# a_expr: a_expr IS NOT UNKNOWN
			2067 => rule_2062(ctx, v, l, loc, 5)
			# a_expr: a_expr IS DISTINCT FROM a_expr
			2068 => rule_2068(ctx, v, l, loc, 3)
			# a_expr: a_expr IS NOT DISTINCT FROM a_expr
			2069 => rule_2069(ctx, v, l, loc, 4)
			# a_expr: a_expr BETWEEN opt_asymmetric b_expr AND a_expr
			2070 => rule_2070(ctx, v, l, loc, 10)
			# a_expr: a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr
			2071 => rule_2071(ctx, v, l, loc, 11)
			# a_expr: a_expr BETWEEN SYMMETRIC b_expr AND a_expr
			2072 => rule_2072(ctx, v, l, loc, 12)
			# a_expr: a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr
			2073 => rule_2073(ctx, v, l, loc, 13)
			# a_expr: a_expr IN_P select_with_parens
			2074 => rule_2074(ctx, v, l, loc, 2, 0)
			# a_expr: a_expr IN_P '(' expr_list ')'
			2075 => rule_2075(ctx, v, l, loc, 6)
			# a_expr: a_expr NOT_LA IN_P select_with_parens
			2076 => rule_2076(ctx, v, l, loc, 2, 0)
			# a_expr: a_expr NOT_LA IN_P '(' expr_list ')'
			2077 => rule_2077(ctx, v, l, loc, 6)
			# a_expr: a_expr subquery_Op sub_type select_with_parens
			2078 => rule_2078(ctx, v, l, loc, 0)
			# a_expr: a_expr subquery_Op sub_type '(' a_expr ')'
			2079 => rule_2079(ctx, v, l, loc, 2, 1, 2)
			# a_expr: UNIQUE opt_unique_null_treatment select_with_parens
			2080 => rule_2080(ctx, v, l, loc)
			# a_expr: a_expr IS DOCUMENT_P
			2081 => rule_2081(ctx, v, l, loc, 7)
			# a_expr: a_expr IS NOT DOCUMENT_P
			2082 => rule_2082(ctx, v, l, loc, 7)
			# a_expr: a_expr IS NORMALIZED
			2083 => rule_2083(ctx, v, l, loc, 3)
			# a_expr: a_expr IS unicode_normal_form NORMALIZED
			2084 => rule_2084(ctx, v, l, loc, 3)
			# a_expr: a_expr IS NOT NORMALIZED
			2085 => rule_2085(ctx, v, l, loc, 3)
			# a_expr: a_expr IS NOT unicode_normal_form NORMALIZED
			2086 => rule_2086(ctx, v, l, loc, 3)
			# a_expr: a_expr IS json_predicate_type_constraint json_key_uniqueness_constraint_opt
			2087 => rule_2087(ctx, v, l, loc, 0, 0, 1)
			# a_expr: a_expr IS NOT json_predicate_type_constraint json_key_uniqueness_constraint_opt
			2088 => rule_2088(ctx, v, l, loc, 0, 0, 1)
			# a_expr: DEFAULT
			2089 => rule_2089(ctx, v, l, loc)
			# b_expr: c_expr
			2090 => rule_164(ctx, v, l, loc)
			# b_expr: b_expr TYPECAST Typename
			2091 => rule_2021(ctx, v, l, loc)
			# b_expr: '+' b_expr
			2092 => rule_1790(ctx, v, l, loc, 0)
			# b_expr: '-' b_expr
			2093 => rule_1791(ctx, v, l, loc)
			# b_expr: b_expr '+' b_expr
			2094 => rule_2027(ctx, v, l, loc, 0)
			# b_expr: b_expr '-' b_expr
			2095 => rule_2028(ctx, v, l, loc, 0)
			# b_expr: b_expr '*' b_expr
			2096 => rule_2029(ctx, v, l, loc, 0)
			# b_expr: b_expr '/' b_expr
			2097 => rule_2030(ctx, v, l, loc, 0)
			# b_expr: b_expr '%' b_expr
			2098 => rule_2031(ctx, v, l, loc, 0)
			# b_expr: b_expr '^' b_expr
			2099 => rule_2032(ctx, v, l, loc, 0)
			# b_expr: b_expr '<' b_expr
			2100 => rule_2033(ctx, v, l, loc, 0)
			# b_expr: b_expr '>' b_expr
			2101 => rule_2034(ctx, v, l, loc, 0)
			# b_expr: b_expr '=' b_expr
			2102 => rule_2035(ctx, v, l, loc, 0)
			# b_expr: b_expr LESS_EQUALS b_expr
			2103 => rule_2036(ctx, v, l, loc, 0)
			# b_expr: b_expr GREATER_EQUALS b_expr
			2104 => rule_2037(ctx, v, l, loc, 0)
			# b_expr: b_expr NOT_EQUALS b_expr
			2105 => rule_2038(ctx, v, l, loc, 0)
			# b_expr: b_expr qual_Op b_expr
			2106 => rule_2039(ctx, v, l, loc, 0)
			# b_expr: qual_Op b_expr
			2107 => rule_2040(ctx, v, l, loc, 0)
			# b_expr: b_expr IS DISTINCT FROM b_expr
			2108 => rule_2068(ctx, v, l, loc, 3)
			# b_expr: b_expr IS NOT DISTINCT FROM b_expr
			2109 => rule_2069(ctx, v, l, loc, 4)
			# b_expr: b_expr IS DOCUMENT_P
			2110 => rule_2081(ctx, v, l, loc, 7)
			# b_expr: b_expr IS NOT DOCUMENT_P
			2111 => rule_2082(ctx, v, l, loc, 7)
			# c_expr: columnref
			2112 => rule_164(ctx, v, l, loc)
			# c_expr: AexprConst
			2113 => rule_164(ctx, v, l, loc)
			# c_expr: PARAM opt_indirection
			2114 => rule_2114(ctx, v, l, loc)
			# c_expr: '(' a_expr ')' opt_indirection
			2115 => rule_2115(ctx, v, l, loc)
			# c_expr: case_expr
			2116 => rule_164(ctx, v, l, loc)
			# c_expr: func_expr
			2117 => rule_164(ctx, v, l, loc)
			# c_expr: select_with_parens
			2118 => rule_2118(ctx, v, l, loc, 4, 0)
			# c_expr: select_with_parens indirection
			2119 => rule_2119(ctx, v, l, loc, 4, 0)
			# c_expr: EXISTS select_with_parens
			2120 => rule_2120(ctx, v, l, loc, 0, 0)
			# c_expr: ARRAY select_with_parens
			2121 => rule_2120(ctx, v, l, loc, 6, 0)
			# c_expr: ARRAY array_expr
			2122 => rule_2122(ctx, v, l, loc)
			# c_expr: explicit_row
			2123 => rule_2123(ctx, v, l, loc, 0, 0)
			# c_expr: implicit_row
			2124 => rule_2123(ctx, v, l, loc, 0, 2)
			# c_expr: GROUPING '(' expr_list ')'
			2125 => rule_2125(ctx, v, l, loc)
			# func_application: func_name '(' ')'
			2126 => rule_2126(ctx, v, l, loc, 0)
			# func_application: func_name '(' func_arg_list opt_sort_clause ')'
			2127 => rule_2127(ctx, v, l, loc, 0)
			# func_application: func_name '(' VARIADIC func_arg_expr opt_sort_clause ')'
			2128 => rule_2128(ctx, v, l, loc, 0)
			# func_application: func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')'
			2129 => rule_2129(ctx, v, l, loc, 0)
			# func_application: func_name '(' ALL func_arg_list opt_sort_clause ')'
			2130 => rule_2130(ctx, v, l, loc, 0)
			# func_application: func_name '(' DISTINCT func_arg_list opt_sort_clause ')'
			2131 => rule_2131(ctx, v, l, loc, 0)
			# func_application: func_name '(' '*' ')'
			2132 => rule_2132(ctx, v, l, loc, 0)
			# func_expr: func_application within_group_clause filter_clause over_clause
			2133 => rule_2133(ctx, v, l, loc)
			# func_expr: json_aggregate_func filter_clause over_clause
			2134 => rule_2134(ctx, v, l, loc)
			# func_expr: func_expr_common_subexpr
			2135 => rule_164(ctx, v, l, loc)
			# func_expr_windowless: func_application
			2136 => rule_164(ctx, v, l, loc)
			# func_expr_windowless: func_expr_common_subexpr
			2137 => rule_164(ctx, v, l, loc)
			# func_expr_windowless: json_aggregate_func
			2138 => rule_164(ctx, v, l, loc)
			# func_expr_common_subexpr: COLLATION FOR '(' a_expr ')'
			2139 => rule_2139(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: CURRENT_DATE
			2140 => rule_2140(ctx, v, l, loc, 0, 1)
			# func_expr_common_subexpr: CURRENT_TIME
			2141 => rule_2140(ctx, v, l, loc, 1, 1)
			# func_expr_common_subexpr: CURRENT_TIME '(' Iconst ')'
			2142 => rule_2142(ctx, v, l, loc, 2)
			# func_expr_common_subexpr: CURRENT_TIMESTAMP
			2143 => rule_2140(ctx, v, l, loc, 3, 1)
			# func_expr_common_subexpr: CURRENT_TIMESTAMP '(' Iconst ')'
			2144 => rule_2142(ctx, v, l, loc, 4)
			# func_expr_common_subexpr: LOCALTIME
			2145 => rule_2140(ctx, v, l, loc, 5, 1)
			# func_expr_common_subexpr: LOCALTIME '(' Iconst ')'
			2146 => rule_2142(ctx, v, l, loc, 6)
			# func_expr_common_subexpr: LOCALTIMESTAMP
			2147 => rule_2140(ctx, v, l, loc, 7, 1)
			# func_expr_common_subexpr: LOCALTIMESTAMP '(' Iconst ')'
			2148 => rule_2142(ctx, v, l, loc, 8)
			# func_expr_common_subexpr: CURRENT_ROLE
			2149 => rule_2140(ctx, v, l, loc, 9, 1)
			# func_expr_common_subexpr: CURRENT_USER
			2150 => rule_2140(ctx, v, l, loc, 10, 1)
			# func_expr_common_subexpr: SESSION_USER
			2151 => rule_2140(ctx, v, l, loc, 12, 1)
			# func_expr_common_subexpr: SYSTEM_USER
			2152 => rule_2152(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: USER
			2153 => rule_2140(ctx, v, l, loc, 11, 1)
			# func_expr_common_subexpr: CURRENT_CATALOG
			2154 => rule_2140(ctx, v, l, loc, 13, 1)
			# func_expr_common_subexpr: CURRENT_SCHEMA
			2155 => rule_2140(ctx, v, l, loc, 14, 1)
			# func_expr_common_subexpr: CAST '(' a_expr AS Typename ')'
			2156 => rule_2156(ctx, v, l, loc)
			# func_expr_common_subexpr: EXTRACT '(' extract_list ')'
			2157 => rule_2157(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: NORMALIZE '(' a_expr ')'
			2158 => rule_2158(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: NORMALIZE '(' a_expr ',' unicode_normal_form ')'
			2159 => rule_2159(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: OVERLAY '(' overlay_list ')'
			2160 => rule_2160(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: OVERLAY '(' func_arg_list_opt ')'
			2161 => rule_2161(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: POSITION '(' position_list ')'
			2162 => rule_2162(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: SUBSTRING '(' substr_list ')'
			2163 => rule_2163(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: SUBSTRING '(' func_arg_list_opt ')'
			2164 => rule_2164(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: TREAT '(' a_expr AS Typename ')'
			2165 => rule_2165(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: TRIM '(' BOTH trim_list ')'
			2166 => rule_2166(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: TRIM '(' LEADING trim_list ')'
			2167 => rule_2167(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: TRIM '(' TRAILING trim_list ')'
			2168 => rule_2168(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: TRIM '(' trim_list ')'
			2169 => rule_2169(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: NULLIF '(' a_expr ',' a_expr ')'
			2170 => rule_2170(ctx, v, l, loc, 5)
			# func_expr_common_subexpr: COALESCE '(' expr_list ')'
			2171 => rule_2171(ctx, v, l, loc)
			# func_expr_common_subexpr: GREATEST '(' expr_list ')'
			2172 => rule_2172(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: LEAST '(' expr_list ')'
			2173 => rule_2172(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: XMLCONCAT '(' expr_list ')'
			2174 => rule_2174(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ')'
			2175 => rule_2175(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ')'
			2176 => rule_2176(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' expr_list ')'
			2177 => rule_2177(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ',' expr_list ')'
			2178 => rule_2178(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: XMLEXISTS '(' c_expr xmlexists_argument ')'
			2179 => rule_2179(ctx, v, l, loc, 3)
			# func_expr_common_subexpr: XMLFOREST '(' xml_attribute_list ')'
			2180 => rule_2180(ctx, v, l, loc, 2)
			# func_expr_common_subexpr: XMLPARSE '(' document_or_content a_expr xml_whitespace_option ')'
			2181 => rule_2181(ctx, v, l, loc, 3, 1)
			# func_expr_common_subexpr: XMLPI '(' NAME_P ColLabel ')'
			2182 => rule_2175(ctx, v, l, loc, 4)
			# func_expr_common_subexpr: XMLPI '(' NAME_P ColLabel ',' a_expr ')'
			2183 => rule_2183(ctx, v, l, loc, 4)
			# func_expr_common_subexpr: XMLROOT '(' a_expr ',' xml_root_version opt_xml_root_standalone ')'
			2184 => rule_2184(ctx, v, l, loc, 5)
			# func_expr_common_subexpr: XMLSERIALIZE '(' document_or_content a_expr AS SimpleTypename xml_indent_option ')'
			2185 => rule_2185(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_OBJECT '(' func_arg_list ')'
			2186 => rule_2186(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: JSON_OBJECT '(' json_name_and_value_list json_object_constructor_null_clause_opt json_key_uniqueness_constraint_opt json_returning_clause_opt ')'
			2187 => rule_2187(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_OBJECT '(' json_returning_clause_opt ')'
			2188 => rule_2188(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_ARRAY '(' json_value_expr_list json_array_constructor_null_clause_opt json_returning_clause_opt ')'
			2189 => rule_2189(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_ARRAY '(' select_no_parens json_format_clause_opt json_returning_clause_opt ')'
			2190 => rule_2190(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_ARRAY '(' json_returning_clause_opt ')'
			2191 => rule_2191(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON '(' json_value_expr json_key_uniqueness_constraint_opt ')'
			2192 => rule_2192(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_SCALAR '(' a_expr ')'
			2193 => rule_2193(ctx, v, l, loc)
			# func_expr_common_subexpr: JSON_SERIALIZE '(' json_value_expr json_returning_clause_opt ')'
			2194 => rule_2194(ctx, v, l, loc)
			# func_expr_common_subexpr: MERGE_ACTION '(' ')'
			2195 => rule_2195(ctx, v, l, loc, 25)
			# func_expr_common_subexpr: JSON_QUERY '(' json_value_expr ',' a_expr json_passing_clause_opt json_returning_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt ')'
			2196 => rule_2196(ctx, v, l, loc, 1)
			# func_expr_common_subexpr: JSON_EXISTS '(' json_value_expr ',' a_expr json_passing_clause_opt json_on_error_clause_opt ')'
			2197 => rule_2197(ctx, v, l, loc, 0)
			# func_expr_common_subexpr: JSON_VALUE '(' json_value_expr ',' a_expr json_passing_clause_opt json_returning_clause_opt json_behavior_clause_opt ')'
			2198 => rule_2198(ctx, v, l, loc, 2)
			# xml_root_version: VERSION_P a_expr
			2199 => rule_248(ctx, v, l, loc)
			# xml_root_version: VERSION_P NO VALUE_P
			2200 => rule_2200(ctx, v, l, loc, 1)
			# opt_xml_root_standalone: ',' STANDALONE_P YES_P
			2201 => rule_2201(ctx, v, l, loc, 0, 1)
			# opt_xml_root_standalone: ',' STANDALONE_P NO
			2202 => rule_2201(ctx, v, l, loc, 1, 1)
			# opt_xml_root_standalone: ',' STANDALONE_P NO VALUE_P
			2203 => rule_2201(ctx, v, l, loc, 2, 1)
			# opt_xml_root_standalone: %empty
			2204 => rule_2204(ctx, v, l, loc, 3, 1)
			# xml_attributes: XMLATTRIBUTES '(' xml_attribute_list ')'
			2205 => rule_563(ctx, v, l, loc)
			# xml_attribute_list: xml_attribute_el
			2206 => rule_224(ctx, v, l, loc)
			# xml_attribute_list: xml_attribute_list ',' xml_attribute_el
			2207 => rule_225(ctx, v, l, loc)
			# xml_attribute_el: a_expr AS ColLabel
			2208 => rule_1919(ctx, v, l, loc)
			# xml_attribute_el: a_expr
			2209 => rule_2209(ctx, v, l, loc)
			# document_or_content: DOCUMENT_P
			2210 => rule_143(ctx, v, l, loc, 0)
			# document_or_content: CONTENT_P
			2211 => rule_143(ctx, v, l, loc, 1)
			# xml_indent_option: INDENT
			2212 => rule_141(ctx, v, l, loc)
			# xml_indent_option: NO INDENT
			2213 => rule_268(ctx, v, l, loc)
			# xml_indent_option: %empty
			2214 => rule_142(ctx, v, l, loc)
			# xml_whitespace_option: PRESERVE WHITESPACE_P
			2215 => rule_141(ctx, v, l, loc)
			# xml_whitespace_option: STRIP_P WHITESPACE_P
			2216 => rule_268(ctx, v, l, loc)
			# xml_whitespace_option: %empty
			2217 => rule_142(ctx, v, l, loc)
			# xmlexists_argument: PASSING c_expr
			2218 => rule_248(ctx, v, l, loc)
			# xmlexists_argument: PASSING c_expr xml_passing_mech
			2219 => rule_248(ctx, v, l, loc)
			# xmlexists_argument: PASSING xml_passing_mech c_expr
			2220 => rule_364(ctx, v, l, loc)
			# xmlexists_argument: PASSING xml_passing_mech c_expr xml_passing_mech
			2221 => rule_364(ctx, v, l, loc)
			# within_group_clause: WITHIN GROUP_P '(' sort_clause ')'
			2224 => rule_903(ctx, v, l, loc)
			# within_group_clause: %empty
			2225 => rule_140(ctx, v, l, loc)
			# filter_clause: FILTER '(' WHERE a_expr ')'
			2226 => rule_766(ctx, v, l, loc)
			# filter_clause: %empty
			2227 => rule_136(ctx, v, l, loc)
			# window_clause: WINDOW window_definition_list
			2228 => rule_374(ctx, v, l, loc)
			# window_clause: %empty
			2229 => rule_140(ctx, v, l, loc)
			# window_definition_list: window_definition
			2230 => rule_224(ctx, v, l, loc)
			# window_definition_list: window_definition_list ',' window_definition
			2231 => rule_225(ctx, v, l, loc)
			# window_definition: ColId AS window_specification
			2232 => rule_2232(ctx, v, l, loc)
			# over_clause: OVER window_specification
			2233 => rule_248(ctx, v, l, loc)
			# over_clause: OVER ColId
			2234 => rule_2234(ctx, v, l, loc, 1058)
			# over_clause: %empty
			2235 => rule_136(ctx, v, l, loc)
			# window_specification: '(' opt_existing_window_name opt_partition_clause opt_sort_clause opt_frame_clause ')'
			2236 => rule_2236(ctx, v, l, loc)
			# opt_existing_window_name: ColId
			2237 => rule_137(ctx, v, l, loc)
			# opt_existing_window_name: %empty
			2238 => rule_138(ctx, v, l, loc)
			# opt_partition_clause: PARTITION BY expr_list
			2239 => rule_563(ctx, v, l, loc)
			# opt_partition_clause: %empty
			2240 => rule_140(ctx, v, l, loc)
			# opt_frame_clause: RANGE frame_extent opt_window_exclusion_clause
			2241 => rule_2241(ctx, v, l, loc, 1, 2)
			# opt_frame_clause: ROWS frame_extent opt_window_exclusion_clause
			2242 => rule_2241(ctx, v, l, loc, 1, 4)
			# opt_frame_clause: GROUPS frame_extent opt_window_exclusion_clause
			2243 => rule_2241(ctx, v, l, loc, 1, 8)
			# opt_frame_clause: %empty
			2244 => rule_2244(ctx, v, l, loc, 1058)
			# frame_extent: frame_bound
			2245 => rule_2245(ctx, v, l, loc, 128, 8192, 1024)
			# frame_extent: BETWEEN frame_bound AND frame_bound
			2246 => rule_2246(ctx, v, l, loc, 1, 16, 128, 64, 512, 4096, 8192, 4096, 1024)
			# frame_bound: UNBOUNDED PRECEDING
			2247 => rule_2247(ctx, v, l, loc, 32)
			# frame_bound: UNBOUNDED FOLLOWING
			2248 => rule_2247(ctx, v, l, loc, 128)
			# frame_bound: CURRENT_P ROW
			2249 => rule_2247(ctx, v, l, loc, 512)
			# frame_bound: a_expr PRECEDING
			2250 => rule_2250(ctx, v, l, loc, 2048)
			# frame_bound: a_expr FOLLOWING
			2251 => rule_2250(ctx, v, l, loc, 8192)
			# opt_window_exclusion_clause: EXCLUDE CURRENT_P ROW
			2252 => rule_143(ctx, v, l, loc, 32768)
			# opt_window_exclusion_clause: EXCLUDE GROUP_P
			2253 => rule_143(ctx, v, l, loc, 65536)
			# opt_window_exclusion_clause: EXCLUDE TIES
			2254 => rule_143(ctx, v, l, loc, 131072)
			# opt_window_exclusion_clause: EXCLUDE NO OTHERS
			2255 => rule_143(ctx, v, l, loc, 0)
			# opt_window_exclusion_clause: %empty
			2256 => rule_145(ctx, v, l, loc, 0)
			# row: ROW '(' expr_list ')'
			2257 => rule_563(ctx, v, l, loc)
			# row: ROW '(' ')'
			2258 => rule_265(ctx, v, l, loc)
			# row: '(' expr_list ',' a_expr ')'
			2259 => rule_2259(ctx, v, l, loc)
			# explicit_row: ROW '(' expr_list ')'
			2260 => rule_563(ctx, v, l, loc)
			# explicit_row: ROW '(' ')'
			2261 => rule_265(ctx, v, l, loc)
			# implicit_row: '(' expr_list ',' a_expr ')'
			2262 => rule_2259(ctx, v, l, loc)
			# sub_type: ANY
			2263 => rule_143(ctx, v, l, loc, 2)
			# sub_type: SOME
			2264 => rule_143(ctx, v, l, loc, 2)
			# sub_type: ALL
			2265 => rule_143(ctx, v, l, loc, 1)
			# all_Op: Op
			2266 => rule_137(ctx, v, l, loc)
			# all_Op: MathOp
			2267 => rule_137(ctx, v, l, loc)
			# MathOp: '+'
			2268 => rule_2268(ctx, v, l, loc)
			# MathOp: '-'
			2269 => rule_2269(ctx, v, l, loc)
			# MathOp: '*'
			2270 => rule_2270(ctx, v, l, loc)
			# MathOp: '/'
			2271 => rule_2271(ctx, v, l, loc)
			# MathOp: '%'
			2272 => rule_2272(ctx, v, l, loc)
			# MathOp: '^'
			2273 => rule_2273(ctx, v, l, loc)
			# MathOp: '<'
			2274 => rule_2274(ctx, v, l, loc)
			# MathOp: '>'
			2275 => rule_2275(ctx, v, l, loc)
			# MathOp: '='
			2276 => rule_2276(ctx, v, l, loc)
			# MathOp: LESS_EQUALS
			2277 => rule_2277(ctx, v, l, loc)
			# MathOp: GREATER_EQUALS
			2278 => rule_2278(ctx, v, l, loc)
			# MathOp: NOT_EQUALS
			2279 => rule_2279(ctx, v, l, loc)
			# qual_Op: Op
			2280 => rule_670(ctx, v, l, loc)
			# qual_Op: OPERATOR '(' any_operator ')'
			2281 => rule_563(ctx, v, l, loc)
			# qual_all_Op: all_Op
			2282 => rule_670(ctx, v, l, loc)
			# qual_all_Op: OPERATOR '(' any_operator ')'
			2283 => rule_563(ctx, v, l, loc)
			# subquery_Op: all_Op
			2284 => rule_670(ctx, v, l, loc)
			# subquery_Op: OPERATOR '(' any_operator ')'
			2285 => rule_563(ctx, v, l, loc)
			# subquery_Op: LIKE
			2286 => rule_2286(ctx, v, l, loc)
			# subquery_Op: NOT_LA LIKE
			2287 => rule_2287(ctx, v, l, loc)
			# subquery_Op: ILIKE
			2288 => rule_2288(ctx, v, l, loc)
			# subquery_Op: NOT_LA ILIKE
			2289 => rule_2289(ctx, v, l, loc)
			# expr_list: a_expr
			2290 => rule_224(ctx, v, l, loc)
			# expr_list: expr_list ',' a_expr
			2291 => rule_225(ctx, v, l, loc)
			# func_arg_list: func_arg_expr
			2292 => rule_224(ctx, v, l, loc)
			# func_arg_list: func_arg_list ',' func_arg_expr
			2293 => rule_225(ctx, v, l, loc)
			# func_arg_expr: a_expr
			2294 => rule_164(ctx, v, l, loc)
			# func_arg_expr: param_name COLON_EQUALS a_expr
			2295 => rule_2295(ctx, v, l, loc, 1)
			# func_arg_expr: param_name EQUALS_GREATER a_expr
			2296 => rule_2295(ctx, v, l, loc, 1)
			# func_arg_list_opt: func_arg_list
			2297 => rule_139(ctx, v, l, loc)
			# func_arg_list_opt: %empty
			2298 => rule_140(ctx, v, l, loc)
			# type_list: Typename
			2299 => rule_224(ctx, v, l, loc)
			# type_list: type_list ',' Typename
			2300 => rule_225(ctx, v, l, loc)
			# array_expr: '[' expr_list ']'
			2301 => rule_2301(ctx, v, l, loc)
			# array_expr: '[' array_expr_list ']'
			2302 => rule_2301(ctx, v, l, loc)
			# array_expr: '[' ']'
			2303 => rule_2303(ctx, v, l, loc)
			# array_expr_list: array_expr
			2304 => rule_224(ctx, v, l, loc)
			# array_expr_list: array_expr_list ',' array_expr
			2305 => rule_225(ctx, v, l, loc)
			# extract_list: extract_arg FROM a_expr
			2306 => rule_2306(ctx, v, l, loc)
			# extract_arg: IDENT
			2307 => rule_137(ctx, v, l, loc)
			# extract_arg: YEAR_P
			2308 => rule_2308(ctx, v, l, loc)
			# extract_arg: MONTH_P
			2309 => rule_2309(ctx, v, l, loc)
			# extract_arg: DAY_P
			2310 => rule_2310(ctx, v, l, loc)
			# extract_arg: HOUR_P
			2311 => rule_2311(ctx, v, l, loc)
			# extract_arg: MINUTE_P
			2312 => rule_2312(ctx, v, l, loc)
			# extract_arg: SECOND_P
			2313 => rule_2313(ctx, v, l, loc)
			# extract_arg: Sconst
			2314 => rule_137(ctx, v, l, loc)
			# unicode_normal_form: NFC
			2315 => rule_2315(ctx, v, l, loc)
			# unicode_normal_form: NFD
			2316 => rule_2316(ctx, v, l, loc)
			# unicode_normal_form: NFKC
			2317 => rule_2317(ctx, v, l, loc)
			# unicode_normal_form: NFKD
			2318 => rule_2318(ctx, v, l, loc)
			# overlay_list: a_expr PLACING a_expr FROM a_expr FOR a_expr
			2319 => rule_2319(ctx, v, l, loc)
			# overlay_list: a_expr PLACING a_expr FROM a_expr
			2320 => rule_2320(ctx, v, l, loc)
			# position_list: b_expr IN_P b_expr
			2321 => rule_2321(ctx, v, l, loc)
			# substr_list: a_expr FROM a_expr FOR a_expr
			2322 => rule_2320(ctx, v, l, loc)
			# substr_list: a_expr FOR a_expr FROM a_expr
			2323 => rule_2323(ctx, v, l, loc)
			# substr_list: a_expr FROM a_expr
			2324 => rule_2324(ctx, v, l, loc)
			# substr_list: a_expr FOR a_expr
			2325 => rule_2325(ctx, v, l, loc, 1, 1, 1)
			# substr_list: a_expr SIMILAR a_expr ESCAPE a_expr
			2326 => rule_2320(ctx, v, l, loc)
			# trim_list: a_expr FROM expr_list
			2327 => rule_2327(ctx, v, l, loc)
			# trim_list: FROM expr_list
			2328 => rule_374(ctx, v, l, loc)
			# trim_list: expr_list
			2329 => rule_139(ctx, v, l, loc)
			# case_expr: CASE case_arg when_clause_list case_default END_P
			2330 => rule_2330(ctx, v, l, loc, 0)
			# when_clause_list: when_clause
			2331 => rule_224(ctx, v, l, loc)
			# when_clause_list: when_clause_list when_clause
			2332 => rule_151(ctx, v, l, loc)
			# when_clause: WHEN a_expr THEN a_expr
			2333 => rule_2333(ctx, v, l, loc)
			# case_default: ELSE a_expr
			2334 => rule_248(ctx, v, l, loc)
			# case_default: %empty
			2335 => rule_136(ctx, v, l, loc)
			# case_arg: a_expr
			2336 => rule_164(ctx, v, l, loc)
			# case_arg: %empty
			2337 => rule_136(ctx, v, l, loc)
			# columnref: ColId
			2338 => rule_2338(ctx, v, l, loc)
			# columnref: ColId indirection
			2339 => rule_2339(ctx, v, l, loc)
			# indirection_el: '.' attr_name
			2340 => rule_2340(ctx, v, l, loc)
			# indirection_el: '.' '*'
			2341 => rule_448(ctx, v, l, loc)
			# indirection_el: '[' a_expr ']'
			2342 => rule_2342(ctx, v, l, loc)
			# indirection_el: '[' opt_slice_bound ':' opt_slice_bound ']'
			2343 => rule_2343(ctx, v, l, loc)
			# opt_slice_bound: a_expr
			2344 => rule_164(ctx, v, l, loc)
			# opt_slice_bound: %empty
			2345 => rule_136(ctx, v, l, loc)
			# indirection: indirection_el
			2346 => rule_224(ctx, v, l, loc)
			# indirection: indirection indirection_el
			2347 => rule_151(ctx, v, l, loc)
			# opt_indirection: %empty
			2348 => rule_140(ctx, v, l, loc)
			# opt_indirection: opt_indirection indirection_el
			2349 => rule_151(ctx, v, l, loc)
			# json_passing_clause_opt: PASSING json_arguments
			2352 => rule_374(ctx, v, l, loc)
			# json_passing_clause_opt: %empty
			2353 => rule_140(ctx, v, l, loc)
			# json_arguments: json_argument
			2354 => rule_224(ctx, v, l, loc)
			# json_arguments: json_arguments ',' json_argument
			2355 => rule_225(ctx, v, l, loc)
			# json_argument: json_value_expr AS ColLabel
			2356 => rule_2356(ctx, v, l, loc)
			# json_wrapper_behavior: WITHOUT WRAPPER
			2357 => rule_143(ctx, v, l, loc, 1)
			# json_wrapper_behavior: WITHOUT ARRAY WRAPPER
			2358 => rule_143(ctx, v, l, loc, 1)
			# json_wrapper_behavior: WITH WRAPPER
			2359 => rule_143(ctx, v, l, loc, 3)
			# json_wrapper_behavior: WITH ARRAY WRAPPER
			2360 => rule_143(ctx, v, l, loc, 3)
			# json_wrapper_behavior: WITH CONDITIONAL ARRAY WRAPPER
			2361 => rule_143(ctx, v, l, loc, 2)
			# json_wrapper_behavior: WITH UNCONDITIONAL ARRAY WRAPPER
			2362 => rule_143(ctx, v, l, loc, 3)
			# json_wrapper_behavior: WITH CONDITIONAL WRAPPER
			2363 => rule_143(ctx, v, l, loc, 2)
			# json_wrapper_behavior: WITH UNCONDITIONAL WRAPPER
			2364 => rule_143(ctx, v, l, loc, 3)
			# json_wrapper_behavior: %empty
			2365 => rule_145(ctx, v, l, loc, 0)
			# json_behavior: DEFAULT a_expr
			2366 => rule_2366(ctx, v, l, loc, 8)
			# json_behavior: json_behavior_type
			2367 => rule_2367(ctx, v, l, loc)
			# json_behavior_type: ERROR_P
			2368 => rule_143(ctx, v, l, loc, 1)
			# json_behavior_type: NULL_P
			2369 => rule_143(ctx, v, l, loc, 0)
			# json_behavior_type: TRUE_P
			2370 => rule_143(ctx, v, l, loc, 3)
			# json_behavior_type: FALSE_P
			2371 => rule_143(ctx, v, l, loc, 4)
			# json_behavior_type: UNKNOWN
			2372 => rule_143(ctx, v, l, loc, 5)
			# json_behavior_type: EMPTY_P ARRAY
			2373 => rule_143(ctx, v, l, loc, 6)
			# json_behavior_type: EMPTY_P OBJECT_P
			2374 => rule_143(ctx, v, l, loc, 7)
			# json_behavior_type: EMPTY_P
			2375 => rule_143(ctx, v, l, loc, 6)
			# json_behavior_clause_opt: json_behavior ON EMPTY_P
			2376 => rule_1858(ctx, v, l, loc)
			# json_behavior_clause_opt: json_behavior ON ERROR_P
			2377 => rule_2377(ctx, v, l, loc)
			# json_behavior_clause_opt: json_behavior ON EMPTY_P json_behavior ON ERROR_P
			2378 => rule_2378(ctx, v, l, loc)
			# json_behavior_clause_opt: %empty
			2379 => rule_561(ctx, v, l, loc)
			# json_on_error_clause_opt: json_behavior ON ERROR_P
			2380 => rule_164(ctx, v, l, loc)
			# json_on_error_clause_opt: %empty
			2381 => rule_136(ctx, v, l, loc)
			# json_value_expr: a_expr json_format_clause_opt
			2382 => rule_2382(ctx, v, l, loc)
			# json_format_clause: FORMAT_LA JSON ENCODING name
			2383 => rule_2383(ctx, v, l, loc, 1, 2, 3, 1)
			# json_format_clause: FORMAT_LA JSON
			2384 => rule_2384(ctx, v, l, loc, 1, 0)
			# json_format_clause_opt: json_format_clause
			2385 => rule_164(ctx, v, l, loc)
			# json_format_clause_opt: %empty
			2386 => rule_2386(ctx, v, l, loc, 0, 0, 1)
			# json_quotes_clause_opt: KEEP QUOTES ON SCALAR STRING_P
			2387 => rule_143(ctx, v, l, loc, 1)
			# json_quotes_clause_opt: KEEP QUOTES
			2388 => rule_143(ctx, v, l, loc, 1)
			# json_quotes_clause_opt: OMIT QUOTES ON SCALAR STRING_P
			2389 => rule_143(ctx, v, l, loc, 2)
			# json_quotes_clause_opt: OMIT QUOTES
			2390 => rule_143(ctx, v, l, loc, 2)
			# json_quotes_clause_opt: %empty
			2391 => rule_145(ctx, v, l, loc, 0)
			# json_returning_clause_opt: RETURNING Typename json_format_clause_opt
			2392 => rule_2392(ctx, v, l, loc)
			# json_returning_clause_opt: %empty
			2393 => rule_136(ctx, v, l, loc)
			# json_predicate_type_constraint: JSON
			2394 => rule_143(ctx, v, l, loc, 0)
			# json_predicate_type_constraint: JSON VALUE_P
			2395 => rule_143(ctx, v, l, loc, 0)
			# json_predicate_type_constraint: JSON ARRAY
			2396 => rule_143(ctx, v, l, loc, 2)
			# json_predicate_type_constraint: JSON OBJECT_P
			2397 => rule_143(ctx, v, l, loc, 1)
			# json_predicate_type_constraint: JSON SCALAR
			2398 => rule_143(ctx, v, l, loc, 3)
			# json_key_uniqueness_constraint_opt: WITH UNIQUE KEYS
			2399 => rule_141(ctx, v, l, loc)
			# json_key_uniqueness_constraint_opt: WITH UNIQUE
			2400 => rule_141(ctx, v, l, loc)
			# json_key_uniqueness_constraint_opt: WITHOUT UNIQUE KEYS
			2401 => rule_268(ctx, v, l, loc)
			# json_key_uniqueness_constraint_opt: WITHOUT UNIQUE
			2402 => rule_268(ctx, v, l, loc)
			# json_key_uniqueness_constraint_opt: %empty
			2403 => rule_142(ctx, v, l, loc)
			# json_name_and_value_list: json_name_and_value
			2404 => rule_224(ctx, v, l, loc)
			# json_name_and_value_list: json_name_and_value_list ',' json_name_and_value
			2405 => rule_225(ctx, v, l, loc)
			# json_name_and_value: c_expr VALUE_P json_value_expr
			2406 => rule_2406(ctx, v, l, loc)
			# json_name_and_value: a_expr ':' json_value_expr
			2407 => rule_2406(ctx, v, l, loc)
			# json_object_constructor_null_clause_opt: NULL_P ON NULL_P
			2408 => rule_268(ctx, v, l, loc)
			# json_object_constructor_null_clause_opt: ABSENT ON NULL_P
			2409 => rule_141(ctx, v, l, loc)
			# json_object_constructor_null_clause_opt: %empty
			2410 => rule_142(ctx, v, l, loc)
			# json_array_constructor_null_clause_opt: NULL_P ON NULL_P
			2411 => rule_268(ctx, v, l, loc)
			# json_array_constructor_null_clause_opt: ABSENT ON NULL_P
			2412 => rule_141(ctx, v, l, loc)
			# json_array_constructor_null_clause_opt: %empty
			2413 => rule_510(ctx, v, l, loc)
			# json_value_expr_list: json_value_expr
			2414 => rule_224(ctx, v, l, loc)
			# json_value_expr_list: json_value_expr_list ',' json_value_expr
			2415 => rule_225(ctx, v, l, loc)
			# json_aggregate_func: JSON_OBJECTAGG '(' json_name_and_value json_object_constructor_null_clause_opt json_key_uniqueness_constraint_opt json_returning_clause_opt ')'
			2416 => rule_2416(ctx, v, l, loc)
			# json_aggregate_func: JSON_ARRAYAGG '(' json_value_expr json_array_aggregate_order_by_clause_opt json_array_constructor_null_clause_opt json_returning_clause_opt ')'
			2417 => rule_2417(ctx, v, l, loc)
			# json_array_aggregate_order_by_clause_opt: ORDER BY sortby_list
			2418 => rule_563(ctx, v, l, loc)
			# json_array_aggregate_order_by_clause_opt: %empty
			2419 => rule_140(ctx, v, l, loc)
			# opt_target_list: target_list
			2420 => rule_139(ctx, v, l, loc)
			# opt_target_list: %empty
			2421 => rule_140(ctx, v, l, loc)
			# target_list: target_el
			2422 => rule_224(ctx, v, l, loc)
			# target_list: target_list ',' target_el
			2423 => rule_225(ctx, v, l, loc)
			# target_el: a_expr AS ColLabel
			2424 => rule_1919(ctx, v, l, loc)
			# target_el: a_expr BareColLabel
			2425 => rule_2425(ctx, v, l, loc)
			# target_el: a_expr
			2426 => rule_2209(ctx, v, l, loc)
			# target_el: '*'
			2427 => rule_2427(ctx, v, l, loc)
			# qualified_name_list: qualified_name
			2428 => rule_224(ctx, v, l, loc)
			# qualified_name_list: qualified_name_list ',' qualified_name
			2429 => rule_225(ctx, v, l, loc)
			# qualified_name: ColId
			2430 => rule_2430(ctx, v, l, loc)
			# qualified_name: ColId indirection
			2431 => rule_2431(ctx, v, l, loc)
			# name_list: name
			2432 => rule_670(ctx, v, l, loc)
			# name_list: name_list ',' name
			2433 => rule_841(ctx, v, l, loc)
			# name: ColId
			2434 => rule_137(ctx, v, l, loc)
			# attr_name: ColLabel
			2435 => rule_137(ctx, v, l, loc)
			# file_name: Sconst
			2436 => rule_137(ctx, v, l, loc)
			# func_name: type_function_name
			2437 => rule_670(ctx, v, l, loc)
			# func_name: ColId indirection
			2438 => rule_2438(ctx, v, l, loc)
			# AexprConst: Iconst
			2439 => rule_1792(ctx, v, l, loc)
			# AexprConst: FCONST
			2440 => rule_1793(ctx, v, l, loc)
			# AexprConst: Sconst
			2441 => rule_226(ctx, v, l, loc)
			# AexprConst: BCONST
			2442 => rule_2442(ctx, v, l, loc)
			# AexprConst: XCONST
			2443 => rule_2442(ctx, v, l, loc)
			# AexprConst: func_name Sconst
			2444 => rule_2444(ctx, v, l, loc)
			# AexprConst: func_name '(' func_arg_list opt_sort_clause ')' Sconst
			2445 => rule_2445(ctx, v, l, loc)
			# AexprConst: ConstTypename Sconst
			2446 => rule_2446(ctx, v, l, loc)
			# AexprConst: ConstInterval Sconst opt_interval
			2447 => rule_2447(ctx, v, l, loc)
			# AexprConst: ConstInterval '(' Iconst ')' Sconst
			2448 => rule_239(ctx, v, l, loc, 32767, 1)
			# AexprConst: TRUE_P
			2449 => rule_2449(ctx, v, l, loc)
			# AexprConst: FALSE_P
			2450 => rule_2450(ctx, v, l, loc)
			# AexprConst: NULL_P
			2451 => rule_1787(ctx, v, l, loc)
			# Iconst: ICONST
			2452 => rule_943(ctx, v, l, loc)
			# Sconst: SCONST
			2453 => rule_137(ctx, v, l, loc)
			# SignedIconst: Iconst
			2454 => rule_943(ctx, v, l, loc)
			# SignedIconst: '+' Iconst
			2455 => rule_1649(ctx, v, l, loc)
			# SignedIconst: '-' Iconst
			2456 => rule_2456(ctx, v, l, loc)
			# RoleId: RoleSpec
			2457 => rule_2457(ctx, v, l, loc)
			# RoleSpec: NonReservedWord
			2458 => rule_2458(ctx, v, l, loc, 0, 4, 4, 0, 0)
			# RoleSpec: CURRENT_ROLE
			2459 => rule_758(ctx, v, l, loc, 1)
			# RoleSpec: CURRENT_USER
			2460 => rule_758(ctx, v, l, loc, 2)
			# RoleSpec: SESSION_USER
			2461 => rule_758(ctx, v, l, loc, 3)
			# role_list: RoleSpec
			2462 => rule_224(ctx, v, l, loc)
			# role_list: role_list ',' RoleSpec
			2463 => rule_225(ctx, v, l, loc)
			# PLpgSQL_Expr: opt_distinct_clause opt_target_list from_clause where_clause group_clause having_clause window_clause opt_sort_clause opt_select_limit opt_for_locking_clause
			2464 => rule_2464(ctx, v, l, loc, 1)
			# PLAssignStmt: plassign_target opt_indirection plassign_equals PLpgSQL_Expr
			2465 => rule_2465(ctx, v, l, loc)
			# plassign_target: ColId
			2466 => rule_137(ctx, v, l, loc)
			# plassign_target: PARAM
			2467 => rule_2467(ctx, v, l, loc)
			# ColId: IDENT
			2470 => rule_137(ctx, v, l, loc)
			# ColId: unreserved_keyword
			2471 => rule_137(ctx, v, l, loc)
			# ColId: col_name_keyword
			2472 => rule_137(ctx, v, l, loc)
			# type_function_name: IDENT
			2473 => rule_137(ctx, v, l, loc)
			# type_function_name: unreserved_keyword
			2474 => rule_137(ctx, v, l, loc)
			# type_function_name: type_func_name_keyword
			2475 => rule_137(ctx, v, l, loc)
			# NonReservedWord: IDENT
			2476 => rule_137(ctx, v, l, loc)
			# NonReservedWord: unreserved_keyword
			2477 => rule_137(ctx, v, l, loc)
			# NonReservedWord: col_name_keyword
			2478 => rule_137(ctx, v, l, loc)
			# NonReservedWord: type_func_name_keyword
			2479 => rule_137(ctx, v, l, loc)
			# ColLabel: IDENT
			2480 => rule_137(ctx, v, l, loc)
			# ColLabel: unreserved_keyword
			2481 => rule_137(ctx, v, l, loc)
			# ColLabel: col_name_keyword
			2482 => rule_137(ctx, v, l, loc)
			# ColLabel: type_func_name_keyword
			2483 => rule_137(ctx, v, l, loc)
			# ColLabel: reserved_keyword
			2484 => rule_137(ctx, v, l, loc)
			# BareColLabel: IDENT
			2485 => rule_137(ctx, v, l, loc)
			# BareColLabel: bare_label_keyword
			2486 => rule_137(ctx, v, l, loc)
			_ => Ok(v.get(0) ?? Rt.of_node(Null))
		}
}

## parse_toplevel: stmtmulti
rule_2 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	var $result = Null
	$result = Rt.list_node(a1)
	Ok(Rt.of_node($result))
}

## parse_toplevel: MODE_TYPE_NAME Typename
rule_3 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_3 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Null
	$result = Rt.list_node(Rt.list_make1(a2))
	Ok(Rt.of_node($result))
}

## parse_toplevel: MODE_PLPGSQL_EXPR PLpgSQL_Expr
rule_4 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_4 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Null
	$result = Rt.list_node(Rt.list_make1(make_raw_stmt(a2, l2)))
	Ok(Rt.of_node($result))
}

## parse_toplevel: MODE_PLPGSQL_ASSIGN1 PLAssignStmt
rule_5 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_5 = |_ctx, v, l, _loc, literal_0| {
	var $a2 = Rt.node_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Null
	var $n = $a2
	$n = Node.PLAssignStmt({ ..Node.pl_assign_stmt_of($n), nnames: literal_0 })
	$a2 = $n
	$result = Rt.list_node(Rt.list_make1(make_raw_stmt($n, l2)))
	Ok(Rt.of_node($result))
}

## stmtmulti: stmtmulti ';' toplevel_stmt
rule_8 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_8 = |_ctx, v, l, _loc| {
	var $a1 = Rt.list_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	var $result = Rt.list_at(v, 0)
	if !(($a1).is_empty()) {
		written = update_raw_stmt_end(Rt.llast($a1), l2)
		$a1 = Rt.list_set($a1, ($a1.len() - 1), written.a0)
	}
	if !(Node.is_null(a3)) {
		$result = Rt.lappend($a1, make_raw_stmt(a3, l3))
	} else {
		$result = $a1
	}
	Ok(Rt.of_list($result))
}

## stmtmulti: toplevel_stmt
rule_9 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_9 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	if !(Node.is_null(a1)) {
		$result = Rt.list_make1(make_raw_stmt(a1, l1))
	} else {
		$result = []
	}
	Ok(Rt.of_list($result))
}

## stmt: %empty
rule_136 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_136 = |_ctx, _v, _l, _loc| {
	var $result = Null
	$result = Null
	Ok(Rt.of_node($result))
}

## opt_single_name: ColId
rule_137 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_137 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.text_at(v, 0)
	$result = a1
	Ok(Rt.of_text($result))
}

## opt_single_name: %empty
rule_138 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_138 = |_ctx, _v, _l, _loc| {
	var $result = Err(Null)
	$result = Err(Null)
	Ok(Rt.of_text($result))
}

## opt_qualified_name: any_name
rule_139 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_139 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = a1
	Ok(Rt.of_list($result))
}

## opt_qualified_name: %empty
rule_140 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_140 = |_ctx, _v, _l, _loc| {
	var $result = []
	$result = []
	Ok(Rt.of_list($result))
}

## opt_concurrently: CONCURRENTLY
rule_141 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_141 = |_ctx, v, _l, _loc| {
	var $result = Rt.bool_at(v, 0)
	$result = Bool.True
	Ok(Rt.of_bool($result))
}

## opt_concurrently: %empty
rule_142 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_142 = |_ctx, _v, _l, _loc| {
	var $result = Bool.False
	$result = Bool.False
	Ok(Rt.of_bool($result))
}

## opt_drop_behavior: CASCADE
rule_143 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_143 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.int_at(v, 0)
	$result = literal_0
	Ok(Rt.of_int($result))
}

## opt_drop_behavior: %empty
rule_145 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_145 = |_ctx, _v, _l, _loc, literal_0| {
	var $result = 0.I64
	$result = literal_0
	Ok(Rt.of_int($result))
}

## CallStmt: CALL func_application
rule_146 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_146 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CallStmt(Node.call_stmt_default)
	$n = Node.CallStmt({ ..Node.call_stmt_of($n), funccall: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateRoleStmt: CREATE ROLE RoleId opt_with OptRoleList
rule_147 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_147 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateRoleStmt({ ..Node.create_role_stmt_default, stmt_type: literal_0, role: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## OptRoleList: OptRoleList CreateOptRoleElem
rule_151 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_151 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, a2)
	Ok(Rt.of_list($result))
}

## AlterOptRoleElem: PASSWORD Sconst
rule_155 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_155 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("password"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: PASSWORD NULL_P
rule_156 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_156 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("password"), Null, l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: ENCRYPTED PASSWORD Sconst
rule_157 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_157 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("password"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: UNENCRYPTED PASSWORD Sconst
rule_158 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_158 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "0A000", Ok("UNENCRYPTED PASSWORD is no longer supported"), l1))
}

## AlterOptRoleElem: INHERIT
rule_159 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_159 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("inherit"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: CONNECTION LIMIT SignedIconst
rule_160 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_160 = |_ctx, v, l, _loc| {
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("connectionlimit"), make_integer(a3), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: VALID UNTIL Sconst
rule_161 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_161 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("validUntil"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: USER role_list
rule_162 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_162 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("rolemembers"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## AlterOptRoleElem: IDENT
rule_163 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_163 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5, literal_6, literal_7, literal_8, literal_9, literal_10, literal_11, literal_12| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if (Rt.strcmp(a1, Ok("superuser")) == literal_0) {
		$result = make_def_elem(Ok("superuser"), make_boolean(Bool.True), l1)
	} else {
		if (Rt.strcmp(a1, Ok("nosuperuser")) == literal_1) {
			$result = make_def_elem(Ok("superuser"), make_boolean(Bool.False), l1)
		} else {
			if (Rt.strcmp(a1, Ok("createrole")) == literal_2) {
				$result = make_def_elem(Ok("createrole"), make_boolean(Bool.True), l1)
			} else {
				if (Rt.strcmp(a1, Ok("nocreaterole")) == literal_3) {
					$result = make_def_elem(Ok("createrole"), make_boolean(Bool.False), l1)
				} else {
					if (Rt.strcmp(a1, Ok("replication")) == literal_4) {
						$result = make_def_elem(Ok("isreplication"), make_boolean(Bool.True), l1)
					} else {
						if (Rt.strcmp(a1, Ok("noreplication")) == literal_5) {
							$result = make_def_elem(Ok("isreplication"), make_boolean(Bool.False), l1)
						} else {
							if (Rt.strcmp(a1, Ok("createdb")) == literal_6) {
								$result = make_def_elem(Ok("createdb"), make_boolean(Bool.True), l1)
							} else {
								if (Rt.strcmp(a1, Ok("nocreatedb")) == literal_7) {
									$result = make_def_elem(Ok("createdb"), make_boolean(Bool.False), l1)
								} else {
									if (Rt.strcmp(a1, Ok("login")) == literal_8) {
										$result = make_def_elem(Ok("canlogin"), make_boolean(Bool.True), l1)
									} else {
										if (Rt.strcmp(a1, Ok("nologin")) == literal_9) {
											$result = make_def_elem(Ok("canlogin"), make_boolean(Bool.False), l1)
										} else {
											if (Rt.strcmp(a1, Ok("bypassrls")) == literal_10) {
												$result = make_def_elem(Ok("bypassrls"), make_boolean(Bool.True), l1)
											} else {
												if (Rt.strcmp(a1, Ok("nobypassrls")) == literal_11) {
													$result = make_def_elem(Ok("bypassrls"), make_boolean(Bool.False), l1)
												} else {
													if (Rt.strcmp(a1, Ok("noinherit")) == literal_12) {
														$result = make_def_elem(Ok("inherit"), make_boolean(Bool.False), l1)
													} else {
														return Err(Rt.error(ctx, "42601", Ok("unrecognized role option \"${Rt.text_str(a1)}\""), l1))
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}
	Ok(Rt.of_node($result))
}

## CreateOptRoleElem: AlterOptRoleElem
rule_164 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_164 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = a1
	Ok(Rt.of_node($result))
}

## CreateOptRoleElem: SYSID Iconst
rule_165 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_165 = |_ctx, v, l, _loc| {
	a2 = Rt.int_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("sysid"), make_integer(a2), l1)
	Ok(Rt.of_node($result))
}

## CreateOptRoleElem: ADMIN role_list
rule_166 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_166 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("adminmembers"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## CreateOptRoleElem: IN_P ROLE role_list
rule_168 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_168 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("addroleto"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## AlterRoleStmt: ALTER ROLE RoleSpec opt_with AlterOptRoleList
rule_171 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_171 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterRoleStmt({ ..Node.alter_role_stmt_default, role: a3 })
	$n = Node.AlterRoleStmt({ ..Node.alter_role_stmt_of($n), action: literal_0 })
	$n = Node.AlterRoleStmt({ ..Node.alter_role_stmt_of($n), options: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_in_database: IN_P DATABASE name
rule_174 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_174 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.text_at(v, 0)
	$result = a3
	Ok(Rt.of_text($result))
}

## AlterRoleSetStmt: ALTER ROLE RoleSpec opt_in_database SetResetClause
rule_175 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_175 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterRoleSetStmt({ ..Node.alter_role_set_stmt_default, role: a3, database: a4, setstmt: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterRoleSetStmt: ALTER ROLE ALL opt_in_database SetResetClause
rule_176 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_176 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterRoleSetStmt({ ..Node.alter_role_set_stmt_default, role: Null, database: a4, setstmt: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropRoleStmt: DROP ROLE role_list
rule_179 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_179 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.DropRoleStmt({ ..Node.drop_role_stmt_default, missing_ok: Bool.False, roles: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropRoleStmt: DROP ROLE IF_P EXISTS role_list
rule_180 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_180 = |_ctx, v, _l, _loc| {
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropRoleStmt({ ..Node.drop_role_stmt_default, missing_ok: Bool.True, roles: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropRoleStmt: DROP USER IF_P EXISTS role_list
rule_182 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_182 = |_ctx, v, _l, _loc| {
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropRoleStmt({ ..Node.drop_role_stmt_default, roles: a5, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterGroupStmt: ALTER GROUP_P RoleSpec add_drop USER role_list
rule_186 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_186 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a6 = Rt.list_at(v, 5)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterRoleStmt({ ..Node.alter_role_stmt_default, role: a3, action: a4 })
	$n = Node.AlterRoleStmt({ ..Node.alter_role_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("rolemembers"), Rt.list_node(a6), l6)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## add_drop: DROP
rule_188 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_188 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.int_at(v, 0)
	$result = (0 - literal_0)
	Ok(Rt.of_int($result))
}

## CreateSchemaStmt: CREATE SCHEMA opt_single_name AUTHORIZATION RoleSpec OptSchemaEltList
rule_189 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_189 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_default, schemaname: a3, authrole: a5, schema_elts: a6, if_not_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateSchemaStmt: CREATE SCHEMA ColId OptSchemaEltList
rule_190 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_190 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_default, schemaname: a3, authrole: Null, schema_elts: a4, if_not_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateSchemaStmt: CREATE SCHEMA IF_P NOT EXISTS opt_single_name AUTHORIZATION RoleSpec OptSchemaEltList
rule_191 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_191 = |ctx, v, l, _loc| {
	a6 = Rt.text_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	l9 = Rt.location(l, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_default, schemaname: a6, authrole: a8 })
	if !((a9).is_empty()) {
		return Err(Rt.error(ctx, "0A000", Ok("CREATE SCHEMA IF NOT EXISTS cannot include schema elements"), l9))
	}
	$n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_of($n), schema_elts: a9, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateSchemaStmt: CREATE SCHEMA IF_P NOT EXISTS ColId OptSchemaEltList
rule_192 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_192 = |ctx, v, l, _loc| {
	a6 = Rt.text_at(v, 5)
	a7 = Rt.list_at(v, 6)
	l7 = Rt.location(l, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_default, schemaname: a6, authrole: Null })
	if !((a7).is_empty()) {
		return Err(Rt.error(ctx, "0A000", Ok("CREATE SCHEMA IF NOT EXISTS cannot include schema elements"), l7))
	}
	$n = Node.CreateSchemaStmt({ ..Node.create_schema_stmt_of($n), schema_elts: a7, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## VariableSetStmt: SET set_rest
rule_201 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_201 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), is_local: Bool.False })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## VariableSetStmt: SET LOCAL set_rest
rule_202 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_202 = |_ctx, v, _l, _loc| {
	var $a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a3
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), is_local: Bool.True })
	$a3 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## VariableSetStmt: SET SESSION set_rest
rule_203 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_203 = |_ctx, v, _l, _loc| {
	var $a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a3
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), is_local: Bool.False })
	$a3 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest: TRANSACTION transaction_mode_list
rule_204 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_204 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("TRANSACTION"), args: a2, jumble_args: Bool.True })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest: SESSION CHARACTERISTICS AS TRANSACTION transaction_mode_list
rule_205 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_205 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("SESSION CHARACTERISTICS"), args: a5, jumble_args: Bool.True })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## generic_set: var_name TO var_list
rule_207 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_207 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.list_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: a1, args: a3, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## generic_set: var_name TO DEFAULT
rule_209 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_209 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: a1 })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: TIME ZONE zone_value
rule_213 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_213 = |_ctx, v, _l, _loc, literal_0, literal_1, literal_2| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("timezone") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), jumble_args: Bool.True })
	if !(Node.is_null(a3)) {
		$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(a3) })
	} else {
		$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), kind: literal_2 })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: CATALOG_P Sconst
rule_214 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_214 = |ctx, _v, l, _loc| {
	l2 = Rt.location(l, 1)
	Err(Rt.error(ctx, "0A000", Ok("current database cannot be changed"), l2))
}

## set_rest_more: SCHEMA Sconst
rule_215 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_215 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("search_path") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const(a2, l2)) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: l2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: NAMES opt_encoding
rule_216 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_216 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("client_encoding"), location: l2 })
	if !(!Rt.text_is_set(a2)) {
		$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const(a2, l2)) })
	} else {
		$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), kind: literal_1 })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: ROLE NonReservedWord_or_Sconst
rule_217 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_217 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("role") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const(a2, l2)) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: l2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: SESSION AUTHORIZATION NonReservedWord_or_Sconst
rule_218 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_218 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("session_authorization") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const(a3, l3)) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: l3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: SESSION AUTHORIZATION DEFAULT
rule_219 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_219 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("session_authorization") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: XML_P OPTION document_or_content
rule_220 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_220 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a3 = Rt.int_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("xmloption") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const((if (a3 == literal_1) Ok("DOCUMENT") else Ok("CONTENT")), l3)) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), jumble_args: Bool.True })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## set_rest_more: TRANSACTION SNAPSHOT Sconst
rule_221 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_221 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("TRANSACTION SNAPSHOT") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), args: Rt.list_make1(make_string_const(a3, l3)) })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: l3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## var_name: var_name '.' ColId
rule_223 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_223 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.text_at(v, 0)
	$result = Ok("${Rt.text_str(a1)}.${Rt.text_str(a3)}")
	Ok(Rt.of_text($result))
}

## var_list: var_value
rule_224 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_224 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(a1)
	Ok(Rt.of_list($result))
}

## var_list: var_list ',' var_value
rule_225 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_225 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, a3)
	Ok(Rt.of_list($result))
}

## var_value: opt_boolean_or_string
rule_226 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_226 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_string_const(a1, l1)
	Ok(Rt.of_node($result))
}

## var_value: NumericOnly
rule_227 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_227 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_a_const(a1, l1)
	Ok(Rt.of_node($result))
}

## iso_level: READ UNCOMMITTED
rule_228 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_228 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("read uncommitted")
	Ok(Rt.of_text($result))
}

## iso_level: READ COMMITTED
rule_229 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_229 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("read committed")
	Ok(Rt.of_text($result))
}

## iso_level: REPEATABLE READ
rule_230 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_230 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("repeatable read")
	Ok(Rt.of_text($result))
}

## iso_level: SERIALIZABLE
rule_231 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_231 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("serializable")
	Ok(Rt.of_text($result))
}

## opt_boolean_or_string: TRUE_P
rule_232 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_232 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("true")
	Ok(Rt.of_text($result))
}

## opt_boolean_or_string: FALSE_P
rule_233 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_233 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("false")
	Ok(Rt.of_text($result))
}

## opt_boolean_or_string: ON
rule_234 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_234 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("on")
	Ok(Rt.of_text($result))
}

## zone_value: ConstInterval Sconst opt_interval
rule_238 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_238 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $t = $a1
	if !((a3).is_empty()) {
		n = Rt.linitial(a3)
		if !((Rt.bit_and(Node.integer_of(Node.a_const_of(n).val).ival, Rt.bit_not(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)))) == literal_2)) {
			return Err(Rt.error(ctx, "42601", Ok("time zone interval must be HOUR or HOUR TO MINUTE"), l3))
		}
	}
	$t = Node.TypeName({ ..Node.type_name_of($t), typmods: a3 })
	$a1 = $t
	$result = make_string_const_cast(a2, l2, $t)
	Ok(Rt.of_node($result))
}

## zone_value: ConstInterval '(' Iconst ')' Sconst
rule_239 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_239 = |_ctx, v, l, _loc, literal_0, literal_1| {
	var $a1 = Rt.node_at(v, 0)
	a3 = Rt.int_at(v, 2)
	a5 = Rt.text_at(v, 4)
	l3 = Rt.location(l, 2)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $t = $a1
	$t = Node.TypeName({ ..Node.type_name_of($t), typmods: Rt.list_make2(make_int_const(literal_0, (0 - literal_1)), make_int_const(a3, l3)) })
	$a1 = $t
	$result = make_string_const_cast(a5, l5, $t)
	Ok(Rt.of_node($result))
}

## zone_value: DEFAULT
rule_241 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_241 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = Null
	Ok(Rt.of_node($result))
}

## opt_encoding: DEFAULT
rule_244 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_244 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Err(Null)
	Ok(Rt.of_text($result))
}

## VariableResetStmt: RESET reset_rest
rule_248 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_248 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	Ok(Rt.of_node($result))
}

## reset_rest: TIME ZONE
rule_250 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_250 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("timezone") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## reset_rest: TRANSACTION ISOLATION LEVEL
rule_251 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_251 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0, name: Ok("transaction_isolation") })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## generic_reset: ALL
rule_254 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_254 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.VariableSetStmt({ ..Node.variable_set_stmt_default, kind: literal_0 })
	$n = Node.VariableSetStmt({ ..Node.variable_set_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## VariableShowStmt: SHOW var_name
rule_259 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_259 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.VariableShowStmt({ ..Node.variable_show_stmt_default, name: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## VariableShowStmt: SHOW TIME ZONE
rule_260 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_260 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.VariableShowStmt({ ..Node.variable_show_stmt_default, name: Ok("timezone") })
	$result = n
	Ok(Rt.of_node($result))
}

## VariableShowStmt: SHOW TRANSACTION ISOLATION LEVEL
rule_261 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_261 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.VariableShowStmt({ ..Node.variable_show_stmt_default, name: Ok("transaction_isolation") })
	$result = n
	Ok(Rt.of_node($result))
}

## VariableShowStmt: SHOW SESSION AUTHORIZATION
rule_262 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_262 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.VariableShowStmt({ ..Node.variable_show_stmt_default, name: Ok("session_authorization") })
	$result = n
	Ok(Rt.of_node($result))
}

## VariableShowStmt: SHOW ALL
rule_263 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_263 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.VariableShowStmt({ ..Node.variable_show_stmt_default, name: Ok("all") })
	$result = n
	Ok(Rt.of_node($result))
}

## ConstraintsSetStmt: SET CONSTRAINTS constraints_set_list constraints_set_mode
rule_264 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_264 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.ConstraintsSetStmt({ ..Node.constraints_set_stmt_default, constraints: a3, deferred: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## constraints_set_list: ALL
rule_265 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_265 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = []
	Ok(Rt.of_list($result))
}

## constraints_set_mode: IMMEDIATE
rule_268 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_268 = |_ctx, v, _l, _loc| {
	var $result = Rt.bool_at(v, 0)
	$result = Bool.False
	Ok(Rt.of_bool($result))
}

## CheckPointStmt: CHECKPOINT
rule_269 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_269 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.CheckPointStmt(Node.check_point_stmt_default)
	$result = n
	Ok(Rt.of_node($result))
}

## DiscardStmt: DISCARD ALL
rule_270 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_270 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	n = Node.DiscardStmt({ ..Node.discard_stmt_default, target: literal_0 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE relation_expr alter_table_cmds
rule_275 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_275 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a3, cmds: a4, objtype: literal_0, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE IF_P EXISTS relation_expr alter_table_cmds
rule_276 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_276 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a5, cmds: a6, objtype: literal_0, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE relation_expr partition_cmd
rule_277 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_277 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a3 })
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), cmds: Rt.list_make1(a4) })
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), objtype: literal_0, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE IF_P EXISTS relation_expr partition_cmd
rule_278 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_278 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a5 })
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), cmds: Rt.list_make1(a6) })
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), objtype: literal_0, missing_ok: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait
rule_279 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_279 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.text_at(v, 5)
	a9 = Rt.text_at(v, 8)
	a10 = Rt.bool_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableMoveAllStmt({ ..Node.alter_table_move_all_stmt_default, orig_tablespacename: a6, objtype: literal_0, roles: [], new_tablespacename: a9, nowait: a10 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER TABLE ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait
rule_280 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_280 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.text_at(v, 5)
	a9 = Rt.list_at(v, 8)
	a12 = Rt.text_at(v, 11)
	a13 = Rt.bool_at(v, 12)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableMoveAllStmt({ ..Node.alter_table_move_all_stmt_default, orig_tablespacename: a6, objtype: literal_0, roles: a9, new_tablespacename: a12, nowait: a13 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER MATERIALIZED VIEW qualified_name alter_table_cmds
rule_290 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_290 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a4, cmds: a5, objtype: literal_0, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name alter_table_cmds
rule_291 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_291 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.node_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableStmt({ ..Node.alter_table_stmt_default, relation: a6, cmds: a7, objtype: literal_0, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name SET TABLESPACE name opt_nowait
rule_292 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_292 = |_ctx, v, _l, _loc, literal_0| {
	a7 = Rt.text_at(v, 6)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.bool_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableMoveAllStmt({ ..Node.alter_table_move_all_stmt_default, orig_tablespacename: a7, objtype: literal_0, roles: [], new_tablespacename: a10, nowait: a11 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTableStmt: ALTER MATERIALIZED VIEW ALL IN_P TABLESPACE name OWNED BY role_list SET TABLESPACE name opt_nowait
rule_293 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_293 = |_ctx, v, _l, _loc, literal_0| {
	a7 = Rt.text_at(v, 6)
	a10 = Rt.list_at(v, 9)
	a13 = Rt.text_at(v, 12)
	a14 = Rt.bool_at(v, 13)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableMoveAllStmt({ ..Node.alter_table_move_all_stmt_default, orig_tablespacename: a7, objtype: literal_0, roles: a10, new_tablespacename: a13, nowait: a14 })
	$result = n
	Ok(Rt.of_node($result))
}

## partition_cmd: ATTACH PARTITION qualified_name PartitionBoundSpec
rule_298 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_298 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $cmd = Node.PartitionCmd(Node.partition_cmd_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$cmd = Node.PartitionCmd({ ..Node.partition_cmd_of($cmd), name: a3, bound: a4, concurrent: Bool.False })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $cmd })
	$result = $n
	Ok(Rt.of_node($result))
}

## partition_cmd: DETACH PARTITION qualified_name opt_concurrently
rule_299 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_299 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $cmd = Node.PartitionCmd(Node.partition_cmd_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$cmd = Node.PartitionCmd({ ..Node.partition_cmd_of($cmd), name: a3, bound: Null, concurrent: a4 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $cmd })
	$result = $n
	Ok(Rt.of_node($result))
}

## partition_cmd: DETACH PARTITION qualified_name FINALIZE
rule_300 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_300 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $cmd = Node.PartitionCmd(Node.partition_cmd_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$cmd = Node.PartitionCmd({ ..Node.partition_cmd_of($cmd), name: a3, bound: Null, concurrent: Bool.False })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $cmd })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ADD_P columnDef
rule_302 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_302 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a2, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ADD_P IF_P NOT EXISTS columnDef
rule_303 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_303 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a5, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ADD_P COLUMN columnDef
rule_304 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_304 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a3, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ADD_P COLUMN IF_P NOT EXISTS columnDef
rule_305 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_305 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a6, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId alter_column_default
rule_306 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_306 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, def: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId DROP NOT NULL_P
rule_307 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_307 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId SET EXPRESSION AS '(' a_expr ')'
rule_309 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_309 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, def: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId DROP EXPRESSION IF_P EXISTS
rule_311 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_311 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId SET STATISTICS set_statistics_value
rule_312 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_312 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, def: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column Iconst SET STATISTICS set_statistics_value
rule_313 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_313 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a3 = Rt.int_at(v, 2)
	a6 = Rt.node_at(v, 5)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	if ((a3 <= literal_0) or (a3 > literal_1)) {
		return Err(Rt.error(ctx, "22023", Ok("column number must be in range from 1 to ${Rt.int_str(32767)}"), l3))
	}
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_2 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), num: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId SET reloptions
rule_314 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_314 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: Rt.list_node(a5) })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId SET column_storage
rule_316 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_316 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.text_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: make_string(a5) })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId ADD_P GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
rule_318 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_318 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.int_at(v, 5)
	a9 = Rt.list_at(v, 8)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	c = Node.Constraint({ ..Node.constraint_default, contype: literal_0, generated_when: a6, options: a9, location: l5 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_1, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: c })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId alter_identity_column_option_list
rule_319 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_319 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: Rt.list_node(a4) })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId DROP IDENTITY_P
rule_320 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_320 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: DROP opt_column IF_P EXISTS ColId opt_drop_behavior
rule_322 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_322 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.text_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a5, behavior: a6, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: DROP opt_column ColId opt_drop_behavior
rule_323 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_323 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a3, behavior: a4, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER opt_column ColId opt_set_data TYPE_P Typename opt_collate_clause alter_using
rule_324 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_324 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.node_at(v, 7)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $def = Node.ColumnDef(Node.column_def_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), type_name: a6 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), coll_clause: a7 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), raw_default: a8 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), location: l3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ADD_P TableConstraint
rule_326 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_326 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER CONSTRAINT name ConstraintAttributeSpec
rule_327 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_327 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5, literal_6, literal_7, literal_8| {
	a3_local = Rt.text_at(v, 2)
	a4_local = Rt.int_at(v, 3)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $c = Node.ATAlterConstraint(Node.at_alter_constraint_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), conname: a3_local })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	if (Rt.bit_and(a4_local, Rt.bit_or(literal_1, literal_2)) != 0) {
		$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), alter_enforceability: Bool.True })
		$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	}
	if (Rt.bit_and(a4_local, Rt.bit_or(Rt.bit_or(Rt.bit_or(literal_3, literal_4), literal_5), literal_6)) != 0) {
		$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), alter_deferrability: Bool.True })
		$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	}
	if (Rt.bit_and(a4_local, literal_7) != 0) {
		$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), alter_inheritability: Bool.True })
		$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	}
	if (Rt.bit_and(a4_local, literal_8) != 0) {
		return Err(Rt.error(ctx, "0A000", Ok("constraints cannot be altered to be NOT VALID"), l4))
	}
	written = process_cas_bits(a4_local, l4, Ok("FOREIGN KEY"), Bool.True, Bool.True, Bool.True, Bool.False, Bool.True, ctx)?
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), deferrable: written.a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), initdeferred: written.a4 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), is_enforced: written.a5 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), noinherit: written.a7 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ALTER CONSTRAINT name INHERIT
rule_328 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_328 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $c = Node.ATAlterConstraint(Node.at_alter_constraint_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), conname: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), alter_inheritability: Bool.True })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$c = Node.ATAlterConstraint({ ..Node.at_alter_constraint_of($c), noinherit: Bool.False })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $c })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: SET WITHOUT OIDS
rule_332 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_332 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: SET WITHOUT CLUSTER
rule_334 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_334 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: Err(Null) })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: ENABLE_P ALWAYS TRIGGER name
rule_338 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_338 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, name: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: INHERIT qualified_name
rule_349 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_349 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: NO INHERIT qualified_name
rule_350 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_350 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: OF any_name
rule_351 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_351 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $def = make_type_name_from_name_list(a2)
	$def = Node.TypeName({ ..Node.type_name_of($def), location: l2 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: OWNER TO RoleSpec
rule_353 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_353 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, newowner: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: SET reloptions
rule_356 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_356 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: Rt.list_node(a2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: REPLICA IDENTITY_P replica_identity
rule_358 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_358 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_table_cmd: alter_generic_options
rule_363 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_363 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: Rt.list_node(a1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_column_default: SET DEFAULT a_expr
rule_364 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_364 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = a3
	Ok(Rt.of_node($result))
}

## opt_collate_clause: COLLATE any_name
rule_366 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_366 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.CollateClause({ ..Node.collate_clause_default, arg: Null, collname: a2, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## replica_identity: NOTHING
rule_370 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_370 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	n = Node.ReplicaIdentityStmt({ ..Node.replica_identity_stmt_default, identity_type: literal_0, name: Err(Null) })
	$result = n
	Ok(Rt.of_node($result))
}

## replica_identity: USING INDEX name
rule_373 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_373 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.ReplicaIdentityStmt({ ..Node.replica_identity_stmt_default, identity_type: literal_0, name: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## reloptions: '(' reloption_list ')'
rule_374 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_374 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = a2
	Ok(Rt.of_list($result))
}

## reloption_elem: ColLabel '=' def_arg
rule_379 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_379 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, a3, l1)
	Ok(Rt.of_node($result))
}

## reloption_elem: ColLabel
rule_380 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_380 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, Null, l1)
	Ok(Rt.of_node($result))
}

## reloption_elem: ColLabel '.' ColLabel '=' def_arg
rule_381 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_381 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem_extended(a1, a3, a5, literal_0, l1)
	Ok(Rt.of_node($result))
}

## reloption_elem: ColLabel '.' ColLabel
rule_382 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_382 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem_extended(a1, a3, Null, literal_0, l1)
	Ok(Rt.of_node($result))
}

## alter_identity_column_option: RESTART
rule_385 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_385 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("restart"), Null, l1)
	Ok(Rt.of_node($result))
}

## alter_identity_column_option: RESTART opt_with NumericOnly
rule_386 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_386 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("restart"), a3, l1)
	Ok(Rt.of_node($result))
}

## alter_identity_column_option: SET SeqOptElem
rule_387 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_387 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a2 = Rt.node_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	if (((Rt.strcmp(Node.def_elem_of(a2).defname, Ok("as")) == literal_0) or (Rt.strcmp(Node.def_elem_of(a2).defname, Ok("restart")) == literal_1)) or (Rt.strcmp(Node.def_elem_of(a2).defname, Ok("owned_by")) == literal_2)) {
		return Err(Rt.error(ctx, "42601", Ok("sequence option \"${Rt.text_str(Node.def_elem_of(a2).defname)}\" not supported here"), l2))
	}
	$result = a2
	Ok(Rt.of_node($result))
}

## alter_identity_column_option: SET GENERATED generated_when
rule_388 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_388 = |_ctx, v, l, _loc| {
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("generated"), make_integer(a3), l1)
	Ok(Rt.of_node($result))
}

## set_statistics_value: SignedIconst
rule_389 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_389 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_integer(a1)
	Ok(Rt.of_node($result))
}

## PartitionBoundSpec: FOR VALUES WITH '(' hash_partbound ')'
rule_393 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_393 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5, literal_6, literal_7| {
	a5 = Rt.list_at(v, 4)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_default, strategy: literal_0 })
	$n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_of($n), remainder: (0 - literal_1) })
	$n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_of($n), modulus: Node.partition_bound_spec_of($n).remainder })
	lc_list = a5
	var $lc_index = 0
	while $lc_index < lc_list.len() {
		opt = (lc_list.get($lc_index) ?? Null)
		if (Rt.strcmp(Node.def_elem_of(opt).defname, Ok("modulus")) == literal_2) {
			if !((Node.partition_bound_spec_of($n).modulus == (0 - literal_3))) {
				return Err(Rt.error(ctx, "42710", Ok("modulus for hash partition provided more than once"), Node.def_elem_of(opt).location))
			}
			$n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_of($n), modulus: def_get_int32(opt, ctx)? })
		} else {
			if (Rt.strcmp(Node.def_elem_of(opt).defname, Ok("remainder")) == literal_4) {
				if !((Node.partition_bound_spec_of($n).remainder == (0 - literal_5))) {
					return Err(Rt.error(ctx, "42710", Ok("remainder for hash partition provided more than once"), Node.def_elem_of(opt).location))
				}
				$n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_of($n), remainder: def_get_int32(opt, ctx)? })
			} else {
				return Err(Rt.error(ctx, "42601", Ok("unrecognized hash partition bound specification \"${Rt.text_str(Node.def_elem_of(opt).defname)}\""), Node.def_elem_of(opt).location))
			}
		}
		$lc_index = $lc_index + 1
	}
	if (Node.partition_bound_spec_of($n).modulus == (0 - literal_6)) {
		return Err(Rt.error(ctx, "42601", Ok("modulus for hash partition must be specified"), l3))
	}
	if (Node.partition_bound_spec_of($n).remainder == (0 - literal_7)) {
		return Err(Rt.error(ctx, "42601", Ok("remainder for hash partition must be specified"), l3))
	}
	$n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_of($n), location: l3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## PartitionBoundSpec: FOR VALUES IN_P '(' expr_list ')'
rule_394 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_394 = |_ctx, v, l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_default, strategy: literal_0, is_default: Bool.False, listdatums: a5, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## PartitionBoundSpec: FOR VALUES FROM '(' expr_list ')' TO '(' expr_list ')'
rule_395 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_395 = |_ctx, v, l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_default, strategy: literal_0, is_default: Bool.False, lowerdatums: a5, upperdatums: a9, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## PartitionBoundSpec: DEFAULT
rule_396 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_396 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionBoundSpec({ ..Node.partition_bound_spec_default, is_default: Bool.True, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## hash_partbound_elem: NonReservedWord Iconst
rule_397 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_397 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.int_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, make_integer(a2), l1)
	Ok(Rt.of_node($result))
}

## AlterCompositeTypeStmt: ALTER TYPE_P any_name alter_type_cmds
rule_400 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_400 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableStmt(Node.alter_table_stmt_default)
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), relation: make_range_var_from_any_name(a3, l3, ctx)? })
	$n = Node.AlterTableStmt({ ..Node.alter_table_stmt_of($n), cmds: a4, objtype: literal_0 })
	$result = $n
	Ok(Rt.of_node($result))
}

## alter_type_cmd: ADD_P ATTRIBUTE TableFuncElement opt_drop_behavior
rule_403 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_403 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableCmd({ ..Node.alter_table_cmd_default, subtype: literal_0, def: a3, behavior: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_type_cmd: ALTER ATTRIBUTE ColId opt_set_data TYPE_P Typename opt_collate_clause opt_drop_behavior
rule_406 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_406 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.int_at(v, 7)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTableCmd(Node.alter_table_cmd_default)
	var $def = Node.ColumnDef(Node.column_def_default)
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), subtype: literal_0, name: a3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), behavior: a8 })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), type_name: a6 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), coll_clause: a7 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), raw_default: Null })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$def = Node.ColumnDef({ ..Node.column_def_of($def), location: l3 })
	$n = Node.AlterTableCmd({ ..Node.alter_table_cmd_of($n), def: $def })
	$result = $n
	Ok(Rt.of_node($result))
}

## ClosePortalStmt: CLOSE cursor_name
rule_407 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_407 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.ClosePortalStmt({ ..Node.close_portal_stmt_default, portalname: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## ClosePortalStmt: CLOSE ALL
rule_408 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_408 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.ClosePortalStmt({ ..Node.close_portal_stmt_default, portalname: Err(Null) })
	$result = n
	Ok(Rt.of_node($result))
}

## CopyStmt: COPY opt_binary qualified_name opt_column_list copy_from opt_program copy_file_name copy_delimiter opt_with copy_options where_clause
rule_409 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_409 = |ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.node_at(v, 7)
	a10 = Rt.list_at(v, 9)
	a11 = Rt.node_at(v, 10)
	l8 = Rt.location(l, 7)
	l11 = Rt.location(l, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CopyStmt({ ..Node.copy_stmt_default, relation: a3, query: Null, attlist: a4, is_from: a5, is_program: a6, filename: a7, where_clause: a11 })
	if (Node.copy_stmt_of($n).is_program and !Rt.text_is_set(Node.copy_stmt_of($n).filename)) {
		return Err(Rt.error(ctx, "42601", Ok("STDIN/STDOUT not allowed with PROGRAM"), l8))
	}
	if (!(Node.copy_stmt_of($n).is_from) and !(Node.is_null(Node.copy_stmt_of($n).where_clause))) {
		return Err(Rt.error(ctx, "42601", Ok("WHERE clause not allowed with COPY TO"), l11))
	}
	$n = Node.CopyStmt({ ..Node.copy_stmt_of($n), options: [] })
	if !Node.is_null(a2) {
		$n = Node.CopyStmt({ ..Node.copy_stmt_of($n), options: Rt.lappend(Node.copy_stmt_of($n).options, a2) })
	}
	if !Node.is_null(a8) {
		$n = Node.CopyStmt({ ..Node.copy_stmt_of($n), options: Rt.lappend(Node.copy_stmt_of($n).options, a8) })
	}
	if !(a10).is_empty() {
		$n = Node.CopyStmt({ ..Node.copy_stmt_of($n), options: Rt.list_concat(Node.copy_stmt_of($n).options, a10) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## CopyStmt: COPY '(' PreparableStmt ')' TO opt_program copy_file_name opt_with copy_options
rule_410 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_410 = |ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.list_at(v, 8)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.CopyStmt({ ..Node.copy_stmt_default, relation: Null, query: a3, attlist: [], is_from: Bool.False, is_program: a6, filename: a7, options: a9 })
	if (Node.copy_stmt_of(n).is_program and !Rt.text_is_set(Node.copy_stmt_of(n).filename)) {
		return Err(Rt.error(ctx, "42601", Ok("STDIN/STDOUT not allowed with PROGRAM"), l5))
	}
	$result = n
	Ok(Rt.of_node($result))
}

## copy_opt_item: BINARY
rule_422 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_422 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("format"), make_string(Ok("binary")), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FREEZE
rule_423 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_423 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("freeze"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: DELIMITER opt_as Sconst
rule_424 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_424 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("delimiter"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: NULL_P opt_as Sconst
rule_425 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_425 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("null"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: CSV
rule_426 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_426 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("format"), make_string(Ok("csv")), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: HEADER_P
rule_427 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_427 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("header"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: QUOTE opt_as Sconst
rule_428 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_428 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("quote"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: ESCAPE opt_as Sconst
rule_429 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_429 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("escape"), make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE QUOTE columnList
rule_430 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_430 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_quote"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE QUOTE '*'
rule_431 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_431 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_quote"), Node.AStar(Node.a_star_default), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE NOT NULL_P columnList
rule_432 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_432 = |_ctx, v, l, _loc| {
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_not_null"), Rt.list_node(a4), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE NOT NULL_P '*'
rule_433 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_433 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_not_null"), Node.AStar(Node.a_star_default), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE NULL_P columnList
rule_434 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_434 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_null"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: FORCE NULL_P '*'
rule_435 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_435 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force_null"), Node.AStar(Node.a_star_default), l1)
	Ok(Rt.of_node($result))
}

## copy_opt_item: ENCODING Sconst
rule_436 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_436 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("encoding"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## copy_delimiter: opt_using DELIMITERS Sconst
rule_439 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_439 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("delimiter"), make_string(a3), l2)
	Ok(Rt.of_node($result))
}

## copy_generic_opt_elem: ColLabel copy_generic_opt_arg
rule_445 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_445 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, a2, l1)
	Ok(Rt.of_node($result))
}

## copy_generic_opt_arg: opt_boolean_or_string
rule_446 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_446 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_string(a1)
	Ok(Rt.of_node($result))
}

## copy_generic_opt_arg: '*'
rule_448 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_448 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = Node.AStar(Node.a_star_default)
	Ok(Rt.of_node($result))
}

## copy_generic_opt_arg: DEFAULT
rule_449 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_449 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = make_string(Ok("default"))
	Ok(Rt.of_node($result))
}

## copy_generic_opt_arg: '(' copy_generic_opt_arg_list ')'
rule_450 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_450 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = Rt.list_node(a2)
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_455 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_455 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.int_at(v, 11)
	a13 = Rt.text_at(v, 12)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a4, table_elts: a6, inh_relations: a8, partspec: a9, of_typename: Null, constraints: [], access_method: a10, options: a11, oncommit: a12, tablespacename: a13, if_not_exists: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_456 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_456 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.node_at(v, 11)
	a13 = Rt.text_at(v, 12)
	a14 = Rt.list_at(v, 13)
	a15 = Rt.int_at(v, 14)
	a16 = Rt.text_at(v, 15)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a7, table_elts: a9, inh_relations: a11, partspec: a12, of_typename: Null, constraints: [], access_method: a13, options: a14, oncommit: a15, tablespacename: a16, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_457 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_457 = |_ctx, v, l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.text_at(v, 8)
	a10 = Rt.list_at(v, 9)
	a11 = Rt.int_at(v, 10)
	a12 = Rt.text_at(v, 11)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a4, table_elts: a7, inh_relations: [], partspec: a8 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), of_typename: make_type_name_from_name_list(a6) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), of_typename: Node.TypeName({ ..Node.type_name_of(Node.create_stmt_of($n).of_typename), location: l6 }) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), constraints: [], access_method: a9, options: a10, oncommit: a11, tablespacename: a12, if_not_exists: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name OF any_name OptTypedTableElementList OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_458 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_458 = |_ctx, v, l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.list_at(v, 9)
	a11 = Rt.node_at(v, 10)
	a12 = Rt.text_at(v, 11)
	a13 = Rt.list_at(v, 12)
	a14 = Rt.int_at(v, 13)
	a15 = Rt.text_at(v, 14)
	l9 = Rt.location(l, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a7, table_elts: a10, inh_relations: [], partspec: a11 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), of_typename: make_type_name_from_name_list(a9) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), of_typename: Node.TypeName({ ..Node.type_name_of(Node.create_stmt_of($n).of_typename), location: l9 }) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), constraints: [], access_method: a12, options: a13, oncommit: a14, tablespacename: a15, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_459 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_459 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.text_at(v, 10)
	a12 = Rt.list_at(v, 11)
	a13 = Rt.int_at(v, 12)
	a14 = Rt.text_at(v, 13)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a4, table_elts: a8 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), inh_relations: Rt.list_make1(a7) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), partbound: a9, partspec: a10, of_typename: Null, constraints: [], access_method: a11, options: a12, oncommit: a13, tablespacename: a14, if_not_exists: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateStmt: CREATE OptTemp TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec OptPartitionSpec table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_460 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_460 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.node_at(v, 11)
	a13 = Rt.node_at(v, 12)
	a14 = Rt.text_at(v, 13)
	a15 = Rt.list_at(v, 14)
	a16 = Rt.int_at(v, 15)
	a17 = Rt.text_at(v, 16)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateStmt(Node.create_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: a2 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), relation: $a7, table_elts: a11 })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), inh_relations: Rt.list_make1(a10) })
	$n = Node.CreateStmt({ ..Node.create_stmt_of($n), partbound: a12, partspec: a13, of_typename: Null, constraints: [], access_method: a14, options: a15, oncommit: a16, tablespacename: a17, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## columnDef: ColId Typename opt_column_storage opt_column_compression create_generic_options ColQualList
rule_482 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_482 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1_local = Rt.text_at(v, 0)
	a2_local = Rt.node_at(v, 1)
	a3 = Rt.text_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ColumnDef({ ..Node.column_def_default, colname: a1_local, type_name: a2_local, storage_name: a3, compression: a4, inhcount: literal_0, is_local: Bool.True, is_not_null: Bool.False, is_from_type: Bool.False, storage: literal_1, raw_default: Null, cooked_default: Null, coll_oid: literal_2, fdwoptions: a5 })
	written = split_col_qual_list(a6, Bool.True, Bool.True, ctx)?
	$n = Node.ColumnDef({ ..Node.column_def_of($n), constraints: written.a1 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), coll_clause: written.a2 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## columnOptions: ColId ColQualList
rule_483 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_483 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1_local = Rt.text_at(v, 0)
	a2_local = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ColumnDef({ ..Node.column_def_default, colname: a1_local, type_name: Null, inhcount: literal_0, is_local: Bool.True, is_not_null: Bool.False, is_from_type: Bool.False, storage: literal_1, raw_default: Null, cooked_default: Null, coll_oid: literal_2 })
	written = split_col_qual_list(a2_local, Bool.True, Bool.True, ctx)?
	$n = Node.ColumnDef({ ..Node.column_def_of($n), constraints: written.a1 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), coll_clause: written.a2 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## columnOptions: ColId WITH OPTIONS ColQualList
rule_484 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_484 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1_local = Rt.text_at(v, 0)
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ColumnDef({ ..Node.column_def_default, colname: a1_local, type_name: Null, inhcount: literal_0, is_local: Bool.True, is_not_null: Bool.False, is_from_type: Bool.False, storage: literal_1, raw_default: Null, cooked_default: Null, coll_oid: literal_2 })
	written = split_col_qual_list(a4, Bool.True, Bool.True, ctx)?
	$n = Node.ColumnDef({ ..Node.column_def_of($n), constraints: written.a1 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), coll_clause: written.a2 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## column_compression: COMPRESSION ColId
rule_485 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_485 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.text_at(v, 0)
	$result = a2
	Ok(Rt.of_text($result))
}

## column_compression: COMPRESSION DEFAULT
rule_486 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_486 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("default")
	Ok(Rt.of_text($result))
}

## ColConstraint: CONSTRAINT name ColConstraintElem
rule_495 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_495 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = $a3
	$n = Node.Constraint({ ..Node.constraint_of($n), conname: a2 })
	$a3 = $n
	$n = Node.Constraint({ ..Node.constraint_of($n), location: l1 })
	$a3 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: NOT NULL_P opt_no_inherit
rule_499 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_499 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.bool_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, is_no_inherit: a3, is_enforced: Bool.True, skip_validation: Bool.False, initially_valid: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: NULL_P
rule_500 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_500 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: UNIQUE opt_unique_null_treatment opt_definition OptConsTableSpace
rule_501 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_501 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.text_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1 })
	$n = Node.Constraint({ ..Node.constraint_of($n), nulls_not_distinct: !(a2) })
	$n = Node.Constraint({ ..Node.constraint_of($n), keys: [], options: a3, indexname: Err(Null), indexspace: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: PRIMARY KEY opt_definition OptConsTableSpace
rule_502 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_502 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.text_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, keys: [], options: a3, indexname: Err(Null), indexspace: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: CHECK '(' a_expr ')' opt_no_inherit
rule_503 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_503 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.bool_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, is_no_inherit: a5, raw_expr: a3, cooked_expr: Err(Null), is_enforced: Bool.True, skip_validation: Bool.False, initially_valid: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: DEFAULT b_expr
rule_504 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_504 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, raw_expr: a2, cooked_expr: Err(Null) })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: GENERATED generated_when AS IDENTITY_P OptParenthesizedSeqOptList
rule_505 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_505 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, generated_when: a2, options: a5, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: GENERATED generated_when AS '(' a_expr ')' opt_virtual_or_stored
rule_506 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_506 = |ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.int_at(v, 1)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.int_at(v, 6)
	l1 = Rt.location(l, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, generated_when: a2, raw_expr: a5, cooked_expr: Err(Null), generated_kind: a7, location: l1 })
	if !((a2 == literal_1)) {
		return Err(Rt.error(ctx, "42601", Ok("for a generated column, GENERATED ALWAYS must be specified"), l2))
	}
	$result = n
	Ok(Rt.of_node($result))
}

## ColConstraintElem: REFERENCES qualified_name opt_column_list key_match key_actions
rule_507 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_507 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, pktable: a2, fk_attrs: [], pk_attrs: a3, fk_matchtype: a4 })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_upd_action: Node.key_action_of(Node.key_actions_of(a5).update_action).action })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_del_action: Node.key_action_of(Node.key_actions_of(a5).delete_action).action })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_del_set_cols: Node.key_action_of(Node.key_actions_of(a5).delete_action).cols })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_enforced: Bool.True, skip_validation: Bool.False, initially_valid: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_unique_null_treatment: %empty
rule_510 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_510 = |_ctx, _v, _l, _loc| {
	var $result = Bool.False
	$result = Bool.True
	Ok(Rt.of_bool($result))
}

## TableLikeClause: LIKE qualified_name TableLikeOptionList
rule_522 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_522 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.TableLikeClause({ ..Node.table_like_clause_default, relation: a2, options: a3, relation_oid: literal_0 })
	$result = n
	Ok(Rt.of_node($result))
}

## TableLikeOptionList: TableLikeOptionList INCLUDING TableLikeOption
rule_523 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_523 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.int_at(v, 0)
	$result = Rt.bit_or(a1, a3)
	Ok(Rt.of_int($result))
}

## TableLikeOptionList: TableLikeOptionList EXCLUDING TableLikeOption
rule_524 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_524 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.int_at(v, 0)
	$result = Rt.bit_and(a1, Rt.bit_not(a3))
	Ok(Rt.of_int($result))
}

## ConstraintElem: CHECK '(' a_expr ')' ConstraintAttributeSpec
rule_538 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_538 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5_local = Rt.int_at(v, 4)
	l1 = Rt.location(l, 0)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, raw_expr: a3, cooked_expr: Err(Null) })
	written = process_cas_bits(a5_local, l5, Ok("CHECK"), Bool.False, Bool.False, Bool.True, Bool.True, Bool.True, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), is_enforced: written.a5 })
	$n = Node.Constraint({ ..Node.constraint_of($n), skip_validation: written.a6 })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_no_inherit: written.a7 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initially_valid: !(Node.constraint_of($n).skip_validation) })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: NOT NULL_P ColId ConstraintAttributeSpec
rule_539 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_539 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	l1 = Rt.location(l, 0)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1 })
	$n = Node.Constraint({ ..Node.constraint_of($n), keys: Rt.list_make1(make_string(a3)) })
	written = process_cas_bits(a4, l4, Ok("NOT NULL"), Bool.False, Bool.False, Bool.False, Bool.True, Bool.True, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), skip_validation: written.a6 })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_no_inherit: written.a7 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initially_valid: !(Node.constraint_of($n).skip_validation) })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: UNIQUE opt_unique_null_treatment '(' columnList opt_without_overlaps ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec
rule_540 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_540 = |ctx, v, l, _loc, literal_0| {
	a2 = Rt.bool_at(v, 1)
	a4_local = Rt.list_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.text_at(v, 8)
	a10 = Rt.int_at(v, 9)
	l1 = Rt.location(l, 0)
	l10 = Rt.location(l, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1 })
	$n = Node.Constraint({ ..Node.constraint_of($n), nulls_not_distinct: !(a2) })
	$n = Node.Constraint({ ..Node.constraint_of($n), keys: a4_local, without_overlaps: a5, including: a7, options: a8, indexname: Err(Null), indexspace: a9 })
	written = process_cas_bits(a10, l10, Ok("UNIQUE"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: UNIQUE ExistingIndex ConstraintAttributeSpec
rule_541 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_541 = |ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	a3_local = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, keys: [], including: [], options: [], indexname: a2, indexspace: Err(Null) })
	written = process_cas_bits(a3_local, l3, Ok("UNIQUE"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: PRIMARY KEY '(' columnList opt_without_overlaps ')' opt_c_include opt_definition OptConsTableSpace ConstraintAttributeSpec
rule_542 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_542 = |ctx, v, l, _loc, literal_0| {
	a4_local = Rt.list_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.text_at(v, 8)
	a10 = Rt.int_at(v, 9)
	l1 = Rt.location(l, 0)
	l10 = Rt.location(l, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, keys: a4_local, without_overlaps: a5, including: a7, options: a8, indexname: Err(Null), indexspace: a9 })
	written = process_cas_bits(a10, l10, Ok("PRIMARY KEY"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: PRIMARY KEY ExistingIndex ConstraintAttributeSpec
rule_543 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_543 = |ctx, v, l, _loc, literal_0| {
	a3_local = Rt.text_at(v, 2)
	a4_local = Rt.int_at(v, 3)
	l1 = Rt.location(l, 0)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, keys: [], including: [], options: [], indexname: a3_local, indexspace: Err(Null) })
	written = process_cas_bits(a4_local, l4, Ok("PRIMARY KEY"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: EXCLUDE access_method_clause '(' ExclusionConstraintList ')' opt_c_include opt_definition OptConsTableSpace OptWhereClause ConstraintAttributeSpec
rule_544 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_544 = |ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	a4_local = Rt.list_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.text_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.int_at(v, 9)
	l1 = Rt.location(l, 0)
	l10 = Rt.location(l, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, access_method: a2, exclusions: a4_local, including: a6, options: a7, indexname: Err(Null), indexspace: a8, where_clause: a9 })
	written = process_cas_bits(a10, l10, Ok("EXCLUDE"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ConstraintElem: FOREIGN KEY '(' columnList optionalPeriodName ')' REFERENCES qualified_name opt_column_and_period_list key_match key_actions ConstraintAttributeSpec
rule_545 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_545 = |ctx, v, l, _loc, literal_0| {
	a4_local = Rt.list_at(v, 3)
	a5_local = Rt.node_at(v, 4)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.int_at(v, 9)
	a11 = Rt.node_at(v, 10)
	a12 = Rt.int_at(v, 11)
	l1 = Rt.location(l, 0)
	l12 = Rt.location(l, 11)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, pktable: a8, fk_attrs: a4_local })
	if !Node.is_null(a5_local) {
		$n = Node.Constraint({ ..Node.constraint_of($n), fk_attrs: Rt.lappend(Node.constraint_of($n).fk_attrs, a5_local) })
		$n = Node.Constraint({ ..Node.constraint_of($n), fk_with_period: Bool.True })
	}
	$n = Node.Constraint({ ..Node.constraint_of($n), pk_attrs: Rt.node_list(Rt.linitial(a9)) })
	if !Node.is_null(Rt.lsecond(a9)) {
		$n = Node.Constraint({ ..Node.constraint_of($n), pk_attrs: Rt.lappend(Node.constraint_of($n).pk_attrs, Rt.lsecond(a9)) })
		$n = Node.Constraint({ ..Node.constraint_of($n), pk_with_period: Bool.True })
	}
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_matchtype: a10 })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_upd_action: Node.key_action_of(Node.key_actions_of(a11).update_action).action })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_del_action: Node.key_action_of(Node.key_actions_of(a11).delete_action).action })
	$n = Node.Constraint({ ..Node.constraint_of($n), fk_del_set_cols: Node.key_action_of(Node.key_actions_of(a11).delete_action).cols })
	written = process_cas_bits(a12, l12, Ok("FOREIGN KEY"), Bool.True, Bool.True, Bool.True, Bool.True, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), deferrable: written.a3 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initdeferred: written.a4 })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_enforced: written.a5 })
	$n = Node.Constraint({ ..Node.constraint_of($n), skip_validation: written.a6 })
	$n = Node.Constraint({ ..Node.constraint_of($n), initially_valid: !(Node.constraint_of($n).skip_validation) })
	$result = $n
	Ok(Rt.of_node($result))
}

## DomainConstraintElem: CHECK '(' a_expr ')' ConstraintAttributeSpec
rule_548 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_548 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.int_at(v, 4)
	l1 = Rt.location(l, 0)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1, raw_expr: a3, cooked_expr: Err(Null) })
	written = process_cas_bits(a5, l5, Ok("CHECK"), Bool.False, Bool.False, Bool.False, Bool.True, Bool.True, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), skip_validation: written.a6 })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_no_inherit: written.a7 })
	$n = Node.Constraint({ ..Node.constraint_of($n), is_enforced: Bool.True })
	$n = Node.Constraint({ ..Node.constraint_of($n), initially_valid: !(Node.constraint_of($n).skip_validation) })
	$result = $n
	Ok(Rt.of_node($result))
}

## DomainConstraintElem: NOT NULL_P ConstraintAttributeSpec
rule_549 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_549 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.Constraint({ ..Node.constraint_default, contype: literal_0, location: l1 })
	$n = Node.Constraint({ ..Node.constraint_of($n), keys: Rt.list_make1(make_string(Ok("value"))) })
	_ = process_cas_bits(a3, l3, Ok("NOT NULL"), Bool.False, Bool.False, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.Constraint({ ..Node.constraint_of($n), initially_valid: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_column_and_period_list: '(' columnList optionalPeriodName ')'
rule_560 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_560 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Rt.list_node(a2), a3)
	Ok(Rt.of_list($result))
}

## opt_column_and_period_list: %empty
rule_561 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_561 = |_ctx, _v, _l, _loc| {
	var $result = []
	$result = Rt.list_make2(Null, Null)
	Ok(Rt.of_list($result))
}

## opt_c_include: INCLUDE '(' columnList ')'
rule_563 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_563 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = a3
	Ok(Rt.of_list($result))
}

## key_match: MATCH PARTIAL
rule_566 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_566 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "0A000", Ok("MATCH PARTIAL not yet implemented"), l1))
}

## ExclusionConstraintList: ExclusionConstraintElem
rule_569 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_569 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(Rt.list_node(a1))
	Ok(Rt.of_list($result))
}

## ExclusionConstraintList: ExclusionConstraintList ',' ExclusionConstraintElem
rule_570 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_570 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, Rt.list_node(a3))
	Ok(Rt.of_list($result))
}

## ExclusionConstraintElem: index_elem WITH any_operator
rule_571 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_571 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, Rt.list_node(a3))
	Ok(Rt.of_list($result))
}

## ExclusionConstraintElem: index_elem WITH OPERATOR '(' any_operator ')'
rule_572 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_572 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, Rt.list_node(a5))
	Ok(Rt.of_list($result))
}

## key_actions: key_update
rule_575 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_575 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyActions(Node.key_actions_default)
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: a1 })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction(Node.key_action_default) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).delete_action), action: literal_0 }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).delete_action), cols: [] }) })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_actions: key_delete
rule_576 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_576 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyActions(Node.key_actions_default)
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction(Node.key_action_default) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).update_action), action: literal_0 }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).update_action), cols: [] }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: a1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_actions: key_update key_delete
rule_577 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_577 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyActions(Node.key_actions_default)
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: a1, delete_action: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_actions: key_delete key_update
rule_578 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_578 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyActions(Node.key_actions_default)
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: a2, delete_action: a1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_actions: %empty
rule_579 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_579 = |_ctx, _v, _l, _loc, literal_0, literal_1| {
	var $result = Null
	var $n = Node.KeyActions(Node.key_actions_default)
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction(Node.key_action_default) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).update_action), action: literal_0 }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), update_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).update_action), cols: [] }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction(Node.key_action_default) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).delete_action), action: literal_1 }) })
	$n = Node.KeyActions({ ..Node.key_actions_of($n), delete_action: Node.KeyAction({ ..Node.key_action_of(Node.key_actions_of($n).delete_action), cols: [] }) })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_update: ON UPDATE key_action
rule_580 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_580 = |ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if !(Node.key_action_of(a3).cols).is_empty() {
		return Err(Rt.error(ctx, "0A000", Ok("a column list with ${Rt.text_str((if (Node.key_action_of(a3).action == literal_0) Ok("SET NULL") else Ok("SET DEFAULT")))} is only supported for ON DELETE actions"), l1))
	}
	$result = a3
	Ok(Rt.of_node($result))
}

## key_action: NO ACTION
rule_582 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_582 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyAction(Node.key_action_default)
	$n = Node.KeyAction({ ..Node.key_action_of($n), action: literal_0, cols: [] })
	$result = $n
	Ok(Rt.of_node($result))
}

## key_action: SET NULL_P opt_column_list
rule_585 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_585 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.KeyAction(Node.key_action_default)
	$n = Node.KeyAction({ ..Node.key_action_of($n), action: literal_0, cols: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## PartitionSpec: PARTITION BY ColId '(' part_params ')'
rule_591 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_591 = |ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PartitionSpec(Node.partition_spec_default)
	$n = Node.PartitionSpec({ ..Node.partition_spec_of($n), strategy: parse_partition_strategy(a3, l3, ctx)? })
	$n = Node.PartitionSpec({ ..Node.partition_spec_of($n), part_params: a5, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## part_elem: ColId opt_collate opt_qualified_name
rule_594 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_594 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionElem({ ..Node.partition_elem_default, name: a1, expr: Null, collation: a2, opclass: a3, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## part_elem: func_expr_windowless opt_collate opt_qualified_name
rule_595 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_595 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionElem({ ..Node.partition_elem_default, name: Err(Null), expr: a1, collation: a2, opclass: a3, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## part_elem: '(' a_expr ')' opt_collate opt_qualified_name
rule_596 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_596 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.PartitionElem({ ..Node.partition_elem_default, name: Err(Null), expr: a2, collation: a4, opclass: a5, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## OptConsTableSpace: USING INDEX TABLESPACE name
rule_608 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_608 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	var $result = Rt.text_at(v, 0)
	$result = a4
	Ok(Rt.of_text($result))
}

## CreateStatsStmt: CREATE STATISTICS opt_qualified_name opt_name_list ON stats_params FROM from_list
rule_611 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_611 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateStatsStmt({ ..Node.create_stats_stmt_default, defnames: a3, stat_types: a4, exprs: a6, relations: a8, stxcomment: Err(Null), if_not_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateStatsStmt: CREATE STATISTICS IF_P NOT EXISTS any_name opt_name_list ON stats_params FROM from_list
rule_612 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_612 = |_ctx, v, _l, _loc| {
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateStatsStmt({ ..Node.create_stats_stmt_default, defnames: a6, stat_types: a7, exprs: a9, relations: a11, stxcomment: Err(Null), if_not_exists: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## stats_param: ColId
rule_615 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_615 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.StatsElem(Node.stats_elem_default)
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), name: a1 })
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), expr: Null })
	Ok(Rt.of_node($result))
}

## stats_param: func_expr_windowless
rule_616 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_616 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.StatsElem(Node.stats_elem_default)
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), name: Err(Null) })
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), expr: a1 })
	Ok(Rt.of_node($result))
}

## stats_param: '(' a_expr ')'
rule_617 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_617 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = Node.StatsElem(Node.stats_elem_default)
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), name: Err(Null) })
	$result = Node.StatsElem({ ..Node.stats_elem_of($result), expr: a2 })
	Ok(Rt.of_node($result))
}

## AlterStatsStmt: ALTER STATISTICS any_name SET STATISTICS set_statistics_value
rule_618 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_618 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterStatsStmt({ ..Node.alter_stats_stmt_default, defnames: a3, missing_ok: Bool.False, stxstattarget: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterStatsStmt: ALTER STATISTICS IF_P EXISTS any_name SET STATISTICS set_statistics_value
rule_619 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_619 = |_ctx, v, _l, _loc| {
	a5 = Rt.list_at(v, 4)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterStatsStmt({ ..Node.alter_stats_stmt_default, defnames: a5, missing_ok: Bool.True, stxstattarget: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateAsStmt: CREATE OptTemp TABLE create_as_target AS SelectStmt opt_with_data
rule_620 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_620 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.bool_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_default, query: a6, into: $a4, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.False })
	$a4 = Node.IntoClause({ ..Node.into_clause_of($a4), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a4).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a4 })
	$a4 = Node.IntoClause({ ..Node.into_clause_of($a4), skip_data: !(a7) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a4 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## CreateAsStmt: CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS SelectStmt opt_with_data
rule_621 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_621 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.bool_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_default, query: a9, into: $a7, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.True })
	$a7 = Node.IntoClause({ ..Node.into_clause_of($a7), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a7).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a7 })
	$a7 = Node.IntoClause({ ..Node.into_clause_of($a7), skip_data: !(a10) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a7 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## create_as_target: qualified_name opt_column_list table_access_method_clause OptWith OnCommitOption OptTableSpace
rule_622 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_622 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	$result = Node.IntoClause(Node.into_clause_default)
	$result = Node.IntoClause({ ..Node.into_clause_of($result), rel: a1 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), col_names: a2 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), access_method: a3 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), options: a4 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), on_commit: a5 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), table_space_name: a6 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), view_query: Null })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), skip_data: Bool.False })
	Ok(Rt.of_node($result))
}

## CreateMatViewStmt: CREATE OptNoLog MATERIALIZED VIEW create_mv_target AS SelectStmt opt_with_data
rule_626 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_626 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.bool_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_default, query: a7, into: $a5, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.False })
	$a5 = Node.IntoClause({ ..Node.into_clause_of($a5), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a5).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a5 })
	$a5 = Node.IntoClause({ ..Node.into_clause_of($a5), skip_data: !(a8) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a5 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## CreateMatViewStmt: CREATE OptNoLog MATERIALIZED VIEW IF_P NOT EXISTS create_mv_target AS SelectStmt opt_with_data
rule_627 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_627 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a8 = Rt.node_at(v, 7)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.bool_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_default, query: a10, into: $a8, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.True })
	$a8 = Node.IntoClause({ ..Node.into_clause_of($a8), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a8).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a8 })
	$a8 = Node.IntoClause({ ..Node.into_clause_of($a8), skip_data: !(a11) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a8 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## create_mv_target: qualified_name opt_column_list table_access_method_clause opt_reloptions OptTableSpace
rule_628 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_628 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.text_at(v, 4)
	var $result = Rt.node_at(v, 0)
	$result = Node.IntoClause(Node.into_clause_default)
	$result = Node.IntoClause({ ..Node.into_clause_of($result), rel: a1 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), col_names: a2 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), access_method: a3 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), options: a4 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), on_commit: literal_0 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), table_space_name: a5 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), view_query: Null })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), skip_data: Bool.False })
	Ok(Rt.of_node($result))
}

## RefreshMatViewStmt: REFRESH MATERIALIZED VIEW opt_concurrently qualified_name opt_with_data
rule_631 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_631 = |_ctx, v, _l, _loc| {
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.bool_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RefreshMatViewStmt({ ..Node.refresh_mat_view_stmt_default, concurrent: a4, relation: a5 })
	$n = Node.RefreshMatViewStmt({ ..Node.refresh_mat_view_stmt_of($n), skip_data: !(a6) })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateSeqStmt: CREATE OptTemp SEQUENCE qualified_name OptSeqOptList
rule_632 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_632 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateSeqStmt(Node.create_seq_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: a2 })
	$n = Node.CreateSeqStmt({ ..Node.create_seq_stmt_of($n), sequence: $a4, options: a5, owner_id: literal_0, if_not_exists: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateSeqStmt: CREATE OptTemp SEQUENCE IF_P NOT EXISTS qualified_name OptSeqOptList
rule_633 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_633 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateSeqStmt(Node.create_seq_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: a2 })
	$n = Node.CreateSeqStmt({ ..Node.create_seq_stmt_of($n), sequence: $a7, options: a8, owner_id: literal_0, if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterSeqStmt: ALTER SEQUENCE qualified_name SeqOptList
rule_634 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_634 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSeqStmt({ ..Node.alter_seq_stmt_default, sequence: a3, options: a4, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSeqStmt: ALTER SEQUENCE IF_P EXISTS qualified_name SeqOptList
rule_635 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_635 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSeqStmt({ ..Node.alter_seq_stmt_default, sequence: a5, options: a6, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## SeqOptElem: AS SimpleTypename
rule_642 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_642 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("as"), a2, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: CACHE NumericOnly
rule_643 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_643 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("cache"), a2, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: CYCLE
rule_644 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_644 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("cycle"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: NO CYCLE
rule_645 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_645 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("cycle"), make_boolean(Bool.False), l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: INCREMENT opt_by NumericOnly
rule_646 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_646 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("increment"), a3, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: LOGGED
rule_647 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_647 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("logged"), Null, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: MAXVALUE NumericOnly
rule_648 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_648 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("maxvalue"), a2, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: MINVALUE NumericOnly
rule_649 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_649 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("minvalue"), a2, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: NO MAXVALUE
rule_650 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_650 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("maxvalue"), Null, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: NO MINVALUE
rule_651 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_651 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("minvalue"), Null, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: OWNED BY any_name
rule_652 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_652 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("owned_by"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: SEQUENCE NAME_P any_name
rule_653 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_653 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("sequence_name"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: START opt_with NumericOnly
rule_654 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_654 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("start"), a3, l1)
	Ok(Rt.of_node($result))
}

## SeqOptElem: UNLOGGED
rule_657 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_657 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("unlogged"), Null, l1)
	Ok(Rt.of_node($result))
}

## NumericOnly: FCONST
rule_660 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_660 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_float(a1)
	Ok(Rt.of_node($result))
}

## NumericOnly: '+' FCONST
rule_661 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_661 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_float(a2)
	Ok(Rt.of_node($result))
}

## NumericOnly: '-' FCONST
rule_662 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_662 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $f = make_float(a2)
	written = do_negate_float_node($f)
	$f = written.a0
	$result = $f
	Ok(Rt.of_node($result))
}

## CreatePLangStmt: CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name
rule_666 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_666 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateExtensionStmt({ ..Node.create_extension_stmt_default, if_not_exists: a2, extname: a6, options: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## CreatePLangStmt: CREATE opt_or_replace opt_trusted opt_procedural LANGUAGE name HANDLER handler_name opt_inline_handler opt_validator
rule_667 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_667 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.bool_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.list_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.CreatePLangStmt({ ..Node.create_p_lang_stmt_default, replace: a2, plname: a6, plhandler: a8, plinline: a9, plvalidator: a10, pltrusted: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## handler_name: name
rule_670 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_670 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(a1))
	Ok(Rt.of_list($result))
}

## handler_name: name attrs
rule_671 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_671 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lcons(make_string(a1), a2)
	Ok(Rt.of_list($result))
}

## CreateTableSpaceStmt: CREATE TABLESPACE name OptTableSpaceOwner LOCATION Sconst opt_reloptions
rule_680 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_680 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateTableSpaceStmt({ ..Node.create_table_space_stmt_default, tablespacename: a3, owner: a4, location: a6, options: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropTableSpaceStmt: DROP TABLESPACE name
rule_683 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_683 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.DropTableSpaceStmt({ ..Node.drop_table_space_stmt_default, tablespacename: a3, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropTableSpaceStmt: DROP TABLESPACE IF_P EXISTS name
rule_684 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_684 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropTableSpaceStmt({ ..Node.drop_table_space_stmt_default, tablespacename: a5, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateExtensionStmt: CREATE EXTENSION name opt_with create_extension_opt_list
rule_685 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_685 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateExtensionStmt({ ..Node.create_extension_stmt_default, extname: a3, if_not_exists: Bool.False, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateExtensionStmt: CREATE EXTENSION IF_P NOT EXISTS name opt_with create_extension_opt_list
rule_686 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_686 = |_ctx, v, _l, _loc| {
	a6 = Rt.text_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateExtensionStmt({ ..Node.create_extension_stmt_default, extname: a6, if_not_exists: Bool.True, options: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## create_extension_opt_item: SCHEMA name
rule_689 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_689 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("schema"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## create_extension_opt_item: VERSION_P NonReservedWord_or_Sconst
rule_690 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_690 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("new_version"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## create_extension_opt_item: FROM NonReservedWord_or_Sconst
rule_691 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_691 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "0A000", Ok("CREATE EXTENSION ... FROM is no longer supported"), l1))
}

## create_extension_opt_item: CASCADE
rule_692 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_692 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("cascade"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## AlterExtensionStmt: ALTER EXTENSION name UPDATE alter_extension_opt_list
rule_693 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_693 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterExtensionStmt({ ..Node.alter_extension_stmt_default, extname: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop object_type_name name
rule_697 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_697 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: a5 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: make_string(a6) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop object_type_any_name any_name
rule_698 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_698 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: a5 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: Rt.list_node(a6) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop AGGREGATE aggregate_with_argtypes
rule_699 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_699 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: literal_0 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop CAST '(' Typename AS Typename ')'
rule_700 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_700 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.node_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: literal_0 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: Rt.list_node(Rt.list_make2(a7, a9)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop OPERATOR CLASS any_name USING name
rule_704 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_704 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a7 = Rt.list_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: literal_0 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: Rt.list_node(Rt.lcons(make_string(a9), a7)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterExtensionContentsStmt: ALTER EXTENSION name add_drop TRANSFORM FOR Typename LANGUAGE name
rule_708 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_708 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_default, extname: a3, action: a4, objtype: literal_0 })
	$n = Node.AlterExtensionContentsStmt({ ..Node.alter_extension_contents_stmt_of($n), object: Rt.list_node(Rt.list_make2(a7, make_string(a9))) })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateFdwStmt: CREATE FOREIGN DATA_P WRAPPER name opt_fdw_options create_generic_options
rule_710 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_710 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateFdwStmt({ ..Node.create_fdw_stmt_default, fdwname: a5, func_options: a6, options: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## fdw_option: HANDLER handler_name
rule_711 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_711 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("handler"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## fdw_option: NO HANDLER
rule_712 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_712 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("handler"), Null, l1)
	Ok(Rt.of_node($result))
}

## fdw_option: VALIDATOR handler_name
rule_713 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_713 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("validator"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## fdw_option: NO VALIDATOR
rule_714 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_714 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("validator"), Null, l1)
	Ok(Rt.of_node($result))
}

## AlterFdwStmt: ALTER FOREIGN DATA_P WRAPPER name opt_fdw_options alter_generic_options
rule_719 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_719 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterFdwStmt({ ..Node.alter_fdw_stmt_default, fdwname: a5, func_options: a6, options: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterFdwStmt: ALTER FOREIGN DATA_P WRAPPER name fdw_options
rule_720 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_720 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterFdwStmt({ ..Node.alter_fdw_stmt_default, fdwname: a5, func_options: a6, options: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## alter_generic_option_elem: SET generic_option_elem
rule_729 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_729 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.DefElem({ ..Node.def_elem_of($result), defaction: literal_0 })
	Ok(Rt.of_node($result))
}

## alter_generic_option_elem: DROP generic_option_name
rule_731 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_731 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem_extended(Err(Null), a2, Null, literal_0, l2)
	Ok(Rt.of_node($result))
}

## CreateForeignServerStmt: CREATE SERVER name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options
rule_735 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_735 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a5 = Rt.text_at(v, 4)
	a9 = Rt.text_at(v, 8)
	a10 = Rt.list_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateForeignServerStmt({ ..Node.create_foreign_server_stmt_default, servername: a3, servertype: a4, version: a5, fdwname: a9, options: a10, if_not_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateForeignServerStmt: CREATE SERVER IF_P NOT EXISTS name opt_type opt_foreign_server_version FOREIGN DATA_P WRAPPER name create_generic_options
rule_736 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_736 = |_ctx, v, _l, _loc| {
	a6 = Rt.text_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.text_at(v, 7)
	a12 = Rt.text_at(v, 11)
	a13 = Rt.list_at(v, 12)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateForeignServerStmt({ ..Node.create_foreign_server_stmt_default, servername: a6, servertype: a7, version: a8, fdwname: a12, options: a13, if_not_exists: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterForeignServerStmt: ALTER SERVER name foreign_server_version alter_generic_options
rule_743 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_743 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterForeignServerStmt({ ..Node.alter_foreign_server_stmt_default, servername: a3, version: a4, options: a5, has_version: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterForeignServerStmt: ALTER SERVER name foreign_server_version
rule_744 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_744 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterForeignServerStmt({ ..Node.alter_foreign_server_stmt_default, servername: a3, version: a4, has_version: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterForeignServerStmt: ALTER SERVER name alter_generic_options
rule_745 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_745 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterForeignServerStmt({ ..Node.alter_foreign_server_stmt_default, servername: a3, options: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateForeignTableStmt: CREATE FOREIGN TABLE qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options
rule_746 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_746 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.list_at(v, 7)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateForeignTableStmt(Node.create_foreign_table_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: literal_0 })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), relation: $a4 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), table_elts: a6 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), inh_relations: a8 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), of_typename: Null }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), constraints: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), options: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), oncommit: literal_1 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), tablespacename: Err(Null) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), if_not_exists: Bool.False }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), servername: a10, options: a11 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateForeignTableStmt: CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name '(' OptTableElementList ')' OptInherit SERVER name create_generic_options
rule_747 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_747 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a7 = Rt.node_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	a13 = Rt.text_at(v, 12)
	a14 = Rt.list_at(v, 13)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateForeignTableStmt(Node.create_foreign_table_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: literal_0 })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), relation: $a7 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), table_elts: a9 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), inh_relations: a11 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), of_typename: Null }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), constraints: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), options: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), oncommit: literal_1 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), tablespacename: Err(Null) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), if_not_exists: Bool.True }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), servername: a13, options: a14 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateForeignTableStmt: CREATE FOREIGN TABLE qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options
rule_748 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_748 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a4 = Rt.node_at(v, 3)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a11 = Rt.text_at(v, 10)
	a12 = Rt.list_at(v, 11)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateForeignTableStmt(Node.create_foreign_table_stmt_default)
	$a4 = Node.RangeVar({ ..Node.range_var_of($a4), relpersistence: literal_0 })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), relation: $a4 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), inh_relations: Rt.list_make1(a7) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), table_elts: a8 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), partbound: a9 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), of_typename: Null }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), constraints: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), options: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), oncommit: literal_1 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), tablespacename: Err(Null) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), if_not_exists: Bool.False }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), servername: a11, options: a12 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateForeignTableStmt: CREATE FOREIGN TABLE IF_P NOT EXISTS qualified_name PARTITION OF qualified_name OptTypedTableElementList PartitionBoundSpec SERVER name create_generic_options
rule_749 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_749 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a7 = Rt.node_at(v, 6)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.node_at(v, 11)
	a14 = Rt.text_at(v, 13)
	a15 = Rt.list_at(v, 14)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateForeignTableStmt(Node.create_foreign_table_stmt_default)
	$a7 = Node.RangeVar({ ..Node.range_var_of($a7), relpersistence: literal_0 })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), relation: $a7 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), inh_relations: Rt.list_make1(a10) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), table_elts: a11 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), partbound: a12 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), of_typename: Null }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), constraints: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), options: [] }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), oncommit: literal_1 }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), tablespacename: Err(Null) }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), base: Node.CreateStmt({ ..Node.create_stmt_of(Node.create_foreign_table_stmt_of($n).base), if_not_exists: Bool.True }) })
	$n = Node.CreateForeignTableStmt({ ..Node.create_foreign_table_stmt_of($n), servername: a14, options: a15 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ImportForeignSchemaStmt: IMPORT_P FOREIGN SCHEMA name import_qualification FROM SERVER name INTO name create_generic_options
rule_750 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_750 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ImportForeignSchemaStmt({ ..Node.import_foreign_schema_stmt_default, server_name: a8, remote_schema: a4, local_schema: a10 })
	$n = Node.ImportForeignSchemaStmt({ ..Node.import_foreign_schema_stmt_of($n), list_type: Node.import_qual_of(a5).type })
	$n = Node.ImportForeignSchemaStmt({ ..Node.import_foreign_schema_stmt_of($n), table_list: Node.import_qual_of(a5).table_names })
	$n = Node.ImportForeignSchemaStmt({ ..Node.import_foreign_schema_stmt_of($n), options: a11 })
	$result = $n
	Ok(Rt.of_node($result))
}

## import_qualification: import_qualification_type '(' relation_expr_list ')'
rule_753 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_753 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ImportQual(Node.import_qual_default)
	$n = Node.ImportQual({ ..Node.import_qual_of($n), type: a1, table_names: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## import_qualification: %empty
rule_754 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_754 = |_ctx, _v, _l, _loc, literal_0| {
	var $result = Null
	var $n = Node.ImportQual(Node.import_qual_default)
	$n = Node.ImportQual({ ..Node.import_qual_of($n), type: literal_0, table_names: [] })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateUserMappingStmt: CREATE USER MAPPING FOR auth_ident SERVER name create_generic_options
rule_755 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_755 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateUserMappingStmt({ ..Node.create_user_mapping_stmt_default, user: a5, servername: a7, options: a8, if_not_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateUserMappingStmt: CREATE USER MAPPING IF_P NOT EXISTS FOR auth_ident SERVER name create_generic_options
rule_756 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_756 = |_ctx, v, _l, _loc| {
	a8 = Rt.node_at(v, 7)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateUserMappingStmt({ ..Node.create_user_mapping_stmt_default, user: a8, servername: a10, options: a11, if_not_exists: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## auth_ident: USER
rule_758 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_758 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_role_spec(literal_0, l1)
	Ok(Rt.of_node($result))
}

## DropUserMappingStmt: DROP USER MAPPING FOR auth_ident SERVER name
rule_759 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_759 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.DropUserMappingStmt({ ..Node.drop_user_mapping_stmt_default, user: a5, servername: a7, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropUserMappingStmt: DROP USER MAPPING IF_P EXISTS FOR auth_ident SERVER name
rule_760 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_760 = |_ctx, v, _l, _loc| {
	a7 = Rt.node_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.DropUserMappingStmt({ ..Node.drop_user_mapping_stmt_default, user: a7, servername: a9, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterUserMappingStmt: ALTER USER MAPPING FOR auth_ident SERVER name alter_generic_options
rule_761 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_761 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterUserMappingStmt({ ..Node.alter_user_mapping_stmt_default, user: a5, servername: a7, options: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreatePolicyStmt: CREATE POLICY name ON qualified_name RowSecurityDefaultPermissive RowSecurityDefaultForCmd RowSecurityDefaultToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck
rule_762 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_762 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.node_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.CreatePolicyStmt({ ..Node.create_policy_stmt_default, policy_name: a3, table: a5, permissive: a6, cmd_name: a7, roles: a8, qual: a9, with_check: a10 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterPolicyStmt: ALTER POLICY name ON qualified_name RowSecurityOptionalToRole RowSecurityOptionalExpr RowSecurityOptionalWithCheck
rule_763 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_763 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterPolicyStmt({ ..Node.alter_policy_stmt_default, policy_name: a3, table: a5, roles: a6, qual: a7, with_check: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## RowSecurityOptionalWithCheck: WITH CHECK '(' a_expr ')'
rule_766 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_766 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = a4
	Ok(Rt.of_node($result))
}

## RowSecurityDefaultToRole: %empty
rule_769 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_769 = |_ctx, _v, _l, _loc, literal_0, literal_1| {
	var $result = []
	$result = Rt.list_make1(make_role_spec(literal_0, (0 - literal_1)))
	Ok(Rt.of_list($result))
}

## RowSecurityDefaultPermissive: AS IDENT
rule_772 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_772 = |ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.bool_at(v, 0)
	if (Rt.strcmp(a2, Ok("permissive")) == literal_0) {
		$result = Bool.True
	} else {
		if (Rt.strcmp(a2, Ok("restrictive")) == literal_1) {
			$result = Bool.False
		} else {
			return Err(Rt.error(ctx, "42601", Ok("unrecognized row security option \"${Rt.text_str(a2)}\""), l2))
		}
	}
	Ok(Rt.of_bool($result))
}

## RowSecurityDefaultForCmd: %empty
rule_775 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_775 = |_ctx, _v, _l, _loc| {
	var $result = Err(Null)
	$result = Ok("all")
	Ok(Rt.of_text($result))
}

## row_security_cmd: ALL
rule_776 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_776 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("all")
	Ok(Rt.of_text($result))
}

## row_security_cmd: SELECT
rule_777 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_777 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("select")
	Ok(Rt.of_text($result))
}

## row_security_cmd: INSERT
rule_778 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_778 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("insert")
	Ok(Rt.of_text($result))
}

## row_security_cmd: UPDATE
rule_779 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_779 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("update")
	Ok(Rt.of_text($result))
}

## row_security_cmd: DELETE_P
rule_780 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_780 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("delete")
	Ok(Rt.of_text($result))
}

## CreateAmStmt: CREATE ACCESS METHOD name TYPE_P am_type HANDLER handler_name
rule_781 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_781 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.int_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateAmStmt({ ..Node.create_am_stmt_default, amname: a4, handler_name: a8, amtype: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateTrigStmt: CREATE opt_or_replace TRIGGER name TriggerActionTime TriggerEvents ON qualified_name TriggerReferencing TriggerForSpec TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')'
rule_784 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_784 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.text_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.bool_at(v, 9)
	a11 = Rt.node_at(v, 10)
	a14 = Rt.list_at(v, 13)
	a16 = Rt.list_at(v, 15)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_default, replace: a2, isconstraint: Bool.False, trigname: a4, relation: a8, funcname: a14, args: a16, row: a10, timing: a5 })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), events: Node.integer_of(Rt.linitial(a6)).ival })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), columns: Rt.node_list(Rt.lsecond(a6)) })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), when_clause: a11, transition_rels: a9, deferrable: Bool.False, initdeferred: Bool.False, constrrel: Null })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateTrigStmt: CREATE opt_or_replace CONSTRAINT TRIGGER name AFTER TriggerEvents ON qualified_name OptConstrFromTable ConstraintAttributeSpec FOR EACH ROW TriggerWhen EXECUTE FUNCTION_or_PROCEDURE func_name '(' TriggerFuncArgs ')'
rule_785 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_785 = |ctx, v, l, _loc, literal_0| {
	a2 = Rt.bool_at(v, 1)
	a5 = Rt.text_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.int_at(v, 10)
	a15 = Rt.node_at(v, 14)
	a18 = Rt.list_at(v, 17)
	a20 = Rt.list_at(v, 19)
	l1 = Rt.location(l, 0)
	l11 = Rt.location(l, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_default, replace: a2 })
	if Node.create_trig_stmt_of($n).replace {
		return Err(Rt.error(ctx, "0A000", Ok("CREATE OR REPLACE CONSTRAINT TRIGGER is not supported"), l1))
	}
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), isconstraint: Bool.True, trigname: a5, relation: a9, funcname: a18, args: a20, row: Bool.True, timing: literal_0 })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), events: Node.integer_of(Rt.linitial(a7)).ival })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), columns: Rt.node_list(Rt.lsecond(a7)) })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), when_clause: a15, transition_rels: [] })
	written = process_cas_bits(a11, l11, Ok("TRIGGER"), Bool.True, Bool.True, Bool.False, Bool.False, Bool.False, ctx)?
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), deferrable: written.a3 })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), initdeferred: written.a4 })
	$n = Node.CreateTrigStmt({ ..Node.create_trig_stmt_of($n), constrrel: a10 })
	$result = $n
	Ok(Rt.of_node($result))
}

## TriggerEvents: TriggerEvents OR TriggerOneEvent
rule_790 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_790 = |ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	events1 = Node.integer_of(Rt.linitial(a1)).ival
	events2 = Node.integer_of(Rt.linitial(a3)).ival
	columns1 = Rt.node_list(Rt.lsecond(a1))
	columns2 = Rt.node_list(Rt.lsecond(a3))
	if (Rt.bit_and(events1, events2) != 0) {
		return Err(Rt.yyerror(ctx, Ok("duplicate trigger events specified")))
	}
	$result = Rt.list_make2(make_integer(Rt.bit_or(events1, events2)), Rt.list_node(Rt.list_concat(columns1, columns2)))
	Ok(Rt.of_list($result))
}

## TriggerOneEvent: INSERT
rule_791 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_791 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(make_integer(literal_0), Null)
	Ok(Rt.of_list($result))
}

## TriggerOneEvent: UPDATE OF columnList
rule_794 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_794 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(make_integer(literal_0), Rt.list_node(a3))
	Ok(Rt.of_list($result))
}

## TriggerTransition: TransitionOldOrNew TransitionRowOrTable opt_as TransitionRelName
rule_800 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_800 = |_ctx, v, _l, _loc| {
	a1 = Rt.bool_at(v, 0)
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.TriggerTransition({ ..Node.trigger_transition_default, name: a4, is_new: a1, is_table: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## TriggerForSpec: FOR TriggerForOptEach TriggerForType
rule_806 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_806 = |_ctx, v, _l, _loc| {
	a3 = Rt.bool_at(v, 2)
	var $result = Rt.bool_at(v, 0)
	$result = a3
	Ok(Rt.of_bool($result))
}

## TriggerFuncArg: Iconst
rule_819 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_819 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_string(Ok("${Rt.int_str(a1)}"))
	Ok(Rt.of_node($result))
}

## ConstraintAttributeSpec: ConstraintAttributeSpec ConstraintAttributeElem
rule_826 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_826 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5, literal_6, literal_7, literal_8, literal_9, literal_10, literal_11, literal_12, literal_13, literal_14, literal_15| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.int_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.int_at(v, 0)
	newspec = Rt.bit_or(a1, a2)
	if (Rt.bit_and(newspec, Rt.bit_or(literal_0, literal_1)) == Rt.bit_or(literal_2, literal_3)) {
		return Err(Rt.error(ctx, "42601", Ok("constraint declared INITIALLY DEFERRED must be DEFERRABLE"), l2))
	}
	if (((Rt.bit_and(newspec, Rt.bit_or(literal_4, literal_5)) == Rt.bit_or(literal_6, literal_7)) or (Rt.bit_and(newspec, Rt.bit_or(literal_8, literal_9)) == Rt.bit_or(literal_10, literal_11))) or (Rt.bit_and(newspec, Rt.bit_or(literal_12, literal_13)) == Rt.bit_or(literal_14, literal_15))) {
		return Err(Rt.error(ctx, "42601", Ok("conflicting constraint properties"), l2))
	}
	$result = newspec
	Ok(Rt.of_int($result))
}

## CreateEventTrigStmt: CREATE EVENT TRIGGER name ON ColLabel EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')'
rule_835 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_835 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a9 = Rt.list_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateEventTrigStmt({ ..Node.create_event_trig_stmt_default, trigname: a4, eventname: a6, whenclause: [], funcname: a9 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateEventTrigStmt: CREATE EVENT TRIGGER name ON ColLabel WHEN event_trigger_when_list EXECUTE FUNCTION_or_PROCEDURE func_name '(' ')'
rule_836 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_836 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.list_at(v, 7)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateEventTrigStmt({ ..Node.create_event_trig_stmt_default, trigname: a4, eventname: a6, whenclause: a8, funcname: a11 })
	$result = n
	Ok(Rt.of_node($result))
}

## event_trigger_when_item: ColId IN_P '(' event_trigger_value_list ')'
rule_839 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_839 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, Rt.list_node(a4), l1)
	Ok(Rt.of_node($result))
}

## event_trigger_value_list: event_trigger_value_list ',' SCONST
rule_841 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_841 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, make_string(a3))
	Ok(Rt.of_list($result))
}

## AlterEventTrigStmt: ALTER EVENT TRIGGER name enable_trigger
rule_842 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_842 = |_ctx, v, _l, _loc| {
	a4 = Rt.text_at(v, 3)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterEventTrigStmt({ ..Node.alter_event_trig_stmt_default, trigname: a4, tgenabled: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateAssertionStmt: CREATE ASSERTION any_name CHECK '(' a_expr ')' ConstraintAttributeSpec
rule_847 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_847 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "0A000", Ok("CREATE ASSERTION is not yet implemented"), l1))
}

## DefineStmt: CREATE opt_or_replace AGGREGATE func_name aggr_args definition
rule_848 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_848 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, oldstyle: Bool.False, replace: a2, defnames: a4, args: a5, definition: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE opt_or_replace AGGREGATE func_name old_aggr_definition
rule_849 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_849 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, oldstyle: Bool.True, replace: a2, defnames: a4, args: [], definition: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE OPERATOR any_operator definition
rule_850 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_850 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, oldstyle: Bool.False, defnames: a3, args: [], definition: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE TYPE_P any_name
rule_852 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_852 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, oldstyle: Bool.False, defnames: a3, args: [], definition: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE TYPE_P any_name AS '(' OptTableFuncElementList ')'
rule_853 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_853 = |ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.list_at(v, 5)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CompositeTypeStmt(Node.composite_type_stmt_default)
	$n = Node.CompositeTypeStmt({ ..Node.composite_type_stmt_of($n), typevar: make_range_var_from_any_name(a3, l3, ctx)? })
	$n = Node.CompositeTypeStmt({ ..Node.composite_type_stmt_of($n), coldeflist: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE TYPE_P any_name AS ENUM_P '(' opt_enum_val_list ')'
rule_854 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_854 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateEnumStmt({ ..Node.create_enum_stmt_default, type_name: a3, vals: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE TYPE_P any_name AS RANGE definition
rule_855 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_855 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateRangeStmt({ ..Node.create_range_stmt_default, type_name: a3, params: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE TEXT_P SEARCH PARSER any_name definition
rule_856 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_856 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, args: [], defnames: a5, definition: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE COLLATION any_name definition
rule_860 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_860 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, args: [], defnames: a3, definition: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE COLLATION IF_P NOT EXISTS any_name definition
rule_861 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_861 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, args: [], defnames: a6, definition: a7, if_not_exists: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE COLLATION any_name FROM any_name
rule_862 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_862 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.list_at(v, 4)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, args: [], defnames: a3 })
	$n = Node.DefineStmt({ ..Node.define_stmt_of($n), definition: Rt.list_make1(make_def_elem(Ok("from"), Rt.list_node(a5), l5)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## DefineStmt: CREATE COLLATION IF_P NOT EXISTS any_name FROM any_name
rule_863 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_863 = |_ctx, v, l, _loc, literal_0| {
	a6 = Rt.list_at(v, 5)
	a8 = Rt.list_at(v, 7)
	l8 = Rt.location(l, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DefineStmt({ ..Node.define_stmt_default, kind: literal_0, args: [], defnames: a6 })
	$n = Node.DefineStmt({ ..Node.define_stmt_of($n), definition: Rt.list_make1(make_def_elem(Ok("from"), Rt.list_node(a8), l8)) })
	$n = Node.DefineStmt({ ..Node.define_stmt_of($n), if_not_exists: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## def_arg: qual_all_Op
rule_871 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_871 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = Rt.list_node(a1)
	Ok(Rt.of_node($result))
}

## AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst
rule_883 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_883 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterEnumStmt({ ..Node.alter_enum_stmt_default, type_name: a3, old_val: Err(Null), new_val: a7, new_val_neighbor: Err(Null), new_val_is_after: Bool.True, skip_if_new_val_exists: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst BEFORE Sconst
rule_884 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_884 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterEnumStmt({ ..Node.alter_enum_stmt_default, type_name: a3, old_val: Err(Null), new_val: a7, new_val_neighbor: a9, new_val_is_after: Bool.False, skip_if_new_val_exists: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterEnumStmt: ALTER TYPE_P any_name ADD_P VALUE_P opt_if_not_exists Sconst AFTER Sconst
rule_885 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_885 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.bool_at(v, 5)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterEnumStmt({ ..Node.alter_enum_stmt_default, type_name: a3, old_val: Err(Null), new_val: a7, new_val_neighbor: a9, new_val_is_after: Bool.True, skip_if_new_val_exists: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterEnumStmt: ALTER TYPE_P any_name RENAME VALUE_P Sconst TO Sconst
rule_886 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_886 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterEnumStmt({ ..Node.alter_enum_stmt_default, type_name: a3, old_val: a6, new_val: a8, new_val_neighbor: Err(Null), new_val_is_after: Bool.False, skip_if_new_val_exists: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterEnumStmt: ALTER TYPE_P any_name DROP VALUE_P Sconst
rule_887 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_887 = |ctx, _v, l, _loc| {
	l4 = Rt.location(l, 3)
	Err(Rt.error(ctx, "0A000", Ok("dropping an enum value is not implemented"), l4))
}

## CreateOpClassStmt: CREATE OPERATOR CLASS any_name opt_default FOR TYPE_P Typename USING name opt_opfamily AS opclass_item_list
rule_890 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_890 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a8 = Rt.node_at(v, 7)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	a13 = Rt.list_at(v, 12)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassStmt({ ..Node.create_op_class_stmt_default, opclassname: a4, is_default: a5, datatype: a8, amname: a10, opfamilyname: a11, items: a13 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_item: OPERATOR Iconst any_operator opclass_purpose
rule_893 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_893 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateOpClassItem(Node.create_op_class_item_default)
	owa = Node.ObjectWithArgs({ ..Node.object_with_args_default, objname: a3, objargs: [] })
	$n = Node.CreateOpClassItem({ ..Node.create_op_class_item_of($n), itemtype: literal_0, name: owa, number: a2, order_family: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## opclass_item: OPERATOR Iconst operator_with_argtypes opclass_purpose
rule_894 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_894 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassItem({ ..Node.create_op_class_item_default, itemtype: literal_0, name: a3, number: a2, order_family: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_item: FUNCTION Iconst function_with_argtypes
rule_895 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_895 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassItem({ ..Node.create_op_class_item_default, itemtype: literal_0, name: a3, number: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_item: FUNCTION Iconst '(' type_list ')' function_with_argtypes
rule_896 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_896 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassItem({ ..Node.create_op_class_item_default, itemtype: literal_0, name: a6, number: a2, class_args: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_item: STORAGE Typename
rule_897 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_897 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassItem({ ..Node.create_op_class_item_default, itemtype: literal_0, storedtype: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_purpose: FOR ORDER BY any_name
rule_903 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_903 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = a4
	Ok(Rt.of_list($result))
}

## CreateOpFamilyStmt: CREATE OPERATOR FAMILY any_name USING name
rule_905 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_905 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpFamilyStmt({ ..Node.create_op_family_stmt_default, opfamilyname: a4, amname: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterOpFamilyStmt: ALTER OPERATOR FAMILY any_name USING name ADD_P opclass_item_list
rule_906 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_906 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterOpFamilyStmt({ ..Node.alter_op_family_stmt_default, opfamilyname: a4, amname: a6, is_drop: Bool.False, items: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterOpFamilyStmt: ALTER OPERATOR FAMILY any_name USING name DROP opclass_drop_list
rule_907 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_907 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterOpFamilyStmt({ ..Node.alter_op_family_stmt_default, opfamilyname: a4, amname: a6, is_drop: Bool.True, items: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## opclass_drop: OPERATOR Iconst '(' type_list ')'
rule_910 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_910 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateOpClassItem({ ..Node.create_op_class_item_default, itemtype: literal_0, number: a2, class_args: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropOpClassStmt: DROP OPERATOR CLASS any_name USING name opt_drop_behavior
rule_912 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_912 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a7 = Rt.int_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt(Node.drop_stmt_default)
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.lcons(make_string(a6), a4))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), remove_type: literal_0, behavior: a7, missing_ok: Bool.False, concurrent: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropOpClassStmt: DROP OPERATOR CLASS IF_P EXISTS any_name USING name opt_drop_behavior
rule_913 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_913 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.list_at(v, 5)
	a8 = Rt.text_at(v, 7)
	a9 = Rt.int_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt(Node.drop_stmt_default)
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.lcons(make_string(a8), a6))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), remove_type: literal_0, behavior: a9, missing_ok: Bool.True, concurrent: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropOwnedStmt: DROP OWNED BY role_list opt_drop_behavior
rule_916 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_916 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropOwnedStmt({ ..Node.drop_owned_stmt_default, roles: a4, behavior: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## ReassignOwnedStmt: REASSIGN OWNED BY role_list TO RoleSpec
rule_917 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_917 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.ReassignOwnedStmt({ ..Node.reassign_owned_stmt_default, roles: a4, newrole: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP object_type_any_name IF_P EXISTS any_name_list opt_drop_behavior
rule_918 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_918 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: a2, missing_ok: Bool.True, objects: a5, behavior: a6, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP object_type_any_name any_name_list opt_drop_behavior
rule_919 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_919 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: a2, missing_ok: Bool.False, objects: a3, behavior: a4, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP object_type_name_on_any_name name ON any_name opt_drop_behavior
rule_922 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_922 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: a2 })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.lappend(a5, make_string(a3)))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), behavior: a6, missing_ok: Bool.False, concurrent: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP object_type_name_on_any_name IF_P EXISTS name ON any_name opt_drop_behavior
rule_923 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_923 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a5 = Rt.text_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.int_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: a2 })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.lappend(a7, make_string(a5)))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), behavior: a8, missing_ok: Bool.True, concurrent: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP TYPE_P type_name_list opt_drop_behavior
rule_924 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_924 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, missing_ok: Bool.False, objects: a3, behavior: a4, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP TYPE_P IF_P EXISTS type_name_list opt_drop_behavior
rule_925 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_925 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, missing_ok: Bool.True, objects: a5, behavior: a6, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP INDEX CONCURRENTLY any_name_list opt_drop_behavior
rule_928 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_928 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, missing_ok: Bool.False, objects: a4, behavior: a5, concurrent: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## DropStmt: DROP INDEX CONCURRENTLY IF_P EXISTS any_name_list opt_drop_behavior
rule_929 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_929 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.list_at(v, 5)
	a7 = Rt.int_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, missing_ok: Bool.True, objects: a6, behavior: a7, concurrent: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## object_type_name: drop_type_name
rule_943 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_943 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	var $result = Rt.int_at(v, 0)
	$result = a1
	Ok(Rt.of_int($result))
}

## attrs: '.' attr_name
rule_963 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_963 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(a2))
	Ok(Rt.of_list($result))
}

## TruncateStmt: TRUNCATE opt_table relation_expr_list opt_restart_seqs opt_drop_behavior
rule_967 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_967 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.TruncateStmt({ ..Node.truncate_stmt_default, relations: a3, restart_seqs: a4, behavior: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON object_type_any_name any_name IS comment_text
rule_971 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_971 = |_ctx, v, _l, _loc| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: a3 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(a4) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON COLUMN any_name IS comment_text
rule_972 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_972 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(a4) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON object_type_name name IS comment_text
rule_973 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_973 = |_ctx, v, _l, _loc| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: a3 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: make_string(a4) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON TYPE_P Typename IS comment_text
rule_974 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_974 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: a4 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON CONSTRAINT name ON any_name IS comment_text
rule_979 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_979 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.lappend(a6, make_string(a4))) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON CONSTRAINT name ON DOMAIN_P any_name IS comment_text
rule_980 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_980 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a7 = Rt.list_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.list_make2(make_type_name_from_name_list(a7), make_string(a4))) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON object_type_name_on_any_name name ON any_name IS comment_text
rule_981 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_981 = |_ctx, v, _l, _loc| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.text_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: a3 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.lappend(a6, make_string(a4))) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON TRANSFORM FOR Typename LANGUAGE name IS comment_text
rule_984 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_984 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.list_make2(a5, make_string(a7))) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON OPERATOR CLASS any_name USING name IS comment_text
rule_985 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_985 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.lcons(make_string(a7), a5)) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON LARGE_P OBJECT_P NumericOnly IS comment_text
rule_987 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_987 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: a5 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CommentStmt: COMMENT ON CAST '(' Typename AS Typename ')' IS comment_text
rule_988 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_988 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a10 = Rt.text_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommentStmt({ ..Node.comment_stmt_default, objtype: literal_0 })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), object: Rt.list_node(Rt.list_make2(a5, a7)) })
	$n = Node.CommentStmt({ ..Node.comment_stmt_of($n), comment: a10 })
	$result = $n
	Ok(Rt.of_node($result))
}

## SecLabelStmt: SECURITY LABEL opt_provider ON object_type_any_name any_name IS security_label
rule_991 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_991 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SecLabelStmt({ ..Node.sec_label_stmt_default, provider: a3, objtype: a5 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), object: Rt.list_node(a6) })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), label: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## SecLabelStmt: SECURITY LABEL opt_provider ON COLUMN any_name IS security_label
rule_992 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_992 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SecLabelStmt({ ..Node.sec_label_stmt_default, provider: a3, objtype: literal_0 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), object: Rt.list_node(a6) })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), label: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## SecLabelStmt: SECURITY LABEL opt_provider ON object_type_name name IS security_label
rule_993 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_993 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SecLabelStmt({ ..Node.sec_label_stmt_default, provider: a3, objtype: a5 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), object: make_string(a6) })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), label: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## SecLabelStmt: SECURITY LABEL opt_provider ON TYPE_P Typename IS security_label
rule_994 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_994 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.node_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SecLabelStmt({ ..Node.sec_label_stmt_default, provider: a3, objtype: literal_0 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), object: a6 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), label: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## SecLabelStmt: SECURITY LABEL opt_provider ON LARGE_P OBJECT_P NumericOnly IS security_label
rule_998 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_998 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SecLabelStmt({ ..Node.sec_label_stmt_default, provider: a3, objtype: literal_0 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), object: a7 })
	$n = Node.SecLabelStmt({ ..Node.sec_label_stmt_of($n), label: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## FetchStmt: FETCH fetch_args
rule_1005 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1005 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.FetchStmt({ ..Node.fetch_stmt_of($n), ismove: Bool.False })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## FetchStmt: MOVE fetch_args
rule_1006 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1006 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.FetchStmt({ ..Node.fetch_stmt_of($n), ismove: Bool.True })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## fetch_args: cursor_name
rule_1007 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1007 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a1, direction: literal_0, how_many: literal_1 })
	$result = n
	Ok(Rt.of_node($result))
}

## fetch_args: from_in cursor_name
rule_1008 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1008 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a2, direction: literal_0, how_many: literal_1 })
	$result = n
	Ok(Rt.of_node($result))
}

## fetch_args: NEXT opt_from_in cursor_name
rule_1009 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1009 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a3, direction: literal_0, how_many: literal_1 })
	$result = n
	Ok(Rt.of_node($result))
}

## fetch_args: LAST_P opt_from_in cursor_name
rule_1012 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1012 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a3, direction: literal_0 })
	$n = Node.FetchStmt({ ..Node.fetch_stmt_of($n), how_many: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## fetch_args: ABSOLUTE_P SignedIconst opt_from_in cursor_name
rule_1013 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1013 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a4, direction: literal_0, how_many: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## fetch_args: SignedIconst opt_from_in cursor_name
rule_1015 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1015 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.int_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a3, direction: literal_0, how_many: a1 })
	$result = n
	Ok(Rt.of_node($result))
}

## fetch_args: FORWARD ALL opt_from_in cursor_name
rule_1019 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1019 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.FetchStmt({ ..Node.fetch_stmt_default, portalname: a4, direction: literal_0, how_many: literal_1 })
	$result = n
	Ok(Rt.of_node($result))
}

## GrantStmt: GRANT privileges ON privilege_target TO grantee_list opt_grant_grant_option opt_granted_by
rule_1027 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1027 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.bool_at(v, 6)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.True, privileges: a2 })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), targtype: Node.priv_target_of(a4).targtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objtype: Node.priv_target_of(a4).objtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objects: Node.priv_target_of(a4).objs })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), grantees: a6, grant_option: a7, grantor: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## RevokeStmt: REVOKE privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior
rule_1028 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1028 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.int_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.False, grant_option: Bool.False, privileges: a2 })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), targtype: Node.priv_target_of(a4).targtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objtype: Node.priv_target_of(a4).objtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objects: Node.priv_target_of(a4).objs })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), grantees: a6, grantor: a7, behavior: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## RevokeStmt: REVOKE GRANT OPTION FOR privileges ON privilege_target FROM grantee_list opt_granted_by opt_drop_behavior
rule_1029 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1029 = |_ctx, v, _l, _loc| {
	a5 = Rt.list_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.int_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.False, grant_option: Bool.True, privileges: a5 })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), targtype: Node.priv_target_of(a7).targtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objtype: Node.priv_target_of(a7).objtype })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), objects: Node.priv_target_of(a7).objs })
	$n = Node.GrantStmt({ ..Node.grant_stmt_of($n), grantees: a9, grantor: a10, behavior: a11 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privileges: ALL '(' columnList ')'
rule_1033 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1033 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	n = Node.AccessPriv({ ..Node.access_priv_default, priv_name: Err(Null), cols: a3 })
	$result = Rt.list_make1(n)
	Ok(Rt.of_list($result))
}

## privileges: ALL PRIVILEGES '(' columnList ')'
rule_1034 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1034 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	var $result = Rt.list_at(v, 0)
	n = Node.AccessPriv({ ..Node.access_priv_default, priv_name: Err(Null), cols: a4 })
	$result = Rt.list_make1(n)
	Ok(Rt.of_list($result))
}

## privilege: SELECT opt_column_list
rule_1037 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1037 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AccessPriv(Node.access_priv_default)
	$n = Node.AccessPriv({ ..Node.access_priv_of($n), priv_name: a1 })
	$n = Node.AccessPriv({ ..Node.access_priv_of($n), cols: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege: ALTER SYSTEM_P
rule_1040 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1040 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.AccessPriv(Node.access_priv_default)
	$n = Node.AccessPriv({ ..Node.access_priv_of($n), priv_name: Ok("alter system") })
	$n = Node.AccessPriv({ ..Node.access_priv_of($n), cols: [] })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege: ColId opt_column_list
rule_1041 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1041 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.AccessPriv({ ..Node.access_priv_default, priv_name: a1, cols: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## privilege_target: qualified_name_list
rule_1046 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1046 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PrivTarget(Node.priv_target_default)
	$n = Node.PrivTarget({ ..Node.priv_target_of($n), targtype: literal_0, objtype: literal_1, objs: a1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege_target: TABLE qualified_name_list
rule_1047 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1047 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PrivTarget(Node.priv_target_default)
	$n = Node.PrivTarget({ ..Node.priv_target_of($n), targtype: literal_0, objtype: literal_1, objs: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege_target: FOREIGN DATA_P WRAPPER name_list
rule_1049 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1049 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PrivTarget(Node.priv_target_default)
	$n = Node.PrivTarget({ ..Node.priv_target_of($n), targtype: literal_0, objtype: literal_1, objs: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege_target: FOREIGN SERVER name_list
rule_1050 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1050 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PrivTarget(Node.priv_target_default)
	$n = Node.PrivTarget({ ..Node.priv_target_of($n), targtype: literal_0, objtype: literal_1, objs: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## privilege_target: ALL TABLES IN_P SCHEMA name_list
rule_1062 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1062 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PrivTarget(Node.priv_target_default)
	$n = Node.PrivTarget({ ..Node.priv_target_of($n), targtype: literal_0, objtype: literal_1, objs: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## GrantRoleStmt: GRANT privilege_list TO role_list opt_granted_by
rule_1073 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1073 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_default, is_grant: Bool.True, granted_roles: a2, grantee_roles: a4, opt: [], grantor: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## GrantRoleStmt: GRANT privilege_list TO role_list WITH grant_role_opt_list opt_granted_by
rule_1074 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1074 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_default, is_grant: Bool.True, granted_roles: a2, grantee_roles: a4, opt: a6, grantor: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## RevokeRoleStmt: REVOKE privilege_list FROM role_list opt_granted_by opt_drop_behavior
rule_1075 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1075 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_default, is_grant: Bool.False, opt: [], granted_roles: a2, grantee_roles: a4, grantor: a5, behavior: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## RevokeRoleStmt: REVOKE ColId OPTION FOR privilege_list FROM role_list opt_granted_by opt_drop_behavior
rule_1076 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1076 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	a5 = Rt.list_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.int_at(v, 8)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.GrantRoleStmt(Node.grant_role_stmt_default)
	var $opt = Null
	$opt = make_def_elem(a2, make_boolean(Bool.False), l2)
	$n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_of($n), is_grant: Bool.False })
	$n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_of($n), opt: Rt.list_make1($opt) })
	$n = Node.GrantRoleStmt({ ..Node.grant_role_stmt_of($n), granted_roles: a5, grantee_roles: a7, grantor: a8, behavior: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## grant_role_opt_value: OPTION
rule_1080 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1080 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = make_boolean(Bool.True)
	Ok(Rt.of_node($result))
}

## grant_role_opt_value: FALSE_P
rule_1082 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1082 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = make_boolean(Bool.False)
	Ok(Rt.of_node($result))
}

## AlterDefaultPrivilegesStmt: ALTER DEFAULT PRIVILEGES DefACLOptionList DefACLAction
rule_1085 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1085 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterDefaultPrivilegesStmt({ ..Node.alter_default_privileges_stmt_default, options: a4 })
	$n = Node.AlterDefaultPrivilegesStmt({ ..Node.alter_default_privileges_stmt_of($n), action: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## DefACLOption: IN_P SCHEMA name_list
rule_1088 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1088 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("schemas"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## DefACLOption: FOR ROLE role_list
rule_1089 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1089 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("roles"), Rt.list_node(a3), l1)
	Ok(Rt.of_node($result))
}

## DefACLAction: GRANT privileges ON defacl_privilege_target TO grantee_list opt_grant_grant_option
rule_1091 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1091 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.int_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.bool_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.True, privileges: a2, targtype: literal_0, objtype: a4, objects: [], grantees: a6, grant_option: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefACLAction: REVOKE privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior
rule_1092 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1092 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.int_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.int_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.False, grant_option: Bool.False, privileges: a2, targtype: literal_0, objtype: a4, objects: [], grantees: a6, behavior: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## DefACLAction: REVOKE GRANT OPTION FOR privileges ON defacl_privilege_target FROM grantee_list opt_drop_behavior
rule_1093 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1093 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a7 = Rt.int_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.int_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.GrantStmt({ ..Node.grant_stmt_default, is_grant: Bool.False, grant_option: Bool.True, privileges: a5, targtype: literal_0, objtype: a7, objects: [], grantees: a9, behavior: a10 })
	$result = n
	Ok(Rt.of_node($result))
}

## IndexStmt: CREATE opt_unique INDEX opt_concurrently opt_single_name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_unique_null_treatment opt_reloptions OptTableSpace where_clause
rule_1101 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1101 = |_ctx, v, _l, _loc, literal_0, literal_1, literal_2, literal_3| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.text_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.list_at(v, 9)
	a12 = Rt.list_at(v, 11)
	a13 = Rt.bool_at(v, 12)
	a14 = Rt.list_at(v, 13)
	a15 = Rt.text_at(v, 14)
	a16 = Rt.node_at(v, 15)
	var $result = Rt.node_at(v, 0)
	var $n = Node.IndexStmt({ ..Node.index_stmt_default, unique: a2, concurrent: a4, idxname: a5, relation: a7, access_method: a8, index_params: a10, index_including_params: a12 })
	$n = Node.IndexStmt({ ..Node.index_stmt_of($n), nulls_not_distinct: !(a13) })
	$n = Node.IndexStmt({ ..Node.index_stmt_of($n), options: a14, table_space: a15, where_clause: a16, exclude_op_names: [], idxcomment: Err(Null), index_oid: literal_0, old_number: literal_1, old_create_subid: literal_2, old_first_relfilelocator_subid: literal_3, primary: Bool.False, isconstraint: Bool.False, deferrable: Bool.False, initdeferred: Bool.False, transformed: Bool.False, if_not_exists: Bool.False, reset_default_tblspc: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## IndexStmt: CREATE opt_unique INDEX opt_concurrently IF_P NOT EXISTS name ON relation_expr access_method_clause '(' index_params ')' opt_include opt_unique_null_treatment opt_reloptions OptTableSpace where_clause
rule_1102 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1102 = |_ctx, v, _l, _loc, literal_0, literal_1, literal_2, literal_3| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.bool_at(v, 3)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.text_at(v, 10)
	a13 = Rt.list_at(v, 12)
	a15 = Rt.list_at(v, 14)
	a16 = Rt.bool_at(v, 15)
	a17 = Rt.list_at(v, 16)
	a18 = Rt.text_at(v, 17)
	a19 = Rt.node_at(v, 18)
	var $result = Rt.node_at(v, 0)
	var $n = Node.IndexStmt({ ..Node.index_stmt_default, unique: a2, concurrent: a4, idxname: a8, relation: a10, access_method: a11, index_params: a13, index_including_params: a15 })
	$n = Node.IndexStmt({ ..Node.index_stmt_of($n), nulls_not_distinct: !(a16) })
	$n = Node.IndexStmt({ ..Node.index_stmt_of($n), options: a17, table_space: a18, where_clause: a19, exclude_op_names: [], idxcomment: Err(Null), index_oid: literal_0, old_number: literal_1, old_create_subid: literal_2, old_first_relfilelocator_subid: literal_3, primary: Bool.False, isconstraint: Bool.False, deferrable: Bool.False, initdeferred: Bool.False, transformed: Bool.False, if_not_exists: Bool.True, reset_default_tblspc: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## access_method_clause: %empty
rule_1106 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1106 = |_ctx, _v, _l, _loc| {
	var $result = Err(Null)
	$result = Ok("btree")
	Ok(Rt.of_text($result))
}

## index_elem_options: opt_collate opt_qualified_name opt_asc_desc opt_nulls_order
rule_1109 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1109 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.IndexElem(Node.index_elem_default)
	$result = Node.IndexElem({ ..Node.index_elem_of($result), name: Err(Null) })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), expr: Null })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), indexcolname: Err(Null) })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), collation: a1 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), opclass: a2 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), opclassopts: [] })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), ordering: a3 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), nulls_ordering: a4 })
	Ok(Rt.of_node($result))
}

## index_elem_options: opt_collate any_name reloptions opt_asc_desc opt_nulls_order
rule_1110 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1110 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	$result = Node.IndexElem(Node.index_elem_default)
	$result = Node.IndexElem({ ..Node.index_elem_of($result), name: Err(Null) })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), expr: Null })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), indexcolname: Err(Null) })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), collation: a1 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), opclass: a2 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), opclassopts: a3 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), ordering: a4 })
	$result = Node.IndexElem({ ..Node.index_elem_of($result), nulls_ordering: a5 })
	Ok(Rt.of_node($result))
}

## index_elem: ColId index_elem_options
rule_1111 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1111 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.IndexElem({ ..Node.index_elem_of($result), name: a1 })
	Ok(Rt.of_node($result))
}

## index_elem: func_expr_windowless index_elem_options
rule_1112 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1112 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.IndexElem({ ..Node.index_elem_of($result), expr: a1 })
	Ok(Rt.of_node($result))
}

## index_elem: '(' a_expr ')' index_elem_options
rule_1113 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1113 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = a4
	$result = Node.IndexElem({ ..Node.index_elem_of($result), expr: a2 })
	Ok(Rt.of_node($result))
}

## CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS func_return opt_createfunc_opt_list opt_routine_body
rule_1126 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1126 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_default, is_procedure: Bool.False, replace: a2, funcname: a4, parameters: a5, return_type: a7, options: a8, sql_body: a9 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults RETURNS TABLE '(' table_func_column_list ')' opt_createfunc_opt_list opt_routine_body
rule_1127 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1127 = |ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.node_at(v, 11)
	l7 = Rt.location(l, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_default, is_procedure: Bool.False, replace: a2, funcname: a4 })
	$n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_of($n), parameters: merge_table_func_parameters(a5, a9, ctx)? })
	$n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_of($n), return_type: table_func_type_name(a9) })
	$n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_of($n), return_type: Node.TypeName({ ..Node.type_name_of(Node.create_function_stmt_of($n).return_type), location: l7 }) })
	$n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_of($n), options: a11, sql_body: a12 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateFunctionStmt: CREATE opt_or_replace FUNCTION func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body
rule_1128 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1128 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_default, is_procedure: Bool.False, replace: a2, funcname: a4, parameters: a5, return_type: Null, options: a6, sql_body: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateFunctionStmt: CREATE opt_or_replace PROCEDURE func_name func_args_with_defaults opt_createfunc_opt_list opt_routine_body
rule_1129 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1129 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateFunctionStmt({ ..Node.create_function_stmt_default, is_procedure: Bool.True, replace: a2, funcname: a4, parameters: a5, return_type: Null, options: a6, sql_body: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## function_with_argtypes: func_name func_args
rule_1138 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1138 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ObjectWithArgs({ ..Node.object_with_args_default, objname: a1 })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objargs: extract_arg_types(a2) })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objfuncargs: a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## function_with_argtypes: type_func_name_keyword
rule_1139 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1139 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ObjectWithArgs(Node.object_with_args_default)
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objname: Rt.list_make1(make_string(a1)) })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), args_unspecified: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## function_with_argtypes: ColId indirection
rule_1141 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1141 = |ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ObjectWithArgs(Node.object_with_args_default)
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objname: check_func_name(Rt.lcons(make_string(a1), a2), ctx)? })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), args_unspecified: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_arg: arg_class param_name func_type
rule_1146 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1146 = |_ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.text_at(v, 1)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FunctionParameter({ ..Node.function_parameter_default, name: a2, arg_type: a3, mode: a1, defexpr: Null, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_arg: param_name arg_class func_type
rule_1147 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1147 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.int_at(v, 1)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FunctionParameter({ ..Node.function_parameter_default, name: a1, arg_type: a3, mode: a2, defexpr: Null, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_arg: param_name func_type
rule_1148 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1148 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FunctionParameter({ ..Node.function_parameter_default, name: a1, arg_type: a2, mode: literal_0, defexpr: Null, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_arg: arg_class func_type
rule_1149 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1149 = |_ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FunctionParameter({ ..Node.function_parameter_default, name: Err(Null), arg_type: a2, mode: a1, defexpr: Null, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_arg: func_type
rule_1150 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1150 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.FunctionParameter({ ..Node.function_parameter_default, name: Err(Null), arg_type: a1, mode: literal_0, defexpr: Null, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_type: type_function_name attrs '%' TYPE_P
rule_1159 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1159 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_type_name_from_name_list(Rt.lcons(make_string(a1), a2))
	$result = Node.TypeName({ ..Node.type_name_of($result), pct_type: Bool.True })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## func_type: SETOF type_function_name attrs '%' TYPE_P
rule_1160 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1160 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_type_name_from_name_list(Rt.lcons(make_string(a2), a3))
	$result = Node.TypeName({ ..Node.type_name_of($result), pct_type: Bool.True })
	$result = Node.TypeName({ ..Node.type_name_of($result), setof: Bool.True })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l2 })
	Ok(Rt.of_node($result))
}

## func_arg_with_default: func_arg DEFAULT a_expr
rule_1162 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1162 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.FunctionParameter({ ..Node.function_parameter_of($result), defexpr: a3 })
	Ok(Rt.of_node($result))
}

## aggr_arg: func_arg
rule_1164 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1164 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if !((((Node.function_parameter_of(a1).mode == literal_0) or (Node.function_parameter_of(a1).mode == literal_1)) or (Node.function_parameter_of(a1).mode == literal_2))) {
		return Err(Rt.error(ctx, "0A000", Ok("aggregates cannot have output arguments"), l1))
	}
	$result = a1
	Ok(Rt.of_node($result))
}

## aggr_args: '(' '*' ')'
rule_1165 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1165 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Null, make_integer((0 - literal_0)))
	Ok(Rt.of_list($result))
}

## aggr_args: '(' aggr_args_list ')'
rule_1166 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1166 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Rt.list_node(a2), make_integer((0 - literal_0)))
	Ok(Rt.of_list($result))
}

## aggr_args: '(' ORDER BY aggr_args_list ')'
rule_1167 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1167 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Rt.list_node(a4), make_integer(literal_0))
	Ok(Rt.of_list($result))
}

## aggr_args: '(' aggr_args_list ORDER BY aggr_args_list ')'
rule_1168 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1168 = |ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = make_ordered_set_args(a2, a5, ctx)?
	Ok(Rt.of_list($result))
}

## aggregate_with_argtypes: func_name aggr_args
rule_1171 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1171 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ObjectWithArgs({ ..Node.object_with_args_default, objname: a1 })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objargs: extract_aggr_arg_types(a2) })
	$n = Node.ObjectWithArgs({ ..Node.object_with_args_of($n), objfuncargs: Rt.node_list(Rt.linitial(a2)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## common_func_opt_item: CALLED ON NULL_P INPUT_P
rule_1178 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1178 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("strict"), make_boolean(Bool.False), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: RETURNS NULL_P ON NULL_P INPUT_P
rule_1179 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1179 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("strict"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: IMMUTABLE
rule_1181 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1181 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("volatility"), make_string(Ok("immutable")), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: STABLE
rule_1182 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1182 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("volatility"), make_string(Ok("stable")), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: VOLATILE
rule_1183 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1183 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("volatility"), make_string(Ok("volatile")), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: EXTERNAL SECURITY DEFINER
rule_1184 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1184 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("security"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: EXTERNAL SECURITY INVOKER
rule_1185 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1185 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("security"), make_boolean(Bool.False), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: LEAKPROOF
rule_1188 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1188 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("leakproof"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: NOT LEAKPROOF
rule_1189 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1189 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("leakproof"), make_boolean(Bool.False), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: COST NumericOnly
rule_1190 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1190 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("cost"), a2, l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: ROWS NumericOnly
rule_1191 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1191 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("rows"), a2, l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: SUPPORT any_name
rule_1192 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1192 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("support"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: FunctionSetResetClause
rule_1193 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1193 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("set"), a1, l1)
	Ok(Rt.of_node($result))
}

## common_func_opt_item: PARALLEL ColId
rule_1194 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1194 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("parallel"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## createfunc_opt_item: AS func_as
rule_1195 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1195 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("as"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## createfunc_opt_item: LANGUAGE NonReservedWord_or_Sconst
rule_1196 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1196 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("language"), make_string(a2), l1)
	Ok(Rt.of_node($result))
}

## createfunc_opt_item: TRANSFORM transform_type_list
rule_1197 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1197 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transform"), Rt.list_node(a2), l1)
	Ok(Rt.of_node($result))
}

## createfunc_opt_item: WINDOW
rule_1198 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1198 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("window"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## func_as: Sconst ',' Sconst
rule_1201 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1201 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(make_string(a1), make_string(a3))
	Ok(Rt.of_list($result))
}

## ReturnStmt: RETURN a_expr
rule_1202 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1202 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $r = Node.ReturnStmt(Node.return_stmt_default)
	$r = Node.ReturnStmt({ ..Node.return_stmt_of($r), returnval: a2 })
	$result = $r
	Ok(Rt.of_node($result))
}

## opt_routine_body: BEGIN_P ATOMIC routine_body_stmt_list END_P
rule_1204 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1204 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = Rt.list_node(Rt.list_make1(Rt.list_node(a3)))
	Ok(Rt.of_node($result))
}

## routine_body_stmt_list: routine_body_stmt_list routine_body_stmt ';'
rule_1206 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1206 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.list_at(v, 0)
	if !(Node.is_null(a2)) {
		$result = Rt.lappend(a1, a2)
	} else {
		$result = a1
	}
	Ok(Rt.of_list($result))
}

## transform_type_list: FOR TYPE_P Typename
rule_1210 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1210 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(a3)
	Ok(Rt.of_list($result))
}

## transform_type_list: transform_type_list ',' FOR TYPE_P Typename
rule_1211 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1211 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, a5)
	Ok(Rt.of_list($result))
}

## AlterFunctionStmt: ALTER FUNCTION function_with_argtypes alterfunc_opt_list opt_restrict
rule_1217 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1217 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterFunctionStmt({ ..Node.alter_function_stmt_default, objtype: literal_0, func: a3, actions: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## RemoveFuncStmt: DROP FUNCTION function_with_argtypes_list opt_drop_behavior
rule_1224 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1224 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, objects: a3, behavior: a4, missing_ok: Bool.False, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RemoveFuncStmt: DROP FUNCTION IF_P EXISTS function_with_argtypes_list opt_drop_behavior
rule_1225 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1225 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0, objects: a5, behavior: a6, missing_ok: Bool.True, concurrent: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## oper_argtypes: '(' Typename ')'
rule_1234 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1234 = |ctx, _v, l, _loc| {
	l3 = Rt.location(l, 2)
	Err(Rt.error(ctx, "42601", Ok("missing argument"), l3))
}

## oper_argtypes: '(' Typename ',' Typename ')'
rule_1235 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1235 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a2, a4)
	Ok(Rt.of_list($result))
}

## oper_argtypes: '(' NONE ',' Typename ')'
rule_1236 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1236 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Null, a4)
	Ok(Rt.of_list($result))
}

## oper_argtypes: '(' Typename ',' NONE ')'
rule_1237 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1237 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a2, Null)
	Ok(Rt.of_list($result))
}

## any_operator: ColId '.' any_operator
rule_1239 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1239 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lcons(make_string(a1), a3)
	Ok(Rt.of_list($result))
}

## operator_with_argtypes: any_operator oper_argtypes
rule_1242 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1242 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.ObjectWithArgs({ ..Node.object_with_args_default, objname: a1, objargs: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## DoStmt: DO dostmt_opt_list
rule_1243 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1243 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.DoStmt({ ..Node.do_stmt_default, args: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## dostmt_opt_item: Sconst
rule_1246 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1246 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("as"), make_string(a1), l1)
	Ok(Rt.of_node($result))
}

## CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITH FUNCTION function_with_argtypes cast_context
rule_1248 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1248 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.int_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateCastStmt({ ..Node.create_cast_stmt_default, sourcetype: a4, targettype: a6, func: a10 })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), context: a11 })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), inout: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITHOUT FUNCTION cast_context
rule_1249 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1249 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a10 = Rt.int_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateCastStmt({ ..Node.create_cast_stmt_default, sourcetype: a4, targettype: a6, func: Null })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), context: a10 })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), inout: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateCastStmt: CREATE CAST '(' Typename AS Typename ')' WITH INOUT cast_context
rule_1250 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1250 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a10 = Rt.int_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateCastStmt({ ..Node.create_cast_stmt_default, sourcetype: a4, targettype: a6, func: Null })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), context: a10 })
	$n = Node.CreateCastStmt({ ..Node.create_cast_stmt_of($n), inout: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropCastStmt: DROP CAST opt_if_exists '(' Typename AS Typename ')' opt_drop_behavior
rule_1254 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1254 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.bool_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.int_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0 })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.list_make2(a5, a7))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), behavior: a9, missing_ok: a3, concurrent: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateTransformStmt: CREATE opt_or_replace TRANSFORM FOR Typename LANGUAGE name '(' transform_element_list ')'
rule_1257 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1257 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.list_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateTransformStmt({ ..Node.create_transform_stmt_default, replace: a2, type_name: a5, lang: a7 })
	$n = Node.CreateTransformStmt({ ..Node.create_transform_stmt_of($n), fromsql: Rt.linitial(a9) })
	$n = Node.CreateTransformStmt({ ..Node.create_transform_stmt_of($n), tosql: Rt.lsecond(a9) })
	$result = $n
	Ok(Rt.of_node($result))
}

## transform_element_list: FROM SQL_P WITH FUNCTION function_with_argtypes ',' TO SQL_P WITH FUNCTION function_with_argtypes
rule_1258 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1258 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a11 = Rt.node_at(v, 10)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a5, a11)
	Ok(Rt.of_list($result))
}

## transform_element_list: TO SQL_P WITH FUNCTION function_with_argtypes ',' FROM SQL_P WITH FUNCTION function_with_argtypes
rule_1259 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1259 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	a11 = Rt.node_at(v, 10)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a11, a5)
	Ok(Rt.of_list($result))
}

## transform_element_list: FROM SQL_P WITH FUNCTION function_with_argtypes
rule_1260 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1260 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a5, Null)
	Ok(Rt.of_list($result))
}

## transform_element_list: TO SQL_P WITH FUNCTION function_with_argtypes
rule_1261 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1261 = |_ctx, v, _l, _loc| {
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Null, a5)
	Ok(Rt.of_list($result))
}

## DropTransformStmt: DROP TRANSFORM opt_if_exists FOR Typename LANGUAGE name opt_drop_behavior
rule_1262 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1262 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.bool_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.int_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DropStmt({ ..Node.drop_stmt_default, remove_type: literal_0 })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), objects: Rt.list_make1(Rt.list_node(Rt.list_make2(a5, make_string(a7)))) })
	$n = Node.DropStmt({ ..Node.drop_stmt_of($n), behavior: a8, missing_ok: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ReindexStmt: REINDEX opt_reindex_option_list reindex_target_relation opt_concurrently qualified_name
rule_1263 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1263 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ReindexStmt({ ..Node.reindex_stmt_default, kind: a3, relation: a5, name: Err(Null), params: a2 })
	if a4 {
		$n = Node.ReindexStmt({ ..Node.reindex_stmt_of($n), params: Rt.lappend(Node.reindex_stmt_of($n).params, make_def_elem(Ok("concurrently"), Null, l4)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ReindexStmt: REINDEX opt_reindex_option_list SCHEMA opt_concurrently name
rule_1264 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1264 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.text_at(v, 4)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ReindexStmt({ ..Node.reindex_stmt_default, kind: literal_0, relation: Null, name: a5, params: a2 })
	if a4 {
		$n = Node.ReindexStmt({ ..Node.reindex_stmt_of($n), params: Rt.lappend(Node.reindex_stmt_of($n).params, make_def_elem(Ok("concurrently"), Null, l4)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ReindexStmt: REINDEX opt_reindex_option_list reindex_target_all opt_concurrently opt_single_name
rule_1265 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1265 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.text_at(v, 4)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ReindexStmt({ ..Node.reindex_stmt_default, kind: a3, relation: Null, name: a5, params: a2 })
	if a4 {
		$n = Node.ReindexStmt({ ..Node.reindex_stmt_of($n), params: Rt.lappend(Node.reindex_stmt_of($n).params, make_def_elem(Ok("concurrently"), Null, l4)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterTblSpcStmt: ALTER TABLESPACE name SET reloptions
rule_1272 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1272 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableSpaceOptionsStmt({ ..Node.alter_table_space_options_stmt_default, tablespacename: a3, options: a5, is_reset: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTblSpcStmt: ALTER TABLESPACE name RESET reloptions
rule_1273 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1273 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTableSpaceOptionsStmt({ ..Node.alter_table_space_options_stmt_default, tablespacename: a3, options: a5, is_reset: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER AGGREGATE aggregate_with_argtypes RENAME TO name
rule_1274 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1274 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: a3 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER COLLATION any_name RENAME TO name
rule_1275 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1275 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: Rt.list_node(a3) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER DATABASE name RENAME TO name
rule_1277 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1277 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, subname: a3, newname: a6, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER DOMAIN_P any_name RENAME CONSTRAINT name TO name
rule_1279 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1279 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: Rt.list_node(a3) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), subname: a6, newname: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER FOREIGN DATA_P WRAPPER name RENAME TO name
rule_1280 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1280 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.text_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: make_string(a5) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a8, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER opt_procedural LANGUAGE name RENAME TO name
rule_1283 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1283 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: make_string(a4) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a7, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER OPERATOR CLASS any_name USING name RENAME TO name
rule_1284 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1284 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: Rt.list_node(Rt.lcons(make_string(a6), a4)) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a9, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER POLICY name ON qualified_name RENAME TO name
rule_1286 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1286 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a5, subname: a3, newname: a8, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER POLICY IF_P EXISTS name ON qualified_name RENAME TO name
rule_1287 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1287 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.text_at(v, 4)
	a7 = Rt.node_at(v, 6)
	a10 = Rt.text_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a7, subname: a5, newname: a10, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER PUBLICATION name RENAME TO name
rule_1289 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1289 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: make_string(a3) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE relation_expr RENAME TO name
rule_1294 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1294 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a3, subname: Err(Null), newname: a6, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME TO name
rule_1295 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1295 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a5, subname: Err(Null), newname: a8, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER MATERIALIZED VIEW qualified_name RENAME TO name
rule_1300 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1300 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a4, subname: Err(Null), newname: a7, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME TO name
rule_1301 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1301 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.node_at(v, 5)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a6, subname: Err(Null), newname: a9, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE relation_expr RENAME opt_column name TO name
rule_1306 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1306 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation_type: literal_1, relation: a3, subname: a6, newname: a8, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME opt_column name TO name
rule_1307 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1307 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.text_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation_type: literal_1, relation: a5, subname: a8, newname: a10, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER MATERIALIZED VIEW qualified_name RENAME opt_column name TO name
rule_1310 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1310 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a4 = Rt.node_at(v, 3)
	a7 = Rt.text_at(v, 6)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation_type: literal_1, relation: a4, subname: a7, newname: a9, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name RENAME opt_column name TO name
rule_1311 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1311 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a6 = Rt.node_at(v, 5)
	a9 = Rt.text_at(v, 8)
	a11 = Rt.text_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation_type: literal_1, relation: a6, subname: a9, newname: a11, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE relation_expr RENAME CONSTRAINT name TO name
rule_1312 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1312 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a3, subname: a6, newname: a8, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TABLE IF_P EXISTS relation_expr RENAME CONSTRAINT name TO name
rule_1313 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1313 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.text_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation: a5, subname: a8, newname: a10, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER EVENT TRIGGER name RENAME TO name
rule_1318 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1318 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: make_string(a4) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TEXT_P SEARCH PARSER any_name RENAME TO name
rule_1323 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1323 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), object: Rt.list_node(a5) })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), newname: a8, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## RenameStmt: ALTER TYPE_P any_name RENAME ATTRIBUTE name TO name opt_drop_behavior
rule_1328 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1328 = |ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	a9 = Rt.int_at(v, 8)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RenameStmt({ ..Node.rename_stmt_default, rename_type: literal_0, relation_type: literal_1 })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), relation: make_range_var_from_any_name(a3, l3, ctx)? })
	$n = Node.RenameStmt({ ..Node.rename_stmt_of($n), subname: a6, newname: a8, behavior: a9, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectDependsStmt: ALTER FUNCTION function_with_argtypes opt_no DEPENDS ON EXTENSION name
rule_1333 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1333 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), object: a3 })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), extname: make_string(a8) })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), remove: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectDependsStmt: ALTER TRIGGER name ON qualified_name opt_no DEPENDS ON EXTENSION name
rule_1336 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1336 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.bool_at(v, 5)
	a10 = Rt.text_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_default, object_type: literal_0, relation: a5 })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), object: Rt.list_node(Rt.list_make1(make_string(a3))) })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), extname: make_string(a10) })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), remove: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectDependsStmt: ALTER MATERIALIZED VIEW qualified_name opt_no DEPENDS ON EXTENSION name
rule_1337 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1337 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_default, object_type: literal_0, relation: a4 })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), extname: make_string(a9) })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), remove: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectDependsStmt: ALTER INDEX qualified_name opt_no DEPENDS ON EXTENSION name
rule_1338 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1338 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_default, object_type: literal_0, relation: a3 })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), extname: make_string(a8) })
	$n = Node.AlterObjectDependsStmt({ ..Node.alter_object_depends_stmt_of($n), remove: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER AGGREGATE aggregate_with_argtypes SET SCHEMA name
rule_1341 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1341 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), object: a3 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), newschema: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER COLLATION any_name SET SCHEMA name
rule_1342 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1342 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), object: Rt.list_node(a3) })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), newschema: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER EXTENSION name SET SCHEMA name
rule_1345 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1345 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), object: make_string(a3) })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), newschema: a6, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER OPERATOR CLASS any_name USING name SET SCHEMA name
rule_1348 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1348 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), object: Rt.list_node(Rt.lcons(make_string(a6), a4)) })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), newschema: a9, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER TABLE relation_expr SET SCHEMA name
rule_1352 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1352 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0, relation: a3, newschema: a6, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER TABLE IF_P EXISTS relation_expr SET SCHEMA name
rule_1353 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1353 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.node_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0, relation: a5, newschema: a8, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER TEXT_P SEARCH PARSER any_name SET SCHEMA name
rule_1355 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1355 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a8 = Rt.text_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0 })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), object: Rt.list_node(a5) })
	$n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_of($n), newschema: a8, missing_ok: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER MATERIALIZED VIEW qualified_name SET SCHEMA name
rule_1363 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1363 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a7 = Rt.text_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0, relation: a4, newschema: a7, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterObjectSchemaStmt: ALTER MATERIALIZED VIEW IF_P EXISTS qualified_name SET SCHEMA name
rule_1364 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1364 = |_ctx, v, _l, _loc, literal_0| {
	a6 = Rt.node_at(v, 5)
	a9 = Rt.text_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterObjectSchemaStmt({ ..Node.alter_object_schema_stmt_default, object_type: literal_0, relation: a6, newschema: a9, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterOperatorStmt: ALTER OPERATOR operator_with_argtypes SET '(' operator_def_list ')'
rule_1368 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1368 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterOperatorStmt({ ..Node.alter_operator_stmt_default, opername: a3, options: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTypeStmt: ALTER TYPE_P any_name SET '(' operator_def_list ')'
rule_1379 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1379 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTypeStmt({ ..Node.alter_type_stmt_default, type_name: a3, options: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER AGGREGATE aggregate_with_argtypes OWNER TO RoleSpec
rule_1380 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1380 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: a3 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER COLLATION any_name OWNER TO RoleSpec
rule_1381 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1381 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: Rt.list_node(a3) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER DATABASE name OWNER TO RoleSpec
rule_1383 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1383 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.node_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: make_string(a3) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER opt_procedural LANGUAGE name OWNER TO RoleSpec
rule_1386 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1386 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: make_string(a4) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER LARGE_P OBJECT_P NumericOnly OWNER TO RoleSpec
rule_1387 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1387 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: a4 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER OPERATOR CLASS any_name USING name OWNER TO RoleSpec
rule_1389 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1389 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a9 = Rt.node_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: Rt.list_node(Rt.lcons(make_string(a6), a4)) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER TEXT_P SEARCH DICTIONARY any_name OWNER TO RoleSpec
rule_1397 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1397 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: Rt.list_node(a5) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterOwnerStmt: ALTER FOREIGN DATA_P WRAPPER name OWNER TO RoleSpec
rule_1399 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1399 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.text_at(v, 4)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_default, object_type: literal_0 })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), object: make_string(a5) })
	$n = Node.AlterOwnerStmt({ ..Node.alter_owner_stmt_of($n), newowner: a8 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreatePublicationStmt: CREATE PUBLICATION name opt_definition
rule_1404 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1404 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.CreatePublicationStmt({ ..Node.create_publication_stmt_default, pubname: a3, options: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreatePublicationStmt: CREATE PUBLICATION name FOR ALL TABLES opt_definition
rule_1405 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1405 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.CreatePublicationStmt({ ..Node.create_publication_stmt_default, pubname: a3, options: a7, for_all_tables: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## CreatePublicationStmt: CREATE PUBLICATION name FOR pub_obj_list opt_definition
rule_1406 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1406 = |ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreatePublicationStmt({ ..Node.create_publication_stmt_default, pubname: a3, options: a6 })
	$n = Node.CreatePublicationStmt({ ..Node.create_publication_stmt_of($n), pubobjects: a5 })
	written = preprocess_pubobj_list(Node.create_publication_stmt_of($n).pubobjects, ctx)?
	$n = Node.CreatePublicationStmt({ ..Node.create_publication_stmt_of($n), pubobjects: written.a0 })
	$result = $n
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: TABLE relation_expr opt_column_list OptWhereClause
rule_1407 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1407 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable(Node.publication_table_default) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), relation: a2 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), columns: a3 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), where_clause: a4 }) })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: TABLES IN_P SCHEMA ColId
rule_1408 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1408 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), name: a4 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), location: l4 })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: TABLES IN_P SCHEMA CURRENT_SCHEMA
rule_1409 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1409 = |_ctx, v, l, _loc, literal_0| {
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), location: l4 })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: ColId opt_column_list OptWhereClause
rule_1410 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1410 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	if (!(a2).is_empty() or !Node.is_null(a3)) {
		$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable(Node.publication_table_default) })
		$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), relation: make_range_var(Err(Null), a1, l1) }) })
		$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), columns: a2 }) })
		$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), where_clause: a3 }) })
	} else {
		$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), name: a1 })
	}
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: ColId indirection opt_column_list OptWhereClause
rule_1411 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1411 = |ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable(Node.publication_table_default) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), relation: make_range_var_from_qualified_name(a1, a2, l1, ctx)? }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), columns: a3 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), where_clause: a4 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: extended_relation_expr opt_column_list OptWhereClause
rule_1412 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1412 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable(Node.publication_table_default) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), relation: a1 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), columns: a2 }) })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubtable: Node.PublicationTable({ ..Node.publication_table_of(Node.publication_obj_spec_of($result).pubtable), where_clause: a3 }) })
	Ok(Rt.of_node($result))
}

## PublicationObjSpec: CURRENT_SCHEMA
rule_1413 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1413 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.PublicationObjSpec(Node.publication_obj_spec_default)
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), pubobjtype: literal_0 })
	$result = Node.PublicationObjSpec({ ..Node.publication_obj_spec_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## AlterPublicationStmt: ALTER PUBLICATION name SET definition
rule_1416 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1416 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterPublicationStmt({ ..Node.alter_publication_stmt_default, pubname: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterPublicationStmt: ALTER PUBLICATION name ADD_P pub_obj_list
rule_1417 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1417 = |ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterPublicationStmt({ ..Node.alter_publication_stmt_default, pubname: a3, pubobjects: a5 })
	written = preprocess_pubobj_list(Node.alter_publication_stmt_of($n).pubobjects, ctx)?
	$n = Node.AlterPublicationStmt({ ..Node.alter_publication_stmt_of($n), pubobjects: written.a0 })
	$n = Node.AlterPublicationStmt({ ..Node.alter_publication_stmt_of($n), action: literal_0 })
	$result = $n
	Ok(Rt.of_node($result))
}

## CreateSubscriptionStmt: CREATE SUBSCRIPTION name CONNECTION Sconst PUBLICATION name_list opt_definition
rule_1420 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1420 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.text_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateSubscriptionStmt({ ..Node.create_subscription_stmt_default, subname: a3, conninfo: a5, publication: a7, options: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name SET definition
rule_1421 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1421 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name CONNECTION Sconst
rule_1422 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1422 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.text_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3, conninfo: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name REFRESH PUBLICATION opt_definition
rule_1423 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1423 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3, options: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name ADD_P PUBLICATION name_list opt_definition
rule_1424 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1424 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.list_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3, publication: a6, options: a7 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name ENABLE_P
rule_1427 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1427 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3 })
	$n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("enabled"), make_boolean(Bool.True), l1)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterSubscriptionStmt: ALTER SUBSCRIPTION name DISABLE_P
rule_1428 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1428 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_default, kind: literal_0, subname: a3 })
	$n = Node.AlterSubscriptionStmt({ ..Node.alter_subscription_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("enabled"), make_boolean(Bool.False), l1)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## DropSubscriptionStmt: DROP SUBSCRIPTION name opt_drop_behavior
rule_1430 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1430 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.DropSubscriptionStmt({ ..Node.drop_subscription_stmt_default, subname: a3, missing_ok: Bool.False, behavior: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropSubscriptionStmt: DROP SUBSCRIPTION IF_P EXISTS name opt_drop_behavior
rule_1431 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1431 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	a6 = Rt.int_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DropSubscriptionStmt({ ..Node.drop_subscription_stmt_default, subname: a5, missing_ok: Bool.True, behavior: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## RuleStmt: CREATE opt_or_replace RULE name AS ON event TO qualified_name where_clause DO opt_instead RuleActionList
rule_1432 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1432 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.text_at(v, 3)
	a7 = Rt.int_at(v, 6)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.node_at(v, 9)
	a12 = Rt.bool_at(v, 11)
	a13 = Rt.list_at(v, 12)
	var $result = Rt.node_at(v, 0)
	n = Node.RuleStmt({ ..Node.rule_stmt_default, replace: a2, relation: a9, rulename: a4, where_clause: a10, event: a7, instead: a12, actions: a13 })
	$result = n
	Ok(Rt.of_node($result))
}

## RuleActionMulti: RuleActionMulti ';' RuleActionStmtOrEmpty
rule_1436 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1436 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	if !(Node.is_null(a3)) {
		$result = Rt.lappend(a1, a3)
	} else {
		$result = a1
	}
	Ok(Rt.of_list($result))
}

## RuleActionMulti: RuleActionStmtOrEmpty
rule_1437 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1437 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.list_at(v, 0)
	if !(Node.is_null(a1)) {
		$result = Rt.list_make1(a1)
	} else {
		$result = []
	}
	Ok(Rt.of_list($result))
}

## NotifyStmt: NOTIFY ColId notify_payload
rule_1452 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1452 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.NotifyStmt({ ..Node.notify_stmt_default, conditionname: a2, payload: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## ListenStmt: LISTEN ColId
rule_1455 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1455 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.ListenStmt({ ..Node.listen_stmt_default, conditionname: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## UnlistenStmt: UNLISTEN ColId
rule_1456 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1456 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.UnlistenStmt({ ..Node.unlisten_stmt_default, conditionname: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## UnlistenStmt: UNLISTEN '*'
rule_1457 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1457 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	n = Node.UnlistenStmt({ ..Node.unlisten_stmt_default, conditionname: Err(Null) })
	$result = n
	Ok(Rt.of_node($result))
}

## TransactionStmt: ABORT_P opt_transaction opt_transaction_chain
rule_1458 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1458 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.bool_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, options: [], chain: a3 })
	$n = Node.TransactionStmt({ ..Node.transaction_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## TransactionStmt: START TRANSACTION transaction_mode_list_or_empty
rule_1459 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1459 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, options: a3 })
	$n = Node.TransactionStmt({ ..Node.transaction_stmt_of($n), location: (0 - literal_1) })
	$result = $n
	Ok(Rt.of_node($result))
}

## TransactionStmt: SAVEPOINT ColId
rule_1462 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1462 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, savepoint_name: a2, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## TransactionStmt: RELEASE SAVEPOINT ColId
rule_1463 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1463 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, savepoint_name: a3, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## TransactionStmt: ROLLBACK opt_transaction TO SAVEPOINT ColId
rule_1465 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1465 = |_ctx, v, l, _loc, literal_0| {
	a5 = Rt.text_at(v, 4)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, savepoint_name: a5, location: l5 })
	$result = n
	Ok(Rt.of_node($result))
}

## TransactionStmt: ROLLBACK opt_transaction TO ColId
rule_1466 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1466 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, savepoint_name: a4, location: l4 })
	$result = n
	Ok(Rt.of_node($result))
}

## TransactionStmt: PREPARE TRANSACTION Sconst
rule_1467 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1467 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.TransactionStmt({ ..Node.transaction_stmt_default, kind: literal_0, gid: a3, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## transaction_mode_item: ISOLATION LEVEL iso_level
rule_1475 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1475 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transaction_isolation"), make_string_const(a3, l3), l1)
	Ok(Rt.of_node($result))
}

## transaction_mode_item: READ ONLY
rule_1476 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1476 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transaction_read_only"), make_int_const(1, l1), l1)
	Ok(Rt.of_node($result))
}

## transaction_mode_item: READ WRITE
rule_1477 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1477 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transaction_read_only"), make_int_const(0, l1), l1)
	Ok(Rt.of_node($result))
}

## transaction_mode_item: DEFERRABLE
rule_1478 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1478 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transaction_deferrable"), make_int_const(1, l1), l1)
	Ok(Rt.of_node($result))
}

## transaction_mode_item: NOT DEFERRABLE
rule_1479 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1479 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("transaction_deferrable"), make_int_const(0, l1), l1)
	Ok(Rt.of_node($result))
}

## ViewStmt: CREATE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option
rule_1488 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1488 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.int_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ViewStmt({ ..Node.view_stmt_default, view: a4 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), view: Node.RangeVar({ ..Node.range_var_of(Node.view_stmt_of($n).view), relpersistence: a2 }) })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), aliases: a5, query: a8, replace: Bool.False, options: a6, with_check_option: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ViewStmt: CREATE OR REPLACE OptTemp VIEW qualified_name opt_column_list opt_reloptions AS SelectStmt opt_check_option
rule_1489 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1489 = |_ctx, v, _l, _loc| {
	a4 = Rt.int_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a10 = Rt.node_at(v, 9)
	a11 = Rt.int_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ViewStmt({ ..Node.view_stmt_default, view: a6 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), view: Node.RangeVar({ ..Node.range_var_of(Node.view_stmt_of($n).view), relpersistence: a4 }) })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), aliases: a7, query: a10, replace: Bool.True, options: a8, with_check_option: a11 })
	$result = $n
	Ok(Rt.of_node($result))
}

## ViewStmt: CREATE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option
rule_1490 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1490 = |ctx, v, l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.list_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.node_at(v, 10)
	a12 = Rt.int_at(v, 11)
	l12 = Rt.location(l, 11)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ViewStmt({ ..Node.view_stmt_default, view: a5 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), view: Node.RangeVar({ ..Node.range_var_of(Node.view_stmt_of($n).view), relpersistence: a2 }) })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), aliases: a7 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), query: make_recursive_view_select(Node.range_var_of(Node.view_stmt_of($n).view).relname, Node.view_stmt_of($n).aliases, a11, ctx)? })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), replace: Bool.False, options: a9, with_check_option: a12 })
	if !((Node.view_stmt_of($n).with_check_option == literal_0)) {
		return Err(Rt.error(ctx, "0A000", Ok("WITH CHECK OPTION not supported on recursive views"), l12))
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ViewStmt: CREATE OR REPLACE OptTemp RECURSIVE VIEW qualified_name '(' columnList ')' opt_reloptions AS SelectStmt opt_check_option
rule_1491 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1491 = |ctx, v, l, _loc, literal_0| {
	a4 = Rt.int_at(v, 3)
	a7 = Rt.node_at(v, 6)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	a13 = Rt.node_at(v, 12)
	a14 = Rt.int_at(v, 13)
	l14 = Rt.location(l, 13)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ViewStmt({ ..Node.view_stmt_default, view: a7 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), view: Node.RangeVar({ ..Node.range_var_of(Node.view_stmt_of($n).view), relpersistence: a4 }) })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), aliases: a9 })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), query: make_recursive_view_select(Node.range_var_of(Node.view_stmt_of($n).view).relname, Node.view_stmt_of($n).aliases, a13, ctx)? })
	$n = Node.ViewStmt({ ..Node.view_stmt_of($n), replace: Bool.True, options: a11, with_check_option: a14 })
	if !((Node.view_stmt_of($n).with_check_option == literal_0)) {
		return Err(Rt.error(ctx, "0A000", Ok("WITH CHECK OPTION not supported on recursive views"), l14))
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## LoadStmt: LOAD file_name
rule_1496 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1496 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.LoadStmt({ ..Node.load_stmt_default, filename: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreatedbStmt: CREATE DATABASE name opt_with createdb_opt_list
rule_1497 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1497 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.CreatedbStmt({ ..Node.createdb_stmt_default, dbname: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## createdb_opt_item: createdb_opt_name opt_equal opt_boolean_or_string
rule_1503 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1503 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(a1, make_string(a3), l1)
	Ok(Rt.of_node($result))
}

## createdb_opt_name: CONNECTION LIMIT
rule_1506 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1506 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("connection_limit")
	Ok(Rt.of_text($result))
}

## AlterDatabaseStmt: ALTER DATABASE name WITH createdb_opt_list
rule_1514 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1514 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDatabaseStmt({ ..Node.alter_database_stmt_default, dbname: a3, options: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDatabaseStmt: ALTER DATABASE name createdb_opt_list
rule_1515 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1515 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDatabaseStmt({ ..Node.alter_database_stmt_default, dbname: a3, options: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDatabaseStmt: ALTER DATABASE name SET TABLESPACE name
rule_1516 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1516 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.text_at(v, 5)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterDatabaseStmt({ ..Node.alter_database_stmt_default, dbname: a3 })
	$n = Node.AlterDatabaseStmt({ ..Node.alter_database_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("tablespace"), make_string(a6), l6)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterDatabaseStmt: ALTER DATABASE name REFRESH COLLATION VERSION_P
rule_1517 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1517 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDatabaseRefreshCollStmt({ ..Node.alter_database_refresh_coll_stmt_default, dbname: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDatabaseSetStmt: ALTER DATABASE name SetResetClause
rule_1518 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1518 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDatabaseSetStmt({ ..Node.alter_database_set_stmt_default, dbname: a3, setstmt: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropdbStmt: DROP DATABASE name
rule_1519 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1519 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.DropdbStmt({ ..Node.dropdb_stmt_default, dbname: a3, missing_ok: Bool.False, options: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## DropdbStmt: DROP DATABASE IF_P EXISTS name
rule_1520 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1520 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.DropdbStmt({ ..Node.dropdb_stmt_default, dbname: a5, missing_ok: Bool.True, options: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## DropdbStmt: DROP DATABASE name opt_with '(' drop_option_list ')'
rule_1521 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1521 = |_ctx, v, _l, _loc| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.DropdbStmt({ ..Node.dropdb_stmt_default, dbname: a3, missing_ok: Bool.False, options: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## DropdbStmt: DROP DATABASE IF_P EXISTS name opt_with '(' drop_option_list ')'
rule_1522 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1522 = |_ctx, v, _l, _loc| {
	a5 = Rt.text_at(v, 4)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.DropdbStmt({ ..Node.dropdb_stmt_default, dbname: a5, missing_ok: Bool.True, options: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## drop_option: FORCE
rule_1525 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1525 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("force"), Null, l1)
	Ok(Rt.of_node($result))
}

## AlterCollationStmt: ALTER COLLATION any_name REFRESH VERSION_P
rule_1526 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1526 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterCollationStmt({ ..Node.alter_collation_stmt_default, collname: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterSystemStmt: ALTER SYSTEM_P SET generic_set
rule_1527 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1527 = |_ctx, v, _l, _loc| {
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterSystemStmt({ ..Node.alter_system_stmt_default, setstmt: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateDomainStmt: CREATE DOMAIN_P any_name opt_as Typename ColQualList
rule_1529 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1529 = |ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CreateDomainStmt({ ..Node.create_domain_stmt_default, domainname: a3, type_name: a5 })
	written = split_col_qual_list(a6, Bool.True, Bool.True, ctx)?
	$n = Node.CreateDomainStmt({ ..Node.create_domain_stmt_of($n), constraints: written.a1 })
	$n = Node.CreateDomainStmt({ ..Node.create_domain_stmt_of($n), coll_clause: written.a2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name alter_column_default
rule_1530 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1530 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3, def: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name DROP NOT NULL_P
rule_1531 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1531 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name ADD_P DomainConstraint
rule_1533 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1533 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3, def: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name DROP CONSTRAINT name opt_drop_behavior
rule_1534 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1534 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	a7 = Rt.int_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3, name: a6, behavior: a7, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name DROP CONSTRAINT IF_P EXISTS name opt_drop_behavior
rule_1535 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1535 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a8 = Rt.text_at(v, 7)
	a9 = Rt.int_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3, name: a8, behavior: a9, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterDomainStmt: ALTER DOMAIN_P any_name VALIDATE CONSTRAINT name
rule_1536 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1536 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterDomainStmt({ ..Node.alter_domain_stmt_default, subtype: literal_0, type_name: a3, name: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTSDictionaryStmt: ALTER TEXT_P SEARCH DICTIONARY any_name definition
rule_1539 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1539 = |_ctx, v, _l, _loc| {
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTSDictionaryStmt({ ..Node.alter_ts_dictionary_stmt_default, dictname: a5, options: a6 })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ADD_P MAPPING FOR name_list any_with any_name_list
rule_1540 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1540 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: a9, dicts: a11, override: Bool.False, replace: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list any_with any_name_list
rule_1541 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1541 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: a9, dicts: a11, override: Bool.True, replace: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING REPLACE any_name any_with any_name
rule_1542 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1542 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: [] })
	$n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_of($n), dicts: Rt.list_make2(Rt.list_node(a9), Rt.list_node(a11)) })
	$n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_of($n), override: Bool.False, replace: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name ALTER MAPPING FOR name_list REPLACE any_name any_with any_name
rule_1543 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1543 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	a11 = Rt.list_at(v, 10)
	a13 = Rt.list_at(v, 12)
	var $result = Rt.node_at(v, 0)
	var $n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: a9 })
	$n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_of($n), dicts: Rt.list_make2(Rt.list_node(a11), Rt.list_node(a13)) })
	$n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_of($n), override: Bool.False, replace: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING FOR name_list
rule_1544 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1544 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a9 = Rt.list_at(v, 8)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: a9, missing_ok: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## AlterTSConfigurationStmt: ALTER TEXT_P SEARCH CONFIGURATION any_name DROP MAPPING IF_P EXISTS FOR name_list
rule_1545 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1545 = |_ctx, v, _l, _loc, literal_0| {
	a5 = Rt.list_at(v, 4)
	a11 = Rt.list_at(v, 10)
	var $result = Rt.node_at(v, 0)
	n = Node.AlterTSConfigurationStmt({ ..Node.alter_ts_configuration_stmt_default, kind: literal_0, cfgname: a5, tokentype: a11, missing_ok: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## CreateConversionStmt: CREATE opt_default CONVERSION_P any_name FOR Sconst TO Sconst FROM any_name
rule_1548 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1548 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	a8 = Rt.text_at(v, 7)
	a10 = Rt.list_at(v, 9)
	var $result = Rt.node_at(v, 0)
	n = Node.CreateConversionStmt({ ..Node.create_conversion_stmt_default, conversion_name: a4, for_encoding_name: a6, to_encoding_name: a8, func_name: a10, def: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## ClusterStmt: CLUSTER '(' utility_option_list ')' qualified_name cluster_index_specification
rule_1549 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1549 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.text_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.ClusterStmt({ ..Node.cluster_stmt_default, relation: a5, indexname: a6, params: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## ClusterStmt: CLUSTER '(' utility_option_list ')'
rule_1550 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1550 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.ClusterStmt({ ..Node.cluster_stmt_default, relation: Null, indexname: Err(Null), params: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## ClusterStmt: CLUSTER opt_verbose qualified_name cluster_index_specification
rule_1551 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1551 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.text_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ClusterStmt({ ..Node.cluster_stmt_default, relation: a3, indexname: a4, params: [] })
	if a2 {
		$n = Node.ClusterStmt({ ..Node.cluster_stmt_of($n), params: Rt.lappend(Node.cluster_stmt_of($n).params, make_def_elem(Ok("verbose"), Null, l2)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ClusterStmt: CLUSTER opt_verbose
rule_1552 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1552 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ClusterStmt({ ..Node.cluster_stmt_default, relation: Null, indexname: Err(Null), params: [] })
	if a2 {
		$n = Node.ClusterStmt({ ..Node.cluster_stmt_of($n), params: Rt.lappend(Node.cluster_stmt_of($n).params, make_def_elem(Ok("verbose"), Null, l2)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ClusterStmt: CLUSTER opt_verbose name ON qualified_name
rule_1553 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1553 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.text_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ClusterStmt({ ..Node.cluster_stmt_default, relation: a5, indexname: a3, params: [] })
	if a2 {
		$n = Node.ClusterStmt({ ..Node.cluster_stmt_of($n), params: Rt.lappend(Node.cluster_stmt_of($n).params, make_def_elem(Ok("verbose"), Null, l2)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## VacuumStmt: VACUUM opt_full opt_freeze opt_verbose opt_analyze opt_vacuum_relation_list
rule_1556 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1556 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.bool_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a6 = Rt.list_at(v, 5)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	l4 = Rt.location(l, 3)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VacuumStmt({ ..Node.vacuum_stmt_default, options: [] })
	if a2 {
		$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), options: Rt.lappend(Node.vacuum_stmt_of($n).options, make_def_elem(Ok("full"), Null, l2)) })
	}
	if a3 {
		$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), options: Rt.lappend(Node.vacuum_stmt_of($n).options, make_def_elem(Ok("freeze"), Null, l3)) })
	}
	if a4 {
		$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), options: Rt.lappend(Node.vacuum_stmt_of($n).options, make_def_elem(Ok("verbose"), Null, l4)) })
	}
	if a5 {
		$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), options: Rt.lappend(Node.vacuum_stmt_of($n).options, make_def_elem(Ok("analyze"), Null, l5)) })
	}
	$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), rels: a6, is_vacuumcmd: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## VacuumStmt: VACUUM '(' utility_option_list ')' opt_vacuum_relation_list
rule_1557 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1557 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.VacuumStmt({ ..Node.vacuum_stmt_default, options: a3, rels: a5, is_vacuumcmd: Bool.True })
	$result = n
	Ok(Rt.of_node($result))
}

## AnalyzeStmt: analyze_keyword opt_verbose opt_vacuum_relation_list
rule_1558 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1558 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.VacuumStmt({ ..Node.vacuum_stmt_default, options: [] })
	if a2 {
		$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), options: Rt.lappend(Node.vacuum_stmt_of($n).options, make_def_elem(Ok("verbose"), Null, l2)) })
	}
	$n = Node.VacuumStmt({ ..Node.vacuum_stmt_of($n), rels: a3, is_vacuumcmd: Bool.False })
	$result = $n
	Ok(Rt.of_node($result))
}

## AnalyzeStmt: analyze_keyword '(' utility_option_list ')' opt_vacuum_relation_list
rule_1559 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1559 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.VacuumStmt({ ..Node.vacuum_stmt_default, options: a3, rels: a5, is_vacuumcmd: Bool.False })
	$result = n
	Ok(Rt.of_node($result))
}

## utility_option_name: analyze_keyword
rule_1566 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1566 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("analyze")
	Ok(Rt.of_text($result))
}

## utility_option_name: FORMAT_LA
rule_1567 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1567 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("format")
	Ok(Rt.of_text($result))
}

## vacuum_relation: relation_expr opt_name_list
rule_1581 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1581 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_vacuum_relation(a1, literal_0, a2)
	Ok(Rt.of_node($result))
}

## ExplainStmt: EXPLAIN ExplainableStmt
rule_1586 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1586 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.ExplainStmt({ ..Node.explain_stmt_default, query: a2, options: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## ExplainStmt: EXPLAIN analyze_keyword opt_verbose ExplainableStmt
rule_1587 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1587 = |_ctx, v, l, _loc| {
	a3 = Rt.bool_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ExplainStmt({ ..Node.explain_stmt_default, query: a4 })
	$n = Node.ExplainStmt({ ..Node.explain_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("analyze"), Null, l2)) })
	if a3 {
		$n = Node.ExplainStmt({ ..Node.explain_stmt_of($n), options: Rt.lappend(Node.explain_stmt_of($n).options, make_def_elem(Ok("verbose"), Null, l3)) })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## ExplainStmt: EXPLAIN VERBOSE ExplainableStmt
rule_1588 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1588 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ExplainStmt({ ..Node.explain_stmt_default, query: a3 })
	$n = Node.ExplainStmt({ ..Node.explain_stmt_of($n), options: Rt.list_make1(make_def_elem(Ok("verbose"), Null, l2)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## ExplainStmt: EXPLAIN '(' utility_option_list ')' ExplainableStmt
rule_1589 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1589 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.ExplainStmt({ ..Node.explain_stmt_default, query: a5, options: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## PrepareStmt: PREPARE name prep_type_clause AS PreparableStmt
rule_1600 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1600 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.PrepareStmt({ ..Node.prepare_stmt_default, name: a2, argtypes: a3, query: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## ExecuteStmt: EXECUTE name execute_param_clause
rule_1608 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1608 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.ExecuteStmt({ ..Node.execute_stmt_default, name: a2, params: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## ExecuteStmt: CREATE OptTemp TABLE create_as_target AS EXECUTE name execute_param_clause opt_with_data
rule_1609 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1609 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	a7 = Rt.text_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.bool_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt(Node.create_table_as_stmt_default)
	n = Node.ExecuteStmt({ ..Node.execute_stmt_default, name: a7, params: a8 })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), query: n })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a4, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.False })
	$a4 = Node.IntoClause({ ..Node.into_clause_of($a4), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a4).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a4 })
	$a4 = Node.IntoClause({ ..Node.into_clause_of($a4), skip_data: !(a9) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a4 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## ExecuteStmt: CREATE OptTemp TABLE IF_P NOT EXISTS create_as_target AS EXECUTE name execute_param_clause opt_with_data
rule_1610 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1610 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.int_at(v, 1)
	var $a7 = Rt.node_at(v, 6)
	a10 = Rt.text_at(v, 9)
	a11 = Rt.list_at(v, 10)
	a12 = Rt.bool_at(v, 11)
	var $result = Rt.node_at(v, 0)
	var $ctas = Node.CreateTableAsStmt(Node.create_table_as_stmt_default)
	n = Node.ExecuteStmt({ ..Node.execute_stmt_default, name: a10, params: a11 })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), query: n })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a7, objtype: literal_0, is_select_into: Bool.False, if_not_exists: Bool.True })
	$a7 = Node.IntoClause({ ..Node.into_clause_of($a7), rel: Node.RangeVar({ ..Node.range_var_of(Node.into_clause_of($a7).rel), relpersistence: a2 }) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a7 })
	$a7 = Node.IntoClause({ ..Node.into_clause_of($a7), skip_data: !(a12) })
	$ctas = Node.CreateTableAsStmt({ ..Node.create_table_as_stmt_of($ctas), into: $a7 })
	$result = $ctas
	Ok(Rt.of_node($result))
}

## DeallocateStmt: DEALLOCATE name
rule_1613 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1613 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.DeallocateStmt({ ..Node.deallocate_stmt_default, name: a2, isall: Bool.False, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## DeallocateStmt: DEALLOCATE PREPARE name
rule_1614 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1614 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.DeallocateStmt({ ..Node.deallocate_stmt_default, name: a3, isall: Bool.False, location: l3 })
	$result = n
	Ok(Rt.of_node($result))
}

## DeallocateStmt: DEALLOCATE ALL
rule_1615 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1615 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	var $n = Node.DeallocateStmt({ ..Node.deallocate_stmt_default, name: Err(Null), isall: Bool.True })
	$n = Node.DeallocateStmt({ ..Node.deallocate_stmt_of($n), location: (0 - literal_0) })
	$result = $n
	Ok(Rt.of_node($result))
}

## InsertStmt: opt_with_clause INSERT INTO insert_target insert_rest opt_on_conflict returning_clause
rule_1617 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1617 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	var $a5 = Rt.node_at(v, 4)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	$a5 = Node.InsertStmt({ ..Node.insert_stmt_of($a5), relation: a4, on_conflict_clause: a6, returning_clause: a7, with_clause: a1 })
	$result = $a5
	Ok(Rt.of_node($result))
}

## insert_target: qualified_name AS ColId
rule_1619 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1619 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$a1 = Node.RangeVar({ ..Node.range_var_of($a1), alias: make_alias(a3, []) })
	$result = $a1
	Ok(Rt.of_node($result))
}

## insert_rest: SelectStmt
rule_1620 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1620 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.InsertStmt(Node.insert_stmt_default)
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), cols: [] })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), select_stmt: a1 })
	Ok(Rt.of_node($result))
}

## insert_rest: OVERRIDING override_kind VALUE_P SelectStmt
rule_1621 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1621 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.InsertStmt(Node.insert_stmt_default)
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), cols: [] })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), override: a2 })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), select_stmt: a4 })
	Ok(Rt.of_node($result))
}

## insert_rest: '(' insert_column_list ')' SelectStmt
rule_1622 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1622 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.InsertStmt(Node.insert_stmt_default)
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), cols: a2 })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), select_stmt: a4 })
	Ok(Rt.of_node($result))
}

## insert_rest: '(' insert_column_list ')' OVERRIDING override_kind VALUE_P SelectStmt
rule_1623 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1623 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a5 = Rt.int_at(v, 4)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	$result = Node.InsertStmt(Node.insert_stmt_default)
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), cols: a2 })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), override: a5 })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), select_stmt: a7 })
	Ok(Rt.of_node($result))
}

## insert_rest: DEFAULT VALUES
rule_1624 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1624 = |_ctx, v, _l, _loc| {
	var $result = Rt.node_at(v, 0)
	$result = Node.InsertStmt(Node.insert_stmt_default)
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), cols: [] })
	$result = Node.InsertStmt({ ..Node.insert_stmt_of($result), select_stmt: Null })
	Ok(Rt.of_node($result))
}

## insert_column_item: ColId opt_indirection
rule_1629 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1629 = |ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: a1 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: check_indirection(a2, ctx)? })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: Null })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_on_conflict: ON CONFLICT opt_conf_expr DO UPDATE SET set_clause_list where_clause
rule_1630 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1630 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.node_at(v, 7)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.OnConflictClause(Node.on_conflict_clause_default)
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), action: literal_0 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), infer: a3 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), target_list: a7 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), where_clause: a8 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_on_conflict: ON CONFLICT opt_conf_expr DO NOTHING
rule_1631 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1631 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.OnConflictClause(Node.on_conflict_clause_default)
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), action: literal_0 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), infer: a3 })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), target_list: [] })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), where_clause: Null })
	$result = Node.OnConflictClause({ ..Node.on_conflict_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_conf_expr: '(' index_params ')' where_clause
rule_1633 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1633 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.InferClause(Node.infer_clause_default)
	$result = Node.InferClause({ ..Node.infer_clause_of($result), index_elems: a2 })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), where_clause: a4 })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), conname: Err(Null) })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_conf_expr: ON CONSTRAINT name
rule_1634 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1634 = |_ctx, v, l, _loc| {
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.InferClause(Node.infer_clause_default)
	$result = Node.InferClause({ ..Node.infer_clause_of($result), index_elems: [] })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), where_clause: Null })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), conname: a3 })
	$result = Node.InferClause({ ..Node.infer_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## returning_clause: RETURNING returning_with_clause target_list
rule_1636 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1636 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.ReturningClause({ ..Node.returning_clause_default, options: a2, exprs: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## returning_option: returning_option_kind AS ColId
rule_1642 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1642 = |_ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.ReturningOption({ ..Node.returning_option_default, option: a1, value: a3, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## DeleteStmt: opt_with_clause DELETE_P FROM relation_expr_opt_alias using_clause where_or_current_clause returning_clause
rule_1645 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1645 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	n = Node.DeleteStmt({ ..Node.delete_stmt_default, relation: a4, using_clause: a5, where_clause: a6, returning_clause: a7, with_clause: a1 })
	$result = n
	Ok(Rt.of_node($result))
}

## LockStmt: LOCK_P opt_table relation_expr_list opt_lock opt_nowait
rule_1648 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1648 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.LockStmt({ ..Node.lock_stmt_default, relations: a3, mode: a4, nowait: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## opt_lock: IN_P lock_type MODE
rule_1649 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1649 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $result = Rt.int_at(v, 0)
	$result = a2
	Ok(Rt.of_int($result))
}

## UpdateStmt: opt_with_clause UPDATE relation_expr_opt_alias SET set_clause_list from_clause where_or_current_clause returning_clause
rule_1664 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1664 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.node_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.UpdateStmt({ ..Node.update_stmt_default, relation: a3, target_list: a5, from_clause: a6, where_clause: a7, returning_clause: a8, with_clause: a1 })
	$result = n
	Ok(Rt.of_node($result))
}

## set_clause_list: set_clause_list ',' set_clause
rule_1666 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1666 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_concat(a1, a3)
	Ok(Rt.of_list($result))
}

## set_clause: set_target '=' a_expr
rule_1667 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1667 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$a1 = Node.ResTarget({ ..Node.res_target_of($a1), val: a3 })
	$result = Rt.list_make1($a1)
	Ok(Rt.of_list($result))
}

## set_clause: '(' set_target_list ')' '=' a_expr
rule_1668 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1668 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a2 = Rt.list_at(v, 1)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	ncolumns_local = Rt.list_length($a2)
	var $i = literal_0
	col_cell_list = $a2
	var $col_cell_index = 0
	while $col_cell_index < col_cell_list.len() {
		var $res_col = (col_cell_list.get($col_cell_index) ?? Null)
		var $r = Node.MultiAssignRef(Node.multi_assign_ref_default)
		$r = Node.MultiAssignRef({ ..Node.multi_assign_ref_of($r), source: a5 })
		$r = Node.MultiAssignRef({ ..Node.multi_assign_ref_of($r), colno: $i, ncolumns: ncolumns_local })
		$res_col = Node.ResTarget({ ..Node.res_target_of($res_col), val: $r })
		$a2 = Rt.list_set($a2, $col_cell_index, $res_col)
		$i = ($i + literal_1)
		$col_cell_index = $col_cell_index + 1
	}
	$result = $a2
	Ok(Rt.of_list($result))
}

## MergeStmt: opt_with_clause MERGE INTO relation_expr_opt_alias USING table_ref ON a_expr merge_when_list returning_clause
rule_1672 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1672 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	a10 = Rt.node_at(v, 9)
	var $result = Rt.node_at(v, 0)
	m = Node.MergeStmt({ ..Node.merge_stmt_default, with_clause: a1, relation: a4, source_relation: a6, join_condition: a8, merge_when_clauses: a9, returning_clause: a10 })
	$result = m
	Ok(Rt.of_node($result))
}

## merge_when_clause: merge_when_tgt_matched opt_merge_when_condition THEN merge_update
rule_1675 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1675 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$a4 = Node.MergeWhenClause({ ..Node.merge_when_clause_of($a4), match_kind: a1, condition: a2 })
	$result = $a4
	Ok(Rt.of_node($result))
}

## merge_when_clause: merge_when_tgt_matched opt_merge_when_condition THEN DO NOTHING
rule_1678 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1678 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	m = Node.MergeWhenClause({ ..Node.merge_when_clause_default, match_kind: a1, command_type: literal_0, condition: a2 })
	$result = m
	Ok(Rt.of_node($result))
}

## merge_update: UPDATE SET set_clause_list
rule_1686 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1686 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: literal_1, target_list: a3, values: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## merge_delete: DELETE_P
rule_1687 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1687 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: literal_1, target_list: [], values: [] })
	$result = n
	Ok(Rt.of_node($result))
}

## merge_insert: INSERT merge_values_clause
rule_1688 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1688 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: literal_1, target_list: [], values: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## merge_insert: INSERT OVERRIDING override_kind VALUE_P merge_values_clause
rule_1689 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1689 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.int_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: a3, target_list: [], values: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## merge_insert: INSERT '(' insert_column_list ')' merge_values_clause
rule_1690 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1690 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: literal_1, target_list: a3, values: a5 })
	$result = n
	Ok(Rt.of_node($result))
}

## merge_insert: INSERT '(' insert_column_list ')' OVERRIDING override_kind VALUE_P merge_values_clause
rule_1691 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1691 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	a6 = Rt.int_at(v, 5)
	a8 = Rt.list_at(v, 7)
	var $result = Rt.node_at(v, 0)
	n = Node.MergeWhenClause({ ..Node.merge_when_clause_default, command_type: literal_0, override: a6, target_list: a3, values: a8 })
	$result = n
	Ok(Rt.of_node($result))
}

## DeclareCursorStmt: DECLARE cursor_name cursor_options CURSOR opt_hold FOR SelectStmt
rule_1694 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1694 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a5 = Rt.int_at(v, 4)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.node_at(v, 0)
	var $n = Node.DeclareCursorStmt({ ..Node.declare_cursor_stmt_default, portalname: a2 })
	$n = Node.DeclareCursorStmt({ ..Node.declare_cursor_stmt_of($n), options: Rt.bit_or(Rt.bit_or(a3, a5), literal_0) })
	$n = Node.DeclareCursorStmt({ ..Node.declare_cursor_stmt_of($n), query: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## cursor_options: cursor_options NO SCROLL
rule_1697 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1697 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.int_at(v, 0)
	var $result = Rt.int_at(v, 0)
	$result = Rt.bit_or(a1, literal_0)
	Ok(Rt.of_int($result))
}

## select_no_parens: select_clause sort_clause
rule_1710 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1710 = |ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a1, a2, [], Null, Null, ctx)?
	$a1 = written.a0
	$result = $a1
	Ok(Rt.of_node($result))
}

## select_no_parens: select_clause opt_sort_clause for_locking_clause opt_select_limit
rule_1711 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1711 = |ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a1, a2, a3, a4, Null, ctx)?
	$a1 = written.a0
	$result = $a1
	Ok(Rt.of_node($result))
}

## select_no_parens: select_clause opt_sort_clause select_limit opt_for_locking_clause
rule_1712 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1712 = |ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a1, a2, a4, a3, Null, ctx)?
	$a1 = written.a0
	$result = $a1
	Ok(Rt.of_node($result))
}

## select_no_parens: with_clause select_clause
rule_1713 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1713 = |ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a2, [], [], Null, a1, ctx)?
	$a2 = written.a0
	$result = $a2
	Ok(Rt.of_node($result))
}

## select_no_parens: with_clause select_clause sort_clause
rule_1714 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1714 = |ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a2, a3, [], Null, a1, ctx)?
	$a2 = written.a0
	$result = $a2
	Ok(Rt.of_node($result))
}

## select_no_parens: with_clause select_clause opt_sort_clause for_locking_clause opt_select_limit
rule_1715 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1715 = |ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a2, a3, a4, a5, a1, ctx)?
	$a2 = written.a0
	$result = $a2
	Ok(Rt.of_node($result))
}

## select_no_parens: with_clause select_clause opt_sort_clause select_limit opt_for_locking_clause
rule_1716 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1716 = |ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	var $result = Rt.node_at(v, 0)
	written = insert_select_options($a2, a3, a5, a4, a1, ctx)?
	$a2 = written.a0
	$result = $a2
	Ok(Rt.of_node($result))
}

## simple_select: SELECT opt_all_clause opt_target_list into_clause from_clause where_clause group_clause having_clause window_clause
rule_1719 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1719 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectStmt({ ..Node.select_stmt_default, target_list: a3, into_clause: a4, from_clause: a5, where_clause: a6 })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_clause: Node.group_clause_of(a7).list })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_distinct: Node.group_clause_of(a7).distinct })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), having_clause: a8, window_clause: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## simple_select: SELECT distinct_clause target_list into_clause from_clause where_clause group_clause having_clause window_clause
rule_1720 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1720 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.list_at(v, 8)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectStmt({ ..Node.select_stmt_default, distinct_clause: a2, target_list: a3, into_clause: a4, from_clause: a5, where_clause: a6 })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_clause: Node.group_clause_of(a7).list })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_distinct: Node.group_clause_of(a7).distinct })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), having_clause: a8, window_clause: a9 })
	$result = $n
	Ok(Rt.of_node($result))
}

## simple_select: TABLE relation_expr
rule_1722 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1722 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $cr = Node.ColumnRef(Node.column_ref_default)
	var $rt = Node.ResTarget(Node.res_target_default)
	var $n = Node.SelectStmt(Node.select_stmt_default)
	$cr = Node.ColumnRef({ ..Node.column_ref_of($cr), fields: Rt.list_make1(Node.AStar(Node.a_star_default)) })
	$cr = Node.ColumnRef({ ..Node.column_ref_of($cr), location: (0 - literal_0) })
	$rt = Node.ResTarget({ ..Node.res_target_of($rt), name: Err(Null), indirection: [] })
	$rt = Node.ResTarget({ ..Node.res_target_of($rt), val: $cr })
	$rt = Node.ResTarget({ ..Node.res_target_of($rt), location: (0 - literal_1) })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), target_list: Rt.list_make1($rt) })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), from_clause: Rt.list_make1(a2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## simple_select: select_clause UNION set_quantifier select_clause
rule_1723 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1723 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = make_set_op(literal_0, (a3 == literal_1), a1, a4)
	Ok(Rt.of_node($result))
}

## with_clause: WITH cte_list
rule_1726 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1726 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.WithClause(Node.with_clause_default)
	$result = Node.WithClause({ ..Node.with_clause_of($result), ctes: a2 })
	$result = Node.WithClause({ ..Node.with_clause_of($result), recursive: Bool.False })
	$result = Node.WithClause({ ..Node.with_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## with_clause: WITH RECURSIVE cte_list
rule_1728 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1728 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.WithClause(Node.with_clause_default)
	$result = Node.WithClause({ ..Node.with_clause_of($result), ctes: a3 })
	$result = Node.WithClause({ ..Node.with_clause_of($result), recursive: Bool.True })
	$result = Node.WithClause({ ..Node.with_clause_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## common_table_expr: name opt_name_list AS opt_materialized '(' PreparableStmt ')' opt_search_clause opt_cycle_clause
rule_1731 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1731 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a4 = Rt.int_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.node_at(v, 8)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CommonTableExpr({ ..Node.common_table_expr_default, ctename: a1, aliascolnames: a2, ctematerialized: a4, ctequery: a6 })
	$n = Node.CommonTableExpr({ ..Node.common_table_expr_of($n), search_clause: a8 })
	$n = Node.CommonTableExpr({ ..Node.common_table_expr_of($n), cycle_clause: a9 })
	$n = Node.CommonTableExpr({ ..Node.common_table_expr_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_search_clause: SEARCH DEPTH FIRST_P BY columnList SET ColId
rule_1735 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1735 = |_ctx, v, l, _loc| {
	a5 = Rt.list_at(v, 4)
	a7 = Rt.text_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.CTESearchClause({ ..Node.cte_search_clause_default, search_col_list: a5, search_breadth_first: Bool.False, search_seq_column: a7, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## opt_search_clause: SEARCH BREADTH FIRST_P BY columnList SET ColId
rule_1736 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1736 = |_ctx, v, l, _loc| {
	a5 = Rt.list_at(v, 4)
	a7 = Rt.text_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.CTESearchClause({ ..Node.cte_search_clause_default, search_col_list: a5, search_breadth_first: Bool.True, search_seq_column: a7, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## opt_cycle_clause: CYCLE columnList SET ColId TO AexprConst DEFAULT AexprConst USING ColId
rule_1738 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1738 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.text_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a8 = Rt.node_at(v, 7)
	a10 = Rt.text_at(v, 9)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.CTECycleClause({ ..Node.cte_cycle_clause_default, cycle_col_list: a2, cycle_mark_column: a4, cycle_mark_value: a6, cycle_mark_default: a8, cycle_path_column: a10, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## opt_cycle_clause: CYCLE columnList SET ColId USING ColId
rule_1739 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1739 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.text_at(v, 3)
	a6 = Rt.text_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.CTECycleClause({ ..Node.cte_cycle_clause_default, cycle_col_list: a2, cycle_mark_column: a4 })
	$n = Node.CTECycleClause({ ..Node.cte_cycle_clause_of($n), cycle_mark_value: make_bool_a_const(Bool.True, (0 - literal_0)) })
	$n = Node.CTECycleClause({ ..Node.cte_cycle_clause_of($n), cycle_mark_default: make_bool_a_const(Bool.False, (0 - literal_1)) })
	$n = Node.CTECycleClause({ ..Node.cte_cycle_clause_of($n), cycle_path_column: a6, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## into_clause: INTO OptTempTableName
rule_1743 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1743 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = Node.IntoClause(Node.into_clause_default)
	$result = Node.IntoClause({ ..Node.into_clause_of($result), rel: a2 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), col_names: [] })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), options: [] })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), on_commit: literal_0 })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), table_space_name: Err(Null) })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), view_query: Null })
	$result = Node.IntoClause({ ..Node.into_clause_of($result), skip_data: Bool.False })
	Ok(Rt.of_node($result))
}

## OptTempTableName: TEMPORARY opt_table qualified_name
rule_1745 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1745 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = a3
	$result = Node.RangeVar({ ..Node.range_var_of($result), relpersistence: literal_0 })
	Ok(Rt.of_node($result))
}

## OptTempTableName: LOCAL TEMPORARY opt_table qualified_name
rule_1747 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1747 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = a4
	$result = Node.RangeVar({ ..Node.range_var_of($result), relpersistence: literal_0 })
	Ok(Rt.of_node($result))
}

## OptTempTableName: TABLE qualified_name
rule_1752 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1752 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.RangeVar({ ..Node.range_var_of($result), relpersistence: literal_0 })
	Ok(Rt.of_node($result))
}

## OptTempTableName: qualified_name
rule_1753 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1753 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.RangeVar({ ..Node.range_var_of($result), relpersistence: literal_0 })
	Ok(Rt.of_node($result))
}

## distinct_clause: DISTINCT
rule_1759 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1759 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(Null)
	Ok(Rt.of_list($result))
}

## sortby: a_expr USING qual_all_Op opt_nulls_order
rule_1770 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1770 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.int_at(v, 3)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = Node.SortBy(Node.sort_by_default)
	$result = Node.SortBy({ ..Node.sort_by_of($result), node: a1 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), sortby_dir: literal_0 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), sortby_nulls: a4 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), use_op: a3 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), location: l3 })
	Ok(Rt.of_node($result))
}

## sortby: a_expr opt_asc_desc opt_nulls_order
rule_1771 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1771 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.int_at(v, 1)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = Node.SortBy(Node.sort_by_default)
	$result = Node.SortBy({ ..Node.sort_by_of($result), node: a1 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), sortby_dir: a2 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), sortby_nulls: a3 })
	$result = Node.SortBy({ ..Node.sort_by_of($result), use_op: [] })
	$result = Node.SortBy({ ..Node.sort_by_of($result), location: (0 - literal_0) })
	Ok(Rt.of_node($result))
}

## select_limit: limit_clause offset_clause
rule_1772 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1772 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.SelectLimit({ ..Node.select_limit_of($result), limit_offset: a2 })
	$result = Node.SelectLimit({ ..Node.select_limit_of($result), offset_loc: l2 })
	Ok(Rt.of_node($result))
}

## select_limit: offset_clause limit_clause
rule_1773 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1773 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.SelectLimit({ ..Node.select_limit_of($result), limit_offset: a1 })
	$result = Node.SelectLimit({ ..Node.select_limit_of($result), offset_loc: l1 })
	Ok(Rt.of_node($result))
}

## select_limit: offset_clause
rule_1775 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1775 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: a1, limit_count: Null, limit_option: literal_0, offset_loc: l1 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: (0 - literal_1) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), option_loc: (0 - literal_2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## limit_clause: LIMIT select_limit_value
rule_1778 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1778 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: Null, limit_count: a2, limit_option: literal_0 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), offset_loc: (0 - literal_1) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: l1 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), option_loc: (0 - literal_2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## limit_clause: LIMIT select_limit_value ',' select_offset_value
rule_1779 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1779 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "42601", Ok("LIMIT #,# syntax is not supported"), l1))
}

## limit_clause: FETCH first_or_next select_fetch_first_value row_or_rows ONLY
rule_1780 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1780 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: Null, limit_count: a3, limit_option: literal_0 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), offset_loc: (0 - literal_1) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: l1 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), option_loc: (0 - literal_2) })
	$result = $n
	Ok(Rt.of_node($result))
}

## limit_clause: FETCH first_or_next select_fetch_first_value row_or_rows WITH TIES
rule_1781 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1781 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: Null, limit_count: a3, limit_option: literal_0 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), offset_loc: (0 - literal_1) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: l1, option_loc: l5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## limit_clause: FETCH first_or_next row_or_rows ONLY
rule_1782 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1782 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: Null })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_count: make_int_const(literal_0, (0 - literal_1)) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_option: literal_2 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), offset_loc: (0 - literal_3) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: l1 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), option_loc: (0 - literal_4) })
	$result = $n
	Ok(Rt.of_node($result))
}

## limit_clause: FETCH first_or_next row_or_rows WITH TIES
rule_1783 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1783 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3| {
	l1 = Rt.location(l, 0)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectLimit(Node.select_limit_default)
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_offset: Null })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_count: make_int_const(literal_0, (0 - literal_1)) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), limit_option: literal_2 })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), offset_loc: (0 - literal_3) })
	$n = Node.SelectLimit({ ..Node.select_limit_of($n), count_loc: l1, option_loc: l4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## select_limit_value: ALL
rule_1787 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1787 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_null_a_const(l1)
	Ok(Rt.of_node($result))
}

## select_fetch_first_value: '+' I_or_F_const
rule_1790 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1790 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("+"), Null, a2, l1)
	Ok(Rt.of_node($result))
}

## select_fetch_first_value: '-' I_or_F_const
rule_1791 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1791 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = do_negate(a2, l1)
	Ok(Rt.of_node($result))
}

## I_or_F_const: Iconst
rule_1792 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1792 = |_ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_int_const(a1, l1)
	Ok(Rt.of_node($result))
}

## I_or_F_const: FCONST
rule_1793 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1793 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_float_const(a1, l1)
	Ok(Rt.of_node($result))
}

## group_clause: GROUP_P BY set_quantifier group_by_list
rule_1798 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1798 = |_ctx, v, _l, _loc, literal_0| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.GroupClause(Node.group_clause_default)
	$n = Node.GroupClause({ ..Node.group_clause_of($n), distinct: (a3 == literal_0) })
	$n = Node.GroupClause({ ..Node.group_clause_of($n), list: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## group_clause: %empty
rule_1799 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1799 = |_ctx, _v, _l, _loc| {
	var $result = Null
	var $n = Node.GroupClause(Node.group_clause_default)
	$n = Node.GroupClause({ ..Node.group_clause_of($n), distinct: Bool.False, list: [] })
	$result = $n
	Ok(Rt.of_node($result))
}

## empty_grouping_set: '(' ')'
rule_1807 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1807 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_grouping_set(literal_0, [], l1)
	Ok(Rt.of_node($result))
}

## rollup_clause: ROLLUP '(' expr_list ')'
rule_1808 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1808 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_grouping_set(literal_0, a3, l1)
	Ok(Rt.of_node($result))
}

## grouping_sets_clause: GROUPING SETS '(' group_by_list ')'
rule_1810 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1810 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_grouping_set(literal_0, a4, l1)
	Ok(Rt.of_node($result))
}

## for_locking_item: for_locking_strength locked_rels_list opt_nowait_or_skip
rule_1819 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1819 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.LockingClause({ ..Node.locking_clause_default, locked_rels: a2, strength: a1, wait_policy: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## values_clause: VALUES '(' expr_list ')'
rule_1826 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1826 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectStmt(Node.select_stmt_default)
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), values_lists: Rt.list_make1(Rt.list_node(a3)) })
	$result = $n
	Ok(Rt.of_node($result))
}

## values_clause: values_clause ',' '(' expr_list ')'
rule_1827 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1827 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = $a1
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), values_lists: Rt.lappend(Node.select_stmt_of($n).values_lists, Rt.list_node(a4)) })
	$a1 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: relation_expr opt_alias_clause
rule_1832 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1832 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$a1 = Node.RangeVar({ ..Node.range_var_of($a1), alias: a2 })
	$result = $a1
	Ok(Rt.of_node($result))
}

## table_ref: relation_expr opt_alias_clause tablesample_clause
rule_1833 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1833 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a3
	$a1 = Node.RangeVar({ ..Node.range_var_of($a1), alias: a2 })
	$n = Node.RangeTableSample({ ..Node.range_table_sample_of($n), relation: $a1 })
	$a3 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: func_table func_alias_clause
rule_1834 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1834 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a1
	$n = Node.RangeFunction({ ..Node.range_function_of($n), alias: Rt.linitial(a2) })
	$a1 = $n
	$n = Node.RangeFunction({ ..Node.range_function_of($n), coldeflist: Rt.node_list(Rt.lsecond(a2)) })
	$a1 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: LATERAL_P func_table func_alias_clause
rule_1835 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1835 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.RangeFunction({ ..Node.range_function_of($n), lateral: Bool.True })
	$a2 = $n
	$n = Node.RangeFunction({ ..Node.range_function_of($n), alias: Rt.linitial(a3) })
	$a2 = $n
	$n = Node.RangeFunction({ ..Node.range_function_of($n), coldeflist: Rt.node_list(Rt.lsecond(a3)) })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: xmltable opt_alias_clause
rule_1836 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1836 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a1
	$n = Node.RangeTableFunc({ ..Node.range_table_func_of($n), alias: a2 })
	$a1 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: LATERAL_P xmltable opt_alias_clause
rule_1837 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1837 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.RangeTableFunc({ ..Node.range_table_func_of($n), lateral: Bool.True })
	$a2 = $n
	$n = Node.RangeTableFunc({ ..Node.range_table_func_of($n), alias: a3 })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## table_ref: select_with_parens opt_alias_clause
rule_1838 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1838 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeSubselect({ ..Node.range_subselect_default, lateral: Bool.False, subquery: a1, alias: a2 })
	$result = n
	Ok(Rt.of_node($result))
}

## table_ref: LATERAL_P select_with_parens opt_alias_clause
rule_1839 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1839 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeSubselect({ ..Node.range_subselect_default, lateral: Bool.True, subquery: a2, alias: a3 })
	$result = n
	Ok(Rt.of_node($result))
}

## table_ref: '(' joined_table ')' alias_clause
rule_1841 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1841 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$a2 = Node.JoinExpr({ ..Node.join_expr_of($a2), alias: a4 })
	$result = $a2
	Ok(Rt.of_node($result))
}

## table_ref: json_table opt_alias_clause
rule_1842 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1842 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $jt = $a1
	$jt = Node.JsonTable({ ..Node.json_table_of($jt), alias: a2 })
	$a1 = $jt
	$result = $jt
	Ok(Rt.of_node($result))
}

## table_ref: LATERAL_P json_table opt_alias_clause
rule_1843 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1843 = |_ctx, v, _l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $jt = $a2
	$jt = Node.JsonTable({ ..Node.json_table_of($jt), alias: a3 })
	$a2 = $jt
	$jt = Node.JsonTable({ ..Node.json_table_of($jt), lateral: Bool.True })
	$a2 = $jt
	$result = $jt
	Ok(Rt.of_node($result))
}

## joined_table: table_ref CROSS JOIN table_ref
rule_1845 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1845 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.JoinExpr({ ..Node.join_expr_default, jointype: literal_0, is_natural: Bool.False, larg: a1, rarg: a4, using_clause: [], join_using_alias: Null, quals: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## joined_table: table_ref join_type JOIN table_ref join_qual
rule_1846 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1846 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.int_at(v, 1)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JoinExpr({ ..Node.join_expr_default, jointype: a2, is_natural: Bool.False, larg: a1, rarg: a4 })
	if (!(Node.is_null(a5)) and (Node.tag(a5) == "List")) {
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), using_clause: Rt.node_list(Rt.linitial(Rt.node_list(a5))) })
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), join_using_alias: Rt.lsecond(Rt.node_list(a5)) })
	} else {
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), quals: a5 })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## joined_table: table_ref JOIN table_ref join_qual
rule_1847 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1847 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JoinExpr({ ..Node.join_expr_default, jointype: literal_0, is_natural: Bool.False, larg: a1, rarg: a3 })
	if (!(Node.is_null(a4)) and (Node.tag(a4) == "List")) {
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), using_clause: Rt.node_list(Rt.linitial(Rt.node_list(a4))) })
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), join_using_alias: Rt.lsecond(Rt.node_list(a4)) })
	} else {
		$n = Node.JoinExpr({ ..Node.join_expr_of($n), quals: a4 })
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## joined_table: table_ref NATURAL join_type JOIN table_ref
rule_1848 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1848 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.int_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	n = Node.JoinExpr({ ..Node.join_expr_default, jointype: a3, is_natural: Bool.True, larg: a1, rarg: a5, using_clause: [], join_using_alias: Null, quals: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## joined_table: table_ref NATURAL JOIN table_ref
rule_1849 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1849 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.JoinExpr({ ..Node.join_expr_default, jointype: literal_0, is_natural: Bool.True, larg: a1, rarg: a4, using_clause: [], join_using_alias: Null, quals: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## alias_clause: AS ColId '(' name_list ')'
rule_1850 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1850 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = Node.Alias(Node.alias_default)
	$result = Node.Alias({ ..Node.alias_of($result), aliasname: a2 })
	$result = Node.Alias({ ..Node.alias_of($result), colnames: a4 })
	Ok(Rt.of_node($result))
}

## alias_clause: AS ColId
rule_1851 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1851 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = Node.Alias(Node.alias_default)
	$result = Node.Alias({ ..Node.alias_of($result), aliasname: a2 })
	Ok(Rt.of_node($result))
}

## alias_clause: ColId '(' name_list ')'
rule_1852 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1852 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = Node.Alias(Node.alias_default)
	$result = Node.Alias({ ..Node.alias_of($result), aliasname: a1 })
	$result = Node.Alias({ ..Node.alias_of($result), colnames: a3 })
	Ok(Rt.of_node($result))
}

## alias_clause: ColId
rule_1853 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1853 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.Alias(Node.alias_default)
	$result = Node.Alias({ ..Node.alias_of($result), aliasname: a1 })
	Ok(Rt.of_node($result))
}

## func_alias_clause: alias_clause
rule_1858 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1858 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, Null)
	Ok(Rt.of_list($result))
}

## func_alias_clause: AS '(' TableFuncElementList ')'
rule_1859 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1859 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Null, Rt.list_node(a3))
	Ok(Rt.of_list($result))
}

## func_alias_clause: AS ColId '(' TableFuncElementList ')'
rule_1860 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1860 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.list_at(v, 0)
	a = Node.Alias({ ..Node.alias_default, aliasname: a2 })
	$result = Rt.list_make2(a, Rt.list_node(a4))
	Ok(Rt.of_list($result))
}

## func_alias_clause: ColId '(' TableFuncElementList ')'
rule_1861 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1861 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	a = Node.Alias({ ..Node.alias_default, aliasname: a1 })
	$result = Rt.list_make2(a, Rt.list_node(a3))
	Ok(Rt.of_list($result))
}

## join_qual: USING '(' name_list ')' opt_alias_clause_for_join_using
rule_1869 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1869 = |_ctx, v, _l, _loc| {
	a3 = Rt.list_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.node_at(v, 0)
	$result = Rt.list_node(Rt.list_make2(Rt.list_node(a3), a5))
	Ok(Rt.of_node($result))
}

## relation_expr: qualified_name
rule_1871 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1871 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.RangeVar({ ..Node.range_var_of($result), inh: Bool.True })
	$result = Node.RangeVar({ ..Node.range_var_of($result), alias: Null })
	Ok(Rt.of_node($result))
}

## extended_relation_expr: ONLY qualified_name
rule_1874 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1874 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.RangeVar({ ..Node.range_var_of($result), inh: Bool.False })
	$result = Node.RangeVar({ ..Node.range_var_of($result), alias: Null })
	Ok(Rt.of_node($result))
}

## extended_relation_expr: ONLY '(' qualified_name ')'
rule_1875 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1875 = |_ctx, v, _l, _loc| {
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = a3
	$result = Node.RangeVar({ ..Node.range_var_of($result), inh: Bool.False })
	$result = Node.RangeVar({ ..Node.range_var_of($result), alias: Null })
	Ok(Rt.of_node($result))
}

## relation_expr_opt_alias: relation_expr ColId
rule_1879 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1879 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	alias_local = Node.Alias({ ..Node.alias_default, aliasname: a2 })
	$a1 = Node.RangeVar({ ..Node.range_var_of($a1), alias: alias_local })
	$result = $a1
	Ok(Rt.of_node($result))
}

## relation_expr_opt_alias: relation_expr AS ColId
rule_1880 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1880 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	alias_local = Node.Alias({ ..Node.alias_default, aliasname: a3 })
	$a1 = Node.RangeVar({ ..Node.range_var_of($a1), alias: alias_local })
	$result = $a1
	Ok(Rt.of_node($result))
}

## tablesample_clause: TABLESAMPLE func_name '(' expr_list ')' opt_repeatable_clause
rule_1881 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1881 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeTableSample({ ..Node.range_table_sample_default, method: a2, args: a4, repeatable: a6, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_table: func_expr_windowless opt_ordinality
rule_1884 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1884 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.bool_at(v, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.RangeFunction({ ..Node.range_function_default, lateral: Bool.False, ordinality: a2, is_rowsfrom: Bool.False })
	$n = Node.RangeFunction({ ..Node.range_function_of($n), functions: Rt.list_make1(Rt.list_node(Rt.list_make2(a1, Null))) })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_table: ROWS FROM '(' rowsfrom_list ')' opt_ordinality
rule_1885 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1885 = |_ctx, v, _l, _loc| {
	a4 = Rt.list_at(v, 3)
	a6 = Rt.bool_at(v, 5)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeFunction({ ..Node.range_function_default, lateral: Bool.False, ordinality: a6, is_rowsfrom: Bool.True, functions: a4 })
	$result = n
	Ok(Rt.of_node($result))
}

## rowsfrom_item: func_expr_windowless opt_col_def_list
rule_1886 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1886 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, Rt.list_node(a2))
	Ok(Rt.of_list($result))
}

## where_or_current_clause: WHERE CURRENT_P OF cursor_name
rule_1896 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1896 = |_ctx, v, _l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	var $result = Rt.node_at(v, 0)
	n = Node.CurrentOfExpr({ ..Node.current_of_expr_default, cursor_name: a4, cursor_param: literal_0 })
	$result = n
	Ok(Rt.of_node($result))
}

## TableFuncElement: ColId Typename opt_collate_clause
rule_1902 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1902 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ColumnDef({ ..Node.column_def_default, colname: a1, type_name: a2, inhcount: literal_0, is_local: Bool.True, is_not_null: Bool.False, is_from_type: Bool.False, storage: literal_1, raw_default: Null, cooked_default: Null })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), coll_clause: a3 })
	$n = Node.ColumnDef({ ..Node.column_def_of($n), coll_oid: literal_2, constraints: [], location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## xmltable: XMLTABLE '(' c_expr xmlexists_argument COLUMNS xmltable_column_list ')'
rule_1903 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1903 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeTableFunc({ ..Node.range_table_func_default, rowexpr: a3, docexpr: a4, columns: a6, namespaces: [], location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## xmltable: XMLTABLE '(' XMLNAMESPACES '(' xml_namespace_list ')' ',' c_expr xmlexists_argument COLUMNS xmltable_column_list ')'
rule_1904 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1904 = |_ctx, v, l, _loc| {
	a5 = Rt.list_at(v, 4)
	a8 = Rt.node_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a11 = Rt.list_at(v, 10)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.RangeTableFunc({ ..Node.range_table_func_default, rowexpr: a8, docexpr: a9, columns: a11, namespaces: a5, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## xmltable_column_el: ColId Typename
rule_1907 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1907 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_default, colname: a1, for_ordinality: Bool.False, type_name: a2, is_not_null: Bool.False, colexpr: Null, coldefexpr: Null, location: l1 })
	$result = fc
	Ok(Rt.of_node($result))
}

## xmltable_column_el: ColId Typename xmltable_column_option_list
rule_1908 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1908 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $fc = Node.RangeTableFuncCol(Node.range_table_func_col_default)
	var $nullability_seen = Bool.False
	$fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_of($fc), colname: a1, type_name: a2, for_ordinality: Bool.False, is_not_null: Bool.False, colexpr: Null, coldefexpr: Null, location: l1 })
	option_list = a3
	var $option_index = 0
	while $option_index < option_list.len() {
		defel = (option_list.get($option_index) ?? Null)
		if (Rt.strcmp(Node.def_elem_of(defel).defname, Ok("default")) == literal_0) {
			if !(Node.is_null(Node.range_table_func_col_of($fc).coldefexpr)) {
				return Err(Rt.error(ctx, "42601", Ok("only one DEFAULT value is allowed"), Node.def_elem_of(defel).location))
			}
			$fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_of($fc), coldefexpr: Node.def_elem_of(defel).arg })
		} else {
			if (Rt.strcmp(Node.def_elem_of(defel).defname, Ok("path")) == literal_1) {
				if !(Node.is_null(Node.range_table_func_col_of($fc).colexpr)) {
					return Err(Rt.error(ctx, "42601", Ok("only one PATH value per column is allowed"), Node.def_elem_of(defel).location))
				}
				$fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_of($fc), colexpr: Node.def_elem_of(defel).arg })
			} else {
				if (Rt.strcmp(Node.def_elem_of(defel).defname, Ok("__pg__is_not_null")) == literal_2) {
					if $nullability_seen {
						return Err(Rt.error(ctx, "42601", Ok("conflicting or redundant NULL / NOT NULL declarations for column \"${Rt.text_str(Node.range_table_func_col_of($fc).colname)}\""), Node.def_elem_of(defel).location))
					}
					$fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_of($fc), is_not_null: Node.boolean_of(Node.def_elem_of(defel).arg).boolval })
					$nullability_seen = Bool.True
				} else {
					return Err(Rt.error(ctx, "42601", Ok("unrecognized column option \"${Rt.text_str(Node.def_elem_of(defel).defname)}\""), Node.def_elem_of(defel).location))
				}
			}
		}
		$option_index = $option_index + 1
	}
	$result = $fc
	Ok(Rt.of_node($result))
}

## xmltable_column_el: ColId FOR ORDINALITY
rule_1909 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1909 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	fc = Node.RangeTableFuncCol({ ..Node.range_table_func_col_default, colname: a1, for_ordinality: Bool.True, location: l1 })
	$result = fc
	Ok(Rt.of_node($result))
}

## xmltable_column_option_el: IDENT b_expr
rule_1912 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1912 = |ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if (Rt.strcmp(a1, Ok("__pg__is_not_null")) == literal_0) {
		return Err(Rt.error(ctx, "42601", Ok("option name \"${Rt.text_str(a1)}\" cannot be used in XMLTABLE"), l1))
	}
	$result = make_def_elem(a1, a2, l1)
	Ok(Rt.of_node($result))
}

## xmltable_column_option_el: DEFAULT b_expr
rule_1913 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1913 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("default"), a2, l1)
	Ok(Rt.of_node($result))
}

## xmltable_column_option_el: NOT NULL_P
rule_1914 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1914 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("__pg__is_not_null"), make_boolean(Bool.True), l1)
	Ok(Rt.of_node($result))
}

## xmltable_column_option_el: NULL_P
rule_1915 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1915 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("__pg__is_not_null"), make_boolean(Bool.False), l1)
	Ok(Rt.of_node($result))
}

## xmltable_column_option_el: PATH b_expr
rule_1916 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1916 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_def_elem(Ok("path"), a2, l1)
	Ok(Rt.of_node($result))
}

## xml_namespace_el: b_expr AS ColLabel
rule_1919 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1919 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.text_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: a3 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: [] })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: a1 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## xml_namespace_el: DEFAULT b_expr
rule_1920 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1920 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: Err(Null) })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: [] })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: a2 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## json_table: JSON_TABLE '(' json_value_expr ',' a_expr json_table_path_name_opt json_passing_clause_opt COLUMNS '(' json_table_column_definition_list ')' json_on_error_clause_opt ')'
rule_1921 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1921 = |ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.text_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a10 = Rt.list_at(v, 9)
	a12 = Rt.node_at(v, 11)
	l1 = Rt.location(l, 0)
	l5 = Rt.location(l, 4)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTable(Node.json_table_default)
	var $pathstring = Err(Null)
	$n = Node.JsonTable({ ..Node.json_table_of($n), context_item: a3 })
	if (!((Node.tag(a5) == "A_Const")) or !((Node.tag(Node.a_const_of(a5).val) == "String"))) {
		return Err(Rt.error(ctx, "0A000", Ok("only string constants are supported in JSON_TABLE path specification"), l5))
	}
	$pathstring = Node.string_of(Node.a_const_of(a5).val).sval
	$n = Node.JsonTable({ ..Node.json_table_of($n), pathspec: make_json_table_path_spec($pathstring, a6, l5, l6) })
	$n = Node.JsonTable({ ..Node.json_table_of($n), passing: a7, columns: a10 })
	$n = Node.JsonTable({ ..Node.json_table_of($n), on_error: a12 })
	$n = Node.JsonTable({ ..Node.json_table_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: ColId FOR ORDINALITY
rule_1926 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1926 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0, name: a1, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: ColId Typename json_table_column_path_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt
rule_1927 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1927 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0, name: a1, type_name: a2 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), format: make_json_format(literal_1, literal_2, (0 - literal_3)) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), pathspec: a3 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), wrapper: a4, quotes: a5 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_empty: Rt.linitial(a6) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_error: Rt.lsecond(a6) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: ColId Typename json_format_clause json_table_column_path_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt
rule_1928 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1928 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.int_at(v, 4)
	a6 = Rt.int_at(v, 5)
	a7 = Rt.list_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0, name: a1, type_name: a2 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), format: a3 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), pathspec: a4 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), wrapper: a5, quotes: a6 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_empty: Rt.linitial(a7) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_error: Rt.lsecond(a7) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: ColId Typename EXISTS json_table_column_path_clause_opt json_on_error_clause_opt
rule_1929 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1929 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0, name: a1, type_name: a2 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), format: make_json_format(literal_1, literal_2, (0 - literal_3)) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), wrapper: literal_4, quotes: literal_5 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), pathspec: a4 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_empty: Null })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), on_error: a5 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: NESTED path_opt Sconst COLUMNS '(' json_table_column_definition_list ')'
rule_1930 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1930 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.text_at(v, 2)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), pathspec: make_json_table_path_spec(a3, Err(Null), l3, (0 - literal_1)) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), columns: a6, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_definition: NESTED path_opt Sconst AS name COLUMNS '(' json_table_column_definition_list ')'
rule_1931 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1931 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.text_at(v, 2)
	a5 = Rt.text_at(v, 4)
	a8 = Rt.list_at(v, 7)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonTableColumn({ ..Node.json_table_column_default, coltype: literal_0 })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), pathspec: make_json_table_path_spec(a3, a5, l3, l5) })
	$n = Node.JsonTableColumn({ ..Node.json_table_column_of($n), columns: a8, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_table_column_path_clause_opt: PATH Sconst
rule_1934 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1934 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_json_table_path_spec(a2, Err(Null), l2, (0 - literal_0))
	Ok(Rt.of_node($result))
}

## Typename: SimpleTypename opt_array_bounds
rule_1936 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1936 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: a2 })
	Ok(Rt.of_node($result))
}

## Typename: SETOF SimpleTypename opt_array_bounds
rule_1937 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1937 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: a3 })
	$result = Node.TypeName({ ..Node.type_name_of($result), setof: Bool.True })
	Ok(Rt.of_node($result))
}

## Typename: SimpleTypename ARRAY '[' Iconst ']'
rule_1938 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1938 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.int_at(v, 3)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: Rt.list_make1(make_integer(a4)) })
	Ok(Rt.of_node($result))
}

## Typename: SETOF SimpleTypename ARRAY '[' Iconst ']'
rule_1939 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1939 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a5 = Rt.int_at(v, 4)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: Rt.list_make1(make_integer(a5)) })
	$result = Node.TypeName({ ..Node.type_name_of($result), setof: Bool.True })
	Ok(Rt.of_node($result))
}

## Typename: SimpleTypename ARRAY
rule_1940 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1940 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: Rt.list_make1(make_integer((0 - literal_0))) })
	Ok(Rt.of_node($result))
}

## Typename: SETOF SimpleTypename ARRAY
rule_1941 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1941 = |_ctx, v, _l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.TypeName({ ..Node.type_name_of($result), array_bounds: Rt.list_make1(make_integer((0 - literal_0))) })
	$result = Node.TypeName({ ..Node.type_name_of($result), setof: Bool.True })
	Ok(Rt.of_node($result))
}

## opt_array_bounds: opt_array_bounds '[' ']'
rule_1942 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1942 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, make_integer((0 - literal_0)))
	Ok(Rt.of_list($result))
}

## opt_array_bounds: opt_array_bounds '[' Iconst ']'
rule_1943 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1943 = |_ctx, v, _l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a1, make_integer(a3))
	Ok(Rt.of_list($result))
}

## SimpleTypename: ConstInterval opt_interval
rule_1950 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1950 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: a2 })
	Ok(Rt.of_node($result))
}

## SimpleTypename: ConstInterval '(' Iconst ')'
rule_1951 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1951 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.int_at(v, 2)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make2(make_int_const(literal_0, (0 - literal_1)), make_int_const(a3, l3)) })
	Ok(Rt.of_node($result))
}

## GenericType: type_function_name opt_type_modifiers
rule_1958 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1958 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_type_name(a1)
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: a2 })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## GenericType: type_function_name attrs opt_type_modifiers
rule_1959 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1959 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_type_name_from_name_list(Rt.lcons(make_string(a1), a2))
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: a3 })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: INT_P
rule_1962 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1962 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("int4"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: SMALLINT
rule_1964 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1964 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("int2"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: BIGINT
rule_1965 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1965 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("int8"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: REAL
rule_1966 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1966 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("float4"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: FLOAT_P opt_float
rule_1967 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1967 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = a2
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: DOUBLE_P PRECISION
rule_1968 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1968 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("float8"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: DECIMAL_P opt_type_modifiers
rule_1969 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1969 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("numeric"))
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: a2 })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## Numeric: BOOLEAN_P
rule_1972 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1972 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("bool"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_float: '(' Iconst ')'
rule_1973 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1973 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a2 = Rt.int_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	if (a2 < literal_0) {
		return Err(Rt.error(ctx, "22023", Ok("precision for type float must be at least 1 bit"), l2))
	} else {
		if (a2 <= literal_1) {
			$result = system_type_name(Ok("float4"))
		} else {
			if (a2 <= literal_2) {
				$result = system_type_name(Ok("float8"))
			} else {
				return Err(Rt.error(ctx, "22023", Ok("precision for type float must be less than 54 bits"), l2))
			}
		}
	}
	Ok(Rt.of_node($result))
}

## opt_float: %empty
rule_1974 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1974 = |_ctx, _v, _l, _loc| {
	var $result = Null
	$result = system_type_name(Ok("float8"))
	Ok(Rt.of_node($result))
}

## ConstBit: BitWithoutLength
rule_1978 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1978 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = a1
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: [] })
	Ok(Rt.of_node($result))
}

## BitWithLength: BIT opt_varying '(' expr_list ')'
rule_1979 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1979 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $typname = Err(Null)
	$typname = (if a2 Ok("varbit") else Ok("bit"))
	$result = system_type_name($typname)
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: a4 })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## BitWithoutLength: BIT opt_varying
rule_1980 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1980 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.bool_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if a2 {
		$result = system_type_name(Ok("varbit"))
	} else {
		$result = system_type_name(Ok("bit"))
		$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make1(make_int_const(literal_0, (0 - literal_1))) })
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## CharacterWithLength: character '(' Iconst ')'
rule_1985 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1985 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(a1)
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make1(make_int_const(a3, l3)) })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## CharacterWithoutLength: character
rule_1986 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_1986 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(a1)
	if (Rt.strcmp(a1, Ok("bpchar")) == literal_0) {
		$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make1(make_int_const(literal_1, (0 - literal_2))) })
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## character: CHARACTER opt_varying
rule_1987 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1987 = |_ctx, v, _l, _loc| {
	a2 = Rt.bool_at(v, 1)
	var $result = Rt.text_at(v, 0)
	$result = (if a2 Ok("varchar") else Ok("bpchar"))
	Ok(Rt.of_text($result))
}

## character: VARCHAR
rule_1989 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1989 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("varchar")
	Ok(Rt.of_text($result))
}

## character: NATIONAL CHARACTER opt_varying
rule_1990 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1990 = |_ctx, v, _l, _loc| {
	a3 = Rt.bool_at(v, 2)
	var $result = Rt.text_at(v, 0)
	$result = (if a3 Ok("varchar") else Ok("bpchar"))
	Ok(Rt.of_text($result))
}

## ConstDatetime: TIMESTAMP '(' Iconst ')' opt_timezone
rule_1995 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1995 = |_ctx, v, l, _loc| {
	a3 = Rt.int_at(v, 2)
	a5 = Rt.bool_at(v, 4)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	if a5 {
		$result = system_type_name(Ok("timestamptz"))
	} else {
		$result = system_type_name(Ok("timestamp"))
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make1(make_int_const(a3, l3)) })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## ConstDatetime: TIMESTAMP opt_timezone
rule_1996 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1996 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if a2 {
		$result = system_type_name(Ok("timestamptz"))
	} else {
		$result = system_type_name(Ok("timestamp"))
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## ConstDatetime: TIME '(' Iconst ')' opt_timezone
rule_1997 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1997 = |_ctx, v, l, _loc| {
	a3 = Rt.int_at(v, 2)
	a5 = Rt.bool_at(v, 4)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	if a5 {
		$result = system_type_name(Ok("timetz"))
	} else {
		$result = system_type_name(Ok("time"))
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), typmods: Rt.list_make1(make_int_const(a3, l3)) })
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## ConstDatetime: TIME opt_timezone
rule_1998 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1998 = |_ctx, v, l, _loc| {
	a2 = Rt.bool_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	if a2 {
		$result = system_type_name(Ok("timetz"))
	} else {
		$result = system_type_name(Ok("time"))
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## ConstInterval: INTERVAL
rule_1999 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_1999 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("interval"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## opt_interval: YEAR_P
rule_2003 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2003 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_int_const(Rt.shift_left(1, literal_0), l1))
	Ok(Rt.of_list($result))
}

## opt_interval: YEAR_P TO MONTH_P
rule_2009 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2009 = |_ctx, v, l, _loc, literal_0, literal_1| {
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_int_const(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)), l1))
	Ok(Rt.of_list($result))
}

## opt_interval: DAY_P TO MINUTE_P
rule_2011 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2011 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_int_const(Rt.bit_or(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)), Rt.shift_left(1, literal_2)), l1))
	Ok(Rt.of_list($result))
}

## opt_interval: DAY_P TO interval_second
rule_2012 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2012 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = a3
	$result = Rt.list_set($result, 0, make_int_const(Rt.bit_or(Rt.bit_or(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)), Rt.shift_left(1, literal_2)), Rt.shift_left(1, literal_3)), l1))
	Ok(Rt.of_list($result))
}

## opt_interval: HOUR_P TO interval_second
rule_2014 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2014 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = a3
	$result = Rt.list_set($result, 0, make_int_const(Rt.bit_or(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)), Rt.shift_left(1, literal_2)), l1))
	Ok(Rt.of_list($result))
}

## opt_interval: MINUTE_P TO interval_second
rule_2015 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2015 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = a3
	$result = Rt.list_set($result, 0, make_int_const(Rt.bit_or(Rt.shift_left(1, literal_0), Rt.shift_left(1, literal_1)), l1))
	Ok(Rt.of_list($result))
}

## interval_second: SECOND_P '(' Iconst ')'
rule_2018 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2018 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(make_int_const(Rt.shift_left(1, literal_0), l1), make_int_const(a3, l3))
	Ok(Rt.of_list($result))
}

## JsonType: JSON
rule_2019 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2019 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = system_type_name(Ok("json"))
	$result = Node.TypeName({ ..Node.type_name_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## a_expr: a_expr TYPECAST Typename
rule_2021 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2021 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_type_cast(a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr COLLATE any_name
rule_2022 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2022 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.list_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.CollateClause({ ..Node.collate_clause_default, arg: a1, collname: a3, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## a_expr: a_expr AT TIME ZONE a_expr
rule_2023 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2023 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("timezone")), Rt.list_make2(a5, a1), literal_0, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr AT LOCAL
rule_2024 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2024 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("timezone")), Rt.list_make1(a1), literal_0, (0 - literal_1))
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '+' a_expr
rule_2027 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2027 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("+"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '-' a_expr
rule_2028 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2028 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("-"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '*' a_expr
rule_2029 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2029 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("*"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '/' a_expr
rule_2030 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2030 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("/"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '%' a_expr
rule_2031 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2031 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("%"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '^' a_expr
rule_2032 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2032 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("^"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '<' a_expr
rule_2033 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2033 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("<"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '>' a_expr
rule_2034 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2034 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok(">"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr '=' a_expr
rule_2035 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2035 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("="), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr LESS_EQUALS a_expr
rule_2036 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2036 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("<="), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr GREATER_EQUALS a_expr
rule_2037 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2037 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok(">="), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_EQUALS a_expr
rule_2038 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2038 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("<>"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr qual_Op a_expr
rule_2039 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2039 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_a_expr(literal_0, a2, a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: qual_Op a_expr
rule_2040 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2040 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_a_expr(literal_0, a1, Null, a2, l1)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr AND a_expr
rule_2041 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2041 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_and_expr(a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr OR a_expr
rule_2042 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2042 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_or_expr(a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: NOT a_expr
rule_2043 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2043 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_not_expr(a2, l1)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr LIKE a_expr
rule_2045 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2045 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("~~"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr LIKE a_expr ESCAPE a_expr
rule_2046 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2046 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("like_escape")), Rt.list_make2(a3, a5), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("~~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA LIKE a_expr
rule_2047 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2047 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("!~~"), a1, a4, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA LIKE a_expr ESCAPE a_expr
rule_2048 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2048 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("like_escape")), Rt.list_make2(a4, a6), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("!~~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr ILIKE a_expr
rule_2049 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2049 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("~~*"), a1, a3, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr ILIKE a_expr ESCAPE a_expr
rule_2050 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2050 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("like_escape")), Rt.list_make2(a3, a5), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("~~*"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA ILIKE a_expr
rule_2051 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2051 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("!~~*"), a1, a4, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA ILIKE a_expr ESCAPE a_expr
rule_2052 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2052 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("like_escape")), Rt.list_make2(a4, a6), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("!~~*"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr SIMILAR TO a_expr
rule_2053 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2053 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("similar_to_escape")), Rt.list_make1(a4), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr SIMILAR TO a_expr ESCAPE a_expr
rule_2054 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2054 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("similar_to_escape")), Rt.list_make2(a4, a6), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA SIMILAR TO a_expr
rule_2055 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2055 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("similar_to_escape")), Rt.list_make1(a5), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("!~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA SIMILAR TO a_expr ESCAPE a_expr
rule_2056 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2056 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = make_func_call(system_func_name(Ok("similar_to_escape")), Rt.list_make2(a5, a7), literal_0, l2)
	$result = make_simple_a_expr(literal_1, Ok("!~"), a1, n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NULL_P
rule_2057 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2057 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = Node.NullTest(Node.null_test_default)
	$n = Node.NullTest({ ..Node.null_test_of($n), arg: a1 })
	$n = Node.NullTest({ ..Node.null_test_of($n), nulltesttype: literal_0, location: l2 })
	$result = $n
	Ok(Rt.of_node($result))
}

## a_expr: row OVERLAPS row
rule_2061 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2061 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	if !((Rt.list_length(a1) == literal_0)) {
		return Err(Rt.error(ctx, "42601", Ok("wrong number of parameters on left side of OVERLAPS expression"), l1))
	}
	if !((Rt.list_length(a3) == literal_1)) {
		return Err(Rt.error(ctx, "42601", Ok("wrong number of parameters on right side of OVERLAPS expression"), l3))
	}
	$result = make_func_call(system_func_name(Ok("overlaps")), Rt.list_concat(a1, a3), literal_2, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS TRUE_P
rule_2062 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2062 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $b = Node.BooleanTest(Node.boolean_test_default)
	$b = Node.BooleanTest({ ..Node.boolean_test_of($b), arg: a1 })
	$b = Node.BooleanTest({ ..Node.boolean_test_of($b), booltesttype: literal_0, location: l2 })
	$result = $b
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS DISTINCT FROM a_expr
rule_2068 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2068 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("="), a1, a5, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NOT DISTINCT FROM a_expr
rule_2069 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2069 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("="), a1, a6, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr BETWEEN opt_asymmetric b_expr AND a_expr
rule_2070 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2070 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("BETWEEN"), a1, Rt.list_node(Rt.list_make2(a4, a6)), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA BETWEEN opt_asymmetric b_expr AND a_expr
rule_2071 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2071 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("NOT BETWEEN"), a1, Rt.list_node(Rt.list_make2(a5, a7)), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr BETWEEN SYMMETRIC b_expr AND a_expr
rule_2072 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2072 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("BETWEEN SYMMETRIC"), a1, Rt.list_node(Rt.list_make2(a4, a6)), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA BETWEEN SYMMETRIC b_expr AND a_expr
rule_2073 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2073 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("NOT BETWEEN SYMMETRIC"), a1, Rt.list_node(Rt.list_make2(a5, a7)), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IN_P select_with_parens
rule_2074 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2074 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.SubLink({ ..Node.sub_link_default, subselect: a3, sub_link_type: literal_0, sub_link_id: literal_1, testexpr: a1, oper_name: [], location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IN_P '(' expr_list ')'
rule_2075 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2075 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.list_at(v, 3)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	var $n = make_simple_a_expr(literal_0, Ok("="), a1, Rt.list_node(a4), l2)
	$n = Node.AExpr({ ..Node.a_expr_of($n), rexpr_list_start: l3, rexpr_list_end: l5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA IN_P select_with_parens
rule_2076 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2076 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.SubLink({ ..Node.sub_link_default, subselect: a4, sub_link_type: literal_0, sub_link_id: literal_1, testexpr: a1, oper_name: [], location: l2 })
	$result = make_not_expr(n, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr NOT_LA IN_P '(' expr_list ')'
rule_2077 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2077 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a5 = Rt.list_at(v, 4)
	l2 = Rt.location(l, 1)
	l4 = Rt.location(l, 3)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $n = make_simple_a_expr(literal_0, Ok("<>"), a1, Rt.list_node(a5), l2)
	$n = Node.AExpr({ ..Node.a_expr_of($n), rexpr_list_start: l4, rexpr_list_end: l6 })
	$result = $n
	Ok(Rt.of_node($result))
}

## a_expr: a_expr subquery_Op sub_type select_with_parens
rule_2078 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2078 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.SubLink({ ..Node.sub_link_default, sub_link_type: a3, sub_link_id: literal_0, testexpr: a1, oper_name: a2, subselect: a4, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## a_expr: a_expr subquery_Op sub_type '(' a_expr ')'
rule_2079 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2079 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.int_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	if (a3 == literal_0) {
		$result = make_a_expr(literal_1, a2, a1, a5, l2)
	} else {
		$result = make_a_expr(literal_2, a2, a1, a5, l2)
	}
	Ok(Rt.of_node($result))
}

## a_expr: UNIQUE opt_unique_null_treatment select_with_parens
rule_2080 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2080 = |ctx, _v, l, _loc| {
	l1 = Rt.location(l, 0)
	Err(Rt.error(ctx, "0A000", Ok("UNIQUE predicate is not yet implemented"), l1))
}

## a_expr: a_expr IS DOCUMENT_P
rule_2081 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2081 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, Err(Null), [], Rt.list_make1(a1), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NOT DOCUMENT_P
rule_2082 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2082 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_not_expr(make_xml_expr(literal_0, Err(Null), [], Rt.list_make1(a1), l2), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NORMALIZED
rule_2083 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2083 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("is_normalized")), Rt.list_make1(a1), literal_0, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS unicode_normal_form NORMALIZED
rule_2084 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2084 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.text_at(v, 2)
	l2 = Rt.location(l, 1)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("is_normalized")), Rt.list_make2(a1, make_string_const(a3, l3)), literal_0, l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NOT NORMALIZED
rule_2085 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2085 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_not_expr(make_func_call(system_func_name(Ok("is_normalized")), Rt.list_make1(a1), literal_0, l2), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NOT unicode_normal_form NORMALIZED
rule_2086 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2086 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.text_at(v, 3)
	l2 = Rt.location(l, 1)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	$result = make_not_expr(make_func_call(system_func_name(Ok("is_normalized")), Rt.list_make2(a1, make_string_const(a4, l4)), literal_0, l2), l2)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS json_predicate_type_constraint json_key_uniqueness_constraint_opt
rule_2087 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2087 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.int_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	format = make_json_format(literal_0, literal_1, (0 - literal_2))
	$result = make_json_is_predicate(a1, format, a3, a4, l1)
	Ok(Rt.of_node($result))
}

## a_expr: a_expr IS NOT json_predicate_type_constraint json_key_uniqueness_constraint_opt
rule_2088 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2088 = |_ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.int_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	format = make_json_format(literal_0, literal_1, (0 - literal_2))
	$result = make_not_expr(make_json_is_predicate(a1, format, a4, a5, l1), l1)
	Ok(Rt.of_node($result))
}

## a_expr: DEFAULT
rule_2089 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2089 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.SetToDefault({ ..Node.set_to_default_default, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## c_expr: PARAM opt_indirection
rule_2114 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2114 = |ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	p = Node.ParamRef({ ..Node.param_ref_default, number: a1, location: l1 })
	if !(a2).is_empty() {
		var $n = Node.AIndirection(Node.a_indirection_default)
		$n = Node.AIndirection({ ..Node.a_indirection_of($n), arg: p })
		$n = Node.AIndirection({ ..Node.a_indirection_of($n), indirection: check_indirection(a2, ctx)? })
		$result = $n
	} else {
		$result = p
	}
	Ok(Rt.of_node($result))
}

## c_expr: '(' a_expr ')' opt_indirection
rule_2115 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2115 = |ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.list_at(v, 3)
	var $result = Rt.node_at(v, 0)
	if !(a4).is_empty() {
		var $n = Node.AIndirection({ ..Node.a_indirection_default, arg: a2 })
		$n = Node.AIndirection({ ..Node.a_indirection_of($n), indirection: check_indirection(a4, ctx)? })
		$result = $n
	} else {
		$result = a2
	}
	Ok(Rt.of_node($result))
}

## c_expr: select_with_parens
rule_2118 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2118 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.SubLink({ ..Node.sub_link_default, sub_link_type: literal_0, sub_link_id: literal_1, testexpr: Null, oper_name: [], subselect: a1, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## c_expr: select_with_parens indirection
rule_2119 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2119 = |ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SubLink(Node.sub_link_default)
	var $a = Node.AIndirection(Node.a_indirection_default)
	$n = Node.SubLink({ ..Node.sub_link_of($n), sub_link_type: literal_0, sub_link_id: literal_1, testexpr: Null, oper_name: [], subselect: a1, location: l1 })
	$a = Node.AIndirection({ ..Node.a_indirection_of($a), arg: $n })
	$a = Node.AIndirection({ ..Node.a_indirection_of($a), indirection: check_indirection(a2, ctx)? })
	$result = $a
	Ok(Rt.of_node($result))
}

## c_expr: EXISTS select_with_parens
rule_2120 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2120 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.SubLink({ ..Node.sub_link_default, sub_link_type: literal_0, sub_link_id: literal_1, testexpr: Null, oper_name: [], subselect: a2, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## c_expr: ARRAY array_expr
rule_2122 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2122 = |_ctx, v, l, _loc| {
	var $a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.AArrayExpr({ ..Node.a_array_expr_of($n), location: l1 })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## c_expr: explicit_row
rule_2123 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2123 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a1 = Rt.list_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	r = Node.RowExpr({ ..Node.row_expr_default, args: a1, row_typeid: literal_0, colnames: [], row_format: literal_1, location: l1 })
	$result = r
	Ok(Rt.of_node($result))
}

## c_expr: GROUPING '(' expr_list ')'
rule_2125 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2125 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	g = Node.GroupingFunc({ ..Node.grouping_func_default, args: a3, location: l1 })
	$result = g
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' ')'
rule_2126 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2126 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(a1, [], literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' func_arg_list opt_sort_clause ')'
rule_2127 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2127 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, a3, literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), agg_order: a4 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' VARIADIC func_arg_expr opt_sort_clause ')'
rule_2128 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2128 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, Rt.list_make1(a4), literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), func_variadic: Bool.True, agg_order: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' func_arg_list ',' VARIADIC func_arg_expr opt_sort_clause ')'
rule_2129 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2129 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.list_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, Rt.lappend(a3, a6), literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), func_variadic: Bool.True, agg_order: a7 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' ALL func_arg_list opt_sort_clause ')'
rule_2130 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2130 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, a4, literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), agg_order: a5 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' DISTINCT func_arg_list opt_sort_clause ')'
rule_2131 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2131 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.list_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, a4, literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), agg_order: a5, agg_distinct: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_application: func_name '(' '*' ')'
rule_2132 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2132 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = make_func_call(a1, [], literal_0, l1)
	$n = Node.FuncCall({ ..Node.func_call_of($n), agg_star: Bool.True })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr: func_application within_group_clause filter_clause over_clause
rule_2133 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2133 = |ctx, v, l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $n = $a1
	if !((a2).is_empty()) {
		if !((Node.func_call_of($n).agg_order).is_empty()) {
			return Err(Rt.error(ctx, "42601", Ok("cannot use multiple ORDER BY clauses with WITHIN GROUP"), l2))
		}
		if Node.func_call_of($n).agg_distinct {
			return Err(Rt.error(ctx, "42601", Ok("cannot use DISTINCT with WITHIN GROUP"), l2))
		}
		if Node.func_call_of($n).func_variadic {
			return Err(Rt.error(ctx, "42601", Ok("cannot use VARIADIC with WITHIN GROUP"), l2))
		}
		$n = Node.FuncCall({ ..Node.func_call_of($n), agg_order: a2 })
		$a1 = $n
		$n = Node.FuncCall({ ..Node.func_call_of($n), agg_within_group: Bool.True })
		$a1 = $n
	}
	$n = Node.FuncCall({ ..Node.func_call_of($n), agg_filter: a3 })
	$a1 = $n
	$n = Node.FuncCall({ ..Node.func_call_of($n), over: a4 })
	$a1 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr: json_aggregate_func filter_clause over_clause
rule_2134 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2134 = |_ctx, v, _l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = (if (Node.tag($a1) == "JsonObjectAgg") Node.json_object_agg_of($a1).constructor else Node.json_array_agg_of($a1).constructor)
	$n = Node.JsonAggConstructor({ ..Node.json_agg_constructor_of($n), agg_filter: a2 })
	if (Node.tag($a1) == "JsonObjectAgg") {
		$a1 = Node.JsonObjectAgg({ ..Node.json_object_agg_of($a1), constructor: $n })
	}
	if !((Node.tag($a1) == "JsonObjectAgg")) {
		$a1 = Node.JsonArrayAgg({ ..Node.json_array_agg_of($a1), constructor: $n })
	}
	$n = Node.JsonAggConstructor({ ..Node.json_agg_constructor_of($n), over: a3 })
	if (Node.tag($a1) == "JsonObjectAgg") {
		$a1 = Node.JsonObjectAgg({ ..Node.json_object_agg_of($a1), constructor: $n })
	}
	if !((Node.tag($a1) == "JsonObjectAgg")) {
		$a1 = Node.JsonArrayAgg({ ..Node.json_array_agg_of($a1), constructor: $n })
	}
	$result = $a1
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: COLLATION FOR '(' a_expr ')'
rule_2139 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2139 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("pg_collation_for")), Rt.list_make1(a4), literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: CURRENT_DATE
rule_2140 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2140 = |_ctx, v, l, _loc, literal_0, literal_1| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_sql_value_function(literal_0, (0 - literal_1), l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: CURRENT_TIME '(' Iconst ')'
rule_2142 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2142 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.int_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_sql_value_function(literal_0, a3, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: SYSTEM_USER
rule_2152 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2152 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("system_user")), [], literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: CAST '(' a_expr AS Typename ')'
rule_2156 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2156 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_type_cast(a3, a5, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: EXTRACT '(' extract_list ')'
rule_2157 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2157 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("extract")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: NORMALIZE '(' a_expr ')'
rule_2158 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2158 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("normalize")), Rt.list_make1(a3), literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: NORMALIZE '(' a_expr ',' unicode_normal_form ')'
rule_2159 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2159 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.text_at(v, 4)
	l1 = Rt.location(l, 0)
	l5 = Rt.location(l, 4)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("normalize")), Rt.list_make2(a3, make_string_const(a5, l5)), literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: OVERLAY '(' overlay_list ')'
rule_2160 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2160 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("overlay")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: OVERLAY '(' func_arg_list_opt ')'
rule_2161 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2161 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(Rt.list_make1(make_string(Ok("overlay"))), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: POSITION '(' position_list ')'
rule_2162 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2162 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("position")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: SUBSTRING '(' substr_list ')'
rule_2163 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2163 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("substring")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: SUBSTRING '(' func_arg_list_opt ')'
rule_2164 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2164 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(Rt.list_make1(make_string(Ok("substring"))), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: TREAT '(' a_expr AS Typename ')'
rule_2165 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2165 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Node.string_of(Rt.llast(Node.type_name_of(a5).names)).sval), Rt.list_make1(a3), literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: TRIM '(' BOTH trim_list ')'
rule_2166 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2166 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("btrim")), a4, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: TRIM '(' LEADING trim_list ')'
rule_2167 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2167 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("ltrim")), a4, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: TRIM '(' TRAILING trim_list ')'
rule_2168 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2168 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.list_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("rtrim")), a4, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: TRIM '(' trim_list ')'
rule_2169 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2169 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("btrim")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: NULLIF '(' a_expr ',' a_expr ')'
rule_2170 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2170 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_simple_a_expr(literal_0, Ok("="), a3, a5, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: COALESCE '(' expr_list ')'
rule_2171 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2171 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	c = Node.CoalesceExpr({ ..Node.coalesce_expr_default, args: a3, location: l1 })
	$result = c
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: GREATEST '(' expr_list ')'
rule_2172 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2172 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	v_2 = Node.MinMaxExpr({ ..Node.min_max_expr_default, args: a3, op: literal_0, location: l1 })
	$result = v_2
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLCONCAT '(' expr_list ')'
rule_2174 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2174 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, Err(Null), [], a3, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ')'
rule_2175 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2175 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, a4, [], [], l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ')'
rule_2176 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2176 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, a4, a6, [], l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' expr_list ')'
rule_2177 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2177 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.list_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, a4, [], a6, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLELEMENT '(' NAME_P ColLabel ',' xml_attributes ',' expr_list ')'
rule_2178 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2178 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.list_at(v, 5)
	a8 = Rt.list_at(v, 7)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, a4, a6, a8, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLEXISTS '(' c_expr xmlexists_argument ')'
rule_2179 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2179 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("xmlexists")), Rt.list_make2(a3, a4), literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLFOREST '(' xml_attribute_list ')'
rule_2180 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2180 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, Err(Null), a3, [], l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLPARSE '(' document_or_content a_expr xml_whitespace_option ')'
rule_2181 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2181 = |_ctx, v, l, _loc, literal_0, literal_1| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $x = make_xml_expr(literal_0, Err(Null), [], Rt.list_make2(a4, make_bool_a_const(a5, (0 - literal_1))), l1)
	$x = Node.XmlExpr({ ..Node.xml_expr_of($x), xmloption: a3 })
	$result = $x
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLPI '(' NAME_P ColLabel ',' a_expr ')'
rule_2183 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2183 = |_ctx, v, l, _loc, literal_0| {
	a4 = Rt.text_at(v, 3)
	a6 = Rt.node_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, a4, [], Rt.list_make1(a6), l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLROOT '(' a_expr ',' xml_root_version opt_xml_root_standalone ')'
rule_2184 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2184 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.node_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_xml_expr(literal_0, Err(Null), [], Rt.list_make3(a3, a5, a6), l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: XMLSERIALIZE '(' document_or_content a_expr AS SimpleTypename xml_indent_option ')'
rule_2185 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2185 = |_ctx, v, l, _loc| {
	a3 = Rt.int_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.bool_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.XmlSerialize({ ..Node.xml_serialize_default, xmloption: a3, expr: a4, type_name: a6, indent: a7, location: l1 })
	$result = n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_OBJECT '(' func_arg_list ')'
rule_2186 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2186 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.list_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_func_call(system_func_name(Ok("json_object")), a3, literal_0, l1)
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_OBJECT '(' json_name_and_value_list json_object_constructor_null_clause_opt json_key_uniqueness_constraint_opt json_returning_clause_opt ')'
rule_2187 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2187 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a6 = Rt.node_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_default, exprs: a3, absent_on_null: a4, unique: a5 })
	$n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_of($n), output: a6 })
	$n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_OBJECT '(' json_returning_clause_opt ')'
rule_2188 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2188 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_default, exprs: [], absent_on_null: Bool.False, unique: Bool.False })
	$n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_of($n), output: a3 })
	$n = Node.JsonObjectConstructor({ ..Node.json_object_constructor_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_ARRAY '(' json_value_expr_list json_array_constructor_null_clause_opt json_returning_clause_opt ')'
rule_2189 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2189 = |_ctx, v, l, _loc| {
	a3 = Rt.list_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_default, exprs: a3, absent_on_null: a4 })
	$n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_of($n), output: a5 })
	$n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_ARRAY '(' select_no_parens json_format_clause_opt json_returning_clause_opt ')'
rule_2190 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2190 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonArrayQueryConstructor({ ..Node.json_array_query_constructor_default, query: a3 })
	$n = Node.JsonArrayQueryConstructor({ ..Node.json_array_query_constructor_of($n), format: a4 })
	$n = Node.JsonArrayQueryConstructor({ ..Node.json_array_query_constructor_of($n), absent_on_null: Bool.True })
	$n = Node.JsonArrayQueryConstructor({ ..Node.json_array_query_constructor_of($n), output: a5 })
	$n = Node.JsonArrayQueryConstructor({ ..Node.json_array_query_constructor_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_ARRAY '(' json_returning_clause_opt ')'
rule_2191 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2191 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_default, exprs: [], absent_on_null: Bool.True })
	$n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_of($n), output: a3 })
	$n = Node.JsonArrayConstructor({ ..Node.json_array_constructor_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON '(' json_value_expr json_key_uniqueness_constraint_opt ')'
rule_2192 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2192 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonParseExpr(Node.json_parse_expr_default)
	$n = Node.JsonParseExpr({ ..Node.json_parse_expr_of($n), expr: a3 })
	$n = Node.JsonParseExpr({ ..Node.json_parse_expr_of($n), unique_keys: a4, output: Null, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_SCALAR '(' a_expr ')'
rule_2193 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2193 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonScalarExpr(Node.json_scalar_expr_default)
	$n = Node.JsonScalarExpr({ ..Node.json_scalar_expr_of($n), expr: a3 })
	$n = Node.JsonScalarExpr({ ..Node.json_scalar_expr_of($n), output: Null, location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_SERIALIZE '(' json_value_expr json_returning_clause_opt ')'
rule_2194 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2194 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonSerializeExpr(Node.json_serialize_expr_default)
	$n = Node.JsonSerializeExpr({ ..Node.json_serialize_expr_of($n), expr: a3 })
	$n = Node.JsonSerializeExpr({ ..Node.json_serialize_expr_of($n), output: a4 })
	$n = Node.JsonSerializeExpr({ ..Node.json_serialize_expr_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: MERGE_ACTION '(' ')'
rule_2195 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2195 = |_ctx, v, l, _loc, literal_0| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	m = Node.MergeSupportFunc({ ..Node.merge_support_func_default, msftype: literal_0, location: l1 })
	$result = m
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_QUERY '(' json_value_expr ',' a_expr json_passing_clause_opt json_returning_clause_opt json_wrapper_behavior json_quotes_clause_opt json_behavior_clause_opt ')'
rule_2196 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2196 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.int_at(v, 7)
	a9 = Rt.int_at(v, 8)
	a10 = Rt.list_at(v, 9)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonFuncExpr({ ..Node.json_func_expr_default, op: literal_0 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), context_item: a3 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), pathspec: a5, passing: a6 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), output: a7 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), wrapper: a8, quotes: a9 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), on_empty: Rt.linitial(a10) })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), on_error: Rt.lsecond(a10) })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_EXISTS '(' json_value_expr ',' a_expr json_passing_clause_opt json_on_error_clause_opt ')'
rule_2197 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2197 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonFuncExpr({ ..Node.json_func_expr_default, op: literal_0 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), context_item: a3 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), pathspec: a5, passing: a6, output: Null })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), on_error: a7 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## func_expr_common_subexpr: JSON_VALUE '(' json_value_expr ',' a_expr json_passing_clause_opt json_returning_clause_opt json_behavior_clause_opt ')'
rule_2198 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2198 = |_ctx, v, l, _loc, literal_0| {
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.list_at(v, 5)
	a7 = Rt.node_at(v, 6)
	a8 = Rt.list_at(v, 7)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonFuncExpr({ ..Node.json_func_expr_default, op: literal_0 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), context_item: a3 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), pathspec: a5, passing: a6 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), output: a7 })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), on_empty: Rt.linitial(a8) })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), on_error: Rt.lsecond(a8) })
	$n = Node.JsonFuncExpr({ ..Node.json_func_expr_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## xml_root_version: VERSION_P NO VALUE_P
rule_2200 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2200 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	$result = make_null_a_const((0 - literal_0))
	Ok(Rt.of_node($result))
}

## opt_xml_root_standalone: ',' STANDALONE_P YES_P
rule_2201 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2201 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $result = Rt.node_at(v, 0)
	$result = make_int_const(literal_0, (0 - literal_1))
	Ok(Rt.of_node($result))
}

## opt_xml_root_standalone: %empty
rule_2204 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2204 = |_ctx, _v, _l, _loc, literal_0, literal_1| {
	var $result = Null
	$result = make_int_const(literal_0, (0 - literal_1))
	Ok(Rt.of_node($result))
}

## xml_attribute_el: a_expr
rule_2209 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2209 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: Err(Null) })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: [] })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: a1 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## window_definition: ColId AS window_specification
rule_2232 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2232 = |_ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	var $a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a3
	$n = Node.WindowDef({ ..Node.window_def_of($n), name: a1 })
	$a3 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## over_clause: OVER ColId
rule_2234 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2234 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	n = Node.WindowDef({ ..Node.window_def_default, name: a2, refname: Err(Null), partition_clause: [], order_clause: [], frame_options: literal_0, start_offset: Null, end_offset: Null, location: l2 })
	$result = n
	Ok(Rt.of_node($result))
}

## window_specification: '(' opt_existing_window_name opt_partition_clause opt_sort_clause opt_frame_clause ')'
rule_2236 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2236 = |_ctx, v, l, _loc| {
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.node_at(v, 4)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.WindowDef({ ..Node.window_def_default, name: Err(Null), refname: a2, partition_clause: a3, order_clause: a4 })
	$n = Node.WindowDef({ ..Node.window_def_of($n), frame_options: Node.window_def_of(a5).frame_options })
	$n = Node.WindowDef({ ..Node.window_def_of($n), start_offset: Node.window_def_of(a5).start_offset })
	$n = Node.WindowDef({ ..Node.window_def_of($n), end_offset: Node.window_def_of(a5).end_offset })
	$n = Node.WindowDef({ ..Node.window_def_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_frame_clause: RANGE frame_extent opt_window_exclusion_clause
rule_2241 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2241 = |_ctx, v, _l, _loc, literal_0, literal_1| {
	var $a2 = Rt.node_at(v, 1)
	a3 = Rt.int_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = $a2
	$n = Node.WindowDef({ ..Node.window_def_of($n), frame_options: Rt.bit_or(Node.window_def_of($n).frame_options, Rt.bit_or(literal_0, literal_1)) })
	$a2 = $n
	$n = Node.WindowDef({ ..Node.window_def_of($n), frame_options: Rt.bit_or(Node.window_def_of($n).frame_options, a3) })
	$a2 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## opt_frame_clause: %empty
rule_2244 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2244 = |_ctx, _v, _l, _loc, literal_0| {
	var $result = Null
	n = Node.WindowDef({ ..Node.window_def_default, frame_options: literal_0, start_offset: Null, end_offset: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## frame_extent: frame_bound
rule_2245 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2245 = |ctx, v, l, _loc, literal_0, literal_1, literal_2| {
	var $a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = $a1
	if (Rt.bit_and(Node.window_def_of($n).frame_options, literal_0) != 0) {
		return Err(Rt.error(ctx, "42P20", Ok("frame start cannot be UNBOUNDED FOLLOWING"), l1))
	}
	if (Rt.bit_and(Node.window_def_of($n).frame_options, literal_1) != 0) {
		return Err(Rt.error(ctx, "42P20", Ok("frame starting from following row cannot end with current row"), l1))
	}
	$n = Node.WindowDef({ ..Node.window_def_of($n), frame_options: Rt.bit_or(Node.window_def_of($n).frame_options, literal_2) })
	$a1 = $n
	$result = $n
	Ok(Rt.of_node($result))
}

## frame_extent: BETWEEN frame_bound AND frame_bound
rule_2246 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2246 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4, literal_5, literal_6, literal_7, literal_8| {
	var $a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	l2 = Rt.location(l, 1)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $n1 = $a2
	n2 = a4
	var $frame_options = Node.window_def_of($n1).frame_options
	$frame_options = Rt.bit_or($frame_options, Rt.shift_left(Node.window_def_of(n2).frame_options, literal_0))
	$frame_options = Rt.bit_or($frame_options, literal_1)
	if (Rt.bit_and($frame_options, literal_2) != 0) {
		return Err(Rt.error(ctx, "42P20", Ok("frame start cannot be UNBOUNDED FOLLOWING"), l2))
	}
	if (Rt.bit_and($frame_options, literal_3) != 0) {
		return Err(Rt.error(ctx, "42P20", Ok("frame end cannot be UNBOUNDED PRECEDING"), l4))
	}
	if ((Rt.bit_and($frame_options, literal_4) != 0) and (Rt.bit_and($frame_options, literal_5) != 0)) {
		return Err(Rt.error(ctx, "42P20", Ok("frame starting from current row cannot have preceding rows"), l4))
	}
	if ((Rt.bit_and($frame_options, literal_6) != 0) and (Rt.bit_and($frame_options, Rt.bit_or(literal_7, literal_8)) != 0)) {
		return Err(Rt.error(ctx, "42P20", Ok("frame starting from following row cannot have preceding rows"), l4))
	}
	$n1 = Node.WindowDef({ ..Node.window_def_of($n1), frame_options: $frame_options })
	$a2 = $n1
	$n1 = Node.WindowDef({ ..Node.window_def_of($n1), end_offset: Node.window_def_of(n2).start_offset })
	$a2 = $n1
	$result = $n1
	Ok(Rt.of_node($result))
}

## frame_bound: UNBOUNDED PRECEDING
rule_2247 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2247 = |_ctx, v, _l, _loc, literal_0| {
	var $result = Rt.node_at(v, 0)
	n = Node.WindowDef({ ..Node.window_def_default, frame_options: literal_0, start_offset: Null, end_offset: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## frame_bound: a_expr PRECEDING
rule_2250 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2250 = |_ctx, v, _l, _loc, literal_0| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.node_at(v, 0)
	n = Node.WindowDef({ ..Node.window_def_default, frame_options: literal_0, start_offset: a1, end_offset: Null })
	$result = n
	Ok(Rt.of_node($result))
}

## row: '(' expr_list ',' a_expr ')'
rule_2259 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2259 = |_ctx, v, _l, _loc| {
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a2, a4)
	Ok(Rt.of_list($result))
}

## MathOp: '+'
rule_2268 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2268 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("+")
	Ok(Rt.of_text($result))
}

## MathOp: '-'
rule_2269 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2269 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("-")
	Ok(Rt.of_text($result))
}

## MathOp: '*'
rule_2270 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2270 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("*")
	Ok(Rt.of_text($result))
}

## MathOp: '/'
rule_2271 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2271 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("/")
	Ok(Rt.of_text($result))
}

## MathOp: '%'
rule_2272 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2272 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("%")
	Ok(Rt.of_text($result))
}

## MathOp: '^'
rule_2273 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2273 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("^")
	Ok(Rt.of_text($result))
}

## MathOp: '<'
rule_2274 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2274 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("<")
	Ok(Rt.of_text($result))
}

## MathOp: '>'
rule_2275 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2275 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok(">")
	Ok(Rt.of_text($result))
}

## MathOp: '='
rule_2276 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2276 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("=")
	Ok(Rt.of_text($result))
}

## MathOp: LESS_EQUALS
rule_2277 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2277 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("<=")
	Ok(Rt.of_text($result))
}

## MathOp: GREATER_EQUALS
rule_2278 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2278 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok(">=")
	Ok(Rt.of_text($result))
}

## MathOp: NOT_EQUALS
rule_2279 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2279 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("<>")
	Ok(Rt.of_text($result))
}

## subquery_Op: LIKE
rule_2286 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2286 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(Ok("~~")))
	Ok(Rt.of_list($result))
}

## subquery_Op: NOT_LA LIKE
rule_2287 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2287 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(Ok("!~~")))
	Ok(Rt.of_list($result))
}

## subquery_Op: ILIKE
rule_2288 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2288 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(Ok("~~*")))
	Ok(Rt.of_list($result))
}

## subquery_Op: NOT_LA ILIKE
rule_2289 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2289 = |_ctx, v, _l, _loc| {
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make1(make_string(Ok("!~~*")))
	Ok(Rt.of_list($result))
}

## func_arg_expr: param_name COLON_EQUALS a_expr
rule_2295 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2295 = |_ctx, v, l, _loc, literal_0| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $na = Node.NamedArgExpr({ ..Node.named_arg_expr_default, name: a1 })
	$na = Node.NamedArgExpr({ ..Node.named_arg_expr_of($na), arg: a3 })
	$na = Node.NamedArgExpr({ ..Node.named_arg_expr_of($na), argnumber: (0 - literal_0) })
	$na = Node.NamedArgExpr({ ..Node.named_arg_expr_of($na), location: l1 })
	$result = $na
	Ok(Rt.of_node($result))
}

## array_expr: '[' expr_list ']'
rule_2301 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2301 = |_ctx, v, l, _loc| {
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	l3 = Rt.location(l, 2)
	var $result = Rt.node_at(v, 0)
	$result = make_a_array_expr(a2, l1, l3)
	Ok(Rt.of_node($result))
}

## array_expr: '[' ']'
rule_2303 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2303 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_a_array_expr([], l1, l2)
	Ok(Rt.of_node($result))
}

## extract_list: extract_arg FROM a_expr
rule_2306 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2306 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a3 = Rt.node_at(v, 2)
	l1 = Rt.location(l, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(make_string_const(a1, l1), a3)
	Ok(Rt.of_list($result))
}

## extract_arg: YEAR_P
rule_2308 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2308 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("year")
	Ok(Rt.of_text($result))
}

## extract_arg: MONTH_P
rule_2309 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2309 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("month")
	Ok(Rt.of_text($result))
}

## extract_arg: DAY_P
rule_2310 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2310 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("day")
	Ok(Rt.of_text($result))
}

## extract_arg: HOUR_P
rule_2311 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2311 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("hour")
	Ok(Rt.of_text($result))
}

## extract_arg: MINUTE_P
rule_2312 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2312 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("minute")
	Ok(Rt.of_text($result))
}

## extract_arg: SECOND_P
rule_2313 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2313 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("second")
	Ok(Rt.of_text($result))
}

## unicode_normal_form: NFC
rule_2315 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2315 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("NFC")
	Ok(Rt.of_text($result))
}

## unicode_normal_form: NFD
rule_2316 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2316 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("NFD")
	Ok(Rt.of_text($result))
}

## unicode_normal_form: NFKC
rule_2317 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2317 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("NFKC")
	Ok(Rt.of_text($result))
}

## unicode_normal_form: NFKD
rule_2318 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2318 = |_ctx, v, _l, _loc| {
	var $result = Rt.text_at(v, 0)
	$result = Ok("NFKD")
	Ok(Rt.of_text($result))
}

## overlay_list: a_expr PLACING a_expr FROM a_expr FOR a_expr
rule_2319 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2319 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	a7 = Rt.node_at(v, 6)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make4(a1, a3, a5, a7)
	Ok(Rt.of_list($result))
}

## overlay_list: a_expr PLACING a_expr FROM a_expr
rule_2320 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2320 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make3(a1, a3, a5)
	Ok(Rt.of_list($result))
}

## position_list: b_expr IN_P b_expr
rule_2321 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2321 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a3, a1)
	Ok(Rt.of_list($result))
}

## substr_list: a_expr FOR a_expr FROM a_expr
rule_2323 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2323 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	a5 = Rt.node_at(v, 4)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make3(a1, a5, a3)
	Ok(Rt.of_list($result))
}

## substr_list: a_expr FROM a_expr
rule_2324 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2324 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, a3)
	Ok(Rt.of_list($result))
}

## substr_list: a_expr FOR a_expr
rule_2325 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2325 = |_ctx, v, _l, _loc, literal_0, literal_1, literal_2| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make3(a1, make_int_const(literal_0, (0 - literal_1)), make_type_cast(a3, system_type_name(Ok("int4")), (0 - literal_2)))
	Ok(Rt.of_list($result))
}

## trim_list: a_expr FROM expr_list
rule_2327 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2327 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.list_at(v, 2)
	var $result = Rt.list_at(v, 0)
	$result = Rt.lappend(a3, a1)
	Ok(Rt.of_list($result))
}

## case_expr: CASE case_arg when_clause_list case_default END_P
rule_2330 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2330 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $c = Node.CaseExpr({ ..Node.case_expr_default, casetype: literal_0 })
	$c = Node.CaseExpr({ ..Node.case_expr_of($c), arg: a2 })
	$c = Node.CaseExpr({ ..Node.case_expr_of($c), args: a3 })
	$c = Node.CaseExpr({ ..Node.case_expr_of($c), defresult: a4 })
	$c = Node.CaseExpr({ ..Node.case_expr_of($c), location: l1 })
	$result = $c
	Ok(Rt.of_node($result))
}

## when_clause: WHEN a_expr THEN a_expr
rule_2333 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2333 = |_ctx, v, l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $w = Node.CaseWhen(Node.case_when_default)
	$w = Node.CaseWhen({ ..Node.case_when_of($w), expr: a2 })
	$w = Node.CaseWhen({ ..Node.case_when_of($w), result: a4 })
	$w = Node.CaseWhen({ ..Node.case_when_of($w), location: l1 })
	$result = $w
	Ok(Rt.of_node($result))
}

## columnref: ColId
rule_2338 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2338 = |ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_column_ref(a1, [], l1, ctx)?
	Ok(Rt.of_node($result))
}

## columnref: ColId indirection
rule_2339 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2339 = |ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_column_ref(a1, a2, l1, ctx)?
	Ok(Rt.of_node($result))
}

## indirection_el: '.' attr_name
rule_2340 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2340 = |_ctx, v, _l, _loc| {
	a2 = Rt.text_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_string(a2)
	Ok(Rt.of_node($result))
}

## indirection_el: '[' a_expr ']'
rule_2342 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2342 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	ai = Node.AIndices({ ..Node.a_indices_default, is_slice: Bool.False, lidx: Null, uidx: a2 })
	$result = ai
	Ok(Rt.of_node($result))
}

## indirection_el: '[' opt_slice_bound ':' opt_slice_bound ']'
rule_2343 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2343 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.node_at(v, 0)
	ai = Node.AIndices({ ..Node.a_indices_default, is_slice: Bool.True, lidx: a2, uidx: a4 })
	$result = ai
	Ok(Rt.of_node($result))
}

## json_argument: json_value_expr AS ColLabel
rule_2356 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2356 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.text_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonArgument(Node.json_argument_default)
	$n = Node.JsonArgument({ ..Node.json_argument_of($n), val: a1 })
	$n = Node.JsonArgument({ ..Node.json_argument_of($n), name: a3 })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_behavior: DEFAULT a_expr
rule_2366 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2366 = |_ctx, v, l, _loc, literal_0| {
	a2 = Rt.node_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_json_behavior(literal_0, a2, l1)
	Ok(Rt.of_node($result))
}

## json_behavior: json_behavior_type
rule_2367 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2367 = |_ctx, v, l, _loc| {
	a1 = Rt.int_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_json_behavior(a1, Null, l1)
	Ok(Rt.of_node($result))
}

## json_behavior_clause_opt: json_behavior ON ERROR_P
rule_2377 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2377 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(Null, a1)
	Ok(Rt.of_list($result))
}

## json_behavior_clause_opt: json_behavior ON EMPTY_P json_behavior ON ERROR_P
rule_2378 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2378 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a4 = Rt.node_at(v, 3)
	var $result = Rt.list_at(v, 0)
	$result = Rt.list_make2(a1, a4)
	Ok(Rt.of_list($result))
}

## json_value_expr: a_expr json_format_clause_opt
rule_2382 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2382 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.node_at(v, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_json_value_expr(a1, Null, a2)
	Ok(Rt.of_node($result))
}

## json_format_clause: FORMAT_LA JSON ENCODING name
rule_2383 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2383 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3| {
	a4 = Rt.text_at(v, 3)
	l1 = Rt.location(l, 0)
	l4 = Rt.location(l, 3)
	var $result = Rt.node_at(v, 0)
	var $encoding = 0.I64
	if !((Rt.pg_strcasecmp(a4, Ok("utf8")) != 0)) {
		$encoding = literal_0
	} else {
		if !((Rt.pg_strcasecmp(a4, Ok("utf16")) != 0)) {
			$encoding = literal_1
		} else {
			if !((Rt.pg_strcasecmp(a4, Ok("utf32")) != 0)) {
				$encoding = literal_2
			} else {
				return Err(Rt.error(ctx, "22023", Ok("unrecognized JSON encoding: ${Rt.text_str(a4)}"), l4))
			}
		}
	}
	$result = make_json_format(literal_3, $encoding, l1)
	Ok(Rt.of_node($result))
}

## json_format_clause: FORMAT_LA JSON
rule_2384 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2384 = |_ctx, v, l, _loc, literal_0, literal_1| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_json_format(literal_0, literal_1, l1)
	Ok(Rt.of_node($result))
}

## json_format_clause_opt: %empty
rule_2386 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2386 = |_ctx, _v, _l, _loc, literal_0, literal_1, literal_2| {
	var $result = Null
	$result = make_json_format(literal_0, literal_1, (0 - literal_2))
	Ok(Rt.of_node($result))
}

## json_returning_clause_opt: RETURNING Typename json_format_clause_opt
rule_2392 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2392 = |_ctx, v, _l, _loc| {
	a2 = Rt.node_at(v, 1)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonOutput({ ..Node.json_output_default, type_name: a2 })
	$n = Node.JsonOutput({ ..Node.json_output_of($n), returning: Node.JsonReturning(Node.json_returning_default) })
	$n = Node.JsonOutput({ ..Node.json_output_of($n), returning: Node.JsonReturning({ ..Node.json_returning_of(Node.json_output_of($n).returning), format: a3 }) })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_name_and_value: c_expr VALUE_P json_value_expr
rule_2406 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2406 = |_ctx, v, _l, _loc| {
	a1 = Rt.node_at(v, 0)
	a3 = Rt.node_at(v, 2)
	var $result = Rt.node_at(v, 0)
	$result = make_json_key_value(a1, a3)
	Ok(Rt.of_node($result))
}

## json_aggregate_func: JSON_OBJECTAGG '(' json_name_and_value json_object_constructor_null_clause_opt json_key_uniqueness_constraint_opt json_returning_clause_opt ')'
rule_2416 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2416 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.bool_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a6 = Rt.node_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonObjectAgg(Node.json_object_agg_default)
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), arg: a3 })
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), absent_on_null: a4, unique: a5 })
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), constructor: Node.JsonAggConstructor(Node.json_agg_constructor_default) })
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_object_agg_of($n).constructor), output: a6 }) })
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_object_agg_of($n).constructor), agg_order: [] }) })
	$n = Node.JsonObjectAgg({ ..Node.json_object_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_object_agg_of($n).constructor), location: l1 }) })
	$result = $n
	Ok(Rt.of_node($result))
}

## json_aggregate_func: JSON_ARRAYAGG '(' json_value_expr json_array_aggregate_order_by_clause_opt json_array_constructor_null_clause_opt json_returning_clause_opt ')'
rule_2417 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2417 = |_ctx, v, l, _loc| {
	a3 = Rt.node_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a5 = Rt.bool_at(v, 4)
	a6 = Rt.node_at(v, 5)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.JsonArrayAgg(Node.json_array_agg_default)
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), arg: a3 })
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), absent_on_null: a5 })
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), constructor: Node.JsonAggConstructor(Node.json_agg_constructor_default) })
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_array_agg_of($n).constructor), agg_order: a4 }) })
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_array_agg_of($n).constructor), output: a6 }) })
	$n = Node.JsonArrayAgg({ ..Node.json_array_agg_of($n), constructor: Node.JsonAggConstructor({ ..Node.json_agg_constructor_of(Node.json_array_agg_of($n).constructor), location: l1 }) })
	$result = $n
	Ok(Rt.of_node($result))
}

## target_el: a_expr BareColLabel
rule_2425 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2425 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: a2 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: [] })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: a1 })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## target_el: '*'
rule_2427 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2427 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.ColumnRef(Node.column_ref_default)
	$n = Node.ColumnRef({ ..Node.column_ref_of($n), fields: Rt.list_make1(Node.AStar(Node.a_star_default)) })
	$n = Node.ColumnRef({ ..Node.column_ref_of($n), location: l1 })
	$result = Node.ResTarget(Node.res_target_default)
	$result = Node.ResTarget({ ..Node.res_target_of($result), name: Err(Null) })
	$result = Node.ResTarget({ ..Node.res_target_of($result), indirection: [] })
	$result = Node.ResTarget({ ..Node.res_target_of($result), val: $n })
	$result = Node.ResTarget({ ..Node.res_target_of($result), location: l1 })
	Ok(Rt.of_node($result))
}

## qualified_name: ColId
rule_2430 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2430 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_range_var(Err(Null), a1, l1)
	Ok(Rt.of_node($result))
}

## qualified_name: ColId indirection
rule_2431 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2431 = |ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_range_var_from_qualified_name(a1, a2, l1, ctx)?
	Ok(Rt.of_node($result))
}

## func_name: ColId indirection
rule_2438 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2438 = |ctx, v, _l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	var $result = Rt.list_at(v, 0)
	$result = check_func_name(Rt.lcons(make_string(a1), a2), ctx)?
	Ok(Rt.of_list($result))
}

## AexprConst: BCONST
rule_2442 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2442 = |_ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_bit_string_const(a1, l1)
	Ok(Rt.of_node($result))
}

## AexprConst: func_name Sconst
rule_2444 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2444 = |_ctx, v, l, _loc| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.text_at(v, 1)
	l1 = Rt.location(l, 0)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $t = make_type_name_from_name_list(a1)
	$t = Node.TypeName({ ..Node.type_name_of($t), location: l1 })
	$result = make_string_const_cast(a2, l2, $t)
	Ok(Rt.of_node($result))
}

## AexprConst: func_name '(' func_arg_list opt_sort_clause ')' Sconst
rule_2445 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2445 = |ctx, v, l, _loc| {
	a1 = Rt.list_at(v, 0)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.list_at(v, 3)
	a6 = Rt.text_at(v, 5)
	l1 = Rt.location(l, 0)
	l4 = Rt.location(l, 3)
	l6 = Rt.location(l, 5)
	var $result = Rt.node_at(v, 0)
	var $t = make_type_name_from_name_list(a1)
	lc_list = a3
	var $lc_index = 0
	while $lc_index < lc_list.len() {
		arg = (lc_list.get($lc_index) ?? Null)
		if (Node.tag(arg) == "NamedArgExpr") {
			return Err(Rt.error(ctx, "42601", Ok("type modifier cannot have parameter name"), Node.named_arg_expr_of(arg).location))
		}
		$lc_index = $lc_index + 1
	}
	if !((a4).is_empty()) {
		return Err(Rt.error(ctx, "42601", Ok("type modifier cannot have ORDER BY"), l4))
	}
	$t = Node.TypeName({ ..Node.type_name_of($t), typmods: a3, location: l1 })
	$result = make_string_const_cast(a6, l6, $t)
	Ok(Rt.of_node($result))
}

## AexprConst: ConstTypename Sconst
rule_2446 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2446 = |_ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	a2 = Rt.text_at(v, 1)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	$result = make_string_const_cast(a2, l2, a1)
	Ok(Rt.of_node($result))
}

## AexprConst: ConstInterval Sconst opt_interval
rule_2447 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2447 = |_ctx, v, l, _loc| {
	var $a1 = Rt.node_at(v, 0)
	a2 = Rt.text_at(v, 1)
	a3 = Rt.list_at(v, 2)
	l2 = Rt.location(l, 1)
	var $result = Rt.node_at(v, 0)
	var $t = $a1
	$t = Node.TypeName({ ..Node.type_name_of($t), typmods: a3 })
	$a1 = $t
	$result = make_string_const_cast(a2, l2, $t)
	Ok(Rt.of_node($result))
}

## AexprConst: TRUE_P
rule_2449 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2449 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_bool_a_const(Bool.True, l1)
	Ok(Rt.of_node($result))
}

## AexprConst: FALSE_P
rule_2450 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2450 = |_ctx, v, l, _loc| {
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	$result = make_bool_a_const(Bool.False, l1)
	Ok(Rt.of_node($result))
}

## SignedIconst: '-' Iconst
rule_2456 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2456 = |_ctx, v, _l, _loc| {
	a2 = Rt.int_at(v, 1)
	var $result = Rt.int_at(v, 0)
	$result = (0 - a2)
	Ok(Rt.of_int($result))
}

## RoleId: RoleSpec
rule_2457 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2457 = |ctx, v, l, _loc| {
	a1 = Rt.node_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.text_at(v, 0)
	spc = a1
	match Node.role_spec_of(spc).roletype {
		0 => {
			$result = Node.role_spec_of(spc).rolename
		}
		4 => {
			return Err(Rt.error(ctx, "42939", Ok("role name \"${Rt.text_str(Ok("public"))}\" is reserved"), l1))
		}
		3 => {
			return Err(Rt.error(ctx, "42939", Ok("${Rt.text_str(Ok("SESSION_USER"))} cannot be used as a role name here"), l1))
		}
		2 => {
			return Err(Rt.error(ctx, "42939", Ok("${Rt.text_str(Ok("CURRENT_USER"))} cannot be used as a role name here"), l1))
		}
		1 => {
			return Err(Rt.error(ctx, "42939", Ok("${Rt.text_str(Ok("CURRENT_ROLE"))} cannot be used as a role name here"), l1))
		}
		_ => {}
	}
	Ok(Rt.of_text($result))
}

## RoleSpec: NonReservedWord
rule_2458 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64, I64, I64, I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2458 = |ctx, v, l, _loc, literal_0, literal_1, literal_2, literal_3, literal_4| {
	a1 = Rt.text_at(v, 0)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Null
	if (Rt.strcmp(a1, Ok("public")) == literal_0) {
		$n = make_role_spec(literal_1, l1)
		$n = Node.RoleSpec({ ..Node.role_spec_of($n), roletype: literal_2 })
	} else {
		if (Rt.strcmp(a1, Ok("none")) == literal_3) {
			return Err(Rt.error(ctx, "42939", Ok("role name \"${Rt.text_str(Ok("none"))}\" is reserved"), l1))
		} else {
			$n = make_role_spec(literal_4, l1)
			$n = Node.RoleSpec({ ..Node.role_spec_of($n), rolename: a1 })
		}
	}
	$result = $n
	Ok(Rt.of_node($result))
}

## PLpgSQL_Expr: opt_distinct_clause opt_target_list from_clause where_clause group_clause having_clause window_clause opt_sort_clause opt_select_limit opt_for_locking_clause
rule_2464 : Rt.Ctx, List(Rt.Value), List(I64), I64, I64 -> Try(Rt.Value, Scan.Problem)
rule_2464 = |ctx, v, _l, _loc, literal_0| {
	a1 = Rt.list_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a3 = Rt.list_at(v, 2)
	a4 = Rt.node_at(v, 3)
	a5 = Rt.node_at(v, 4)
	a6 = Rt.node_at(v, 5)
	a7 = Rt.list_at(v, 6)
	a8 = Rt.list_at(v, 7)
	a9 = Rt.node_at(v, 8)
	a10 = Rt.list_at(v, 9)
	var $result = Rt.node_at(v, 0)
	var $n = Node.SelectStmt({ ..Node.select_stmt_default, distinct_clause: a1, target_list: a2, from_clause: a3, where_clause: a4 })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_clause: Node.group_clause_of(a5).list })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), group_distinct: Node.group_clause_of(a5).distinct })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), having_clause: a6, window_clause: a7, sort_clause: a8 })
	if !Node.is_null(a9) {
		$n = Node.SelectStmt({ ..Node.select_stmt_of($n), limit_offset: Node.select_limit_of(a9).limit_offset })
		$n = Node.SelectStmt({ ..Node.select_stmt_of($n), limit_count: Node.select_limit_of(a9).limit_count })
		if (!(!(Node.select_stmt_of($n).sort_clause).is_empty()) and (Node.select_limit_of(a9).limit_option == literal_0)) {
			return Err(Rt.error(ctx, "42601", Ok("WITH TIES cannot be specified without ORDER BY clause"), Node.select_limit_of(a9).option_loc))
		}
		$n = Node.SelectStmt({ ..Node.select_stmt_of($n), limit_option: Node.select_limit_of(a9).limit_option })
	}
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), locking_clause: a10 })
	$result = $n
	Ok(Rt.of_node($result))
}

## PLAssignStmt: plassign_target opt_indirection plassign_equals PLpgSQL_Expr
rule_2465 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2465 = |ctx, v, l, _loc| {
	a1 = Rt.text_at(v, 0)
	a2 = Rt.list_at(v, 1)
	a4 = Rt.node_at(v, 3)
	l1 = Rt.location(l, 0)
	var $result = Rt.node_at(v, 0)
	var $n = Node.PLAssignStmt({ ..Node.pl_assign_stmt_default, name: a1 })
	$n = Node.PLAssignStmt({ ..Node.pl_assign_stmt_of($n), indirection: check_indirection(a2, ctx)? })
	$n = Node.PLAssignStmt({ ..Node.pl_assign_stmt_of($n), val: a4 })
	$n = Node.PLAssignStmt({ ..Node.pl_assign_stmt_of($n), location: l1 })
	$result = $n
	Ok(Rt.of_node($result))
}

## plassign_target: PARAM
rule_2467 : Rt.Ctx, List(Rt.Value), List(I64), I64 -> Try(Rt.Value, Scan.Problem)
rule_2467 = |_ctx, v, _l, _loc| {
	a1 = Rt.int_at(v, 0)
	var $result = Rt.text_at(v, 0)
	$result = Ok("$${Rt.int_str(a1)}")
	Ok(Rt.of_text($result))
}

expr_location : Node -> I64
expr_location = |expr_arg| {
	var $loc = 0.I64
	if Node.is_null(expr_arg) {
		return (0 - 1)
	}
	match Node.tag(expr_arg) {
		"RangeVar" => {
			$loc = Node.range_var_of(expr_arg).location
		}
		"GroupingFunc" => {
			$loc = Node.grouping_func_of(expr_arg).location
		}
		"MergeSupportFunc" => {
			$loc = Node.merge_support_func_of(expr_arg).location
		}
		"NamedArgExpr" => {
			na = expr_arg
			$loc = leftmost_loc(Node.named_arg_expr_of(na).location, expr_location(Node.named_arg_expr_of(na).arg))
		}
		"BoolExpr" => {
			bexpr = expr_arg
			$loc = leftmost_loc(Node.bool_expr_of(bexpr).location, expr_location(Rt.list_node(Node.bool_expr_of(bexpr).args)))
		}
		"SubLink" => {
			sublink = expr_arg
			$loc = leftmost_loc(expr_location(Node.sub_link_of(sublink).testexpr), Node.sub_link_of(sublink).location)
		}
		"CaseExpr" => {
			$loc = Node.case_expr_of(expr_arg).location
		}
		"CaseWhen" => {
			$loc = Node.case_when_of(expr_arg).location
		}
		"RowExpr" => {
			$loc = Node.row_expr_of(expr_arg).location
		}
		"CoalesceExpr" => {
			$loc = Node.coalesce_expr_of(expr_arg).location
		}
		"MinMaxExpr" => {
			$loc = Node.min_max_expr_of(expr_arg).location
		}
		"SQLValueFunction" => {
			$loc = Node.sql_value_function_of(expr_arg).location
		}
		"XmlExpr" => {
			xexpr = expr_arg
			$loc = leftmost_loc(Node.xml_expr_of(xexpr).location, expr_location(Rt.list_node(Node.xml_expr_of(xexpr).args)))
		}
		"JsonFormat" => {
			$loc = Node.json_format_of(expr_arg).location
		}
		"JsonValueExpr" => {
			$loc = expr_location(Node.json_value_expr_of(expr_arg).raw_expr)
		}
		"JsonIsPredicate" => {
			$loc = Node.json_is_predicate_of(expr_arg).location
		}
		"JsonBehavior" => {
			$loc = expr_location(Node.json_behavior_of(expr_arg).expr)
		}
		"NullTest" => {
			nexpr = expr_arg
			$loc = leftmost_loc(Node.null_test_of(nexpr).location, expr_location(Node.null_test_of(nexpr).arg))
		}
		"BooleanTest" => {
			bexpr_2 = expr_arg
			$loc = leftmost_loc(Node.boolean_test_of(bexpr_2).location, expr_location(Node.boolean_test_of(bexpr_2).arg))
		}
		"SetToDefault" => {
			$loc = Node.set_to_default_of(expr_arg).location
		}
		"IntoClause" => {
			$loc = expr_location(Node.into_clause_of(expr_arg).rel)
		}
		"List" => {
			$loc = (0 - 1)
			lc_list = Rt.node_list(expr_arg)
			var $lc_index = 0
			while $lc_index < lc_list.len() {
				$loc = expr_location((lc_list.get($lc_index) ?? Null))
				if ($loc >= 0) {
					break
				}
				$lc_index = $lc_index + 1
			}
		}
		"A_Expr" => {
			aexpr = expr_arg
			$loc = leftmost_loc(Node.a_expr_of(aexpr).location, expr_location(Node.a_expr_of(aexpr).lexpr))
		}
		"ColumnRef" => {
			$loc = Node.column_ref_of(expr_arg).location
		}
		"ParamRef" => {
			$loc = Node.param_ref_of(expr_arg).location
		}
		"A_Const" => {
			$loc = Node.a_const_of(expr_arg).location
		}
		"FuncCall" => {
			fc = expr_arg
			$loc = leftmost_loc(Node.func_call_of(fc).location, expr_location(Rt.list_node(Node.func_call_of(fc).args)))
		}
		"A_ArrayExpr" => {
			$loc = Node.a_array_expr_of(expr_arg).location
		}
		"ResTarget" => {
			$loc = Node.res_target_of(expr_arg).location
		}
		"MultiAssignRef" => {
			$loc = expr_location(Node.multi_assign_ref_of(expr_arg).source)
		}
		"TypeCast" => {
			tc = expr_arg
			$loc = expr_location(Node.type_cast_of(tc).arg)
			$loc = leftmost_loc($loc, Node.type_name_of(Node.type_cast_of(tc).type_name).location)
			$loc = leftmost_loc($loc, Node.type_cast_of(tc).location)
		}
		"CollateClause" => {
			$loc = expr_location(Node.collate_clause_of(expr_arg).arg)
		}
		"SortBy" => {
			$loc = expr_location(Node.sort_by_of(expr_arg).node)
		}
		"WindowDef" => {
			$loc = Node.window_def_of(expr_arg).location
		}
		"RangeTableSample" => {
			$loc = Node.range_table_sample_of(expr_arg).location
		}
		"TypeName" => {
			$loc = Node.type_name_of(expr_arg).location
		}
		"ColumnDef" => {
			$loc = Node.column_def_of(expr_arg).location
		}
		"Constraint" => {
			$loc = Node.constraint_of(expr_arg).location
		}
		"FunctionParameter" => {
			$loc = Node.function_parameter_of(expr_arg).location
		}
		"XmlSerialize" => {
			$loc = Node.xml_serialize_of(expr_arg).location
		}
		"GroupingSet" => {
			$loc = Node.grouping_set_of(expr_arg).location
		}
		"WithClause" => {
			$loc = Node.with_clause_of(expr_arg).location
		}
		"InferClause" => {
			$loc = Node.infer_clause_of(expr_arg).location
		}
		"OnConflictClause" => {
			$loc = Node.on_conflict_clause_of(expr_arg).location
		}
		"CTESearchClause" => {
			$loc = Node.cte_search_clause_of(expr_arg).location
		}
		"CTECycleClause" => {
			$loc = Node.cte_cycle_clause_of(expr_arg).location
		}
		"CommonTableExpr" => {
			$loc = Node.common_table_expr_of(expr_arg).location
		}
		"JsonKeyValue" => {
			$loc = expr_location(Node.json_key_value_of(expr_arg).key)
		}
		"JsonObjectConstructor" => {
			$loc = Node.json_object_constructor_of(expr_arg).location
		}
		"JsonArrayConstructor" => {
			$loc = Node.json_array_constructor_of(expr_arg).location
		}
		"JsonArrayQueryConstructor" => {
			$loc = Node.json_array_query_constructor_of(expr_arg).location
		}
		"JsonAggConstructor" => {
			$loc = Node.json_agg_constructor_of(expr_arg).location
		}
		"JsonObjectAgg" => {
			$loc = expr_location(Node.json_object_agg_of(expr_arg).constructor)
		}
		"JsonArrayAgg" => {
			$loc = expr_location(Node.json_array_agg_of(expr_arg).constructor)
		}
		"PartitionElem" => {
			$loc = Node.partition_elem_of(expr_arg).location
		}
		"PartitionSpec" => {
			$loc = Node.partition_spec_of(expr_arg).location
		}
		"PartitionBoundSpec" => {
			$loc = Node.partition_bound_spec_of(expr_arg).location
		}
		_ => {
			$loc = (0 - 1)
		}
	}
	$loc
}

make_simple_a_expr : I64, Node.Text, Node, Node, I64 -> Node
make_simple_a_expr = |kind_arg, name_arg, lexpr_arg, rexpr_arg, location_arg| {
	var $a = Node.AExpr({ ..Node.a_expr_default, kind: kind_arg })
	$a = Node.AExpr({ ..Node.a_expr_of($a), name: Rt.list_make1(make_string(name_arg)) })
	$a = Node.AExpr({ ..Node.a_expr_of($a), lexpr: lexpr_arg, rexpr: rexpr_arg, location: location_arg })
	$a
}

make_range_var : Node.Text, Node.Text, I64 -> Node
make_range_var = |schemaname_arg, relname_arg, location_arg| {
	r = Node.RangeVar({ ..Node.range_var_default, catalogname: Err(Null), schemaname: schemaname_arg, relname: relname_arg, inh: Bool.True, relpersistence: 112, alias: Null, location: location_arg })
	r
}

make_type_cast : Node, Node, I64 -> Node
make_type_cast = |arg_arg, typename_arg, location_arg| {
	n = Node.TypeCast({ ..Node.type_cast_default, arg: arg_arg, type_name: typename_arg, location: location_arg })
	n
}

make_raw_stmt : Node, I64 -> Node
make_raw_stmt = |stmt_arg, stmt_location_arg| {
	rs = Node.RawStmt({ ..Node.raw_stmt_default, stmt: stmt_arg, stmt_location: stmt_location_arg, stmt_len: 0 })
	rs
}

make_def_elem : Node.Text, Node, I64 -> Node
make_def_elem = |name_arg, arg_arg, location_arg| {
	res = Node.DefElem({ ..Node.def_elem_default, defnamespace: Err(Null), defname: name_arg, arg: arg_arg, defaction: 0, location: location_arg })
	res
}

make_string : Node.Text -> Node
make_string = |str_arg| {
	v = Node.String({ ..Node.string_default, sval: str_arg })
	v
}

make_boolean : Bool -> Node
make_boolean = |val_arg| {
	v = Node.Boolean({ ..Node.boolean_default, boolval: val_arg })
	v
}

make_integer : I64 -> Node
make_integer = |i_arg| {
	v = Node.Integer({ ..Node.integer_default, ival: i_arg })
	v
}

make_string_const_cast : Node.Text, I64, Node -> Node
make_string_const_cast = |str_arg, location_arg, typename_arg| {
	s = make_string_const(str_arg, location_arg)
	make_type_cast(s, typename_arg, (0 - 1))
}

make_type_name_from_name_list : List(Node) -> Node
make_type_name_from_name_list = |names_arg| {
	var $n = Node.TypeName({ ..Node.type_name_default, names: names_arg, typmods: [] })
	$n = Node.TypeName({ ..Node.type_name_of($n), typemod: (0 - 1) })
	$n = Node.TypeName({ ..Node.type_name_of($n), location: (0 - 1) })
	$n
}

make_def_elem_extended : Node.Text, Node.Text, Node, I64, I64 -> Node
make_def_elem_extended = |name_space_arg, name_arg, arg_arg, defaction_arg, location_arg| {
	res = Node.DefElem({ ..Node.def_elem_default, defnamespace: name_space_arg, defname: name_arg, arg: arg_arg, defaction: defaction_arg, location: location_arg })
	res
}

def_get_int32 : Node, Rt.Ctx -> Try(I64, Scan.Problem)
def_get_int32 = |def_arg, ctx| {
	if Node.is_null(Node.def_elem_of(def_arg).arg) {
		return Err(Rt.error(ctx, "42601", Ok("${Rt.text_str(Node.def_elem_of(def_arg).defname)} requires an integer value"), (0 - 1)))
	}
	match Node.tag(Node.def_elem_of(def_arg).arg) {
		"Integer" => {
			Ok(Node.integer_of(Node.def_elem_of(def_arg).arg).ival)
		}
		_ => {
			Err(Rt.error(ctx, "42601", Ok("${Rt.text_str(Node.def_elem_of(def_arg).defname)} requires an integer value"), (0 - 1)))
		}
	}
}

make_range_var_from_any_name : List(Node), I64, Rt.Ctx -> Try(Node, Scan.Problem)
make_range_var_from_any_name = |names_arg, position_arg, ctx| {
	var $r = Node.RangeVar(Node.range_var_default)
	match Rt.list_length(names_arg) {
		1 => {
			$r = Node.RangeVar({ ..Node.range_var_of($r), catalogname: Err(Null), schemaname: Err(Null) })
			$r = Node.RangeVar({ ..Node.range_var_of($r), relname: Node.string_of(Rt.linitial(names_arg)).sval })
		}
		2 => {
			$r = Node.RangeVar({ ..Node.range_var_of($r), catalogname: Err(Null) })
			$r = Node.RangeVar({ ..Node.range_var_of($r), schemaname: Node.string_of(Rt.linitial(names_arg)).sval })
			$r = Node.RangeVar({ ..Node.range_var_of($r), relname: Node.string_of(Rt.lsecond(names_arg)).sval })
		}
		3 => {
			$r = Node.RangeVar({ ..Node.range_var_of($r), catalogname: Node.string_of(Rt.linitial(names_arg)).sval })
			$r = Node.RangeVar({ ..Node.range_var_of($r), schemaname: Node.string_of(Rt.lsecond(names_arg)).sval })
			$r = Node.RangeVar({ ..Node.range_var_of($r), relname: Node.string_of(Rt.lthird(names_arg)).sval })
		}
		_ => {
			return Err(Rt.error(ctx, "42601", Ok("improper qualified name (too many dotted names): ${Rt.text_str(name_list_to_string(names_arg))}"), position_arg))
		}
	}
	$r = Node.RangeVar({ ..Node.range_var_of($r), relpersistence: 112, location: position_arg })
	Ok($r)
}

parse_partition_strategy : Node.Text, I64, Rt.Ctx -> Try(I64, Scan.Problem)
parse_partition_strategy = |strategy_arg, location_arg, ctx| {
	if (Rt.pg_strcasecmp(strategy_arg, Ok("list")) == 0) {
		return Ok(108)
	} else {
		if (Rt.pg_strcasecmp(strategy_arg, Ok("range")) == 0) {
			return Ok(114)
		} else {
			if (Rt.pg_strcasecmp(strategy_arg, Ok("hash")) == 0) {
				return Ok(104)
			}
		}
	}
	Err(Rt.error(ctx, "22023", Ok("unrecognized partitioning strategy \"${Rt.text_str(strategy_arg)}\""), location_arg))
}

make_float : Node.Text -> Node
make_float = |numeric_str_arg| {
	v = Node.Float({ ..Node.float_default, fval: numeric_str_arg })
	v
}

make_role_spec : I64, I64 -> Node
make_role_spec = |type_arg, location_arg| {
	spec = Node.RoleSpec({ ..Node.role_spec_default, roletype: type_arg, location: location_arg })
	spec
}

merge_table_func_parameters : List(Node), List(Node), Rt.Ctx -> Try(List(Node), Scan.Problem)
merge_table_func_parameters = |func_args_arg, columns_arg, ctx| {
	lc_list = func_args_arg
	var $lc_index = 0
	while $lc_index < lc_list.len() {
		p = (lc_list.get($lc_index) ?? Null)
		if ((!((Node.function_parameter_of(p).mode == 100)) and !((Node.function_parameter_of(p).mode == 105))) and !((Node.function_parameter_of(p).mode == 118))) {
			return Err(Rt.error(ctx, "42601", Ok("OUT and INOUT arguments aren't allowed in TABLE functions"), Node.function_parameter_of(p).location))
		}
		$lc_index = $lc_index + 1
	}
	Ok(Rt.list_concat(func_args_arg, columns_arg))
}

table_func_type_name : List(Node) -> Node
table_func_type_name = |columns_arg| {
	var $result = Null
	if (Rt.list_length(columns_arg) == 1) {
		p = Rt.linitial(columns_arg)
		$result = Node.function_parameter_of(p).arg_type
	} else {
		$result = system_type_name(Ok("record"))
	}
	$result = Node.TypeName({ ..Node.type_name_of($result), setof: Bool.True })
	$result
}

extract_arg_types : List(Node) -> List(Node)
extract_arg_types = |parameters_arg| {
	var $result = []
	i_list = parameters_arg
	var $i_index = 0
	while $i_index < i_list.len() {
		p = (i_list.get($i_index) ?? Null)
		if (!((Node.function_parameter_of(p).mode == 111)) and !((Node.function_parameter_of(p).mode == 116))) {
			$result = Rt.lappend($result, Node.function_parameter_of(p).arg_type)
		}
		$i_index = $i_index + 1
	}
	$result
}

check_func_name : List(Node), Rt.Ctx -> Try(List(Node), Scan.Problem)
check_func_name = |names_arg, ctx| {
	i_list = names_arg
	var $i_index = 0
	while $i_index < i_list.len() {
		if !((Node.tag((i_list.get($i_index) ?? Null)) == "String")) {
			return Err(Rt.yyerror(ctx, Ok("syntax error")))
		}
		$i_index = $i_index + 1
	}
	Ok(names_arg)
}

make_ordered_set_args : List(Node), List(Node), Rt.Ctx -> Try(List(Node), Scan.Problem)
make_ordered_set_args = |directargs_arg, orderedargs_arg, ctx| {
	var $orderedargs = orderedargs_arg
	lastd = Rt.llast(directargs_arg)
	var $ndirectargs = Null
	if (Node.function_parameter_of(lastd).mode == 118) {
		firsto = Rt.linitial($orderedargs)
		if ((!((Rt.list_length($orderedargs) == 1)) or !((Node.function_parameter_of(firsto).mode == 118))) or !(Rt.equal(Node.function_parameter_of(lastd).arg_type, Node.function_parameter_of(firsto).arg_type))) {
			return Err(Rt.error(ctx, "0A000", Ok("an ordered-set aggregate with a VARIADIC direct argument must have one VARIADIC aggregated argument of the same data type"), Node.function_parameter_of(firsto).location))
		}
		$orderedargs = []
	}
	$ndirectargs = make_integer(Rt.list_length(directargs_arg))
	Ok(Rt.list_make2(Rt.list_node(Rt.list_concat(directargs_arg, $orderedargs)), $ndirectargs))
}

extract_aggr_arg_types : List(Node) -> List(Node)
extract_aggr_arg_types = |aggrargs_arg| {
	extract_arg_types(Rt.node_list(Rt.linitial(aggrargs_arg)))
}

make_range_var_from_qualified_name : Node.Text, List(Node), I64, Rt.Ctx -> Try(Node, Scan.Problem)
make_range_var_from_qualified_name = |name_arg, namelist_arg, location_arg, ctx| {
	var $r = Null
	_ = check_qualified_name(namelist_arg, ctx)?
	$r = make_range_var(Err(Null), Err(Null), location_arg)
	match Rt.list_length(namelist_arg) {
		1 => {
			$r = Node.RangeVar({ ..Node.range_var_of($r), catalogname: Err(Null), schemaname: name_arg })
			$r = Node.RangeVar({ ..Node.range_var_of($r), relname: Node.string_of(Rt.linitial(namelist_arg)).sval })
		}
		2 => {
			$r = Node.RangeVar({ ..Node.range_var_of($r), catalogname: name_arg })
			$r = Node.RangeVar({ ..Node.range_var_of($r), schemaname: Node.string_of(Rt.linitial(namelist_arg)).sval })
			$r = Node.RangeVar({ ..Node.range_var_of($r), relname: Node.string_of(Rt.lsecond(namelist_arg)).sval })
		}
		_ => {
			return Err(Rt.error(ctx, "42601", Ok("improper qualified name (too many dotted names): ${Rt.text_str(name_list_to_string(Rt.lcons(make_string(name_arg), namelist_arg)))}"), location_arg))
		}
	}
	Ok($r)
}

make_recursive_view_select : Node.Text, List(Node), Node, Rt.Ctx -> Try(Node, Scan.Problem)
make_recursive_view_select = |relname_arg, aliases_arg, query_arg, ctx| {
	var $s = Node.SelectStmt(Node.select_stmt_default)
	var $w = Node.WithClause(Node.with_clause_default)
	var $cte = Node.CommonTableExpr(Node.common_table_expr_default)
	var $tl = []
	$cte = Node.CommonTableExpr({ ..Node.common_table_expr_of($cte), ctename: relname_arg, aliascolnames: aliases_arg, ctematerialized: 0, ctequery: query_arg })
	$cte = Node.CommonTableExpr({ ..Node.common_table_expr_of($cte), location: (0 - 1) })
	$w = Node.WithClause({ ..Node.with_clause_of($w), recursive: Bool.True })
	$w = Node.WithClause({ ..Node.with_clause_of($w), ctes: Rt.list_make1($cte) })
	$w = Node.WithClause({ ..Node.with_clause_of($w), location: (0 - 1) })
	lc_list = aliases_arg
	var $lc_index = 0
	while $lc_index < lc_list.len() {
		var $rt = Node.ResTarget({ ..Node.res_target_default, name: Err(Null), indirection: [] })
		$rt = Node.ResTarget({ ..Node.res_target_of($rt), val: make_column_ref(Node.string_of((lc_list.get($lc_index) ?? Null)).sval, [], (0 - 1), ctx)? })
		$rt = Node.ResTarget({ ..Node.res_target_of($rt), location: (0 - 1) })
		$tl = Rt.lappend($tl, $rt)
		$lc_index = $lc_index + 1
	}
	$s = Node.SelectStmt({ ..Node.select_stmt_of($s), with_clause: $w, target_list: $tl })
	$s = Node.SelectStmt({ ..Node.select_stmt_of($s), from_clause: Rt.list_make1(make_range_var(Err(Null), relname_arg, (0 - 1))) })
	Ok($s)
}

make_vacuum_relation : Node, I64, List(Node) -> Node
make_vacuum_relation = |relation_arg, oid_arg, va_cols_arg| {
	v = Node.VacuumRelation({ ..Node.vacuum_relation_default, relation: relation_arg, oid: oid_arg, va_cols: va_cols_arg })
	v
}

make_alias : Node.Text, List(Node) -> Node
make_alias = |aliasname_arg, colnames_arg| {
	var $a = Node.Alias(Node.alias_default)
	$a = Node.Alias({ ..Node.alias_of($a), aliasname: aliasname_arg })
	$a = Node.Alias({ ..Node.alias_of($a), colnames: colnames_arg })
	$a
}

check_indirection : List(Node), Rt.Ctx -> Try(List(Node), Scan.Problem)
check_indirection = |indirection_arg, ctx| {
	l_list = indirection_arg
	var $l_index = 0
	while $l_index < l_list.len() {
		if (Node.tag((l_list.get($l_index) ?? Null)) == "A_Star") {
			if !(!Rt.cell_is_set(Rt.cell(l_list, $l_index + 1))) {
				return Err(Rt.yyerror(ctx, Ok("improper use of \"*\"")))
			}
		}
		$l_index = $l_index + 1
	}
	Ok(indirection_arg)
}

make_set_op : I64, Bool, Node, Node -> Node
make_set_op = |op_arg, all_arg, larg_arg, rarg_arg| {
	var $n = Node.SelectStmt({ ..Node.select_stmt_default, op: op_arg, all: all_arg })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), larg: larg_arg })
	$n = Node.SelectStmt({ ..Node.select_stmt_of($n), rarg: rarg_arg })
	$n
}

make_grouping_set : I64, List(Node), I64 -> Node
make_grouping_set = |kind_arg, content_arg, location_arg| {
	n = Node.GroupingSet({ ..Node.grouping_set_default, kind: kind_arg, content: content_arg, location: location_arg })
	n
}

make_json_table_path_spec : Node.Text, Node.Text, I64, I64 -> Node
make_json_table_path_spec = |string_arg, name_arg, string_location_arg, name_location_arg| {
	var $pathspec = Node.JsonTablePathSpec(Node.json_table_path_spec_default)
	$pathspec = Node.JsonTablePathSpec({ ..Node.json_table_path_spec_of($pathspec), string: make_string_const(string_arg, string_location_arg) })
	if !(!Rt.text_is_set(name_arg)) {
		$pathspec = Node.JsonTablePathSpec({ ..Node.json_table_path_spec_of($pathspec), name: name_arg })
	}
	$pathspec = Node.JsonTablePathSpec({ ..Node.json_table_path_spec_of($pathspec), name_location: name_location_arg, location: string_location_arg })
	$pathspec
}

make_json_format : I64, I64, I64 -> Node
make_json_format = |type_arg, encoding_arg, location_arg| {
	jf = Node.JsonFormat({ ..Node.json_format_default, format_type: type_arg, encoding: encoding_arg, location: location_arg })
	jf
}

make_type_name : Node.Text -> Node
make_type_name = |typnam_arg| {
	make_type_name_from_name_list(Rt.list_make1(make_string(typnam_arg)))
}

system_type_name : Node.Text -> Node
system_type_name = |name_arg| {
	make_type_name_from_name_list(Rt.list_make2(make_string(Ok("pg_catalog")), make_string(name_arg)))
}

make_func_call : List(Node), List(Node), I64, I64 -> Node
make_func_call = |name_arg, args_arg, funcformat_arg, location_arg| {
	n = Node.FuncCall({ ..Node.func_call_default, funcname: name_arg, args: args_arg, agg_order: [], agg_filter: Null, over: Null, agg_within_group: Bool.False, agg_star: Bool.False, agg_distinct: Bool.False, func_variadic: Bool.False, funcformat: funcformat_arg, location: location_arg })
	n
}

system_func_name : Node.Text -> List(Node)
system_func_name = |name_arg| {
	Rt.list_make2(make_string(Ok("pg_catalog")), make_string(name_arg))
}

make_a_expr : I64, List(Node), Node, Node, I64 -> Node
make_a_expr = |kind_arg, name_arg, lexpr_arg, rexpr_arg, location_arg| {
	a = Node.AExpr({ ..Node.a_expr_default, kind: kind_arg, name: name_arg, lexpr: lexpr_arg, rexpr: rexpr_arg, location: location_arg })
	a
}

make_and_expr : Node, Node, I64 -> Node
make_and_expr = |lexpr_arg, rexpr_arg, location_arg| {
	var $lexpr = lexpr_arg
	if (Node.tag($lexpr) == "BoolExpr") {
		var $blexpr = $lexpr
		if (Node.bool_expr_of($blexpr).boolop == 0) {
			$blexpr = Node.BoolExpr({ ..Node.bool_expr_of($blexpr), args: Rt.lappend(Node.bool_expr_of($blexpr).args, rexpr_arg) })
			$lexpr = $blexpr
			return $blexpr
		}
	}
	make_bool_expr(0, Rt.list_make2($lexpr, rexpr_arg), location_arg)
}

make_or_expr : Node, Node, I64 -> Node
make_or_expr = |lexpr_arg, rexpr_arg, location_arg| {
	var $lexpr = lexpr_arg
	if (Node.tag($lexpr) == "BoolExpr") {
		var $blexpr = $lexpr
		if (Node.bool_expr_of($blexpr).boolop == 1) {
			$blexpr = Node.BoolExpr({ ..Node.bool_expr_of($blexpr), args: Rt.lappend(Node.bool_expr_of($blexpr).args, rexpr_arg) })
			$lexpr = $blexpr
			return $blexpr
		}
	}
	make_bool_expr(1, Rt.list_make2($lexpr, rexpr_arg), location_arg)
}

make_not_expr : Node, I64 -> Node
make_not_expr = |expr_arg, location_arg| {
	make_bool_expr(2, Rt.list_make1(expr_arg), location_arg)
}

make_xml_expr : I64, Node.Text, List(Node), List(Node), I64 -> Node
make_xml_expr = |op_arg, name_arg, named_args_arg, args_arg, location_arg| {
	x = Node.XmlExpr({ ..Node.xml_expr_default, op: op_arg, name: name_arg, named_args: named_args_arg, arg_names: [], args: args_arg, type: 0, location: location_arg })
	x
}

make_json_is_predicate : Node, Node, I64, Bool, I64 -> Node
make_json_is_predicate = |expr_arg, format_arg, item_type_arg, unique_keys_arg, location_arg| {
	var $n = Node.JsonIsPredicate(Node.json_is_predicate_default)
	$n = Node.JsonIsPredicate({ ..Node.json_is_predicate_of($n), expr: expr_arg, format: format_arg, item_type: item_type_arg, unique_keys: unique_keys_arg, location: location_arg })
	$n
}

make_sql_value_function : I64, I64, I64 -> Node
make_sql_value_function = |op_arg, typmod_arg, location_arg| {
	svf = Node.SQLValueFunction({ ..Node.sql_value_function_default, op: op_arg, typmod: typmod_arg, location: location_arg })
	svf
}

make_a_array_expr : List(Node), I64, I64 -> Node
make_a_array_expr = |elements_arg, location_arg, location_end_arg| {
	n = Node.AArrayExpr({ ..Node.a_array_expr_default, elements: elements_arg, location: location_arg, list_start: location_arg, list_end: location_end_arg })
	n
}

make_column_ref : Node.Text, List(Node), I64, Rt.Ctx -> Try(Node, Scan.Problem)
make_column_ref = |colname_arg, indirection_arg, location_arg, ctx| {
	var $indirection = indirection_arg
	var $c = Node.ColumnRef(Node.column_ref_default)
	var $nfields = 0
	$c = Node.ColumnRef({ ..Node.column_ref_of($c), location: location_arg })
	l_list = $indirection
	var $l_index = 0
	while $l_index < l_list.len() {
		if (Node.tag((l_list.get($l_index) ?? Null)) == "A_Indices") {
			var $i = Node.AIndirection(Node.a_indirection_default)
			if ($nfields == 0) {
				$c = Node.ColumnRef({ ..Node.column_ref_of($c), fields: Rt.list_make1(make_string(colname_arg)) })
				$i = Node.AIndirection({ ..Node.a_indirection_of($i), indirection: check_indirection($indirection, ctx)? })
			} else {
				$i = Node.AIndirection({ ..Node.a_indirection_of($i), indirection: check_indirection(Rt.list_copy_tail($indirection, $nfields), ctx)? })
				$indirection = Rt.list_truncate($indirection, $nfields)
				$c = Node.ColumnRef({ ..Node.column_ref_of($c), fields: Rt.lcons(make_string(colname_arg), $indirection) })
			}
			$i = Node.AIndirection({ ..Node.a_indirection_of($i), arg: $c })
			return Ok($i)
		} else {
			if (Node.tag((l_list.get($l_index) ?? Null)) == "A_Star") {
				if !(!Rt.cell_is_set(Rt.cell(l_list, $l_index + 1))) {
					return Err(Rt.yyerror(ctx, Ok("improper use of \"*\"")))
				}
			}
		}
		$nfields = ($nfields + 1)
		$l_index = $l_index + 1
	}
	$c = Node.ColumnRef({ ..Node.column_ref_of($c), fields: Rt.lcons(make_string(colname_arg), $indirection) })
	Ok($c)
}

make_json_behavior : I64, Node, I64 -> Node
make_json_behavior = |btype_arg, expr_arg, location_arg| {
	behavior = Node.JsonBehavior({ ..Node.json_behavior_default, btype: btype_arg, expr: expr_arg, location: location_arg })
	behavior
}

make_json_value_expr : Node, Node, Node -> Node
make_json_value_expr = |raw_expr_arg, formatted_expr_arg, format_arg| {
	jve = Node.JsonValueExpr({ ..Node.json_value_expr_default, raw_expr: raw_expr_arg, formatted_expr: formatted_expr_arg, format: format_arg })
	jve
}

make_json_key_value : Node, Node -> Node
make_json_key_value = |key_arg, value_arg| {
	var $n = Node.JsonKeyValue(Node.json_key_value_default)
	$n = Node.JsonKeyValue({ ..Node.json_key_value_of($n), key: key_arg })
	$n = Node.JsonKeyValue({ ..Node.json_key_value_of($n), value: value_arg })
	$n
}

leftmost_loc : I64, I64 -> I64
leftmost_loc = |loc1_arg, loc2_arg| {
	if (loc1_arg < 0) {
		loc2_arg
	} else {
		if (loc2_arg < 0) {
			loc1_arg
		} else {
			Rt.min(loc1_arg, loc2_arg)
		}
	}
}

check_qualified_name : List(Node), Rt.Ctx -> Try({}, Scan.Problem)
check_qualified_name = |names_arg, ctx| {
	i_list = names_arg
	var $i_index = 0
	while $i_index < i_list.len() {
		if !((Node.tag((i_list.get($i_index) ?? Null)) == "String")) {
			return Err(Rt.yyerror(ctx, Ok("syntax error")))
		}
		$i_index = $i_index + 1
	}
	Ok({})
}

make_bool_expr : I64, List(Node), I64 -> Node
make_bool_expr = |boolop_arg, args_arg, location_arg| {
	b = Node.BoolExpr({ ..Node.bool_expr_default, boolop: boolop_arg, args: args_arg, location: location_arg })
	b
}

## ---- Ported by hand from gram.y (tools/actions_hand.roc) ----
##
## These helpers write through the pointers they are given (a union member,
## an argument the caller keeps using, or out-parameters), which the
## translator does not do. A written argument comes back in a record field
## named after its position, `a0`, `a1` and so on. A constant name between
## two at signs is filled in by the generator.

## makeIntConst
make_int_const : I64, I64 -> Node
make_int_const = |val, location| Node.AConst({ ..Node.a_const_default, val: Node.Integer({ ival: val }), location })

## makeFloatConst
make_float_const : Node.Text, I64 -> Node
make_float_const = |str, location| Node.AConst({ ..Node.a_const_default, val: Node.Float({ fval: str }), location })

## makeStringConst
make_string_const : Node.Text, I64 -> Node
make_string_const = |str, location| Node.AConst({ ..Node.a_const_default, val: Node.String({ sval: str }), location })

## makeBitStringConst
make_bit_string_const : Node.Text, I64 -> Node
make_bit_string_const = |str, location| Node.AConst({ ..Node.a_const_default, val: Node.BitString({ bsval: str }), location })

## makeBoolAConst
make_bool_a_const : Bool, I64 -> Node
make_bool_a_const = |state, location| Node.AConst({ ..Node.a_const_default, val: Node.Boolean({ boolval: state }), location })

## makeNullAConst
make_null_a_const : I64 -> Node
make_null_a_const = |location| Node.AConst({ ..Node.a_const_default, isnull: Bool.True, location })

## makeAConst: only called with an Integer or a Float.
make_a_const : Node, I64 -> Node
make_a_const = |v, location|
	match v {
		Float(f) => make_float_const(f.fval, location)
		Integer(i) => make_int_const(i.ival, location)
		_ => Null
	}

## doNegate: a negated number constant stays a constant, with the location
## of the minus sign; anything else becomes `- x`.
do_negate : Node, I64 -> Node
do_negate = |n, location|
	match n {
		AConst(con) => {
			moved = { ..con, location }
			match con.val {
				Integer(i) => Node.AConst({ ..moved, val: Node.Integer({ ival: 0 - i.ival }) })
				Float(f) => Node.AConst({ ..moved, val: Node.Float({ fval: negate_float(f.fval) }) })
				_ => make_simple_a_expr(0, Ok("-"), Null, Node.AConst(moved), location)
			}
		}
		_ => make_simple_a_expr(0, Ok("-"), Null, n, location)
	}

## doNegateFloat: strip a leading `-`, or add one, after any leading `+`.
negate_float : Node.Text -> Node.Text
negate_float = |fval| {
	bytes = Rt.text_str(fval).to_utf8()
	unsigned = if bytes.first() == Ok('+') bytes.drop_first(1) else bytes
	if unsigned.first() == Ok('-') {
		Ok(Str.from_utf8_lossy(unsigned.drop_first(1)))
	} else {
		Ok("-${Str.from_utf8_lossy(unsigned)}")
	}
}

## insertSelectOptions
insert_select_options : Node, List(Node), List(Node), Node, Node, Rt.Ctx -> Try({ a0 : Node }, Scan.Problem)
insert_select_options = |stmt_node, sort_clause, locking_clause, limit_clause, with_clause, ctx| {
	var $stmt = Node.select_stmt_of(stmt_node)
	if !sort_clause.is_empty() {
		if !$stmt.sort_clause.is_empty() {
			return Err(Rt.error(ctx, "42601", Ok("multiple ORDER BY clauses not allowed"), expr_location(Rt.list_node(sort_clause))))
		}
		$stmt = { ..$stmt, sort_clause }
	}
	$stmt = { ..$stmt, locking_clause: $stmt.locking_clause.concat(locking_clause) }
	match limit_clause {
		SelectLimit(limit) => {
			if !Node.is_null(limit.limit_offset) {
				if !Node.is_null($stmt.limit_offset) {
					return Err(Rt.error(ctx, "42601", Ok("multiple OFFSET clauses not allowed"), limit.offset_loc))
				}
				$stmt = { ..$stmt, limit_offset: limit.limit_offset }
			}
			if !Node.is_null(limit.limit_count) {
				if !Node.is_null($stmt.limit_count) {
					return Err(Rt.error(ctx, "42601", Ok("multiple LIMIT clauses not allowed"), limit.count_loc))
				}
				$stmt = { ..$stmt, limit_count: limit.limit_count }
			}
			if $stmt.sort_clause.is_empty() and limit.limit_option == 1 {
				return Err(Rt.error(ctx, "42601", Ok("WITH TIES cannot be specified without ORDER BY clause"), limit.option_loc))
			}
			if limit.limit_option == 1 and !$stmt.locking_clause.is_empty() {
				for lock in $stmt.locking_clause {
					if Node.locking_clause_of(lock).wait_policy == 1 {
						return Err(Rt.error(ctx, "42601", Ok("SKIP LOCKED and WITH TIES options cannot be used together"), limit.option_loc))
					}
				}
			}
			$stmt = { ..$stmt, limit_option: limit.limit_option }
		}
		_ => {}
	}
	if !Node.is_null(with_clause) {
		if !Node.is_null($stmt.with_clause) {
			return Err(Rt.error(ctx, "42601", Ok("multiple WITH clauses not allowed"), expr_location(with_clause)))
		}
		$stmt = { ..$stmt, with_clause }
	}
	Ok({ a0: Node.SelectStmt($stmt) })
}

## SplitColQualList: the COLLATE clause out of a column's constraints.
split_col_qual_list : List(Node), Bool, Bool, Rt.Ctx -> Try({ a1 : List(Node), a2 : Node }, Scan.Problem)
split_col_qual_list = |qual_list, _want_constraints, _want_collate, ctx| {
	var $kept = []
	var $collate = Null
	for n in qual_list {
		match n {
			Constraint(_) => {
				$kept = $kept.append(n)
			}
			CollateClause(c) => {
				if !Node.is_null($collate) {
					return Err(Rt.error(ctx, "42601", Ok("multiple COLLATE clauses not allowed"), c.location))
				}
				$collate = n
			}
			_ => {
				return Err(Rt.error(ctx, "XX000", Ok("unexpected node type ${Node.tag(n)}"), -1))
			}
		}
	}
	Ok({ a1: $kept, a2: $collate })
}

## processCASbits: constraint attribute bits into the flags the caller asks
## for. Asking about a bit the caller has no flag for is an error.
process_cas_bits : I64, I64, Node.Text, Bool, Bool, Bool, Bool, Bool, Rt.Ctx -> Try({ a3 : Bool, a4 : Bool, a5 : Bool, a6 : Bool, a7 : Bool }, Scan.Problem)
process_cas_bits = |cas_bits, location, constr_type, has_deferrable, has_initdeferred, has_is_enforced, has_not_valid, has_no_inherit, ctx| {
	var $deferrable = Bool.False
	var $initdeferred = Bool.False
	var $is_enforced = Bool.True
	var $not_valid = Bool.False
	var $no_inherit = Bool.False
	if Rt.bit_and(cas_bits, Rt.bit_or(2, 8)) != 0 {
		if !has_deferrable {
			return Err(cas_error(ctx, constr_type, "DEFERRABLE", location))
		}
		$deferrable = Bool.True
	}
	if Rt.bit_and(cas_bits, 8) != 0 {
		if !has_initdeferred {
			return Err(cas_error(ctx, constr_type, "DEFERRABLE", location))
		}
		$initdeferred = Bool.True
	}
	if Rt.bit_and(cas_bits, 16) != 0 {
		if !has_not_valid {
			return Err(cas_error(ctx, constr_type, "NOT VALID", location))
		}
		$not_valid = Bool.True
	}
	if Rt.bit_and(cas_bits, 32) != 0 {
		if !has_no_inherit {
			return Err(cas_error(ctx, constr_type, "NO INHERIT", location))
		}
		$no_inherit = Bool.True
	}
	if Rt.bit_and(cas_bits, 64) != 0 {
		if !has_is_enforced {
			return Err(cas_error(ctx, constr_type, "NOT ENFORCED", location))
		}
		$is_enforced = Bool.False
		$not_valid = Bool.True
	}
	if Rt.bit_and(cas_bits, 128) != 0 {
		if !has_is_enforced {
			return Err(cas_error(ctx, constr_type, "ENFORCED", location))
		}
		$is_enforced = Bool.True
	}
	Ok({ a3: $deferrable, a4: $initdeferred, a5: $is_enforced, a6: $not_valid, a7: $no_inherit })
}

## preprocess_pubobj_list: fill in each object's kind from the one before it.
preprocess_pubobj_list : List(Node), Rt.Ctx -> Try({ a0 : List(Node) }, Scan.Problem)
preprocess_pubobj_list = |list, ctx| {
	if list.is_empty() {
		return Ok({ a0: list })
	}
	first = Node.publication_obj_spec_of(Rt.linitial(list))
	if first.pubobjtype == 3 {
		return Err(Rt.error(ctx, "42601", Ok("invalid publication object list"), first.location))
	}
	var $prev = 3
	var $out = []
	for item in list {
		var $obj = Node.publication_obj_spec_of(item)
		if $obj.pubobjtype == 3 {
			$obj = { ..$obj, pubobjtype: $prev }
		}
		if $obj.pubobjtype == 0 {
			if !Rt.text_is_set($obj.name) and Node.is_null($obj.pubtable) {
				return Err(Rt.error(ctx, "42601", Ok("invalid table name"), $obj.location))
			}
			if Rt.text_is_set($obj.name) {
				pubtable = Node.PublicationTable({ ..Node.publication_table_default, relation: make_range_var(Err(Null), $obj.name, $obj.location) })
				$obj = { ..$obj, pubtable, name: Err(Null) }
			}
		} else if $obj.pubobjtype == 1 or $obj.pubobjtype == 2 {
			match $obj.pubtable {
				PublicationTable(t) => {
					if !Node.is_null(t.where_clause) {
						return Err(Rt.error(ctx, "42601", Ok("WHERE clause not allowed for schema"), $obj.location))
					}
					if !t.columns.is_empty() {
						return Err(Rt.error(ctx, "42601", Ok("column specification not allowed for schema"), $obj.location))
					}
				}
				_ => {}
			}
			if Rt.text_is_set($obj.name) {
				$obj = { ..$obj, pubobjtype: 1 }
			} else if Node.is_null($obj.pubtable) {
				$obj = { ..$obj, pubobjtype: 2 }
			} else {
				return Err(Rt.error(ctx, "42601", Ok("invalid schema name"), $obj.location))
			}
		}
		$prev = $obj.pubobjtype
		$out = $out.append(Node.PublicationObjSpec($obj))
	}
	Ok({ a0: $out })
}

## updateRawStmtEnd: set a statement's length once.
update_raw_stmt_end : Node, I64 -> { a0 : Node }
update_raw_stmt_end = |rs_node, end_location| {
	rs = Node.raw_stmt_of(rs_node)
	if rs.stmt_len > 0 {
		{ a0: rs_node }
	} else {
		{ a0: Node.RawStmt({ ..rs, stmt_len: end_location - rs.stmt_location }) }
	}
}

## NameListToString (namespace.c): names joined with dots.
name_list_to_string : List(Node) -> Node.Text
name_list_to_string = |names| {
	parts : List(Str)
	parts = names.map(
		|n|
			match n {
				String(s) => Rt.text_str(s.sval)
				AStar(_) => "*"
				_ => "?"
			},
	)
	Ok(Str.join_with(parts, "."))
}

cas_error : Rt.Ctx, Node.Text, Str, I64 -> Scan.Problem
cas_error = |ctx, constr_type, what, location| Rt.error(ctx, "0A000", Ok("${Rt.text_str(constr_type)} constraints cannot be marked ${what}"), location)

## doNegateFloat, on a Float node the caller keeps.
do_negate_float_node : Node -> { a0 : Node }
do_negate_float_node = |v| { a0: Node.Float({ fval: negate_float(Node.float_of(v).fval) }) }
