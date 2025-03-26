defmodule TradingSystemMain.MixProject do
  use Mix.Project

  def project do
    [
      app: :trading_system_main,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixir_paths: elixir_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {TradingSystemMain.Application, []},
      extra_applications: [:logger, :runtime_tools, :core, :portfolio_manager, :data_collector, :order_manager, :decision_engine, :web_dashboard]
    ]
  end

  defp elixir_paths(:test), do: ["lib", "test/support"]
  defp elixir_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Core dependencies
      {:core, path: "../core"},
      {:portfolio_manager, path: "../portfolio_manager"},
      {:data_collector, path: "../data_collector"},
      {:order_manager, path: "../order_manager"},
      {:decision_engine, path: "../decision_engine"},
      {:web_dashboard, path: "../web_dashboard"},
      {:data_processor, path: "../data_processor"},

      # Phoenix dependencies
      {:phoenix, github: "phoenixframework/phoenix", tag: "v1.7.10", override: true},
      {:phoenix_html, github: "phoenixframework/phoenix_html", tag: "v3.3.2", override: true},
      {:phoenix_live_reload, github: "phoenixframework/phoenix_live_reload", tag: "v1.2.1", override: true},
      {:phoenix_live_view, github: "phoenixframework/phoenix_live_view", tag: "v0.20.1", override: true},
      {:floki, github: "philss/floki", tag: "v0.34.0", override: true},
      {:phoenix_live_dashboard, github: "phoenixframework/phoenix_live_dashboard", tag: "v0.8.2", override: true},
      {:telemetry_metrics, github: "beam-telemetry/telemetry_metrics", tag: "v0.6.1", override: true},
      {:telemetry_poller, github: "beam-telemetry/telemetry_poller", tag: "v1.0.0", override: true},
      {:gettext, github: "elixir-lang/gettext", tag: "v0.23.1", override: true},
      {:jason, github: "michalmuskala/jason", tag: "v1.4.1", override: true},
      {:plug_cowboy, github: "elixir-plug/plug_cowboy", tag: "v2.6.1", override: true},
      {:plug, github: "elixir-plug/plug", tag: "v1.14.2", override: true},
      {:plug_crypto, github: "elixir-plug/plug_crypto", tag: "v1.2.5", override: true},
      {:cowboy, github: "ninenines/cowboy", tag: "2.10.0", override: true},
      {:cowboy_telemetry, github: "beam-telemetry/cowboy_telemetry", tag: "v0.4.0", override: true},
      {:cowlib, github: "ninenines/cowlib", ref: "2.12.1", override: true},
      {:ranch, github: "ninenines/ranch", tag: "2.1.0", override: true},
      {:mime, github: "elixir-plug/mime", tag: "v2.0.5", override: true},
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", tag: "v2.1.3", override: true},

      # Database dependencies
      {:ecto_sql, github: "elixir-ecto/ecto_sql", tag: "v3.10.2", override: true},
      {:ecto, github: "elixir-ecto/ecto", tag: "v3.10.3", override: true},
      {:postgrex, github: "elixir-ecto/postgrex", tag: "v0.17.4", override: true},
      {:db_connection, github: "elixir-ecto/db_connection", tag: "v2.5.0", override: true},

      # HTTP and WebSocket dependencies
      {:httpoison, github: "edgurgel/httpoison", tag: "v2.2.1", override: true},
      {:hackney, github: "benoitc/hackney", tag: "1.19.1", override: true},
      {:certifi, github: "certifi/erlang-certifi", tag: "2.9.0", override: true},
      {:idna, github: "benoitc/erlang-idna", tag: "6.1.1", override: true},
      {:metrics, github: "benoitc/erlang-metrics", override: true},
      {:mimerl, github: "benoitc/mimerl", tag: "1.2.0", override: true},
      {:parse_trans, github: "uwiger/parse_trans", tag: "3.4.1", override: true},
      {:ssl_verify_fun, github: "deadtrickster/ssl_verify_fun.erl", tag: "1.1.7", override: true},
      {:websockex, github: "Azolo/websockex", tag: "v0.4.3", override: true},
      {:ex_binance, github: "fremantle-industries/ex_binance", tag: "v0.0.5", override: true},
      {:exconstructor, github: "appcues/exconstructor", tag: "1.2.4", override: true},

      # Flow and GenStage dependencies
      {:flow, github: "dashbitco/flow", tag: "v1.2.4", override: true},
      {:gen_stage, github: "elixir-lang/gen_stage", tag: "v1.2.1", override: true},

      # NX and Scholar dependencies
      {:nx, github: "elixir-nx/nx", tag: "v0.6.2", override: true},
      {:scholar, github: "elixir-nx/scholar", tag: "v0.2.1", override: true},
      {:polaris, github: "elixir-nx/polaris", tag: "v0.1.0", override: true},

      # Finch and related dependencies
      {:finch, github: "sneako/finch", tag: "v0.16.0", override: true},
      {:castore, github: "elixir-mint/castore", tag: "v1.0.3", override: true},
      {:mint, github: "elixir-mint/mint", tag: "v1.5.1", override: true},
      {:hpax, github: "elixir-mint/hpax", tag: "v0.1.2", override: true},
      {:nimble_pool, github: "dashbitco/nimble_pool", tag: "v1.1.0", override: true},
      {:nimble_options, github: "dashbitco/nimble_options", tag: "v1.1.1", override: true},
      {:telemetry, github: "beam-telemetry/telemetry", tag: "v1.2.1", override: true},
      {:decimal, github: "ericmj/decimal", tag: "v2.1.1", override: true},
      {:unicode_util_compat, github: "benoitc/unicode_util_compat", tag: "0.7.0", override: true},

      # Statistics dependency
      {:statistics, github: "msharp/elixir-statistics", override: true},

      # Ethereum dependencies
      {:ethereumex, github: "mana-ethereum/ethereumex", override: true},
      {:ex_abi, github: "poanetwork/ex_abi", override: true},
      {:ex_secp256k1, github: "omgnetwork/ex_secp256k1", override: true},
      {:rustler_precompiled, github: "philss/rustler_precompiled", tag: "v0.8.0", override: true},

      # Development dependencies
      {:ex_doc, github: "elixir-lang/ex_doc", tag: "v0.31.0", only: :dev, runtime: false, override: true},
      {:makeup_erlang, github: "elixir-makeup/makeup_erlang", tag: "v0.1.1", only: :dev, runtime: false, override: true},
      {:elixir_make, github: "elixir-lang/elixir_make", tag: "v0.7.7", only: :dev, runtime: false, override: true},
      {:deep_merge, github: "PragTob/deep_merge", tag: "1.0.0", only: :dev, runtime: false, override: true},
      {:xla, github: "elixir-nx/xla", tag: "v0.6.0", only: :dev, runtime: false, override: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
