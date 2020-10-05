defmodule GraphConn.ActionApi.Responder do
  use GenServer
  require Logger

  def name(base_name),
    do: Module.concat(base_name, Responder)

  def start_link(base_name),
    do: GenServer.start_link(__MODULE__, base_name, name: name(base_name))

  @impl GenServer
  def init(base_name),
    do: {:ok, %{base_name: base_name, responses: %{}}}

  def return_response(%GraphConn.Request{} = response, base_name, resend_after) do
    base_name
    |> name()
    |> GenServer.cast({:register_response, response, resend_after})

    GraphConn.execute(base_name, :"action-ws", response)
  end

  @spec response_acked(module(), String.t()) :: :ok
  def response_acked(base_name, req_id) do
    base_name
    |> name()
    |> GenServer.cast({:response_acked, req_id})
  end

  @impl GenServer
  def handle_cast(
        {:register_response, %GraphConn.Request{body: %{id: req_id}} = response, resend_after},
        state
      ) do
    responses =
      if Map.has_key?(state.responses, req_id) do
        state.responses
      else
        ref =
          state.base_name
          |> name()
          |> Process.send_after({:resend_response, req_id, resend_after}, resend_after)

        Map.put(state.responses, req_id, {response, ref})
      end

    {:noreply, %{state | responses: responses}}
  end

  def handle_cast({:response_acked, req_id}, state) do
    responses =
      state.responses
      |> Map.pop(req_id)
      |> case do
        {nil, responses} ->
          responses

        {{_, ref}, new_responses} ->
          Logger.info("[ActionHandler.Responder] Response acked", req_id: req_id)
          Process.cancel_timer(ref)
          new_responses
      end

    {:noreply, %{state | responses: responses}}
  end

  @impl GenServer
  def handle_info({:resend_response, req_id, resend_after}, state) do
    resend_after = resend_after * 2

    responses =
      if Map.has_key?(state.responses, req_id) do
        {%GraphConn.Request{} = response, _} = Map.get(state.responses, req_id)

        ref =
          state.base_name
          |> name()
          |> Process.send_after({:resend_response, req_id, resend_after}, resend_after)

        Logger.warn("[ActionHandler.Responder] Resending response", req_id: req_id)
        GraphConn.execute(state.base_name, :"action-ws", response)
        Map.put(state.responses, req_id, {response, ref})
      else
        state.responses
      end

    {:noreply, %{state | responses: responses}}
  end
end
