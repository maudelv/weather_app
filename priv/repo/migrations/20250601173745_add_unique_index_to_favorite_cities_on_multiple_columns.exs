defmodule WeatherApp.Repo.Migrations.AddUniqueIndexToFavoriteCitiesOnMultipleColumns do
  use Ecto.Migration

  def change do
    create unique_index(:favorite_cities, [:country_code, :state, :lat, :lon],
             name: :favorite_cities_country_code_state_lat_lon_index
           )
  end
end
