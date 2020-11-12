defmodule GraphConn.ActionApi.Handler do
  @moduledoc """
  This module is behaviour that should be used in module that will represent
  main entry point for communication with Graph Action API in a role of action handler,
  meaning it will receive action requests, execute them agains environment and return response back.
  """

  @callback default_execution_timeout(String.t()) :: non_neg_integer()
  @callback resend_response_timeout() :: non_neg_integer()

  defmacro __using__(opts \\ []) do
    quote do
      use Supervisor
      @behaviour GraphConn
      @behaviour GraphConn.ActionApi.Handler
      alias GraphConn.ActionApi
      require Logger

      defp _get_config do
        unquote(opts)
        |> Keyword.get(:otp_app, :graph_conn)
        |> Application.get_env(__MODULE__)
      end

      defp _put_config(nil), do: _get_config()
      defp _put_config([]), do: _get_config()

      defp _put_config(config) do
        unquote(opts)
        |> Keyword.get(:otp_app, :graph_conn)
        |> Application.put_env(__MODULE__, config)

        config
      end

      @doc false
      @spec _task_supervisor_name() :: module()
      def _task_supervisor_name(),
        do: Module.concat(__MODULE__, TaskSupervisor)

      @doc false
      @spec _request_cache_name() :: module()
      def _request_cache_name(),
        do: Module.concat(__MODULE__, RequestCache)

      def start_link(config \\ nil) do
        Supervisor.start_link(__MODULE__, _put_config(config), name: __MODULE__)
      end

      @impl Supervisor
      def init(config) do
        children = [
          {ConCache,
           [
             name: _request_cache_name(),
             ttl_check_interval: :timer.minutes(1),
             global_ttl: :timer.hours(12),
             acquire_lock_timeout: :timer.minutes(20)
           ]},
          {GraphConn.Supervisor, [__MODULE__, {config, %{}}]},
          {Task.Supervisor, [name: _task_supervisor_name()]},
          {ActionApi.Responder, __MODULE__}
        ]

        Supervisor.init(children, strategy: :one_for_one)
      end

      @doc """
      Returns current status of main (REST) connection with HIRO Graph server.
      """
      @spec status() :: GraphConn.status()
      def status,
        do: GraphConn.status(__MODULE__)

      @impl GraphConn
      @doc false
      def on_status_change(:ready, _),
        do: :ok = GraphConn.open_ws_connection(__MODULE__, :"action-ws")

      def on_status_change(new_status, _),
        do: Logger.debug("[ActionHandler] New ActionAPI status changed to #{inspect(new_status)}")

      @impl GraphConn
      @doc false
      def on_status_change(:"action-ws", status, _),
        do: Logger.info("[ActionHandler] New ActionWS status: #{inspect(status)}")

      @impl GraphConn
      @doc false
      def handle_message(:"action-ws", %{"type" => "acknowledged", "id" => req_id} = _msg, _),
        do: ActionApi.Responder.response_acked(__MODULE__, req_id)

      def handle_message(
            :"action-ws",
            %{"type" => "negativeAcknowledged", "id" => req_id} = _msg,
            _
          ) do
        Logger.warn("[ActionHandler] Server returned NACK", req_id: req_id)
        ActionApi.Responder.response_acked(__MODULE__, req_id)
      end

      def handle_message(
            :"action-ws",
            %{
              "type" => "submitAction",
              "id" => req_id,
              "capability" => capability,
              "parameters" => params
            } = msg,
            _
          ) do
        execution_timeout = msg["timeout"] || default_execution_timeout(capability)

        task = fn ->
          Logger.metadata(req_id: req_id)
          Logger.debug("[ActionHandler] Received message: #{inspect(msg)}")

          GraphConn.execute(__MODULE__, :"action-ws", %GraphConn.Request{
            body: %{id: req_id, type: "acknowledged", code: 200, message: ""}
          })

          _request_cache_name()
          |> ConCache.get_or_store(
            req_id,
            fn ->
              Logger.info("[ActionHandler] Executing #{inspect(capability)}: #{inspect(params)}")

              result =
                case execute(capability, params) do
                  :ok ->
                    ""

                  {:ok, response} ->
                    response
                    |> Jason.encode!()
                    |> _check_payload_size()

                  {:error, error} ->
                    Jason.encode!(%{error: error})
                end

              Logger.info("[ActionHandler] Sending result")

              %GraphConn.Request{
                body: %{id: req_id, type: "sendActionResult", result: result}
              }
            end
          )
          |> ActionApi.Responder.return_response(__MODULE__, resend_response_timeout())
        end

        Task.Supervisor.start_child(_task_supervisor_name(), task, shutdown: execution_timeout)
      end

      def handle_message(:"action-ws", msg, _) do
        Logger.warn("[ActionHandler] Received unexpected message from action-ws: #{inspect(msg)}")
      end

      defp _check_payload_size(response) when byte_size(response) > 1_000_000 do
        %{error: "Response is exceeding limit of 1MB"}
        |> Jason.encode!()
      end

      defp _check_payload_size(response),
        do: response

      @spec default_execution_timeout(String.t()) :: non_neg_integer()
      def default_execution_timeout(_capability),
        do: 60_000

      @spec resend_response_timeout() :: non_neg_integer()
      def resend_response_timeout,
        do: 3_000

      def execute(capability, _params) do
        Logger.warn("[ActionHandler] Unhandled capability received: #{capability}")
        {:error, %{code: 404, message: "Unhandled capability #{inspect(capability)}"}}
      end

      defoverridable default_execution_timeout: 1, resend_response_timeout: 0, execute: 2
    end
  end
end
