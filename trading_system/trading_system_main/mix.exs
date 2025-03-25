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
      extra_applications: [:logger],
      mod: {TradingSystemMain.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:data_collector, in_umbrella: true},
      {:data_processor, in_umbrella: true},
      {:decision_engine, in_umbrella: true},
      {:order_manager, in_umbrella: true},
      {:portfolio_manager, in_umbrella: true},
      
      # No external API dependencies needed - using Erlang's built-in HTTP server
    ]
  end
end
