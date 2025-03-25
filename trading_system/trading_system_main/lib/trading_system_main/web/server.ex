defmodule TradingSystemMain.Web.Server do
  @moduledoc """
  HTTP server for the Trading System Main API.
  """
  
  use GenServer
  require Logger
  
  @default_port 4000
  
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, @default_port)
    
    case Plug.Cowboy.http(TradingSystemMain.Web.Router, [], port: port) do
      {:ok, _} ->
        Logger.info("Trading System Main API server started on port #{port}")
        {:ok, %{port: port}}
      
      {:error, :eaddrinuse} ->
        Logger.warning("Port #{port} already in use, trying alternative port")
        # Try an alternative port
        alt_port = port + 100
        {:ok, _} = Plug.Cowboy.http(TradingSystemMain.Web.Router, [], port: alt_port)
        Logger.info("Trading System Main API server started on alternative port #{alt_port}")
        {:ok, %{port: alt_port}}
        
      {:error, reason} ->
        Logger.error("Failed to start HTTP server: #{inspect(reason)}")
        {:stop, reason}
    end
  end
  
  @impl true
  def terminate(_reason, %{port: port}) do
    :ok = Plug.Cowboy.shutdown(TradingSystemMain.Web.Router.HTTP)
    Logger.info("Trading System Main API server on port #{port} stopped")
  end
end
