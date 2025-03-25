defmodule WebDashboard.DashboardLive.Index do
  use Phoenix.LiveView
  alias Core.Repo
  alias Core.Schema.{Account, Balance, Transaction, PortfolioSnapshot}
  alias WebDashboard.CoreComponents
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "portfolio_updates")
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "transaction_updates")
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "balance_updates")
    end

    {:ok, 
      socket
      |> assign(:page_title, "Dashboard")
      |> assign_dashboard_data()
      |> assign_recent_transactions()
      |> assign_active_accounts()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Dashboard")
  end

  @impl true
  def handle_info({:transaction_created, _transaction}, socket) do
    {:noreply, 
      socket
      |> assign_dashboard_data()
      |> assign_recent_transactions()}
  end

  @impl true
  def handle_info({:balance_updated, _balance}, socket) do
    {:noreply, 
      socket
      |> assign_dashboard_data()}
  end

  @impl true
  def handle_info({:portfolio_updated, _snapshot}, socket) do
    {:noreply, 
      socket
      |> assign_dashboard_data()}
  end

  defp assign_dashboard_data(socket) do
    # Get total portfolio value
    total_value = get_total_portfolio_value()
    
    # Get 24h change
    previous_value = get_previous_portfolio_value(24)
    change_24h = calculate_change(total_value, previous_value)
    
    # Get 7d change
    previous_value_7d = get_previous_portfolio_value(24 * 7)
    change_7d = calculate_change(total_value, previous_value_7d)
    
    # Get account stats
    total_accounts = Repo.aggregate(Account, :count, :id)
    active_accounts = Repo.aggregate(from(a in Account, where: a.active == true), :count, :id)
    
    # Get transaction stats
    total_transactions = Repo.aggregate(Transaction, :count, :id)
    
    # Get top assets by value
    top_assets = get_top_assets()
    
    socket
    |> assign(:total_value, format_currency(total_value))
    |> assign(:change_24h, format_percentage(change_24h))
    |> assign(:change_24h_type, if(change_24h >= 0, do: "increase", else: "decrease"))
    |> assign(:change_7d, format_percentage(change_7d))
    |> assign(:change_7d_type, if(change_7d >= 0, do: "increase", else: "decrease"))
    |> assign(:total_accounts, total_accounts)
    |> assign(:active_accounts, active_accounts)
    |> assign(:total_transactions, total_transactions)
    |> assign(:top_assets, top_assets)
  end

  defp assign_recent_transactions(socket) do
    transactions = 
      Transaction
      |> order_by([t], desc: t.inserted_at)
      |> limit(5)
      |> Repo.all()
      |> Repo.preload(:account)
    
    assign(socket, :recent_transactions, transactions)
  end

  defp assign_active_accounts(socket) do
    accounts = 
      Account
      |> where([a], a.active == true)
      |> order_by([a], desc: a.inserted_at)
      |> limit(5)
      |> Repo.all()
    
    assign(socket, :active_accounts, accounts)
  end

  defp get_total_portfolio_value do
    case Repo.one(from p in PortfolioSnapshot, 
                 order_by: [desc: p.timestamp], 
                 limit: 1, 
                 select: p.total_value) do
      nil -> 0.0
      value -> value
    end
  end

  defp get_previous_portfolio_value(hours_ago) do
    timestamp = DateTime.utc_now() |> DateTime.add(-hours_ago, :hour)
    
    query = from p in PortfolioSnapshot,
            where: p.timestamp <= ^timestamp,
            order_by: [desc: p.timestamp],
            limit: 1,
            select: p.total_value
            
    case Repo.one(query) do
      nil -> 0.0
      value -> value
    end
  end

  defp calculate_change(current, previous) do
    if previous == 0, do: 0, else: (current - previous) / previous * 100
  end

  defp get_top_assets do
    query = from b in Balance,
            group_by: b.asset,
            select: %{
              asset: b.asset,
              total_value: sum(b.value_in_quote)
            },
            order_by: [desc: sum(b.value_in_quote)],
            limit: 5
            
    Repo.all(query)
  end

  defp format_currency(value) do
    "$#{:erlang.float_to_binary(value, decimals: 2)}"
  end

  defp format_percentage(value) do
    sign = if value >= 0, do: "+", else: ""
    "#{sign}#{:erlang.float_to_binary(value, decimals: 2)}%"
  end
end
