import Config

# Portfolio Manager configuration
config :portfolio_manager,
  ecto_repos: [Core.Repo]

# Import environment specific config
import_config "#{config_env()}.exs"
