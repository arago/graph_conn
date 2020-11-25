defmodule GraphConn.Instrumenter do
  @spec execute(atom, map, map) :: :ok
  def execute(name, measurements \\ %{}, data \\ %{}),
    do: :telemetry.execute([:graph_conn, name], measurements, data)

  @spec duration(integer) :: integer
  def duration(mono_start) do
    (System.monotonic_time() - mono_start)
    |> System.convert_time_unit(:native, :millisecond)
  end
end
