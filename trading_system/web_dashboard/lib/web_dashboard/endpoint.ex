defmodule WebDashboard.Endpoint do
  use Phoenix.Endpoint, otp_app: :web_dashboard

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_web_dashboard_key",
    signing_salt: "Nt5W2n8u",
    same_site: "Lax"
  ]

  # Specify the view to use for rendering errors
  @render_errors [
    formats: [
      html: WebDashboard.ErrorHTML,
      json: WebDashboard.ErrorJSON
    ],
    layout: false,
    status_code_to_view: %{
      404 => :not_found,
      500 => :internal_server_error
    }
  ]

  socket "/live", Phoenix.LiveView.Socket,
    websocket: [connect_info: [session: @session_options]],
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :web_dashboard,
    gzip: false,
    only: WebDashboard.static_paths()

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  # Use the plug for logging
  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Allow liveview to work without checks
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  # Set up session handling
  plug Plug.MethodOverride
  plug Plug.Head
  plug Plug.Session, @session_options

  # Add the main router
  plug WebDashboard.Router

  # Initialize the endpoint
  def init(_key, config) do
    # Always update the render_errors configuration
    config = Keyword.put(config, :render_errors, @render_errors)
    {:ok, config}
  end
end
