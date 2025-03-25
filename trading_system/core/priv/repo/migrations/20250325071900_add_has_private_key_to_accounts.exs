defmodule Core.Repo.Migrations.AddHasPrivateKeyToAccounts do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      add :has_private_key, :boolean, default: false
    end
  end
end
