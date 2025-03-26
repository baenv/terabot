defmodule DataCollector.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Registry for DEX trackers
      {Registry, keys: :unique, name: DataCollector.Registry},
      # Start the Ethereum data collector worker
      DataCollector.EthereumWorker,
      # Start the DEX price tracker supervisor
      {DataCollector.DexTracker.Supervisor, []},
      # Start the PubSub server for data notifications
      {Phoenix.PubSub, name: DataCollector.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DataCollector.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
