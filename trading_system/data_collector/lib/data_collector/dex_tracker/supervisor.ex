defmodule DataCollector.DexTracker.Supervisor do
  @moduledoc """
  Supervisor for DEX price tracking processes.
  Manages a collection of tracker processes, each responsible for
  a specific DEX or token pair.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the DEX tracker supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a new tracker for a specific DEX and token pair.

  ## Parameters
    * `dex` - The DEX to track (e.g., :uniswap, :sushiswap)
    * `token_pair` - The token pair to track (e.g., "ETH/USDT")
    * `opts` - Additional options for the tracker

  Returns:
    * `{:ok, pid}` - The PID of the started tracker
    * `{:error, reason}` - Error with reason
  """
  def start_tracker(dex, token_pair, opts \\ []) do
    child_spec = %{
      id: tracker_id(dex, token_pair),
      start: {DataCollector.DexTracker.Worker, :start_link, [[dex: dex, token_pair: token_pair] ++ opts]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops a tracker for a specific DEX and token pair.

  ## Parameters
    * `dex` - The DEX to track (e.g., :uniswap, :sushiswap)
    * `token_pair` - The token pair to track (e.g., "ETH/USDT")

  Returns:
    * `:ok` - The tracker was stopped
    * `{:error, reason}` - Error with reason
  """
  def stop_tracker(dex, token_pair) do
    id = tracker_id(dex, token_pair)

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
    * `[{dex, token_pair, pid}]` - List of active trackers
  """
  def list_trackers do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(fn {id, pid, _type, _modules} ->
      [dex, token_pair] = String.split(to_string(id), ":")
      {String.to_atom(dex), token_pair, pid}
    end)
  end

  @impl Supervisor
  def init(_opts) do
    # Start with no children initially
    # Trackers will be added dynamically as needed
    children = []

    # Start with default trackers for common pairs
    # These will be the initial trackers when the system starts
    Task.start(fn ->
      Process.sleep(1000) # Give the supervisor time to start
      start_default_trackers()
    end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Private functions

  defp tracker_id(dex, token_pair) do
    "#{dex}:#{token_pair}"
  end

  defp start_default_trackers do
    # Start trackers for common pairs on major DEXes
    default_trackers = [
      {:uniswap, "ETH/USDT"},
      {:uniswap, "ETH/USDC"},
      {:uniswap, "WBTC/ETH"},
      {:sushiswap, "ETH/USDT"},
      {:sushiswap, "ETH/USDC"}
    ]

    for {dex, token_pair} <- default_trackers do
      case start_tracker(dex, token_pair) do
        {:ok, _pid} ->
          Logger.info("Started default tracker for #{dex}:#{token_pair}")

        {:error, reason} ->
          Logger.error("Failed to start default tracker for #{dex}:#{token_pair}: #{inspect(reason)}")
      end
    end
  end
end
