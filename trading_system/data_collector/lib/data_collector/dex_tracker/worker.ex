defmodule DataCollector.DexTracker.Worker do
  @moduledoc """
  Worker for tracking prices on decentralized exchanges.
  Collects and monitors price data for specific token pairs on various DEXes.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub

  # Client API

  @doc """
  Starts a DEX tracker worker.

  ## Options
    * `:dex` - The DEX to track (e.g., :uniswap, :sushiswap)
    * `:token_pair` - The token pair to track (e.g., "ETH/USDT")
    * `:interval` - Polling interval in milliseconds (default: 30_000)
  """
  def start_link(opts) do
    dex = Keyword.fetch!(opts, :dex)
    token_pair = Keyword.fetch!(opts, :token_pair)
    name = {:via, Registry, {DataCollector.Registry, {__MODULE__, dex, token_pair}}}
    GenServer.start_link(__MODULE__, opts, name: name)
  end

  @doc """
  Gets the latest price for a token pair on a specific DEX.

  ## Parameters
    * `dex` - The DEX to query (e.g., :uniswap, :sushiswap)
    * `token_pair` - The token pair to query (e.g., "ETH/USDT")

  Returns:
    * `{:ok, price}` - The latest price
    * `{:error, reason}` - Error with reason
  """
  def get_latest_price(dex, token_pair) do
    case Registry.lookup(DataCollector.Registry, {__MODULE__, dex, token_pair}) do
      [{pid, _}] ->
        GenServer.call(pid, :get_latest_price)

      [] ->
        {:error, :tracker_not_found}
    end
  end

  @doc """
  Gets historical prices for a token pair on a specific DEX.

  ## Parameters
    * `dex` - The DEX to query (e.g., :uniswap, :sushiswap)
    * `token_pair` - The token pair to query (e.g., "ETH/USDT")
    * `period` - The time period to query (e.g., :hour, :day, :week)

  Returns:
    * `{:ok, prices}` - The historical prices
    * `{:error, reason}` - Error with reason
  """
  def get_historical_prices(dex, token_pair, period) do
    case Registry.lookup(DataCollector.Registry, {__MODULE__, dex, token_pair}) do
      [{pid, _}] ->
        GenServer.call(pid, {:get_historical_prices, period})

      [] ->
        {:error, :tracker_not_found}
    end
  end

  # Server callbacks

  @impl GenServer
  def init(opts) do
    dex = Keyword.fetch!(opts, :dex)
    token_pair = Keyword.fetch!(opts, :token_pair)
    interval = Keyword.get(opts, :interval, 30_000)

    Logger.info("Starting DEX tracker for #{dex}:#{token_pair} with interval #{interval}ms")

    # Schedule the first price update
    schedule_price_update(interval)

    {:ok, %{
      dex: dex,
      token_pair: token_pair,
      interval: interval,
      latest_price: nil,
      historical_prices: %{
        hour: [],
        day: [],
        week: []
      },
      last_update: nil
    }}
  end

  @impl GenServer
  def handle_call(:get_latest_price, _from, state) do
    {:reply, {:ok, state.latest_price}, state}
  end

  @impl GenServer
  def handle_call({:get_historical_prices, period}, _from, state) do
    prices = Map.get(state.historical_prices, period, [])
    {:reply, {:ok, prices}, state}
  end

  @impl GenServer
  def handle_info(:update_price, state) do
    # Update price data
    new_state = update_price_data(state)

    # Schedule next update
    schedule_price_update(state.interval)

    {:noreply, new_state}
  end

  # Private functions

  defp schedule_price_update(interval) do
    Process.send_after(self(), :update_price, interval)
  end

  defp update_price_data(state) do
    # Fetch latest price from the DEX
    case fetch_dex_price(state.dex, state.token_pair) do
      {:ok, price} ->
        now = DateTime.utc_now()

        # Only broadcast if price changed
        if price != state.latest_price do
          Logger.info("#{state.dex}:#{state.token_pair} price updated: #{price}")
          PubSub.broadcast(
            DataCollector.PubSub,
            "dex:#{state.dex}:#{state.token_pair}",
            {:price_update, state.dex, state.token_pair, price, now}
          )
        end

        # Update historical price data
        historical_prices = update_historical_prices(state.historical_prices, price, now)

        # Return updated state
        %{state |
          latest_price: price,
          historical_prices: historical_prices,
          last_update: now
        }

      {:error, reason} ->
        Logger.error("Failed to fetch price for #{state.dex}:#{state.token_pair}: #{reason}")
        state
    end
  end

  defp fetch_dex_price(dex, token_pair) do
    # Make API call to fetch price from the DEX
    # This is a simplified implementation

    # In a real implementation, this would call DEX-specific APIs or smart contracts
    case dex do
      :uniswap ->
        fetch_uniswap_price(token_pair)

      :sushiswap ->
        fetch_sushiswap_price(token_pair)

      _ ->
        {:error, "Unsupported DEX: #{dex}"}
    end
  end

  defp fetch_uniswap_price(token_pair) do
    # Simulate fetching price from Uniswap
    # In a real implementation, this would query the Uniswap contracts or API

    # For demonstration, we'll generate a random price around a base value
    # based on the token pair
    base_price = case token_pair do
      "ETH/USDT" -> 2000.0
      "ETH/USDC" -> 2000.0
      "WBTC/ETH" -> 0.065
      _ -> 100.0
    end

    # Add some random variation
    variation = ((:rand.uniform() - 0.5) * 0.02) * base_price
    price = base_price + variation

    {:ok, price}
  end

  defp fetch_sushiswap_price(token_pair) do
    # Simulate fetching price from SushiSwap
    # In a real implementation, this would query the SushiSwap contracts or API

    # For demonstration, we'll generate a random price around a base value
    # slightly different from Uniswap to simulate price differences
    base_price = case token_pair do
      "ETH/USDT" -> 2001.0
      "ETH/USDC" -> 2001.0
      "WBTC/ETH" -> 0.0651
      _ -> 101.0
    end

    # Add some random variation
    variation = ((:rand.uniform() - 0.5) * 0.02) * base_price
    price = base_price + variation

    {:ok, price}
  end

  defp update_historical_prices(historical_prices, latest_price, timestamp) do
    # Add the latest price to historical data sets
    hour_prices = [%{price: latest_price, timestamp: timestamp} | historical_prices.hour]
    |> Enum.take(60) # Keep up to 60 data points for hour view

    day_prices = if rem(System.os_time(:second), 300) < 30 do
      # Add to day prices every 5 minutes
      [%{price: latest_price, timestamp: timestamp} | historical_prices.day]
      |> Enum.take(288) # Keep up to 288 data points for day view (5-minute intervals)
    else
      historical_prices.day
    end

    week_prices = if rem(System.os_time(:second), 3600) < 30 do
      # Add to week prices every hour
      [%{price: latest_price, timestamp: timestamp} | historical_prices.week]
      |> Enum.take(168) # Keep up to 168 data points for week view (hourly)
    else
      historical_prices.week
    end

    %{
      hour: hour_prices,
      day: day_prices,
      week: week_prices
    }
  end
end
