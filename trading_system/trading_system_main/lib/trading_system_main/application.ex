defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Load environment variables from .env file
    load_env()

    # Start applications in the correct order
    ensure_started(:core)
    ensure_started(:data_collector)
    ensure_started(:order_manager)
    ensure_started(:decision_engine)
    ensure_started(:portfolio_manager)

    # Explicitly start the web dashboard
    ensure_started(:web_dashboard)

    children = [
      # Start the Registry for component registration
      {Registry, keys: :unique, name: TradingSystemMain.Registry},
      # Start the PubSub server for system-wide events
      {Phoenix.PubSub, name: TradingSystemMain.PubSub},
      # Start the ETS tables for caching
      TradingSystemMain.Cache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingSystemMain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Helper to ensure an application is started
  defp ensure_started(app) do
    case Application.ensure_all_started(app) do
      {:ok, _} ->
        Logger.info("#{app} successfully started")
      {:error, {dep, reason}} ->
        Logger.error("Failed to start #{app}: dependency #{dep} failed with reason: #{inspect(reason)}")
    end
  end

  # Load environment variables from .env file
  defp load_env do
    env_file = Path.join(File.cwd!(), "../../.env")
    if File.exists?(env_file) do
      env_file
      |> File.read!()
      |> String.split("\n")
      |> Enum.filter(fn line ->
        String.trim(line) != "" && !String.starts_with?(String.trim(line), "#")
      end)
      |> Enum.each(fn line ->
        case String.split(line, "=", parts: 2) do
          [key, value] ->
            System.put_env(String.trim(key), String.trim(value))
          _ ->
            nil
        end
      end)
      Logger.info("Loaded environment variables from .env file")
    else
      Logger.warn("No .env file found at #{env_file}")
    end
  end
end
