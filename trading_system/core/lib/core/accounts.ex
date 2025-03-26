defmodule Core.Accounts do
  @moduledoc """
  This module handles all account-related operations in the system.
  It serves as the interface for the WebDashboard to access account data.
  """

  @doc """
  Returns a list of all accounts in the system.
  """
  def list_accounts do
    # TODO: Implement actual database query when schemas are ready
    accounts = [
      %{
        id: "acc_1",
        name: "Main Trading Account",
        type: "exchange",
        provider: "binance",
        account_id: "binance_001",
        has_private_key: true,
        active: true
      },
      %{
        id: "acc_2",
        name: "Ethereum Wallet",
        type: "wallet",
        provider: "ethereum",
        account_id: "0x1234abcd...",
        has_private_key: true,
        active: true
      },
      %{
        id: "acc_3",
        name: "Cold Storage",
        type: "wallet",
        provider: "bitcoin",
        account_id: "bc1qa34...",
        has_private_key: false,
        active: false
      }
    ]

    {:ok, accounts}
  end

  @doc """
  Gets a single account by its ID.
  """
  def get_account(id) do
    # TODO: Implement actual database query when schemas are ready
    account = %{
      id: id,
      name: "Account #{id}",
      type: "exchange",
      provider: "binance",
      account_id: "binance_#{id}",
      has_private_key: true,
      active: true,
      balance: %{
        "BTC" => 0.5,
        "ETH" => 15.0,
        "USDT" => 10000.0
      }
    }

    {:ok, account}
  end
end
