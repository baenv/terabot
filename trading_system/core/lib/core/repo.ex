defmodule Core.Repo do
  # Repo module for database interactions

  use Ecto.Repo,
    otp_app: :core,
    adapter: Ecto.Adapters.Postgres

  @impl true
  def init(_, config) do
    config = Keyword.put(config, :parameters, application_name: "terabot")

    # Ensure we're using TCP rather than Unix sockets
    config = Keyword.put(config, :socket_dir, nil)

    {:ok, config}
  end
end
