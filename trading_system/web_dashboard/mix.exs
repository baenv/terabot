defmodule WebDashboard.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_dashboard,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  def application do
    [
      mod: {WebDashboard.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  defp deps do
    [
      # Internal dependencies
      {:core, path: "../core"},

      # Framework
      {:phoenix, "~> 1.7.10"},
      {:phoenix_html, "~> 3.3.3"},
      {:phoenix_live_reload, "~> 1.4.1", only: :dev},
      {:phoenix_live_view, "~> 0.20.1"},
      {:phoenix_pubsub, git: "https://github.com/phoenixframework/phoenix_pubsub.git", tag: "v2.1.3", override: true},

      # Telemetry
      {:telemetry_metrics, "~> 0.6.2"},
      {:telemetry_poller, "~> 1.0.0"},
      {:telemetry, git: "https://github.com/beam-telemetry/telemetry.git", tag: "v1.2.1", override: true},

      # Utilities
      {:number, "~> 1.0"},

      # Backend
      {:plug_cowboy, "~> 2.7.0"},
      {:jason, git: "https://github.com/michalmuskala/jason.git", tag: "v1.4.1", override: true},
      {:gettext, "~> 0.23.1"},

      # Assets
      {:esbuild, "~> 0.9.0", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.3.1", runtime: Mix.env() == :dev}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  defp aliases do
    [
      setup: ["deps.get", "assets.deploy"],
      "assets.deploy": ["tailwind default --minify", "esbuild default --minify", "phx.digest"]
    ]
  end
end
