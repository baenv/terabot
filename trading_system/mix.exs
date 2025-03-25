defmodule TradingSystem.MixProject do
  use Mix.Project

  def project do
    [
      app: :trading_system,
      name: :trading_system,
      version: "0.1.0",
      build_path: "_build",
      config_path: "config/config.exs",
      deps_path: "deps",
      lockfile: "mix.lock",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  def application do
    [
      mod: {TradingSystem.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  defp deps do
    [
      {:core, path: "./core"},
      {:data_collector, path: "./data_collector"},
      {:data_processor, path: "./data_processor"},
      {:decision_engine, path: "./decision_engine"},
      {:order_manager, path: "./order_manager"},
      {:portfolio_manager, path: "./portfolio_manager"},
      {:trading_system_main, path: "./trading_system_main"},
      {:dotenvy, github: "fireproofsocks/dotenvy", tag: "v0.8.0", override: true},
      {:plug, github: "elixir-plug/plug", tag: "v1.14.2", override: true},
      {:plug_cowboy, github: "elixir-plug/plug_cowboy", tag: "v2.6.1", override: true},
      {:jason, github: "michalmuskala/jason", tag: "v1.4.1", override: true},
      {:telemetry, github: "beam-telemetry/telemetry", tag: "v1.2.1", override: true},
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", tag: "v2.1.3", override: true},
      {:cowboy, github: "ninenines/cowboy", tag: "2.10.0", override: true},
      {:cowboy_telemetry,
       github: "beam-telemetry/cowboy_telemetry", tag: "v0.4.0", override: true},
      {:mime, github: "elixir-plug/mime", tag: "v2.0.5", override: true},
      {:statistics, github: "msharp/elixir-statistics", override: true},
      {:httpoison, github: "edgurgel/httpoison", tag: "v2.2.1", override: true},
      {:ranch, github: "ninenines/ranch", tag: "2.1.0", override: true},
      {:hackney, github: "benoitc/hackney", tag: "1.19.1", override: true},
      {:metrics, github: "benoitc/erlang-metrics", override: true},
      {:ssl_verify_fun, github: "deadtrickster/ssl_verify_fun.erl", tag: "1.1.7", override: true},
      {:parse_trans, github: "uwiger/parse_trans", tag: "3.4.1", override: true},
      {:mimerl, github: "benoitc/mimerl", tag: "1.2.0", override: true},
      {:certifi, github: "certifi/erlang-certifi", tag: "2.9.0", override: true},
      {:idna, github: "benoitc/erlang-idna", tag: "6.1.1", override: true},
      {:unicode_util_compat, github: "benoitc/unicode_util_compat", tag: "0.7.0", override: true},
      {:decimal, github: "ericmj/decimal", tag: "v2.1.1", override: true},
      {:ex_binance, github: "fremantle-industries/ex_binance", tag: "v0.0.5", override: true},
      {:websockex, github: "Azolo/websockex", tag: "v0.4.3", override: true},
      {:exconstructor, github: "appcues/exconstructor", tag: "1.2.4", override: true},
      {:db_connection, github: "elixir-ecto/db_connection", tag: "v2.5.0", override: true},
      {:flow, github: "dashbitco/flow", tag: "v1.2.4", override: true},
      {:nx, github: "elixir-nx/nx", tag: "v0.6.2", override: true},
      {:castore, github: "elixir-mint/castore", tag: "v1.0.3", override: true},
      {:mint, github: "elixir-mint/mint", tag: "v1.5.1", override: true},
      {:plug_crypto, github: "elixir-plug/plug_crypto", tag: "v1.2.5", override: true},
      {:ecto, github: "elixir-ecto/ecto", tag: "v3.10.3", override: true},
      {:websocket_client, github: "jeremyong/websocket_client", override: true},
      {:scholar, github: "elixir-nx/scholar", tag: "v0.2.1", override: true},
      {:nimble_options, github: "dashbitco/nimble_options", tag: "v1.1.1", override: true},
      {:nimble_pool, github: "dashbitco/nimble_pool", tag: "v1.1.0", override: true},
      {:polaris, github: "elixir-nx/polaris", tag: "v0.1.0", override: true},
      {:hpax, github: "elixir-mint/hpax", tag: "v0.1.2", override: true},
      {:gen_stage, github: "elixir-lang/gen_stage", tag: "v1.2.1", override: true}
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "compile"],
      test: ["test"],
      "test.all": ["cmd mix test --include integration"]
    ]
  end
end
