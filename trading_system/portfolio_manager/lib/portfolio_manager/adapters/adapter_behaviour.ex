defmodule PortfolioManager.Adapters.AdapterBehaviour do
  @moduledoc """
  Defines the common interface that all platform adapters must implement.
  This behavior ensures consistent interaction with different trading platforms.
  """

  @doc """
  Retrieves current balances for all assets in the account.
  
  Returns:
    * `{:ok, map()}` - Map of asset balances with keys as asset symbols
    * `{:error, reason}` - Error with reason
  """
  @callback get_balances() :: {:ok, map()} | {:error, any()}

  @doc """
  Retrieves transaction history for the account.
  
  ## Parameters
    * `opts` - Map of options for filtering transactions (e.g., time range, asset type)
  
  Returns:
    * `{:ok, list()}` - List of transaction records
    * `{:error, reason}` - Error with reason
  """
  @callback get_transactions(opts :: map()) :: {:ok, list()} | {:error, any()}

  @doc """
  Retrieves detailed information about a specific asset.
  
  ## Parameters
    * `asset_id` - String identifier for the asset
  
  Returns:
    * `{:ok, map()}` - Map containing asset details
    * `{:error, reason}` - Error with reason
  """
  @callback get_asset_info(asset_id :: String.t()) :: {:ok, map()} | {:error, any()}

  @doc """
  Retrieves current market values for assets in the specified base currency.
  
  ## Parameters
    * `base_currency` - String identifier for the base currency (e.g., "USDT")
  
  Returns:
    * `{:ok, map()}` - Map of asset market values with keys as asset symbols
    * `{:error, reason}` - Error with reason
  """
  @callback get_market_values(base_currency :: String.t()) :: {:ok, map()} | {:error, any()}
  
  @doc """
  Starts a WebSocket connection for real-time updates.
  This should establish a persistent connection to the exchange's WebSocket API
  and set up handlers for relevant events (trades, balance updates, etc.).
  
  Returns:
    * `{:ok, reference}` - Reference to the WebSocket connection
    * `{:error, reason}` - Error with reason
  """
  @callback start_websocket() :: {:ok, reference()} | {:error, any()}
  
  @doc """
  Stops an active WebSocket connection.
  
  ## Parameters
    * `reference` - Reference to the WebSocket connection returned by start_websocket/0
  
  Returns:
    * `:ok` - Connection stopped successfully
    * `{:error, reason}` - Error with reason
  """
  @callback stop_websocket(reference :: reference()) :: :ok | {:error, any()}
  
  @doc """
  Registers a webhook endpoint with the exchange, if supported.
  This allows the exchange to push notifications to our system.
  
  ## Parameters
    * `endpoint` - URL of the webhook endpoint
    * `events` - List of event types to subscribe to
  
  Returns:
    * `{:ok, webhook_id}` - ID or reference for the registered webhook
    * `{:error, reason}` - Error with reason
    * `{:not_supported}` - If the exchange doesn't support webhooks
  """
  @callback register_webhook(endpoint :: String.t(), events :: list(String.t())) :: 
    {:ok, String.t()} | {:error, any()} | {:not_supported}
  
  @doc """
  Validates a webhook payload from the exchange.
  This should verify the authenticity of incoming webhook requests.
  
  ## Parameters
    * `payload` - The raw webhook payload
    * `headers` - HTTP headers from the webhook request
  
  Returns:
    * `{:ok, event_data}` - Validated and parsed event data
    * `{:error, reason}` - Error with reason
  """
  @callback validate_webhook(payload :: map(), headers :: map()) :: 
    {:ok, map()} | {:error, any()}
  
  @doc """
  Processes a real-time event from WebSocket or webhook.
  This should handle the event and update local state as needed.
  
  ## Parameters
    * `event` - The event data to process
    * `type` - The type of event (e.g., "trade", "balance_update")
  
  Returns:
    * `{:ok, result}` - Event processed successfully with result
    * `{:error, reason}` - Error with reason
  """
  @callback process_realtime_event(event :: map(), type :: String.t()) :: 
    {:ok, any()} | {:error, any()}

  @doc """
  Initializes the adapter with account-specific configuration.
  
  ## Parameters
    * `config` - Map containing configuration parameters
  
  Returns:
    * `{:ok, state}` - Initialized state
    * `{:error, reason}` - Error with reason
  """
  @callback init(config :: map()) :: {:ok, any()} | {:error, any()}
end
