defmodule Core.Transactions do
  @moduledoc """
  This module handles all transaction-related operations in the system.
  It serves as the interface for the WebDashboard to access transaction data.
  """

  @doc """
  Lists transactions for a specific account or all transactions if no account is specified.
  """
  def list_transactions(account_id \\ nil) do
    # TODO: Implement actual database query when schemas are ready
    transactions = [
      %{
        id: "tx_1",
        account_id: "acc_1",
        type: "trade",
        status: "completed",
        created_at: "2023-05-10T15:30:45Z",
        updated_at: "2023-05-10T15:31:02Z",
        details: %{
          buy_asset: "BTC",
          sell_asset: "USDT",
          buy_amount: 0.5,
          sell_amount: 20000.0,
          price: 40000.0,
          fee: 10.0,
          fee_asset: "USDT"
        }
      },
      %{
        id: "tx_2",
        account_id: "acc_2",
        type: "transfer",
        status: "completed",
        created_at: "2023-05-09T12:15:33Z",
        updated_at: "2023-05-09T12:20:11Z",
        details: %{
          asset: "ETH",
          amount: 5.0,
          from: "0x1234abcd...",
          to: "0x5678efgh...",
          fee: 0.002,
          fee_asset: "ETH",
          hash: "0xabc123..."
        }
      },
      %{
        id: "tx_3",
        account_id: "acc_1",
        type: "trade",
        status: "pending",
        created_at: "2023-05-11T09:45:12Z",
        updated_at: "2023-05-11T09:45:12Z",
        details: %{
          buy_asset: "ETH",
          sell_asset: "USDT",
          buy_amount: 10.0,
          sell_amount: 25000.0,
          price: 2500.0,
          fee: 12.5,
          fee_asset: "USDT"
        }
      }
    ]

    # Filter by account_id if provided
    transactions = if account_id do
      Enum.filter(transactions, fn tx -> tx.account_id == account_id end)
    else
      transactions
    end

    {:ok, transactions}
  end
end
