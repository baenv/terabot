defmodule PortfolioManager.EthereumAdapter do
  @moduledoc """
  Adapter for managing Ethereum-based portfolios.
  Handles ETH balance tracking and transaction monitoring.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias Core.Vault.KeyVault
  alias Core.Schema.Account

  # Client API

  @doc """
  Starts the Ethereum adapter.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the ETH balance for an account.

  ## Parameters
    * `account_id` - The account ID

  Returns:
    * `{:ok, balance}` - The ETH balance in Wei
    * `{:error, reason}` - Error with reason
  """
  def get_balance(account_id) do
    GenServer.call(__MODULE__, {:get_balance, account_id})
  end

  @doc """
  Gets the token balance for an account.

  ## Parameters
    * `account_id` - The account ID
    * `token_address` - The token contract address

  Returns:
    * `{:ok, balance}` - The token balance
    * `{:error, reason}` - Error with reason
  """
  def get_token_balance(account_id, token_address) do
    GenServer.call(__MODULE__, {:get_token_balance, account_id, token_address})
  end

  @doc """
  Gets the transaction history for an account.

  ## Parameters
    * `account_id` - The account ID
    * `limit` - Maximum number of transactions to return (default: 100)

  Returns:
    * `{:ok, transactions}` - List of transactions
    * `{:error, reason}` - Error with reason
  """
  def get_transaction_history(account_id, limit \\ 100) do
    GenServer.call(__MODULE__, {:get_transaction_history, account_id, limit})
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Ethereum HTTP client is configured via the application env
    # no need to start it explicitly as it's just a module with functions

    {:ok, %{
      subscribed: false,
      balances: %{},
      transactions: %{},
      positions: %{},
      # Default to an empty list of DEX adapters until they're configured
      dex_adapters: []
    }}
  end

  @impl GenServer
  def handle_call({:get_balance, account_id}, _from, state) do
    with {:ok, account} <- get_account(account_id),
         {:ok, balance} <- fetch_balance(account.address, state.eth_client) do

      # Update cached balance
      accounts = Map.put(state.accounts, account_id, balance)

      {:reply, {:ok, balance}, %{state | accounts: accounts}}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get ETH balance: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_token_balance, account_id, token_address}, _from, state) do
    with {:ok, account} <- get_account(account_id),
         {:ok, balance} <- fetch_token_balance(account.address, token_address, state.eth_client) do

      {:reply, {:ok, balance}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get token balance: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_transaction_history, account_id, limit}, _from, state) do
    with {:ok, account} <- get_account(account_id),
         {:ok, transactions} <- fetch_transaction_history(account.address, limit, state.eth_client) do

      {:reply, {:ok, transactions}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get transaction history: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_info({:new_block, block}, state) do
    # Check balances for all tracked accounts
    new_state = check_account_balances(state)

    {:noreply, new_state}
  end

  # Private functions

  defp get_eth_rpc_url do
    System.get_env("ETH_RPC_URL", "http://localhost:8545")
  end

  defp get_chain_id do
    # Get chain ID from environment or default to mainnet
    System.get_env("ETH_CHAIN_ID", "1") |> String.to_integer()
  end

  defp get_account(account_id) do
    case Core.Repo.get(Account, account_id) do
      nil ->
        {:error, :account_not_found}

      account ->
        {:ok, account}
    end
  end

  defp fetch_balance(address, client) do
    case Ethereumex.HttpClient.eth_get_balance(address, "latest") do
      {:ok, balance_hex} ->
        {:ok, String.replace_prefix(balance_hex, "0x", "") |> String.to_integer(16)}

      {:error, reason} ->
        {:error, "Failed to get balance: #{inspect(reason)}"}
    end
  end

  defp fetch_token_balance(address, token_address, client) do
    # Prepare the balanceOf function call
    data = "0x70a08231000000000000000000000000" <> String.slice(address, 2..-1)

    # Call the token contract
    case Ethereumex.HttpClient.eth_call(%{
      to: token_address,
      data: data
    }, "latest") do
      {:ok, balance_hex} ->
        {:ok, String.replace_prefix(balance_hex, "0x", "") |> String.to_integer(16)}

      {:error, reason} ->
        {:error, "Failed to get token balance: #{inspect(reason)}"}
    end
  end

  defp fetch_transaction_history(address, limit, client) do
    # Get the latest block number
    case Ethereumex.HttpClient.eth_block_number() do
      {:ok, block_number_hex} ->
        block_number = String.replace_prefix(block_number_hex, "0x", "") |> String.to_integer(16)

        # Get transactions for the last N blocks
        transactions = get_transactions_for_blocks(address, block_number - limit, block_number, client)
        {:ok, transactions}

      {:error, reason} ->
        {:error, "Failed to get block number: #{inspect(reason)}"}
    end
  end

  defp get_transactions_for_blocks(address, from_block, to_block, client) do
    # Get transaction receipts for the address
    case Ethereumex.HttpClient.eth_get_logs(%{
      address: address,
      fromBlock: "0x" <> Integer.to_string(from_block, 16),
      toBlock: "0x" <> Integer.to_string(to_block, 16)
    }) do
      {:ok, logs} ->
        # Process logs into transactions
        Enum.map(logs, fn log ->
          %{
            block_number: String.replace_prefix(log["blockNumber"], "0x", "") |> String.to_integer(16),
            transaction_hash: log["transactionHash"],
            from: log["from"],
            to: log["to"],
            value: String.replace_prefix(log["data"], "0x", "") |> String.to_integer(16)
          }
        end)

      {:error, reason} ->
        Logger.error("Failed to get transaction logs: #{inspect(reason)}")
        []
    end
  end

  defp check_account_balances(state) do
    # Check balances for all tracked accounts
    Enum.reduce(state.accounts, state, fn {account_id, _last_balance}, acc ->
      case get_balance(account_id) do
        {:ok, new_balance} ->
          # If balance changed, broadcast update
          if new_balance != acc.accounts[account_id] do
            PubSub.broadcast(
              PortfolioManager.PubSub,
              "portfolio:balance",
              {:balance_updated, account_id, new_balance}
            )
          end

          # Update cached balance
          accounts = Map.put(acc.accounts, account_id, new_balance)
          %{acc | accounts: accounts}

        {:error, reason} ->
          Logger.error("Failed to check balance for account #{account_id}: #{inspect(reason)}")
          acc
      end
    end)
  end

  defp subscribe_to_blocks do
    # Subscribe to new blocks from the Ethereum node
    # This is a simplified version - in production, you would use WebSocket subscription
    Process.send_after(self(), :subscribe, 1000)
  end

  @impl GenServer
  def handle_info(:subscribe, state) do
    # Schedule next block check
    Process.send_after(self(), {:new_block, %{}}, 15000)

    {:noreply, state}
  end
end
