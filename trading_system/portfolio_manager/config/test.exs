import Config

# Portfolio Manager configuration
config :portfolio_manager,
  rebalance_interval: 60,  # shorter interval for testing
  test_mode: true

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning
