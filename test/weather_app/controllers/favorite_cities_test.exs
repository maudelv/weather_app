defmodule WeatherApp.Controllers.Weather.FavoritesTest do
  use WeatherApp.DataCase, async: true

  alias WeatherApp.Controllers.Weather.Favorites
  alias WeatherApp.Schemas.FavoriteCity

  describe "add_favorite/1" do
    test "adds a city to favorites with correct position" do
      city_data = %{
        name: "Madrid",
        country_code: "ES",
        state: "Madrid",
        lat: 40.4168,
        lon: -3.7038
      }

      assert {:ok, favorite_city} = Favorites.add_favorite(city_data)
      assert favorite_city.name == "Madrid"
      assert favorite_city.country_code == "ES"
      assert favorite_city.position == 0
    end

    test "adds multiple cities with incremental positions" do
      city1_data = %{
        name: "Madrid",
        country_code: "ES",
        state: "Madrid",
        lat: 40.4168,
        lon: -3.7038
      }

      city2_data = %{
        name: "Barcelona",
        country_code: "ES",
        state: "Catalonia",
        lat: 41.3851,
        lon: 2.1734
      }

      assert {:ok, favorite1} = Favorites.add_favorite(city1_data)
      assert {:ok, favorite2} = Favorites.add_favorite(city2_data)

      assert favorite1.position == 0
      assert favorite2.position == 1
    end

    test "returns error for invalid data" do
      invalid_data = %{
        name: "",
        country_code: "",
        lat: "invalid",
        lon: "invalid"
      }

      assert {:error, changeset} = Favorites.add_favorite(invalid_data)
      assert changeset.valid? == false
    end

    test "prevents duplicate cities" do
      city_data = %{
        name: "Madrid",
        country_code: "ES",
        state: "Madrid",
        lat: 40.4168,
        lon: -3.7038
      }

      assert {:ok, _} = Favorites.add_favorite(city_data)

      # Try to add the same city again - should fail due to unique constraint
      assert_raise Ecto.ConstraintError, fn ->
        Favorites.add_favorite(city_data)
      end
    end
  end

  describe "delete_favorite/1" do
    test "deletes a favorite city and updates positions" do
      # Add three cities
      city1 = create_favorite_city("Madrid", "ES", 0)
      city2 = create_favorite_city("Barcelona", "ES", 1)
      city3 = create_favorite_city("Valencia", "ES", 2)

      # Delete the middle one
      assert {:ok, deleted_city} = Favorites.delete_favorite(city2.id)
      assert deleted_city.id == city2.id

      # Check remaining cities have correct positions
      remaining_cities = Favorites.list_favorites()
      assert length(remaining_cities) == 2

      madrid = Enum.find(remaining_cities, &(&1.name == "Madrid"))
      valencia = Enum.find(remaining_cities, &(&1.name == "Valencia"))

      assert madrid.position == 0
      assert valencia.position == 1
    end

    test "returns error when city not found" do
      assert {:error, :not_found} = Favorites.delete_favorite(999)
    end

    test "deletes first city and updates positions correctly" do
      city1 = create_favorite_city("Madrid", "ES", 0)
      city2 = create_favorite_city("Barcelona", "ES", 1)
      city3 = create_favorite_city("Valencia", "ES", 2)

      assert {:ok, _} = Favorites.delete_favorite(city1.id)

      remaining_cities = Favorites.list_favorites()
      assert length(remaining_cities) == 2

      barcelona = Enum.find(remaining_cities, &(&1.name == "Barcelona"))
      valencia = Enum.find(remaining_cities, &(&1.name == "Valencia"))

      assert barcelona.position == 0
      assert valencia.position == 1
    end

    test "deletes last city without affecting other positions" do
      city1 = create_favorite_city("Madrid", "ES", 0)
      city2 = create_favorite_city("Barcelona", "ES", 1)
      city3 = create_favorite_city("Valencia", "ES", 2)

      assert {:ok, _} = Favorites.delete_favorite(city3.id)

      remaining_cities = Favorites.list_favorites()
      assert length(remaining_cities) == 2

      madrid = Enum.find(remaining_cities, &(&1.name == "Madrid"))
      barcelona = Enum.find(remaining_cities, &(&1.name == "Barcelona"))

      assert madrid.position == 0
      assert barcelona.position == 1
    end
  end

  describe "list_favorites/0" do
    test "returns empty list when no favorites" do
      assert Favorites.list_favorites() == []
    end

    test "returns favorites ordered by position" do
      city3 = create_favorite_city("Valencia", "ES", 2)
      city1 = create_favorite_city("Madrid", "ES", 0)
      city2 = create_favorite_city("Barcelona", "ES", 1)

      favorites = Favorites.list_favorites()
      assert length(favorites) == 3

      assert Enum.at(favorites, 0).name == "Madrid"
      assert Enum.at(favorites, 1).name == "Barcelona"
      assert Enum.at(favorites, 2).name == "Valencia"
    end
  end

  describe "count_favorites/0" do
    test "returns 0 when no favorites" do
      assert Favorites.count_favorites() == 0
    end

    test "returns correct count" do
      create_favorite_city("Madrid", "ES", 0)
      create_favorite_city("Barcelona", "ES", 1)

      assert Favorites.count_favorites() == 2
    end
  end

  describe "is_favorite?/1" do
    test "returns false when city is not a favorite" do
      assert Favorites.is_favorite?(999) == false
    end

    test "returns true when city is a favorite" do
      city = create_favorite_city("Madrid", "ES", 0)
      assert Favorites.is_favorite?(city.id) == true
    end
  end

  # Helper function to create favorite cities for testing
  defp create_favorite_city(name, country_code, position) do
    {:ok, city} = %FavoriteCity{}
    |> FavoriteCity.changeset(%{
      name: name,
      country_code: country_code,
      state: "Test State",
      lat: 40.0 + position,
      lon: -3.0 + position,
      position: position
    })
    |> Repo.insert()

    city
  end
end
