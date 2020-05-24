defmodule GraphConn.MockTest do
  use ExUnit.Case, async: true
  alias GraphConn.Mock

  describe "capabilities" do
    test "returns default capabilities from config" do
      assert Application.get_env(:graph_conn, :mock)[:capabilities] == Mock.get_capabilities()
      assert Enum.count(Mock.get_capabilities()) > 0
    end

    test "returns default and added capabilities" do
      new_capabilities = %{"on_condition_test" => %{}}
      assert :ok = Mock.put_capabilities(new_capabilities)
      assert %{"on_condition_test" => %{}} = Mock.get_capabilities()
      assert Enum.count(Mock.get_capabilities()) > 1
    end
  end

  describe "applicabilities" do
    test "returns default applicabilities from config" do
      assert %{"action_handler" => %{}} == Mock.get_applicabilities()
    end

    test "returns default and added applicabilities for action_handler" do
      new_applicabilities = %{"on_condition_test" => %{}}
      assert :ok = Mock.put_applicabilities("action_handler", new_applicabilities)
      assert %{"action_handler" => %{"on_condition_test" => %{}}} == Mock.get_applicabilities()
    end
  end
end
