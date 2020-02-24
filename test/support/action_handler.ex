defmodule ActionHandler do
  @moduledoc !"""
             Each execute function is executed in different task process.
             """

  use GraphConn.ActionApi.Handler

  def execute("ExecuteCommand", params) do
    (params["sleep"] || Enum.random(1..5))
    |> Process.sleep()

    case params do
      %{"return_error" => error} ->
        {:error, error}

      _ ->
        {:ok, params}
    end
  end

  @spec default_execution_timeout(String.t()) :: non_neg_integer()
  def default_execution_timeout("ExecuteCommand"),
    do: 10_000

  @spec resend_response_timeout() :: non_neg_integer()
  def resend_response_timeout,
    do: 3_000
end
