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
      {:phoenix_pubsub, github: "phoenixframework/phoenix_pubsub", tag: "v2.1.3", override: true},

      # Web dependencies
      {:plug, github: "elixir-plug/plug", tag: "v1.14.2", override: true},
      {:plug_cowboy, github: "elixir-plug/plug_cowboy", tag: "v2.6.1", override: true},
      {:cowboy, "~> 2.9.0", override: true},
      {:cowlib, "~> 2.11.0", override: true},
      {:ranch, "~> 1.8.0", override: true},

      # Ethereum dependencies
      {:ethereumex, github: "mana-ethereum/ethereumex", override: true},
      {:ex_abi, github: "poanetwork/ex_abi", override: true},
      {:ex_secp256k1, github: "omgnetwork/ex_secp256k1", override: true},
      {:rustler_precompiled, github: "philss/rustler_precompiled", tag: "v0.8.0", override: true},

      # Decimal for precise calculations
      {:decimal, github: "ericmj/decimal", tag: "v2.1.1", override: true},

      # HTTP client
      {:httpoison, github: "edgurgel/httpoison", tag: "v2.2.1", override: true},
      {:jason, github: "michalmuskala/jason", tag: "v1.4.1", override: true},
      {:finch, github: "sneako/finch", tag: "v0.16.0", override: true},

      # Monitoring and logging
      {:telemetry, github: "beam-telemetry/telemetry", tag: "v1.2.1", override: true},
      {:telemetry_metrics, github: "beam-telemetry/telemetry_metrics", tag: "v0.6.1", override: true},
      {:telemetry_poller, github: "beam-telemetry/telemetry_poller", tag: "v1.0.0", override: true},

      # Testing
      {:mox, "~> 1.1.0", only: :test}
    ]
  end
end
