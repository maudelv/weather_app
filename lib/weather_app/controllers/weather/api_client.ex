defmodule WeatherApp.Controllers.Weather.ApiClient do

  @geo_url Dotenv.get("OPENWEATHER_API_GEO_URL")
  @api_key Dotenv.get("OPENWEATHER_API_KEY")

  def search_cities(query) do
    url = "#{@geo_url}/direct?q=#{query}&limit=10&appid=#{@api_key}"

    case HTTPoison.get(url) do
      {:ok, response} when response.status_code == 200 ->
        case Jason.decode(response.body) do
          {:ok, decoded_response} ->
            validate_cities_response(decoded_response)
          {:error, reason} ->
            {:error, "JSON decode error: #{reason}"}
        end
      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Error: #{code}"}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @doc """
  Validates the cities search response.
  """
  defp validate_cities_response(response) do
    case response do
      [] -> {:error, "No cities found"}
      cities when is_list(cities) -> {:ok, cities}
      _ -> {:error, "Invalid response format"}
    end
  end
end
