import Config

# Data Collector configuration
config :data_collector,
  binance_api_key: "test_key",
  binance_api_secret: "test_secret",
  trading_pairs: ["BTCUSDT"],
  mock_api_calls: true

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning
