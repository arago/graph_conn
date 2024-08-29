defmodule GraphConn.Supervisor do
  @moduledoc false
  use Supervisor
  alias GraphConn.Tools

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
      {Finch,
       name: Module.concat(base_name, Finch),
       pools: %{
         default: [{:size, 50}, {:count, 1} | _conn_opts()]
       }},
      {GraphConn.ConnectionManager, [base_name, config]}
    ]
    |> Supervisor.init(strategy: :one_for_all)
  end

  defp _name(base_name), do: Module.concat(base_name, Supervisor)

  defp _conn_opts do
    insecure? = Application.get_env(:graph_conn, :insecure) == true
    proxy = Application.get_env(:graph_conn, :proxy, false)
    ca_cert_file = Application.get_env(:graph_conn, :ca_cert)

    case {insecure?, proxy} do
      {true, false} ->
        transport_opts =
          [verify: :verify_none]
          |> _inject_ca_cert_file(ca_cert_file)

        [conn_opts: [transport_opts: transport_opts]]

      {true, proxy} ->
        transport_opts =
          [verify: :verify_none]
          |> _inject_ca_cert_file(ca_cert_file)

        [conn_opts: [transport_opts: transport_opts, proxy: _proxy_opts(proxy)]]

      {false, false} ->
        transport_opts =
          [verify: :verify_peer]
          |> _inject_ca_cert_file(ca_cert_file)

        [conn_opts: [transport_opts: transport_opts]]

      {false, proxy} ->
        transport_opts =
          [verify: :verify_peer]
          |> _inject_ca_cert_file(ca_cert_file)

        [conn_opts: [transport_opts: transport_opts, proxy: _proxy_opts(proxy)]]
    end
  end

  defp _proxy_opts(config) do
    address = Keyword.fetch!(config, :address)
    port = Keyword.fetch!(config, :port) |> Tools.to_integer()
    opts = Keyword.get(config, :opts, [])

    {:http, address, port, opts}
  end

  defp _inject_ca_cert_file(opts, nil), do: opts
  defp _inject_ca_cert_file(opts, file_path), do: [{:cacerts, file_path} | opts]
end
