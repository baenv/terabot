defmodule PortfolioManager.WebhookController do
  @moduledoc """
  Controller for handling incoming webhook requests from exchanges and blockchain services.
  Validates and processes webhook payloads, then forwards events to the appropriate adapter.
  """
  
  # Explicitly require the dependencies
  require Logger
  alias Core.Repo
  alias Core.Schema.Account
  
  # Add plug dependency to application
  Application.ensure_all_started(:plug)
  
  # Use Plug.Router
  use Plug.Router
  
  plug(Plug.Logger)
  plug(:match)
  plug(Plug.Parsers, parsers: [:json], json_decoder: Jason)
  plug(:dispatch)
  
  # Binance webhook endpoint
  post "/webhooks/binance/:account_id" do
    handle_webhook(conn, "binance", account_id)
  end
  
  # Uniswap webhook endpoint
  post "/webhooks/uniswap/:account_id" do
    handle_webhook(conn, "uniswap", account_id)
  end
  
  # Ethereum blockchain events endpoint
  post "/webhooks/ethereum/:account_id" do
    handle_webhook(conn, "ethereum", account_id)
  end
  
  # DEX-specific event endpoints
  post "/webhooks/dex/:dex_name/:account_id" do
    handle_dex_webhook(conn, dex_name, account_id)
  end
  
  # Blockchain transaction events endpoint
  post "/webhooks/blockchain/:chain_id/:account_id" do
    handle_blockchain_webhook(conn, chain_id, account_id)
  end
  
  # Generic webhook endpoint for future providers
  post "/webhooks/:provider/:account_id" do
    handle_webhook(conn, provider, account_id)
  end
  
  # Catch-all for unmatched routes
  match _ do
    send_resp(conn, 404, "Not found")
  end
  
  # Private functions
  
  defp handle_webhook(conn, provider, account_id) do
    # Get account from database
    case Repo.get(Account, account_id) do
      nil ->
        # Account not found
        Logger.warning("Webhook received for unknown account: #{account_id}")
        send_resp(conn, 404, "Account not found")
        
      account ->
        if account.active do
          # Get adapter module for provider
          adapter_module = get_adapter_module(provider)
          
          # Validate webhook payload
          case adapter_module.validate_webhook(conn.body_params, conn.req_headers) do
            {:ok, event_data} ->
              # Determine event type
              event_type = determine_event_type(provider, event_data)
              
              # Find adapter process
              adapter_name = {adapter_module, account.id}
              case Registry.lookup(PortfolioManager.AdapterRegistry, adapter_name) do
                [{pid, _}] ->
                  # Forward event to adapter
                  send(pid, {:webhook_event, event_data, event_type})
                  send_resp(conn, 200, "OK")
                  
                [] ->
                  # Adapter process not found
                  Logger.error("Adapter process not found for account #{account.id}")
                  send_resp(conn, 500, "Adapter not available")
              end
              
            {:error, reason} ->
              # Invalid webhook payload
              Logger.error("Invalid webhook payload: #{inspect(reason)}")
              send_resp(conn, 400, "Invalid payload")
          end
        else
          # Account is inactive
          Logger.warning("Webhook received for inactive account: #{account_id}")
          send_resp(conn, 403, "Account inactive")
        end
    end
  end
  
  defp handle_dex_webhook(conn, dex_name, account_id) do
    # Get account from database
    case Repo.get(Account, account_id) do
      nil ->
        # Account not found
        Logger.warning("DEX webhook received for unknown account: #{account_id}")
        send_resp(conn, 404, "Account not found")
        
      account ->
        if account.active do
          # Get adapter module for the DEX
          adapter_module = get_dex_adapter_module(dex_name)
          
          # Validate webhook payload
          case adapter_module.validate_webhook(conn.body_params, conn.req_headers) do
            {:ok, event_data} ->
              # Determine event type for DEX events
              event_type = determine_dex_event_type(dex_name, event_data)
              
              # Find adapter process
              adapter_name = {adapter_module, account.id}
              case Registry.lookup(PortfolioManager.AdapterRegistry, adapter_name) do
                [{pid, _}] ->
                  # Forward event to adapter
                  send(pid, {:dex_event, event_data, event_type})
                  
                  # Log the event for debugging
                  Logger.debug("DEX event received: #{dex_name}, type: #{event_type}")
                  
                  send_resp(conn, 200, "OK")
                  
                [] ->
                  # Adapter process not found
                  Logger.error("DEX adapter process not found for account #{account.id}")
                  send_resp(conn, 500, "Adapter not available")
              end
              
            {:error, reason} ->
              # Invalid webhook payload
              Logger.error("Invalid DEX webhook payload: #{inspect(reason)}")
              send_resp(conn, 400, "Invalid payload")
          end
        else
          # Account is inactive
          Logger.warning("DEX webhook received for inactive account: #{account_id}")
          send_resp(conn, 403, "Account inactive")
        end
    end
  end
  
  defp handle_blockchain_webhook(conn, chain_id, account_id) do
    # Get account from database
    case Repo.get(Account, account_id) do
      nil ->
        # Account not found
        Logger.warning("Blockchain webhook received for unknown account: #{account_id}")
        send_resp(conn, 404, "Account not found")
        
      account ->
        if account.active do
          # Get adapter module for the blockchain
          adapter_module = get_blockchain_adapter_module(chain_id)
          
          # Validate webhook payload
          case adapter_module.validate_webhook(conn.body_params, conn.req_headers) do
            {:ok, event_data} ->
              # Determine event type for blockchain events
              event_type = determine_blockchain_event_type(chain_id, event_data)
              
              # Find adapter process
              adapter_name = {adapter_module, account.id}
              case Registry.lookup(PortfolioManager.AdapterRegistry, adapter_name) do
                [{pid, _}] ->
                  # Forward event to adapter
                  send(pid, {:blockchain_event, event_data, event_type})
                  
                  # Log the event for debugging
                  Logger.debug("Blockchain event received: #{chain_id}, type: #{event_type}")
                  
                  send_resp(conn, 200, "OK")
                  
                [] ->
                  # Adapter process not found
                  Logger.error("Blockchain adapter process not found for account #{account.id}")
                  send_resp(conn, 500, "Adapter not available")
              end
              
            {:error, reason} ->
              # Invalid webhook payload
              Logger.error("Invalid blockchain webhook payload: #{inspect(reason)}")
              send_resp(conn, 400, "Invalid payload")
          end
        else
          # Account is inactive
          Logger.warning("Blockchain webhook received for inactive account: #{account_id}")
          send_resp(conn, 403, "Account inactive")
        end
    end
  end
  
  defp get_adapter_module("binance"), do: PortfolioManager.Adapters.BinanceAdapter
  defp get_adapter_module("uniswap"), do: PortfolioManager.Adapters.UniswapAdapter
  defp get_adapter_module("ethereum"), do: PortfolioManager.Adapters.EthereumAdapter
  defp get_adapter_module(provider), do: raise "Unsupported provider: #{provider}"
  
  defp determine_event_type("binance", event_data) do
    # Extract event type from Binance payload
    event_data["e"] || "unknown"
  end
  
  defp determine_event_type("uniswap", event_data) do
    # Extract event type from Uniswap payload
    event_data["type"] || "unknown"
  end
  
  defp determine_event_type("ethereum", event_data) do
    # Extract event type from Ethereum payload
    event_data["event_type"] || event_data["type"] || "unknown"
  end
  
  defp determine_event_type(_, _), do: "unknown"
  
  defp get_dex_adapter_module("uniswap"), do: PortfolioManager.Adapters.UniswapAdapter
  defp get_dex_adapter_module("sushiswap"), do: PortfolioManager.Adapters.UniswapAdapter # Reuse Uniswap adapter for now
  defp get_dex_adapter_module(dex_name), do: raise "Unsupported DEX: #{dex_name}"
  
  defp get_blockchain_adapter_module("1"), do: PortfolioManager.Adapters.EthereumAdapter # Ethereum Mainnet
  defp get_blockchain_adapter_module("56"), do: PortfolioManager.Adapters.EthereumAdapter # BSC
  defp get_blockchain_adapter_module("137"), do: PortfolioManager.Adapters.EthereumAdapter # Polygon
  defp get_blockchain_adapter_module(chain_id), do: raise "Unsupported blockchain: #{chain_id}"
  
  defp determine_dex_event_type("uniswap", event_data) do
    # Extract event type from Uniswap payload
    cond do
      Map.has_key?(event_data, "swap") -> "swap"
      Map.has_key?(event_data, "mint") -> "liquidity_added"
      Map.has_key?(event_data, "burn") -> "liquidity_removed"
      Map.has_key?(event_data, "sync") -> "pool_sync"
      true -> event_data["type"] || "unknown"
    end
  end
  
  defp determine_dex_event_type("sushiswap", event_data) do
    # Similar to Uniswap
    determine_dex_event_type("uniswap", event_data)
  end
  
  defp determine_dex_event_type(_, event_data) do
    event_data["type"] || "unknown"
  end
  
  defp determine_blockchain_event_type(_, event_data) do
    cond do
      Map.has_key?(event_data, "block") -> "new_block"
      Map.has_key?(event_data, "transaction") -> "transaction"
      Map.has_key?(event_data, "token_transfer") -> "token_transfer"
      Map.has_key?(event_data, "contract_event") -> "contract_event"
      true -> event_data["type"] || "unknown"
    end
  end
end
