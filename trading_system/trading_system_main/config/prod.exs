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

# Decision Engine configuration
config :decision_engine,
  strategy_module: System.get_env("STRATEGY_MODULE") |> String.to_atom()

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
