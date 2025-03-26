defmodule WebDashboard.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    config = Application.get_env(:web_dashboard, :server, [])

    children = [
      # Start a simple web server
      {Plug.Cowboy, scheme: :http, plug: WebDashboard.Router, options: [
        port: Keyword.get(config, :port, 4000),
        ip: Keyword.get(config, :ip, {127, 0, 0, 1})
      ]}
    ]

    opts = [strategy: :one_for_one, name: WebDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
