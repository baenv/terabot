defmodule Core.Metrics do
  @moduledoc """
  Provides metrics collection for the Core application.
  Collects database metrics and other core system metrics.
  """
  require Logger

  @doc """
  Collects database metrics and emits them as telemetry events.
  Called by the telemetry_poller.
  """
  def collect_db_metrics do
    # Repo statistics
    try do
      stats = Core.Repo.__telemetry_aggregates__()
      :telemetry.execute([:core, :repo, :statistics], stats, %{})
    rescue
      e ->
        Logger.error("Failed to collect repo metrics: #{inspect(e)}")
    end
  end
end
