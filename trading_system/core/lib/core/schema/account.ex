defmodule Core.Schema.Account do
  @moduledoc """
  Schema for storing account information.
  Represents a trading account on a specific platform (CEX or DEX).
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "accounts" do
    field :name, :string
    field :type, :string  # "dex" or "cex"
    field :provider, :string  # e.g., "binance", "uniswap"
    field :account_id, :string  # platform-specific ID
    field :config, :map  # platform-specific configuration
    field :metadata, :map, default: %{}  # additional data
    field :active, :boolean, default: true
    field :has_private_key, :boolean, default: false  # indicates if a private key is stored in the vault
    
    has_many :balances, Core.Schema.Balance
    has_many :transactions, Core.Schema.Transaction
    
    timestamps()
  end
  
  @required_fields [:name, :type, :provider, :account_id, :config]
  @optional_fields [:metadata, :active, :has_private_key]
  
  @doc """
  Creates a changeset for an account.
  
  ## Parameters
    * `account` - The account to change
    * `attrs` - The attributes to apply
  """
  def changeset(account, attrs) do
    account
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:type, ["dex", "cex"])
    |> unique_constraint([:provider, :account_id])
  end
  
  @doc """
  Creates a changeset for a new account.
  """
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
  
  @doc """
  Creates a changeset for updating an account.
  """
  def update_changeset(account, attrs) do
    changeset(account, attrs)
  end
  
  @doc """
  Creates a changeset for deactivating an account.
  """
  def deactivate_changeset(account) do
    change(account, active: false)
  end
end
