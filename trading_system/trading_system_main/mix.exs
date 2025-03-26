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
        :data_processor
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
      # Temporarily disabled due to Plug dependency issues
      {:portfolio_manager, path: "../portfolio_manager"},
      {:data_collector, path: "../data_collector"},
      {:order_manager, path: "../order_manager"},
      {:decision_engine, path: "../decision_engine"},
      # Temporarily disabled due to compilation issues
      # {:web_dashboard, path: "../web_dashboard"},
      {:data_processor, path: "../data_processor"},

      # Ethereum dependencies
      {:ethereumex, github: "mana-ethereum/ethereumex", override: true},

      # Phoenix dependencies
      {:phoenix, "~> 1.7.7", override: true},
      {:phoenix_html, "~> 3.3.1", override: true},
      {:phoenix_live_reload, "~> 1.2", override: true},
      {:phoenix_live_view, "~> 0.20.1", override: true},
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", tag: "v2.1.3", override: true},
      {:floki, ">= 0.30.0", only: :test, override: true},
      {:phoenix_live_dashboard, "~> 0.8.2", override: true},
      {:telemetry_metrics, github: "beam-telemetry/telemetry_metrics", tag: "v0.6.1", override: true},
      {:telemetry_poller, github: "beam-telemetry/telemetry_poller", tag: "v1.0.0", override: true},
      {:gettext, "~> 0.20", override: true},
      {:jason, "~> 1.4", override: true},
      {:plug, github: "elixir-plug/plug", tag: "v1.14.2", override: true},
      {:plug_cowboy, github: "elixir-plug/plug_cowboy", tag: "v2.6.1", override: true},
      {:cowboy, "~> 2.9.0", override: true},
      {:cowlib, "~> 2.11.0", override: true},
      {:ranch, "~> 1.8.0", override: true},
      {:statistics, github: "msharp/elixir-statistics", override: true},
      {:telemetry, "~> 1.0", override: true},
      {:decimal, github: "ericmj/decimal", tag: "v2.1.1", override: true},
      {:websockex, github: "Azolo/websockex", tag: "v0.4.3", override: true},
      {:finch, github: "sneako/finch", tag: "v0.16.0", override: true},

      # ML dependencies - use hex.pm version which should have proper app files
      {:nx, "~> 0.6.1", override: true},

      # HTTP client
      {:httpoison, github: "edgurgel/httpoison", tag: "v2.2.1", override: true}
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
