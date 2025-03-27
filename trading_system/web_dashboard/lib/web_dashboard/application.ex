defmodule WebDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system
      {Phoenix.PubSub, name: WebDashboard.PubSub},
      # Start the Phoenix endpoint
      {WebDashboard.Endpoint, []}
    ]

    opts = [strategy: :one_for_one, name: WebDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
