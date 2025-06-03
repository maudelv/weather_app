defmodule WeatherApp.Controllers.Weather.ApiClientTest do
  use ExUnit.Case, async: true
  import Mox

  alias WeatherApp.Controllers.Weather.ApiClient
  alias WeatherApp.HTTPoisonMock

  # Asegurar que los mocks se verifican
  setup :verify_on_exit!

  describe "search_cities/1" do
    test "returns cities when API responds successfully" do
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

      # Configurar el mock
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: Jason.encode!(cities_response)
         }}
      end)

      # Ejecutar la función
      result = ApiClient.search_cities("Madrid", HTTPoisonMock)

      # Verificar resultado
      assert {:ok, cities} = result
      assert length(cities) == 2
      assert Enum.find(cities, &(&1["country"] == "ES"))
      assert Enum.find(cities, &(&1["country"] == "US"))
    end

    test "returns error when no cities found" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok,
         %HTTPoison.Response{
           status_code: 200,
           body: "[]"
         }}
      end)

      result = ApiClient.search_cities("NonExistentCity", HTTPoisonMock)

      assert {:error, "No se ha encontrado ningina ciudad con ese nombre."} = result
    end

    test "returns error when API responds with 400" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok, %HTTPoison.Response{status_code: 400}}
      end)

      result = ApiClient.search_cities("", HTTPoisonMock)

      assert {:error,
              "No se ha encontrado una ciudad con ese nombre o la solicitud es incorrecta."} =
               result
    end

    test "returns error when API responds with other error codes" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok, %HTTPoison.Response{status_code: 500}}
      end)

      result = ApiClient.search_cities("Madrid", HTTPoisonMock)

      assert {:error, "Error del API: 500. Por favor, inténtalo de nuevo."} = result
    end

    test "returns error when connection fails" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:error, %HTTPoison.Error{reason: :timeout}}
      end)

      result = ApiClient.search_cities("Madrid", HTTPoisonMock)

      assert {:error, "Error de conexión: timeout"} = result
    end
  end

  describe "get_weather_data/3" do
    test "returns weather data when API responds successfully" do
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
          }
        ],
        "daily" => [
          %{
            "dt" => 1_640_995_200,
            "temp" => %{"day" => 20.0, "min" => 15.0, "max" => 25.0},
            "humidity" => 60,
            "weather" => [%{"description" => "soleado", "icon" => "01d"}],
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

      result = ApiClient.get_weather_data(40.4168, -3.7038, "metric", HTTPoisonMock)

      assert {:ok, weather_data} = result
      assert weather_data["current"]["temp"] == 22.5
      assert weather_data["current"]["humidity"] == 65
      assert is_list(weather_data["hourly"])
      assert is_list(weather_data["daily"])
    end

    test "returns error when API responds with 400" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok, %HTTPoison.Response{status_code: 400}}
      end)

      result = ApiClient.get_weather_data(0.0, 0.0, "metric", HTTPoisonMock)

      assert {:error,
              "No se pudieron obtener datos del clima para las coordenadas proporcionadas."} =
               result
    end

    test "returns error when API responds with other error codes" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:ok, %HTTPoison.Response{status_code: 401}}
      end)

      result = ApiClient.get_weather_data(40.4168, -3.7038, "metric", HTTPoisonMock)

      assert {:error, "Error del API del clima: 401. Por favor, inténtalo de nuevo."} = result
    end

    test "returns error when connection fails" do
      HTTPoisonMock
      |> expect(:get, fn _url ->
        {:error, %HTTPoison.Error{reason: :nxdomain}}
      end)

      result = ApiClient.get_weather_data(40.4168, -3.7038, "metric", HTTPoisonMock)

      assert {:error, "Error de conexión al obtener el clima: nxdomain"} = result
    end
  end
end
