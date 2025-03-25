defmodule PortfolioManager.Web.Router do
  use Plug.Router
  
  plug Plug.Logger
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  # Account management endpoints
  post "/accounts" do
    {:ok, body, conn} = read_body(conn)
    account_params = Jason.decode!(body, keys: :atoms)
    
    case PortfolioManager.API.register_account(account_params) do
      {:ok, account} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(201, Jason.encode!(%{
          status: "success",
          data: %{
            id: account.id,
            name: account.name,
            provider: account.provider,
            account_id: account.account_id,
            type: account.type
          }
        }))
        
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _opts} -> msg end)
        
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{
          status: "error",
          errors: errors
        }))
    end
  end
  
  get "/accounts" do
    case PortfolioManager.API.list_accounts() do
      {:ok, accounts} ->
        accounts_data = Enum.map(accounts, fn account ->
          %{
            id: account.id,
            name: account.name,
            provider: account.provider,
            account_id: account.account_id,
            type: account.type,
            active: account.active
          }
        end)
        
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          data: accounts_data
        }))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Failed to retrieve accounts: #{inspect(reason)}"
        }))
    end
  end
  
  get "/accounts/:id" do
    case PortfolioManager.API.get_account(id) do
      {:ok, account} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          data: %{
            id: account.id,
            name: account.name,
            provider: account.provider,
            account_id: account.account_id,
            type: account.type,
            active: account.active
          }
        }))
        
      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{
          status: "error",
          message: "Account not found"
        }))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Failed to retrieve account: #{inspect(reason)}"
        }))
    end
  end
  
  # Portfolio endpoints
  get "/portfolio" do
    opts = case conn.query_params do
      %{"base_currency" => base_currency} -> %{base_currency: base_currency}
      _ -> %{}
    end
    
    case PortfolioManager.API.get_portfolio_summary(opts) do
      {:ok, portfolio} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{
          status: "success",
          data: portfolio
        }))
        
      {:error, reason} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{
          status: "error",
          message: "Failed to retrieve portfolio: #{inspect(reason)}"
        }))
    end
  end
  
  # Health check endpoint
  get "/health" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: "ok", service: "portfolio_manager"}))
  end
  
  # Fallback for unmatched routes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{status: "error", message: "Not found"}))
  end
end
