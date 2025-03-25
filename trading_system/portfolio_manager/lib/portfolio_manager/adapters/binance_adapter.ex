defmodule PortfolioManager.Adapters.BinanceAdapter do
  @moduledoc """
  Adapter implementation for Binance exchange.
  Handles communication with Binance API and transforms data to the standardized format.
  Supports real-time updates via WebSocket and webhooks.
  """
  
  @behaviour PortfolioManager.Adapters.AdapterBehaviour
  
  use GenServer
  require Logger
  alias Phoenix.PubSub
  
  # Client API
  
  @doc """
  Starts the Binance adapter process.
  
  ## Parameters
    * `config` - Map containing Binance API credentials and settings
  """
  def start_link(config) do
    GenServer.start_link(__MODULE__, config, name: via_tuple(config.account_id))
  end
  
  @doc """
  Returns the process name for this adapter instance.
  """
  def via_tuple(account_id) do
    {:via, Registry, {PortfolioManager.AdapterRegistry, {__MODULE__, account_id}}}
  end
  
  @doc """
  Gets current balances for all assets.
  """
  def get_balances(account_id) do
    GenServer.call(via_tuple(account_id), :get_balances)
  end
  
  @doc """
  Gets transaction history with optional filters.
  """
  def fetch_account_transactions(account_id, opts \\ %{}) do
    GenServer.call(via_tuple(account_id), {:get_transactions, opts})
  end
  
  @doc """
  Gets detailed information about a specific asset.
  """
  def get_asset_info(account_id, asset_id) do
    GenServer.call(via_tuple(account_id), {:get_asset_info, asset_id})
  end
  
  @doc """
  Gets current market values for assets in the specified base currency.
  """
  def get_market_values(account_id, base_currency) do
    GenServer.call(via_tuple(account_id), {:get_market_values, base_currency})
  end
  
  # Callback implementations for AdapterBehaviour
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def get_balances, do: {:error, :not_implemented_directly}
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def get_transactions(_opts), do: {:error, :not_implemented_directly}
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def get_asset_info(_asset_id), do: {:error, :not_implemented_directly}
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def get_market_values(_base_currency), do: {:error, :not_implemented_directly}
  
  # Note: We implement init as part of GenServer callbacks below
  
  # GenServer callbacks
  
  @impl GenServer
  def init(config) do
    # Validate required config
    with {:ok, api_key} <- Map.fetch(config, :api_key),
         {:ok, api_secret} <- Map.fetch(config, :api_secret) do
      state = %{
        api_key: api_key,
        api_secret: api_secret,
        account_id: config.account_id,
        last_sync: nil,
        websocket_pid: nil,  # Changed from websocket_ref to websocket_pid
        webhook_id: nil,
        rate_limits: %{
          # Track rate limits to avoid API throttling
          requests: %{
            count: 0,
            window_start: DateTime.utc_now()
          }
        }
      }
      
      # Subscribe to PubSub topic for this account
      PubSub.subscribe(PortfolioManager.PubSub, "account:#{config.account_id}")
      
      # Schedule initial sync
      Process.send_after(self(), :sync_account, 5 * 1000) # Initial sync after 5 seconds
      
      # Start WebSocket connection after a short delay to allow the adapter to initialize
      if Map.get(config, :auto_connect, true) do
        Process.send_after(self(), :start_websocket, 10 * 1000) # Start WebSocket after 10 seconds
      end
      
      {:ok, state}
    else
      :error -> 
        Logger.error("Missing required Binance API credentials")
        {:stop, :missing_credentials}
    end
  end
  
  @impl GenServer
  def handle_call(:get_balances, _from, state) do
    case fetch_account_balances(state) do
      {:ok, balances} ->
        {:reply, {:ok, balances}, state}
      {:error, reason} = error ->
        Logger.error("Failed to fetch Binance balances: #{inspect(reason)}")
        {:reply, error, state}
    end
  end
  
  def handle_call(:get_account_id, _from, state) do
    {:reply, state.account_id, state}
  end
  
  def handle_call(:get_api_key, _from, state) do
    {:reply, state.api_key, state}
  end
  
  def handle_call(:get_api_secret, _from, state) do
    {:reply, state.api_secret, state}
  end
  
  def handle_call(:get_websocket_status, _from, state) do
    status = if state.websocket_pid && Process.alive?(state.websocket_pid) do
      :connected
    else
      :disconnected
    end
    {:reply, status, state}
  end
  
  @impl GenServer
  def handle_call({:get_transactions, opts}, _from, state) do
    case fetch_transactions(state, opts) do
      {:ok, transactions} ->
        {:reply, {:ok, transactions}, state}
      {:error, reason} = error ->
        Logger.error("Failed to fetch Binance transactions: #{inspect(reason)}")
        {:reply, error, state}
    end
  end
  
  @impl GenServer
  def handle_call({:get_asset_info, asset_id}, _from, state) do
    case fetch_asset_info(state, asset_id) do
      {:ok, info} ->
        {:reply, {:ok, info}, state}
      {:error, reason} = error ->
        Logger.error("Failed to fetch Binance asset info for #{asset_id}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end
  
  @impl GenServer
  def handle_call({:get_market_values, base_currency}, _from, state) do
    case fetch_market_values(state, base_currency) do
      {:ok, values} ->
        {:reply, {:ok, values}, state}
      {:error, reason} = error ->
        Logger.error("Failed to fetch Binance market values in #{base_currency}: #{inspect(reason)}")
        {:reply, error, state}
    end
  end
  
  @impl GenServer
  def handle_info(:sync_account, state) do
    # Perform full account synchronization
    Logger.info("Syncing Binance account #{state.account_id}")
    
    # Sync balances
    case fetch_account_balances(state) do
      {:ok, balances} ->
        # Update balances in database via Tracker
        GenServer.cast(PortfolioManager.Tracker, {:update_balances, state.account_id, balances})
      {:error, reason} ->
        Logger.error("Failed to fetch Binance balances: #{inspect(reason)}")
    end
    
    # Sync transactions since last sync
    last_sync = state.last_sync || ~U[2020-01-01 00:00:00Z]
    case fetch_transactions(state, %{start_date: last_sync}) do
      {:ok, transactions} ->
        # Record transactions via Tracker
        Enum.each(transactions, fn tx ->
          tx_params = Map.merge(tx, %{account_id: state.account_id})
          GenServer.cast(PortfolioManager.Tracker, {:record_transaction, tx_params})
        end)
      {:error, reason} ->
        Logger.error("Failed to fetch Binance transactions: #{inspect(reason)}")
    end
    
    # Determine next sync interval based on WebSocket status
    next_sync_interval = if state.websocket_pid && Process.alive?(state.websocket_pid) do
      # WebSocket is active, use longer interval (30 minutes)
      30 * 60 * 1000
    else
      # No WebSocket, use shorter interval (5 minutes)
      5 * 60 * 1000
    end
    
    # Schedule next sync
    Process.send_after(self(), :sync_account, next_sync_interval)
    
    {:noreply, %{state | last_sync: DateTime.utc_now()}}
  end
  
  @impl GenServer
  def handle_info(:start_websocket, state) do
    # Start WebSocket connection
    Logger.info("Starting WebSocket connection for Binance account #{state.account_id}")
    
    case start_websocket() do
      {:ok, ws_pid} ->
        Logger.info("Successfully started WebSocket connection for account #{state.account_id}")
        {:noreply, %{state | websocket_pid: ws_pid}}
      {:error, reason} ->
        Logger.error("Failed to start WebSocket connection: #{inspect(reason)}")
        # Retry after 1 minute
        Process.send_after(self(), :start_websocket, 60 * 1000)
        {:noreply, state}
    end
  end
  
  @impl GenServer
  def handle_info({:websocket_event, event, type}, state) do
    # Process WebSocket event
    Logger.info("Received WebSocket event: #{type}")
    
    case process_realtime_event(event, type) do
      {:ok, _result} -> :ok
      {:error, reason} -> Logger.error("Failed to process WebSocket event: #{inspect(reason)}")
    end
    
    {:noreply, state}
  end
  
  @impl GenServer
  def handle_info({:webhook_event, event, type}, state) do
    # Process webhook event
    case process_realtime_event(event, type) do
      {:ok, _result} -> :ok
      {:error, reason} -> Logger.error("Failed to process webhook event: #{inspect(reason)}")
    end
    
    {:noreply, state}
  end
  
  @impl GenServer
  def terminate(_reason, state) do
    # Clean up WebSocket connection if active
    if state.websocket_ref do
      stop_websocket(state.websocket_ref)
    end
    
    :ok
  end
  
  # WebSockex callbacks for WebSocket handling
  
  @impl WebSockex
  def handle_frame({:text, msg}, state) do
    case Jason.decode(msg) do
      {:ok, event} ->
        # Send event to GenServer process
        send(self(), {:websocket_event, event})
        {:ok, state}
      {:error, reason} ->
        Logger.error("Failed to decode WebSocket message: #{inspect(reason)}")
        {:ok, state}
    end
  end
  
  @impl WebSockex
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("Binance WebSocket disconnected: #{inspect(reason)}")
    # Attempt to reconnect after a delay
    Process.sleep(5000)
    {:reconnect, state}
  end
  
  # AdapterBehaviour implementation for real-time methods
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def start_websocket do
    # Get the current process PID (the adapter process)
    adapter_pid = self()
    
    # Get account details from the adapter state
    account_id = GenServer.call(adapter_pid, :get_account_id)
    api_key = GenServer.call(adapter_pid, :get_api_key)
    api_secret = GenServer.call(adapter_pid, :get_api_secret)
    
    # Start the WebSocket client
    {:ok, ws_pid} = PortfolioManager.Adapters.BinanceWebSocketClient.start_link(
      account_id: account_id,
      adapter_pid: adapter_pid,
      api_key: api_key,
      api_secret: api_secret
    )
    
    # Store the WebSocket PID in the adapter state
    GenServer.cast(adapter_pid, {:set_websocket_pid, ws_pid})
    
    # Return the WebSocket client PID as reference
    {:ok, ws_pid}
  end
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def stop_websocket(ws_pid) do
    # Stop the WebSocket client
    if Process.alive?(ws_pid) do
      PortfolioManager.Adapters.BinanceWebSocketClient.stop(ws_pid)
    end
    :ok
  end
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def register_webhook(_endpoint, _events) do
    # In a real implementation, this would register a webhook with Binance
    # Binance doesn't support webhooks directly, but we could use a third-party service
    # that bridges WebSocket events to webhooks
    
    # For demonstration, return not supported
    {:not_supported}
  end
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def validate_webhook(payload, _headers) do
    # In a real implementation, this would validate the webhook signature
    # For demonstration, just return the payload
    {:ok, payload}
  end
  
  @impl PortfolioManager.Adapters.AdapterBehaviour
  def process_realtime_event(event, type) do
    # Process different event types
    case type do
      "outboundAccountPosition" ->
        # Balance update event
        process_balance_update(event)
        
      "executionReport" ->
        # Order/trade execution event
        process_execution_report(event)
        
      "balanceUpdate" ->
        # Balance update from deposit/withdrawal
        process_balance_update(event)
        
      _ ->
        # Unknown event type
        {:error, :unknown_event_type}
    end
  end
  
  # Private functions for event processing
  
  defp process_balance_update(_event) do
    # Extract balance information from event
    # In a real implementation, this would parse the event data
    # and update balances in the database
    
    # For demonstration, just return success
    {:ok, :balance_updated}
  end
  
  defp process_execution_report(_event) do
    # Extract trade information from event
    # In a real implementation, this would parse the event data,
    # create a transaction record, and update balances
    
    # For demonstration, just return success
    {:ok, :transaction_recorded}
  end
  
  # Private functions for API calls
  
  defp fetch_account_balances(state) do
    # In a real implementation, this would make an API call to Binance
    # For now, we'll return mock data
    
    # Check rate limits before making request
    with {:ok, _state} <- check_rate_limits(state) do
      # Mock response
      balances = %{
        "BTC" => %{
          "free" => "0.5",
          "locked" => "0.0",
          "total" => "0.5"
        },
        "ETH" => %{
          "free" => "10.0",
          "locked" => "2.0",
          "total" => "12.0"
        },
        "USDT" => %{
          "free" => "5000.0",
          "locked" => "0.0",
          "total" => "5000.0"
        }
      }
      
      # Transform to standardized format
      transformed_balances = 
        balances
        |> Enum.map(fn {asset, data} ->
          {asset, %{
            available: String.to_float(data["free"]),
            locked: String.to_float(data["locked"]),
            total: String.to_float(data["total"])
          }}
        end)
        |> Enum.into(%{})
      
      {:ok, transformed_balances}
    end
  end
  
  defp fetch_transactions(state, opts) do
    # In a real implementation, this would make an API call to Binance
    # For now, we'll return mock data
    
    with {:ok, _state} <- check_rate_limits(state) do
      # Mock response
      transactions = [
        %{
          "id" => "123456",
          "type" => "BUY",
          "asset" => "BTC",
          "amount" => "0.1",
          "price" => "50000.0",
          "fee" => "0.001",
          "fee_asset" => "BTC",
          "timestamp" => "2025-03-20T10:00:00Z"
        },
        %{
          "id" => "123457",
          "type" => "SELL",
          "asset" => "ETH",
          "amount" => "2.0",
          "price" => "3000.0",
          "fee" => "0.01",
          "fee_asset" => "ETH",
          "timestamp" => "2025-03-21T11:30:00Z"
        }
      ]
      
      # Apply filters from opts if provided
      filtered_transactions = 
        transactions
        |> filter_by_date(opts)
        |> filter_by_asset(opts)
        |> filter_by_type(opts)
      
      # Transform to standardized format
      transformed_transactions = 
        filtered_transactions
        |> Enum.map(fn tx ->
          %{
            tx_id: tx["id"],
            tx_type: String.downcase(tx["type"]),
            asset: tx["asset"],
            amount: String.to_float(tx["amount"]),
            price: String.to_float(tx["price"]),
            fee: String.to_float(tx["fee"]),
            fee_asset: tx["fee_asset"],
            timestamp: tx["timestamp"],
            platform: "binance"
          }
        end)
      
      {:ok, transformed_transactions}
    end
  end
  
  defp fetch_asset_info(state, asset_id) do
    # In a real implementation, this would make an API call to Binance
    # For now, we'll return mock data
    
    with {:ok, _state} <- check_rate_limits(state) do
      # Mock response based on asset_id
      asset_info = case asset_id do
        "BTC" ->
          %{
            "name" => "Bitcoin",
            "symbol" => "BTC",
            "min_withdraw" => "0.001",
            "withdraw_fee" => "0.0005",
            "status" => "active"
          }
        "ETH" ->
          %{
            "name" => "Ethereum",
            "symbol" => "ETH",
            "min_withdraw" => "0.01",
            "withdraw_fee" => "0.005",
            "status" => "active"
          }
        _ ->
          nil
      end
      
      if asset_info do
        {:ok, asset_info}
      else
        {:error, :asset_not_found}
      end
    end
  end
  
  defp fetch_market_values(state, base_currency) do
    # In a real implementation, this would make an API call to Binance
    # For now, we'll return mock data
    
    with {:ok, _state} <- check_rate_limits(state) do
      # Mock response
      values = case base_currency do
        "USDT" ->
          %{
            "BTC" => "50000.0",
            "ETH" => "3000.0",
            "BNB" => "500.0"
          }
        "BTC" ->
          %{
            "ETH" => "0.06",
            "BNB" => "0.01",
            "USDT" => "0.00002"
          }
        _ ->
          %{}
      end
      
      # Transform to standardized format
      transformed_values = 
        values
        |> Enum.map(fn {asset, price} ->
          {asset, String.to_float(price)}
        end)
        |> Enum.into(%{})
      
      {:ok, transformed_values}
    end
  end
  
  # Helper functions
  
  defp check_rate_limits(state) do
    # Simple rate limiting implementation
    # In a real implementation, this would be more sophisticated
    now = DateTime.utc_now()
    window_start = state.rate_limits.requests.window_start
    count = state.rate_limits.requests.count
    
    # Reset counter if window has passed (1 minute)
    if DateTime.diff(now, window_start, :second) > 60 do
      new_state = put_in(state.rate_limits.requests, %{count: 1, window_start: now})
      {:ok, new_state}
    else
      # Check if we're within limits (e.g., 1200 requests per minute)
      if count < 1200 do
        new_state = put_in(state.rate_limits.requests.count, count + 1)
        {:ok, new_state}
      else
        {:error, :rate_limited}
      end
    end
  end
  
  defp filter_by_date(transactions, %{start_date: start_date, end_date: end_date}) do
    Enum.filter(transactions, fn tx ->
      tx_date = tx["timestamp"]
      tx_date >= start_date && tx_date <= end_date
    end)
  end
  
  defp filter_by_date(transactions, _), do: transactions
  
  defp filter_by_asset(transactions, %{asset: asset}) do
    Enum.filter(transactions, fn tx -> tx["asset"] == asset end)
  end
  
  defp filter_by_asset(transactions, _), do: transactions
  
  defp filter_by_type(transactions, %{type: type}) do
    Enum.filter(transactions, fn tx -> tx["type"] == String.upcase(type) end)
  end
  
  defp filter_by_type(transactions, _), do: transactions
end
