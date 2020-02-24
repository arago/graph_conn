defmodule GraphConn.TestApplication do
  @moduledoc false

  use Application
  require Logger

  @port 8081

  def start(_type, _args) do
    invoker_credentials = [
      client_id: "action_invoker",
      client_secret: "action_invoker_secret",
      username: "action_invoker_username",
      password: "action_invoker_password"
    ]

    config =
      :graph_conn
      |> Application.get_env(TestConn)
      |> Keyword.put(:host, "localhost")
      |> Keyword.put(:port, @port)
      |> Keyword.put(:transport, :tcp)
      |> Keyword.put(:credentials, invoker_credentials)

    Application.put_env(:graph_conn, TestConn, config)

    handler_credentials = [
      client_id: "action_handler",
      client_secret: "action_handler_secret",
      username: "action_handler_username",
      password: "action_handler_password"
    ]

    handler_config =
      config
      |> Keyword.put(:credentials, handler_credentials)

    Application.put_env(:graph_conn, ActionHandler, handler_config)

    children = [
      {Plug.Cowboy,
       scheme: :http, plug: GraphConn.TestRouter, options: [dispatch: _dispatch(), port: @port]},
      Registry.child_spec(
        keys: :duplicate,
        name: Registry.TestSockets
      )
    ]

    opts = [strategy: :one_for_one, name: __MODULE__]
    Logger.info("Starting local test server @ port #{inspect(@port)}")
    Supervisor.start_link(children, opts)
  end

  defp _dispatch do
    [
      {:_,
       [
         {"/api/0.9/action-ws/[...]", GraphConn.TestSocket, []},
         {:_, Plug.Cowboy.Handler, {GraphConn.TestRouter, []}}
       ]}
    ]
  end
end
