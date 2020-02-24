defmodule GraphConn.ActionApi.Invoker.RequestRegistryTest do
  use ExUnit.Case, async: true
  alias GraphConn.ActionApi.Invoker.RequestRegistry

  setup_all do
    {:ok, _pid} = RequestRegistry.start_link(__MODULE__)
    :ok
  end

  describe ":ack message" do
    test "is received for registered request_id" do
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.ack(__MODULE__, "123")
      assert_receive {:ack, "123"}
    end

    test "doesn't receive ack for message it's not registered with" do
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.ack(__MODULE__, "234")
      refute_receive {:ack, "234"}
    end
  end

  describe ":nack message" do
    test "is received for registered request_id" do
      error = %{"code" => 403, "message" => "forbidden"}
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.nack(__MODULE__, "123", error)
      assert_receive {:nack, "123", ^error}
    end

    test "doesn't receive ack for message it's not registered with" do
      error = %{"code" => 403, "message" => "forbidden"}
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.nack(__MODULE__, "234", error)
      refute_receive {:nack, "234", _error}
    end

    test "is not received twice" do
      error = %{"code" => 403, "message" => "forbidden"}
      :ok = RequestRegistry.register(__MODULE__, "123")

      :ok = RequestRegistry.nack(__MODULE__, "123", error)
      assert_receive {:nack, "123", ^error}

      :ok = RequestRegistry.nack(__MODULE__, "123", error)
      refute_receive {:nack, "123", ^error}
    end
  end

  describe ":response message" do
    test "is received for registered request_id" do
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.respond(__MODULE__, "123", %{a: 1})
      assert_receive {:response, "123", %{a: 1}}
    end

    test "doesn't receive response for message it's not registered with" do
      :ok = RequestRegistry.register(__MODULE__, "123")
      :ok = RequestRegistry.respond(__MODULE__, "234", %{a: 1})
      refute_receive {:response, "234", %{a: 1}}
    end

    test "is not received twice" do
      :ok = RequestRegistry.register(__MODULE__, "123")

      :ok = RequestRegistry.respond(__MODULE__, "123", %{a: 1})
      assert_receive {:response, "123", %{a: 1}}

      :ok = RequestRegistry.respond(__MODULE__, "123", %{a: 1})
      refute_receive {:response, "123", %{a: 1}}
    end
  end
end
