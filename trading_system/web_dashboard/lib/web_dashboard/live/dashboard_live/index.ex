defmodule WebDashboard.DashboardLive.Index do
  use Phoenix.LiveView
  alias Phoenix.LiveView.JS

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Set up periodic refresh if needed
      :timer.send_interval(30000, self(), :refresh)
    end

    socket =
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:loading, false)
      |> assign(:system_status, %{status: "running"})
      |> assign(:stats, %{
        accounts: 0,
        transactions: 0,
        orders: 0
      })

    {:ok, socket}
  end

  def handle_event("refresh", _, socket) do
    send(self(), :refresh)
    {:noreply, assign(socket, :loading, true)}
  end

  def handle_info(:refresh, socket) do
    # Fetch latest data in a real implementation
    {:noreply, socket |> assign(:loading, false)}
  end

  def render(assigns) do
    ~H"""
    <div class="py-6">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 md:px-8">
        <div class="flex justify-between items-center mb-4">
          <h1 class="text-2xl font-semibold text-gray-900">Trading Dashboard</h1>
          <button
            phx-click="refresh"
            class="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            disabled={@loading}
          >
            <svg xmlns="http://www.w3.org/2000/svg" class={"h-4 w-4 mr-1 #{if @loading, do: "animate-spin"}"} viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <path stroke-linecap="round" stroke-linejoin="round" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Refresh
          </button>
        </div>

        <!-- System Status -->
        <div class="bg-white shadow overflow-hidden sm:rounded-lg mb-6">
          <div class="px-4 py-5 sm:px-6 flex justify-between items-center">
            <div>
              <h3 class="text-lg leading-6 font-medium text-gray-900">System Status</h3>
              <p class="mt-1 max-w-2xl text-sm text-gray-500">Current status of the trading system</p>
            </div>
            <div class="flex items-center">
              <div class={"h-3 w-3 rounded-full #{if @system_status.status == "running", do: "bg-green-500", else: "bg-red-500"} mr-2"}></div>
              <span class="text-sm font-medium">
                <%= String.capitalize(@system_status.status) %>
              </span>
            </div>
          </div>
        </div>

        <!-- Stats Overview -->
        <div class="grid grid-cols-1 gap-5 sm:grid-cols-2 lg:grid-cols-3 mb-6">
          <!-- Account Stats -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0 bg-indigo-500 rounded-md p-3">
                  <svg class="h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dt class="text-sm font-medium text-gray-500 truncate">Total Accounts</dt>
                  <dd class="flex items-baseline">
                    <div class="text-2xl font-semibold text-gray-900"><%= @stats.accounts %></div>
                  </dd>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-4 sm:px-6">
              <div class="text-sm">
                <a href="/accounts" class="font-medium text-indigo-600 hover:text-indigo-500">View all accounts</a>
              </div>
            </div>
          </div>

          <!-- Transaction Stats -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0 bg-green-500 rounded-md p-3">
                  <svg class="h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7h12m0 0l-4-4m4 4l-4 4m0 6H4m0 0l4 4m-4-4l4-4" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dt class="text-sm font-medium text-gray-500 truncate">Total Transactions</dt>
                  <dd class="flex items-baseline">
                    <div class="text-2xl font-semibold text-gray-900"><%= @stats.transactions %></div>
                  </dd>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-4 sm:px-6">
              <div class="text-sm">
                <a href="/transactions" class="font-medium text-indigo-600 hover:text-indigo-500">View all transactions</a>
              </div>
            </div>
          </div>

          <!-- Order Stats -->
          <div class="bg-white overflow-hidden shadow rounded-lg">
            <div class="px-4 py-5 sm:p-6">
              <div class="flex items-center">
                <div class="flex-shrink-0 bg-yellow-500 rounded-md p-3">
                  <svg class="h-6 w-6 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
                  </svg>
                </div>
                <div class="ml-5 w-0 flex-1">
                  <dt class="text-sm font-medium text-gray-500 truncate">Active Orders</dt>
                  <dd class="flex items-baseline">
                    <div class="text-2xl font-semibold text-gray-900"><%= @stats.orders %></div>
                  </dd>
                </div>
              </div>
            </div>
            <div class="bg-gray-50 px-4 py-4 sm:px-6">
              <div class="text-sm">
                <a href="/orders" class="font-medium text-indigo-600 hover:text-indigo-500">View all orders</a>
              </div>
            </div>
          </div>
        </div>

        <!-- Quick Actions -->
        <div class="bg-white shadow sm:rounded-lg mb-6">
          <div class="px-4 py-5 sm:px-6">
            <h3 class="text-lg leading-6 font-medium text-gray-900">Quick Actions</h3>
            <p class="mt-1 max-w-2xl text-sm text-gray-500">Common trading system operations</p>
          </div>
          <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
            <dl class="sm:divide-y sm:divide-gray-200">
              <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">Create New Account</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <button
                    class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  >
                    Create Account
                  </button>
                </dd>
              </div>
              <div class="py-4 sm:py-5 sm:grid sm:grid-cols-3 sm:gap-4 sm:px-6">
                <dt class="text-sm font-medium text-gray-500">System Control</dt>
                <dd class="mt-1 text-sm text-gray-900 sm:mt-0 sm:col-span-2">
                  <div class="flex space-x-3">
                    <button class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-green-600 hover:bg-green-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500">
                      Start System
                    </button>
                    <button class="inline-flex items-center px-3 py-1.5 border border-transparent text-xs font-medium rounded shadow-sm text-white bg-red-600 hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500">
                      Stop System
                    </button>
                  </div>
                </dd>
              </div>
            </dl>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
