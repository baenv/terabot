defmodule WebDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the PubSub system for real-time updates
      {Registry, keys: :unique, name: WebDashboard.PubSub},
      # Start the Web Server
      {Plug.Cowboy, scheme: :http, plug: WebDashboard.Router, options: [port: 4000]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WebDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
