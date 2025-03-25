defmodule Core.MixProject do
  use Mix.Project

  def project do
    [
      app: :core,
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
      mod: {Core.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, github: "michalmuskala/jason", tag: "v1.4.1"},
      {:finch, github: "sneako/finch", tag: "v0.16.0"},
      {:telemetry, github: "beam-telemetry/telemetry", tag: "v1.2.1"},
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", tag: "v2.1.3"},
      {:ecto_sql, github: "elixir-ecto/ecto_sql", tag: "v3.10.2", override: true},
      {:postgrex, github: "elixir-ecto/postgrex", tag: "v0.17.4", override: true},
      {:dotenvy, github: "fireproofsocks/dotenvy", tag: "v0.8.0"}
    ]
  end
end
