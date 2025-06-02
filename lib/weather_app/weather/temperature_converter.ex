defmodule WeatherApp.Weather.TemperatureConverter do
  @moduledoc """
  Módulo responsable de las conversiones de temperatura entre diferentes unidades.
  """

  @spec convert_weather_data(map(), String.t()) :: map()
  def convert_weather_data(weather_data, format) do
    %{
      current_weather: convert_current_weather(weather_data.current_weather, format),
      hourly_weather: convert_hourly_weather(weather_data.hourly_weather, format),
      weekly_weather: convert_weekly_weather(weather_data.weekly_weather, format)
    }
  end

  @spec convert_current_weather(map(), String.t()) :: map()
  defp convert_current_weather(current_weather, format) do
    converted_temp = convert_temperature(current_weather.original_temperature, format)

    current_weather
    |> Map.put(:temperature, converted_temp)
    |> Map.put(:temperature_unit, temperature_unit(format))
  end

  @spec convert_hourly_weather(list(), String.t()) :: list()
  defp convert_hourly_weather(hourly_weather, format) do
    Enum.map(hourly_weather, fn hour ->
      converted_temp = convert_temperature(hour.original_temperature, format)

      hour
      |> Map.put(:temperature, converted_temp)
      |> Map.put(:temperature_unit, temperature_unit(format))
    end)
  end

  @spec convert_weekly_weather(list(), String.t()) :: list()
  defp convert_weekly_weather(weekly_weather, format) do
    Enum.map(weekly_weather, fn day ->
      # Convertir todas las temperaturas del día
      day
      |> Map.put(:temperature, convert_temperature(day.original_temperature, format))
      |> Map.put(:temp_min, convert_temperature(day.original_temp_min, format))
      |> Map.put(:temp_max, convert_temperature(day.original_temp_max, format))
      |> Map.put(:temperature_unit, temperature_unit(format))
    end)
  end

  @spec convert_temperature(float(), String.t()) :: float()
  defp convert_temperature(temp_celsius, format) do
    case format do
      "celsius" -> temp_celsius
      "fahrenheit" -> temp_celsius * 9 / 5 + 32
      "kelvin" -> temp_celsius + 273.15
      _ -> temp_celsius
    end
  end

  @spec temperature_unit(String.t()) :: String.t()
  def temperature_unit("celsius"), do: "C"
  def temperature_unit("fahrenheit"), do: "F"
  def temperature_unit("kelvin"), do: "K"
  def temperature_unit(_), do: "C"
end
