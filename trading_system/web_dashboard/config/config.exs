import Config

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure the web server
config :web_dashboard, WebDashboard.Endpoint,
  url: [host: "localhost"],
  adapter: Phoenix.Endpoint.Cowboy2Adapter,
  render_errors: [
    formats: [html: WebDashboard.ErrorHTML, json: WebDashboard.ErrorJSON],
    layout: false
  ],
  pubsub_server: WebDashboard.PubSub,
  live_view: [signing_salt: "terabotSecureSalt"]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
