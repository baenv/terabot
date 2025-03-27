defmodule WebDashboard.Metrics do
  @moduledoc """
  Provides metrics collection for the web dashboard.
  Collects system metrics and emits them as telemetry events.
  """
  require Logger

  @doc """
  Collects system metrics and emits them as telemetry events.
  Called by the telemetry_poller.
  """
  def collect_system_metrics do
    # Process count
    process_count = :erlang.system_info(:process_count)
    :telemetry.execute([:web_dashboard, :vm], %{process_count: process_count}, %{})

    # Memory usage - convert to map
    memory_data = :erlang.memory()
    memory_map = memory_data |> Enum.into(%{})
    :telemetry.execute([:web_dashboard, :vm, :memory], memory_map, %{})

    # CPU usage and load
    system_info = %{
      schedulers: :erlang.system_info(:schedulers),
      schedulers_online: :erlang.system_info(:schedulers_online)
    }
    :telemetry.execute([:web_dashboard, :vm, :system], system_info, %{})

    # Collect GC info - convert to map
    {_, gc_stats} = :erlang.process_info(self(), :garbage_collection)
    gc_map = gc_stats |> Enum.into(%{})
    :telemetry.execute([:web_dashboard, :vm, :garbage_collection], gc_map, %{})
  end
end
