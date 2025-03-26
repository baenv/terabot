defmodule WebDashboard.TransactionsController do
  use Phoenix.Controller
  alias Core.Transactions

  def index(conn, params) do
    account_id = params["account_id"]

    with {:ok, transactions} <- Transactions.list_transactions(account_id) do
      json(conn, transactions)
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end
end
