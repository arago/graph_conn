defmodule GraphConn.MixProject do
  use Mix.Project

  def project do
    [
      app: :graph_conn,
      version: "1.0.0",
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
      dialyzer: [
        plt_add_apps: [:mix, :certifi]
      ],
      name: "GraphConn",
      docs: _docs(),
      deps: _deps(),
      build_path: "../../_build",
      deps_path: "../../deps",
      lockfile: "../../mix.lock",
      elixirc_paths: _elixirc_paths(Mix.env())
    ]
  end

  def application do
    # on local machine, when switching between integration and mock tests, you need to `touch mix.exs` first:
    #  $> touch mix.exs && INTEGRATION_TESTS=true mix test
    [
      extra_applications: [:logger, :ssl, :certifi]
    ] ++ _application(Mix.env() == :test && System.get_env("INTEGRATION_TESTS") != "true")
  end

  defp _application(true), do: [mod: {GraphConn.Mock.Application, []}]
  defp _application(false), do: []

  defp _deps do
    [
      {:elixir_uuid, "~> 1.2"},
      {:machine_gun, "~> 0.1.6"},
      {:gun, "~> 1.3.1"},
      {:ssl_verify_fun, "~> 1.1"},
      {:jason, "~> 1.1"},
      ## needed for action handlers only
      {:con_cache, "~> 0.14"},
      {:cowlib, "~> 2.8.0", override: true},

      # test dependencies
      {:dialyxir, "~> 1.0.0", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.21", runtime: false},
      {:excoveralls, "~> 0.12", runtime: false},
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
