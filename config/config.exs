import Config

config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:req_id, :pid]

config :graph_conn, TestConn,
  url: "https://ec2-52-208-152-194.eu-west-1.compute.amazonaws.com:8443",
  insecure: true,
  auth: [
    credentials: [
      client_id: "ck9jz6vab011b0j6156i9cwyy",
      client_secret:
        "nqdwwpWZkaxlQUpPlwa2pyJo1cJkdpO4aMSJQZ81s5se7D8HkfaSZobqsTBONYQp62t5DZSku3t2l9DlBFrNauoGw2mXCzN6m7QAJ4HDo0YkNDuJGyPMGChFg6mOzok6",
      username: "saas_customer1.org-instance1-engine_main",
      password: "Ix6e7MmyicId%1aZ"
    ]
  ]

config :graph_conn, ActionHandler,
  url: "https://ec2-52-208-152-194.eu-west-1.compute.amazonaws.com:8443",
  insecure: true,
  auth: [
    credentials: [
      client_id: "ck9jz9pqx07s10j61mv1sz24v",
      client_secret:
        "1ZYcBDASvPi1K2q8TEDi38w6sLoTYx37X4oSVbgJNgdmmU7XsXF4Kbbp8umpnwQXOUfjJFeKqWW52kQHK1CpirO8vfY25EaDorNedizGHiGHkKs133aELnMmgBX9ao20",
      username: "saas_customer1.org-instance1-actionhandler1",
      password: "lnpjco7d4hmle5db267eh98ra1%1aZ"
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
