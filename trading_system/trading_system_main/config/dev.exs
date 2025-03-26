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

# Portfolio Manager configuration was removed

# Decision Engine configuration
config :decision_engine,
  strategy_module: DecisionEngine.Strategies.Default

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
