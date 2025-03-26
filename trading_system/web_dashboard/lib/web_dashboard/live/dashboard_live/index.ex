defmodule WebDashboard.DashboardLive.Index do
  use Phoenix.LiveView

  alias WebDashboard.CoreComponents

  @mock_portfolio_data %{
    total_value: 125_432.17,
    week_change_pct: 2.3,
    active_accounts: 3,
    total_transactions: 124,
    recent_transactions: [
      %{
        time: ~U[2023-06-01 12:34:56Z],
        account: "Main Wallet",
        type: "Swap",
        amount: "1.5 ETH",
        value_usd: 2621.25
      },
      %{
        time: ~U[2023-06-01 10:22:15Z],
        account: "Trading Account",
        type: "Buy",
        amount: "500 UNI",
        value_usd: 1750.00
      },
      %{
        time: ~U[2023-05-31 22:10:45Z],
        account: "DeFi Wallet",
        type: "Withdraw",
        amount: "1200 USDC",
        value_usd: 1200.00
      }
    ],
    active_accounts: [
      %{id: "acc1", name: "Main Wallet", type: "Ethereum", balance: "4.28 ETH", value_usd: 7485.12},
      %{id: "acc2", name: "Trading Account", type: "Binance", balance: "24,500 USDT", value_usd: 24500.00},
      %{id: "acc3", name: "DeFi Wallet", type: "Ethereum", balance: "Various", value_usd: 93447.05}
    ],
    top_assets: [
      %{symbol: "ETH", amount: "4.28", value_usd: 7485.12, percentage: 6.0},
      %{symbol: "USDT", amount: "24,500", value_usd: 24500.00, percentage: 19.5},
      %{symbol: "BTC", amount: "0.95", value_usd: 27455.00, percentage: 21.9},
      %{symbol: "USDC", amount: "15,000", value_usd: 15000.00, percentage: 12.0},
      %{symbol: "Other", amount: "Various", value_usd: 51002.05, percentage: 40.6}
    ]
  }

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to data update events
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "portfolio_updates")
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "transaction_updates")
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "account_updates")
    end

    {:ok,
      socket
      |> assign(:page_title, "Dashboard")
      |> assign(:portfolio_data, @mock_portfolio_data)
    }
  end

  def handle_info({:portfolio_updated, portfolio_data}, socket) do
    {:noreply, assign(socket, :portfolio_data, portfolio_data)}
  end

  def handle_info({:transaction_updated, _transaction}, socket) do
    # In a real app, you would update the transactions list here
    # For now, we'll just leave it as is
    {:noreply, socket}
  end

  def handle_info({:account_updated, _account}, socket) do
    # In a real app, you would update the active accounts here
    # For now, we'll just leave it as is
    {:noreply, socket}
  end

  def handle_event("refresh", _params, socket) do
    # For now, we'll just respond immediately
    # In a real app, you would trigger a refresh of the data
    {:noreply,
      socket
      |> put_flash(:info, "Dashboard data refreshed")
    }
  end

  def handle_event("register_wallet", _params, socket) do
    # We would navigate to the wallet registration page
    # For now, we'll just show a flash message
    {:noreply,
      socket
      |> put_flash(:info, "Wallet registration form would be shown here")
    }
  end
end
