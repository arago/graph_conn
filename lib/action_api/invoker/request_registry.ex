defmodule GraphConn.ActionApi.Invoker.RequestRegistry do
  @moduledoc !"""
             Registry of `request_id` => `[calling_process]`. Each 
             request invoker is registered here so it should expect
             `:ack` and `:response` messages sent back to it.
             """

  defp _name(base_name),
    do: Module.concat(base_name, RequestRegistry)

  def child_spec(arg) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [arg]}
    }
  end

  def start_link(base_name) do
    Registry.start_link(
      keys: :duplicate,
      name: _name(base_name),
      partitions: System.schedulers_online()
    )
  end

  @doc """
  Registers calling process as requester for given `request_id`,
  meaning that it should expect `{:ack, request_id}` and 
  `{:response, request_id, response, ack_response}` messages.
  """
  @spec register(module(), String.t()) :: :ok
  def register(base_name, request_id) do
    {:ok, _} =
      base_name
      |> _name()
      |> Registry.register(request_id, [])

    :ok
  end

  @doc """
  Sends `{:ack, request_id}` messages to all process that registered
  themselves with `request_id`. This message is sent when Action API
  acks message on it's part.
  """
  def ack(base_name, request_id) do
    base_name
    |> _name()
    |> Registry.dispatch(request_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:ack, request_id})
    end)

    :ok
  end

  @doc """
  Sends `{:nack, request_id, %{code: error_code, message: error_description}}`
  messages to all process that registered themselves with `request_id`.

  This message is sent when Action API nacks message on it's part.
  """
  def nack(base_name, request_id, error) do
    name = _name(base_name)

    Registry.dispatch(name, request_id, fn entries ->
      for {pid, _} <- entries, do: send(pid, {:nack, request_id, error})
    end)

    Registry.unregister(name, request_id)
    :ok
  end

  @doc """
  Sends `{:response, request_id, response, ack_response}` messages to
  all process that registered themselves with `request_id`.
  """
  def respond(base_name, request_id, response) do
    name = _name(base_name)

    Registry.dispatch(name, request_id, fn entries ->
      for {pid, _} <- entries,
          do: send(pid, {:response, request_id, response})
    end)

    Registry.unregister(name, request_id)
    :ok
  end
end
