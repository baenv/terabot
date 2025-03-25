defmodule PortfolioManager.Web.Server do
  @moduledoc """
  HTTP server for the Portfolio Manager API.
  """
  
  use GenServer
  require Logger
  
  @default_port 4004
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    port = get_port(opts)
    
    case Plug.Cowboy.http(PortfolioManager.Web.Router, [], port: port) do
      {:ok, pid} ->
        Logger.info("Portfolio Manager API server started on port #{port}")
        {:ok, %{port: port, pid: pid}}
      {:error, :eaddrinuse} ->
        Logger.warning("Port #{port} already in use, trying port #{port + 1}")
        case Plug.Cowboy.http(PortfolioManager.Web.Router, [], port: port + 1) do
          {:ok, pid} ->
            Logger.info("Portfolio Manager API server started on port #{port + 1}")
            {:ok, %{port: port + 1, pid: pid}}
          {:error, reason} ->
            Logger.error("Failed to start Portfolio Manager API server: #{inspect(reason)}")
            {:stop, reason}
        end
      {:error, reason} ->
        Logger.error("Failed to start Portfolio Manager API server: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  defp get_port(opts) do
    # Priority: 1. Options passed to start_link, 2. Environment variable, 3. Default port
    case Keyword.get(opts, :port) do
      nil ->
        case System.get_env("PORTFOLIO_MANAGER_PORT") do
          nil -> @default_port
          port_str -> String.to_integer(port_str)
        end
      port -> port
    end
  end
  
  @impl true
  def terminate(_reason, %{port: port}) do
    :ok = Plug.Cowboy.shutdown(PortfolioManager.Web.Router.HTTP)
    Logger.info("Portfolio Manager API server on port #{port} stopped")
  end
end
