defmodule OrderManager.TransactionManager do
  @moduledoc """
  Manages Ethereum transactions for trading operations.
  Handles transaction preparation, submission, and confirmation tracking.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias Core.Schema.Transaction
  alias Core.Repo

  # Client API

  @doc """
  Starts the transaction manager.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Submits a transaction for execution.

  ## Parameters
    * `tx_params` - Map with transaction parameters:
      * `:account_id` - ID of the account/wallet to use
      * `:tx_type` - Type of transaction (e.g., :buy, :sell, :approve)
      * `:dex` - DEX to use (e.g., :uniswap, :sushiswap)
      * `:base_asset` - Base asset symbol (e.g., "ETH")
      * `:quote_asset` - Quote asset symbol (e.g., "USDT")
      * `:amount` - Amount of base asset to trade
      * `:price` - Target price (optional for market orders)
      * `:slippage` - Maximum acceptable slippage percentage (default: 0.5)
      * `:gas_priority` - Gas priority level (:low, :medium, :high)

  Returns:
    * `{:ok, tx_id}` - The ID of the submitted transaction
    * `{:error, reason}` - Error with reason
  """
  def submit_transaction(tx_params) do
    GenServer.call(__MODULE__, {:submit_transaction, tx_params})
  end

  @doc """
  Gets the status of a transaction.

  ## Parameters
    * `tx_id` - The transaction ID

  Returns:
    * `{:ok, status}` - The transaction status
    * `{:error, reason}` - Error with reason
  """
  def get_transaction_status(tx_id) do
    GenServer.call(__MODULE__, {:get_transaction_status, tx_id})
  end

  @doc """
  Cancels a pending transaction if possible.

  ## Parameters
    * `tx_id` - The transaction ID

  Returns:
    * `{:ok, :cancelled}` - The transaction was cancelled
    * `{:ok, :cancellation_submitted}` - Cancellation transaction submitted
    * `{:error, reason}` - Error with reason
  """
  def cancel_transaction(tx_id) do
    GenServer.call(__MODULE__, {:cancel_transaction, tx_id})
  end

  @doc """
  Speed up a pending transaction by increasing gas price.

  ## Parameters
    * `tx_id` - The transaction ID

  Returns:
    * `{:ok, new_tx_id}` - ID of the new transaction with higher gas
    * `{:error, reason}` - Error with reason
  """
  def speed_up_transaction(tx_id) do
    GenServer.call(__MODULE__, {:speed_up_transaction, tx_id})
  end

  # Server callbacks

  @impl GenServer
  def init(_opts) do
    # Initialize transaction tracking state
    {:ok, %{
      transactions: %{}, # Map of transaction_id => transaction data
      pending_confirmations: %{} # Map of eth_tx_hash => transaction_id
    }}
  end

  @impl GenServer
  def handle_call({:submit_transaction, tx_params}, _from, state) do
    # Validate transaction parameters
    with :ok <- validate_tx_params(tx_params),
         # Get the account/wallet
         {:ok, account} <- get_account(tx_params.account_id),
         # Prepare the transaction
         {:ok, eth_tx} <- prepare_transaction(tx_params, account),
         # Create transaction record
         {:ok, tx_record} <- create_transaction_record(tx_params, eth_tx),
         # Execute the transaction
         {:ok, eth_tx_hash} <- execute_transaction(eth_tx, account) do

      # Update state
      transactions = Map.put(state.transactions, tx_record.id, %{
        record: tx_record,
        eth_tx_hash: eth_tx_hash,
        status: :pending,
        submitted_at: DateTime.utc_now()
      })

      pending_confirmations = Map.put(state.pending_confirmations, eth_tx_hash, tx_record.id)

      # Start a monitor process for this transaction
      {:ok, _pid} = OrderManager.Monitor.Supervisor.start_monitor(eth_tx_hash, tx_record.id)

      # Broadcast transaction submission
      PubSub.broadcast(
        OrderManager.PubSub,
        "transactions",
        {:transaction_submitted, tx_record.id, eth_tx_hash}
      )

      {:reply, {:ok, tx_record.id}, %{state |
        transactions: transactions,
        pending_confirmations: pending_confirmations
      }}
    else
      {:error, reason} = error ->
        Logger.error("Failed to submit transaction: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_transaction_status, tx_id}, _from, state) do
    case Map.get(state.transactions, tx_id) do
      nil ->
        # Transaction not found in memory, check database
        case Repo.get(Transaction, tx_id) do
          nil ->
            {:reply, {:error, :not_found}, state}

          tx_record ->
            {:reply, {:ok, tx_record.status}, state}
        end

      tx_data ->
        {:reply, {:ok, tx_data.status}, state}
    end
  end

  @impl GenServer
  def handle_call({:cancel_transaction, tx_id}, _from, state) do
    case Map.get(state.transactions, tx_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      tx_data ->
        case tx_data.status do
          :pending ->
            # Attempt to cancel the transaction
            # For Ethereum, this means submitting a zero-value transaction with the same nonce
            # but higher gas price to replace the original transaction
            case cancel_ethereum_transaction(tx_data.eth_tx_hash, tx_data.record) do
              {:ok, cancel_tx_hash} ->
                # Update transaction status
                updated_tx_data = %{tx_data | status: :cancelling}
                transactions = Map.put(state.transactions, tx_id, updated_tx_data)

                # Add the cancellation transaction to pending confirmations
                pending_confirmations = Map.put(
                  state.pending_confirmations,
                  cancel_tx_hash,
                  "cancel:#{tx_id}"
                )

                # Start a monitor process for the cancellation transaction
                {:ok, _pid} = OrderManager.Monitor.Supervisor.start_monitor(
                  cancel_tx_hash,
                  tx_id,
                  :cancel
                )

                # Broadcast cancellation attempt
                PubSub.broadcast(
                  OrderManager.PubSub,
                  "transactions",
                  {:transaction_cancellation, tx_id, cancel_tx_hash}
                )

                {:reply, {:ok, :cancellation_submitted}, %{state |
                  transactions: transactions,
                  pending_confirmations: pending_confirmations
                }}

              {:error, reason} = error ->
                Logger.error("Failed to cancel transaction #{tx_id}: #{inspect(reason)}")
                {:reply, error, state}
            end

          _other_status ->
            {:reply, {:error, "Cannot cancel transaction with status: #{tx_data.status}"}, state}
        end
    end
  end

  @impl GenServer
  def handle_call({:speed_up_transaction, tx_id}, _from, state) do
    case Map.get(state.transactions, tx_id) do
      nil ->
        {:reply, {:error, :not_found}, state}

      tx_data ->
        case tx_data.status do
          :pending ->
            # Attempt to speed up the transaction
            # For Ethereum, this means submitting an identical transaction with the same nonce
            # but higher gas price
            case speed_up_ethereum_transaction(tx_data.eth_tx_hash, tx_data.record) do
              {:ok, new_tx_hash} ->
                # Update transaction hash
                updated_tx_data = %{tx_data | eth_tx_hash: new_tx_hash}
                transactions = Map.put(state.transactions, tx_id, updated_tx_data)

                # Update pending confirmations
                pending_confirmations = state.pending_confirmations
                |> Map.delete(tx_data.eth_tx_hash)
                |> Map.put(new_tx_hash, tx_id)

                # Start a monitor process for the new transaction
                {:ok, _pid} = OrderManager.Monitor.Supervisor.start_monitor(
                  new_tx_hash,
                  tx_id
                )

                # Broadcast speed-up
                PubSub.broadcast(
                  OrderManager.PubSub,
                  "transactions",
                  {:transaction_speed_up, tx_id, new_tx_hash}
                )

                {:reply, {:ok, tx_id}, %{state |
                  transactions: transactions,
                  pending_confirmations: pending_confirmations
                }}

              {:error, reason} = error ->
                Logger.error("Failed to speed up transaction #{tx_id}: #{inspect(reason)}")
                {:reply, error, state}
            end

          _other_status ->
            {:reply, {:error, "Cannot speed up transaction with status: #{tx_data.status}"}, state}
        end
    end
  end

  @impl GenServer
  def handle_info({:transaction_confirmed, eth_tx_hash}, state) do
    case Map.get(state.pending_confirmations, eth_tx_hash) do
      nil ->
        # Unknown transaction, ignore
        {:noreply, state}

      "cancel:" <> tx_id ->
        # Cancellation transaction confirmed
        case Map.get(state.transactions, tx_id) do
          nil ->
            {:noreply, state}

          tx_data ->
            # Update transaction status
            updated_tx_data = %{tx_data | status: :cancelled}
            transactions = Map.put(state.transactions, tx_id, updated_tx_data)

            # Update transaction record in database
            update_transaction_status(tx_id, :cancelled)

            # Broadcast cancellation
            PubSub.broadcast(
              OrderManager.PubSub,
              "transactions",
              {:transaction_cancelled, tx_id}
            )

            # Remove from pending confirmations
            pending_confirmations = Map.delete(state.pending_confirmations, eth_tx_hash)

            {:noreply, %{state |
              transactions: transactions,
              pending_confirmations: pending_confirmations
            }}
        end

      tx_id ->
        # Regular transaction confirmed
        case Map.get(state.transactions, tx_id) do
          nil ->
            {:noreply, state}

          tx_data ->
            # Update transaction status
            updated_tx_data = %{tx_data | status: :confirmed}
            transactions = Map.put(state.transactions, tx_id, updated_tx_data)

            # Update transaction record in database
            update_transaction_status(tx_id, :confirmed)

            # Broadcast confirmation
            PubSub.broadcast(
              OrderManager.PubSub,
              "transactions",
              {:transaction_confirmed, tx_id, eth_tx_hash}
            )

            # Remove from pending confirmations
            pending_confirmations = Map.delete(state.pending_confirmations, eth_tx_hash)

            {:noreply, %{state |
              transactions: transactions,
              pending_confirmations: pending_confirmations
            }}
        end
    end
  end

  @impl GenServer
  def handle_info({:transaction_failed, eth_tx_hash, reason}, state) do
    case Map.get(state.pending_confirmations, eth_tx_hash) do
      nil ->
        # Unknown transaction, ignore
        {:noreply, state}

      "cancel:" <> tx_id ->
        # Cancellation transaction failed
        case Map.get(state.transactions, tx_id) do
          nil ->
            {:noreply, state}

          tx_data ->
            # Revert transaction status to pending
            updated_tx_data = %{tx_data | status: :pending}
            transactions = Map.put(state.transactions, tx_id, updated_tx_data)

            # Broadcast cancellation failure
            PubSub.broadcast(
              OrderManager.PubSub,
              "transactions",
              {:cancellation_failed, tx_id, reason}
            )

            # Remove from pending confirmations
            pending_confirmations = Map.delete(state.pending_confirmations, eth_tx_hash)

            {:noreply, %{state |
              transactions: transactions,
              pending_confirmations: pending_confirmations
            }}
        end

      tx_id ->
        # Regular transaction failed
        case Map.get(state.transactions, tx_id) do
          nil ->
            {:noreply, state}

          tx_data ->
            # Update transaction status
            updated_tx_data = %{tx_data | status: :failed}
            transactions = Map.put(state.transactions, tx_id, updated_tx_data)

            # Update transaction record in database
            update_transaction_status(tx_id, :failed, reason)

            # Broadcast failure
            PubSub.broadcast(
              OrderManager.PubSub,
              "transactions",
              {:transaction_failed, tx_id, reason}
            )

            # Remove from pending confirmations
            pending_confirmations = Map.delete(state.pending_confirmations, eth_tx_hash)

            {:noreply, %{state |
              transactions: transactions,
              pending_confirmations: pending_confirmations
            }}
        end
    end
  end

  # Private functions

  defp validate_tx_params(params) do
    required_fields = [:account_id, :tx_type, :base_asset, :quote_asset, :amount]

    missing_fields = Enum.filter(required_fields, fn field ->
      not Map.has_key?(params, field)
    end)

    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, "Missing required fields: #{inspect(missing_fields)}"}
    end
  end

  defp get_account(account_id) do
    case Core.Repo.get(Core.Schema.Account, account_id) do
      nil ->
        {:error, :account_not_found}

      account ->
        {:ok, account}
    end
  end

  defp prepare_transaction(tx_params, account) do
    # Delegate to the EthereumOrderExecutor for transaction preparation
    OrderManager.EthereumOrderExecutor.prepare_transaction(tx_params, account)
  end

  defp create_transaction_record(tx_params, eth_tx) do
    # Create a transaction record in the database
    attrs = %{
      account_id: tx_params.account_id,
      tx_type: tx_params.tx_type,
      base_asset: tx_params.base_asset,
      quote_asset: tx_params.quote_asset,
      amount: tx_params.amount,
      price: Map.get(tx_params, :price),
      status: :pending,
      dex: Map.get(tx_params, :dex, :uniswap),
      gas_price: eth_tx.gas_price,
      gas_limit: eth_tx.gas_limit,
      nonce: eth_tx.nonce,
      metadata: %{
        eth_to: eth_tx.to,
        eth_data: eth_tx.data,
        eth_value: eth_tx.value,
        slippage: Map.get(tx_params, :slippage, 0.5)
      }
    }

    changeset = Transaction.changeset(%Transaction{}, attrs)
    Core.Repo.insert(changeset)
  end

  defp execute_transaction(eth_tx, account) do
    # Delegate to the EthereumOrderExecutor for transaction execution
    OrderManager.EthereumOrderExecutor.execute_transaction(eth_tx, account)
  end

  defp cancel_ethereum_transaction(eth_tx_hash, tx_record) do
    # Delegate to the EthereumOrderExecutor for transaction cancellation
    OrderManager.EthereumOrderExecutor.cancel_transaction(eth_tx_hash, tx_record)
  end

  defp speed_up_ethereum_transaction(eth_tx_hash, tx_record) do
    # Delegate to the EthereumOrderExecutor for transaction speed-up
    OrderManager.EthereumOrderExecutor.speed_up_transaction(eth_tx_hash, tx_record)
  end

  defp update_transaction_status(tx_id, status, reason \\ nil) do
    case Core.Repo.get(Transaction, tx_id) do
      nil ->
        {:error, :not_found}

      tx_record ->
        metadata = if reason do
          Map.put(tx_record.metadata || %{}, :failure_reason, reason)
        else
          tx_record.metadata
        end

        changeset = Transaction.changeset(tx_record, %{status: status, metadata: metadata})
        Core.Repo.update(changeset)
    end
  end
end
