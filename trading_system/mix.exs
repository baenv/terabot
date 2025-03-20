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
      extra_applications: [:logger]
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
      {:dotenvy, "~> 0.8.0"}
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
