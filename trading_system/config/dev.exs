import Config

config :core,
  ecto_repos: [Core.Repo]

config :core, Core.Repo,
  database: System.get_env("DB_NAME") || "trading_system_dev",
  username: System.get_env("DB_USER") || "postgres",
  password: System.get_env("DB_PASS") || "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool_size: 10,
  socket_dir: nil

config :data_collector,
  binance_api_key: System.get_env("BINANCE_API_KEY"),
  binance_api_secret: System.get_env("BINANCE_API_SECRET"),
  trading_pairs: ["BTCUSDT", "ETHUSDT", "BNBUSDT"]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :tai, Tai.Orders.OrderRepo,
  database: System.get_env("DB_NAME") || "trading_system_dev",
  username: System.get_env("DB_USER") || "postgres",
  password: System.get_env("DB_PASS") || "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool_size: 10,
  socket_dir: nil
