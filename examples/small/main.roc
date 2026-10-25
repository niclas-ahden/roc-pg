## A small app for the cost of row types in `roc build`: 20 queries over one
## table, each returning its own 8-field record (`id`, `name` and a different
## run of six more columns). Everything else is the same in every query.
##
## Giving all 20 queries the same row type makes `roc build` about three times
## faster, while `roc check` takes the same time either way. See the README at
## the root of the repository.
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Duration
import pf.Random
import pf.OsStr
import pg.Client
import pg.Catalog
import "schema.sql" as schema_sql : Str

parsed_schema = Catalog.from_schema(schema_sql)

Schema := [].{ catalog = |{}| parsed_schema }

Db : Client.Client(Tcp.Connection, Schema)

planets_01! : I32, Db => Try(List({ id : I32, name : Str, star_system_id : I32, climate : Try(Str, [Null]), terrain : Try(Str, [Null]), diameter_km : Try(F64, [Null]), gravity_standard : Try(F64, [Null]), rotation_period_hours : Try(F64, [Null]) }), _)
planets_01! = |min_threat, db|
	db.query!("SELECT id, name, star_system_id, climate, terrain, diameter_km, gravity_standard, rotation_period_hours FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_02! : I32, Db => Try(List({ id : I32, name : Str, climate : Try(Str, [Null]), terrain : Try(Str, [Null]), diameter_km : Try(F64, [Null]), gravity_standard : Try(F64, [Null]), rotation_period_hours : Try(F64, [Null]), orbital_period_days : Try(F64, [Null]) }), _)
planets_02! = |min_threat, db|
	db.query!("SELECT id, name, climate, terrain, diameter_km, gravity_standard, rotation_period_hours, orbital_period_days FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_03! : I32, Db => Try(List({ id : I32, name : Str, terrain : Try(Str, [Null]), diameter_km : Try(F64, [Null]), gravity_standard : Try(F64, [Null]), rotation_period_hours : Try(F64, [Null]), orbital_period_days : Try(F64, [Null]), surface_water_pct : Try(F64, [Null]) }), _)
planets_03! = |min_threat, db|
	db.query!("SELECT id, name, terrain, diameter_km, gravity_standard, rotation_period_hours, orbital_period_days, surface_water_pct FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_04! : I32, Db => Try(List({ id : I32, name : Str, diameter_km : Try(F64, [Null]), gravity_standard : Try(F64, [Null]), rotation_period_hours : Try(F64, [Null]), orbital_period_days : Try(F64, [Null]), surface_water_pct : Try(F64, [Null]), population : Try(I64, [Null]) }), _)
planets_04! = |min_threat, db|
	db.query!("SELECT id, name, diameter_km, gravity_standard, rotation_period_hours, orbital_period_days, surface_water_pct, population FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_05! : I32, Db => Try(List({ id : I32, name : Str, gravity_standard : Try(F64, [Null]), rotation_period_hours : Try(F64, [Null]), orbital_period_days : Try(F64, [Null]), surface_water_pct : Try(F64, [Null]), population : Try(I64, [Null]), capital_city : Try(Str, [Null]) }), _)
planets_05! = |min_threat, db|
	db.query!("SELECT id, name, gravity_standard, rotation_period_hours, orbital_period_days, surface_water_pct, population, capital_city FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_06! : I32, Db => Try(List({ id : I32, name : Str, rotation_period_hours : Try(F64, [Null]), orbital_period_days : Try(F64, [Null]), surface_water_pct : Try(F64, [Null]), population : Try(I64, [Null]), capital_city : Try(Str, [Null]), allegiance : Str }), _)
planets_06! = |min_threat, db|
	db.query!("SELECT id, name, rotation_period_hours, orbital_period_days, surface_water_pct, population, capital_city, allegiance FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_07! : I32, Db => Try(List({ id : I32, name : Str, orbital_period_days : Try(F64, [Null]), surface_water_pct : Try(F64, [Null]), population : Try(I64, [Null]), capital_city : Try(Str, [Null]), allegiance : Str, imperial_garrison : Bool }), _)
planets_07! = |min_threat, db|
	db.query!("SELECT id, name, orbital_period_days, surface_water_pct, population, capital_city, allegiance, imperial_garrison FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_08! : I32, Db => Try(List({ id : I32, name : Str, surface_water_pct : Try(F64, [Null]), population : Try(I64, [Null]), capital_city : Try(Str, [Null]), allegiance : Str, imperial_garrison : Bool, rebel_cell : Bool }), _)
planets_08! = |min_threat, db|
	db.query!("SELECT id, name, surface_water_pct, population, capital_city, allegiance, imperial_garrison, rebel_cell FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_09! : I32, Db => Try(List({ id : I32, name : Str, population : Try(I64, [Null]), capital_city : Try(Str, [Null]), allegiance : Str, imperial_garrison : Bool, rebel_cell : Bool, breathable_atmosphere : Bool }), _)
planets_09! = |min_threat, db|
	db.query!("SELECT id, name, population, capital_city, allegiance, imperial_garrison, rebel_cell, breathable_atmosphere FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_10! : I32, Db => Try(List({ id : I32, name : Str, capital_city : Try(Str, [Null]), allegiance : Str, imperial_garrison : Bool, rebel_cell : Bool, breathable_atmosphere : Bool, hyperspace_beacon_code : Try(Str, [Null]) }), _)
planets_10! = |min_threat, db|
	db.query!("SELECT id, name, capital_city, allegiance, imperial_garrison, rebel_cell, breathable_atmosphere, hyperspace_beacon_code FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_11! : I32, Db => Try(List({ id : I32, name : Str, allegiance : Str, imperial_garrison : Bool, rebel_cell : Bool, breathable_atmosphere : Bool, hyperspace_beacon_code : Try(Str, [Null]), spaceport_count : I32 }), _)
planets_11! = |min_threat, db|
	db.query!("SELECT id, name, allegiance, imperial_garrison, rebel_cell, breathable_atmosphere, hyperspace_beacon_code, spaceport_count FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_12! : I32, Db => Try(List({ id : I32, name : Str, imperial_garrison : Bool, rebel_cell : Bool, breathable_atmosphere : Bool, hyperspace_beacon_code : Try(Str, [Null]), spaceport_count : I32, threat_level : I32 }), _)
planets_12! = |min_threat, db|
	db.query!("SELECT id, name, imperial_garrison, rebel_cell, breathable_atmosphere, hyperspace_beacon_code, spaceport_count, threat_level FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_13! : I32, Db => Try(List({ id : I32, name : Str, rebel_cell : Bool, breathable_atmosphere : Bool, hyperspace_beacon_code : Try(Str, [Null]), spaceport_count : I32, threat_level : I32, last_patrol_at : Try(Str, [Null]) }), _)
planets_13! = |min_threat, db|
	db.query!("SELECT id, name, rebel_cell, breathable_atmosphere, hyperspace_beacon_code, spaceport_count, threat_level, last_patrol_at FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_14! : I32, Db => Try(List({ id : I32, name : Str, breathable_atmosphere : Bool, hyperspace_beacon_code : Try(Str, [Null]), spaceport_count : I32, threat_level : I32, last_patrol_at : Try(Str, [Null]), liberated_at : Try(Str, [Null]) }), _)
planets_14! = |min_threat, db|
	db.query!("SELECT id, name, breathable_atmosphere, hyperspace_beacon_code, spaceport_count, threat_level, last_patrol_at, liberated_at FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_15! : I32, Db => Try(List({ id : I32, name : Str, hyperspace_beacon_code : Try(Str, [Null]), spaceport_count : I32, threat_level : I32, last_patrol_at : Try(Str, [Null]), liberated_at : Try(Str, [Null]), occupied_at : Try(Str, [Null]) }), _)
planets_15! = |min_threat, db|
	db.query!("SELECT id, name, hyperspace_beacon_code, spaceport_count, threat_level, last_patrol_at, liberated_at, occupied_at FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_16! : I32, Db => Try(List({ id : I32, name : Str, spaceport_count : I32, threat_level : I32, last_patrol_at : Try(Str, [Null]), liberated_at : Try(Str, [Null]), occupied_at : Try(Str, [Null]), description : Try(Str, [Null]) }), _)
planets_16! = |min_threat, db|
	db.query!("SELECT id, name, spaceport_count, threat_level, last_patrol_at, liberated_at, occupied_at, description FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_17! : I32, Db => Try(List({ id : I32, name : Str, threat_level : I32, last_patrol_at : Try(Str, [Null]), liberated_at : Try(Str, [Null]), occupied_at : Try(Str, [Null]), description : Try(Str, [Null]), holonet_entry_url : Try(Str, [Null]) }), _)
planets_17! = |min_threat, db|
	db.query!("SELECT id, name, threat_level, last_patrol_at, liberated_at, occupied_at, description, holonet_entry_url FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_18! : I32, Db => Try(List({ id : I32, name : Str, last_patrol_at : Try(Str, [Null]), liberated_at : Try(Str, [Null]), occupied_at : Try(Str, [Null]), description : Try(Str, [Null]), holonet_entry_url : Try(Str, [Null]), map_image_key : Try(Str, [Null]) }), _)
planets_18! = |min_threat, db|
	db.query!("SELECT id, name, last_patrol_at, liberated_at, occupied_at, description, holonet_entry_url, map_image_key FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_19! : I32, Db => Try(List({ id : I32, name : Str, liberated_at : Try(Str, [Null]), occupied_at : Try(Str, [Null]), description : Try(Str, [Null]), holonet_entry_url : Try(Str, [Null]), map_image_key : Try(Str, [Null]), first_contact_on : Try(Str, [Null]) }), _)
planets_19! = |min_threat, db|
	db.query!("SELECT id, name, liberated_at, occupied_at, description, holonet_entry_url, map_image_key, first_contact_on FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

planets_20! : I32, Db => Try(List({ id : I32, name : Str, occupied_at : Try(Str, [Null]), description : Try(Str, [Null]), holonet_entry_url : Try(Str, [Null]), map_image_key : Try(Str, [Null]), first_contact_on : Try(Str, [Null]), archived_at : Try(Str, [Null]) }), _)
planets_20! = |min_threat, db|
	db.query!("SELECT id, name, occupied_at, description, holonet_entry_url, map_image_key, first_contact_on, archived_at FROM planets WHERE threat_level >= $min_threat ORDER BY name", { min_threat, })

main! : List(OsStr) => Try({}, _)
main! = |os_args| {
	match List.map(os_args, OsStr.display) {
		[url] => {
			db = Client.connect_url!(url, { connect!: |host, port| Tcp.connect!(host, port, { connect_timeout: Duration.seconds(5), io_timeout: Duration.seconds(35) }), random_u64!: Random.seed_u64!, statement_timeout: Duration.seconds(30) })?
			Stdout.line!(Str.inspect(planets_01!(0, db)))?
			Stdout.line!(Str.inspect(planets_02!(0, db)))?
			Stdout.line!(Str.inspect(planets_03!(0, db)))?
			Stdout.line!(Str.inspect(planets_04!(0, db)))?
			Stdout.line!(Str.inspect(planets_05!(0, db)))?
			Stdout.line!(Str.inspect(planets_06!(0, db)))?
			Stdout.line!(Str.inspect(planets_07!(0, db)))?
			Stdout.line!(Str.inspect(planets_08!(0, db)))?
			Stdout.line!(Str.inspect(planets_09!(0, db)))?
			Stdout.line!(Str.inspect(planets_10!(0, db)))?
			Stdout.line!(Str.inspect(planets_11!(0, db)))?
			Stdout.line!(Str.inspect(planets_12!(0, db)))?
			Stdout.line!(Str.inspect(planets_13!(0, db)))?
			Stdout.line!(Str.inspect(planets_14!(0, db)))?
			Stdout.line!(Str.inspect(planets_15!(0, db)))?
			Stdout.line!(Str.inspect(planets_16!(0, db)))?
			Stdout.line!(Str.inspect(planets_17!(0, db)))?
			Stdout.line!(Str.inspect(planets_18!(0, db)))?
			Stdout.line!(Str.inspect(planets_19!(0, db)))?
			Stdout.line!(Str.inspect(planets_20!(0, db)))?
			db.close!()
			Ok({})
		}
		_ => Stdout.line!("usage: small <database url>")
	}
}
