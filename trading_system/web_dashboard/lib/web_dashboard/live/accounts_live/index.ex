defmodule WebDashboard.AccountsLive.Index do
  use Phoenix.LiveView

  alias WebDashboard.CoreComponents

  @mock_accounts [
    %{
      id: "acc1",
      name: "Main ETH Wallet",
      type: "Wallet",
      provider: "ethereum",
      account_id: "0x1234567890abcdef1234567890abcdef12345678",
      has_private_key: true,
      active: true
    },
    %{
      id: "acc2",
      name: "Binance Account",
      type: "Exchange",
      provider: "binance",
      account_id: "binance_user_123",
      has_private_key: false,
      active: true
    },
    %{
      id: "acc3",
      name: "DeFi Wallet",
      type: "Wallet",
      provider: "ethereum",
      account_id: "0xabcdef1234567890abcdef1234567890abcdef12",
      has_private_key: true,
      active: false
    }
  ]

  def mount(_params, _session, socket) do
    if connected?(socket) do
      # Subscribe to account update events
      Phoenix.PubSub.subscribe(WebDashboard.PubSub, "account_updates")
    end

    {:ok,
      socket
      |> assign(:page_title, "Accounts")
      |> assign(:accounts, @mock_accounts)
    }
  end

  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Accounts")
  end

  def handle_info({:account_updated, account}, socket) do
    accounts = Enum.map(socket.assigns.accounts, fn a ->
      if a.id == account.id, do: account, else: a
    end)

    {:noreply, assign(socket, :accounts, accounts)}
  end

  def handle_info({:account_created, account}, socket) do
    accounts = [account | socket.assigns.accounts]
    {:noreply, assign(socket, :accounts, accounts)}
  end

  def handle_event("toggle_active", %{"id" => id}, socket) do
    # Find the account to toggle
    accounts = Enum.map(socket.assigns.accounts, fn account ->
      if account.id == id do
        %{account | active: !account.active}
      else
        account
      end
    end)

    # In a real app, we would also update the backend
    # For now, we'll just update the state

    {:noreply,
      socket
      |> assign(:accounts, accounts)
      |> put_flash(:info, "Account status updated")
    }
  end

  def handle_event("add_account", _params, socket) do
    # Navigate to account creation form
    # In a real app, we would navigate to a form
    # For now, just show a flash message

    {:noreply,
      socket
      |> put_flash(:info, "Account creation would be shown here")
    }
  end
end
