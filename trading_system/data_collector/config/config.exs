import Config

# Data Collector configuration
config :data_collector,
  ecto_repos: [Core.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"
