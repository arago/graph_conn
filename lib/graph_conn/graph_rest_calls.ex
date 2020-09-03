defmodule GraphConn.GraphRestCalls do
  @moduledoc false

  alias GraphConn.{Request, Response}
  require Logger

  @type versions() :: %{atom() => %{path: String.t(), subprotocol: String.t()}}

  @doc """
  Returns map of API versions connected Graph server supports,
  together with their path and subprotocol (for websocket connections).

  ## Example:

      iex> config = Application.get_env(:graph_conn, GraphConn.TestConn)
      iex> {:ok, _versions} = GraphConn.GraphRestCalls.get_versions(config)
      {:ok,
       %{
         action: %{path: "/api/0.9/action/", protocol: "", subprotocol: "0.9"},
         "action-ws": %{
           path: "/api/0.9/action-ws/",
           protocol: "action-0.9.0",
           subprotocol: "0.9"
         },
         app: %{path: "/api/6.1/app/", protocol: "", subprotocol: "6.1"},
         auth: %{path: "/api/6/auth/", protocol: "", subprotocol: "6"},
         authz: %{path: "/api/6.1/authz/", protocol: "", subprotocol: "6.1"},
         "events-ws": %{
           path: "/api/6.1/events-ws/",
           protocol: "events-1.0.0",
           subprotocol: "6.1"
         },
         graph: %{path: "/api/7.1/graph/", protocol: "", subprotocol: "7.1"},
         "graph-ws": %{
           path: "/api/6.1/graph-ws/",
           protocol: "graph-2.0.0",
           subprotocol: "6.1"
         },
         health: %{path: "/api/7.0/health/", protocol: "", subprotocol: "7.0"},
         help: %{path: "/help/", protocol: "", subprotocol: ""},
         iam: %{path: "/api/6.1/iam/", protocol: "", subprotocol: "6.1"},
         ki: %{path: "/api/6/ki/", protocol: "", subprotocol: "6"},
         logs: %{path: "/api/0.9/logs/", protocol: "", subprotocol: "0.9"},
         variables: %{path: "/api/6/variables/", protocol: "", subprotocol: "6"}
       }}
  """
  @spec get_versions(Keyword.t()) :: {:ok, versions()} | {:error, any()}
  def get_versions(config) do
    Logger.info("Getting supported Graph API versions...")

    request = %Request{path: "/api/version"}

    with {:ok, graph_versions} <- _get_versions(request, config),
         {:ok, auth_versions} <- _get_versions(request, config[:auth]) do
      auth_versions = Map.take(auth_versions, [:auth])

      {:ok, Map.merge(graph_versions, auth_versions)}
    end
  end

  @spec _get_versions(Request.t(), Keyword.t()) :: {:ok, versions()} | {:error, any()}
  defp _get_versions(%Request{} = request, config) do
    request
    |> _shoot(config)
    |> case do
      %MachineGun.Response{status_code: 200, body: body} ->
        versions =
          body
          |> Jason.decode!()
          |> Enum.map(fn {key,
                          %{"endpoint" => endpoint, "protocols" => protocol, "version" => version}} ->
            {String.to_atom(key), %{path: endpoint, protocol: protocol, subprotocol: version}}
          end)
          |> Enum.into(%{})

        {:ok, versions}

      other ->
        {:error, other}
    end
  end

  @doc """
  Gets token for given `config`.

  - `expires_at` in response is unix time in milliseconds.
  """
  @spec authenticate(Keyword.t(), %{auth: %{path: String.t()}}) ::
          {:ok, %{token: String.t(), expires_at: pos_integer()}} | {:error, any()}
  def authenticate(config, %{auth: %{path: auth_namespace}}) do
    Logger.info("Authenticating...")

    body =
      config
      |> Keyword.fetch!(:auth)
      |> Keyword.fetch!(:credentials)
      |> Enum.into(%{})
      |> Jason.encode!()

    %Request{method: :post, path: auth_namespace <> "app", body: body}
    |> _shoot(config)
    |> case do
      %MachineGun.Response{status_code: 200, body: body} ->
        Logger.info("Successfully authenticated.")
        %{"_TOKEN" => token, "expires-at" => expires_at} = Jason.decode!(body)

        {:ok, %{token: token, expires_at: expires_at}}

      %MachineGun.Response{body: body} = response ->
        error =
          case Jason.decode(body) do
            {:ok, map} -> map
            {:error, _} -> response
          end

        Logger.error("Authentication error: #{inspect(error)}")
        {:error, error}

      %MachineGun.Error{reason: reason} ->
        Logger.error("Authentication error: #{inspect(reason)}")
        {:error, reason}
    end
  end

  def execute(base_name, target_api, request, opts \\ []) do
    with {:ok, %{path: namespace}} <- _get_version(base_name, target_api) do
      [{:config, config}] = :ets.lookup(base_name, :config)

      token =
        case :ets.lookup(base_name, :token) do
          [{:token, token}] -> token
          [] -> nil
        end

      request
      |> _inject_namespace(namespace)
      |> _inject_token(token)
      |> _execute(config, opts)
    end
  end

  defp _execute(request, config, opts, attempt \\ 1) do
    response =
      request
      |> _shoot(config, opts)
      |> _process_response()

    case {response, attempt} do
      {{:retry, _}, attempt} when attempt < 6 ->
        Process.sleep(1_000)
        Logger.info("[GraphRestCalls] Retrying request...")
        _execute(request, config, opts, attempt + 1)

      {{:retry, error}, _attempt} ->
        error

      {other, _attempt} ->
        other
    end
  end

  defp _get_version(_base_name, :base), do: {:ok, %{path: ""}}

  defp _get_version(base_name, target_api) do
    [{:versions, versions}] = :ets.lookup(base_name, :versions)

    case Map.get(versions, target_api) do
      nil -> {:error, {:unknown_api, Map.keys(versions)}}
      version -> {:ok, version}
    end
  end

  @spec _inject_namespace(Request.t(), String.t()) :: Request.t()
  defp _inject_namespace(%Request{path: path} = request, namespace),
    do: %Request{request | path: namespace <> path}

  @spec _inject_token(Request.t(), nil | String.t()) :: Request.t()
  defp _inject_token(%Request{} = request, nil),
    do: request

  defp _inject_token(%Request{headers: headers} = request, token),
    do: %Request{request | headers: Map.put(headers, "Authorization", "Bearer " <> token)}

  defp _shoot(%Request{} = request, config, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, 5_000)

    uri = _build_uri(request, config)

    body =
      case request.body do
        %{} -> Jason.encode!(request.body)
        nil -> ""
        _ -> request.body
      end

    headers = _convert_headers(request.headers, body)

    Logger.debug(fn ->
      "[GraphRestCaller] Sending #{String.upcase(to_string(request.method))}: #{uri}"
    end)

    {_, response} =
      MachineGun.request(request.method, uri, body, headers, %{
        request_timeout: timeout,
        pool_group: :graph_conn
      })

    response
  end

  defp _build_uri(%Request{path: path, query_params: query}, config) do
    transport = if config[:transport] == :tcp, do: "http", else: "https"
    "#{transport}://#{config[:host]}:#{config[:port]}#{path}?#{URI.encode_query(query)}"
  end

  @spec _convert_headers(map(), nil | String.t()) :: [{String.t(), charlist()}]
  defp _convert_headers(headers, body) do
    json = 'application/json'

    headers =
      Enum.map(headers, fn {name, value} ->
        key = name |> to_string() |> String.downcase()
        val = value |> to_charlist()
        {key, val}
      end)

    if body && byte_size(body) > 0 do
      [{"accept", json}, {"content-type", json}, {"content-length", byte_size(body)} | headers]
    else
      [{"accept", json} | headers]
    end
  end

  defp _process_response(%MachineGun.Response{body: body} = response) do
    machine_gun_resp =
      case Jason.decode(body) do
        {:ok, result} -> %{response | body: result}
        _ -> response
      end

    response = %Response{
      code: machine_gun_resp.status_code,
      body: machine_gun_resp.body,
      headers: machine_gun_resp.headers
    }

    {:ok, response}
  end

  defp _process_response(
         %MachineGun.Error{reason: {:stop, {:goaway, _, _, _}, _} = reason} = response
       ) do
    Logger.warn("[GraphRestCalls] Received GOAWAY: #{inspect(reason)}")
    {:retry, response}
  end

  defp _process_response(error) do
    Logger.error("[GraphRestCalls] Received unhandled REST response: #{inspect(error)}")
    error
  end
end
