defmodule GraphConn.ActionApi do
  @typedoc """
  Execution error explanation:

  - `not_found` - Requested action_handler_id and capability_name is
    not found as valid combination for this client.
  - `{:ack_timeout, timeout}` - Graph didn't receive message in specified `timeout`.
  - `{:exec_timeout, timeout}` - Graph didn't respond in specified `timeout`.
  """
  @type execution_error() ::
          :not_found
          | {:ack_timeout, timeout :: pos_integer()}
          | {:exec_timeout, timeout :: pos_integer()}
          | {:nack, error :: term()}
end
