## A command line tool for the Rebel Alliance's operations database, and a
## realistic workload for compile-time query checking: 59 tables and
## 212 checked queries. See the README at the root of the repository.
##
##     rebellion <database url> <area> <command> [arguments]
##     rebellion postgresql://postgres@localhost:5432/rebellion galaxy planet Hoth
app [main!] {
	pf: platform "https://github.com/roc-lang/basic-cli/releases/download/0.26.0/GddgvsGjiNXrHFW6au5i5dUDbTs8FinQdrgE2Gqmw53t.tar.zst",
	pg: "../../package/main.roc",
}

import pf.Stdout
import pf.Tcp
import pf.Random
import pf.OsStr
import pg.Client
import Bases
import Battles
import Bounties
import Droids
import Fleet
import Force
import Galaxy
import Intel
import Logistics
import Missions
import Operators
import Personnel
import Squadrons

main! : List(OsStr) => Try({}, _)
main! = |os_args| {
	args = List.map(os_args, OsStr.display)
	match args {
		[url, area, .. as command] => {
			db = Client.connect_url!(url, { connect!: Tcp.connect!, random_u64!: Random.seed_u64! })?
			output =
				match area {
					"bases" => Bases.run!(command, db)
					"battles" => Battles.run!(command, db)
					"bounties" => Bounties.run!(command, db)
					"droids" => Droids.run!(command, db)
					"fleet" => Fleet.run!(command, db)
					"force" => Force.run!(command, db)
					"galaxy" => Galaxy.run!(command, db)
					"intel" => Intel.run!(command, db)
					"logistics" => Logistics.run!(command, db)
					"missions" => Missions.run!(command, db)
					"operators" => Operators.run!(command, db)
					"personnel" => Personnel.run!(command, db)
					"squadrons" => Squadrons.run!(command, db)
					_ => "unknown area ${area}"
				}
			db.close!()
			Stdout.line!(output)
		}
		_ => Stdout.line!("usage: rebellion <database url> <area> <command> [arguments]")
	}
}
