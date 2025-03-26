defmodule WebDashboard.PortfolioController do
  use Phoenix.Controller
  alias Core.Portfolio

  def index(conn, params) do
    account_id = params["account_id"]

    with {:ok, portfolio_data} <- Portfolio.get_portfolio(account_id) do
      json(conn, portfolio_data)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Portfolio not found"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end
end
