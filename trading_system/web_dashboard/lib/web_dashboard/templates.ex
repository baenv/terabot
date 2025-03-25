defmodule WebDashboard.Templates do
  @moduledoc """
  Provides HTML templates for the web dashboard.
  """

  @doc """
  Renders the layout with the given content.
  """
  def render_layout(content, assigns) do
    page_title = Map.get(assigns, :page_title, "Trading Dashboard")
    current_year = DateTime.utc_now().year

    """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="utf-8"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>#{page_title} · Terabot</title>
        <style>
          body { font-family: system-ui, sans-serif; margin: 0; padding: 0; background-color: #f9fafb; }
          .container { max-width: 1200px; margin: 0 auto; padding: 0 1rem; }
          header { background-color: #4f46e5; color: white; padding: 1rem 0; }
          header .container { display: flex; justify-content: space-between; align-items: center; }
          header a { color: white; text-decoration: none; }
          header nav a { margin-left: 1rem; }
          main { padding: 2rem 0; }
          footer { background-color: #1f2937; color: white; padding: 1rem 0; text-align: center; }
          .card { background-color: white; border-radius: 0.5rem; box-shadow: 0 1px 3px rgba(0,0,0,0.1); padding: 1rem; margin-bottom: 1rem; }
          table { width: 100%; border-collapse: collapse; }
          table th { text-align: left; padding: 0.5rem; background-color: #f3f4f6; }
          table td { padding: 0.5rem; border-top: 1px solid #e5e7eb; }
          .btn { display: inline-block; padding: 0.5rem 1rem; background-color: #4f46e5; color: white; border-radius: 0.25rem; text-decoration: none; }
        </style>
      </head>
      <body>
        <header>
          <div class="container">
            <a href="/" style="font-size: 1.5rem; font-weight: 700;">Terabot Dashboard</a>
            <nav>
              <a href="/">Dashboard</a>
              <a href="/accounts">Accounts</a>
              <a href="/transactions">Transactions</a>
              <a href="/portfolio">Portfolio</a>
              <a href="/performance">Performance</a>
              <a href="/wallets">Wallets</a>
            </nav>
          </div>
        </header>
        <main>
          <div class="container">
            #{content}
          </div>
        </main>
        <footer>
          <div class="container">
            <p>&copy; #{current_year} Terabot Trading System</p>
          </div>
        </footer>
      </body>
    </html>
    """
  end

  def render("dashboard", _assigns) do
    """
    <h1>Trading System Dashboard</h1>

    <div class="card">
      <h2>System Status</h2>
      <p>The trading system is currently running.</p>
    </div>

    <div class="card">
      <h2>Recent Accounts</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Address</th>
            <th>Created</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Demo Account</td>
            <td>0x1234...5678</td>
            <td>Today</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def render("accounts", _assigns) do
    """
    <h1>Accounts</h1>

    <div class="card">
      <h2>All Accounts</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Address</th>
            <th>Balance</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Demo Account</td>
            <td>0x1234...5678</td>
            <td>1000 USD</td>
            <td><a href="/accounts/1" class="btn">View</a></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  def render("portfolio", assigns) do
    snapshots_html =
      Enum.map_join(assigns[:snapshots] || [], "", fn snapshot ->
        badge_html =
          if snapshot.change && snapshot.change > 0 do
            "<span class=\"badge badge-green\">+#{Float.round(snapshot.change, 2)}%</span>"
          else
            if snapshot.change && snapshot.change < 0 do
              "<span class=\"badge badge-red\">#{Float.round(snapshot.change, 2)}%</span>"
            else
              "<span class=\"badge badge-gray\">0%</span>"
            end
          end

        "<tr><td>#{format_date_short(snapshot.timestamp)}</td><td>#{Float.round(snapshot.total_value, 2)} USD</td><td>#{badge_html}</td></tr>"
      end)

    balances_html =
      Enum.map_join(assigns[:balances] || [], "", fn b ->
        "<tr><td class='px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900'>#{b.asset}</td><td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>$#{format_number(b.total_value)}</td></tr>"
      end)

    ~s(
      <div class="space-y-8">
        <div class="bg-white shadow rounded-lg p-6">
          <h1 class="text-2xl font-bold mb-6">Portfolio</h1>

          <div class="mb-8">
            <h2 class="text-xl font-semibold mb-4">Portfolio Value Over Time</h2>
            <div class="card">
              <table>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Value &#40;USD&#41;</th>
                    <th>Change</th>
                  </tr>
                </thead>
                <tbody>
                  #{snapshots_html}
                </tbody>
              </table>
            </div>
          </div>

          <div>
            <h2 class="text-xl font-semibold mb-4">Asset Allocation</h2>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asset</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value &#40;USD&#41;</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  #{balances_html}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    )
  end

  # Renders the performance metrics page.
  def render("performance", _assigns) do
    """
    <h1>Performance Metrics</h1>

    <div class="card">
      <h2>Return on Investment (ROI)</h2>
      <div id="roi-chart" style="height: 300px; margin-bottom: 20px;"></div>
      <div class="flex justify-between">
        <button class="btn" onclick="loadPerformanceData('roi', 'daily')">Daily</button>
        <button class="btn" onclick="loadPerformanceData('roi', 'weekly')">Weekly</button>
        <button class="btn" onclick="loadPerformanceData('roi', 'monthly')">Monthly</button>
        <button class="btn" onclick="loadPerformanceData('roi', 'yearly')">Yearly</button>
      </div>
    </div>

    <div class="card">
      <h2>Volatility</h2>
      <div id="volatility-chart" style="height: 300px; margin-bottom: 20px;"></div>
      <div class="flex justify-between">
        <button class="btn" onclick="loadPerformanceData('volatility', 'daily')">Daily</button>
        <button class="btn" onclick="loadPerformanceData('volatility', 'weekly')">Weekly</button>
        <button class="btn" onclick="loadPerformanceData('volatility', 'monthly')">Monthly</button>
        <button class="btn" onclick="loadPerformanceData('volatility', 'yearly')">Yearly</button>
      </div>
    </div>

    <div class="card">
      <h2>Sharpe Ratio</h2>
      <div id="sharpe-chart" style="height: 300px; margin-bottom: 20px;"></div>
      <div class="flex justify-between">
        <button class="btn" onclick="loadPerformanceData('sharpe', 'daily')">Daily</button>
        <button class="btn" onclick="loadPerformanceData('sharpe', 'weekly')">Weekly</button>
        <button class="btn" onclick="loadPerformanceData('sharpe', 'monthly')">Monthly</button>
        <button class="btn" onclick="loadPerformanceData('sharpe', 'yearly')">Yearly</button>
      </div>
    </div>

    <div class="card">
      <h2>Maximum Drawdown</h2>
      <div id="drawdown-chart" style="height: 300px; margin-bottom: 20px;"></div>
      <div class="flex justify-between">
        <button class="btn" onclick="loadPerformanceData('drawdown', 'daily')">Daily</button>
        <button class="btn" onclick="loadPerformanceData('drawdown', 'weekly')">Weekly</button>
        <button class="btn" onclick="loadPerformanceData('drawdown', 'monthly')">Monthly</button>
        <button class="btn" onclick="loadPerformanceData('drawdown', 'yearly')">Yearly</button>
      </div>
    </div>

    <div class="card">
      <h2>Asset Allocation</h2>
      <div id="allocation-chart" style="height: 300px;"></div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
    <script>
      // Initialize charts with empty data
      document.addEventListener('DOMContentLoaded', function() {
        // Initialize all charts
        initChart('roi-chart', 'ROI');
        initChart('volatility-chart', 'Volatility');
        initChart('sharpe-chart', 'Sharpe Ratio');
        initChart('drawdown-chart', 'Maximum Drawdown');
        initAllocationChart();

        // Load initial data
        loadPerformanceData('roi', 'monthly');
        loadPerformanceData('volatility', 'monthly');
        loadPerformanceData('sharpe', 'monthly');
        loadPerformanceData('drawdown', 'monthly');
        loadAllocationData();
      });

      function initChart(elementId, label) {
        const ctx = document.getElementById(elementId);
        new Chart(ctx, {
          type: 'line',
          data: {
            labels: [],
            datasets: [{
              label: label,
              data: [],
              borderColor: '#4f46e5',
              tension: 0.1
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false
          }
        });
      }

      function initAllocationChart() {
        const ctx = document.getElementById('allocation-chart');
        new Chart(ctx, {
          type: 'pie',
          data: {
            labels: [],
            datasets: [{
              data: [],
              backgroundColor: [
                '#4f46e5', '#10b981', '#f59e0b', '#ef4444',
                '#8b5cf6', '#ec4899', '#06b6d4', '#84cc16'
              ]
            }]
          },
          options: {
            responsive: true,
            maintainAspectRatio: false
          }
        });
      }

      function loadPerformanceData(metric, period) {
        fetch(`/api/performance/${metric}?period=${period}`)
          .then(response => response.json())
          .then(data => {
            updateChart(`${metric}-chart`, data);
          })
          .catch(error => console.error(`Error loading ${metric} data:`, error));
      }

      function loadAllocationData() {
        fetch('/api/performance/allocation')
          .then(response => response.json())
          .then(data => {
            updateAllocationChart(data);
          })
          .catch(error => console.error('Error loading allocation data:', error));
      }

      function updateChart(elementId, data) {
        const chart = Chart.getChart(elementId);
        if (chart) {
          // Update chart data
          chart.data.labels = data.labels || [];
          chart.data.datasets[0].data = data.values || [];
          chart.update();
        }
      }

      function updateAllocationChart(data) {
        const chart = Chart.getChart('allocation-chart');
        if (chart) {
          // Update chart data
          chart.data.labels = Object.keys(data);
          chart.data.datasets[0].data = Object.values(data);
          chart.update();
        }
      }
    </script>
    """
  end

  # Renders the transactions page.
  def render("transactions", _assigns) do
    """
    <h1>Transactions</h1>

    <div class="card">
      <h2>Recent Transactions</h2>
      <table>
        <thead>
          <tr>
            <th>Date</th>
            <th>Type</th>
            <th>Amount</th>
            <th>Asset</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Today</td>
            <td>Buy</td>
            <td>0.1</td>
            <td>BTC</td>
            <td>Completed</td>
          </tr>
          <tr>
            <td>Yesterday</td>
            <td>Sell</td>
            <td>0.5</td>
            <td>ETH</td>
            <td>Completed</td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  # Renders the wallets page.
  def render("wallets", _assigns) do
    """
    <h1>Wallet Management</h1>

    <div class="card">
      <h2>Register New Wallet</h2>
      <form action="/wallets/register" method="post">
        <div style="margin-bottom: 1rem;">
          <label style="display: block; margin-bottom: 0.5rem;">Private Key</label>
          <input type="password" name="private_key" style="width: 100%; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 0.25rem;" />
        </div>
        <div style="margin-bottom: 1rem;">
          <label style="display: block; margin-bottom: 0.5rem;">Name</label>
          <input type="text" name="name" style="width: 100%; padding: 0.5rem; border: 1px solid #d1d5db; border-radius: 0.25rem;" />
        </div>
        <button type="submit" class="btn">Register Wallet</button>
      </form>
    </div>

    <div class="card">
      <h2>Your Wallets</h2>
      <table>
        <thead>
          <tr>
            <th>Name</th>
            <th>Address</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr>
            <td>Main Wallet</td>
            <td>0x1234...5678</td>
            <td><a href="/wallets/1" class="btn">View</a></td>
          </tr>
        </tbody>
      </table>
    </div>
    """
  end

  @doc """
  Renders a 404 not found page.
  """
  def render("404", _assigns) do
    """
    <div style="text-align: center; padding: 3rem 0;">
      <h1>404 - Page Not Found</h1>
      <p>The page you're looking for doesn't exist.</p>
      <a href="/" class="btn">Go to Dashboard</a>
    </div>
    """
  end

  @doc """
  Renders a 500 server error page.
  """
  def render("500", _assigns) do
    """
    <div style="text-align: center; padding: 3rem 0;">
      <h1>500 - Server Error</h1>
      <p>Something went wrong on our end. Please try again later.</p>
      <a href="/" class="btn">Go to Dashboard</a>
    </div>
    """
  end

  @doc """
  Formats a date for display.
  """
  def format_date(datetime) do
    case datetime do
      %DateTime{} -> Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
      %NaiveDateTime{} -> Calendar.strftime(datetime, "%Y-%m-%d %H:%M")
      _ -> "Unknown date"
    end
  end

  defp format_date_short(datetime) do
    case datetime do
      nil -> ""
      _ -> Calendar.strftime(datetime, "%Y-%m-%d")
    end
  end

  @doc """
  Renders a template with the given assigns.
  """
  def render(template, assigns) do
    apply(__MODULE__, String.to_atom("render_#{template}"), [assigns])
  end

  @doc """
  Renders the dashboard template.
  """
  def render_dashboard(assigns) do
    ~s(
      <div class="space-y-8">
        <div class="bg-white shadow rounded-lg p-6">
          <h1 class="text-2xl font-bold mb-6">Dashboard</h1>
          <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
            <div class="bg-indigo-100 p-4 rounded-lg">
              <h3 class="text-lg font-semibold text-indigo-800">Portfolio Value</h3>
              <p class="text-2xl font-bold">$#{format_number(assigns[:total_value])}</p>
            </div>
            <!-- Add more stat cards here -->
          </div>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-xl font-bold mb-4">Recent Transactions</h2>
            #{render_transactions_table(assigns[:transactions], short: true)}
            <div class="mt-4">
              <a href="/transactions" class="text-indigo-600 hover:text-indigo-800">View all transactions →</a>
            </div>
          </div>

          <div class="bg-white shadow rounded-lg p-6">
            <h2 class="text-xl font-bold mb-4">Active Accounts</h2>
            #{render_accounts_table(assigns[:accounts], short: true)}
            <div class="mt-4">
              <a href="/accounts" class="text-indigo-600 hover:text-indigo-800">View all accounts →</a>
            </div>
          </div>
        </div>
      </div>
    )
  end

  # Renders the accounts template.
  def render_accounts(assigns) do
    ~s(
      <div class="bg-white shadow rounded-lg p-6">
        <div class="flex justify-between items-center mb-6">
          <h1 class="text-2xl font-bold">Accounts</h1>
          <div class="space-x-2">
            <a href="/accounts/new" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
              Add CEX Account
            </a>
            <a href="/wallets" class="bg-indigo-600 hover:bg-indigo-700 text-white px-4 py-2 rounded-md text-sm font-medium">
              Add Wallet
            </a>
          </div>
        </div>
        #{render_accounts_table(assigns[:accounts])}
      </div>
    )
  end

  @doc """
  Renders the account details template.
  """
  def render_account_details(assigns) do
    account = assigns[:account]
    ~s(
      <div class="space-y-8">
        <div class="bg-white shadow rounded-lg p-6">
          <div class="flex justify-between items-center mb-6">
            <h1 class="text-2xl font-bold">#{account.name}</h1>
            <div>
              <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{if account.active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"}">
                #{if account.active, do: "Active", else: "Inactive"}
              </span>
              <span class="ml-2 inline-flex items-center rounded-md px-2 py-1 text-xs font-medium bg-purple-100 text-purple-800">
                #{String.upcase(account.type)}
              </span>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4 mb-6">
            <div>
              <h3 class="text-sm font-medium text-gray-500">Provider</h3>
              <p class="mt-1">#{account.provider}</p>
            </div>
            <div>
              <h3 class="text-sm font-medium text-gray-500">Account ID</h3>
              <p class="mt-1">#{account.account_id}</p>
            </div>
            <div>
              <h3 class="text-sm font-medium text-gray-500">Created At</h3>
              <p class="mt-1">#{format_datetime(account.inserted_at)}</p>
            </div>
            <div>
              <h3 class="text-sm font-medium text-gray-500">Private Key</h3>
              <p class="mt-1">
                <span class="inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{if account.has_private_key, do: "bg-green-100 text-green-800", else: "bg-gray-100 text-gray-800"}">
                  #{if account.has_private_key, do: "Available", else: "Not Available"}
                </span>
              </p>
            </div>
          </div>
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-bold mb-4">Balances</h2>
          #{render_balances_table(assigns[:balances])}
        </div>

        <div class="bg-white shadow rounded-lg p-6">
          <h2 class="text-xl font-bold mb-4">Recent Transactions</h2>
          #{render_transactions_table(assigns[:transactions])}
        </div>
      </div>
    )
  end

  @doc """
  Renders the transactions template.
  """
  def render_transactions(assigns) do
    ~s(
      <div class="bg-white shadow rounded-lg p-6">
        <h1 class="text-2xl font-bold mb-6">Transactions</h1>
        #{render_transactions_table(assigns[:transactions])}
      </div>
    )
  end

  @doc """
  Renders the portfolio template.
  """
  def render_portfolio(assigns) do
    snapshots_html =
      Enum.map_join(assigns[:snapshots] || [], "", fn snapshot ->
        badge_html =
          if snapshot.change && snapshot.change > 0 do
            "<span class=\"badge badge-green\">+#{Float.round(snapshot.change, 2)}%</span>"
          else
            if snapshot.change && snapshot.change < 0 do
              "<span class=\"badge badge-red\">#{Float.round(snapshot.change, 2)}%</span>"
            else
              "<span class=\"badge badge-gray\">0%</span>"
            end
          end

        "<tr><td>#{format_date_short(snapshot.timestamp)}</td><td>#{Float.round(snapshot.total_value, 2)} USD</td><td>#{badge_html}</td></tr>"
      end)

    balances_html =
      Enum.map_join(assigns[:balances] || [], "", fn b ->
        "<tr><td class='px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900'>#{b.asset}</td><td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>$#{format_number(b.total_value)}</td></tr>"
      end)

    ~s(
      <div class="space-y-8">
        <div class="bg-white shadow rounded-lg p-6">
          <h1 class="text-2xl font-bold mb-6">Portfolio</h1>

          <div class="mb-8">
            <h2 class="text-xl font-semibold mb-4">Portfolio Value Over Time</h2>
            <div class="card">
              <table>
                <thead>
                  <tr>
                    <th>Date</th>
                    <th>Value &#40;USD&#41;</th>
                    <th>Change</th>
                  </tr>
                </thead>
                <tbody>
                  #{snapshots_html}
                </tbody>
              </table>
            </div>
          </div>

          <div>
            <h2 class="text-xl font-semibold mb-4">Asset Allocation</h2>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200">
                <thead class="bg-gray-50">
                  <tr>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asset</th>
                    <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value &#40;USD&#41;</th>
                  </tr>
                </thead>
                <tbody class="bg-white divide-y divide-gray-200">
                  #{balances_html}
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    )
  end

  @doc """
  Renders the wallets template with private key registration form.
  """
  def render_wallets(assigns) do
    ~s(
      <div class=\"space-y-8\">
        <div class=\"bg-white shadow rounded-lg p-6\">
          <h1 class=\"text-2xl font-bold mb-6\">Wallet Management</h1>

          #{if Map.get(assigns, :error) do
      "<div class=\"bg-red-100 border border-red-400 text-red-700 px-4 py-3 rounded mb-6\" role=\"alert\">
              <p>#{assigns.error}</p>
            </div>"
    else
      ""
    end}

          <div class=\"grid grid-cols-1 lg:grid-cols-2 gap-8\">
            <div>
              <h2 class=\"text-xl font-semibold mb-4\">Register Wallet with Private Key</h2>
              <form action=\"/wallets/register\" method=\"post\" class=\"space-y-4\">
                <div>
                  <label for=\"name\" class=\"block text-sm font-medium text-gray-700\">Wallet Name</label>
                  <input type=\"text\" name=\"name\" id=\"name\" required class=\"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm\">
                </div>

                <div>
                  <label for=\"provider\" class=\"block text-sm font-medium text-gray-700\">Provider/Network</label>
                  <select name=\"provider\" id=\"provider\" required class=\"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm\">
                    <option value=\"ethereum\">Ethereum</option>
                    <option value=\"binance\">Binance Smart Chain</option>
                    <option value=\"polygon\">Polygon</option>
                    <option value=\"arbitrum\">Arbitrum</option>
                  </select>
                </div>

                <div>
                  <label for=\"address\" class=\"block text-sm font-medium text-gray-700\">Wallet Address</label>
                  <input type=\"text\" name=\"address\" id=\"address\" required class=\"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm\">
                </div>

                <div>
                  <label for=\"private_key\" class=\"block text-sm font-medium text-gray-700\">Private Key</label>
                  <input type=\"password\" name=\"private_key\" id=\"private_key\" required class=\"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm\">
                  <p class="mt-1 text-sm text-gray-500">Your private key will be encrypted and stored securely.</p>
                </div>

                <div>
                  <label for=\"password\" class=\"block text-sm font-medium text-gray-700\">Encryption Password</label>
                  <input type=\"password\" name=\"password\" id=\"password\" required class=\"mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm\">
                  <p class=\"mt-1 text-sm text-gray-500\">This password will be used to encrypt your private key.</p>
                </div>

                <div>
                  <button type=\"submit\" class=\"inline-flex justify-center py-2 px-4 border border-transparent shadow-sm text-sm font-medium rounded-md text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500\">
                    Register Wallet
                  </button>
                </div>
              </form>
            </div>

            <div>
              <h2 class="text-xl font-semibold mb-4">Registered Wallets</h2>
              #{render_accounts_table(assigns[:accounts], show_type: false)}
            </div>
          </div>
        </div>
      </div>
    )
  end

  # Helper functions to render common components

  defp render_accounts_table(accounts, opts \\ []) do
    short = Keyword.get(opts, :short, false)
    show_type = Keyword.get(opts, :show_type, true)

    ~s(
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Name</th>
              #{if show_type, do: "<th scope='col' class='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>Type</th>", else: ""}
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Provider</th>
              #{unless short, do: "<th scope='col' class='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>Account ID</th>", else: ""}
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Status</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider"></th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            #{Enum.map_join(accounts || [], "", fn account -> "<tr>
                <td class='px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900'>#{account.name}</td>
                #{if show_type do
        "<td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>
                    <span class='inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{if account.type == "cex", do: "bg-purple-100 text-purple-800", else: "bg-yellow-100 text-yellow-800"}'>
                      #{String.upcase(account.type)}
                    </span>
                  </td>"
      else
        ""
      end}
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{account.provider}</td>
                #{unless short, do: "<td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{account.account_id}</td>", else: ""}
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>
                  <span class='inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{if account.active, do: "bg-green-100 text-green-800", else: "bg-red-100 text-red-800"}'>
                    #{if account.active, do: "Active", else: "Inactive"}
                  </span>
                </td>
                <td class='px-6 py-4 whitespace-nowrap text-right text-sm font-medium'>
                  <a href='/accounts/#{account.id}' class='text-indigo-600 hover:text-indigo-900'>View</a>
                </td>
              </tr>" end)}
          </tbody>
        </table>
      </div>
    )
  end

  defp render_transactions_table(transactions, opts \\ []) do
    short = Keyword.get(opts, :short, false)

    ~s(
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Date</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Account</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Type</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asset</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
              #{unless short, do: "<th scope='col' class='px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider'>Value &#40;USD&#41;</th>", else: ""}
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            #{Enum.map_join(transactions || [], "", fn tx -> "<tr>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{format_datetime(tx.inserted_at)}</td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{tx.account.name}</td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>
                  <span class='inline-flex items-center rounded-md px-2 py-1 text-xs font-medium #{transaction_type_class(tx.type)}'>
                    #{String.upcase(tx.type)}
                  </span>
                </td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{tx.asset}</td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{format_number(tx.amount)}</td>
                #{unless short, do: "<td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>$#{format_number(tx.value_in_quote)}</td>", else: ""}
              </tr>" end)}
          </tbody>
        </table>
      </div>
    )
  end

  defp render_balances_table(balances) do
    ~s(
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Asset</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Amount</th>
              <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase tracking-wider">Value &#40;USD&#41;</th>
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-gray-200">
            #{Enum.map_join(balances || [], "", fn balance -> "<tr>
                <td class='px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900'>#{balance.asset}</td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>#{format_number(balance.amount)}</td>
                <td class='px-6 py-4 whitespace-nowrap text-sm text-gray-500'>$#{format_number(balance.value_in_quote)}</td>
              </tr>" end)}
          </tbody>
        </table>
      </div>
    )
  end

  # Helper functions for formatting

  defp format_number(nil), do: "0.00"

  defp format_number(num) when is_float(num) do
    :erlang.float_to_binary(num, decimals: 2)
  end

  defp format_number(num) when is_integer(num) do
    "#{num}.00"
  end

  defp format_number(num) do
    "#{num}"
  end

  defp format_datetime(nil), do: ""

  defp format_datetime(datetime) do
    Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S")
  end

  defp transaction_type_class("deposit"), do: "bg-green-100 text-green-800"
  defp transaction_type_class("withdrawal"), do: "bg-red-100 text-red-800"
  defp transaction_type_class("trade"), do: "bg-blue-100 text-blue-800"
  defp transaction_type_class("fee"), do: "bg-yellow-100 text-yellow-800"
  defp transaction_type_class(_), do: "bg-gray-100 text-gray-800"
end
