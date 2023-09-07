defmodule ActionInvoker do
  @moduledoc false
  use GraphConn.ActionApi.Invoker

  def execute(capability \\ "ExecuteCommand", params),
    do: execute(UUID.uuid4(), "action_handler", capability, params)
end
