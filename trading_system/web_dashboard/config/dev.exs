import Config

# Dev configuration for the simple server
config :web_dashboard, :server,
  port: 4000,
  host: "localhost",
  ip: {127, 0, 0, 1}

# Set a higher stacktrace during development
config :logger, :console, level: :debug
