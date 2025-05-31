defmodule WeatherApp.Repo.Migrations.CreateFavoriteCities do
  use Ecto.Migration

  def change do
    create table(:favorite_cities) do
      add :" country_code", :string
      add :" name", :string
      add :" state", :string
      add :" lat", :decimal
      add :" lon", :decimal
      add :" position", :integer

      timestamps(type: :utc_datetime)
    end
  end
end
