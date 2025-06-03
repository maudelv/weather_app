defmodule WeatherApp.Controllers.Weather.WeatherData do
  @moduledoc """
  Module for retrieving and formatting weather data.
  """

  alias WeatherApp.Controllers.Weather.ApiClient

  def get_current_weather(lat, lon, temp_format) do
    case ApiClient.get_weather_data(lat, lon, temp_format) do
      {:ok, weather_data} ->
        {:ok, format_weather_display(weather_data, temp_format)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp format_weather_display(weather_data, temp_format) do
    %{
      current_weather: %{
        temperature: weather_data["current"]["temp"],
        original_temperature: weather_data["current"]["temp"],
        humidity: weather_data["current"]["humidity"],
        description: get_weather_description(weather_data["current"]["weather"]),
        icon: get_weather_icon(weather_data["current"]["weather"]),
        wind_speed: weather_data["current"]["wind_speed"],
        wind_speed_unit: "m/s"
      },
      hourly_weather:
        Enum.map(weather_data["hourly"], fn hour ->
          %{
            time: hour["dt"],
            temperature: hour["temp"],
            original_temperature: hour["temp"],
            temperature_unit: temp_format,
            humidity: hour["humidity"],
            description: hour["weather"],
            icon: get_weather_icon(hour["weather"]),
            wind_speed: hour["wind_speed"],
            wind_speed_unit: "m/s"
          }
        end),
      weekly_weather:
        Enum.map(weather_data["daily"], fn day ->
          %{
            date: day["dt"],
            temperature: day["temp"]["day"],
            temp_min: day["temp"]["min"],
            temp_max: day["temp"]["max"],
            original_temperature: day["temp"]["day"],
            original_temp_min: day["temp"]["min"],
            original_temp_max: day["temp"]["max"],
            temperature_unit: temp_format,
            humidity: day["humidity"],
            description: day["weather"],
            icon: get_weather_icon(day["weather"]),
            wind_speed: day["wind_speed"],
            wind_speed_unit: "m/s"
          }
        end)
    }
  end

  # Funciones auxiliares para extraer datos de forma segura
  defp get_weather_description(weather_list)
       when is_list(weather_list) and length(weather_list) > 0 do
    case List.first(weather_list) do
      %{} = weather_map -> Map.get(weather_map, "description", "")
      _ -> ""
    end
  end

  defp get_weather_description(_), do: ""

  defp get_weather_icon(weather_list) when is_list(weather_list) and length(weather_list) > 0 do
    case List.first(weather_list) do
      %{} = weather_map -> Map.get(weather_map, "icon", "")
      _ -> ""
    end
  end

  defp get_weather_icon(_), do: ""
end
