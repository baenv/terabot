defmodule TradingSystemMain.MixProject do
  use Mix.Project

  def project do
    [
      app: :trading_system_main,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :core,
        :data_collector,
        :data_processor,
        :decision_engine,
        :order_manager,
        :portfolio_manager
      ],
      mod: {TradingSystemMain.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, path: "../core"},
      {:data_collector, path: "../data_collector"},
      {:data_processor, path: "../data_processor"},
      {:decision_engine, path: "../decision_engine"},
      {:order_manager, path: "../order_manager"},
      {:portfolio_manager, path: "../portfolio_manager"},
      
      # HTTP server dependencies
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"}
    ]
  end
end
