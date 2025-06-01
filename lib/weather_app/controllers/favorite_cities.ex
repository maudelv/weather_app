defmodule WeatherApp.Controllers.Weather.Favorites do
  @moduledoc """
  Module for managing favorite cities.
  """

  alias WeatherApp.Repo
  alias WeatherApp.Schemas.FavoriteCity # Align with corrected schema module name
  import Ecto.Query

  @doc """
  Adds a city to favorites.
  """
  def add_favorite(city_data) do
    %FavoriteCity{}
    |> FavoriteCity.changeset(city_data)
    |> Repo.insert()
  end

  @doc """
  Removes a city from favorites by city ID.
  """
  def remove_favorite(city_id) do
    favorite = Repo.get_by(FavoriteCity, city_id: city_id)

    case favorite do
      nil -> {:error, "Favorite not found"}
      _ -> Repo.delete(favorite)
    end
  end

  @doc """
  Lists all favorite cities.
  """
  def list_favorites() do
    Repo.all(FavoriteCity)
  end

  @doc """
  Counts the number of favorite cities.
  """
  def count_favorites do
    Repo.aggregate(FavoriteCity, :count, :id)
  end

  @doc """
  Checks if a city is a favorite by city ID.
  """
  def is_favorite?(city_id) do
    Repo.exists?(from f in FavoriteCity, where: f.city_id == ^city_id)
  end
end
