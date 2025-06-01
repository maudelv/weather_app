defmodule WeatherApp.Controllers.Weather.ApiClient do

  defp base_url, do: System.get_env("OPENWEATHER_API_BASE_URL")
  defp api_key, do: System.get_env("OPENWEATHER_API_KEY")

  def search_cities(query) do
    url = "#{base_url()}/geo/1.0/direct?q=#{query}&limit=10&appid=#{api_key()}"

    case HTTPoison.get(url) do
      {:ok, response} when response.status_code == 200 ->
        case Jason.decode(response.body) do
          {:ok, decoded_response} ->
            validate_cities_response(decoded_response)
          {:error, reason} ->
            {:error, "Error al procesar la respuesta del API: #{reason}"}
        end
      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, "No se ha encontrado una ciudad con ese nombre o la solicitud es incorrecta."}
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Error del API: #{code}. Por favor, inténtalo de nuevo."}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Error de conexión: #{reason}"}
    end
  end

  @spec get_weather_data(float(), float()) :: {:ok, map()} | {:error, String.t()}
  def get_weather_data(lat, lon) do
    url = "#{base_url()}/data/2.5/weather?lat=#{lat}&lon=#{lon}&appid=#{api_key()}"

    case HTTPoison.get(url) do
      {:ok, response} when response.status_code == 200 ->
        case Jason.decode(response.body) do
          {:ok, decoded_response} ->
            {:ok, decoded_response}
          {:error, reason} ->
            {:error, "Error al procesar la respuesta del API del clima: #{reason}"}
        end
      {:ok, %HTTPoison.Response{status_code: 400}} ->
        {:error, "No se pudieron obtener datos del clima para las coordenadas proporcionadas."}
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Error del API del clima: #{code}. Por favor, inténtalo de nuevo."}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Error de conexión al obtener el clima: #{reason}"}
    end
  end


  @doc """
  Validates the cities search response.
  """
  defp validate_cities_response(response) do
    case response do
      [] -> {:error, "No se ha encontrado ningina ciudad con ese nombre."}
      cities when is_list(cities) -> {:ok, cities}
      _ -> {:error, "Respuesta inesperada del API de búsqueda de ciudades."}
    end
  end
end
