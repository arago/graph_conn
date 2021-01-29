defmodule GraphConn.ActionApi.RequestTest do
  use ExUnit.Case, async: true
  alias GraphConn.ActionApi

  describe "request id calculation is deterministic" do
    test "request_id is the same for the same ticket_id, handler, capability and params" do
      ticket_id = UUID.uuid4()
      handler = UUID.uuid4()
      capability = UUID.uuid4()
      params = %{"other_handler" => "Echo", "command" => "ls"}

      %ActionApi.Request{id: request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      %ActionApi.Request{id: ^request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })
    end

    test "request_id is different if ticket_id is different" do
      ticket_id = UUID.uuid4()
      handler = UUID.uuid4()
      capability = UUID.uuid4()
      params = %{"other_handler" => "Echo", "command" => "ls"}

      %ActionApi.Request{id: request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      ticket_id = UUID.uuid4()

      %ActionApi.Request{id: request_id2} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      refute request_id == request_id2
    end

    test "request_id is different for different handler" do
      ticket_id = UUID.uuid4()
      handler = UUID.uuid4()
      capability = UUID.uuid4()
      params = %{"other_handler" => "Echo", "command" => "ls"}

      %ActionApi.Request{id: request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      handler = UUID.uuid4()

      %ActionApi.Request{id: request_id2} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      refute request_id == request_id2
    end

    test "request_id is different for different capability" do
      ticket_id = UUID.uuid4()
      handler = UUID.uuid4()
      capability = UUID.uuid4()
      params = %{"other_handler" => "Echo", "command" => "ls"}

      %ActionApi.Request{id: request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      capability = UUID.uuid4()

      %ActionApi.Request{id: request_id2} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      refute request_id == request_id2
    end

    test "request_id is different for different params" do
      ticket_id = UUID.uuid4()
      handler = UUID.uuid4()
      capability = UUID.uuid4()
      params = %{"other_handler" => "Echo", "command" => "ls"}

      %ActionApi.Request{id: request_id} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      params = %{"other_handler" => "Echo", "command" => "ls -l"}

      %ActionApi.Request{id: request_id2} =
        ActionApi.Request.new(%{
          ticket_id: ticket_id,
          handler: handler,
          capability: capability,
          params: params,
          timeout: 5_000
        })

      refute request_id == request_id2
    end
  end
end
