import Config

# Core database configuration
config :core, Core.Repo,
  database: System.get_env("DB_NAME") || "trading_system_dev",
  username: System.get_env("DB_USER") || "postgres",
  password: System.get_env("DB_PASS") || "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool_size: 10,
  socket_dir: nil

# Data Collector configuration
config :data_collector,
  binance_api_key: System.get_env("BINANCE_API_KEY"),
  binance_api_secret: System.get_env("BINANCE_API_SECRET"),
  trading_pairs: ["BTCUSDT", "ETHUSDT", "BNBUSDT"]

# Portfolio Manager configuration
config :portfolio_manager,
  rebalance_interval: 3600  # in seconds

# Order Manager configuration
config :order_manager,
  max_retry_attempts: 3,
  retry_interval: 1000  # in milliseconds

# Decision Engine configuration
config :decision_engine,
  strategy_module: DecisionEngine.Strategies.Default

# Web Dashboard configuration
config :web_dashboard,
  port: 4000,
  secret_key_base: System.get_env("SECRET_KEY_BASE")

# Trading System Main configuration
config :trading_system_main,
  environment: :dev

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug

# Ethereum configuration
config :ethereumex,
  url: System.get_env("ETH_RPC_URL") || "http://localhost:8545"
