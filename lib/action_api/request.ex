defmodule GraphConn.ActionApi.Request do
  @moduledoc !"""
             Structure of request used for invoking action.
             """

  @type t() :: %__MODULE__{
          type: :submitAction,
          id: String.t(),
          handler: String.t(),
          capability: String.t(),
          timeout: pos_integer(),
          parameters: map()
        }

  @derive Jason.Encoder
  @enforce_keys [:id, :handler, :capability, :timeout]
  defstruct type: :submitAction,
            id: nil,
            handler: nil,
            capability: nil,
            parameters: %{},
            timeout: 60_000

  @default_timeout 60_000

  @spec new(%{
          ticket_id: String.t(),
          handler: String.t(),
          capability: String.t(),
          params: map(),
          timeout: nil | pos_integer()
        }) :: t()
  def new(payload) do
    %__MODULE__{
      id: _calculate_id(payload),
      handler: payload.handler,
      capability: payload.capability,
      parameters: payload.params,
      timeout: payload[:timeout] || @default_timeout
    }
  end

  @spec _calculate_id(%{
          ticket_id: String.t(),
          handler: String.t(),
          capability: String.t(),
          params: map()
        }) :: String.t()
  defp _calculate_id(payload) do
    "#{payload.ticket_id}#{payload.handler}#{payload.capability}#{inspect(payload.params)}"
    |> Base.encode64()
  end
end
