defmodule Core.Repo.Migrations.CreatePortfolioManagerTables do
  use Ecto.Migration

  def change do
    # Accounts table
    create table(:accounts) do
      add :name, :string, null: false
      add :type, :string, null: false  # "dex" or "cex"
      add :provider, :string, null: false  # e.g., "binance", "uniswap"
      add :account_id, :string, null: false
      add :config, :map, null: false
      add :metadata, :map, default: %{}
      add :active, :boolean, default: true
      
      timestamps()
    end
    
    create unique_index(:accounts, [:provider, :account_id])
    
    # Balances table
    create table(:balances) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :asset, :string, null: false
      add :total, :decimal, precision: 28, scale: 18, null: false
      add :available, :decimal, precision: 28, scale: 18, null: false
      add :locked, :decimal, precision: 28, scale: 18, null: false
      add :last_updated, :utc_datetime_usec, null: false
      
      timestamps()
    end
    
    create index(:balances, [:account_id])
    create unique_index(:balances, [:account_id, :asset])
    
    # Transactions table
    create table(:transactions) do
      add :account_id, references(:accounts, on_delete: :delete_all), null: false
      add :tx_id, :string, null: false
      add :tx_type, :string, null: false  # "buy", "sell", "deposit", "withdrawal"
      add :asset, :string, null: false
      add :amount, :decimal, precision: 28, scale: 18, null: false
      add :price, :decimal, precision: 28, scale: 18
      add :fee, :decimal, precision: 28, scale: 18
      add :fee_asset, :string
      add :timestamp, :utc_datetime_usec, null: false
      add :metadata, :map, default: %{}
      
      timestamps()
    end
    
    create index(:transactions, [:account_id])
    create index(:transactions, [:timestamp])
    create unique_index(:transactions, [:account_id, :tx_id])
    
    # Portfolio Snapshots table
    create table(:portfolio_snapshots) do
      add :timestamp, :utc_datetime_usec, null: false
      add :base_currency, :string, null: false, default: "USDT"
      add :value, :decimal, precision: 28, scale: 18, null: false
      add :assets, :map, null: false
      add :accounts, :map, null: false
      
      timestamps()
    end
    
    create index(:portfolio_snapshots, [:timestamp])
    create index(:portfolio_snapshots, [:base_currency])
  end
end
