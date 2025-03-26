defmodule PortfolioManager.Tracker.Supervisor do
  @moduledoc """
  Supervisor for portfolio tracking processes.
  Manages a collection of tracker processes, each responsible for
  tracking a specific portfolio's positions and balances.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the portfolio tracker supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a new tracker for a specific portfolio.

  ## Parameters
    * `portfolio_id` - The portfolio ID to track
    * `account_id` - The account ID associated with the portfolio

  Returns:
    * `{:ok, pid}` - The PID of the started tracker
    * `{:error, reason}` - Error with reason
  """
  def start_tracker(portfolio_id, account_id) do
    child_spec = %{
      id: tracker_id(portfolio_id),
      start: {PortfolioManager.Tracker.Worker, :start_link, [[
        portfolio_id: portfolio_id,
        account_id: account_id
      ]]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops a tracker for a specific portfolio.

  ## Parameters
    * `portfolio_id` - The portfolio ID

  Returns:
    * `:ok` - The tracker was stopped
    * `{:error, reason}` - Error with reason
  """
  def stop_tracker(portfolio_id) do
    id = tracker_id(portfolio_id)

    case Supervisor.terminate_child(__MODULE__, id) do
      :ok ->
        Supervisor.delete_child(__MODULE__, id)

      error ->
        error
    end
  end

  @doc """
  Lists all active trackers.

  Returns:
    * `[{portfolio_id, account_id, pid}]` - List of active trackers
  """
  def list_trackers do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(fn {id, pid, _type, _modules} ->
      [portfolio_id, account_id] = String.split(to_string(id), ":")
      {portfolio_id, account_id, pid}
    end)
  end

  @impl Supervisor
  def init(_opts) do
    # Start with no children initially
    # Trackers will be added dynamically as needed
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Private functions

  defp tracker_id(portfolio_id) do
    "#{portfolio_id}"
  end
end
