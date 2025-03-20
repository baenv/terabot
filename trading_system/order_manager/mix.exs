defmodule OrderManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :order_manager,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OrderManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:decision_engine, in_umbrella: true},
      {:ex_binance, "~> 0.0.4"},
      {:decimal, "~> 2.1"}
    ]
  end
end
