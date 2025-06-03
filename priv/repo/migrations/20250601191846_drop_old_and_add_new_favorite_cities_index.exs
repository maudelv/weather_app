defmodule WeatherApp.Repo.Migrations.DropOldAndAddNewFavoriteCitiesIndex do
  use Ecto.Migration

  def change do
    drop index(:favorite_cities, [], name: :favorite_cities_country_code_state_lat_lon_index)

    create unique_index(:favorite_cities, [:country_code, :name],
             name: :favorite_cities_country_code_name_index
           )
  end
end
