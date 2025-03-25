defmodule WebDashboard.AccountsLive.Index do
  use Phoenix.LiveView
  alias Core.Repo
  alias Core.Schema.Account
  alias PortfolioManager.API, as: PortfolioAPI
  alias WebDashboard.CoreComponents
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "account_updates")
    end

    {:ok, 
      socket
      |> assign(:page_title, "Accounts")
      |> assign_accounts()}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Accounts")
    |> assign(:account, nil)
  end

  @impl true
  def handle_event("toggle_account", %{"id" => id}, socket) do
    account = Repo.get!(Account, id)
    
    case account.active do
      true -> 
        {:ok, _} = PortfolioAPI.deactivate_account(id)
        {:noreply, socket |> put_flash(:info, "Account deactivated successfully") |> assign_accounts()}
      false -> 
        {:ok, _} = PortfolioAPI.activate_account(id)
        {:noreply, socket |> put_flash(:info, "Account activated successfully") |> assign_accounts()}
    end
  end

  @impl true
  def handle_info({:account_updated, _account}, socket) do
    {:noreply, assign_accounts(socket)}
  end

  @impl true
  def handle_info({:account_created, _account}, socket) do
    {:noreply, assign_accounts(socket)}
  end

  defp assign_accounts(socket) do
    accounts = 
      Account
      |> order_by([a], desc: a.inserted_at)
      |> Repo.all()
    
    assign(socket, :accounts, accounts)
  end
end
