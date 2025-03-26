defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Registry for component registration
      {Registry, keys: :unique, name: TradingSystemMain.Registry},
      # Start the PubSub server for system-wide events
      {Phoenix.PubSub, name: TradingSystemMain.PubSub},
      # Start the ETS tables for caching
      TradingSystemMain.Cache,
      # Start the core application
      Core.Application,
      # Start the portfolio manager
      PortfolioManager.Application,
      # Start the data collector
      DataCollector.Application,
      # Start the order manager
      OrderManager.Application,
      # Start the decision engine
      DecisionEngine.Application
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingSystemMain.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
