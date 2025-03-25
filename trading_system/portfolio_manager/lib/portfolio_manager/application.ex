defmodule PortfolioManager.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Registry for adapter processes
      {Registry, keys: :unique, name: PortfolioManager.AdapterRegistry},
      
      # Start the PubSub system for event broadcasting
      {Phoenix.PubSub, name: PortfolioManager.PubSub},
      
      # Start the Tracker process
      {PortfolioManager.Tracker, []},
      
      # Start the Adapters Supervisor
      {PortfolioManager.Adapters.Supervisor, []},
      
      # Start the Web API server
      {PortfolioManager.Web.Server, []},
      
      # Start the Webhook server for real-time updates
      {Plug.Cowboy, scheme: :http, plug: PortfolioManager.WebhookController, options: [port: webhook_port()]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PortfolioManager.Supervisor]
    Supervisor.start_link(children, opts)
  end
  
  # Get webhook port from environment or use default
  # Try to find an available port starting from the base port
  defp webhook_port do
    base_port = case System.get_env("PORTFOLIO_WEBHOOK_PORT") do
      nil -> 4005 # Default base port (different from API server port 4004)
      port_str -> String.to_integer(port_str)
    end
    
    # If we're in development mode, try to find an available port
    # by incrementing from the base port
    if Mix.env() == :dev do
      find_available_port(base_port)
    else
      base_port
    end
  end
  
  # Find an available port by incrementing from the base port
  # This helps avoid conflicts in development
  defp find_available_port(port, max_attempts \\ 10)
  defp find_available_port(port, 0) do
    # Last resort, try a port far from the base
    fallback_port = port + 1000
    IO.puts("Warning: Could not find available port after multiple attempts. Using fallback port #{fallback_port}")
    fallback_port
  end
  defp find_available_port(port, attempts) do
    case :gen_tcp.listen(port, [:binary, active: false]) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        IO.puts("Using available port: #{port}")
        port
      {:error, :eaddrinuse} ->
        IO.puts("Port #{port} is already in use, trying next port")
        find_available_port(port + 1, attempts - 1)
      {:error, reason} ->
        IO.puts("Error checking port #{port}: #{inspect(reason)}, trying next port")
        find_available_port(port + 1, attempts - 1)
    end
  end
end
