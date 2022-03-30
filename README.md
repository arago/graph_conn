# GraphConn

This library serves as a communication layer between HIRO engine and ActionHandler on one side,
and HIRO Graph server on the other.

## Installation

Import library as dependency using git path (and optional tag/branch):

```elixir
def deps do
  [
    {:graph_conn, git: "git@github.com:arago/graph_conn.git", tag: "latest"}
  ]
end
```

## Telemetry

  Sends telemetry events:
    * `[:graph_conn, :ws_upgrade], %{time, duration}, %{node, success}`
    * `[:graph_conn, :ws_down], %{time}, %{node}`
    * `[:graph_conn, :ws_lost_connection], %{time}, %{node}`
    * `[:graph_conn, :ws_sent_bytes], %{time, duration, bytes}, %{node}`
    * `[:graph_conn, :ws_received_bytes], %{time, bytes}, %{node}`
    * `[:graph_conn, :rest], %{time, duration, bytes_sent, bytes_received}, %{node, path, method, status_code}`

  `time` is in UTC, `success` is boolean, `duration` is in ms, `bytes` is number of bytes sent or recieved.

## Test

Run `mix test` to run ActionInvoker and ActionHandler tests against local mock server. For tests running through Graph create `config/git_ignored.exs` file and set with correct credentials:

```
import Config

config :graph_conn, GraphConn.TestConn,
  url: "https://ec2-63-33-203-84.eu-west-1.compute.amazonaws.com:8443",
  insecure: true,
  auth: [
    credentials: [
      client_id: "<CLIENT_ID>",
      client_secret: "<CLIENT_SECRET>",
      username: "<USERNAME>",
      password: "<PASSWORD>"
    ]
  ]

config :graph_conn, GraphConn.Test.ActionHandler,
  url: "https://ec2-63-33-203-84.eu-west-1.compute.amazonaws.com:8443",
  insecure: true,
  auth: [
    credentials: [
      client_id: "<AH_CLIENT_ID>",
      client_secret: "<AH_CLIENT_SECRET>",
      username: "<AH_USERNAME>",
      password: "<AH_PASSWORD>"
    ]
  ]
```

and then run

```
INTEGRATION_TESTS=true mix test
```

## Usage

### Define your Conn module


```elixir
defmodule MyConn do
  use GraphConn, otp_app: :graph_conn
  require Logger

  def on_status_change(new_status, _) do
    Logger.debug("New status for main connection is: #{inspect(new_status)}")
  end

  def on_status_change(api, new_status, _) do
    Logger.debug("New status for #{api} connection is: #{inspect(new_status)}")
  end

  def handle_message(api, msg, _) do
    Logger.debug("Received new message #{inspect(msg)} from #{api}")
  end
end
```

### Start connection

Connection can be started either manually or preferably as a part of supervision tree:

```elixir
def start(_, _) do
  children = [
    {MyConn, [:from_config]},
    # ... other children
  ]
  
  opts = [strategy: :one_for_one]
  Supervisor.start_link(children, opts)
end
```

### Configuration

Set Graph server details

```elixir
config :graph_conn, MyConn,
  host: "example.com",
  port: 8443,
  insecure: true,
  credentials: [
    client_id: "client_id",
    client_secret: "client_secret",
    password: "password%",
    username: "me@arago.de"
  ]
```

For communication with Graph server with REST calls we use pool of connections.

### Invoke call

Once connection is started, it will pick api versions from Graph server and authenticate
using `:credentials` from configuration. When everything is ready, `on_status_change/2` callback
will be invoked with `new_status = :ready`.

Current connection status can be also checked explicitly:

```elixir
:ready = MyConn.status()
```

Prepare request and execute it against some api (`:action` in this case).

```elixir
config_id = "my_config_id"
request = %GraphConn.Request{
  path: "app/#{config_id}/handlers"
}
{:ok, %GraphConn.Response{} = response} = MyConn.execute(:action, request)
```

## Documentation

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc):

`$> mix docs`

## Tests

Tests can be run against integrated Mock server or against real Graph server (configured in config/config.exs).

By default tests are run against Mock server, but if system env var `INTEGRATION_TESTS=true` is set,
tests will be run against real server. When switching between those two modes on local computer,
`mix.exs` needs to be changed in order to force `.app` file recompilation.

So in order to run integration tests, start them as:

```
$> touch mix.exs && INTEGRATION_TESTS=true mix test
```

and if you want to move back to Mock server do:

```
$> touch mix.exs && mix test
```
