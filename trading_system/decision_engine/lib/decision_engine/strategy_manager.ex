defmodule DecisionEngine.StrategyManager do
  @moduledoc """
  Manages trading strategies and their lifecycle.
  Handles strategy registration, activation, and deactivation.
  """

  use GenServer
  require Logger
  alias Phoenix.PubSub

  # Client API

  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Registers a new trading strategy.
  """
  def register_strategy(strategy_module, config) do
    GenServer.call(__MODULE__, {:register_strategy, strategy_module, config})
  end

  @doc """
  Activates a registered strategy.
  """
  def activate_strategy(strategy_id) do
    GenServer.call(__MODULE__, {:activate_strategy, strategy_id})
  end

  @doc """
  Deactivates a running strategy.
  """
  def deactivate_strategy(strategy_id) do
    GenServer.call(__MODULE__, {:deactivate_strategy, strategy_id})
  end

  @doc """
  Lists all registered strategies.
  """
  def list_strategies do
    GenServer.call(__MODULE__, :list_strategies)
  end

  # Server callbacks

  @impl true
  def init(_opts) do
    {:ok, %{
      strategies: %{},  # Map of strategy_id => strategy_info
      active_strategies: MapSet.new()  # Set of active strategy_ids
    }}
  end

  @impl true
  def handle_call({:register_strategy, strategy_module, config}, _from, state) do
    strategy_id = generate_strategy_id()

    strategy_info = %{
      id: strategy_id,
      module: strategy_module,
      config: config,
      registered_at: DateTime.utc_now()
    }

    strategies = Map.put(state.strategies, strategy_id, strategy_info)

    Logger.info("Registered new strategy: #{inspect(strategy_module)} with ID #{strategy_id}")

    {:reply, {:ok, strategy_id}, %{state | strategies: strategies}}
  end

  @impl true
  def handle_call({:activate_strategy, strategy_id}, _from, state) do
    case Map.get(state.strategies, strategy_id) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}

      strategy_info ->
        if MapSet.member?(state.active_strategies, strategy_id) do
          {:reply, {:error, :already_active}, state}
        else
          # Here we would start the actual strategy process
          # For now, we just mark it as active
          active_strategies = MapSet.put(state.active_strategies, strategy_id)

          Logger.info("Activated strategy #{strategy_id}")

          PubSub.broadcast(
            DecisionEngine.PubSub,
            "strategies",
            {:strategy_activated, strategy_id}
          )

          {:reply, :ok, %{state | active_strategies: active_strategies}}
        end
    end
  end

  @impl true
  def handle_call({:deactivate_strategy, strategy_id}, _from, state) do
    case Map.get(state.strategies, strategy_id) do
      nil ->
        {:reply, {:error, :strategy_not_found}, state}

      _strategy_info ->
        if MapSet.member?(state.active_strategies, strategy_id) do
          # Here we would stop the actual strategy process
          # For now, we just mark it as inactive
          active_strategies = MapSet.delete(state.active_strategies, strategy_id)

          Logger.info("Deactivated strategy #{strategy_id}")

          PubSub.broadcast(
            DecisionEngine.PubSub,
            "strategies",
            {:strategy_deactivated, strategy_id}
          )

          {:reply, :ok, %{state | active_strategies: active_strategies}}
        else
          {:reply, {:error, :not_active}, state}
        end
    end
  end

  @impl true
  def handle_call(:list_strategies, _from, state) do
    strategies_list = Enum.map(state.strategies, fn {id, info} ->
      Map.put(info, :active?, MapSet.member?(state.active_strategies, id))
    end)

    {:reply, {:ok, strategies_list}, state}
  end

  # Private functions

  defp generate_strategy_id do
    :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower)
  end
end
