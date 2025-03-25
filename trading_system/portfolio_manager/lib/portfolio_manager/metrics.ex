defmodule PortfolioManager.Metrics do
  @moduledoc """
  Performance metrics calculation for portfolio analysis.
  Provides functions for calculating ROI, volatility, and other performance metrics.
  """

  alias Core.Schema.PortfolioSnapshot
  alias Core.Repo
  import Ecto.Query, only: [from: 2]

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
  def calculate_roi(period, opts \\ %{}) do
    base_currency = Map.get(opts, :base_currency, "USDT")
    end_date = Map.get(opts, :end_date, DateTime.utc_now())

    # Calculate start date based on period
    start_date =
      case period do
        :daily -> DateTime.add(end_date, -1, :day)
        :weekly -> DateTime.add(end_date, -7, :day)
        :monthly -> DateTime.add(end_date, -30, :day)
        :yearly -> DateTime.add(end_date, -365, :day)
        _ -> raise "Invalid period: #{period}"
      end

    # Get snapshots for start and end dates
    start_snapshot = get_nearest_snapshot(start_date, base_currency)
    end_snapshot = get_nearest_snapshot(end_date, base_currency)

    case {start_snapshot, end_snapshot} do
      {nil, _} ->
        {:error, :insufficient_data}

      {_, nil} ->
        {:error, :insufficient_data}

      {start_snapshot, end_snapshot} ->
        # Calculate ROI
        start_value = start_snapshot.value
        end_value = end_snapshot.value

        if Decimal.eq?(start_value, Decimal.new(0)) do
          {:error, :division_by_zero}
        else
          roi =
            Decimal.div(
              Decimal.sub(end_value, start_value),
              start_value
            )

          {:ok, roi}
        end
    end
  end

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
  def calculate_volatility(period, opts \\ %{}) do
    base_currency = Map.get(opts, :base_currency, "USDT")
    end_date = Map.get(opts, :end_date, DateTime.utc_now())

    # Calculate start date and interval based on period
    {start_date, interval} =
      case period do
        :daily -> {DateTime.add(end_date, -1, :day), 1}
        :weekly -> {DateTime.add(end_date, -7, :day), 7}
        :monthly -> {DateTime.add(end_date, -30, :day), 30}
        :yearly -> {DateTime.add(end_date, -365, :day), 90}
        _ -> raise "Invalid period: #{period}"
      end

    # Get snapshots for the period
    snapshots =
      from(s in PortfolioSnapshot,
        where:
          s.timestamp >= ^start_date and s.timestamp <= ^end_date and
            s.base_currency == ^base_currency,
        order_by: [asc: s.timestamp]
      )
      |> Repo.all()

    if length(snapshots) < 2 do
      {:error, :insufficient_data}
    else
      # Calculate daily returns
      returns = calculate_returns(snapshots)

      # Calculate standard deviation of returns
      mean = Enum.sum(returns) / length(returns)

      sum_squared_diff =
        returns
        |> Enum.map(fn return -> :math.pow(return - mean, 2) end)
        |> Enum.sum()

      variance = sum_squared_diff / length(returns)
      volatility = :math.sqrt(variance)

      # Annualize volatility
      annualized_volatility = volatility * :math.sqrt(365 / interval)

      {:ok, Decimal.from_float(annualized_volatility)}
    end
  end

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
  def calculate_sharpe_ratio(period, opts \\ %{}) do
    base_currency = Map.get(opts, :base_currency, "USDT")
    risk_free_rate = Map.get(opts, :risk_free_rate, 0.02)

    # Calculate ROI
    case calculate_roi(period, opts) do
      {:ok, roi} ->
        # Calculate volatility
        case calculate_volatility(period, opts) do
          {:ok, volatility} ->
            # Convert Decimal to float for calculation
            roi_float = Decimal.to_float(roi)
            volatility_float = Decimal.to_float(volatility)

            # Calculate Sharpe ratio
            if volatility_float == 0 do
              {:error, :division_by_zero}
            else
              sharpe_ratio = (roi_float - risk_free_rate) / volatility_float
              {:ok, Decimal.from_float(sharpe_ratio)}
            end

          error ->
            error
        end

      error ->
        error
    end
  end

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
  def calculate_max_drawdown(period, opts \\ %{}) do
    base_currency = Map.get(opts, :base_currency, "USDT")
    end_date = Map.get(opts, :end_date, DateTime.utc_now())

    # Calculate start date based on period
    start_date =
      case period do
        :daily -> DateTime.add(end_date, -1, :day)
        :weekly -> DateTime.add(end_date, -7, :day)
        :monthly -> DateTime.add(end_date, -30, :day)
        :yearly -> DateTime.add(end_date, -365, :day)
        _ -> raise "Invalid period: #{period}"
      end

    # Get snapshots for the period
    snapshots =
      from(s in PortfolioSnapshot,
        where:
          s.timestamp >= ^start_date and s.timestamp <= ^end_date and
            s.base_currency == ^base_currency,
        order_by: [asc: s.timestamp]
      )
      |> Repo.all()

    if length(snapshots) < 2 do
      {:error, :insufficient_data}
    else
      # Calculate maximum drawdown
      {max_drawdown, _peak, _trough} = calculate_drawdown(snapshots)

      {:ok, max_drawdown}
    end
  end

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
  def calculate_asset_allocation(opts \\ %{}) do
    case PortfolioManager.Tracker.get_portfolio_summary(opts) do
      {:ok, summary} ->
        # Calculate percentages
        total_value = summary.total_value

        if Decimal.eq?(total_value, Decimal.new(0)) do
          {:error, :empty_portfolio}
        else
          allocation =
            summary.assets
            |> Enum.map(fn {asset, data} ->
              percentage = Decimal.div(data.value, total_value)
              {asset, %{percentage: percentage, value: data.value}}
            end)
            |> Enum.into(%{})

          {:ok, allocation}
        end

      error ->
        error
    end
  end

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
  def generate_performance_report(period, opts \\ %{}) do
    base_currency = Map.get(opts, :base_currency, "USDT")

    with {:ok, roi} <- calculate_roi(period, opts),
         {:ok, volatility} <- calculate_volatility(period, opts),
         {:ok, sharpe_ratio} <- calculate_sharpe_ratio(period, opts),
         {:ok, max_drawdown} <- calculate_max_drawdown(period, opts),
         {:ok, allocation} <- calculate_asset_allocation(opts),
         {:ok, summary} <- PortfolioManager.Tracker.get_portfolio_summary(opts) do
      # Generate report
      report = %{
        period: period,
        base_currency: base_currency,
        timestamp: DateTime.utc_now(),
        portfolio_value: summary.total_value,
        metrics: %{
          roi: roi,
          volatility: volatility,
          sharpe_ratio: sharpe_ratio,
          max_drawdown: max_drawdown
        },
        asset_allocation: allocation,
        accounts: summary.accounts
      }

      {:ok, report}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  # Private functions

  defp get_nearest_snapshot(date, base_currency) do
    # Get snapshot closest to the given date
    before_snapshot =
      from(s in PortfolioSnapshot,
        where: s.timestamp <= ^date and s.base_currency == ^base_currency,
        order_by: [desc: s.timestamp],
        limit: 1
      )
      |> Repo.one()

    after_snapshot =
      from(s in PortfolioSnapshot,
        where: s.timestamp >= ^date and s.base_currency == ^base_currency,
        order_by: [asc: s.timestamp],
        limit: 1
      )
      |> Repo.one()

    cond do
      is_nil(before_snapshot) and is_nil(after_snapshot) ->
        nil

      is_nil(before_snapshot) ->
        after_snapshot

      is_nil(after_snapshot) ->
        before_snapshot

      true ->
        # Return the closest snapshot
        before_diff = DateTime.diff(date, before_snapshot.timestamp, :second)
        after_diff = DateTime.diff(after_snapshot.timestamp, date, :second)

        if before_diff <= after_diff, do: before_snapshot, else: after_snapshot
    end
  end

  defp calculate_returns(snapshots) do
    snapshots
    |> Enum.chunk_every(2, 1, :discard)
    |> Enum.map(fn [prev, curr] ->
      prev_value = Decimal.to_float(prev.value)
      curr_value = Decimal.to_float(curr.value)

      if prev_value == 0, do: 0, else: (curr_value - prev_value) / prev_value
    end)
  end

  defp calculate_drawdown(snapshots) do
    # Extract values
    values = Enum.map(snapshots, fn s -> {s.timestamp, Decimal.to_float(s.value)} end)

    # Calculate maximum drawdown
    Enum.reduce(values, {Decimal.new(0), nil, nil, 0}, fn {timestamp, value},
                                                          {max_dd, peak_ts, trough_ts, peak} ->
      if value > peak do
        # New peak
        {max_dd, timestamp, trough_ts, value}
      else
        # Potential trough
        drawdown = if peak > 0, do: (peak - value) / peak, else: 0
        drawdown_decimal = Decimal.from_float(drawdown)

        if Decimal.gt?(drawdown_decimal, max_dd) do
          # New maximum drawdown
          {drawdown_decimal, peak_ts, timestamp, peak}
        else
          {max_dd, peak_ts, trough_ts, peak}
        end
      end
    end)
    |> then(fn {max_dd, peak_ts, trough_ts, _peak} -> {max_dd, peak_ts, trough_ts} end)
  end
end
