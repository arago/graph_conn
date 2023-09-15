defmodule GraphConn.MockGraphApplication do
  @moduledoc false

  use Application
  require Logger

  @impl Application
  def start(_type, _args) do
    :ok =
      GraphConn.Test.MockServer.inject_local_config(
        {:graph_conn, GraphConn.Test.ActionHandler},
        :valid_handler_credentials
      )

    :ok =
      GraphConn.Test.MockServer.inject_local_config(
        {:graph_conn, GraphConn.TestConn},
        :valid_invoker_credentials
      )

    invoker_config = Application.get_env(:graph_conn, GraphConn.TestConn)

    opts = [strategy: :one_for_one, name: __MODULE__]

    [
      GraphConn.Test.MockServer,
      {ActionInvoker, invoker_config}
    ]
    |> Supervisor.start_link(opts)
  end
end
