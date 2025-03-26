defmodule TradingSystemMain.Cache do
  @moduledoc """
  System-wide caching module using ETS tables.
  Provides fast in-memory storage for frequently accessed data.
  """

  use GenServer
  require Logger

  # Client API

  @doc """
  Starts the cache server.
  """
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  @doc """
  Gets a value from the cache.

  ## Parameters
    * `key` - The cache key

  Returns:
    * `{:ok, value}` - The cached value
    * `:error` - Key not found
  """
  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  @doc """
  Puts a value in the cache.

  ## Parameters
    * `key` - The cache key
    * `value` - The value to cache
    * `ttl` - Time to live in seconds (optional)

  Returns:
    * `:ok` - Value cached successfully
    * `{:error, reason}` - Error with reason
  """
  def put(key, value, ttl \\ nil) do
    GenServer.call(__MODULE__, {:put, key, value, ttl})
  end

  @doc """
  Deletes a value from the cache.

  ## Parameters
    * `key` - The cache key

  Returns:
    * `:ok` - Value deleted successfully
    * `{:error, reason}` - Error with reason
  """
  def delete(key) do
    GenServer.call(__MODULE__, {:delete, key})
  end

  @doc """
  Clears all values from the cache.

  Returns:
    * `:ok` - Cache cleared successfully
    * `{:error, reason}` - Error with reason
  """
  def clear do
    GenServer.call(__MODULE__, :clear)
  end

  # Server callbacks

  @impl GenServer
  def init(_state) do
    # Create ETS tables for caching
    :ets.new(:cache_data, [:named_table, :set, :public])
    :ets.new(:cache_ttl, [:named_table, :set, :public])

    # Schedule periodic cleanup of expired entries
    schedule_cleanup()

    {:ok, %{}}
  end

  @impl GenServer
  def handle_call({:get, key}, _from, state) do
    case get_cached_value(key) do
      {:ok, value} ->
        {:reply, {:ok, value}, state}

      :error ->
        {:reply, :error, state}
    end
  end

  @impl GenServer
  def handle_call({:put, key, value, ttl}, _from, state) do
    # Store the value
    :ets.insert(:cache_data, {key, value})

    # Store TTL if specified
    if ttl do
      expires_at = System.system_time(:second) + ttl
      :ets.insert(:cache_ttl, {key, expires_at})
    end

    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call({:delete, key}, _from, state) do
    :ets.delete(:cache_data, key)
    :ets.delete(:cache_ttl, key)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_call(:clear, _from, state) do
    :ets.delete_all_objects(:cache_data)
    :ets.delete_all_objects(:cache_ttl)
    {:reply, :ok, state}
  end

  @impl GenServer
  def handle_info(:cleanup, state) do
    # Clean up expired entries
    cleanup_expired_entries()

    # Schedule next cleanup
    schedule_cleanup()

    {:noreply, state}
  end

  # Private functions

  defp get_cached_value(key) do
    case :ets.lookup(:cache_ttl, key) do
      [{^key, expires_at}] ->
        if System.system_time(:second) < expires_at do
          case :ets.lookup(:cache_data, key) do
            [{^key, value}] ->
              {:ok, value}

            [] ->
              :error
          end
        else
          # Entry expired, clean it up
          :ets.delete(:cache_data, key)
          :ets.delete(:cache_ttl, key)
          :error
        end

      [] ->
        # No TTL entry, check if value exists
        case :ets.lookup(:cache_data, key) do
          [{^key, value}] ->
            {:ok, value}

          [] ->
            :error
        end
    end
  end

  defp cleanup_expired_entries do
    now = System.system_time(:second)

    # Find all expired entries
    expired_keys = :ets.match_object(:cache_ttl, {:'$1', :'$2'})
    |> Enum.filter(fn {_key, expires_at} -> now >= expires_at end)
    |> Enum.map(fn {key, _expires_at} -> key end)

    # Remove expired entries
    Enum.each(expired_keys, fn key ->
      :ets.delete(:cache_data, key)
      :ets.delete(:cache_ttl, key)
    end)
  end

  defp schedule_cleanup do
    # Clean up every 5 minutes
    Process.send_after(self(), :cleanup, 5 * 60 * 1000)
  end
end
