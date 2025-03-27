defmodule WebDashboard.Application do
  @moduledoc false
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    # Check if we're in standalone mode (without Core)
    standalone = System.get_env("STANDALONE") == "true" || !code_available?(:core)
    Logger.info("Web dashboard starting in #{if standalone, do: "standalone", else: "normal"} mode")

    # Force server to start
    force_server_to_start()

    children = [
      # Start the Telemetry supervisor
      WebDashboard.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: WebDashboard.PubSub},
      # Start the Phoenix endpoint
      {WebDashboard.Endpoint, []}
    ]

    # See if we can access and log configuration
    endpoint_config = Application.get_env(:web_dashboard, WebDashboard.Endpoint)
    http_config = Keyword.get(endpoint_config, :http, [])
    port = Keyword.get(http_config, :port, 4000)
    ip = Keyword.get(http_config, :ip, {127, 0, 0, 1})
    server_enabled = Keyword.get(endpoint_config, :server, false)

    Logger.info("WebDashboard endpoint configuration:")
    Logger.info("  Port: #{port}")
    Logger.info("  IP: #{inspect(ip)}")
    Logger.info("  Server enabled: #{server_enabled}")
    Logger.info("  URL: http://localhost:#{port}")

    opts = [strategy: :one_for_one, name: WebDashboard.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WebDashboard.Endpoint.config_change(changed, removed)
    :ok
  end

  # Function to force the server to start
  defp force_server_to_start do
    # Get current config
    endpoint_config = Application.get_env(:web_dashboard, WebDashboard.Endpoint, [])

    # Ensure server is enabled
    updated_config = Keyword.put(endpoint_config, :server, true)

    # Ensure http configuration is set properly
    http_config = Keyword.get(updated_config, :http, [])
    http_config = Keyword.put_new(http_config, :port, 4000)
    http_config = Keyword.put_new(http_config, :ip, {0, 0, 0, 0})
    updated_config = Keyword.put(updated_config, :http, http_config)

    # Ensure secret_key_base is set
    updated_config = Keyword.put_new(updated_config, :secret_key_base, "MDJbPbYKOLQT7SSIhAfg4XZTnbFyUy1a6U5/xA7GKJQjfBe54G4A3YMgZm69EoJ3")

    # Ensure LiveView signing salt is set
    live_view_config = Keyword.get(updated_config, :live_view, [])
    live_view_config = Keyword.put_new(live_view_config, :signing_salt, "GDCg8JH2Il2A6gHk")
    updated_config = Keyword.put(updated_config, :live_view, live_view_config)

    # Update the application environment
    Application.put_env(:web_dashboard, WebDashboard.Endpoint, updated_config)

    Logger.info("Forced WebDashboard server to start on http://localhost:#{http_config[:port]}")
  end

  # Check if a module is available
  defp code_available?(app) do
    case :application.get_application(app) do
      {:ok, _} -> true
      _ -> false
    end
  end
end
