import Config

# Portfolio Manager configuration
config :portfolio_manager,
  rebalance_interval: String.to_integer(System.get_env("REBALANCE_INTERVAL") || "3600"),  # in seconds
  test_mode: false

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info
