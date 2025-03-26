defmodule WebDashboard.StatusController do
  use Phoenix.Controller

  def index(conn, _params) do
    status = %{
      status: "ok",
      version: "1.0.0",
      timestamp: DateTime.utc_now() |> DateTime.to_string()
    }

    json(conn, status)
  end
end
