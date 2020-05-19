defmodule GraphConn.GraphRestCallsTest do
  use ExUnit.Case, async: true
  import GraphConn.GraphRestCalls
  alias GraphConn.{ConnectionManager,Mock.Conn}

  # doctest GraphConn.GraphRestCalls

  describe "get_versions/1" do
    test "returns api versions" do
      config =
        :graph_conn
        |> Application.get_env(Conn)
        |> ConnectionManager.parse_urls()

      assert {:ok, %{:"action-ws" => %{path: _, protocol: _, subprotocol: _}}} =
               get_versions(config)
    end
  end

  describe "authenticate/3" do
    test "returns token" do
      config =
        :graph_conn
        |> Application.get_env(Conn)
        |> ConnectionManager.parse_urls()

      {:ok, versions} = get_versions(config)

      assert {:ok, %{token: _, expires_at: _}} = authenticate(config, versions)
    end
  end
end
