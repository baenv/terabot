defmodule WebDashboard.Telemetry do
  @moduledoc """
  Telemetry metrics module for the Web Dashboard application.

  This module defines metrics that help monitor system performance and health.
  """
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      # Telemetry poller for periodic measurements
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("core.repo.query.total_time",
        unit: {:native, :millisecond},
        description: "The sum of the other measurements"
      ),
      summary("core.repo.query.decode_time",
        unit: {:native, :millisecond},
        description: "The time spent decoding the data received from the database"
      ),
      summary("core.repo.query.query_time",
        unit: {:native, :millisecond},
        description: "The time spent executing the query"
      ),
      summary("core.repo.query.queue_time",
        unit: {:native, :millisecond},
        description: "The time spent waiting for a database connection"
      ),
      summary("core.repo.query.idle_time",
        unit: {:native, :millisecond},
        description: "The time the connection spent waiting before being checked out for the query"
      ),

      # Portfolio Metrics
      summary("portfolio_manager.update.duration",
        unit: {:native, :millisecond},
        description: "Portfolio update duration"
      ),
      last_value("portfolio_manager.total_value",
        description: "Total portfolio value"
      ),

      # Order Metrics
      summary("order_manager.execute.duration",
        unit: {:native, :millisecond},
        description: "Order execution duration"
      ),

      # System Metrics
      last_value("web_dashboard.vm.process_count",
        description: "Total number of processes"
      ),
      last_value("web_dashboard.vm.memory.total",
        unit: :byte,
        description: "Total memory allocated"
      ),
      last_value("web_dashboard.vm.memory.processes",
        unit: :byte,
        description: "Memory allocated for processes"
      ),
      last_value("web_dashboard.vm.system.schedulers_online",
        description: "Number of schedulers online"
      )
    ]
  end

  defp periodic_measurements do
    [
      # Custom metrics - simpler is better for now
      {WebDashboard.Metrics, :collect_system_metrics, []}
    ]
  end
end
