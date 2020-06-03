defmodule GraphConn.ActionApi.HandlerTest do
  use ExUnit.Case, async: true

  describe "status/0" do
    test "is :ready when ws connection is established" do
      assert :ready = TestActionHandler.status()
    end
  end
end
