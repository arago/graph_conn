defmodule ActionInvoker do
  @moduledoc false
  use GraphConn.ActionApi.Invoker

  def execute(req_id \\ UUID.uuid4(), capability \\ "ExecuteCommand", params),
    do: execute(req_id, "ah_app_id_cls303dzz11yn0150m5qnmlrx", capability, params)
end
