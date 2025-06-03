defmodule WeatherApp.Controllers.Weather.WeatherDataTest do
  use ExUnit.Case, async: true
  import Mox

  alias WeatherApp.Controllers.Weather.WeatherData
  alias WeatherApp.HTTPoisonMock

  # Ensure mocks are verified
  setup :verify_on_exit!

  describe "get_current_weather/3" do
    test "returns formatted weather data when API responds successfully" do
      weather_response = %{
        "current" => %{
          "temp" => 22.5,
          "humidity" => 65,
          "weather" => [%{"description" => "cielo claro", "icon" => "01d"}],
          "wind_speed" => 3.2
        },
        "hourly" => [
          %{
            "dt" => 1_640_995_200,
            "temp" => 21.0,
            "humidity" => 70,
            "weather" => [%{"description" => "parcialmente nublado", "icon" => "02d"}],
            "wind_speed" => 2.8
          },
          %{
            "dt" => 1_640_998_800,
            "temp" => 23.0,
            "humidity" => 68,
            "weather" => [%{"description" => "soleado", "icon" => "01d"}],
            "wind_speed" => 3.0
          }
        ],
        "daily" => [
          %{
            "dt" => 1_640_995_200,
            "temp" => %{"day" => 20.0, "min" => 15.0, "max" => 25.0},
            "humidity" => 60,
            "weather" => [%{"description" => "soleado", "icon" => "01d"}],
            "wind_speed" => 4.0
          },
          %{
            "dt" => 1_641_081_600,
            "temp" => %{"day" => 18.0, "min" => 12.0, "max" => 22.0},
            "humidity" => 55,
            "weather" => [%{"description" => "nublado", "icon" => "03d"}],
            "wind_speed" => 3.5
          }
        ]
      }

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(weather_response)
         }}
      end)

      result = WeatherData.get_current_weather(40.4168, -3.7038, "metric")

      assert {:ok, formatted_weather} = result

      # Test current weather formatting
      current = formatted_weather.current_weather
      assert current.temperature == 22.5
      assert current.original_temperature == 22.5
      assert current.humidity == 65
      assert current.description == "cielo claro"
      assert current.icon == "01d"
      assert current.wind_speed == 3.2
      assert current.wind_speed_unit == "m/s"

      # Test hourly weather formatting
      hourly = formatted_weather.hourly_weather
      assert length(hourly) == 2

      first_hour = Enum.at(hourly, 0)
      assert first_hour.time == 1_640_995_200
      assert first_hour.temperature == 21.0
      assert first_hour.original_temperature == 21.0
      assert first_hour.temperature_unit == "metric"
      assert first_hour.humidity == 70
      assert first_hour.icon == "02d"
      assert first_hour.wind_speed == 2.8
      assert first_hour.wind_speed_unit == "m/s"

      # Test daily weather formatting
      daily = formatted_weather.weekly_weather
      assert length(daily) == 2

      first_day = Enum.at(daily, 0)
      assert first_day.date == 1_640_995_200
      assert first_day.temperature == 20.0
      assert first_day.temp_min == 15.0
      assert first_day.temp_max == 25.0
      assert first_day.original_temperature == 20.0
      assert first_day.original_temp_min == 15.0
      assert first_day.original_temp_max == 25.0
      assert first_day.temperature_unit == "metric"
      assert first_day.humidity == 60
      assert first_day.icon == "01d"
      assert first_day.wind_speed == 4.0
      assert first_day.wind_speed_unit == "m/s"
    end

    test "returns error when API client returns error" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      result = WeatherData.get_current_weather(40.4168, -3.7038, "metric")

      assert {:error, "Error de conexión al obtener el clima: timeout"} = result
    end

    test "returns error when API responds with error status" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok, %HTTPoison.Response{status_code: 400}}
      end)

      result = WeatherData.get_current_weather(0.0, 0.0, "metric")

      assert {:error,
              "No se pudieron obtener datos del clima para las coordenadas proporcionadas."} =
               result
    end

    test "handles weather data with missing weather descriptions gracefully" do
      weather_response = %{
        "current" => %{
          "temp" => 22.5,
          "humidity" => 65,
          "weather" => [],
          "wind_speed" => 3.2
        },
        "hourly" => [
          %{
            "dt" => 1_640_995_200,
            "temp" => 21.0,
            "humidity" => 70,
            "weather" => nil,
            "wind_speed" => 2.8
          }
        ],
        "daily" => [
          %{
            "dt" => 1_640_995_200,
            "temp" => %{"day" => 20.0, "min" => 15.0, "max" => 25.0},
            "humidity" => 60,
            "weather" => [%{}],
            "wind_speed" => 4.0
          }
        ]
      }

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(weather_response)
         }}
      end)

      result = WeatherData.get_current_weather(40.4168, -3.7038, "metric")

      assert {:ok, formatted_weather} = result

      # Should handle missing weather descriptions gracefully
      assert formatted_weather.current_weather.description == ""
      assert formatted_weather.current_weather.icon == ""

      first_hour = Enum.at(formatted_weather.hourly_weather, 0)
      assert first_hour.icon == ""

      first_day = Enum.at(formatted_weather.weekly_weather, 0)
      assert first_day.icon == ""
    end

    test "handles different temperature formats" do
      weather_response = %{
        "current" => %{
          "temp" => 72.5,
          "humidity" => 65,
          "weather" => [%{"description" => "clear sky", "icon" => "01d"}],
          "wind_speed" => 3.2
        },
        "hourly" => [],
        "daily" => []
      }

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(weather_response)
         }}
      end)

      result = WeatherData.get_current_weather(40.4168, -3.7038, "imperial")

      assert {:ok, formatted_weather} = result
      assert formatted_weather.current_weather.temperature == 72.5
      assert formatted_weather.current_weather.original_temperature == 72.5
    end

    test "handles weather data with partial hourly and daily data" do
      weather_response = %{
        "current" => %{
          "temp" => 22.5,
          "humidity" => 65,
          "weather" => [%{"description" => "cielo claro", "icon" => "01d"}],
          "wind_speed" => 3.2
        },
        "hourly" => [],
        "daily" => []
      }

      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(weather_response)
         }}
      end)

      result = WeatherData.get_current_weather(40.4168, -3.7038, "metric")

      assert {:ok, formatted_weather} = result
      assert formatted_weather.current_weather.temperature == 22.5
      assert formatted_weather.hourly_weather == []
      assert formatted_weather.weekly_weather == []
    end
  end
end
