defmodule PortfolioManager.SushiSwapAdapter do
  @moduledoc """
  Adapter for managing SushiSwap-based portfolios.
  Handles liquidity pool positions and token swaps.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias Core.Schema.Account

  # Client API

  @doc """
  Starts the SushiSwap adapter.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Gets the liquidity pool position for an account.

  ## Parameters
    * `account_id` - The account ID
    * `token0` - First token address
    * `token1` - Second token address

  Returns:
    * `{:ok, position}` - The liquidity pool position
    * `{:error, reason}` - Error with reason
  """
  def get_lp_position(account_id, token0, token1) do
    GenServer.call(__MODULE__, {:get_lp_position, account_id, token0, token1})
  end

  @doc """
  Gets the token price from SushiSwap.

  ## Parameters
    * `token0` - First token address
    * `token1` - Second token address

  Returns:
    * `{:ok, price}` - The token price
    * `{:error, reason}` - Error with reason
  """
  def get_token_price(token0, token1) do
    GenServer.call(__MODULE__, {:get_token_price, token0, token1})
  end

  @doc """
  Gets the liquidity pool reserves.

  ## Parameters
    * `token0` - First token address
    * `token1` - Second token address

  Returns:
    * `{:ok, reserves}` - The pool reserves
    * `{:error, reason}` - Error with reason
  """
  def get_pool_reserves(token0, token1) do
    GenServer.call(__MODULE__, {:get_pool_reserves, token0, token1})
  end

  @doc """
  Gets the liquidity pool reserves directly with server state.

  ## Parameters
    * `token0` - First token address
    * `token1` - Second token address
    * `state` - Server state

  Returns:
    * `{:ok, reserves}` - The pool reserves
    * `{:error, reason}` - Error with reason
  """
  def get_pool_reserves(token0, token1, state) do
    pool_address = get_pool_address(token0, token1, state)

    case pool_address do
      {:ok, address} ->
        # Simulate fetching reserves from the pool address
        # In a real implementation, this would call the smart contract
        reserve0 = :rand.uniform(1000000) * 1.0
        reserve1 = :rand.uniform(1000000) * 1.0

        {:ok, %{
          reserve0: reserve0,
          reserve1: reserve1,
          block_timestamp: System.os_time(:second)
        }}

      error ->
        error
    end
  end

  # Server callbacks

  @impl GenServer
  def init(_opts) do
    # Initialize Ethereum client
    {:ok, eth_client} = Ethereumex.HttpClient.start_link(url: get_eth_rpc_url())

    # Get SushiSwap contract addresses
    factory_address = get_sushiswap_factory_address()
    router_address = get_sushiswap_router_address()

    {:ok, %{
      eth_client: eth_client,
      factory_address: factory_address,
      router_address: router_address,
      chain_id: get_chain_id()
    }}
  end

  @impl GenServer
  def handle_call({:get_lp_position, account_id, token0, token1}, _from, state) do
    with {:ok, account} <- get_account(account_id),
         {:ok, pool_address} <- get_pool_address(token0, token1, state),
         {:ok, position} <- fetch_lp_position(account.address, pool_address, state.eth_client) do

      {:reply, {:ok, position}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get LP position: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_token_price, token0, token1}, _from, state) do
    with {:ok, reserves} <- get_pool_reserves(token0, token1, state) do
      price = calculate_price(reserves)
      {:reply, {:ok, price}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get token price: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:get_pool_reserves, token0, token1}, _from, state) do
    with {:ok, pool_address} <- get_pool_address(token0, token1, state),
         {:ok, reserves} <- fetch_pool_reserves(pool_address, state.eth_client) do

      {:reply, {:ok, reserves}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to get pool reserves: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  # Private functions

  defp get_eth_rpc_url do
    System.get_env("ETH_RPC_URL", "http://localhost:8545")
  end

  defp get_chain_id do
    # Get chain ID from environment or default to mainnet
    System.get_env("ETH_CHAIN_ID", "1") |> String.to_integer()
  end

  defp get_sushiswap_factory_address do
    System.get_env("SUSHISWAP_FACTORY_ADDRESS")
  end

  defp get_sushiswap_router_address do
    System.get_env("SUSHISWAP_ROUTER_ADDRESS")
  end

  defp get_account(account_id) do
    case Core.Repo.get(Account, account_id) do
      nil ->
        {:error, :account_not_found}

      account ->
        {:ok, account}
    end
  end

  defp get_pool_address(token0, token1, state) do
    # Prepare the getPool function call
    data = "0x1698c168" <> # getPool function signature
           String.pad_leading(String.slice(token0, 2..-1), 64, "0") <>
           String.pad_leading(String.slice(token1, 2..-1), 64, "0") <>
           "0000000000000000000000000000000000000000000000000000000000000060" <>
           "0000000000000000000000000000000000000000000000000000000000000000"

    # Call the factory contract
    case Ethereumex.HttpClient.eth_call(%{
      to: state.factory_address,
      data: data
    }, "latest") do
      {:ok, pool_address_hex} ->
        {:ok, "0x" <> String.slice(pool_address_hex, 26..-1)}

      {:error, reason} ->
        {:error, "Failed to get pool address: #{inspect(reason)}"}
    end
  end

  defp fetch_lp_position(address, pool_address, client) do
    # Prepare the positions function call
    data = "0x514fcac7" <> # positions function signature
           String.pad_leading(String.slice(address, 2..-1), 64, "0")

    # Call the pool contract
    case Ethereumex.HttpClient.eth_call(%{
      to: pool_address,
      data: data
    }, "latest") do
      {:ok, position_data} ->
        # Parse the position data
        position = parse_position_data(position_data)
        {:ok, position}

      {:error, reason} ->
        {:error, "Failed to get LP position: #{inspect(reason)}"}
    end
  end

  defp fetch_pool_reserves(pool_address, client) do
    # Prepare the getReserves function call
    data = "0x0902f1ac" # getReserves function signature

    # Call the pool contract
    case Ethereumex.HttpClient.eth_call(%{
      to: pool_address,
      data: data
    }, "latest") do
      {:ok, reserves_data} ->
        # Parse the reserves data
        reserves = parse_reserves_data(reserves_data)
        {:ok, reserves}

      {:error, reason} ->
        {:error, "Failed to get pool reserves: #{inspect(reason)}"}
    end
  end

  defp calculate_price(reserves) do
    # Calculate price based on reserves
    # Price = reserve1 / reserve0
    Decimal.div(reserves.reserve1, reserves.reserve0)
  end

  defp parse_position_data(data) do
    # Parse the position data from the contract
    # This is a simplified version - in production, you would use the actual ABI
    %{
      liquidity: String.slice(data, 2..65) |> String.to_integer(16),
      fee_growth_inside0_last_x128: String.slice(data, 66..129) |> String.to_integer(16),
      fee_growth_inside1_last_x128: String.slice(data, 130..193) |> String.to_integer(16),
      fees_earned0: String.slice(data, 194..257) |> String.to_integer(16),
      fees_earned1: String.slice(data, 258..321) |> String.to_integer(16)
    }
  end

  defp parse_reserves_data(data) do
    # Parse the reserves data from the contract
    # This is a simplified version - in production, you would use the actual ABI
    %{
      reserve0: String.slice(data, 2..65) |> String.to_integer(16),
      reserve1: String.slice(data, 66..129) |> String.to_integer(16),
      block_timestamp_last: String.slice(data, 130..193) |> String.to_integer(16)
    }
  end

  # Helper function to get pool address
  defp get_pool_address(token0, token1, _state) do
    # Simplified implementation
    # In reality, would use a factory contract to look up the pool
    {:ok, "0x" <> :crypto.strong_rand_bytes(20) |> Base.encode16(case: :lower)}
  end
end
