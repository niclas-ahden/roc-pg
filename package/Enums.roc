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

## The values of the C enums that fields of the parse tree hold, by their
## C names in snake case: `Enums.object_table` is `OBJECT_TABLE`. Written
## by `tools/actions.roc`, do not edit.
Enums :: [].{
	# `A_Expr_Kind`

	aexpr_op : I64
	aexpr_op = 0

	aexpr_op_any : I64
	aexpr_op_any = 1

	aexpr_op_all : I64
	aexpr_op_all = 2

	aexpr_distinct : I64
	aexpr_distinct = 3

	aexpr_not_distinct : I64
	aexpr_not_distinct = 4

	aexpr_nullif : I64
	aexpr_nullif = 5

	aexpr_in : I64
	aexpr_in = 6

	aexpr_like : I64
	aexpr_like = 7

	aexpr_ilike : I64
	aexpr_ilike = 8

	aexpr_similar : I64
	aexpr_similar = 9

	aexpr_between : I64
	aexpr_between = 10

	aexpr_not_between : I64
	aexpr_not_between = 11

	aexpr_between_sym : I64
	aexpr_between_sym = 12

	aexpr_not_between_sym : I64
	aexpr_not_between_sym = 13

	# `AlterPublicationAction`

	ap_add_objects : I64
	ap_add_objects = 0

	ap_drop_objects : I64
	ap_drop_objects = 1

	ap_set_objects : I64
	ap_set_objects = 2

	# `AlterSubscriptionType`

	alter_subscription_options : I64
	alter_subscription_options = 0

	alter_subscription_connection : I64
	alter_subscription_connection = 1

	alter_subscription_set_publication : I64
	alter_subscription_set_publication = 2

	alter_subscription_add_publication : I64
	alter_subscription_add_publication = 3

	alter_subscription_drop_publication : I64
	alter_subscription_drop_publication = 4

	alter_subscription_refresh : I64
	alter_subscription_refresh = 5

	alter_subscription_enabled : I64
	alter_subscription_enabled = 6

	alter_subscription_skip : I64
	alter_subscription_skip = 7

	# `AlterTSConfigType`

	alter_tsconfig_add_mapping : I64
	alter_tsconfig_add_mapping = 0

	alter_tsconfig_alter_mapping_for_token : I64
	alter_tsconfig_alter_mapping_for_token = 1

	alter_tsconfig_replace_dict : I64
	alter_tsconfig_replace_dict = 2

	alter_tsconfig_replace_dict_for_token : I64
	alter_tsconfig_replace_dict_for_token = 3

	alter_tsconfig_drop_mapping : I64
	alter_tsconfig_drop_mapping = 4

	# `AlterTableType`

	at_add_column : I64
	at_add_column = 0

	at_add_column_to_view : I64
	at_add_column_to_view = 1

	at_column_default : I64
	at_column_default = 2

	at_cooked_column_default : I64
	at_cooked_column_default = 3

	at_drop_not_null : I64
	at_drop_not_null = 4

	at_set_not_null : I64
	at_set_not_null = 5

	at_set_expression : I64
	at_set_expression = 6

	at_drop_expression : I64
	at_drop_expression = 7

	at_set_statistics : I64
	at_set_statistics = 8

	at_set_options : I64
	at_set_options = 9

	at_reset_options : I64
	at_reset_options = 10

	at_set_storage : I64
	at_set_storage = 11

	at_set_compression : I64
	at_set_compression = 12

	at_drop_column : I64
	at_drop_column = 13

	at_add_index : I64
	at_add_index = 14

	at_re_add_index : I64
	at_re_add_index = 15

	at_add_constraint : I64
	at_add_constraint = 16

	at_re_add_constraint : I64
	at_re_add_constraint = 17

	at_re_add_domain_constraint : I64
	at_re_add_domain_constraint = 18

	at_alter_constraint : I64
	at_alter_constraint = 19

	at_validate_constraint : I64
	at_validate_constraint = 20

	at_add_index_constraint : I64
	at_add_index_constraint = 21

	at_drop_constraint : I64
	at_drop_constraint = 22

	at_re_add_comment : I64
	at_re_add_comment = 23

	at_alter_column_type : I64
	at_alter_column_type = 24

	at_alter_column_generic_options : I64
	at_alter_column_generic_options = 25

	at_change_owner : I64
	at_change_owner = 26

	at_cluster_on : I64
	at_cluster_on = 27

	at_drop_cluster : I64
	at_drop_cluster = 28

	at_set_logged : I64
	at_set_logged = 29

	at_set_un_logged : I64
	at_set_un_logged = 30

	at_drop_oids : I64
	at_drop_oids = 31

	at_set_access_method : I64
	at_set_access_method = 32

	at_set_table_space : I64
	at_set_table_space = 33

	at_set_rel_options : I64
	at_set_rel_options = 34

	at_reset_rel_options : I64
	at_reset_rel_options = 35

	at_replace_rel_options : I64
	at_replace_rel_options = 36

	at_enable_trig : I64
	at_enable_trig = 37

	at_enable_always_trig : I64
	at_enable_always_trig = 38

	at_enable_replica_trig : I64
	at_enable_replica_trig = 39

	at_disable_trig : I64
	at_disable_trig = 40

	at_enable_trig_all : I64
	at_enable_trig_all = 41

	at_disable_trig_all : I64
	at_disable_trig_all = 42

	at_enable_trig_user : I64
	at_enable_trig_user = 43

	at_disable_trig_user : I64
	at_disable_trig_user = 44

	at_enable_rule : I64
	at_enable_rule = 45

	at_enable_always_rule : I64
	at_enable_always_rule = 46

	at_enable_replica_rule : I64
	at_enable_replica_rule = 47

	at_disable_rule : I64
	at_disable_rule = 48

	at_add_inherit : I64
	at_add_inherit = 49

	at_drop_inherit : I64
	at_drop_inherit = 50

	at_add_of : I64
	at_add_of = 51

	at_drop_of : I64
	at_drop_of = 52

	at_replica_identity : I64
	at_replica_identity = 53

	at_enable_row_security : I64
	at_enable_row_security = 54

	at_disable_row_security : I64
	at_disable_row_security = 55

	at_force_row_security : I64
	at_force_row_security = 56

	at_no_force_row_security : I64
	at_no_force_row_security = 57

	at_generic_options : I64
	at_generic_options = 58

	at_attach_partition : I64
	at_attach_partition = 59

	at_detach_partition : I64
	at_detach_partition = 60

	at_detach_partition_finalize : I64
	at_detach_partition_finalize = 61

	at_add_identity : I64
	at_add_identity = 62

	at_set_identity : I64
	at_set_identity = 63

	at_drop_identity : I64
	at_drop_identity = 64

	at_re_add_statistics : I64
	at_re_add_statistics = 65

	# `BoolExprType`

	and_expr : I64
	and_expr = 0

	or_expr : I64
	or_expr = 1

	not_expr : I64
	not_expr = 2

	# `BoolTestType`

	is_true : I64
	is_true = 0

	is_not_true : I64
	is_not_true = 1

	is_false : I64
	is_false = 2

	is_not_false : I64
	is_not_false = 3

	is_unknown : I64
	is_unknown = 4

	is_not_unknown : I64
	is_not_unknown = 5

	# `CTEMaterialize`

	cte_materialize_default : I64
	cte_materialize_default = 0

	cte_materialize_always : I64
	cte_materialize_always = 1

	cte_materialize_never : I64
	cte_materialize_never = 2

	# `CmdType`

	cmd_unknown : I64
	cmd_unknown = 0

	cmd_select : I64
	cmd_select = 1

	cmd_update : I64
	cmd_update = 2

	cmd_insert : I64
	cmd_insert = 3

	cmd_delete : I64
	cmd_delete = 4

	cmd_merge : I64
	cmd_merge = 5

	cmd_utility : I64
	cmd_utility = 6

	cmd_nothing : I64
	cmd_nothing = 7

	# `CoercionContext`

	coercion_implicit : I64
	coercion_implicit = 0

	coercion_assignment : I64
	coercion_assignment = 1

	coercion_plpgsql : I64
	coercion_plpgsql = 2

	coercion_explicit : I64
	coercion_explicit = 3

	# `CoercionForm`

	coerce_explicit_call : I64
	coerce_explicit_call = 0

	coerce_explicit_cast : I64
	coerce_explicit_cast = 1

	coerce_implicit_cast : I64
	coerce_implicit_cast = 2

	coerce_sql_syntax : I64
	coerce_sql_syntax = 3

	# `ConstrType`

	constr_null : I64
	constr_null = 0

	constr_notnull : I64
	constr_notnull = 1

	constr_default : I64
	constr_default = 2

	constr_identity : I64
	constr_identity = 3

	constr_generated : I64
	constr_generated = 4

	constr_check : I64
	constr_check = 5

	constr_primary : I64
	constr_primary = 6

	constr_unique : I64
	constr_unique = 7

	constr_exclusion : I64
	constr_exclusion = 8

	constr_foreign : I64
	constr_foreign = 9

	constr_attr_deferrable : I64
	constr_attr_deferrable = 10

	constr_attr_not_deferrable : I64
	constr_attr_not_deferrable = 11

	constr_attr_deferred : I64
	constr_attr_deferred = 12

	constr_attr_immediate : I64
	constr_attr_immediate = 13

	constr_attr_enforced : I64
	constr_attr_enforced = 14

	constr_attr_not_enforced : I64
	constr_attr_not_enforced = 15

	# `DefElemAction`

	defelem_unspec : I64
	defelem_unspec = 0

	defelem_set : I64
	defelem_set = 1

	defelem_add : I64
	defelem_add = 2

	defelem_drop : I64
	defelem_drop = 3

	# `DiscardMode`

	discard_all : I64
	discard_all = 0

	discard_plans : I64
	discard_plans = 1

	discard_sequences : I64
	discard_sequences = 2

	discard_temp : I64
	discard_temp = 3

	# `DropBehavior`

	drop_restrict : I64
	drop_restrict = 0

	drop_cascade : I64
	drop_cascade = 1

	# `FetchDirection`

	fetch_forward : I64
	fetch_forward = 0

	fetch_backward : I64
	fetch_backward = 1

	fetch_absolute : I64
	fetch_absolute = 2

	fetch_relative : I64
	fetch_relative = 3

	# `FunctionParameterMode`

	func_param_in : I64
	func_param_in = 105

	func_param_out : I64
	func_param_out = 111

	func_param_inout : I64
	func_param_inout = 98

	func_param_variadic : I64
	func_param_variadic = 118

	func_param_table : I64
	func_param_table = 116

	func_param_default : I64
	func_param_default = 100

	# `GrantTargetType`

	acl_target_object : I64
	acl_target_object = 0

	acl_target_all_in_schema : I64
	acl_target_all_in_schema = 1

	acl_target_defaults : I64
	acl_target_defaults = 2

	# `GroupingSetKind`

	grouping_set_empty : I64
	grouping_set_empty = 0

	grouping_set_simple : I64
	grouping_set_simple = 1

	grouping_set_rollup : I64
	grouping_set_rollup = 2

	grouping_set_cube : I64
	grouping_set_cube = 3

	grouping_set_sets : I64
	grouping_set_sets = 4

	# `ImportForeignSchemaType`

	fdw_import_schema_all : I64
	fdw_import_schema_all = 0

	fdw_import_schema_limit_to : I64
	fdw_import_schema_limit_to = 1

	fdw_import_schema_except : I64
	fdw_import_schema_except = 2

	# `JoinType`

	join_inner : I64
	join_inner = 0

	join_left : I64
	join_left = 1

	join_full : I64
	join_full = 2

	join_right : I64
	join_right = 3

	join_semi : I64
	join_semi = 4

	join_anti : I64
	join_anti = 5

	join_right_semi : I64
	join_right_semi = 6

	join_right_anti : I64
	join_right_anti = 7

	join_unique_outer : I64
	join_unique_outer = 8

	join_unique_inner : I64
	join_unique_inner = 9

	# `JsonBehaviorType`

	json_behavior_null : I64
	json_behavior_null = 0

	json_behavior_error : I64
	json_behavior_error = 1

	json_behavior_empty : I64
	json_behavior_empty = 2

	json_behavior_true : I64
	json_behavior_true = 3

	json_behavior_false : I64
	json_behavior_false = 4

	json_behavior_unknown : I64
	json_behavior_unknown = 5

	json_behavior_empty_array : I64
	json_behavior_empty_array = 6

	json_behavior_empty_object : I64
	json_behavior_empty_object = 7

	json_behavior_default : I64
	json_behavior_default = 8

	# `JsonEncoding`

	js_enc_default : I64
	js_enc_default = 0

	js_enc_utf8 : I64
	js_enc_utf8 = 1

	js_enc_utf16 : I64
	js_enc_utf16 = 2

	js_enc_utf32 : I64
	js_enc_utf32 = 3

	# `JsonExprOp`

	json_exists_op : I64
	json_exists_op = 0

	json_query_op : I64
	json_query_op = 1

	json_value_op : I64
	json_value_op = 2

	json_table_op : I64
	json_table_op = 3

	# `JsonFormatType`

	js_format_default : I64
	js_format_default = 0

	js_format_json : I64
	js_format_json = 1

	js_format_jsonb : I64
	js_format_jsonb = 2

	# `JsonQuotes`

	js_quotes_unspec : I64
	js_quotes_unspec = 0

	js_quotes_keep : I64
	js_quotes_keep = 1

	js_quotes_omit : I64
	js_quotes_omit = 2

	# `JsonTableColumnType`

	jtc_for_ordinality : I64
	jtc_for_ordinality = 0

	jtc_regular : I64
	jtc_regular = 1

	jtc_exists : I64
	jtc_exists = 2

	jtc_formatted : I64
	jtc_formatted = 3

	jtc_nested : I64
	jtc_nested = 4

	# `JsonValueType`

	js_type_any : I64
	js_type_any = 0

	js_type_object : I64
	js_type_object = 1

	js_type_array : I64
	js_type_array = 2

	js_type_scalar : I64
	js_type_scalar = 3

	# `JsonWrapper`

	jsw_unspec : I64
	jsw_unspec = 0

	jsw_none : I64
	jsw_none = 1

	jsw_conditional : I64
	jsw_conditional = 2

	jsw_unconditional : I64
	jsw_unconditional = 3

	# `LimitOption`

	limit_option_count : I64
	limit_option_count = 0

	limit_option_with_ties : I64
	limit_option_with_ties = 1

	# `LockClauseStrength`

	lcs_none : I64
	lcs_none = 0

	lcs_forkeyshare : I64
	lcs_forkeyshare = 1

	lcs_forshare : I64
	lcs_forshare = 2

	lcs_fornokeyupdate : I64
	lcs_fornokeyupdate = 3

	lcs_forupdate : I64
	lcs_forupdate = 4

	# `LockWaitPolicy`

	lock_wait_block : I64
	lock_wait_block = 0

	lock_wait_skip : I64
	lock_wait_skip = 1

	lock_wait_error : I64
	lock_wait_error = 2

	# `MergeMatchKind`

	merge_when_matched : I64
	merge_when_matched = 0

	merge_when_not_matched_by_source : I64
	merge_when_not_matched_by_source = 1

	merge_when_not_matched_by_target : I64
	merge_when_not_matched_by_target = 2

	# `MinMaxOp`

	is_greatest : I64
	is_greatest = 0

	is_least : I64
	is_least = 1

	# `NullTestType`

	is_null : I64
	is_null = 0

	is_not_null : I64
	is_not_null = 1

	# `ObjectType`

	object_access_method : I64
	object_access_method = 0

	object_aggregate : I64
	object_aggregate = 1

	object_amop : I64
	object_amop = 2

	object_amproc : I64
	object_amproc = 3

	object_attribute : I64
	object_attribute = 4

	object_cast : I64
	object_cast = 5

	object_column : I64
	object_column = 6

	object_collation : I64
	object_collation = 7

	object_conversion : I64
	object_conversion = 8

	object_database : I64
	object_database = 9

	object_default : I64
	object_default = 10

	object_defacl : I64
	object_defacl = 11

	object_domain : I64
	object_domain = 12

	object_domconstraint : I64
	object_domconstraint = 13

	object_event_trigger : I64
	object_event_trigger = 14

	object_extension : I64
	object_extension = 15

	object_fdw : I64
	object_fdw = 16

	object_foreign_server : I64
	object_foreign_server = 17

	object_foreign_table : I64
	object_foreign_table = 18

	object_function : I64
	object_function = 19

	object_index : I64
	object_index = 20

	object_language : I64
	object_language = 21

	object_largeobject : I64
	object_largeobject = 22

	object_matview : I64
	object_matview = 23

	object_opclass : I64
	object_opclass = 24

	object_operator : I64
	object_operator = 25

	object_opfamily : I64
	object_opfamily = 26

	object_parameter_acl : I64
	object_parameter_acl = 27

	object_policy : I64
	object_policy = 28

	object_procedure : I64
	object_procedure = 29

	object_publication : I64
	object_publication = 30

	object_publication_namespace : I64
	object_publication_namespace = 31

	object_publication_rel : I64
	object_publication_rel = 32

	object_role : I64
	object_role = 33

	object_routine : I64
	object_routine = 34

	object_rule : I64
	object_rule = 35

	object_schema : I64
	object_schema = 36

	object_sequence : I64
	object_sequence = 37

	object_subscription : I64
	object_subscription = 38

	object_statistic_ext : I64
	object_statistic_ext = 39

	object_tabconstraint : I64
	object_tabconstraint = 40

	object_table : I64
	object_table = 41

	object_tablespace : I64
	object_tablespace = 42

	object_transform : I64
	object_transform = 43

	object_trigger : I64
	object_trigger = 44

	object_tsconfiguration : I64
	object_tsconfiguration = 45

	object_tsdictionary : I64
	object_tsdictionary = 46

	object_tsparser : I64
	object_tsparser = 47

	object_tstemplate : I64
	object_tstemplate = 48

	object_type : I64
	object_type = 49

	object_user_mapping : I64
	object_user_mapping = 50

	object_view : I64
	object_view = 51

	# `OnCommitAction`

	oncommit_noop : I64
	oncommit_noop = 0

	oncommit_preserve_rows : I64
	oncommit_preserve_rows = 1

	oncommit_delete_rows : I64
	oncommit_delete_rows = 2

	oncommit_drop : I64
	oncommit_drop = 3

	# `OnConflictAction`

	onconflict_none : I64
	onconflict_none = 0

	onconflict_nothing : I64
	onconflict_nothing = 1

	onconflict_update : I64
	onconflict_update = 2

	# `OverridingKind`

	overriding_not_set : I64
	overriding_not_set = 0

	overriding_user_value : I64
	overriding_user_value = 1

	overriding_system_value : I64
	overriding_system_value = 2

	# `PartitionStrategy`

	partition_strategy_list : I64
	partition_strategy_list = 108

	partition_strategy_range : I64
	partition_strategy_range = 114

	partition_strategy_hash : I64
	partition_strategy_hash = 104

	# `PublicationObjSpecType`

	publicationobj_table : I64
	publicationobj_table = 0

	publicationobj_tables_in_schema : I64
	publicationobj_tables_in_schema = 1

	publicationobj_tables_in_cur_schema : I64
	publicationobj_tables_in_cur_schema = 2

	publicationobj_continuation : I64
	publicationobj_continuation = 3

	# `ReindexObjectType`

	reindex_object_index : I64
	reindex_object_index = 0

	reindex_object_table : I64
	reindex_object_table = 1

	reindex_object_schema : I64
	reindex_object_schema = 2

	reindex_object_system : I64
	reindex_object_system = 3

	reindex_object_database : I64
	reindex_object_database = 4

	# `ReturningOptionKind`

	returning_option_old : I64
	returning_option_old = 0

	returning_option_new : I64
	returning_option_new = 1

	# `RoleSpecType`

	rolespec_cstring : I64
	rolespec_cstring = 0

	rolespec_current_role : I64
	rolespec_current_role = 1

	rolespec_current_user : I64
	rolespec_current_user = 2

	rolespec_session_user : I64
	rolespec_session_user = 3

	rolespec_public : I64
	rolespec_public = 4

	# `RoleStmtType`

	rolestmt_role : I64
	rolestmt_role = 0

	rolestmt_user : I64
	rolestmt_user = 1

	rolestmt_group : I64
	rolestmt_group = 2

	# `SQLValueFunctionOp`

	svfop_current_date : I64
	svfop_current_date = 0

	svfop_current_time : I64
	svfop_current_time = 1

	svfop_current_time_n : I64
	svfop_current_time_n = 2

	svfop_current_timestamp : I64
	svfop_current_timestamp = 3

	svfop_current_timestamp_n : I64
	svfop_current_timestamp_n = 4

	svfop_localtime : I64
	svfop_localtime = 5

	svfop_localtime_n : I64
	svfop_localtime_n = 6

	svfop_localtimestamp : I64
	svfop_localtimestamp = 7

	svfop_localtimestamp_n : I64
	svfop_localtimestamp_n = 8

	svfop_current_role : I64
	svfop_current_role = 9

	svfop_current_user : I64
	svfop_current_user = 10

	svfop_user : I64
	svfop_user = 11

	svfop_session_user : I64
	svfop_session_user = 12

	svfop_current_catalog : I64
	svfop_current_catalog = 13

	svfop_current_schema : I64
	svfop_current_schema = 14

	# `SetOperation`

	setop_none : I64
	setop_none = 0

	setop_union : I64
	setop_union = 1

	setop_intersect : I64
	setop_intersect = 2

	setop_except : I64
	setop_except = 3

	# `SortByDir`

	sortby_default : I64
	sortby_default = 0

	sortby_asc : I64
	sortby_asc = 1

	sortby_desc : I64
	sortby_desc = 2

	sortby_using : I64
	sortby_using = 3

	# `SortByNulls`

	sortby_nulls_default : I64
	sortby_nulls_default = 0

	sortby_nulls_first : I64
	sortby_nulls_first = 1

	sortby_nulls_last : I64
	sortby_nulls_last = 2

	# `SubLinkType`

	exists_sublink : I64
	exists_sublink = 0

	all_sublink : I64
	all_sublink = 1

	any_sublink : I64
	any_sublink = 2

	rowcompare_sublink : I64
	rowcompare_sublink = 3

	expr_sublink : I64
	expr_sublink = 4

	multiexpr_sublink : I64
	multiexpr_sublink = 5

	array_sublink : I64
	array_sublink = 6

	cte_sublink : I64
	cte_sublink = 7

	# `TransactionStmtKind`

	trans_stmt_begin : I64
	trans_stmt_begin = 0

	trans_stmt_start : I64
	trans_stmt_start = 1

	trans_stmt_commit : I64
	trans_stmt_commit = 2

	trans_stmt_rollback : I64
	trans_stmt_rollback = 3

	trans_stmt_savepoint : I64
	trans_stmt_savepoint = 4

	trans_stmt_release : I64
	trans_stmt_release = 5

	trans_stmt_rollback_to : I64
	trans_stmt_rollback_to = 6

	trans_stmt_prepare : I64
	trans_stmt_prepare = 7

	trans_stmt_commit_prepared : I64
	trans_stmt_commit_prepared = 8

	trans_stmt_rollback_prepared : I64
	trans_stmt_rollback_prepared = 9

	# `VariableSetKind`

	var_set_value : I64
	var_set_value = 0

	var_set_default : I64
	var_set_default = 1

	var_set_current : I64
	var_set_current = 2

	var_set_multi : I64
	var_set_multi = 3

	var_reset : I64
	var_reset = 4

	var_reset_all : I64
	var_reset_all = 5

	# `ViewCheckOption`

	no_check_option : I64
	no_check_option = 0

	local_check_option : I64
	local_check_option = 1

	cascaded_check_option : I64
	cascaded_check_option = 2

	# `XmlExprOp`

	is_xmlconcat : I64
	is_xmlconcat = 0

	is_xmlelement : I64
	is_xmlelement = 1

	is_xmlforest : I64
	is_xmlforest = 2

	is_xmlparse : I64
	is_xmlparse = 3

	is_xmlpi : I64
	is_xmlpi = 4

	is_xmlroot : I64
	is_xmlroot = 5

	is_xmlserialize : I64
	is_xmlserialize = 6

	is_document : I64
	is_document = 7

	# `XmlOptionType`

	xmloption_document : I64
	xmloption_document = 0

	xmloption_content : I64
	xmloption_content = 1

}
