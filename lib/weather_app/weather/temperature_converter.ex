defmodule WeatherApp.Weather.TemperatureConverter do
  @moduledoc """
  Módulo responsable de las conversiones de temperatura entre diferentes unidades.
  """

  @spec convert(map(), String.t()) :: map()
  def convert(weather, format) do
    temp_kelvin = weather.original_temperature

    converted_temp = case format do
      "celsius" -> temp_kelvin - 273.15
      "fahrenheit" -> (temp_kelvin - 273.15) * 9 / 5 + 32
      "kelvin" -> temp_kelvin
      _ -> temp_kelvin - 273.15
    end

    %{weather | temperature: Float.round(converted_temp, 1)}
  end

  @spec temperature_unit(String.t()) :: String.t()
  def temperature_unit("celsius"), do: "C"
  def temperature_unit("fahrenheit"), do: "F"
  def temperature_unit("kelvin"), do: "K"
  def temperature_unit(_), do: "C"
end
