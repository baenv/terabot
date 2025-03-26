defmodule DataProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_processor,
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
      mod: {DataProcessor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, path: "../core"},
      {:statistics, github: "msharp/elixir-statistics", override: true},
      {:flow, github: "dashbitco/flow", tag: "v1.2.4", override: true}
    ]
  end
end
