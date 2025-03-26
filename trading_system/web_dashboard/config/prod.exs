import Config

# Production configuration for the simple server
config :web_dashboard, :server,
  port: String.to_integer(System.get_env("PORT") || "4000"),
  host: System.get_env("HOST") || "localhost",
  ip: {0, 0, 0, 0}  # Allow connections from all IPs in production

config :logger, level: :info
