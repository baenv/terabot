defmodule TradingSystemMain.Web.Health do
  @moduledoc """
  Provides health check functionality for the system components.
  """

  @doc """
  Performs a basic health check.
  """
  def check do
    Jason.encode!(%{
      status: "ok",
      version: "0.1.0",
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Checks the health of all components.
  """
  def check_components do
    components = %{
      core: check_service(:core),
      data_collector: check_service(:data_collector),
      portfolio_manager: check_service(:portfolio_manager),
      order_manager: check_service(:order_manager),
      decision_engine: check_service(:decision_engine),
      data_processor: check_service(:data_processor)
    }

    Jason.encode!(%{
      status: "ok",
      components: components,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  end

  @doc """
  Checks the health of a specific component.
  """
  def check_component(component) do
    component_atom = String.to_existing_atom(component)
    result = check_service(component_atom)

    Jason.encode!(%{
      status: if(result.status == "ok", do: "ok", else: "error"),
      component: result,
      timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
    })
  rescue
    _ ->
      Jason.encode!(%{
        status: "error",
        error: "Component not found or invalid",
        timestamp: DateTime.utc_now() |> DateTime.to_iso8601()
      })
  end

  # Private functions

  defp check_service(service_name) do
    # In a real implementation, this would check the actual service status
    # For now, return a simulated status
    %{
      name: service_name,
      status: "ok",
      details: "Service is running"
    }
  end
end
