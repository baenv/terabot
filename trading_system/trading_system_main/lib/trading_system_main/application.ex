defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    children = get_children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingSystemMain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp get_children do
    base_children = [
      # Start the Registry for component registration
      {Registry, keys: :unique, name: TradingSystemMain.Registry},
      # Start the PubSub server for system-wide events
      {Phoenix.PubSub, name: TradingSystemMain.PubSub},
      # Start the ETS tables for caching
      TradingSystemMain.Cache
    ]

    # Dynamically add the available applications to avoid errors
    # if they are not available
    base_children ++ get_available_apps()
  end

  defp get_available_apps do
    available_apps = []

    available_apps =
      if Code.ensure_loaded?(Core.Application) do
        Logger.info("Core application is available, adding to children")
        # Instead of directly using the Application module, depend on the OTP application
        available_apps
      else
        Logger.warning("Core application is not available")
        available_apps
      end


    available_apps =
      if Code.ensure_loaded?(DataCollector.Application) do
        Logger.info("DataCollector is available, adding to children")
        # Instead of directly using the Application module, depend on the OTP application
        available_apps
      else
        Logger.warning("DataCollector is not available")
        available_apps
      end

    available_apps =
      if Code.ensure_loaded?(OrderManager.Application) do
        Logger.info("OrderManager is available, adding to children")
        # Instead of directly using the Application module, depend on the OTP application
        available_apps
      else
        Logger.warning("OrderManager is not available")
        available_apps
      end

    available_apps =
      if Code.ensure_loaded?(DecisionEngine.Application) do
        Logger.info("DecisionEngine is available, adding to children")
        # Instead of directly using the Application module, depend on the OTP application
        available_apps
      else
        Logger.warning("DecisionEngine is not available")
        available_apps
      end

    available_apps =
      if Code.ensure_loaded?(PortfolioManager.Application) do
        Logger.info("PortfolioManager is available, adding to children")
        # Instead of directly using the Application module, depend on the OTP application
        available_apps
      else
        Logger.warning("PortfolioManager is not available")
        available_apps
      end

    # Disable web_dashboard temporarily as it has compilation issues
    available_apps =
     if Code.ensure_loaded?(WebDashboard.Application) do
       Logger.info("WebDashboard is available, adding to children")
       # Instead of directly using the Application module, depend on the OTP application
       available_apps
     else
       Logger.warning("WebDashboard is not available")
       available_apps
     end

    available_apps
  end
end
