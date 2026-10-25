## Use in place of a schema when you don't have a `schema.sql`. Checked
## queries are then checked for syntax and parameters, but not for tables,
## columns or types.
##
## ```
## Db : Client.Client(Tcp.Connection, NoSchema)
## ```
import Catalog

NoSchema := [].{
	catalog : {} -> Catalog
	catalog = |{}| Catalog.none
}
