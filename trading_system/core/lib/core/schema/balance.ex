defmodule Core.Schema.Balance do
  @moduledoc """
  Schema for storing asset balances.
  Tracks the current balance of assets for each account.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  alias Core.Schema.Account
  
  schema "balances" do
    field :asset, :string
    field :total, :decimal
    field :available, :decimal
    field :locked, :decimal
    field :last_updated, :utc_datetime_usec
    
    belongs_to :account, Account
    
    timestamps()
  end
  
  @required_fields [:asset, :total, :available, :locked, :account_id, :last_updated]
  @optional_fields []
  
  @doc """
  Creates a changeset for a balance.
  
  ## Parameters
    * `balance` - The balance to change
    * `attrs` - The attributes to apply
  """
  def changeset(balance, attrs) do
    balance
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:total, greater_than_or_equal_to: 0)
    |> validate_number(:available, greater_than_or_equal_to: 0)
    |> validate_number(:locked, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:account_id)
    |> unique_constraint([:account_id, :asset])
  end
  
  @doc """
  Creates a changeset for a new balance.
  """
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for updating a balance.
  """
  def update_changeset(balance, attrs) do
    changeset(balance, attrs)
  end
  
  @doc """
  Creates a changeset for upserting a balance.
  If the balance doesn't exist, it will be created.
  If it does exist, it will be updated.
  """
  def upsert_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
end
