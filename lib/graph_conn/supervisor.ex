defmodule GraphConn.Supervisor do
  @moduledoc false

  use Supervisor

  def child_spec([base_name, config]) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [base_name, config]}
    }
  end

  def start_link(base_name, {config, internal_state}) do
    Supervisor.start_link(__MODULE__, {base_name, config, internal_state}, name: _name(base_name))
  end

  def stop(base_name, reason, timeout) do
    base_name
    |> _name()
    |> Supervisor.stop(reason, timeout)
  end

  @impl true
  def init({base_name, config, internal_state}) do
    [
      {GraphConn.ClientState, [base_name, internal_state]},
      {GraphConn.WsConnections, [base_name]},
      {Finch, name: Module.concat(base_name, Finch)},
      {GraphConn.ConnectionManager, [base_name, config]}
    ]
    |> Supervisor.init(strategy: :one_for_all)
  end

  defp _name(base_name), do: Module.concat(base_name, Supervisor)
end
