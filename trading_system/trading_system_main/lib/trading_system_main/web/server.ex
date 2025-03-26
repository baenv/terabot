defmodule TradingSystemMain.Web.Server do
  @moduledoc """
  HTTP server for the Trading System Main API.
  """

  use GenServer
  require Logger

  @default_port 4000

  # API functions
  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def start() do
    GenServer.call(__MODULE__, :start)
  end

  def stop() do
    GenServer.call(__MODULE__, :stop)
  end

  # Callbacks
  @impl true
  def init(opts) do
    port = Keyword.get(opts, :port, @default_port)
    Logger.info("Web server will use port #{port}")

    # Return without starting the server automatically
    {:ok, %{port: port, server_ref: nil}}
  end

  @impl true
  def handle_call(:start, _from, state = %{port: port}) do
    Logger.info("Starting simplified web server (without Plug.Cowboy) on port #{port}...")
    # Here we would normally start a web server
    # For now just return a mock reference
    server_ref = :mock_server_ref

    {:reply, {:ok, server_ref}, %{state | server_ref: server_ref}}
  end

  @impl true
  def handle_call(:stop, _from, state = %{server_ref: server_ref}) when not is_nil(server_ref) do
    Logger.info("Stopping simplified web server...")
    # Here we would stop the web server

    {:reply, :ok, %{state | server_ref: nil}}
  end

  @impl true
  def handle_call(:stop, _from, state) do
    {:reply, {:error, :not_running}, state}
  end

  @impl true
  def terminate(_reason, %{server_ref: server_ref}) when not is_nil(server_ref) do
    Logger.info("Terminating simplified web server...")
    # Clean up here if needed
    :ok
  end

  @impl true
  def terminate(_reason, _state) do
    :ok
  end
end
