import Config

# Order Manager configuration
config :order_manager,
  max_retry_attempts: String.to_integer(System.get_env("MAX_RETRY_ATTEMPTS", "3")),
  retry_interval: String.to_integer(System.get_env("RETRY_INTERVAL", "1000")),
  test_mode: false

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info
