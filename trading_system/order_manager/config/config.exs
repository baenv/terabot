import Config

# Order Manager configuration
config :order_manager,
  ecto_repos: [Core.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"
