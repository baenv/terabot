defmodule OrderManager.Monitor.Worker do
  @moduledoc """
  Worker for monitoring Ethereum transaction confirmations.
  Tracks the status of a specific transaction and notifies when it's confirmed or failed.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub

  # Client API

  @doc """
  Starts a transaction monitor worker.

  ## Options
    * `:eth_tx_hash` - The Ethereum transaction hash to monitor
    * `:tx_id` - The internal transaction ID
    * `:type` - The type of monitoring (:normal or :cancel)
    * `:interval` - Polling interval in milliseconds (default: 5000)
    * `:max_attempts` - Maximum number of confirmation attempts (default: 120)
  """
  def start_link(opts) do
    eth_tx_hash = Keyword.fetch!(opts, :eth_tx_hash)
    tx_id = Keyword.fetch!(opts, :tx_id)
    type = Keyword.get(opts, :type, :normal)
    name = {:via, Registry, {OrderManager.Registry, {__MODULE__, eth_tx_hash, tx_id, type}}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets the current status of the monitored transaction.

  ## Parameters
    * `eth_tx_hash` - The Ethereum transaction hash
    * `tx_id` - The internal transaction ID
    * `type` - The type of monitoring (:normal or :cancel)

  Returns:
    * `{:ok, status}` - The current transaction status
    * `{:error, reason}` - Error with reason
  """
  def get_status(eth_tx_hash, tx_id, type \\ :normal) do
    case Registry.lookup(OrderManager.Registry, {__MODULE__, eth_tx_hash, tx_id, type}) do
      [{pid, _}] ->
        GenServer.call(pid, :get_status)

      [] ->
        {:error, :monitor_not_found}
    end
  end

  # Server callbacks

  @impl GenServer
  def init(opts) do
    eth_tx_hash = Keyword.fetch!(opts, :eth_tx_hash)
    tx_id = Keyword.fetch!(opts, :tx_id)
    type = Keyword.get(opts, :type, :normal)
    interval = Keyword.get(opts, :interval, 5000)
    max_attempts = Keyword.get(opts, :max_attempts, 120)

    Logger.info("Starting transaction monitor for #{eth_tx_hash} (#{type})")

    # Schedule the first status check
    schedule_status_check(interval)

    {:ok, %{
      eth_tx_hash: eth_tx_hash,
      tx_id: tx_id,
      type: type,
      interval: interval,
      max_attempts: max_attempts,
      attempts: 0,
      status: :pending,
      last_check: nil
    }}
  end

  @impl GenServer
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state.status}, state}
  end

  @impl GenServer
  def handle_info(:check_status, state) do
    # Check if we've exceeded max attempts
    if state.attempts >= state.max_attempts do
      # Stop the monitor and notify failure
      stop_monitor(state)
      {:noreply, %{state | status: :timeout}}
    else
      # Check transaction status
      new_state = check_transaction_status(state)

      # Schedule next check
      schedule_status_check(state.interval)

      {:noreply, new_state}
    end
  end

  # Private functions

  defp schedule_status_check(interval) do
    Process.send_after(self(), :check_status, interval)
  end

  defp check_transaction_status(state) do
    case Ethereumex.HttpClient.eth_get_transaction_receipt(state.eth_tx_hash) do
      {:ok, nil} ->
        # Transaction not yet mined
        %{state | attempts: state.attempts + 1, last_check: DateTime.utc_now()}

      {:ok, receipt} ->
        # Transaction mined, check status
        if receipt["status"] == "0x1" do
          # Transaction successful
          stop_monitor(state)
          notify_success(state)
          %{state | status: :confirmed, last_check: DateTime.utc_now()}
        else
          # Transaction failed
          stop_monitor(state)
          notify_failure(state, "Transaction failed")
          %{state | status: :failed, last_check: DateTime.utc_now()}
        end

      {:error, reason} ->
        Logger.error("Failed to get transaction receipt: #{inspect(reason)}")
        %{state | attempts: state.attempts + 1, last_check: DateTime.utc_now()}
    end
  end

  defp stop_monitor(state) do
    # Stop the monitor process
    Process.send_after(self(), :stop, 0)
  end

  defp notify_success(state) do
    # Broadcast transaction confirmation
    PubSub.broadcast(
      OrderManager.PubSub,
      "transactions",
      {:transaction_confirmed, state.tx_id, state.eth_tx_hash}
    )
  end

  defp notify_failure(state, reason) do
    # Broadcast transaction failure
    PubSub.broadcast(
      OrderManager.PubSub,
      "transactions",
      {:transaction_failed, state.tx_id, state.eth_tx_hash, reason}
    )
  end
end
