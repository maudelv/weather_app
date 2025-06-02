defmodule WeatherApp.Weather.TemperatureConverterTest do
  use ExUnit.Case, async: true

  alias WeatherApp.Weather.TemperatureConverter

  describe "convert_weather_data/2" do
    test "converts complete weather data to fahrenheit" do
      weather_data = %{
        current_weather: %{
          temperature: 20.0,
          original_temperature: 20.0,
          humidity: 65,
          description: "clear sky"
        },
        hourly_weather: [
          %{
            temperature: 18.0,
            original_temperature: 18.0,
            humidity: 70,
            time: 1640995200
          },
          %{
            temperature: 22.0,
            original_temperature: 22.0,
            humidity: 68,
            time: 1640998800
          }
        ],
        weekly_weather: [
          %{
            temperature: 19.0,
            temp_min: 15.0,
            temp_max: 25.0,
            original_temperature: 19.0,
            original_temp_min: 15.0,
            original_temp_max: 25.0,
            humidity: 60,
            date: 1640995200
          }
        ]
      }

      result = TemperatureConverter.convert_weather_data(weather_data, "fahrenheit")

      # Test current weather conversion
      assert result.current_weather.temperature == 68.0
      assert result.current_weather.temperature_unit == "F"
      assert result.current_weather.humidity == 65

      # Test hourly weather conversion
      assert length(result.hourly_weather) == 2
      first_hour = Enum.at(result.hourly_weather, 0)
      assert first_hour.temperature == 64.4
      assert first_hour.temperature_unit == "F"
      assert first_hour.humidity == 70

      second_hour = Enum.at(result.hourly_weather, 1)
      assert second_hour.temperature == 71.6
      assert second_hour.temperature_unit == "F"

      # Test weekly weather conversion
      assert length(result.weekly_weather) == 1
      first_day = Enum.at(result.weekly_weather, 0)
      assert first_day.temperature == 66.2
      assert first_day.temp_min == 59.0
      assert first_day.temp_max == 77.0
      assert first_day.temperature_unit == "F"
      assert first_day.humidity == 60
    end

    test "converts complete weather data to kelvin" do
      weather_data = %{
        current_weather: %{
          temperature: 20.0,
          original_temperature: 20.0,
          humidity: 65
        },
        hourly_weather: [
          %{
            temperature: 0.0,
            original_temperature: 0.0,
            humidity: 70
          }
        ],
        weekly_weather: [
          %{
            temperature: -10.0,
            temp_min: -15.0,
            temp_max: -5.0,
            original_temperature: -10.0,
            original_temp_min: -15.0,
            original_temp_max: -5.0,
            humidity: 60
          }
        ]
      }

      result = TemperatureConverter.convert_weather_data(weather_data, "kelvin")

      # Test current weather conversion
      assert result.current_weather.temperature == 293.15
      assert result.current_weather.temperature_unit == "K"

      # Test hourly weather conversion
      first_hour = Enum.at(result.hourly_weather, 0)
      assert first_hour.temperature == 273.15
      assert first_hour.temperature_unit == "K"

      # Test weekly weather conversion
      first_day = Enum.at(result.weekly_weather, 0)
      assert first_day.temperature == 263.15
      assert first_day.temp_min == 258.15
      assert first_day.temp_max == 268.15
      assert first_day.temperature_unit == "K"
    end

    test "keeps celsius temperatures unchanged" do
      weather_data = %{
        current_weather: %{
          temperature: 20.0,
          original_temperature: 20.0,
          humidity: 65
        },
        hourly_weather: [
          %{
            temperature: 18.0,
            original_temperature: 18.0,
            humidity: 70
          }
        ],
        weekly_weather: [
          %{
            temperature: 22.0,
            temp_min: 15.0,
            temp_max: 25.0,
            original_temperature: 22.0,
            original_temp_min: 15.0,
            original_temp_max: 25.0,
            humidity: 60
          }
        ]
      }

      result = TemperatureConverter.convert_weather_data(weather_data, "celsius")

      # Test that temperatures remain unchanged
      assert result.current_weather.temperature == 20.0
      assert result.current_weather.temperature_unit == "C"

      first_hour = Enum.at(result.hourly_weather, 0)
      assert first_hour.temperature == 18.0
      assert first_hour.temperature_unit == "C"

      first_day = Enum.at(result.weekly_weather, 0)
      assert first_day.temperature == 22.0
      assert first_day.temp_min == 15.0
      assert first_day.temp_max == 25.0
      assert first_day.temperature_unit == "C"
    end

    test "handles unknown temperature format by defaulting to celsius" do
      weather_data = %{
        current_weather: %{
          temperature: 20.0,
          original_temperature: 20.0,
          humidity: 65
        },
        hourly_weather: [],
        weekly_weather: []
      }

      result = TemperatureConverter.convert_weather_data(weather_data, "unknown_format")

      assert result.current_weather.temperature == 20.0
      assert result.current_weather.temperature_unit == "C"
    end

    test "handles empty hourly and weekly weather arrays" do
      weather_data = %{
        current_weather: %{
          temperature: 20.0,
          original_temperature: 20.0,
          humidity: 65
        },
        hourly_weather: [],
        weekly_weather: []
      }

      result = TemperatureConverter.convert_weather_data(weather_data, "fahrenheit")

      assert result.current_weather.temperature == 68.0
      assert result.current_weather.temperature_unit == "F"
      assert result.hourly_weather == []
      assert result.weekly_weather == []
    end
  end

  describe "temperature_unit/1" do
    test "returns correct unit for celsius" do
      assert TemperatureConverter.temperature_unit("celsius") == "C"
    end

    test "returns correct unit for fahrenheit" do
      assert TemperatureConverter.temperature_unit("fahrenheit") == "F"
    end

    test "returns correct unit for kelvin" do
      assert TemperatureConverter.temperature_unit("kelvin") == "K"
    end

    test "returns default unit for unknown format" do
      assert TemperatureConverter.temperature_unit("unknown") == "C"
      assert TemperatureConverter.temperature_unit("") == "C"
      assert TemperatureConverter.temperature_unit(nil) == "C"
    end
  end

  describe "temperature conversion accuracy" do
    test "celsius to fahrenheit conversion is accurate" do
      # Test common temperature conversions
      assert convert_temp(0.0, "fahrenheit") == 32.0
      assert convert_temp(100.0, "fahrenheit") == 212.0
      assert convert_temp(-40.0, "fahrenheit") == -40.0
      assert_in_delta convert_temp(37.0, "fahrenheit"), 98.6, 0.1
    end

    test "celsius to kelvin conversion is accurate" do
      # Test common temperature conversions
      assert convert_temp(0.0, "kelvin") == 273.15
      assert convert_temp(100.0, "kelvin") == 373.15
      assert convert_temp(-273.15, "kelvin") == 0.0
      assert convert_temp(20.0, "kelvin") == 293.15
    end

    test "celsius remains unchanged" do
      assert convert_temp(0.0, "celsius") == 0.0
      assert convert_temp(100.0, "celsius") == 100.0
      assert convert_temp(-10.0, "celsius") == -10.0
      assert convert_temp(37.5, "celsius") == 37.5
    end
  end

  # Helper function to test individual temperature conversion
  defp convert_temp(temp, format) do
    weather_data = %{
      current_weather: %{
        temperature: temp,
        original_temperature: temp,
        humidity: 65
      },
      hourly_weather: [],
      weekly_weather: []
    }

    result = TemperatureConverter.convert_weather_data(weather_data, format)
    result.current_weather.temperature
  end
end
