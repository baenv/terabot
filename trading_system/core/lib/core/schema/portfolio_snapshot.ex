defmodule Core.Schema.PortfolioSnapshot do
  @moduledoc """
  Schema for storing point-in-time portfolio snapshots.
  Records the total portfolio value and asset breakdown at specific points in time.
  """
  
  use Ecto.Schema
  import Ecto.Changeset
  
  schema "portfolio_snapshots" do
    field :timestamp, :utc_datetime_usec
    field :base_currency, :string, default: "USDT"
    field :value, :decimal
    field :assets, :map  # Map of asset => value pairs
    field :accounts, :map  # Map of account_id => value pairs
    
    timestamps()
  end
  
  @required_fields [:timestamp, :value, :base_currency, :assets, :accounts]
  @optional_fields []
  
  @doc """
  Creates a changeset for a portfolio snapshot.
  
  ## Parameters
    * `snapshot` - The snapshot to change
    * `attrs` - The attributes to apply
  """
  def changeset(snapshot, attrs) do
    snapshot
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_number(:value, greater_than_or_equal_to: 0)
  end
  
  @doc """
  Creates a changeset for a new portfolio snapshot.
  """
  def create_changeset(attrs) do
    changeset(%__MODULE__{}, attrs)
  end
end
