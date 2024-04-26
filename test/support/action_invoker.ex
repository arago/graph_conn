defmodule ActionInvoker do
  @moduledoc false
  use GraphConn.ActionApi.Invoker

  def execute(req_id \\ UUID.uuid4(), capability \\ "ExecuteCommand", params),
    do: execute(req_id, "action_handler", capability, params)
end
