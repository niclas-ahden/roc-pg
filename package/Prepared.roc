## A named prepared statement: its server side name, the SQL to re-parse
## on a connection where that name does not exist, the backend it was
## prepared on, and its result columns.
##
## Internal to the package. It is opaque, so only the client's prepare
## function makes one, and a [Statement] cannot claim a name or a backend
## it was not prepared with.
import ProtoBackend

Prepared :: {
	name : Str,
	sql : Str,
	prepared_on : [Pending, Known(ProtoBackend.KeyData)],
	columns : List(ProtoBackend.Column),
}.{
	new : { name : Str, sql : Str, prepared_on : [Pending, Known(ProtoBackend.KeyData)], columns : List(ProtoBackend.Column) } -> Prepared
	new = |{ name: given_name, sql: given_sql, prepared_on: given_prepared_on, columns: given_columns }| { name: given_name, sql: given_sql, prepared_on: given_prepared_on, columns: given_columns }

	name : Prepared -> Str
	name = |prepared| prepared.name

	sql : Prepared -> Str
	sql = |prepared| prepared.sql

	prepared_on : Prepared -> [Pending, Known(ProtoBackend.KeyData)]
	prepared_on = |prepared| prepared.prepared_on

	columns : Prepared -> List(ProtoBackend.Column)
	columns = |prepared| prepared.columns
}
