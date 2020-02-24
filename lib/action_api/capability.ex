defmodule GraphConn.ActionApi.Capability do
  @moduledoc """
  Capability struct

  * name - name of capability used as an identifier.
  * description - text describing the capability, coming from ogit/description.
  * mandatory_params - is list of mandatory parameter names (json-decoded content of `ogit/Automation/mandatoryParameters`).
  * optional_params - is list of optional parameter names (json-decoded content of `ogit/Automation/optionalParameters`).
  """

  @type t :: %__MODULE__{
          name: String.t(),
          description: String.t(),
          mandatory_params: [String.t()],
          optional_params: [String.t()]
        }

  @enforce_keys ~w(name description mandatory_params optional_params)a
  defstruct @enforce_keys
end
