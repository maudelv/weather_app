defmodule WeatherApp.Repo.Migrations.FixFavoriteCitiesStructure do
  use Ecto.Migration

  def up do
    # Crear una nueva tabla temporal con la estructura correcta según tu schema
    create table(:favorite_cities_temp) do
      add :country_code, :string, size: 2, null: false
      add :state, :string
      add :lat, :decimal, precision: 10, scale: 7, null: false
      add :lon, :decimal, precision: 10, scale: 7, null: false
      add :position, :integer, default: 0, null: false

      timestamps()
    end

    # Eliminar la tabla antigua
    drop table(:favorite_cities)

    # Renombrar la tabla temporal
    rename table(:favorite_cities_temp), to: table(:favorite_cities)

    # Crear índices según tu schema original
    create index(:favorite_cities, [:country_code])
    create index(:favorite_cities, [:position])
  end

  def down do
    # En caso de rollback, recrear la tabla original
    drop_if_exists table(:favorite_cities)

    create table(:favorite_cities) do
      add :country_code, :string
      add :state, :string
      add :lat, :decimal
      add :lon, :decimal
      add :position, :integer

      timestamps()
    end
  end
end
