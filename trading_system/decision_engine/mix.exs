defmodule DecisionEngine.MixProject do
  use Mix.Project

  def project do
    [
      app: :decision_engine,
      version: "0.1.0",
      elixir: "~> 1.14",
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
      {:core, path: "../core", override: true},
      {:data_processor, path: "../data_processor", override: true},
      {:nx, github: "elixir-nx/nx", tag: "v0.6.2", override: true},
      {:scholar, github: "elixir-nx/scholar", tag: "v0.2.1", override: true}
    ]
  end
end
