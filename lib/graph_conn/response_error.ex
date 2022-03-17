defmodule GraphConn.ResponseError do
  @moduledoc """
  `reason` and `error` are mutualy exclusive. If http client error had `reason` in response,
  it will be copied here, otherwise whole error struct will be copied to `error` field.
  """

  @type t() :: %__MODULE__{
          reason: nil | String.t(),
          error: nil | any()
        }

  defstruct ~w(reason error)a
end
