defmodule DataCollector.EthereumWorker do
  @moduledoc """
  Worker for collecting Ethereum blockchain data.
  Connects to Ethereum nodes to gather real-time block data,
  transaction information, and events from smart contracts.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub

  # Client API

  @doc """
  Starts the Ethereum data collector worker.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the latest Ethereum block.
  """
  def get_latest_block do
    GenServer.call(__MODULE__, :get_latest_block)
  end

  @doc """
  Gets the latest gas price.
  """
  def get_gas_price do
    GenServer.call(__MODULE__, :get_gas_price)
  end

  @doc """
  Gets transaction information by hash.
  """
  def get_transaction(tx_hash) do
    GenServer.call(__MODULE__, {:get_transaction, tx_hash})
  end

  # Server callbacks

  @impl GenServer
  def init(_opts) do
    # Initialize the worker state
    # In a production environment, we would establish a WebSocket connection
    # to an Ethereum node. For development, we'll start with a periodic poll.

    # Get the Ethereum RPC URL
    eth_rpc_url = get_eth_rpc_url()
    Logger.info("Initializing Ethereum Worker with RPC URL: #{eth_rpc_url}")

    # Schedule the first data collection
    schedule_data_collection()

    {:ok, %{
      latest_block: nil,
      latest_gas_price: nil,
      transactions: %{},
      eth_rpc_url: eth_rpc_url,
      connection_attempts: 0
    }}
  end

  @impl GenServer
  def handle_call(:get_latest_block, _from, state) do
    {:reply, {:ok, state.latest_block}, state}
  end

  @impl GenServer
  def handle_call(:get_gas_price, _from, state) do
    {:reply, {:ok, state.latest_gas_price}, state}
  end

  @impl GenServer
  def handle_call({:get_transaction, tx_hash}, _from, state) do
    case Map.get(state.transactions, tx_hash) do
      nil ->
        # Transaction not in local cache, fetch from node
        case fetch_transaction(tx_hash, state.eth_rpc_url) do
          {:ok, tx_data} ->
            # Update transactions cache
            updated_transactions = Map.put(state.transactions, tx_hash, tx_data)
            {:reply, {:ok, tx_data}, %{state | transactions: updated_transactions}}

          {:error, reason} = error ->
            Logger.error("Failed to fetch transaction #{tx_hash}: #{reason}")
            {:reply, error, state}
        end

      tx_data ->
        # Return cached transaction data
        {:reply, {:ok, tx_data}, state}
    end
  end

  @impl GenServer
  def handle_info(:collect_data, state) do
    # Collect latest block data
    new_state = collect_ethereum_data(state)

    # Schedule next data collection
    schedule_data_collection()

    {:noreply, new_state}
  end

  # Private functions

  defp schedule_data_collection do
    # Schedule data collection every 15 seconds
    # In production, use WebSocket subscription for real-time updates
    Process.send_after(self(), :collect_data, 15_000)
  end

  defp collect_ethereum_data(state) do
    # Collect latest block
    with {:ok, latest_block} <- fetch_latest_block(state.eth_rpc_url),
         {:ok, gas_price} <- fetch_gas_price(state.eth_rpc_url) do

      # Broadcast updates if there are changes
      if latest_block != state.latest_block do
        block_number = latest_block["number"]
        Logger.info("New Ethereum block received: #{block_number}")
        PubSub.broadcast(DataCollector.PubSub, "ethereum:blocks", {:new_block, latest_block})
      end

      if gas_price != state.latest_gas_price do
        gas_price_gwei = gas_price / 1_000_000_000
        Logger.info("Gas price updated: #{gas_price_gwei} Gwei")
        PubSub.broadcast(DataCollector.PubSub, "ethereum:gas", {:gas_price_update, gas_price})
      end

      # Reset connection attempts on success
      %{state | latest_block: latest_block, latest_gas_price: gas_price, connection_attempts: 0}
    else
      {:error, reason} ->
        # Increment connection attempt counter
        attempts = state.connection_attempts + 1

        # If we've hit a lot of errors, log at warning level instead of error to reduce noise
        if attempts <= 5 do
          Logger.error("Failed to collect Ethereum data: #{reason} (attempt #{attempts})")
        else
          # Only log every 10th error after the first 5 to reduce log spam
          if rem(attempts, 10) == 0 do
            Logger.warn("Still unable to connect to Ethereum node after #{attempts} attempts: #{reason}")
          end
        end

        %{state | connection_attempts: attempts}
    end
  end

  defp fetch_latest_block(rpc_url) do
    # Make RPC call to get latest block
    # This is a simplified implementation
    case make_rpc_call(rpc_url, "eth_blockNumber", []) do
      {:ok, result} ->
        # Parse the result (hex string to integer)
        block_number = String.replace_prefix(result, "0x", "") |> String.to_integer(16)

        # Fetch block details
        case make_rpc_call(rpc_url, "eth_getBlockByNumber", ["0x" <> Integer.to_string(block_number, 16), false]) do
          {:ok, block_data} ->
            {:ok, block_data}

          {:error, reason} = error ->
            Logger.error("Failed to fetch block details: #{reason}")
            error
        end

      {:error, reason} = error ->
        Logger.error("Failed to fetch latest block number: #{reason}")
        error
    end
  end

  defp fetch_gas_price(rpc_url) do
    # Make RPC call to get gas price
    case make_rpc_call(rpc_url, "eth_gasPrice", []) do
      {:ok, result} ->
        # Parse the result (hex string to integer)
        gas_price = String.replace_prefix(result, "0x", "") |> String.to_integer(16)
        {:ok, gas_price}

      {:error, reason} = error ->
        Logger.error("Failed to fetch gas price: #{reason}")
        error
    end
  end

  defp fetch_transaction(tx_hash, rpc_url) do
    # Make RPC call to get transaction details
    case make_rpc_call(rpc_url, "eth_getTransactionByHash", [tx_hash]) do
      {:ok, nil} ->
        {:error, :transaction_not_found}

      {:ok, tx_data} ->
        {:ok, tx_data}

      {:error, reason} = error ->
        Logger.error("Failed to fetch transaction: #{reason}")
        error
    end
  end

  defp make_rpc_call(url, method, params) do
    # Make JSON-RPC call to Ethereum node
    # In a real implementation, use a proper HTTP client with error handling
    # For this example, we'll use a simplified approach

    payload = %{
      jsonrpc: "2.0",
      method: method,
      params: params,
      id: :os.system_time(:millisecond)
    }

    case HTTPoison.post(url, Jason.encode!(payload), [{"Content-Type", "application/json"}]) do
      {:ok, %{status_code: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"result" => result}} ->
            {:ok, result}

          {:ok, %{"error" => %{"message" => message}}} ->
            {:error, message}

          {:error, %Jason.DecodeError{} = error} ->
            {:error, "JSON decode error: #{inspect(error)}"}
        end

      {:ok, %{status_code: status_code}} ->
        {:error, "HTTP error: #{status_code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "HTTP request error: #{inspect(reason)}"}
    end
  end

  defp get_eth_rpc_url do
    # Get Ethereum RPC URL from environment variables
    # Default to a local development node if not configured
    primary_url = System.get_env("ETH_RPC_URL")

    if primary_url do
      primary_url
    else
      # Fallback to these public endpoints if no environment variable is set
      # These are free public endpoints that may have rate limits
      fallback_urls = [
        "https://eth.llamarpc.com",
        "https://rpc.ankr.com/eth",
        "https://ethereum.publicnode.com"
      ]

      # Choose a random fallback URL
      fallback_url = Enum.random(fallback_urls)
      Logger.warn("No ETH_RPC_URL environment variable found, using fallback: #{fallback_url}")
      fallback_url
    end
  end
end
