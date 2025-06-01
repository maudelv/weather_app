defmodule WeatherApp.Controllers.Weather.WeatherData do
  @moduledoc """
  Module for retrieving and formatting weather data.
  """

  alias WeatherApp.Controllers.Weather.ApiClient

  def get_current_weather(lat, lon) do
    case ApiClient.get_weather_data(lat, lon) do
      {:ok, weather_data} ->
        {:ok, format_weather_display(weather_data)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_weather_display(weather_data) do
    %{
      temperature: weather_data["main"]["temp"],
      original_temperature: weather_data["main"]["temp"],
      humidity: weather_data["main"]["humidity"],
      description: weather_data["weather"] |> List.first() |> Map.get("description"),
      wind_speed: weather_data["wind"]["speed"]
    }
  end
end
