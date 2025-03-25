defmodule Core.Schema.Transaction do
  @moduledoc """
  Schema for storing transaction history.
  Records all transactions (buys, sells, deposits, withdrawals) for each account.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Schema.Account
  
  schema "transactions" do
    field :tx_id, :string  # platform-specific transaction ID
    field :tx_type, :string  # "buy", "sell", "deposit", "withdrawal"
    field :asset, :string
    field :amount, :decimal
    field :price, :decimal
    field :fee, :decimal
    field :fee_asset, :string
    field :timestamp, :utc_datetime_usec
    field :metadata, :map, default: %{}  # additional data
    
    belongs_to :account, Account
    
    timestamps()
  end
  
  @required_fields [:tx_id, :tx_type, :asset, :amount, :timestamp, :account_id]
  @optional_fields [:price, :fee, :fee_asset, :metadata]
  
  @doc """
  Creates a changeset for a transaction.
  
  ## Parameters
    * `transaction` - The transaction to change
    * `attrs` - The attributes to apply
  """
  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:tx_type, ["buy", "sell", "deposit", "withdrawal"])
    |> validate_number(:amount, greater_than: 0)
    |> validate_number(:fee, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint([:account_id, :tx_id])
  end
  
  @doc """
  Creates a changeset for a new transaction.
  """
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for a buy transaction.
  """
  def buy_changeset(attrs) do
    attrs = Map.put(attrs, :tx_type, "buy")
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for a sell transaction.
  """
  def sell_changeset(attrs) do
    attrs = Map.put(attrs, :tx_type, "sell")
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for a deposit transaction.
  """
  def deposit_changeset(attrs) do
    attrs = Map.put(attrs, :tx_type, "deposit")
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for a withdrawal transaction.
  """
  def withdrawal_changeset(attrs) do
    attrs = Map.put(attrs, :tx_type, "withdrawal")
    changeset(%__MODULE__{}, attrs)
  end
end
