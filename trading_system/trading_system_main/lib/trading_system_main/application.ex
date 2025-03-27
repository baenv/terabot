defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @default_eth_rpc_urls [
    "https://eth.llamarpc.com",
    "https://ethereum.publicnode.com",
    "https://rpc.flashbots.net/",
    "https://1rpc.io/eth",
    "https://mainnet.infura.io/v3/9aa3d95b3bc440fa88ea12eaa4456161" # Public Infura endpoint
  ]

  @impl true
  def start(_type, _args) do
    # Load environment variables from .env file
    load_env()

    children = [
      # Start the Registry for component registration
      {Registry, keys: :unique, name: TradingSystemMain.Registry},

      # Start the PubSub server for system-wide events
      {Phoenix.PubSub, name: TradingSystemMain.PubSub},

      # Start the ETS tables for caching
      TradingSystemMain.Cache,

      # Supervisor for core application (if not already started)
      maybe_start_application(:core),

      # Supervisor for data collector
      maybe_start_application(:data_collector),

      # Supervisor for order manager
      maybe_start_application(:order_manager),

      # Supervisor for decision engine
      maybe_start_application(:decision_engine),

      # Supervisor for portfolio manager
      maybe_start_application(:portfolio_manager),

      # Supervisor for web dashboard
      maybe_start_application(:web_dashboard)
    ]
    |> Enum.filter(&(&1 != nil)) # Remove nil entries

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :rest_for_one, name: TradingSystemMain.Supervisor]

    case Supervisor.start_link(children, opts) do
      {:ok, pid} ->
        Logger.info("TradingSystemMain started successfully")
        {:ok, pid}
      {:error, reason} ->
        Logger.error("Failed to start TradingSystemMain: #{inspect(reason)}")
        {:error, reason}
    end
  end

  # Load environment variables from .env file
  defp load_env do
    env_file = Path.join(File.cwd!(), "../../.env")

    # Load from .env file if it exists
    env_vars = if File.exists?(env_file) do
      env_file
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(fn line ->
        String.trim(line) != "" && !String.starts_with?(String.trim(line), "#")
      end)
      |> Enum.reduce(%{}, fn line, acc ->
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            Map.put(acc, String.trim(key), String.trim(value))
          _ ->
            acc
        end
      end)
    else
      Logger.warn("No .env file found at #{env_file}")
      %{}
    end

    # Set environment variables with defaults if not set
    set_env_with_default(env_vars, "ETH_RPC_URL", Enum.random(@default_eth_rpc_urls))
    set_env_with_default(env_vars, "ETH_CHAIN_ID", "1") # Mainnet
    set_env_with_default(env_vars, "ETH_NETWORK", "mainnet")

    # Set any remaining variables from .env
    env_vars
    |> Map.drop(["ETH_RPC_URL", "ETH_CHAIN_ID", "ETH_NETWORK"])
    |> Enum.each(fn {key, value} ->
      System.put_env(key, value)
    end)

    Logger.info("Environment configuration loaded")

    # Log the selected Ethereum RPC URL (but mask any API keys)
    eth_rpc_url = System.get_env("ETH_RPC_URL")
    masked_url = if String.contains?(eth_rpc_url, "?apiKey=") do
      String.replace(eth_rpc_url, ~r/apiKey=([^&]+)/, "apiKey=****")
    else
      eth_rpc_url
    end
    Logger.info("Using Ethereum RPC URL: #{masked_url}")
  end

  # Helper function to set environment variable with default if not already set
  defp set_env_with_default(env_vars, key, default) do
    value = Map.get(env_vars, key) || System.get_env(key) || default
    System.put_env(key, value)
  end

  # Helper function to conditionally start an application
  defp maybe_start_application(app) do
    app_module = Module.concat([Macro.camelize(to_string(app)), "Application"])

    # If the app is web_dashboard, make sure server is enabled
    if app == :web_dashboard do
      # Ensure the server is set to start
      config = Application.get_env(:web_dashboard, WebDashboard.Endpoint, [])
      unless Keyword.get(config, :server) do
        Application.put_env(:web_dashboard, WebDashboard.Endpoint, Keyword.put(config, :server, true))
      end

      # Log web dashboard URL
      port = get_in(config, [:http, :port]) || 4000
      Logger.info("WebDashboard will be available at: http://localhost:#{port}")
    end

    case Application.ensure_all_started(app) do
      {:ok, _} ->
        # Application started successfully, don't add it to children
        Logger.info("Application #{app} started successfully")
        nil
      {:error, {:already_started, ^app}} ->
        # Application is already running, don't add it to children
        Logger.info("Application #{app} is already running")
        nil
      {:error, reason} ->
        # Failed to start application for other reasons
        Logger.error("Failed to start #{app} application: #{inspect(reason)}")
        # Return the application supervisor spec to try starting it
        %{
          id: app_module,
          start: {app_module, :start, [:normal, []]},
          restart: :permanent,
          type: :supervisor
        }
    end
  end
end
