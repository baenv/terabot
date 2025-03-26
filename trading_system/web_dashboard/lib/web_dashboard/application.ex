defmodule WebDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system for real-time updates
      {Phoenix.PubSub, name: WebDashboard.PubSub},

      # Start the Phoenix Endpoint for the web dashboard
      {WebDashboard.Endpoint, []}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
