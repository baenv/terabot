defmodule PortfolioManager.Tracker.Worker do
  @moduledoc """
  Worker for tracking portfolio positions and balances.
  Monitors ETH balances, token balances, and liquidity pool positions
  across different DEXes (Uniswap and SushiSwap).
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub
  alias Core.Schema.Account
  alias Core.Schema.Portfolio

  # Client API

  @doc """
  Starts a portfolio tracker worker.

  ## Options
    * `:portfolio_id` - The portfolio ID to track
    * `:account_id` - The account ID associated with the portfolio
    * `:interval` - Update interval in milliseconds (default: 30000)
  """
  def start_link(opts) do
    portfolio_id = Keyword.fetch!(opts, :portfolio_id)
    account_id = Keyword.fetch!(opts, :account_id)
    name = {:via, Registry, {PortfolioManager.Registry, {__MODULE__, portfolio_id, account_id}}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets the current portfolio status.

  ## Parameters
    * `portfolio_id` - The portfolio ID
    * `account_id` - The account ID

  Returns:
    * `{:ok, status}` - The current portfolio status
    * `{:error, reason}` - Error with reason
  """
  def get_status(portfolio_id, account_id) do
    case Registry.lookup(PortfolioManager.Registry, {__MODULE__, portfolio_id, account_id}) do
      [{pid, _}] ->
        GenServer.call(pid, :get_status)

      [] ->
        {:error, :tracker_not_found}
    end
  end

  # Server callbacks

  @impl GenServer
  def init(opts) do
    portfolio_id = Keyword.fetch!(opts, :portfolio_id)
    account_id = Keyword.fetch!(opts, :account_id)
    interval = Keyword.get(opts, :interval, 30000)

    Logger.info("Starting portfolio tracker for portfolio #{portfolio_id} (account #{account_id})")

    # Schedule the first update
    schedule_update(interval)

    {:ok, %{
      portfolio_id: portfolio_id,
      account_id: account_id,
      interval: interval,
      last_update: nil,
      status: :initializing
    }}
  end

  @impl GenServer
  def handle_call(:get_status, _from, state) do
    {:reply, {:ok, state.status}, state}
  end

  @impl GenServer
  def handle_info(:update, state) do
    # Update portfolio status
    new_state = update_portfolio_status(state)

    # Schedule next update
    schedule_update(state.interval)

    {:noreply, new_state}
  end

  # Private functions

  defp schedule_update(interval) do
    Process.send_after(self(), :update, interval)
  end

  defp update_portfolio_status(state) do
    with {:ok, portfolio} <- get_portfolio(state.portfolio_id),
         {:ok, account} <- get_account(state.account_id),
         {:ok, eth_balance} <- get_eth_balance(account.id),
         {:ok, token_balances} <- get_token_balances(account.id, portfolio.tokens),
         {:ok, lp_positions} <- get_lp_positions(account.id, portfolio.lp_pairs) do

      # Prepare portfolio status
      status = %{
        eth_balance: eth_balance,
        token_balances: token_balances,
        lp_positions: lp_positions,
        last_update: DateTime.utc_now()
      }

      # Broadcast portfolio update
      broadcast_portfolio_update(state.portfolio_id, status)

      # Update state
      %{state | status: status, last_update: DateTime.utc_now()}
    else
      {:error, reason} ->
        Logger.error("Failed to update portfolio status: #{inspect(reason)}")
        %{state | status: :error}
    end
  end

  defp get_portfolio(portfolio_id) do
    case Core.Repo.get(Portfolio, portfolio_id) do
      nil ->
        {:error, :portfolio_not_found}

      portfolio ->
        {:ok, portfolio}
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

  defp get_eth_balance(account_id) do
    PortfolioManager.EthereumAdapter.get_balance(account_id)
  end

  defp get_token_balances(account_id, tokens) do
    # Get balances for all tokens in the portfolio
    balances = Enum.reduce(tokens, %{}, fn token, acc ->
      case PortfolioManager.EthereumAdapter.get_token_balance(account_id, token.address) do
        {:ok, balance} ->
          Map.put(acc, token.symbol, balance)

        {:error, reason} ->
          Logger.error("Failed to get balance for token #{token.symbol}: #{inspect(reason)}")
          acc
      end
    end)

    {:ok, balances}
  end

  defp get_lp_positions(account_id, lp_pairs) do
    # Get LP positions for all pairs in the portfolio
    positions = Enum.reduce(lp_pairs, %{}, fn pair, acc ->
      case get_lp_position(account_id, pair) do
        {:ok, position} ->
          Map.put(acc, pair.id, position)

        {:error, reason} ->
          Logger.error("Failed to get LP position for pair #{pair.id}: #{inspect(reason)}")
          acc
      end
    end)

    {:ok, positions}
  end

  defp get_lp_position(account_id, pair) do
    # Get LP position based on the DEX
    case pair.dex do
      :uniswap ->
        PortfolioManager.UniswapAdapter.get_lp_position(account_id, pair.token0_address, pair.token1_address)

      :sushiswap ->
        PortfolioManager.SushiSwapAdapter.get_lp_position(account_id, pair.token0_address, pair.token1_address)

      _ ->
        {:error, "Unsupported DEX: #{pair.dex}"}
    end
  end

  defp broadcast_portfolio_update(portfolio_id, status) do
    PubSub.broadcast(
      PortfolioManager.PubSub,
      "portfolio:update",
      {:portfolio_updated, portfolio_id, status}
    )
  end
end
