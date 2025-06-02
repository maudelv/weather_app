defmodule WeatherApp.Controllers.Weather.Favorites do
  @moduledoc """
  Module for managing favorite cities.
  """

  alias WeatherApp.Repo
  alias WeatherApp.Schemas.FavoriteCity
  import Ecto.Query

  @doc """
  Adds a city to favorites.
  """
  def add_favorite(city_data) do
    next_position = count_favorites()
    data_with_position = Map.put(Map.new(city_data), :position, next_position)

    %FavoriteCity{}
    |> FavoriteCity.changeset(data_with_position)
    |> Repo.insert()
  end

  @doc """
  Removes a city from favorites by city ID.
  """
  def delete_favorite(id) do
    Repo.transaction(fn ->
      case Repo.get(FavoriteCity, id) do
        nil ->
          Repo.rollback(:not_found)

        favorite_city ->
          deleted_position = favorite_city.position

          # Attempt to delete the city
          case Repo.delete(favorite_city) do
            {:ok, deleted_struct} ->
              # If deletion is successful, update positions of remaining favorites
              # to fill the gap left by the deleted city.
              from(f in FavoriteCity, where: f.position > ^deleted_position)
              |> Repo.update_all(inc: [position: -1])

              # If all operations succeed, the function inside transaction returns this.
              # The transaction will wrap it as {:ok, deleted_struct}.
              deleted_struct

            {:error, reason_for_delete_failure} ->
              # Deletion failed. Rollback the transaction with the reason.
              # Transaction will return {:error, reason_for_delete_failure}.
              Repo.rollback(reason_for_delete_failure)
          end
      end
    end)
  end

  @doc """
  Lists all favorite cities.
  """
  def list_favorites() do
    Repo.all(from f in FavoriteCity, order_by: [asc: f.position])
  end

  @doc """
  Counts the number of favorite cities.
  """
  def count_favorites do
    Repo.aggregate(FavoriteCity, :count, :id)
  end

  @doc """
  Checks if a city is a favorite by ID.
  """
  def is_favorite?(id) do
    Repo.exists?(from f in FavoriteCity, where: f.id == ^id)
  end
end
