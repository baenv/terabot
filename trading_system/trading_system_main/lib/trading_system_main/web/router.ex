defmodule TradingSystemMain.Web.Router do
  use Plug.Router
  
  plug Plug.Logger
  plug :match
  plug Plug.Parsers,
    parsers: [:json],
    pass: ["application/json"],
    json_decoder: Jason
  plug :dispatch

  # Health check endpoint
  get "/api/health" do
    # Use the standalone health module that doesn't rely on dependencies
    health_data = TradingSystemMain.Health.check_all_apps()
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(health_data))
  end
  
  # Check specific application health
  get "/api/health/:app_name" do
    app_atom = String.to_atom(app_name)
    health_data = TradingSystemMain.Health.check_app_health(app_atom)
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(health_data))
  end
  
  # Forward portfolio manager requests
  forward "/api/port", to: PortfolioManager.Web.Router
  
  # Fallback for unmatched routes
  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{status: "error", message: "Not found"}))
  end
  
  # Helper functions have been moved to TradingSystemMain.Health module
end
