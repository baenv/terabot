defmodule PortfolioManager.API do
  @moduledoc """
  Public API for the Portfolio Manager.
  Provides a unified interface for other components to interact with the Portfolio Manager.
  """
  
  alias PortfolioManager.{Tracker, Metrics}
  alias Core.Repo
  alias Core.Schema.Account
  
  @doc """
  Registers a new account for tracking.
  
  ## Parameters
    * `account_params` - Map containing account parameters
      * `:name` - Account name (required)
      * `:type` - Account type ("dex" or "cex") (required)
      * `:provider` - Provider name (e.g., "binance", "uniswap") (required)
      * `:account_id` - Platform-specific account ID (required)
      * `:config` - Platform-specific configuration (required)
      * `:metadata` - Additional metadata (optional)
    * `private_key_opts` - Optional map with private key information
      * `:private_key` - The private key to store (required if map is provided)
      * `:encryption_password` - Password for encrypting the key (required if map is provided)
  
  Returns:
    * `{:ok, account}` - The created account
    * `{:error, reason}` - Error with reason
  """
  defdelegate register_account(account_params, private_key_opts \\ nil), to: Tracker
  
  @doc """
  Deactivates an account.
  
  ## Parameters
    * `account_id` - The ID of the account to deactivate
  
  Returns:
    * `{:ok, account}` - The deactivated account
    * `{:error, reason}` - Error with reason
  """
  defdelegate deactivate_account(account_id), to: Tracker
  
  @doc """
  Lists all accounts.
  
  Returns:
    * `{:ok, accounts}` - List of all accounts
    * `{:error, reason}` - Error with reason
  """
  def list_accounts do
    # Use a safer approach that handles potential database issues
    try do
      # Get all accounts but map them to a structure with only the fields we need
      accounts = Repo.all(Account)
        |> Enum.map(fn account -> 
          %{
            id: account.id,
            name: account.name,
            type: account.type,
            provider: account.provider,
            account_id: account.account_id,
            active: account.active,
            inserted_at: account.inserted_at,
            updated_at: account.updated_at
          }
        end)
      {:ok, accounts}
    rescue
      e in Postgrex.Error -> 
        require Logger
        Logger.error("Database error in list_accounts: #{inspect(e)}")
        {:error, "Database error: #{e.postgres.message}"}
      e -> 
        require Logger
        Logger.error("Unexpected error in list_accounts: #{inspect(e)}")
        {:error, "Unexpected error: #{inspect(e)}"}  
    end
  end
  
  @doc """
  Gets an account by ID.
  
  ## Parameters
    * `id` - The ID of the account to retrieve
  
  Returns:
    * `{:ok, account}` - The retrieved account
    * `{:error, :not_found}` - Account not found
    * `{:error, reason}` - Error with reason
  """
  def get_account(id) do
    try do
      case Repo.get(Account, id) do
        nil -> 
          {:error, :not_found}
        account -> 
          # Map to a structure with only the fields we need
          account_data = %{
            id: account.id,
            name: account.name,
            type: account.type,
            provider: account.provider,
            account_id: account.account_id,
            active: account.active,
            inserted_at: account.inserted_at,
            updated_at: account.updated_at
          }
          {:ok, account_data}
      end
    rescue
      e in Postgrex.Error -> 
        require Logger
        Logger.error("Database error in get_account: #{inspect(e)}")
        {:error, "Database error: #{e.postgres.message}"}
      e -> 
        require Logger
        Logger.error("Unexpected error in get_account: #{inspect(e)}")
        {:error, "Unexpected error: #{inspect(e)}"}
    end
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
  defdelegate get_portfolio_summary(opts \\ %{}), to: Tracker
  
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
  defdelegate get_asset_balance(asset, opts \\ %{}), to: Tracker
  
  @doc """
  Records a transaction.
  
  ## Parameters
    * `transaction_params` - Map containing transaction parameters
      * `:account_id` - Account ID (required)
      * `:tx_id` - Transaction ID (required)
      * `:tx_type` - Transaction type ("buy", "sell", "deposit", "withdrawal") (required)
      * `:asset` - Asset symbol (required)
      * `:amount` - Transaction amount (required)
      * `:timestamp` - Transaction timestamp (required)
      * `:price` - Price per unit (optional)
      * `:fee` - Transaction fee (optional)
      * `:fee_asset` - Fee asset (optional)
      * `:metadata` - Additional metadata (optional)
  
  Returns:
    * `{:ok, transaction}` - The created transaction
    * `{:error, changeset}` - Error with changeset
  """
  defdelegate record_transaction(transaction_params), to: Tracker
  
  @doc """
  Triggers a manual sync for an account.
  
  ## Parameters
    * `account_id` - The ID of the account to sync
  
  Returns:
    * `:ok` - Sync initiated
    * `{:error, reason}` - Error with reason
  """
  defdelegate sync_account(account_id), to: Tracker
  
  @doc """
  Creates a portfolio snapshot.
  
  ## Parameters
    * `base_currency` - The currency to value the portfolio in (default: "USDT")
  
  Returns:
    * `{:ok, snapshot}` - The created snapshot
    * `{:error, reason}` - Error with reason
  """
  defdelegate create_snapshot(base_currency \\ "USDT"), to: Tracker
  
  @doc """
  Calculates Return on Investment (ROI) for a specific time period.
  
  ## Parameters
    * `period` - The time period to calculate ROI for (:daily, :weekly, :monthly, :yearly)
    * `opts` - Options for calculation
      * `:base_currency` - The currency to calculate ROI in (default: "USDT")
      * `:end_date` - The end date for calculation (default: current date)
  
  Returns:
    * `{:ok, roi}` - The calculated ROI as a decimal
    * `{:error, reason}` - Error with reason
  """
  defdelegate calculate_roi(period, opts \\ %{}), to: Metrics
  
  @doc """
  Calculates volatility for a specific time period.
  
  ## Parameters
    * `period` - The time period to calculate volatility for (:daily, :weekly, :monthly, :yearly)
    * `opts` - Options for calculation
      * `:base_currency` - The currency to calculate volatility in (default: "USDT")
      * `:end_date` - The end date for calculation (default: current date)
  
  Returns:
    * `{:ok, volatility}` - The calculated volatility as a decimal
    * `{:error, reason}` - Error with reason
  """
  defdelegate calculate_volatility(period, opts \\ %{}), to: Metrics
  
  @doc """
  Calculates Sharpe ratio for a specific time period.
  
  ## Parameters
    * `period` - The time period to calculate Sharpe ratio for (:daily, :weekly, :monthly, :yearly)
    * `opts` - Options for calculation
      * `:base_currency` - The currency to calculate Sharpe ratio in (default: "USDT")
      * `:risk_free_rate` - The risk-free rate to use (default: 0.02 for 2%)
      * `:end_date` - The end date for calculation (default: current date)
  
  Returns:
    * `{:ok, sharpe_ratio}` - The calculated Sharpe ratio as a decimal
    * `{:error, reason}` - Error with reason
  """
  defdelegate calculate_sharpe_ratio(period, opts \\ %{}), to: Metrics
  
  @doc """
  Calculates maximum drawdown for a specific time period.
  
  ## Parameters
    * `period` - The time period to calculate drawdown for (:daily, :weekly, :monthly, :yearly)
    * `opts` - Options for calculation
      * `:base_currency` - The currency to calculate drawdown in (default: "USDT")
      * `:end_date` - The end date for calculation (default: current date)
  
  Returns:
    * `{:ok, drawdown}` - The calculated maximum drawdown as a decimal
    * `{:error, reason}` - Error with reason
  """
  defdelegate calculate_max_drawdown(period, opts \\ %{}), to: Metrics
  
  @doc """
  Calculates asset allocation percentages.
  
  ## Parameters
    * `opts` - Options for calculation
      * `:base_currency` - The currency to calculate allocation in (default: "USDT")
      * `:account_ids` - List of account IDs to include (default: all)
  
  Returns:
    * `{:ok, allocation}` - The calculated asset allocation
    * `{:error, reason}` - Error with reason
  """
  defdelegate calculate_asset_allocation(opts \\ %{}), to: Metrics
  
  @doc """
  Generates a performance report for a specific time period.
  
  ## Parameters
    * `period` - The time period for the report (:daily, :weekly, :monthly, :yearly)
    * `opts` - Options for the report
      * `:base_currency` - The currency for the report (default: "USDT")
      * `:account_ids` - List of account IDs to include (default: all)
  
  Returns:
    * `{:ok, report}` - The generated report
    * `{:error, reason}` - Error with reason
  """
  defdelegate generate_performance_report(period, opts \\ %{}), to: Metrics
  
  @doc """
  Validates if a trade is possible given the current portfolio.
  
  ## Parameters
    * `trade_params` - Map containing trade parameters
      * `:account_id` - Account ID
      * `:asset` - Asset to trade
      * `:amount` - Amount to trade
      * `:price` - Price per unit
      * `:type` - Trade type ("buy" or "sell")
  
  Returns:
    * `{:ok, validation}` - Validation result with details
    * `{:error, reason}` - Error with reason
  """
  def validate_trade(trade_params) do
    with {:ok, account_id} <- Map.fetch(trade_params, :account_id),
         {:ok, asset} <- Map.fetch(trade_params, :asset),
         {:ok, amount} <- Map.fetch(trade_params, :amount),
         {:ok, price} <- Map.fetch(trade_params, :price),
         {:ok, type} <- Map.fetch(trade_params, :type) do
      
      case type do
        "buy" ->
          # For buy, check if we have enough of the quote currency
          quote_currency = get_quote_currency(asset)
          quote_amount = Decimal.mult(amount, price)
          
          case Tracker.get_asset_balance(quote_currency, %{account_ids: [account_id]}) do
            {:ok, balance} ->
              if Decimal.compare(balance.available, quote_amount) == :lt do
                {:error, :insufficient_funds}
              else
                {:ok, %{
                  valid: true,
                  asset: asset,
                  amount: amount,
                  price: price,
                  total_cost: quote_amount,
                  quote_currency: quote_currency,
                  available_balance: balance.available
                }}
              end
              
            error ->
              error
          end
          
        "sell" ->
          # For sell, check if we have enough of the asset
          case Tracker.get_asset_balance(asset, %{account_ids: [account_id]}) do
            {:ok, balance} ->
              if Decimal.compare(balance.available, amount) == :lt do
                {:error, :insufficient_funds}
              else
                quote_currency = get_quote_currency(asset)
                quote_amount = Decimal.mult(amount, price)
                
                {:ok, %{
                  valid: true,
                  asset: asset,
                  amount: amount,
                  price: price,
                  total_value: quote_amount,
                  quote_currency: quote_currency,
                  available_balance: balance.available
                }}
              end
              
            error ->
              error
          end
          
        _ ->
          {:error, :invalid_trade_type}
      end
    else
      :error -> {:error, :missing_parameters}
    end
  end
  
  @doc """
  Handles a trade notification from the Order Manager.
  
  ## Parameters
    * `trade_notification` - Map containing trade notification
      * `:account_id` - Account ID
      * `:tx_id` - Transaction ID
      * `:asset` - Asset traded
      * `:amount` - Amount traded
      * `:price` - Price per unit
      * `:type` - Trade type ("buy" or "sell")
      * `:timestamp` - Trade timestamp
      * `:fee` - Trade fee
      * `:fee_asset` - Fee asset
  
  Returns:
    * `{:ok, transaction}` - The recorded transaction
    * `{:error, reason}` - Error with reason
  """
  def handle_trade_notification(trade_notification) do
    # Transform trade notification to transaction params
    transaction_params = %{
      account_id: trade_notification.account_id,
      tx_id: trade_notification.tx_id,
      tx_type: trade_notification.type,
      asset: trade_notification.asset,
      amount: trade_notification.amount,
      price: trade_notification.price,
      fee: trade_notification.fee,
      fee_asset: trade_notification.fee_asset,
      timestamp: trade_notification.timestamp,
      metadata: Map.drop(trade_notification, [:account_id, :tx_id, :asset, :amount, :price, :type, :timestamp, :fee, :fee_asset])
    }
    
    # Record transaction
    Tracker.record_transaction(transaction_params)
  end
  
  # Private functions
  
  defp get_quote_currency("BTC"), do: "USDT"
  defp get_quote_currency("ETH"), do: "USDT"
  defp get_quote_currency("BNB"), do: "USDT"
  defp get_quote_currency(_), do: "USDT"
end
