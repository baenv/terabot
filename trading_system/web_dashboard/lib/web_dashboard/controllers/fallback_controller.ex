defmodule WebDashboard.FallbackController do
  use Phoenix.Controller

  def not_found(conn, _params) do
    conn
    |> put_status(404)
    |> put_view(WebDashboard.ErrorHTML)
    |> render("404.html")
  end

  def internal_error(conn, _params) do
    conn
    |> put_status(500)
    |> put_view(WebDashboard.ErrorHTML)
    |> render("500.html")
  end

  # Handle API errors
  def not_found_json(conn, _params) do
    conn
    |> put_status(404)
    |> put_view(WebDashboard.ErrorJSON)
    |> render("404.json")
  end

  def internal_error_json(conn, _params) do
    conn
    |> put_status(500)
    |> put_view(WebDashboard.ErrorJSON)
    |> render("500.json")
  end
end
