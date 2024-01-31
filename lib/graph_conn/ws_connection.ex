defmodule GraphConn.WsConnection do
  @moduledoc false

  use GenServer
  alias GraphConn.{WS, Request, Instrumenter}
  require Logger

  defmodule State do
    @moduledoc false

    @type t() :: %__MODULE__{
            base_name: atom(),
            api: atom(),
            internal_state: map(),
            status: GraphConn.status(),
            last_pong: DateTime.t(),
            conn_pid: nil | pid()
          }

    @enforce_keys ~w(base_name api internal_state status last_pong)a
    defstruct @enforce_keys ++ ~w(conn_pid)a
  end

  @ping_interval Application.compile_env(:graph_conn, :ping_interval, 2_000)
  @reconnect_after_missing_pings Application.compile_env(
                                   :graph_conn,
                                   :reconnect_after_missing_pings,
                                   3
                                 )
  @reconnect_after_sec Integer.floor_div(
                         @ping_interval * @reconnect_after_missing_pings,
                         1000
                       )

  defp _name(base_name, api) do
    base_name
    |> Module.concat(api)
    |> Module.concat(WsConnection)
  end

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, opts},
      type: :worker,
      restart: :temporary
    }
  end

  @spec start_link(atom(), atom(), Keyword.t(), map(), map(), String.t()) :: GenServer.on_start()
  def start_link(base_name, api, config, internal_state, version, token) do
    GenServer.start_link(__MODULE__, {base_name, api, config, internal_state, version, token},
      name: _name(base_name, api)
    )
  end

  def execute(server, %Request{} = request),
    do: GenServer.cast(server, {:execute, request})

  @impl GenServer
  def init({base_name, api, config, internal_state, version, token}) do
    status = {:disconnected, :started}

    state =
      %State{
        base_name: base_name,
        api: api,
        internal_state: internal_state,
        status: status,
        last_pong: DateTime.utc_now()
      }
      |> _connect(config)
      |> _ws_upgrade(version.path, version.subprotocol, token)

    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:execute, %Request{} = request}, %State{} = state) do
    spawn(fn ->
      Logger.debug(fn ->
        "[WsConnection] Pushing message to #{state.api}:\n#{inspect(request.body)}"
      end)

      WS.push(state.conn_pid, Jason.encode!(request.body))
    end)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:gun_ws, conn_pid, _stream_ref, {:text, text}},
        %State{conn_pid: conn_pid} = state
      ) do
    spawn(fn ->
      :ok =
        Instrumenter.execute(
          :ws_received_bytes,
          %{time: DateTime.utc_now(), bytes: byte_size(text)},
          %{node: Node.self()}
        )

      msg = Jason.decode!(text)

      Logger.debug(fn ->
        "[WsConnection] Just received text message on #{state.api}:\n#{inspect(msg)}"
      end)

      apply(state.base_name, :handle_message, [state.api, msg, state.internal_state])
    end)

    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, conn_pid, _stream_ref, :ping},
        %State{conn_pid: conn_pid} = state
      ) do
    Logger.debug("[WsConnection] Ignore received ping, gun will send pong")
    {:noreply, state}
  end

  def handle_info(
        {:gun_ws, conn_pid, _stream_ref, :pong},
        %State{conn_pid: conn_pid} = state
      ) do
    Logger.debug("[WsConnection] Received pong")
    {:noreply, %{state | last_pong: DateTime.utc_now()}}
  end

  def handle_info(:check_last_pong, %State{} = state) do
    Logger.debug("[WsConnection] checking last pong")

    reconnect_after = @reconnect_after_sec

    DateTime.utc_now()
    |> DateTime.diff(state.last_pong)
    |> case do
      diff when diff > reconnect_after ->
        Instrumenter.execute(
          :ws_lost_connection,
          %{time: DateTime.utc_now()},
          %{node: Node.self()}
        )

        {:stop, {:error, "Missing pong for more than #{reconnect_after} seconds"}, state}

      _ ->
        Process.send_after(self(), :check_last_pong, @ping_interval)
        {:noreply, state}
    end
  end

  def handle_info({:DOWN, _, :process, conn_pid, reason}, %State{conn_pid: conn_pid} = state) do
    status =
      case reason do
        :shutdown ->
          Logger.info("WS connection with #{state.api} went down normally.")
          {:disconnected, :normal}

        _ ->
          :ok =
            Instrumenter.execute(
              :ws_down,
              %{time: DateTime.utc_now()},
              %{node: Node.self()}
            )

          Logger.warning("WS connection with #{state.api} went down: #{inspect(reason)}")
          {:disconnected, reason}
      end

    {:stop, status, state}
  end

  def handle_info(message, %State{} = state) do
    Logger.debug(fn -> "Unexpected message: #{inspect(message)} on state: #{inspect(state)}" end)
    {:noreply, state}
  end

  ## Helper functions

  @spec _connect(State.t(), Keyword.t()) :: State.t()
  defp _connect(%State{} = state, config) do
    host = Keyword.fetch!(config, :host)
    port = Keyword.fetch!(config, :port)

    WS.connect(host, port, config)
    |> case do
      {:ok, conn_pid} ->
        Process.monitor(conn_pid)
        %State{state | status: :connected, conn_pid: conn_pid}

      {:error, error} ->
        Logger.error("Can't connect to graph: #{inspect(error)}")
        state
    end
  end

  defp _ws_upgrade(%State{conn_pid: conn_pid} = state, path, subprotocol, token) do
    Logger.info("Upgrading connection...")
    :ok = WS.ws_upgrade(conn_pid, path, subprotocol, token)
    Logger.info("WebSocket upgrade succeeded.")
    Process.send_after(self(), :check_last_pong, @ping_interval)
    state
  end
end
