import Config

# Order Manager configuration
config :order_manager,
  max_retry_attempts: 2,
  retry_interval: 100,  # shorter interval for testing
  test_mode: true

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning
