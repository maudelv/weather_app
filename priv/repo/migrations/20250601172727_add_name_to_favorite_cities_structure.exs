defmodule WeatherApp.Repo.Migrations.AddNameToFavoriteCitiesStructure do
  use Ecto.Migration

  def change do
    alter table(:favorite_cities) do
      add :name, :string
    end
  end
end
