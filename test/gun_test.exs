defmodule GraphConn.GunTest do
  use ExUnit.Case, async: true

  @tag :skip
  test "gun ws connection on local phoenix server" do
    # This one works in the moment of writing.
    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 10,
      http_opts: %{keepalive: :infinity},
      http2_opts: %{keepalive: :infinity},
      protocols: [:http]
    }

    host = 'localhost'
    port = 4333
    path = '/socket/websocket/'
    assert {:ok, conn_pid} = :gun.open(host, port, connect_opts)
    assert Process.alive?(conn_pid)
    assert {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))

    stream_ref = :gun.ws_upgrade(conn_pid, path, [], %{})

    assert_receive {:gun_upgrade, ^conn_pid, ^stream_ref, ["websocket"], _response_headers}
    refute_receive _, 2_000
  end

  @tag :skip
  test "on echo.websocket.org server" do
    # This one fails in the moment of writing on :gun.await_up with error:
    # {:error, {:shutdown, :nxdomain}}
    host = 'echo.webscoket.org'
    port = 443
    path = '/'

    connect_opts = %{
      connect_timeout: :timer.minutes(1),
      retry: 10,
      retry_timeout: 10,
      http_opts: %{keepalive: :infinity},
      http2_opts: %{keepalive: :infinity},
      protocols: [:http],
      transport: :tls,
      transport_opts: [
        verify: :verify_peer,
        cacerts: :certifi.cacerts(),
        depth: 99,
        server_name_indication: host,
        reuse_sessions: false,
        verify_fun: {&:ssl_verify_hostname.verify_fun/3, [check_hostname: host]}
      ]
    }

    assert {:ok, conn_pid} = :gun.open(host, port, connect_opts)
    assert Process.alive?(conn_pid)
    assert {:ok, _protocol} = :gun.await_up(conn_pid, :timer.minutes(1))

    stream_ref = :gun.ws_upgrade(conn_pid, path, [], %{})

    assert_receive {:gun_upgrade, ^conn_pid, ^stream_ref, ["websocket"], _response_headers}
    refute_receive _, 2_000
  end

  @tag :skip
  test "on HIRO server" do
    TestConn.start_supervisor(:from_config, %{forward_to: self()})
    assert_receive {:conn_status_changed, :ready}
    api = :"action-ws"

    request = %GraphConn.Request{
      body: %{
        "type" => "submitAction",
        "id" => "123213",
        "handler" => "ck2uexxlp005d5y38e5v8dif0_ck2yte2ro0pzbly38z0arl6vp",
        "capability" => "ck2uexxlp005d5y38e5v8dif0_ck2xh4og0002nly38l3yp72a9",
        "timeout" => 300_000,
        "parameters" => %{
          "command" => "some_command",
          "target" => "http://.."
        }
      }
    }

    # assert {:ok, %GraphConn.Response{body: body} = response} = TestConn.execute(api, request)
    assert :ok = TestConn.execute(api, request)
    assert_receive :wip
    refute_receive _, 2_000
  end
end
