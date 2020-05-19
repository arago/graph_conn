ExUnit.start(exclude: [:skip, :integration], assert_receive_timeout: 5_000)

{:ok, _pid} =
  :graph_conn
  |> Application.get_env(ActionHandler)
  |> TestActionHandler.start_link()

{:ok, _pid} =
  :graph_conn
  |> Application.get_env(GraphConn.Mock.Conn)
  |> ActionInvoker.start_link()

Process.sleep(1900)
