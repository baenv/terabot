defmodule DecisionEngine.SignalProcessor do
  @moduledoc """
  Processes trading signals from various strategies and converts them into actionable orders.
  Handles signal validation, aggregation, and order generation.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Process a new trading signal.
  """
  def process_signal(signal) do
    GenServer.cast(__MODULE__, {:process_signal, signal})
  end

  @doc """
  Get current signal statistics.
  """
  def get_stats do
    GenServer.call(__MODULE__, :get_stats)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    # Subscribe to strategy events
    PubSub.subscribe(DecisionEngine.PubSub, "strategies")

    {:ok, %{
      processed_signals: 0,
      generated_orders: 0,
      rejected_signals: 0,
      last_signal: nil,
      last_processed_at: nil
    }}
  end

  @impl true
  def handle_cast({:process_signal, signal}, state) do
    # Validate and process the signal
    case validate_signal(signal) do
      :ok ->
        # Convert signal to order
        case generate_order(signal) do
          {:ok, order} ->
            # Broadcast the generated order
            PubSub.broadcast(
              DecisionEngine.PubSub,
              "orders",
              {:new_order, order}
            )

            Logger.info("Generated order from signal: #{inspect(order)}")

            {:noreply, %{state |
              processed_signals: state.processed_signals + 1,
              generated_orders: state.generated_orders + 1,
              last_signal: signal,
              last_processed_at: DateTime.utc_now()
            }}

          {:error, reason} ->
            Logger.warn("Failed to generate order from signal: #{inspect(reason)}")

            {:noreply, %{state |
              processed_signals: state.processed_signals + 1,
              rejected_signals: state.rejected_signals + 1,
              last_signal: signal,
              last_processed_at: DateTime.utc_now()
            }}
        end

      {:error, reason} ->
        Logger.warn("Invalid signal received: #{inspect(reason)}")

        {:noreply, %{state |
          processed_signals: state.processed_signals + 1,
          rejected_signals: state.rejected_signals + 1,
          last_signal: signal,
          last_processed_at: DateTime.utc_now()
        }}
    end
  end

  @impl true
  def handle_call(:get_stats, _from, state) do
    stats = %{
      processed_signals: state.processed_signals,
      generated_orders: state.generated_orders,
      rejected_signals: state.rejected_signals,
      last_signal: state.last_signal,
      last_processed_at: state.last_processed_at
    }

    {:reply, {:ok, stats}, state}
  end

  @impl true
  def handle_info({:strategy_activated, strategy_id}, state) do
    Logger.info("Strategy #{strategy_id} activated, ready to process its signals")
    {:noreply, state}
  end

  @impl true
  def handle_info({:strategy_deactivated, strategy_id}, state) do
    Logger.info("Strategy #{strategy_id} deactivated, will ignore its signals")
    {:noreply, state}
  end

  # Private functions

  defp validate_signal(signal) do
    # Implement signal validation logic
    # For now, just check if required fields are present
    required_fields = [:strategy_id, :type, :asset_pair, :price, :amount]

    case Enum.find(required_fields, fn field -> !Map.has_key?(signal, field) end) do
      nil -> :ok
      field -> {:error, "Missing required field: #{field}"}
    end
  end

  defp generate_order(signal) do
    # Convert signal to order format
    # This is a simplified implementation
    order = %{
      strategy_id: signal.strategy_id,
      type: signal.type,
      asset_pair: signal.asset_pair,
      price: signal.price,
      amount: signal.amount,
      created_at: DateTime.utc_now()
    }

    {:ok, order}
  end
end
