defmodule PortfolioManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :portfolio_manager,
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
      mod: {PortfolioManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:order_manager, in_umbrella: true},
      {:decimal, "~> 2.1"},
      {:statistics, "~> 0.6.2"}
    ]
  end
end
