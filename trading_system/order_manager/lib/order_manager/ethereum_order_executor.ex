defmodule OrderManager.EthereumOrderExecutor do
  @moduledoc """
  Executes Ethereum transactions for trading operations.
  Handles transaction preparation, signing, and submission to the Ethereum network.
  """

  use GenServer
  require Logger
  alias Core.Vault.KeyVault
  alias Core.Schema.Account

  # Client API

  @doc """
  Starts the Ethereum order executor.
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Prepares a transaction for execution.

  ## Parameters
    * `tx_params` - Map with transaction parameters
    * `account` - The account to use for the transaction

  Returns:
    * `{:ok, eth_tx}` - The prepared Ethereum transaction
    * `{:error, reason}` - Error with reason
  """
  def prepare_transaction(tx_params, account) do
    GenServer.call(__MODULE__, {:prepare_transaction, tx_params, account})
  end

  @doc """
  Executes a prepared transaction.

  ## Parameters
    * `eth_tx` - The prepared Ethereum transaction
    * `account` - The account to use for the transaction

  Returns:
    * `{:ok, tx_hash}` - The transaction hash
    * `{:error, reason}` - Error with reason
  """
  def execute_transaction(eth_tx, account) do
    GenServer.call(__MODULE__, {:execute_transaction, eth_tx, account})
  end

  @doc """
  Cancels a pending transaction.

  ## Parameters
    * `eth_tx_hash` - The hash of the transaction to cancel
    * `tx_record` - The transaction record

  Returns:
    * `{:ok, cancel_tx_hash}` - The cancellation transaction hash
    * `{:error, reason}` - Error with reason
  """
  def cancel_transaction(eth_tx_hash, tx_record) do
    GenServer.call(__MODULE__, {:cancel_transaction, eth_tx_hash, tx_record})
  end

  @doc """
  Speeds up a pending transaction.

  ## Parameters
    * `eth_tx_hash` - The hash of the transaction to speed up
    * `tx_record` - The transaction record

  Returns:
    * `{:ok, new_tx_hash}` - The new transaction hash
    * `{:error, reason}` - Error with reason
  """
  def speed_up_transaction(eth_tx_hash, tx_record) do
    GenServer.call(__MODULE__, {:speed_up_transaction, eth_tx_hash, tx_record})
  end

  # Server callbacks

  @impl GenServer
  def init(_opts) do
    # Ethereum HTTP client is configured via the application env
    # no need to start it explicitly as it's just a module with functions

    {:ok, %{
      chain_id: get_chain_id()
    }}
  end

  @impl GenServer
  def handle_call({:prepare_transaction, tx_params, account}, _from, state) do
    with {:ok, nonce} <- get_nonce(account.address, nil),
         {:ok, gas_price} <- get_gas_price(nil),
         {:ok, gas_limit} <- estimate_gas_limit(tx_params, account, nil),
         {:ok, tx_data} <- prepare_tx_data(tx_params, account) do

      eth_tx = %{
        from: account.address,
        to: tx_data.to,
        value: tx_data.value,
        data: tx_data.data,
        nonce: nonce,
        gas_price: gas_price,
        gas_limit: gas_limit,
        chain_id: state.chain_id
      }

      {:reply, {:ok, eth_tx}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to prepare transaction: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:execute_transaction, eth_tx, account}, _from, state) do
    with {:ok, private_key} <- KeyVault.get_private_key(account.id),
         {:ok, signed_tx} <- sign_transaction(eth_tx, private_key),
         {:ok, tx_hash} <- submit_transaction(signed_tx, nil) do

      {:reply, {:ok, tx_hash}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to execute transaction: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:cancel_transaction, eth_tx_hash, tx_record}, _from, state) do
    with {:ok, account} <- get_account(tx_record.account_id),
         {:ok, nonce} <- get_nonce(account.address, nil),
         {:ok, gas_price} <- get_gas_price(nil),
         {:ok, cancel_tx} <- prepare_cancel_tx(account, nonce, gas_price, state.chain_id),
         {:ok, private_key} <- KeyVault.get_private_key(account.id),
         {:ok, signed_tx} <- sign_transaction(cancel_tx, private_key),
         {:ok, tx_hash} <- submit_transaction(signed_tx, nil) do

      {:reply, {:ok, tx_hash}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to cancel transaction: #{inspect(reason)}")
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:speed_up_transaction, eth_tx_hash, tx_record}, _from, state) do
    with {:ok, account} <- get_account(tx_record.account_id),
         {:ok, gas_price} <- get_gas_price(nil),
         {:ok, speed_up_tx} <- prepare_speed_up_tx(tx_record, gas_price, state.chain_id),
         {:ok, private_key} <- KeyVault.get_private_key(account.id),
         {:ok, signed_tx} <- sign_transaction(speed_up_tx, private_key),
         {:ok, tx_hash} <- submit_transaction(signed_tx, nil) do

      {:reply, {:ok, tx_hash}, state}
    else
      {:error, reason} = error ->
        Logger.error("Failed to speed up transaction: #{inspect(reason)}")
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

  defp get_nonce(address, client) do
    case Ethereumex.HttpClient.eth_get_transaction_count(address, "latest") do
      {:ok, nonce_hex} ->
        {:ok, String.replace_prefix(nonce_hex, "0x", "") |> String.to_integer(16)}

      {:error, reason} ->
        {:error, "Failed to get nonce: #{inspect(reason)}"}
    end
  end

  defp get_gas_price(client) do
    case Ethereumex.HttpClient.eth_gas_price() do
      {:ok, gas_price_hex} ->
        {:ok, String.replace_prefix(gas_price_hex, "0x", "") |> String.to_integer(16)}

      {:error, reason} ->
        {:error, "Failed to get gas price: #{inspect(reason)}"}
    end
  end

  defp estimate_gas_limit(tx_params, account, client) do
    # Prepare a transaction for gas estimation
    tx = %{
      from: account.address,
      to: get_contract_address(tx_params),
      value: "0x0",
      data: get_contract_data(tx_params)
    }

    case Ethereumex.HttpClient.eth_estimate_gas(tx) do
      {:ok, gas_limit_hex} ->
        {:ok, String.replace_prefix(gas_limit_hex, "0x", "") |> String.to_integer(16)}

      {:error, reason} ->
        {:error, "Failed to estimate gas limit: #{inspect(reason)}"}
    end
  end

  @doc """
  Get contract address from transaction parameters.

  ## Parameters
    * `tx_params` - Map with transaction parameters

  Returns:
    * The contract address to interact with
  """
  defp get_contract_address(tx_params) do
    case tx_params.tx_type do
      :buy -> get_dex_contract_address(tx_params.dex)
      :sell -> get_dex_contract_address(tx_params.dex)
      :approve -> tx_params.token_address
      _ -> tx_params.to || raise "Missing contract address in transaction parameters"
    end
  end

  @doc """
  Get contract data (ABI-encoded function call) from transaction parameters.

  ## Parameters
    * `tx_params` - Map with transaction parameters

  Returns:
    * The ABI-encoded function call data
  """
  defp get_contract_data(tx_params) do
    case tx_params.tx_type do
      :buy ->
        encode_swap_function(
          tx_params.recipient || tx_params.from,
          tx_params.amount,
          tx_params.price,
          tx_params.slippage
        )
      :sell ->
        encode_swap_function(
          tx_params.recipient || tx_params.from,
          tx_params.amount,
          tx_params.price,
          tx_params.slippage
        )
      :approve ->
        encode_approve_function(
          tx_params.spender,
          tx_params.amount
        )
      _ ->
        tx_params.data || "0x"
    end
  end

  defp prepare_tx_data(tx_params, account) do
    # Prepare transaction data based on the type
    case tx_params.tx_type do
      :buy ->
        prepare_buy_tx(tx_params, account)

      :sell ->
        prepare_sell_tx(tx_params, account)

      :approve ->
        prepare_approve_tx(tx_params, account)

      _ ->
        {:error, "Unsupported transaction type: #{tx_params.tx_type}"}
    end
  end

  defp prepare_buy_tx(tx_params, account) do
    # Get the DEX contract address
    contract_address = get_dex_contract_address(tx_params.dex)

    # Prepare the swap function call
    data = encode_swap_function(
      account.address, # recipient
      tx_params.amount, # amount in
      tx_params.price, # amount out min
      tx_params.slippage # slippage tolerance
    )

    {:ok, %{
      to: contract_address,
      value: "0x0", # No ETH value for token swaps
      data: data
    }}
  end

  defp prepare_sell_tx(tx_params, account) do
    # Similar to buy but with reversed token order
    contract_address = get_dex_contract_address(tx_params.dex)

    data = encode_swap_function(
      account.address,
      tx_params.amount,
      tx_params.price,
      tx_params.slippage
    )

    {:ok, %{
      to: contract_address,
      value: "0x0",
      data: data
    }}
  end

  defp prepare_approve_tx(tx_params, account) do
    # Prepare token approval transaction
    contract_address = get_token_contract_address(tx_params.base_asset)

    data = encode_approve_function(
      get_dex_contract_address(tx_params.dex),
      tx_params.amount
    )

    {:ok, %{
      to: contract_address,
      value: "0x0",
      data: data
    }}
  end

  defp prepare_cancel_tx(account, nonce, gas_price, chain_id) do
    # Prepare a zero-value transaction with the same nonce
    {:ok, %{
      from: account.address,
      to: account.address, # Send to self
      value: "0x0",
      data: "0x",
      nonce: nonce,
      gas_price: gas_price,
      gas_limit: 21000,
      chain_id: chain_id
    }}
  end

  defp prepare_speed_up_tx(tx_record, gas_price, chain_id) do
    # Prepare a transaction with the same parameters but higher gas price
    {:ok, %{
      from: tx_record.from,
      to: tx_record.to,
      value: tx_record.value,
      data: tx_record.data,
      nonce: tx_record.nonce,
      gas_price: gas_price,
      gas_limit: tx_record.gas_limit,
      chain_id: chain_id
    }}
  end

  defp sign_transaction(eth_tx, private_key) do
    # Sign the transaction with the private key
    case Eth.Tx.sign(eth_tx, private_key) do
      {:ok, signed_tx} ->
        {:ok, "0x" <> Base.hex_encode32(signed_tx)}

      {:error, reason} ->
        {:error, "Failed to sign transaction: #{inspect(reason)}"}
    end
  end

  defp submit_transaction(signed_tx, client) do
    case Ethereumex.HttpClient.eth_send_raw_transaction(signed_tx) do
      {:ok, tx_hash} ->
        {:ok, tx_hash}

      {:error, reason} ->
        {:error, "Failed to submit transaction: #{inspect(reason)}"}
    end
  end

  defp get_account(account_id) do
    case Core.Repo.get(Account, account_id) do
      nil ->
        {:error, :account_not_found}

      account ->
        {:ok, account}
    end
  end

  defp get_dex_contract_address(dex) do
    # Get DEX contract address from configuration
    case dex do
      :uniswap ->
        System.get_env("UNISWAP_ROUTER_ADDRESS")

      :sushiswap ->
        System.get_env("SUSHISWAP_ROUTER_ADDRESS")

      _ ->
        {:error, "Unsupported DEX: #{dex}"}
    end
  end

  defp get_token_contract_address(symbol) do
    # Get token contract address from configuration
    System.get_env("TOKEN_#{String.upcase(symbol)}_ADDRESS")
  end

  defp encode_swap_function(recipient, amount_in, amount_out_min, slippage) do
    # Encode the swap function call according to the DEX ABI
    # This is a simplified version - in production, you would use the actual ABI
    "0x" <> Base.hex_encode32(recipient) <>
    Base.hex_encode32(amount_in) <>
    Base.hex_encode32(amount_out_min) <>
    Base.hex_encode32(slippage)
  end

  defp encode_approve_function(spender, amount) do
    # Encode the approve function call according to the ERC20 ABI
    # This is a simplified version - in production, you would use the actual ABI
    "0x" <> Base.hex_encode32(spender) <>
    Base.hex_encode32(amount)
  end
end
