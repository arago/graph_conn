defmodule GraphConn.Mock.Conn do
  @moduledoc false

  use GraphConn, otp_app: :graph_conn

  def on_status_change(new_status, %{forward_to: test_pid}) do
    send(test_pid, {:conn_status_changed, new_status})
  end

  def on_status_change(api, new_status, %{forward_to: test_pid}) do
    send(test_pid, {:conn_status_changed, api, new_status})
  end

  def handle_message(from_api, msg, %{forward_to: test_pid}) do
    send(test_pid, {:received_message, from_api, msg})
  end
end
