defmodule WebDashboard.Router do
  use Plug.Router

  # Enable logging
  plug Plug.Logger

  # Need this for router to work
  plug :match
  plug :dispatch

  # Simple route responses
  get "/" do
    send_resp(conn, 200, "Terabot Trading System Dashboard")
  end

  get "/accounts" do
    send_resp(conn, 200, "Accounts List")
  end

  get "/accounts/:id" do
    send_resp(conn, 200, "Account #{id} Details")
  end

  get "/portfolio" do
    send_resp(conn, 200, "Portfolio Overview")
  end

  get "/transactions" do
    send_resp(conn, 200, "Transactions List")
  end

  # API endpoints
  get "/api/accounts" do
    # Return empty accounts for now
    accounts = []
    json = Jason.encode!(accounts)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  get "/api/accounts/:id" do
    # Return mock account data
    account = %{id: id, name: "Account #{id}"}
    json = Jason.encode!(account)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  get "/api/portfolio" do
    # Return empty portfolio data for now
    portfolio = %{
      total_value: 0.0,
      assets: []
    }
    json = Jason.encode!(portfolio)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  get "/api/transactions" do
    # Return empty transactions for now
    transactions = []
    json = Jason.encode!(transactions)
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, json)
  end

  # Catch-all route
  match _ do
    send_resp(conn, 404, "Not found")
  end
end
