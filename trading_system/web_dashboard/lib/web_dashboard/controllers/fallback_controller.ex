defmodule WebDashboard.FallbackController do
  use Phoenix.Controller

  def not_found(conn, _params) do
    conn
    |> put_status(404)
    |> text("Not found")
  end
end
