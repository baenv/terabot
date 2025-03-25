defmodule DataCollector.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_collector,
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
      mod: {DataCollector.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, path: "../core"},
      {:websockex, "~> 0.4.3"},
      {:ex_binance, "~> 0.0.4"}
    ]
  end
end
