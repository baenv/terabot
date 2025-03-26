defmodule OrderManager.Monitor.Supervisor do
  @moduledoc """
  Supervisor for transaction monitoring processes.
  Manages a collection of monitor processes, each responsible for
  tracking a specific transaction's confirmation status.
  """

  use Supervisor
  require Logger

  @doc """
  Starts the transaction monitor supervisor.
  """
  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Starts a new monitor for a specific transaction.

  ## Parameters
    * `eth_tx_hash` - The Ethereum transaction hash to monitor
    * `tx_id` - The internal transaction ID
    * `type` - The type of monitoring (:normal or :cancel)

  Returns:
    * `{:ok, pid}` - The PID of the started monitor
    * `{:error, reason}` - Error with reason
  """
  def start_monitor(eth_tx_hash, tx_id, type \\ :normal) do
    child_spec = %{
      id: monitor_id(eth_tx_hash),
      start: {OrderManager.Monitor.Worker, :start_link, [[
        eth_tx_hash: eth_tx_hash,
        tx_id: tx_id,
        type: type
      ]]},
      restart: :permanent,
      shutdown: 5000,
      type: :worker
    }

    Supervisor.start_child(__MODULE__, child_spec)
  end

  @doc """
  Stops a monitor for a specific transaction.

  ## Parameters
    * `eth_tx_hash` - The Ethereum transaction hash

  Returns:
    * `:ok` - The monitor was stopped
    * `{:error, reason}` - Error with reason
  """
  def stop_monitor(eth_tx_hash) do
    id = monitor_id(eth_tx_hash)

    case Supervisor.terminate_child(__MODULE__, id) do
      :ok ->
        Supervisor.delete_child(__MODULE__, id)

      error ->
        error
    end
  end

  @doc """
  Lists all active monitors.

  Returns:
    * `[{eth_tx_hash, tx_id, type, pid}]` - List of active monitors
  """
  def list_monitors do
    __MODULE__
    |> Supervisor.which_children()
    |> Enum.map(fn {id, pid, _type, _modules} ->
      [eth_tx_hash, tx_id, type] = String.split(to_string(id), ":")
      {eth_tx_hash, tx_id, String.to_atom(type), pid}
    end)
  end

  @impl Supervisor
  def init(_opts) do
    # Start with no children initially
    # Monitors will be added dynamically as needed
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  # Private functions

  defp monitor_id(eth_tx_hash) do
    "#{eth_tx_hash}"
  end
end
