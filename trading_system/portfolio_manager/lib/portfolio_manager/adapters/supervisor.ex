defmodule PortfolioManager.Adapters.Supervisor do
  @moduledoc """
  Supervisor for portfolio adapter processes.
  Dynamically supervises adapter instances for different accounts.
  """
  
  use DynamicSupervisor
  require Logger
  
  @doc """
  Starts the adapter supervisor.
  """
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end
  
  @doc """
  Starts an adapter for a specific account.
  
  ## Parameters
    * `adapter_module` - The adapter module to use (e.g., BinanceAdapter)
    * `config` - Configuration for the adapter
  
  Returns:
    * `{:ok, pid}` - The PID of the started adapter
    * `{:error, reason}` - Error with reason
  """
  def start_adapter(adapter_module, config) do
    # Validate adapter module implements the required behavior
    unless adapter_module.module_info(:attributes)[:behaviour] == [PortfolioManager.Adapters.AdapterBehaviour] do
      Logger.error("Module #{inspect(adapter_module)} does not implement AdapterBehaviour")
      {:error, :invalid_adapter}
    else
      DynamicSupervisor.start_child(__MODULE__, {adapter_module, config})
    end
  end
  
  @doc """
  Stops an adapter for a specific account.
  
  ## Parameters
    * `adapter_module` - The adapter module
    * `account_id` - The account ID
  
  Returns:
    * `:ok` - The adapter was stopped
    * `{:error, reason}` - Error with reason
  """
  def stop_adapter(adapter_module, account_id) do
    case Registry.lookup(PortfolioManager.AdapterRegistry, {adapter_module, account_id}) do
      [{pid, _}] -> 
        DynamicSupervisor.terminate_child(__MODULE__, pid)
      [] -> 
        {:error, :not_found}
    end
  end
  
  @doc """
  Lists all running adapters.
  
  Returns a list of {adapter_module, account_id, pid} tuples.
  """
  def list_adapters do
    Registry.select(PortfolioManager.AdapterRegistry, [{{:"$1", :"$2", :"$3"}, [], [{{:"$1", :"$2", :"$3"}}]}])
  end
  
  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
