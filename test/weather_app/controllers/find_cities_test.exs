defmodule WeatherApp.Controllers.Weather.FindCitiesTest do
  use ExUnit.Case, async: true
  import Mox

  alias WeatherApp.Controllers.Weather.FindCities
  alias WeatherApp.HTTPoisonMock

  # Ensure mocks are verified
  setup :verify_on_exit!

  describe "find_cities/1" do
    test "returns cities when query is valid and API responds successfully" do
      cities_response = [
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        },
        %{
          "name" => "Madrid",
          "country" => "US",
          "lat" => 40.2021,
          "lon" => -86.9005
        }
      ]

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(cities_response)
         }}
      end)

      result = FindCities.find_cities("Madrid")

      assert {:ok, cities} = result
      assert length(cities) == 2
      assert Enum.find(cities, &(&1["country"] == "ES"))
      assert Enum.find(cities, &(&1["country"] == "US"))
    end

    test "returns empty list when query is too short" do
      result = FindCities.find_cities("M")
      assert {:ok, []} = result
    end

    test "returns empty list when query is empty string" do
      result = FindCities.find_cities("")
      assert {:ok, []} = result
    end

    test "returns empty list when query is not a string" do
      result = FindCities.find_cities(123)
      assert {:ok, []} = result
    end

    test "returns empty list when query is nil" do
      result = FindCities.find_cities(nil)
      assert {:ok, []} = result
    end

    test "deduplicates cities with same name and country" do
      cities_response = [
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        },
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        },
        %{
          "name" => "Barcelona",
          "country" => "ES",
          "lat" => 41.3851,
          "lon" => 2.1734
        }
      ]

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(cities_response)
         }}
      end)

      result = FindCities.find_cities("Madrid")

      assert {:ok, cities} = result
      assert length(cities) == 2

      madrid_cities = Enum.filter(cities, &(&1["name"] == "Madrid"))
      assert length(madrid_cities) == 1
    end

    test "returns error when API client returns error" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      result = FindCities.find_cities("Madrid")

      assert {:error, "Error de conexión: timeout"} = result
    end

    test "handles API returning empty array" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "[]"
         }}
      end)

      result = FindCities.find_cities("NonExistentCity")

      assert {:ok, []} = result
    end

    test "handles whitespace in query" do
      cities_response = [
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        }
      ]

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(cities_response)
         }}
      end)

      result = FindCities.find_cities("  Madrid  ")

      assert {:ok, cities} = result
      assert length(cities) == 1
    end
  end

  describe "format_city_options/1" do
    test "formats cities correctly" do
      cities = [
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        },
        %{
          "name" => "Barcelona",
          "country" => "ES",
          "lat" => 41.3851,
          "lon" => 2.1734
        }
      ]

      result = FindCities.format_city_options(cities)

      expected = [
        "Madrid, ES (40.4168, -3.7038)",
        "Barcelona, ES (41.3851, 2.1734)"
      ]

      assert result == expected
    end

    test "handles empty list" do
      result = FindCities.format_city_options([])
      assert result == []
    end

    test "handles cities with missing fields gracefully" do
      cities = [
        %{
          "name" => "Madrid",
          "country" => "ES",
          "lat" => 40.4168,
          "lon" => -3.7038
        },
        %{
          "name" => "Unknown",
          "country" => nil,
          "lat" => nil,
          "lon" => nil
        }
      ]

      result = FindCities.format_city_options(cities)

      assert length(result) == 2
      assert Enum.at(result, 0) == "Madrid, ES (40.4168, -3.7038)"
      assert Enum.at(result, 1) == "Unknown,  (, )"
    end
  end
end
