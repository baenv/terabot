import Config

# Core database configuration
config :core, Core.Repo,
  database: System.get_env("DB_NAME"),
  username: System.get_env("DB_USER"),
  password: System.get_env("DB_PASS"),
  hostname: System.get_env("DB_HOST"),
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool_size: 20,
  socket_dir: nil

# Data Collector configuration
config :data_collector,
  binance_api_key: System.get_env("BINANCE_API_KEY"),
  binance_api_secret: System.get_env("BINANCE_API_SECRET"),
  trading_pairs: System.get_env("TRADING_PAIRS") |> String.split(",")

# Portfolio Manager configuration
config :portfolio_manager,
  rebalance_interval: String.to_integer(System.get_env("REBALANCE_INTERVAL") || "3600")  # in seconds

# Order Manager configuration
config :order_manager,
  max_retry_attempts: String.to_integer(System.get_env("MAX_RETRY_ATTEMPTS") || "3"),
  retry_interval: String.to_integer(System.get_env("RETRY_INTERVAL") || "1000")  # in milliseconds

# Decision Engine configuration
config :decision_engine,
  strategy_module: System.get_env("STRATEGY_MODULE") |> String.to_atom()

# Web Dashboard configuration
config :web_dashboard,
  port: String.to_integer(System.get_env("PORT") || "4000"),
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Trading System Main configuration
config :trading_system_main,
  environment: :prod

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :info

# Ethereum configuration
config :ethereumex,
  url: System.get_env("ETH_RPC_URL")
