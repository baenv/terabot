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

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :debug
