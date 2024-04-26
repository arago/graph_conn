defmodule GraphConn.Response do
  @type t() :: %__MODULE__{
          code: pos_integer(),
          headers: GraphConn.headers(),
          body: nil | String.t() | map()
        }

  @enforce_keys ~w(code headers)a
  defstruct @enforce_keys ++ ~w(body)a
end
