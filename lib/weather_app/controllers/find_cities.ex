defmodule WeatherApp.Controllers.Weather.FindCities do
  @moduledoc """
  Controller for finding cities based on a search query.
  """

  alias WeatherApp.Controllers.Weather.ApiClient

  @doc """
  Searches for cities based on the provided query.
  """
  def find_cities(query) when is_binary(query) and byte_size(query) >= 2 do
    case ApiClient.search_cities(query) do
      {:ok, cities} -> {:ok, cities}
      {:error, reason} -> {:error, reason}
    end
  end

  # Handle queries shorter than 2 characters
  def find_cities(query) when is_binary(query) and byte_size(query) < 2 do
    {:ok, []}
  end

  # Catch-all for any other type of query, though less likely with LiveView input
  def find_cities(_) do
    {:ok, []}
  end

  def format_city_options(cities) do
    Enum.map(cities, fn city ->
      "#{city["name"]}, #{city["country"]} (#{city["lat"]}, #{city["lon"]})"
    end)
  end
end
