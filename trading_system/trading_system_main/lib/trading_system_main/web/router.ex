defmodule TradingSystemMain.Web.Router do
  use Plug.Router

  alias TradingSystemMain.Web.Health

  plug :match
  plug :dispatch

  # Health check endpoint
  get "/health" do
    resp = Health.check()
    send_resp(conn, 200, resp)
  end

  # Health check for system components
  get "/health/components" do
    resp = Health.check_components()
    send_resp(conn, 200, resp)
  end

  # Health check specific component
  get "/health/:component" do
    resp = Health.check_component(component)
    send_resp(conn, 200, resp)
  end

  # Forward requests to appropriate sub-applications
  # Removed the forward to PortfolioManager.Web.Router since it's causing issues

  # Handle 404s
  match _ do
    send_resp(conn, 404, "Not found")
  end
end
