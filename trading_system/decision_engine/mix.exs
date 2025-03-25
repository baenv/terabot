defmodule DecisionEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :decision_engine,
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
      mod: {DecisionEngine.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, path: "../core"},
      {:data_processor, path: "../data_processor"},
      {:nx, "~> 0.6.2"},
      {:scholar, "~> 0.2.1"}
    ]
  end
end
