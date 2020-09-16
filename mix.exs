defmodule GraphConn.MixProject do
  use Mix.Project

  def project do
    [
      app: :graph_conn,
      version: "1.0.1",
      elixir: "~> 1.9",
      start_permanent: true,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        dialyzer: :test,
        docs: :test,
        bless: :test
      ],
      # dialyzer: [
      #  plt_add_deps: :apps_direct,
      #  plt_add_apps: [:mix, :ex_unit, :gun]
      # ],
      name: "GraphConn",
      docs: _docs(),
      deps: _deps(),
      elixirc_paths: _elixirc_paths(Mix.env())
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :certifi]
    ]
  end

  defp _deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:machine_gun, "~> 0.1.6"},
      # {:gun, "~> 1.3.3"},
      {:gun, github: "ninenines/gun", tag: "2.0.0-pre.2", override: true},
      {:ssl_verify_fun, "~> 1.1"},
      {:jason, "~> 1.1"},
      ## needed for action handlers only
      {:con_cache, "~> 0.14"},
      {:cowlib, "~> 2.8.0", override: true},

      # test dependencies
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.12", only: [:dev, :test], runtime: false},
      {:plug_cowboy, "~> 2.1"}
    ]
  end

  defp _docs do
    [
      output: "doc"
    ]
  end

  defp _elixirc_paths(:test), do: ["lib", "test/support"]
  defp _elixirc_paths(_), do: ["lib"]
end
