defmodule WebDashboard.StatusController do
  use Phoenix.Controller
  import Plug.Conn
  import Phoenix.Controller

  def index(conn, _params) do
    status = %{
      status: "ok",
      version: "1.0.0",
      timestamp: DateTime.utc_now() |> DateTime.to_string(),
      server_info: %{
        phoenix_version: Application.spec(:phoenix, :vsn),
        elixir_version: System.version(),
        environment: Application.get_env(:web_dashboard, :env, :dev)
      }
    }

    json(conn, status)
  end

  def health(conn, _params) do
    # Simple health check that ensures the web dashboard is running
    # In a real application, you would check dependencies, database, etc.
    app_status = %{
      web_dashboard: :running,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    }

    conn
    |> put_status(:ok)
    |> json(%{status: "ok", health: app_status})
  end
end
