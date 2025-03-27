defmodule PortfolioManager.MixProject do
  use Mix.Project

  def project do
    [
      app: :portfolio_manager,
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
      mod: {PortfolioManager.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Core dependencies
      {:core, path: "../core", override: true},

      # Phoenix dependencies
      {:phoenix_pubsub, "~> 2.1.3", override: true},

      # Web dependencies
      {:plug, "~> 1.14.2", override: true},
      {:plug_cowboy, "~> 2.6.2", override: true},
      {:cowboy, "~> 2.9.0", override: true},
      {:cowlib, "~> 2.11.0", override: true},
      {:ranch, "~> 1.8.0", override: true},

      # Ethereum dependencies
      {:ethereumex, "~> 0.10.7", override: true},
      {:ex_abi, "~> 0.5.16", override: true},
      {:ex_secp256k1, "~> 0.7.4", override: true},
      {:ex_keccak, "~> 0.7.3", override: true},
      {:rustler, "~> 0.30.0", override: true},
      {:rustler_precompiled, "~> 0.8.2", override: true},

      # Decimal for precise calculations
      {:decimal, "~> 2.1.1", override: true},

      # HTTP client
      {:httpoison, "~> 2.2.2", override: true},
      {:jason, "~> 1.4.4", override: true},
      {:finch, "~> 0.16.0", override: true},

      # Monitoring and logging
      {:telemetry, "~> 1.2.1", override: true},
      {:telemetry_metrics, "~> 0.6.2", override: true},
      {:telemetry_poller, "~> 1.0.0", override: true},

      # Testing
      {:mox, "~> 1.1.0", only: :test},

      # Additional dependencies needed by other modules to ensure compatibility
      {:nimble_options, "~> 1.1.1", override: true},
      {:nimble_pool, "~> 1.1.0", override: true},
      {:hackney, "~> 1.23.0", override: true},
      {:unicode_util_compat, "~> 0.7.0", override: true},
      {:certifi, "~> 2.14.0", override: true},
      {:parse_trans, "~> 3.4.1", override: true},
      {:castore, "~> 1.0.12", override: true},
      {:mint, "~> 1.7.1", override: true},
      {:mime, "~> 2.0.6", override: true},
      {:db_connection, "~> 2.7.0", override: true}
    ]
  end
end
