defmodule WebDashboard.Router do
  use Phoenix.Router
  import Phoenix.LiveView.Router
  import Plug.Conn
  import Phoenix.Controller

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WebDashboard.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", WebDashboard do
    pipe_through :browser

    # LiveView routes
    live "/", DashboardLive.Index, :index
    live "/accounts", AccountsLive.Index, :index
    live "/accounts/:id", AccountsLive.Show, :show
    live "/transactions", TransactionsLive.Index, :index
    live "/portfolio", PortfolioLive.Index, :index
    live "/orders", OrdersLive.Index, :index
    live "/wallets", WalletsLive.Index, :index
  end

  # API endpoints
  scope "/api", WebDashboard do
    pipe_through :api

    get "/status", StatusController, :index
    get "/accounts", AccountsController, :index
    get "/accounts/:id", AccountsController, :show
    get "/portfolio", PortfolioController, :index
    get "/transactions", TransactionsController, :index
  end

  # Fallback route for development
  if Mix.env() == :dev do
    # Enable debug info for LiveView
    scope "/" do
      pipe_through :browser
      forward "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    end
  end

  # Fallback for any other routes
  scope "/" do
    pipe_through :browser
    get "/*path", WebDashboard.FallbackController, :not_found
  end
end
