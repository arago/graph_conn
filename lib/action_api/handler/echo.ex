defmodule GraphConn.ActionApi.Handler.Echo do
  @spec execute(params :: map()) ::
          :ok
          | {:ok, any()}
          | {:error, {exit_code :: non_neg_integer(), response :: any()}}
          | {:error, any()}

  def execute(%{"return_error" => error}),
    do: {:error, error}

  def execute(%{"sleep" => sleep} = params) do
    Process.sleep(sleep)
    {:ok, params}
  end

  def execute(%{} = params),
    do: {:ok, params}
end
