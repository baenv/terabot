defmodule TradingSystemMain.MixProject do
  use Mix.Project

  def project do
    [
      app: :trading_system_main,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {TradingSystemMain.Application, []},
      extra_applications: [
        :logger,
        :runtime_tools,
        :core,
        :portfolio_manager,
        :data_collector,
        :order_manager,
        :decision_engine,
        :data_processor,
        :web_dashboard
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      # Poncho project dependencies
      {:core, path: "../core"},
      {:portfolio_manager, path: "../portfolio_manager"},
      {:data_collector, path: "../data_collector"},
      {:order_manager, path: "../order_manager"},
      {:decision_engine, path: "../decision_engine"},
      {:web_dashboard, path: "../web_dashboard"},
      {:data_processor, path: "../data_processor"},

      # Ethereum dependencies
      {:ethereumex, "~> 0.10.7", override: true},
      {:ex_abi, "~> 0.5.16", override: true},
      {:ex_secp256k1, "~> 0.7.4", override: true},
      {:ex_keccak, "~> 0.7.3", override: true},
      {:rustler, "~> 0.30.0", override: true},

      # Phoenix dependencies
      {:phoenix, "~> 1.7.20", override: true},
      {:phoenix_html, "~> 3.3.4", override: true},
      {:phoenix_live_reload, "~> 1.4.1", override: true},
      {:phoenix_live_view, "~> 0.20.17", override: true},
      {:phoenix_pubsub, "~> 2.1.3", override: true},
      {:floki, ">= 0.37.1", only: :test, override: true},
      {:phoenix_live_dashboard, "~> 0.8.6", override: true},
      {:telemetry_metrics, "~> 0.6.2", override: true},
      {:telemetry_poller, "~> 1.0.0", override: true},
      {:gettext, "~> 0.23.1", override: true},
      {:jason, "~> 1.4.4", override: true},
      {:plug, "~> 1.14.2", override: true},
      {:plug_cowboy, "~> 2.6.2", override: true},
      {:cowboy, "~> 2.9.0", override: true},
      {:cowlib, "~> 2.11.0", override: true},
      {:ranch, "~> 1.8.0", override: true},
      {:statistics, "~> 0.6.3", override: true},
      {:telemetry, "~> 1.2.1", override: true},
      {:decimal, "~> 2.1.1", override: true},
      {:websockex, "~> 0.4.3", override: true},
      {:finch, "~> 0.16.0", override: true},

      # ML dependencies
      {:nx, "~> 0.6.4", override: true},
      {:complex, "~> 0.6.0", override: true},

      # HTTP client
      {:httpoison, "~> 2.2.2", override: true},

      # Additional dependencies needed by other modules
      {:rustler_precompiled, "~> 0.8.2", override: true},
      {:nimble_options, "~> 1.1.1", override: true},
      {:nimble_pool, "~> 1.1.0", override: true},
      {:hackney, "~> 1.23.0", override: true},
      {:unicode_util_compat, "~> 0.7.0", override: true},
      {:certifi, "~> 2.14.0", override: true},
      {:parse_trans, "~> 3.4.1", override: true},
      {:castore, "~> 1.0.12", override: true},
      {:mint, "~> 1.7.1", override: true},
      {:mime, "~> 2.0.6", override: true},
      {:db_connection, "~> 2.7.0", override: true},
      {:ecto, "~> 3.10.3", override: true},

      # Testing
      {:mox, "~> 1.1.0", only: :test, override: true}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get"]
    ]
  end
end
