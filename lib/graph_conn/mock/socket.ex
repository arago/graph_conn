defmodule GraphConn.Mock.Socket do
  @moduledoc false

  @behaviour :cowboy_websocket

  def init(
        %{headers: %{"sec-websocket-protocol" => "0.9, token-action_" <> client_type}} = request,
        _state
      ) do
    state = %{registry_key: "action_" <> client_type}

    {:cowboy_websocket, request, state}
  end

  def init(request, _state) do
    state = %{registry_key: request.path}

    {:cowboy_websocket, request, state}
  end

  def websocket_init(state) do
    Registry.TestSockets
    |> Registry.register(state.registry_key, {})

    {:ok, state}
  end

  def websocket_handle({:text, incoming_message}, state) do
    incoming_message
    |> Jason.decode!(keys: :atoms)
    |> _respond(state)

    {:ok, state}
  end

  defp _respond(%{type: "acknowledged", id: _id}, _state),
    do: :ok

  defp _respond(%{type: "submitAction", id: id, capability: "nack"}, state) do
    nack =
      %{
        type: "negativeAcknowledged",
        id: id,
        code: 403,
        message: "Forbidden"
      }
      |> Jason.encode!()

    Registry.TestSockets
    |> Registry.dispatch(state.registry_key, fn entries ->
      for {pid, _} <- entries do
        Process.send(pid, nack, [])
      end
    end)
  end

  defp _respond(
         %{type: "submitAction", id: id, capability: capability} = request,
         %{registry_key: "action_invoker"} = state
       ) do
    capabilities = ActionInvoker.available_capabilities()

    if capability in Map.keys(capabilities) do
      Registry.TestSockets
      |> Registry.register(id, {})

      1..5
      |> Enum.random()
      |> Process.sleep()

      ack =
        %{
          type: "acknowledged",
          id: id
        }
        |> Jason.encode!()

      Registry.TestSockets
      |> Registry.dispatch(state.registry_key, fn entries ->
        for {pid, _} <- entries do
          Process.send(pid, ack, [])
        end
      end)

      Registry.TestSockets
      |> Registry.dispatch("action_handler", fn entries ->
        for {pid, _} <- entries do
          Process.send(pid, Jason.encode!(request), [])
        end
      end)
    else
      nack =
        %{
          type: "negativeAcknowledged",
          id: id,
          code: 404,
          message: "capability #{capability} not found"
        }
        |> Jason.encode!()

      Registry.TestSockets
      |> Registry.dispatch(state.registry_key, fn entries ->
        for {pid, _} <- entries do
          Process.send(pid, nack, [])
        end
      end)
    end
  end

  defp _respond(
         %{type: "sendActionResult", id: id} = response,
         %{registry_key: "action_handler"} = state
       ) do
    ack =
      %{
        type: "acknowledged",
        id: id
      }
      |> Jason.encode!()

    Registry.TestSockets
    |> Registry.dispatch(state.registry_key, fn entries ->
      for {pid, _} <- entries do
        Process.send(pid, ack, [])
      end
    end)

    Registry.TestSockets
    |> Registry.dispatch(id, fn entries ->
      for {pid, _} <- entries do
        Process.send(pid, Jason.encode!(response), [])
      end
    end)
  end

  defp _respond(msg, state) do
    response =
      %{"type" => "error", "code" => 400, "message" => "invalid action message #{inspect(msg)}"}
      |> Jason.encode!()

    Registry.TestSockets
    |> Registry.dispatch(state.registry_key, fn entries ->
      for {pid, _} <- entries, do: Process.send(pid, response, [])
    end)
  end

  def websocket_info(info, state) do
    {:reply, {:text, info}, state}
  end
end
