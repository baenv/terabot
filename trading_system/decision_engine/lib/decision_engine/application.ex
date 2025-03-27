defmodule DecisionEngine.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system for decision engine events
      {Phoenix.PubSub, name: DecisionEngine.PubSub},
      # Start the strategy manager
      DecisionEngine.StrategyManager,
      # Start the signal processor
      DecisionEngine.SignalProcessor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DecisionEngine.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
