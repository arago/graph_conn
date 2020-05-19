defmodule GraphConn.Mock.Application do
  @moduledoc false

  use Application
  require Logger
  alias GraphConn.Mock

  @port 8081

  def start(_type, _args) do
    _inject_local_config()

    children = [
      {Plug.Cowboy,
       scheme: :http, plug: Mock.Router, options: [dispatch: _dispatch(), port: @port]},
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
         {"/api/0.9/action-ws/[...]", Mock.Socket, []},
         {:_, Plug.Cowboy.Handler, {Mock.Router, []}}
       ]}
    ]
  end

  defp _inject_local_config do
    invoker_credentials = [
      client_id: "action_invoker",
      client_secret: "action_invoker_secret",
      username: "action_invoker_username",
      password: "action_invoker_password"
    ]

    handler_credentials = [
      client_id: "action_handler",
      client_secret: "action_handler_secret",
      username: "action_handler_username",
      password: "action_handler_password"
    ]

    config =
      :graph_conn
      |> Application.get_env(Mock.Conn)
      |> Keyword.put(:url, "http://localhost:#{@port}")
      |> Keyword.put(:transport, :tcp)

    auth_config = [credentials: invoker_credentials]
    handler_auth_config = [credentials: handler_credentials]

    config =
      config
      |> Keyword.put(:auth, auth_config)

    Application.put_env(:graph_conn, Mock.Conn, config)

    handler_config =
      config
      |> Keyword.put(:auth, handler_auth_config)

    Application.put_env(:graph_conn, ActionHandler, handler_config)
  end
end
