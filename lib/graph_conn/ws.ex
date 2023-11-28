defmodule GraphConn.WS do
  @moduledoc false

  # :gun wrapper for making connection, ws_upgrade and pushing ws message.
  # Functions from this module are used in WsConnection only.

  alias GraphConn.{Response, Tools, Instrumenter}
  require Logger

  @doc """
  Opens connection for given `host` @ given `port`.

  ## Options:
  - `connect_timeout`: :infinity or number of ms to wait for connection to be established.
    Defaults to 1 minute.
  - `timeout`: :infinity or a number to keep connection alive.
  - `retry`: number of retries before giving up.
  - `retry_timeout`: time to wait for retrying.
  - `protocols`: defaults to `[:http2, :http]`. Note that `http2` can't be upgraded to websocket!
  """
  @spec connect(String.t() | charlist(), String.t() | pos_integer(), Keyword.t()) ::
          {:ok, pid()} | {:error, any()}
  def connect(host, port, opts \\ []) do
    host = to_charlist(host)
    port = Tools.to_integer(port)
    connect_opts = _connect_opts(opts, host)

    case _proxy_config() do
      nil ->
        _connect(host, port, connect_opts)

      proxy_config ->
        connect_opts = Map.merge(connect_opts, %{host: host, port: port}) |> Enum.into([])
        _proxy_connect(proxy_config, connect_opts)
    end
  end

  defp _proxy_config do
    :graph_conn
    |> Application.get_env(:proxy)
    |> case do
      nil ->
        nil

      proxy_config ->
        address = Keyword.fetch!(proxy_config, :address) |> String.to_charlist()
        transport = Keyword.get(proxy_config, :transport, "tcp") |> String.to_atom()
        secure? = Keyword.get(proxy_config, :insecure, "false") == "false"

        tls_opts =
          if transport == :tls && secure?,
            do: _transport_opts(address),
            else: [verify: :verify_none]

        [
          address: address,
          port: Keyword.fetch!(proxy_config, :port) |> Tools.to_integer(),
          protocols: [:http],
          trace: false,
          transport: transport,
          tls_opts: tls_opts
        ]
        |> Enum.into(%{})
    end
  end

  defp _connect(host, port, connect_opts) do
    Logger.info("[GraphConn.WS] Connecting to #{host}:#{port} ...")

    with {:ok, conn_pid} <- :gun.open(host, port, connect_opts),
         {:ok, protocol} <- :gun.await_up(conn_pid, :timer.minutes(1)) do
      Logger.info("[GraphConn.WS] Connected to #{host} using #{protocol}")
      {:ok, conn_pid}
    end
  end

  defp _proxy_connect(proxy_config, connect_opts) do
    connect_opts = Enum.into(connect_opts, %{})

    Logger.info(
      "[GraphConn.WS] Connecting to #{connect_opts[:host]}:#{connect_opts[:port]} via proxy #{proxy_config.address}:#{proxy_config.port} ..."
    )

    {address, proxy_config} = Map.pop(proxy_config, :address)
    {port, proxy_config} = Map.pop(proxy_config, :port)

    with {:ok, conn_pid} <- :gun.open(address, port, proxy_config),
         {:ok, :http} <- :gun.await_up(conn_pid, :timer.minutes(1)),
         conn_ref <- :gun.connect(conn_pid, connect_opts),
         {:response, :fin, 200, _} <- :gun.await(conn_pid, conn_ref) do
      Logger.info("[GraphConn.WS] Connected to #{connect_opts[:host]} via proxy")

      {:ok, conn_pid}
    end
  end

  @spec ws_upgrade(pid(), String.t(), String.t(), String.t()) :: :ok | {:error, any()}
  def ws_upgrade(conn_pid, path, subprotocol, token) do
    mono_start = System.monotonic_time()

    stream_ref =
      :gun.ws_upgrade(
        conn_pid,
        path,
        [],
        %{
          silence_pings: false,
          protocols: [{subprotocol, :gun_ws_h}, {"token-#{token}", :gun_ws_h}]
        }
      )

    response = _async_response(conn_pid, stream_ref)
    success? = response == :ok

    Instrumenter.execute(
      :ws_upgrade,
      %{time: DateTime.utc_now(), duration: Instrumenter.duration(mono_start)},
      %{node: Node.self(), success: success?}
    )

    response
  end

  @spec push(pid(), String.t()) :: :ok
  def push(conn_pid, body) do
    Logger.debug(fn -> "[GraphConn.WS] Pushing #{inspect(body)}" end)
    mono_start = System.monotonic_time()
    :ok = :gun.ws_send(conn_pid, {:text, body})

    :ok =
      Instrumenter.execute(
        :ws_sent_bytes,
        %{
          time: DateTime.utc_now(),
          duration: Instrumenter.duration(mono_start),
          bytes: byte_size(body)
        },
        %{node: Node.self()}
      )
  end

  @spec _async_response(pid(), reference()) :: Response.t() | :ok | {:error, any()}
  defp _async_response(conn_pid, stream_ref) do
    Logger.debug("Waiting for response")

    receive do
      {:gun_response, ^conn_pid, ^stream_ref, :fin, code, headers} ->
        %Response{code: code, headers: headers}

      {:gun_response, ^conn_pid, ^stream_ref, :nofin, code, headers} ->
        case _receive_data(conn_pid, stream_ref) do
          {:ok, data} ->
            %Response{code: code, body: data, headers: headers}

          {:error, reason} ->
            {:error, reason}
        end

      {:gun_upgrade, ^conn_pid, ^stream_ref, ["websocket"], _response_headers} ->
        :ok

      {:gun_error, ^conn_pid, ^stream_ref, reason} ->
        {:error, reason}

      {:gun_error, ^conn_pid, error} ->
        {:error, error}

      {:gun_down, ^conn_pid, _protocol, _reason, _killed_streams, _unprocessed_streams} ->
        {:error, :gun_down}

      {:DOWN, _monitor_ref, :process, ^conn_pid, reason} ->
        {:error, reason}
    after
      5_000 ->
        {:error, :recv_timeout}
    end
  end

  @spec _receive_data(pid(), reference(), binary()) ::
          {:ok, binary()} | {:error, any()}
  defp _receive_data(conn_pid, stream_ref, response_data \\ "") do
    Logger.debug("Waiting for data")

    receive do
      {:gun_data, ^conn_pid, ^stream_ref, :fin, data} ->
        {:ok, response_data <> data}

      {:gun_data, ^conn_pid, ^stream_ref, :nofin, data} ->
        _receive_data(conn_pid, stream_ref, response_data <> data)

      {:gun_down, ^conn_pid, _protocol, reason, _killed_streams, _unprocessed_streams} ->
        {:error, reason}

      {:DOWN, _monitor_ref, :process, ^conn_pid, reason} ->
        {:error, reason}
    after
      :timer.minutes(5) ->
        {:error, :recv_timeout}
    end
  end

  @spec _connect_opts(Keyword.t(), charlist()) :: %{atom() => any}
  defp _connect_opts(opts, host) do
    connect_opts = %{
      connect_timeout: Keyword.get(opts, :connect_timeout, :timer.minutes(1)),
      retry: Keyword.get(opts, :retry, 10),
      retry_timeout: Keyword.get(opts, :retry_timeout, 100),
      http_opts: %{keepalive: Keyword.get(opts, :keepalive, :infinity)},
      http2_opts: %{keepalive: Keyword.get(opts, :keepalive, :infinity)},
      protocols: opts[:protocols] || [:http, :http2],
      transport: Keyword.get(opts, :transport, :tls)
    }

    case !!opts[:insecure] do
      true ->
        Map.put(connect_opts, :tls_opts, verify: :verify_none)

      false ->
        Map.put(connect_opts, :tls_opts, _transport_opts(host))
    end
  end

  @spec _transport_opts(charlist()) :: Keyword.t()
  defp _transport_opts(host) do
    [
      verify: :verify_peer,
      depth: 10,
      cacertfile: :certifi.cacertfile(),
      server_name_indication: host,
      verify_fun: {&:ssl_verify_hostname.verify_fun/3, [check_hostname: host]},
      customize_hostname_check: [
        match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
      ]
    ]
  end
end
