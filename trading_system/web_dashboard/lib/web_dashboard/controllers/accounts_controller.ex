defmodule WebDashboard.AccountsController do
  use Phoenix.Controller
  alias Core.Accounts

  def index(conn, _params) do
    with {:ok, accounts} <- Accounts.list_accounts() do
      json(conn, accounts)
    else
      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def show(conn, %{"id" => id}) do
    with {:ok, account} <- Accounts.get_account(id) do
      json(conn, account)
    else
      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Account not found"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end
end
