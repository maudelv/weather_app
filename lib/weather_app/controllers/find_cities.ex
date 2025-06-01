defmodule WeatherApp.Controllers.Weather.FindCities do
  @moduledoc """
  Controller for finding cities based on a search query.
  """

  alias WeatherApp.Controllers.Weather.ApiClient

  @doc """
  Searches for cities based on the provided query.
  """
  def find_cities(query) do
    with {:ok, validated_query} <- validate_query(query),
         {:ok, cities} <- ApiClient.search_cities(validated_query) do
      {:ok, deduplicate_cities(cities)}
    else
      {:error, :empty_result} -> {:ok, []}
      {:error, reason} -> {:error, reason}
    end
  end

  defp deduplicate_cities(cities) do
    Enum.uniq_by(cities, fn city -> {city["name"], city["country"]} end)
  end

  defp validate_query(query) when is_binary(query) and byte_size(query) >= 2 do
    {:ok, query}
  end

  defp validate_query(query) when is_binary(query) and byte_size(query) < 2 do
    {:error, :empty_result}
  end

  defp validate_query(_) do
    {:error, :empty_result}
  end

  def format_city_options(cities) do
    Enum.map(cities, fn city ->
      "#{city["name"]}, #{city["country"]} (#{city["lat"]}, #{city["lon"]})"
    end)
  end
end
