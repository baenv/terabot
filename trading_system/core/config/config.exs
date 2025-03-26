import Config

# Core application configuration
config :core,
  ecto_repos: [Core.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"
