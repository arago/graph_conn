defmodule GraphConn.Mock do
  def get_capabilities do
    Application.get_env(:graph_conn, :mock, [])[:capabilities] || %{}
  end

  def put_capabilities(new_capabilities) when is_map(new_capabilities) do
    capabilities = Map.merge(get_capabilities(), new_capabilities)

    mock =
      Application.get_env(:graph_conn, :mock)
      |> Keyword.put(:capabilities, capabilities)

    Application.put_env(:graph_conn, :mock, mock)
  end

  def get_applicabilities do
    Application.get_env(:graph_conn, :mock, [])[:applicabilities] || %{"action_handler" => %{}}
  end

  @doc """
  Puts `new_applicabilities` for action handler with "action_handler" id.
  """
  def put_applicabilities(ah_id \\ "action_handler", new_applicabilities) when is_map(new_applicabilities) do
    applicabilities = Map.merge(get_applicabilities()[ah_id], new_applicabilities)

    mock =
      Application.get_env(:graph_conn, :mock)
      |> Keyword.put(:applicabilities, %{ah_id => applicabilities})

    Application.put_env(:graph_conn, :mock, mock)
  end
end
