defmodule GraphConn.Mock do
  def get_capabilities do
    Application.get_env(:graph_conn, :mock, [])[:capabilities] || %{}
  end

  def put_capabilities(new_capabilities) when is_binary(new_capabilities) do
    capabilities = Map.merge(get_capabilities(), convert_capabilities_from_json(new_capabilities))

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
  def put_applicabilities(ah_id \\ "action_handler", new_applicabilities)
      when is_binary(new_applicabilities) do
    applicabilities =
      Map.merge(
        get_applicabilities()[ah_id],
        convert_applicabilities_from_json(new_applicabilities)
      )

    mock =
      Application.get_env(:graph_conn, :mock)
      |> Keyword.put(:applicabilities, %{ah_id => applicabilities})

    Application.put_env(:graph_conn, :mock, mock)
  end

  @doc false
  def convert_capabilities_from_json(json) do
    json
    |> Jason.decode!()
    |> Enum.map(fn {key, val} ->
      {mandatory_params, optional_params} =
        val
        |> Enum.reduce({%{}, %{}}, fn
          {param_name, nil}, {mandatory_params, optional_params} ->
            {Map.put(mandatory_params, param_name, %{}), optional_params}

          {param_name, default_value}, {mandatory_params, optional_params} ->
            {mandatory_params,
             Map.put(optional_params, param_name, %{"default" => default_value})}
        end)

      {key, %{"mandatoryParameters" => mandatory_params, "optionalParameters" => optional_params}}
    end)
    |> Enum.into(%{})
  end

  @doc false
  def convert_applicabilities_from_json(json) do
    json
    |> Jason.decode!()
    |> Enum.reduce(%{}, fn elem, acc ->
      capability = Map.get(elem, "capability")
      applicability_map = Map.get(elem, "applicability")

      {applicability_name, applicability_value} =
        case Enum.into(applicability_map, []) do
          [{applicability_name, applicability_value}] -> {applicability_name, applicability_value}
          [applicability_name] -> {applicability_name, %{}}
        end

      capability_value =
        acc
        |> Map.get(capability, %{})
        |> Map.put(applicability_name, applicability_value)

      Map.put(acc, capability, capability_value)
    end)
  end
end
