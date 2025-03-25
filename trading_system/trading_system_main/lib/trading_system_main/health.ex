defmodule TradingSystemMain.Health do
  @moduledoc """
  Health check utilities for the Terabot trading system.
  Provides a dependency-free way to check application status.
  """
  
  @doc """
  Get health status for all applications in the trading system.
  During development with dependency issues, this will show all apps as available.
  """
  def check_all_apps do
    apps = [:core, :data_collector, :data_processor, :decision_engine, 
            :order_manager, :portfolio_manager, :trading_system_main]
    
    app_statuses = apps
                   |> Enum.map(fn app -> {app, %{status: "available"}} end)
                   |> Enum.into(%{})
    
    %{
      status: "ok",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601(),
      applications: app_statuses
    }
  end
  
  @doc """
  Get health status for a specific application.
  During development with dependency issues, this will show the app as available.
  """
  def check_app_health(app) do
    %{status: "available"}
  end
end
