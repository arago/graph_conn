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

  @type build_params() :: %{
          optional(:timeout) => nil | pos_integer(),
          :ticket_id => String.t(),
          :handler => String.t(),
          :capability => String.t(),
          :params => map()
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

  @spec new(build_params()) :: t()
  def new(payload) do
    %__MODULE__{
      id: _calculate_id(payload),
      handler: payload.handler,
      capability: payload.capability,
      parameters: payload.params,
      timeout: payload[:timeout] || @default_timeout
    }
  end

  @spec _calculate_id(build_params()) :: String.t()
  def _calculate_id(payload) do
    "#{payload.ticket_id}#{payload.handler}#{payload.capability}#{inspect(payload.params)}"
    |> Murmur.hash_x64_128()
    |> to_string()
  end
end
