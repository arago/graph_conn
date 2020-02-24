defmodule GraphConn.WsConnections do
  @moduledoc false

  use DynamicSupervisor

  def _name(base_name),
    do: Module.concat(base_name, WsConnections)

  def start_link([base_name]),
    do: DynamicSupervisor.start_link(__MODULE__, :ok, name: _name(base_name))

  def start_connection(base_name, api, config, internal_state, version, token) do
    spec = {GraphConn.WsConnection, [base_name, api, config, internal_state, version, token]}

    base_name
    |> _name()
    |> DynamicSupervisor.start_child(spec)
  end

  def init(:ok),
    do: DynamicSupervisor.init(strategy: :one_for_one)
end
