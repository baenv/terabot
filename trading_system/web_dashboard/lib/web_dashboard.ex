defmodule WebDashboard do
  @moduledoc """
  WebDashboard provides a web interface for the Terabot trading system.

  It allows users to view and manage accounts, transactions, and portfolio performance.
  """

  @doc """
  Starts the web dashboard server.
  """
  def start do
    WebDashboard.Application.start(nil, nil)
  end

  @doc """
  Stops the web dashboard server.
  """
  def stop do
    Supervisor.stop(WebDashboard.Supervisor)
  end

  @doc """
  Returns the URL of the web dashboard.
  """
  def url do
    "http://localhost:4000"
  end

  @doc """
  Returns a list of static paths that can be served from the static directory.
  """
  def static_paths do
    ~w(assets fonts images favicon.ico robots.txt)
  end

  @doc """
  Broadcasts an update to subscribers when account data changes.
  """
  def broadcast_account_update(account) do
    Registry.dispatch(WebDashboard.PubSub, "account_updates", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:account_updated, account})
    end)
  end

  @doc """
  Broadcasts an update to subscribers when a new account is created.
  """
  def broadcast_account_created(account) do
    Registry.dispatch(WebDashboard.PubSub, "account_updates", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:account_created, account})
    end)
  end

  @doc """
  Broadcasts an update to subscribers when transaction data changes.
  """
  def broadcast_transaction_update(transaction) do
    Registry.dispatch(WebDashboard.PubSub, "transaction_updates", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:transaction_updated, transaction})
    end)
  end

  @doc """
  Broadcasts an update to subscribers when portfolio data changes.
  """
  def broadcast_portfolio_update(portfolio_data) do
    Registry.dispatch(WebDashboard.PubSub, "portfolio_updates", fn entries ->
      for {pid, _} <- entries, do: send(pid, {:portfolio_updated, portfolio_data})
    end)
  end
end
