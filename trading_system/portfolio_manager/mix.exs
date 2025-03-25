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
      {:core, path: "../core"},
      {:order_manager, path: "../order_manager"},
      {:decimal, "~> 2.1"},
      {:statistics, "~> 0.6.2"},
      {:plug, "~> 1.14"},
      {:plug_cowboy, "~> 2.6"},
      {:jason, "~> 1.4"},
      # WebSocket client for real-time exchange connections
      {:websocket_client, "~> 1.4"},
      # HTTP client for API calls and webhook registration
      {:httpoison, "~> 1.8"},
      # For cryptographic operations (already included in Erlang/OTP)
      # Using :crypto module from Erlang/OTP instead of external dependency
      # For handling event broadcasting within the application
      {:phoenix_pubsub, "~> 2.0"}
    ]
  end
end
