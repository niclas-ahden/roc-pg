#!/usr/bin/env roc
## All tests: the package's `expect` blocks, a syntax check of the examples,
## then the integration tests against a throwaway Postgres server.
##
## The server binaries (initdb, pg_ctl) come from the flake dev shell:
##
##     nix develop -c ./tests.roc
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.23.0/7NpDhuqoqGFedmVLvmm1zjq37GCmaFGzwr5sz4ch9wTK.tar.zst",
}

import pf.Stdout
import pf.Cmd
import pf.Env
import pf.Path
import pf.OsStr exposing [OsStr]

pg_port = "5499"

pg_user = "roc_pg_test"

pg_database = "postgres"

main! = |_args| {
	Stdout.line!("== unit tests")?
	run!("roc", ["test", "package/main.roc"])?

	Stdout.line!("== check examples and tests")?
	for file in ["examples/query.roc", "examples/prepared.roc", "examples/pool.roc", "tests/integration.roc"] {
		run!("roc", ["check", file])?
	}

	Stdout.line!("== integration tests against a throwaway Postgres")?
	# The data dir is repo local (and gitignored) rather than under TMPDIR,
	# where the roc interpreter's scratch cleanup can delete it mid-run.
	# Absolute, because the postgres daemon resolves the socket dir after
	# changing its working directory.
	data_dir = Env.cwd!().map_err(|_| CwdUnavailable)?.join(".pg-test-db")
	data = Path.display(data_dir)

	# A leftover server from an aborted run would hold the port and data dir.
	_ = run!("pg_ctl", ["stop", "-D", data, "-m", "immediate"])
	if Path.exists!(data_dir)? {
		Path.delete_all!(data_dir)?
	}

	run!("initdb", ["-D", data, "-U", pg_user, "-A", "trust"])?

	# The integration tests exercise the cleartext password flow with one
	# dedicated user. pg_hba rules are first-match-wins, so the rule goes
	# before the catch-all trust rules initdb generated.
	hba_path = data_dir.join("pg_hba.conf")
	hba = Path.read_utf8!(hba_path)?
	Path.write_utf8!(hba_path, "host all roc_pg_password_test 127.0.0.1/32 password\n${hba}")?

	# The socket dir is pointed into the data dir because the default
	# (/run/postgresql) is not writable in CI or the nix dev shell.
	run!("pg_ctl", ["start", "-D", data, "-l", "${data}/log", "-w", "-o", "-p ${pg_port} -c listen_addresses=127.0.0.1 -k ${data}"])?

	result = run!("roc", ["tests/integration.roc", "127.0.0.1", pg_port, pg_user, pg_database])

	# Stop the server whether the tests passed or not.
	_ = run!("pg_ctl", ["stop", "-D", data, "-m", "immediate"])

	match result {
		Ok({}) => Stdout.line!("all tests passed")
		Err(err) => Err(err)
	}
}

# Run a command with inherited stdio, failing the script on a nonzero exit.
run! : Str, List(Str) => Try({}, [Exit(I32), ..])
run! = |program, arguments| {
	Cmd.exec!(OsStr.from_str(program), arguments.map(OsStr.from_str)) ? |_| Exit(1)
	Ok({})
}
