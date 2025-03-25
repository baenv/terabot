defmodule DataProcessor.MixProject do
  use Mix.Project

  def project do
    [
      app: :data_processor,
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
      mod: {DataProcessor.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:core, in_umbrella: true},
      {:statistics, "~> 0.6.2"},
      {:tai, "~> 0.0.62"},
      {:flow, "~> 1.2"}
    ]
  end
end
