defmodule PortfolioManager.Tracker do
  @moduledoc """
  Core portfolio tracking module.
  Manages portfolio state and synchronization with external platforms.
  """
  
  use GenServer
  require Logger
  alias Core.Schema.{Account, Balance, Transaction, PortfolioSnapshot}
  alias Core.Repo
  # Import Ecto.Query for database queries
  import Ecto.Query, only: [from: 2]
  
  # Client API
  
  @doc """
  Starts the portfolio tracker.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end
  
  @doc """
  Registers a new account for tracking.
  
  ## Parameters
    * `account_params` - Map containing account parameters
    * `private_key_opts` - Optional map with private key information
      * `:private_key` - The private key to store (required if map is provided)
      * `:encryption_password` - Password for encrypting the key (required if map is provided)
  
  Returns:
    * `{:ok, account}` - The created account
    * `{:error, reason}` - Error with reason
  """
  def register_account(account_params, private_key_opts \\ nil) do
    GenServer.call(__MODULE__, {:register_account, account_params, private_key_opts})
  end
  
  @doc """
  Deactivates an account.
  
  ## Parameters
    * `account_id` - The ID of the account to deactivate
  
  Returns:
    * `{:ok, account}` - The deactivated account
    * `{:error, reason}` - Error with reason
  """
  def deactivate_account(account_id) do
    GenServer.call(__MODULE__, {:deactivate_account, account_id})
  end
  
  @doc """
  Gets the current portfolio summary.
  
  ## Parameters
    * `opts` - Options for filtering the summary
      * `:base_currency` - The currency to value the portfolio in (default: "USDT")
      * `:account_ids` - List of account IDs to include (default: all)
  
  Returns:
    * `{:ok, summary}` - The portfolio summary
    * `{:error, reason}` - Error with reason
  """
  def get_portfolio_summary(opts \\ %{}) do
    GenServer.call(__MODULE__, {:get_portfolio_summary, opts})
  end
  
  @doc """
  Gets the balance for a specific asset.
  
  ## Parameters
    * `asset` - The asset to get the balance for
    * `opts` - Options for filtering
      * `:account_ids` - List of account IDs to include (default: all)
  
  Returns:
    * `{:ok, balance}` - The asset balance
    * `{:error, reason}` - Error with reason
  """
  def get_asset_balance(asset, opts \\ %{}) do
    GenServer.call(__MODULE__, {:get_asset_balance, asset, opts})
  end
  
  @doc """
  Records a transaction.
  
  ## Parameters
    * `transaction_params` - Map containing transaction parameters
  
  Returns:
    * `{:ok, transaction}` - The created transaction
    * `{:error, changeset}` - Error with changeset
  """
  def record_transaction(transaction_params) do
    GenServer.call(__MODULE__, {:record_transaction, transaction_params})
  end
  
  @doc """
  Triggers a manual sync for an account.
  
  ## Parameters
    * `account_id` - The ID of the account to sync
  
  Returns:
    * `:ok` - Sync initiated
    * `{:error, reason}` - Error with reason
  """
  def sync_account(account_id) do
    GenServer.cast(__MODULE__, {:sync_account, account_id})
  end
  
  @doc """
  Creates a portfolio snapshot.
  
  ## Parameters
    * `base_currency` - The currency to value the portfolio in
  
  Returns:
    * `{:ok, snapshot}` - The created snapshot
    * `{:error, reason}` - Error with reason
  """
  def create_snapshot(base_currency \\ "USDT") do
    GenServer.call(__MODULE__, {:create_snapshot, base_currency})
  end
  
  # GenServer callbacks
  
  @impl true
  def init(_) do
    # Schedule regular portfolio snapshots
    schedule_snapshot()
    
    {:ok, %{}}
  end
  
  @impl true
  def handle_call({:register_account, account_params, private_key_opts}, _from, state) do
    # Create account in database
    changeset = Account.create_changeset(account_params)
    
    case Repo.insert(changeset) do
      {:ok, account} ->
        # Store private key if provided
        result = 
          if private_key_opts do
            case store_private_key(account, private_key_opts) do
              {:ok, _key_id} ->
                # Update account to indicate it has a private key
                case update_account_private_key_status(account, true) do
                  {:ok, updated_account} -> {:ok, updated_account}
                  {:error, reason} -> 
                    # Clean up the stored key if we couldn't update the account
                    _ = Core.Vault.KeyVault.remove_private_key(account.id)
                    {:error, reason}
                end
                
              {:error, reason} ->
                {:error, reason}
            end
          else
            {:ok, account}
          end
            
        case result do
          {:ok, updated_account} ->
            # Start the appropriate adapter
            adapter_module = get_adapter_module(updated_account.provider)
            adapter_config = Map.merge(updated_account.config, %{account_id: updated_account.id})
            
            case PortfolioManager.Adapters.Supervisor.start_adapter(adapter_module, adapter_config) do
              {:ok, _pid} ->
                # Trigger initial sync
                sync_account(updated_account.id)
                {:reply, {:ok, updated_account}, state}
                
              {:error, reason} ->
                Logger.error("Failed to start adapter for account #{updated_account.id}: #{inspect(reason)}")
                {:reply, {:error, :adapter_start_failed}, state}
            end
            
          {:error, reason} ->
            # Delete the account if we couldn't store the private key
            Repo.delete(account)
            Logger.error("Failed to process private key for account #{account.id}: #{inspect(reason)}")
            {:reply, {:error, "Failed to process private key: #{inspect(reason)}"}, state}
        end
        
      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end
  
  @impl true
  def handle_call({:deactivate_account, account_id}, _from, state) do
    case Repo.get(Account, account_id) do
      nil ->
        {:reply, {:error, :not_found}, state}
        
      account ->
        # Deactivate account in database
        changeset = Account.deactivate_changeset(account)
        
        case Repo.update(changeset) do
          {:ok, updated_account} ->
            # Stop the adapter
            adapter_module = get_adapter_module(account.provider)
            PortfolioManager.Adapters.Supervisor.stop_adapter(adapter_module, account_id)
            
            {:reply, {:ok, updated_account}, state}
            
          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
    end
  end
  
  @impl true
  def handle_call({:get_portfolio_summary, opts}, _from, state) do
    base_currency = Map.get(opts, :base_currency, "USDT")
    account_ids = Map.get(opts, :account_ids)
    
    # Query accounts
    accounts_query = from a in Account, where: a.active == true
    accounts_query = if account_ids do
      from a in accounts_query, where: a.id in ^account_ids
    else
      accounts_query
    end
    accounts = Repo.all(accounts_query)
    
    # Get balances for each account
    balances_by_account = 
      Enum.map(accounts, fn account ->
        balances = 
          from(b in Balance, where: b.account_id == ^account.id)
          |> Repo.all()
          |> Enum.group_by(&(&1.asset), &(&1.amount))
          
        {account, balances}
      end)
      |> Enum.into(%{})
      
    # Get market values for assets
    market_values = get_market_values(base_currency)
    
    # Calculate total portfolio value
    {total_value, asset_values} = calculate_portfolio_value(balances_by_account, market_values)
    
    # Build summary
    summary = %{
      total_value: total_value,
      base_currency: base_currency,
      assets: asset_values,
      accounts: Enum.map(accounts, fn account -> 
        account_balances = Map.get(balances_by_account, account, %{})
        account_value = calculate_account_value(account_balances, market_values)
        
        %{
          id: account.id,
          name: account.name,
          type: account.type,
          provider: account.provider,
          value: account_value
        }
      end),
      last_updated: DateTime.utc_now()
    }
    
    {:reply, {:ok, summary}, state}
  end
  
  @impl true
  def handle_call({:get_asset_balance, asset, opts}, _from, state) do
    account_ids = Map.get(opts, :account_ids)
    
    # Query balances
    balances_query = from b in Balance, where: b.asset == ^asset
    balances_query = if account_ids do
      from b in balances_query, where: b.account_id in ^account_ids
    else
      balances_query
    end
    
    balances = Repo.all(balances_query) |> Repo.preload(:account)
    
    # Calculate total balance
    total_amount = Enum.reduce(balances, Decimal.new(0), fn balance, acc ->
      Decimal.add(acc, balance.amount)
    end)
    
    total_available = Enum.reduce(balances, Decimal.new(0), fn balance, acc ->
      Decimal.add(acc, balance.available)
    end)
    
    total_locked = Enum.reduce(balances, Decimal.new(0), fn balance, acc ->
      Decimal.add(acc, balance.locked)
    end)
    
    # Build response
    balance_info = %{
      asset: asset,
      total: total_amount,
      available: total_available,
      locked: total_locked,
      by_account: Enum.map(balances, fn balance ->
        %{
          account_id: balance.account_id,
          account_name: balance.account.name,
          amount: balance.amount,
          available: balance.available,
          locked: balance.locked,
          synced_at: balance.synced_at
        }
      end)
    }
    
    {:reply, {:ok, balance_info}, state}
  end
  
  @impl true
  def handle_call({:record_transaction, transaction_params}, _from, state) do
    # Create transaction in database
    changeset = Transaction.create_changeset(transaction_params)
    
    case Repo.insert(changeset) do
      {:ok, transaction} ->
        # Update balances based on transaction
        update_balances_from_transaction(transaction)
        {:reply, {:ok, transaction}, state}
        
      {:error, changeset} ->
        {:reply, {:error, changeset}, state}
    end
  end
  
  @impl true
  def handle_call({:create_snapshot, base_currency}, _from, state) do
    # Get current portfolio summary
    case get_portfolio_summary(%{base_currency: base_currency}) do
      {:ok, summary} ->
        # Create snapshot
        snapshot_params = %{
          timestamp: DateTime.utc_now(),
          value: summary.total_value,
          base_currency: base_currency,
          asset_breakdown: summary.assets
        }
        
        changeset = PortfolioSnapshot.create_changeset(snapshot_params)
        
        case Repo.insert(changeset) do
          {:ok, snapshot} ->
            {:reply, {:ok, snapshot}, state}
            
          {:error, changeset} ->
            {:reply, {:error, changeset}, state}
        end
        
      {:error, reason} ->
        {:reply, {:error, reason}, state}
    end
  end
  
  @impl true
  def handle_cast({:sync_account, account_id}, state) do
    # Get account
    case Repo.get(Account, account_id) do
      nil ->
        Logger.warning("Account #{account_id} not found for sync")
        {:noreply, state}
        
      account ->
        if account.active do
          # Get adapter module
          adapter_module = get_adapter_module(account.provider)
          
          # Get registry name for the adapter
          adapter_name = {adapter_module, account.id}
          
          # Find adapter process
          case Registry.lookup(PortfolioManager.AdapterRegistry, adapter_name) do
            [{pid, _}] ->
              # Sync balances
              sync_balances(pid, account)
              
              # Sync transactions
              sync_transactions(pid, account)
              
              {:noreply, state}
              
            [] ->
              Logger.warning("Adapter process not found for account #{account.id}")
              {:noreply, state}
          end
        else
          Logger.info("Skipping sync for inactive account #{account.id}")
          {:noreply, state}
        end
    end
  end
  
  @impl true
  def handle_cast({:update_balances, account_id, balances}, state) do
    # Get account
    case Repo.get(Account, account_id) do
      nil ->
        Logger.warning("Account #{account_id} not found for balance update")
        
      account ->
        if account.active do
          # Update balances in database
          Enum.each(balances, fn {asset, data} ->
            balance_params = %{
              account_id: account.id,
              asset: asset,
              amount: data.total,
              available: data.available,
              locked: data.locked,
              synced_at: DateTime.utc_now()
            }
            
            # Find existing balance or create new one
            case Repo.get_by(Balance, account_id: account.id, asset: asset) do
              nil ->
                # Create new balance
                Balance.create_changeset(balance_params)
                |> Repo.insert()
                
              existing_balance ->
                # Update existing balance
                Balance.update_changeset(existing_balance, balance_params)
                |> Repo.update()
            end
          end)
          
          # Broadcast balance update event
          Phoenix.PubSub.broadcast(
            PortfolioManager.PubSub,
            "account:#{account.id}",
            {:balance_updated, account.id}
          )
          
          Logger.info("Updated balances for account #{account.id} from real-time event")
        else
          Logger.info("Skipping balance update for inactive account #{account.id}")
        end
    end
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:record_transaction, tx_params}, state) do
    # Check if transaction already exists
    existing = Repo.get_by(Transaction, 
      account_id: tx_params.account_id, 
      tx_id: tx_params.tx_id
    )
    
    if existing do
      # Transaction already exists, skip
      Logger.debug("Transaction #{tx_params.tx_id} already exists, skipping")
    else
      # Create transaction in database
      changeset = Transaction.create_changeset(tx_params)
      
      case Repo.insert(changeset) do
        {:ok, transaction} ->
          # Update balances based on transaction
          update_balances_from_transaction(transaction)
          
          # Broadcast transaction event
          Phoenix.PubSub.broadcast(
            PortfolioManager.PubSub,
            "account:#{transaction.account_id}",
            {:transaction_recorded, transaction.id}
          )
          
          Logger.info("Recorded transaction #{transaction.tx_id} from real-time event")
          
        {:error, changeset} ->
          Logger.error("Failed to record transaction: #{inspect(changeset.errors)}")
      end
    end
    
    {:noreply, state}
  end
  
  @impl true
  def handle_info(:create_snapshot, state) do
    # Create snapshot in default currency
    {:ok, _snapshot} = create_snapshot()
    
    # Schedule next snapshot
    schedule_snapshot()
    
    {:noreply, state}
  end
  
  # Private functions
  
  defp get_adapter_module("binance"), do: PortfolioManager.Adapters.BinanceAdapter
  defp get_adapter_module("uniswap"), do: PortfolioManager.Adapters.UniswapAdapter
  defp get_adapter_module(provider), do: raise "Unsupported provider: #{provider}"
  
  defp sync_balances(adapter_pid, account) do
    case GenServer.call(adapter_pid, :get_balances) do
      {:ok, balances} ->
        # Update balances in database
        Enum.each(balances, fn {asset, data} ->
          balance_params = %{
            account_id: account.id,
            asset: asset,
            amount: data.total,
            available: data.available,
            locked: data.locked,
            synced_at: DateTime.utc_now()
          }
          
          # Find existing balance or create new one
          case Repo.get_by(Balance, account_id: account.id, asset: asset) do
            nil ->
              # Create new balance
              Balance.create_changeset(balance_params)
              |> Repo.insert()
              
            existing_balance ->
              # Update existing balance
              Balance.update_changeset(existing_balance, balance_params)
              |> Repo.update()
          end
        end)
        
      {:error, reason} ->
        Logger.error("Failed to sync balances for account #{account.id}: #{inspect(reason)}")
    end
  end
  
  defp sync_transactions(adapter_pid, account) do
    # Get last synced transaction timestamp
    last_tx = 
      from(t in Transaction, 
        where: t.account_id == ^account.id,
        order_by: [desc: t.timestamp],
        limit: 1
      )
      |> Repo.one()
      
    # Set sync start time
    start_time = if last_tx, do: last_tx.timestamp, else: ~U[2020-01-01 00:00:00Z]
    
    # Get transactions since last sync
    case GenServer.call(adapter_pid, {:get_transactions, %{start_date: start_time}}) do
      {:ok, transactions} ->
        # Insert new transactions
        Enum.each(transactions, fn tx ->
          tx_params = Map.merge(tx, %{account_id: account.id})
          
          # Check if transaction already exists
          case Repo.get_by(Transaction, account_id: account.id, tx_id: tx.tx_id) do
            nil ->
              # Create new transaction
              Transaction.create_changeset(tx_params)
              |> Repo.insert()
              
            _existing_tx ->
              # Transaction already exists, skip
              :ok
          end
        end)
        
      {:error, reason} ->
        Logger.error("Failed to sync transactions for account #{account.id}: #{inspect(reason)}")
    end
  end
  
  defp update_balances_from_transaction(transaction) do
    # Get account
    account = Repo.get(Account, transaction.account_id)
    
    # Update balance based on transaction type
    case transaction.tx_type do
      "buy" ->
        # Increase asset balance
        update_asset_balance(account.id, transaction.asset, transaction.amount)
        
        # If price is available, decrease quote currency balance
        if transaction.price do
          quote_amount = Decimal.mult(transaction.amount, transaction.price)
          quote_currency = get_quote_currency(transaction.asset)
          update_asset_balance(account.id, quote_currency, Decimal.negate(quote_amount))
        end
        
      "sell" ->
        # Decrease asset balance
        update_asset_balance(account.id, transaction.asset, Decimal.negate(transaction.amount))
        
        # If price is available, increase quote currency balance
        if transaction.price do
          quote_amount = Decimal.mult(transaction.amount, transaction.price)
          quote_currency = get_quote_currency(transaction.asset)
          update_asset_balance(account.id, quote_currency, quote_amount)
        end
        
      "deposit" ->
        # Increase asset balance
        update_asset_balance(account.id, transaction.asset, transaction.amount)
        
      "withdrawal" ->
        # Decrease asset balance
        update_asset_balance(account.id, transaction.asset, Decimal.negate(transaction.amount))
    end
    
    # Update fee if present
    if transaction.fee && transaction.fee_asset do
      update_asset_balance(account.id, transaction.fee_asset, Decimal.negate(transaction.fee))
    end
  end
  
  defp update_asset_balance(account_id, asset, amount_change) do
    # Find existing balance or create new one
    case Repo.get_by(Balance, account_id: account_id, asset: asset) do
      nil ->
        # Create new balance
        balance_params = %{
          account_id: account_id,
          asset: asset,
          amount: amount_change,
          available: amount_change,
          locked: Decimal.new(0),
          synced_at: DateTime.utc_now()
        }
        
        Balance.create_changeset(balance_params)
        |> Repo.insert()
        
      existing_balance ->
        # Update existing balance
        new_amount = Decimal.add(existing_balance.amount, amount_change)
        new_available = Decimal.add(existing_balance.available, amount_change)
        
        balance_params = %{
          amount: new_amount,
          available: new_available,
          synced_at: DateTime.utc_now()
        }
        
        Balance.update_changeset(existing_balance, balance_params)
        |> Repo.update()
    end
  end
  
  defp get_quote_currency("BTC"), do: "USDT"
  defp get_quote_currency("ETH"), do: "USDT"
  defp get_quote_currency("BNB"), do: "USDT"
  defp get_quote_currency(_), do: "USDT"
  
  # Private key handling functions
  
  @doc """
  Stores a private key for an account in the secure vault.
  
  ## Parameters
    * `account` - The account to store the private key for
    * `private_key_opts` - Map with private key information
      * `:private_key` - The private key to store
      * `:encryption_password` - Password for encrypting the key
  
  Returns:
    * `{:ok, key_id}` - The ID of the stored key
    * `{:error, reason}` - Error with reason
  """
  defp store_private_key(account, private_key_opts) do
    with {:ok, private_key} <- Map.fetch(private_key_opts, :private_key),
         {:ok, encryption_password} <- Map.fetch(private_key_opts, :encryption_password) do
      Core.Vault.KeyVault.store_private_key(account.id, private_key, encryption_password)
    else
      :error -> {:error, "Missing required private key information"}
    end
  end
  
  @doc """
  Updates an account's has_private_key status.
  
  ## Parameters
    * `account` - The account to update
    * `has_key` - Boolean indicating if the account has a private key
  
  Returns:
    * `{:ok, updated_account}` - The updated account
    * `{:error, changeset}` - Error with changeset
  """
  defp update_account_private_key_status(account, has_key) do
    changeset = Account.changeset(account, %{has_private_key: has_key})
    Repo.update(changeset)
  end
  
  @doc """
  Gets a private key for an account.
  
  ## Parameters
    * `account_id` - The ID of the account
    * `encryption_password` - Password for decrypting the key
  
  Returns:
    * `{:ok, private_key}` - The decrypted private key
    * `{:error, reason}` - Error with reason
  """
  def get_private_key(account_id, encryption_password) do
    Core.Vault.KeyVault.get_private_key(account_id, encryption_password)
  end
  
  defp get_market_values(base_currency) do
    # In a real implementation, this would fetch market values from a price feed
    # For now, we'll return mock data
    case base_currency do
      "USDT" ->
        %{
          "BTC" => Decimal.new("50000.0"),
          "ETH" => Decimal.new("3000.0"),
          "BNB" => Decimal.new("500.0"),
          "USDT" => Decimal.new("1.0")
        }
      "BTC" ->
        %{
          "BTC" => Decimal.new("1.0"),
          "ETH" => Decimal.new("0.06"),
          "BNB" => Decimal.new("0.01"),
          "USDT" => Decimal.new("0.00002")
        }
      _ ->
        %{}
    end
  end
  
  defp calculate_portfolio_value(balances_by_account, market_values) do
    # Aggregate balances across all accounts
    all_assets = 
      balances_by_account
      |> Enum.flat_map(fn {_account, balances} -> Map.keys(balances) end)
      |> Enum.uniq()
      
    # Calculate value for each asset
    asset_values = 
      all_assets
      |> Enum.map(fn asset ->
        # Sum balances across all accounts
        total_balance = 
          balances_by_account
          |> Enum.flat_map(fn {_account, balances} -> Map.get(balances, asset, []) end)
          |> Enum.reduce(Decimal.new(0), fn amount, acc -> Decimal.add(acc, amount) end)
          
        # Get market value
        market_value = Map.get(market_values, asset, Decimal.new(0))
        
        # Calculate value
        value = Decimal.mult(total_balance, market_value)
        
        {asset, %{balance: total_balance, price: market_value, value: value}}
      end)
      |> Enum.into(%{})
      
    # Calculate total portfolio value
    total_value = 
      asset_values
      |> Enum.map(fn {_asset, data} -> data.value end)
      |> Enum.reduce(Decimal.new(0), fn value, acc -> Decimal.add(acc, value) end)
      
    {total_value, asset_values}
  end
  
  defp calculate_account_value(balances, market_values) do
    balances
    |> Enum.map(fn {asset, amounts} ->
      # Sum amounts
      total_amount = 
        amounts
        |> Enum.reduce(Decimal.new(0), fn amount, acc -> Decimal.add(acc, amount) end)
        
      # Get market value
      market_value = Map.get(market_values, asset, Decimal.new(0))
      
      # Calculate value
      Decimal.mult(total_amount, market_value)
    end)
    |> Enum.reduce(Decimal.new(0), fn value, acc -> Decimal.add(acc, value) end)
  end
  
  defp schedule_snapshot do
    # Schedule snapshot for 1 hour from now
    Process.send_after(self(), :create_snapshot, 60 * 60 * 1000)
  end
end
