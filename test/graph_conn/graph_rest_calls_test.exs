defmodule GraphConn.GraphRestCallsTest do
  use ExUnit.Case, async: true
  import GraphConn.GraphRestCalls

  # doctest GraphConn.GraphRestCalls

  describe "get_versions/1" do
    test "returns api versions" do
      config = Application.get_env(:graph_conn, TestConn)

      assert {:ok, %{:"action-ws" => %{path: _, protocol: _, subprotocol: _}}} =
               get_versions(config)
    end
  end

  describe "authenticate/3" do
    test "returns token" do
      config = Application.get_env(:graph_conn, TestConn)
      {:ok, versions} = get_versions(config)

      assert {:ok, %{token: _, expires_at: _}} = authenticate(config, versions)
    end
  end
end
