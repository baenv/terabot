import Config

# Test configuration for the simple server
config :web_dashboard, :server,
  port: 4001,  # Use a different port for tests
  host: "localhost",
  ip: {127, 0, 0, 1}

config :logger, level: :warning
