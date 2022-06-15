# 1.5.2

## 1. Enhancements
  * Allow `config :graph_conn, insecure: true` to force insecure SSL connections

# 1.5.1

## 1. Bug fix
  * Fix ssl options for ws connection

# 1.5.0

## 1. Enhancements
  * Use `finch` lib for REST requests instead of `machine_gun`.

# 1.4.1

## 1. Enhancements
  * Update all deps and fix dialyzer errors

# 1.4.0

## 1. Bug fix
  * Action executions are not performed inside Cachex process

# 1.3.2

## 1. Bug fix
  * Processes will now unregister themself after execution

# 1.3.1

## 1. Enhancements
  * Update dependencies for later erlang compatibility

# 1.3.0

## 1. Enhancements
  * Replace con_cache with cachex.

# 1.2.0

## 1. Bug fix
  * Make request_id for action api deterministic.

# 1.1.5

## 1. Enhancements
  * Process ws response and prepare request out of Connection process.

# 1.1.4

## 1. Bug fixes
  * Fix problem with RequestRegistry when ack/nack is received for already processed request.

# 1.1.3

## 1. Enhancements
  * Send WS and REST related telemetry events

# 1.1.2

## 1. Bug fix
  * Action Handler will pass on inspected error if error not json encodable

# 1.1.1

## 1. Bug fix
  * Action Invoker ignores received response if it can't find request_id in registry 5 times with a second wait time

# 1.1.0

## 1. Enhancements
  * Default (local) request registry can be changed with clients (distributed) version

# 1.0.4

## 1. Enhancements
  * Generate smaller request ids by using murmur hash

# 1.0.3

## 1. Enhancements
  * Improve logging for Action API

## 2. Bug fix
  * Fix stopping ws connection on missing pongs.

# 1.0.2

## 1. Enhancements
  * Default authentication to 60sec
  * Allow `timeout` in graph_con config for default execution timeout (defaults to 5 sec).
  * Allow `timeout` in graph_coni[:auth] config for default authentication timeout (defaults to 60 sec).

# 1.0.1

## 1. Enhancements
  * Stop GraphConn process if authentication returns 401
  * Exponentially increase delay between two unsuccessful authentications
  * Require cowlib ~> 2.9.1

# 1.0.0

## 1. Enhancements
  * Handle GOAWAY message sent by server.
