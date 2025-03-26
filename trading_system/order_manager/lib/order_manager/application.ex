defmodule OrderManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the transaction manager
      OrderManager.TransactionManager,
      # Start the Ethereum order executor
      OrderManager.EthereumOrderExecutor,
      # Start the transaction monitor supervisor
      {OrderManager.Monitor.Supervisor, []},
      # Start the PubSub server for order notifications
      {Phoenix.PubSub, name: OrderManager.PubSub}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: OrderManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
