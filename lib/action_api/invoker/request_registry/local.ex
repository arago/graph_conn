defmodule GraphConn.ActionApi.Invoker.RequestRegistry.Local do
  alias GraphConn.ActionApi.Invoker.RequestRegistry
  @behaviour RequestRegistry

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  def start_link(base_name) do
    Registry.start_link(
      keys: :duplicate,
      name: RequestRegistry.name(base_name),
      partitions: System.schedulers_online()
    )
  end

  @impl RequestRegistry
  @spec register_self(atom(), term()) :: :ok
  def register_self(name, request_id) do
    {:ok, _pid} = Registry.register(name, request_id, [])
    :ok
  end

  @impl RequestRegistry
  @spec lookup(atom(), term()) :: [pid()]
  def lookup(name, request_id) do
    name
    |> Registry.lookup(request_id)
    |> Enum.map(fn {pid, _value} -> pid end)
  end

  @impl RequestRegistry
  @spec unregister(atom(), term()) :: :ok
  def unregister(name, request_id),
    do: Registry.unregister(name, request_id)
end
