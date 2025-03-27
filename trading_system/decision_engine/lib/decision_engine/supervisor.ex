defmodule DecisionEngine.Supervisor do
  @moduledoc """
  Supervisor for the Decision Engine components.
  Manages strategy workers and signal processors.
  """

  use Supervisor
  require Logger

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    children = [
      # Add strategy workers here when implemented
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
