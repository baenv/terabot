defmodule WebDashboard.MixProject do
  use Mix.Project

  def project do
    [
      app: :web_dashboard,
      version: "0.1.0",
      elixir: "~> 1.15",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
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
      # Web dependencies
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      
      # Internal dependencies (poncho style)
      {:core, path: "../core", override: true},
      {:portfolio_manager, path: "../portfolio_manager", override: true},
      {:order_manager, path: "../order_manager", override: true},
      {:data_collector, path: "../data_collector", override: true}
    ]
  end
end
