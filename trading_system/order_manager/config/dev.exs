import Config

# Order Manager configuration
config :order_manager,
  max_retry_attempts: 3,
  retry_interval: 1000,  # in milliseconds
  test_mode: false

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug
