import Config

# Data Collector configuration
config :data_collector,
  binance_api_key: System.get_env("BINANCE_API_KEY"),
  binance_api_secret: System.get_env("BINANCE_API_SECRET"),
  trading_pairs: ["BTCUSDT", "ETHUSDT", "BNBUSDT"],
  mock_api_calls: false

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug
