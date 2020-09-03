import Config

import_config_if_exists = fn file_name ->
  __ENV__.file
  |> Path.dirname()
  |> Path.join(file_name)
  |> File.exists?()
  |> if do
    import_config(file_name)
  end
end

config :logger, :console,
  format: "$date $time $metadata[$level] $message\n",
  level: :debug,
  metadata: [:req_id, :pid]

config :machine_gun,
  graph_conn: %{
    # Poolboy size
    pool_size: 10,
    # Poolboy max_overflow
    pool_max_overflow: 5,
    pool_timeout: 1000
  }

import_config_if_exists.("#{Mix.env()}.exs")
import_config_if_exists.("git_ignored.exs")
