defmodule TradingSystemMain.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    # Explicitly start each component application
    # This ensures they're properly loaded and available
    start_component_applications()

    children = [
      # Start the proper web server
      {TradingSystemMain.Web.Server, []}

      # Add other supervised children here if needed
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: TradingSystemMain.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Helper function to start all component applications
  defp start_component_applications do
    # Start applications in dependency order
    apps = [
      :core,
      :data_collector,
      :data_processor,
      :decision_engine,
      :order_manager,
      :portfolio_manager
    ]

    Enum.each(apps, fn app ->
      case Application.ensure_all_started(app) do
        {:ok, _} ->
          IO.puts("Started #{app} application successfully")

        {:error, {app, reason}} ->
          IO.puts("Failed to start #{app}: #{inspect(reason)}")
      end
    end)
  end
end
