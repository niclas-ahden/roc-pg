#!/usr/bin/env roc
## All tests: the package's `expect` blocks, a syntax check of the examples,
## then the integration tests against a throwaway Postgres server.
##
## The server binaries (initdb, pg_ctl) come from the flake dev shell:
##
##     nix develop -c ./tests.roc
app [main!] {
	pf: platform "https://github.com/niclas-ahden/basic-cli/releases/download/0.29.0/GrSTLEKd6yw8orQ5ByQQVY3Htg59vZYaoHBvQELueiMB.tar.zst",
}

import pf.Stdout
import pf.Cmd
import pf.Env
import pf.Path
import pf.Utc
import pf.OsStr

pg_port = "5499"

pg_user = "roc_pg_test"

pg_database = "postgres"

main! = |_args| {
	Stdout.line!("== unit tests")?
	run!("roc", ["test", "package/main.roc"])?

	Stdout.line!("== check examples and tests")?
	for file in ["examples/query.roc", "examples/prepared.roc", "examples/webserver.roc", "tests/integration.roc", "tests/concurrent/server.roc"] {
		check!(file)?
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

	# The integration tests log in with a password as dedicated users, for
	# each way the server can ask for it: cleartext, md5 and SCRAM, and for
	# SCRAM with the passwords and iteration counts of test_scram_passwords!.
	# pg_hba rules are first-match-wins, so these go before the catch-all
	# trust rules initdb generated.
	hba_path = data_dir.join("pg_hba.conf")
	hba = Path.read_utf8!(hba_path)?
	scram_users = Str.join_with(["roc_pg_scram_test", "roc_pg_scram_utf8_test", "roc_pg_scram_nbsp_test", "roc_pg_scram_low_test", "roc_pg_scram_high_test"], ",")
	Path.write_utf8!(hba_path, "host all roc_pg_password_test 127.0.0.1/32 password\nhost all roc_pg_md5_test 127.0.0.1/32 md5\nhost all ${scram_users} 127.0.0.1/32 scram-sha-256\n${hba}")?

	# The socket dir is pointed into the data dir because the default
	# (/run/postgresql) is not writable in CI or the nix dev shell.
	run!("pg_ctl", ["start", "-D", data, "-l", "${data}/log", "-w", "-o", "-p ${pg_port} -c listen_addresses=127.0.0.1 -k ${data}"])?

	result = run!("roc", ["tests/integration.roc", "127.0.0.1", pg_port, pg_user, pg_database])

	concurrent_result =
		match result {
			Ok({}) => concurrent!({})
			Err(_) => Ok({})
		}

	# Stop the server whether the tests passed or not.
	_ = run!("pg_ctl", ["stop", "-D", data, "-m", "immediate"])

	result?
	concurrent_result?
	Stdout.line!("all tests passed")
}

## `roc check` a file. roc exits 2 when it warned but found no errors. A
## warning in this repository still fails the check. One in a package roc
## downloaded, like the official basic-webserver warning about its own
## files, cannot be fixed here, so it does not.
check! : Str => Try({}, [Exit(I32)])
check! = |file| {
	output = Cmd.new_str("roc").args_str(["check", file]).stdout(Tee).stderr(Tee).run!() ? |_| Exit(1)
	match output.status {
		Exited(0) => Ok({})
		Exited(2) => {
			locations = warning_locations(Str.from_utf8_lossy(output.stdout_bytes.concat(output.stderr_bytes)))
			if !locations.is_empty() and !locations.any(in_repo) {
				Stdout.line!("(${locations.len().to_str()} warnings, all in downloaded packages)") ? |_| Exit(1)
				Ok({})
			} else {
				Err(Exit(2))
			}
		}
		_ => Err(Exit(1))
	}
}

## The file of each warning roc printed, read from its header, such as
## `── ● redundant open tag union ─ ../../.cache/roc/packages/.../Cmd.roc:48:233`.
warning_locations : Str -> List(Str)
warning_locations = |text|
	text.split_on("\n").keep_if(|line| line.starts_with("── ● ")).map(
		|line| {
			last = line.trim_end().split_on(" ").last() ?? ""
			parts = last.split_on(":")
			# Drop the line and column. A Windows path keeps the colon of its drive.
			if parts.len() >= 3 Str.join_with(parts.drop_last(2), ":") else last
		},
	)

## Whether a path roc printed, relative to the repository root, is inside
## it. roc prints a file elsewhere with a leading `..` or as an absolute path.
in_repo : Str -> Bool
in_repo = |path| {
	forward = Str.join_with(path.split_on("\\"), "/")
	drive =
		match forward.to_utf8().get(1) {
			Ok(58) => Bool.True
			_ => Bool.False
		}
	!(forward.starts_with("..") or forward.starts_with("/") or drive)
}

# Run a command with inherited stdio, failing the script on a nonzero exit.
run! : Str, List(Str) => Try({}, [Exit(I32)])
run! = |program, arguments| {
	Cmd.exec!(OsStr.from_str(program), arguments.map(OsStr.from_str)) ? |_| Exit(1)
	Ok({})
}

# ---- concurrency, through a platform that runs handlers in parallel ----

concurrent_dir = ".concurrent-test"

concurrent_port = "8765"

concurrent_requests : U64
concurrent_requests = 300

concurrent_parallel : U64
concurrent_parallel = 40

## How long the server's query sleeps, so that requests overlap.
concurrent_sleep_ms : U64
concurrent_sleep_ms = 20

## basic-cli runs a script one step at a time, so the integration tests never
## have two requests racing. tests/concurrent/server.roc is a web server on
## basic-webserver whose handlers run at the same time, each on a connection
## of its own. It is hit with many requests at once, and every reply must
## carry its own number.
##
## Needs curl.
concurrent! = |{}| {
	Stdout.line!("== concurrent requests, a connection each")?
	dir = Path.utf8(concurrent_dir)
	if Path.exists!(dir)? {
		Path.delete_all!(dir)?
	}
	Path.create_dir!(dir)?
	run!("roc", ["build", "tests/concurrent/server.roc", "--output=${concurrent_dir}/server"])?

	server =
		Cmd.new_str("${concurrent_dir}/server")
			.envs_str([
				("PG_HOST", "127.0.0.1"),
				("PG_PORT", pg_port),
				("PG_USER", pg_user),
				("PG_DATABASE", pg_database),
				("LISTEN_PORT", concurrent_port),
			])
			.stdout(Null)
			.stderr(Null)
			.spawn_leashed!()
			.map_err(|_| ConcurrentServerDidNotStart)?

	outcome = concurrent_checks!({})
	_ = server.kill!()
	outcome?
	Stdout.line!("ok: ${concurrent_requests.to_str()} concurrent requests, ${concurrent_parallel.to_str()} at a time, a connection each")
}

concurrent_checks! = |{}| {
	base = "http://127.0.0.1:${concurrent_port}/q"

	# Wait for the server to listen.
	run!("curl", ["--silent", "--fail", "--output", "/dev/null", "--retry", "100", "--retry-delay", "0", "--retry-connrefused", "--retry-max-time", "20", "${base}/0"])?

	# One file per request, so each reply can be matched to its request.
	started = Utc.now!()
	run!("curl", ["--silent", "--parallel", "--parallel-immediate", "--parallel-max", concurrent_parallel.to_str(), "--output", "${concurrent_dir}/reply_#1.txt", "${base}/[1-${concurrent_requests.to_str()}]"])?
	elapsed_ms = Utc.delta_as_millis(started, Utc.now!())

	_ = collect_pids!(1, [])?
	# One request after another would take the sleep of every one of them.
	# Twice as fast is well short of what overlapping requests take, and far
	# more than they need.
	one_by_one_ms = concurrent_requests * concurrent_sleep_ms
	Stdout.line!("${concurrent_requests.to_str()} requests took ${elapsed_ms.to_str()} ms, one by one they would take at least ${one_by_one_ms.to_str()} ms")?
	if elapsed_ms > U64.to_u128(one_by_one_ms // 2) {
		Err(ConcurrentTestFailed("the requests never ran in parallel"))
	} else {
		Ok({})
	}
}

## Every reply must be the answer to its own request: "n=<i> pid=<pid>".
collect_pids! = |index, pids|
	if index > concurrent_requests {
		Ok(pids)
	} else {
		reply = Path.read_utf8!(Path.utf8("${concurrent_dir}/reply_${index.to_str()}.txt")).map_err(|_| ConcurrentTestFailed("no reply for request ${index.to_str()}"))?
		expected = "n=${index.to_str()} pid="
		if reply.starts_with(expected) {
			collect_pids!(index + 1, pids.append(reply.drop_prefix(expected)))
		} else {
			Err(ConcurrentTestFailed("request ${index.to_str()} got: ${reply}"))
		}
	}
