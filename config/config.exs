use Mix.Config

config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:req_id, :pid]

config :graph_conn, TestConn,
  url: "http://localhost:8081",
  insecure: true,
  auth: [
  credentials: [
    client_id: "action_invoker",
    client_secret: "action_invoker_secret",
    username: "action_invoker_username",
    password: "action_invoker_password"
  ]
  ]

config :graph_conn, ActionHandler,
  url: "http://localhost:8081",
  insecure: true,
  auth: [
  credentials: [
    client_id: "action_handler",
    client_secret: "action_handler_secret",
    username: "action_handler_username",
    password: "action_handler_password"
  ]
  ]

config :machine_gun,
  graph_conn: %{
    # Poolboy size
    pool_size: 10,
    # Poolboy max_overflow
    pool_max_overflow: 5,
    pool_timeout: 1000
  }
