defmodule GraphConn.ClientState do
  @moduledoc !"""
             Keeps state of client conn module.
             """

  use GenServer

  defp _name(base_name),
    do: Module.concat(base_name, ClientState)

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      type: :worker
    }
  end

  def start_link(base_name, state) do
    GenServer.start_link(__MODULE__, state, name: _name(base_name))
  end

  @spec get_state(atom()) :: map()
  def get_state(base_name) do
    base_name
    |> _name()
    |> GenServer.call(:get_state)
  end

  @spec put_state(atom(), map()) :: :ok
  def put_state(base_name, new_state) do
    base_name
    |> _name()
    |> GenServer.cast({:put_state, new_state})

    :ok
  end

  @impl GenServer
  def init(state),
    do: {:ok, state}

  @impl GenServer
  def handle_call(:get_state, _from, state),
    do: {:reply, state, state}

  @impl GenServer
  def handle_cast({:put_state, new_state}, _state),
    do: {:noreply, new_state}
end
