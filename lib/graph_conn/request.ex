defmodule GraphConn.Request do
  @moduledoc """
  Structure of request used as a parameter in MyConn.execute/3.
  """

  @type t() :: %__MODULE__{
          method: :get | :post | :put | :patch | :head | :options,
          headers: map(),
          path: String.t(),
          query_params: map(),
          body: nil | map() | String.t()
        }

  defstruct method: :get, path: "", query_params: %{}, body: nil, headers: %{}
end
