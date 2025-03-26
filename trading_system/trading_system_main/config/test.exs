import Config

# Core database configuration
config :core, Core.Repo,
  database: System.get_env("DB_NAME") || "trading_system_test",
  username: System.get_env("DB_USER") || "postgres",
  password: System.get_env("DB_PASS") || "postgres",
  hostname: System.get_env("DB_HOST") || "localhost",
  port: String.to_integer(System.get_env("DB_PORT") || "5432"),
  pool: Ecto.Adapters.SQL.Sandbox,
  socket_dir: nil

# Set test mode for components
config :decision_engine, test_mode: true
config :trading_system_main, environment: :test

# Logger configuration
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id],
  level: :warning

# Ethereum mock configuration
config :ethereumex,
  url: "http://localhost:8545",
  http_options: [recv_timeout: 10000],
  http_headers: [{"Content-Type", "application/json"}]
