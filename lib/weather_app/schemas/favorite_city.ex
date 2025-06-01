defmodule WeatherApp.Schemas.FavoriteCity do
  use Ecto.Schema
  import Ecto.Changeset

  schema "favorite_cities" do
    field :country_code, :string
    field :name, :string # Added name field
    field :state, :string
    field :lat, :decimal
    field :lon, :decimal
    field :position, :integer

    timestamps()
  end

  @doc false
  def changeset(favorite_city, attrs) do
    favorite_city
    |> cast(attrs, [:country_code, :name, :state, :lat, :lon, :position]) # Added :name to cast
    |> validate_length(:country_code, is: 2)
    |> validate_number(:lat, greater_than_or_equal_to: -90, less_than_or_equal_to: 90)
    |> validate_number(:lon, greater_than_or_equal_to: -180, less_than_or_equal_to: 180)
    |> validate_number(:position, greater_than_or_equal_to: 0)
    |> unique_constraint([:country_code, :state, :lat, :lon],
        name: :favorite_cities_country_code_state_lat_lon_index,
        message: "Esta ciudad ya está en favoritos")
  end

  @doc """
  Changeset específico para actualizar solo la posición
  """
  def position_changeset(favorite_city, attrs) do
    favorite_city
    |> cast(attrs, [:position])
    |> validate_required([:position])
    |> validate_number(:position, greater_than_or_equal_to: 0)
  end
end
