## Queries that must not compile. ./tests.roc runs `roc check` on this file
## and expects it to fail with every message listed in `expected_errors` of
## tests.roc, each at its query literal.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.25.0/CZsY7tYZwR3rj9kYbpaCfxki2yVAaRL8bBwMLvB2xkbA.tar.zst",
	pg: "../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pf.OsStr
import pg.Client
import pg.Catalog

schema_sql =
	\\CREATE TABLE public.students (
	\\    id integer NOT NULL,
	\\    name text NOT NULL,
	\\    phone text,
	\\    school_id integer NOT NULL
	\\);
	\\CREATE TABLE public.schools (
	\\    id integer NOT NULL,
	\\    name text NOT NULL
	\\);

catalog : Catalog
catalog = Catalog.from_schema(schema_sql)

Schema := [].{
	catalog : {} -> Catalog
	catalog = |{}| catalog
}

Db : Client.Client(Tcp.Stream, Schema)

unknown_table! : I32, Db => Try(List({ id : I32 }), _)
unknown_table! = |id, db| db.query!("select id from student where id = $id", { id, })

unknown_column! : I32, Db => Try(List({ id : I32 }), _)
unknown_column! = |id, db| db.query!("select r.id from students r where r.schol_id = $id", { id, })

positional! : I32, Db => Try(List({ id : I32 }), _)
positional! = |id, db| db.query!("select id from students where id = $1", { id, })

unterminated! : Db => Try(List({ id : I32 }), _)
unterminated! = |db| db.query!("select id from students where name = 'oops", {})

ambiguous! : Db => Try(List({ id : I32 }), _)
ambiguous! = |db| db.query!("select id from students r join schools o on o.id = r.school_id", {})

bad_insert_column! : I32, Db => Try(U64, _)
bad_insert_column! = |id, db| db.execute!("insert into students (id, nmae, school_id) values ($id, 'x', 1)", { id, })

misspelled_param! : I32, Db => Try(List({ id : I32 }), _)
misspelled_param! = |school_id, db| db.query!("select id from students where school_id = $schol_id", { school_id, })

unused_param! : I32, Str, Db => Try(List({ id : I32 }), _)
unused_param! = |id, name, db| db.query!("select id from students where id = $id", { id, name })

param_type! : Dec, Db => Try(List({ id : I32 }), _)
param_type! = |school_id, db| db.query!("select id from students where school_id = $school_id", { school_id, })

null_param! : Try(Str, [Null]), Db => Try(U64, _)
null_param! = |name, db| db.execute!("update students set name = $name where id = 1", { name, })

syntax_error! : I32, Db => Try(List({ id : I32 }), _)
syntax_error! = |id, db| db.query!("select id form students where id = $id", { id, })

two_statements! : Db => Try(U64, _)
two_statements! = |db| db.execute!("update students set phone = null; delete from schools", {})

# No annotation on `db`. The error must still show at the literal (roc-lang/roc#11675).
untyped_db! = |id, db| db.query_one!("select name from students where id = $idd", { id, })

# The row type is checked too, whatever the query function wraps it in.
missing_field! : Str, Db => Try(List({ id : I32, phone : Try(Str, [Null]) }), _)
missing_field! = |name, db| db.query!("select id from students where name = $name", { name, })

misspelled_field! : Db => Try(List({ nmae : Str }), _)
misspelled_field! = |db| db.query!("select id, name from students", {})

nullable_field! : I32, Db => Try({ phone : Str }, _)
nullable_field! = |id, db| db.query_one!("select phone from students where id = $id", { id, })

nullif_field! : I32, Db => Try(List({ school_id : I32 }), _)
nullif_field! = |id, db| db.query!("select nullif(school_id, 85) as school_id from students where id = $id", { id, })

count_field! : Db => Try(Try({ n : I32 }, [NotFound]), _)
count_field! = |db| db.query_optional!("select count(*) as n from students", {})

sum_field! : Db => Try(List({ total : I32 }), _)
sum_field! = |db| db.query!("select sum(school_id) as total from students", {})

nested_field! : Db => Try(List({ school : { id : I32 } }), _)
nested_field! = |db| db.query!("select school_id from students", {})

unproven_field! : Db => Try(List({ first : I32 }), _)
unproven_field! = |db| db.query!("select (array[school_id])[1] as first from students", {})

narrowing_field! : Db => Try(List({ small : U8 }), _)
narrowing_field! = |db| db.query!("select school_id as small from students", {})

# No annotation at all: the row type comes from the caller.
inferred_row! = |db| db.query!("select id from students", {})

main! : List(OsStr) => Try({}, _)
main! = |_args| {
	db = Client.connect!({ connect!: Tcp.connect!, random_u64!: Random.seed_u64!, host: "localhost", port: 5432, user: "postgres", database: "postgres", auth: NoAuth, timeout_ms: 5000 })?
	_ = unknown_table!(1, db)?
	_ = unknown_column!(1, db)?
	_ = positional!(1, db)?
	_ = unterminated!(db)?
	_ = ambiguous!(db)?
	_ = bad_insert_column!(1, db)?
	_ = misspelled_param!(1, db)?
	_ = unused_param!(1, "x", db)?
	_ = param_type!(1.5, db)?
	_ = null_param!(Err(Null), db)?
	_ = syntax_error!(1, db)?
	_ = two_statements!(db)?
	row : { name : Str }
	row = untyped_db!(1.I32, db)?
	Stdout.line!(row.name)?
	_ = missing_field!("x", db)?
	_ = misspelled_field!(db)?
	_ = nullable_field!(1, db)?
	_ = nullif_field!(1, db)?
	_ = count_field!(db)?
	_ = sum_field!(db)?
	_ = nested_field!(db)?
	_ = unproven_field!(db)?
	_ = narrowing_field!(db)?
	names : List({ name : Str })
	names = inferred_row!(db)?
	Stdout.line!(names.len().to_str())?
	Stdout.line!("unreachable")
}
