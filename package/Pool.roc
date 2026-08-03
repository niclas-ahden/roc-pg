## A pool of Postgres connections, so concurrent work checks out its own
## connection instead of conflicting on a shared one.
##
## The connections themselves live in a host-managed pool (basic-cli's
## `Tcp.Pool`); this module layers the Postgres session on top: a `fresh`
## connection gets the startup/auth handshake, a recycled one is already
## authenticated and mid-session (its backend key rides along in the pool's
## metadata blob).
##
## Build a pool once with [Pool.new!]. The pool record's TCP handle is a
## platform type, so the app declares the alias (this package never names
## platform types):
##
## ```
## PgPool : { tcp_pool : Tcp.Pool, user : Str, database : Str, auth : [NoAuth, Password(Str)], timeout_ms : U64 }
##
## pool = Pool.new!(effects, { host: "localhost", port: 5432, user: "postgres", database: "postgres", auth: NoAuth, timeout_ms: 5000, max_connections: 16 })
##
## client = Pool.acquire!(effects, pool)?
## result = Client.command!(cmd, client)?
## Pool.release!(client)
## ```
##
## A checked-out connection that is dropped without `release!` frees its pool
## slot when the last reference goes away, and a possibly mid-protocol
## connection is never reused. `release!` verifies the connection before
## pooling it: a connection the server reports idle goes back, an abandoned
## transaction is rolled back first, and a connection that fails the cleanup
## is closed.
import Bytes
import Client
import Cmd

Pool :: [].{

	## Create a connection pool. Dials nothing up front — connections are
	## established (and authenticated) lazily on first acquire, and at most
	## `max_connections` exist at once. `timeout_ms` caps each TCP dial, read,
	## and write on every connection acquired from this pool.
	new! = |effects, { host, port, user, database, auth, timeout_ms, max_connections }| {
		tcp_pool! = effects.pool!
		tcp_pool = tcp_pool!({ host, port, max_connections })
		{ tcp_pool, user, database, auth, timeout_ms }
	}

	## Check a connection out of the pool: recycled and ready if one is
	## available, freshly dialed and authenticated otherwise.
	acquire! = |effects, pool| {
		tcp_acquire! = effects.pool_acquire!
		{ stream, fresh, metadata } = tcp_acquire!(pool.tcp_pool)?

		if fresh {
			match Client.startup!(effects, stream, { user: pool.user, database: pool.database, auth: pool.auth, timeout_ms: pool.timeout_ms }) {
				Ok(client) => Ok(client)
				Err(err) => {
					# Close rather than release: a half-started session must
					# not go back into the pool, and the package cannot assume
					# the platform closes dropped streams.
					close! = effects.close!
					_ = close!(stream)
					Err(err)
				}
			}
		} else {
			Ok({ stream, effects, timeout_ms: pool.timeout_ms, backend_key: decode_key(metadata) })
		}
	}

	## Return a connection to the pool for another request to reuse.
	##
	## Only a verified-clean connection is pooled: a Sync round trip asks the
	## server for its transaction status first. An idle connection goes
	## straight back, and a connection left mid-transaction (open or failed)
	## gets a rollback so the abandoned transaction cannot leak into the next
	## checkout. A connection that errors during this cleanup is closed
	## instead, and the pool dials a fresh one on a later acquire.
	release! = |client| {
		status =
			match Client.sync_status!(client) {
				Ok(Idle) => Ok(Idle)
				Ok(TransactionBlock) | Ok(FailedTransactionBlock) =>
					match Client.command!(Cmd.new("rollback"), client) {
						Ok(_) => Client.sync_status!(client)
						Err(err) => Err(err)
					}
				Err(err) => Err(err)
			}

		match status {
			Ok(Idle) => {
				tcp_release! = client.effects.pool_release!
				tcp_release!({ stream: client.stream, metadata: encode_key(client.backend_key) })
			}
			_ => Client.close!(client)
		}
	}
}

## The backend key (needed for query cancellation) is per-connection session
## state; persist it across checkouts in the pool's metadata blob as two
## big-endian i32s.
encode_key = |backend_key|
	match backend_key {
		Known({ process_id, secret_key }) => Bytes.i32(process_id).concat(Bytes.i32(secret_key))
		Pending => []
	}

decode_key = |metadata|
	match Bytes.take_i32(metadata) {
		Ok({ val: process_id, rest }) =>
			match Bytes.take_i32(rest) {
				Ok({ val: secret_key, rest: _ }) => Known({ process_id, secret_key })
				Err(_) => Pending
			}
		Err(_) => Pending
	}
