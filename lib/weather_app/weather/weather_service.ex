defmodule WeatherApp.Weather.WeatherService do
  @moduledoc """
  Servicio que maneja toda la lógica de negocio relacionada con el clima.
  """

  alias WeatherApp.Controllers.Weather.{FindCities, WeatherData, Favorites}
  alias WeatherApp.Weather.TemperatureConverter
  alias Phoenix.LiveView.Socket

  @spec initialize_weather_state(Socket.t()) :: Socket.t()
  def initialize_weather_state(socket) do
    Phoenix.Component.assign(socket,
      cities: [],
      weather: nil,
      temperature_format: "celsius",
      error: nil,
      favorite_cities: Favorites.list_favorites()
    )
  end

  @spec update_temperature_format(Socket.t(), String.t()) :: Socket.t()
  def update_temperature_format(socket, format) do
    socket = Phoenix.Component.assign(socket, temperature_format: format)

    if socket.assigns.weather do
      converted_weather = TemperatureConverter.convert_weather_data(socket.assigns.weather, format)
      Phoenix.Component.assign(socket, weather: converted_weather)
    else
      socket
    end
  end

  @spec search_cities(Socket.t(), String.t()) :: Socket.t()
  def search_cities(socket, query) do
    query = String.trim(query)
    socket = Phoenix.Component.assign(socket, cities: [], error: nil)

    if query == "" do
      socket
    else
      case FindCities.find_cities(query) do
        {:ok, cities} ->
          Phoenix.Component.assign(socket, cities: cities, error: nil)
        {:error, reason} ->
          Phoenix.Component.assign(socket, error: reason, cities: [])
      end
    end
  end

  @spec fetch_weather_data(Socket.t(), String.t(), String.t()) :: Socket.t()
  def fetch_weather_data(socket, lat, lon) do
    with {:ok, {lat_float, lon_float}} <- parse_coordinates(lat, lon),
         {:ok, weather} <- WeatherData.get_current_weather(lat_float, lon_float, "metric") do
      converted_weather = TemperatureConverter.convert_weather_data(weather, socket.assigns.temperature_format)
      IO.inspect(converted_weather, label: "Converted Weather Data")
      Phoenix.Component.assign(socket, weather: converted_weather, error: nil)
    else
      {:error, reason} ->
        Phoenix.Component.assign(socket, error: reason)
    end
  end

  @spec add_city_to_favorites(Socket.t(), map()) :: Socket.t()
  def add_city_to_favorites(socket, params) do
    with %{"country_code" => country_code, "lat" => lat, "lon" => lon} <- params,
         {:ok, {lat_float, lon_float}} <- parse_coordinates(lat, lon) do

      city_data = build_city_data(params, country_code, lat_float, lon_float)

      case Favorites.add_favorite(city_data) do
        {:ok, _favorite_city} ->
          updated_favorites = Favorites.list_favorites()

          socket
          |> Phoenix.LiveView.put_flash(:info, "Ciudad añadida a favoritos.")
          |> Phoenix.Component.assign(:favorite_cities, updated_favorites)

        {:error, changeset} ->
          error_message = build_favorite_error_message(changeset)
          Phoenix.LiveView.put_flash(socket, :error, error_message)
      end
    else
      _error ->
        Phoenix.LiveView.put_flash(socket, :error, "Datos de ciudad inválidos para añadir a favoritos.")
    end
  rescue
    Ecto.ConstraintError ->
      Phoenix.LiveView.put_flash(socket, :error, "Error: Esta ciudad ya está en favoritos.")
    _error ->
      Phoenix.LiveView.put_flash(socket, :error, "Error inesperado al procesar la solicitud.")
  end

  @spec remove_city_from_favorites(Socket.t(), String.t()) :: Socket.t()
  def remove_city_from_favorites(socket, id) do
    case Favorites.delete_favorite(id) do
      {:ok, _} ->
        favorite_cities = Favorites.list_favorites()

        socket
        |> Phoenix.Component.assign(:favorite_cities, favorite_cities)
        |> Phoenix.LiveView.put_flash(:info, "Ciudad eliminada de favoritos.")

      {:error, _} ->
        Phoenix.LiveView.put_flash(socket, :error, "Error al eliminar ciudad de favoritos.")
    end
  end

  # Private functions

  defp parse_coordinates(lat, lon) do
    try do
      lat_float = String.to_float(lat)
      lon_float = String.to_float(lon)
      {:ok, {lat_float, lon_float}}
    rescue
      ArgumentError -> {:error, "Formato de coordenadas inválido. Asegúrate de que son números."}
    end
  end

  defp build_city_data(params, country_code, lat_float, lon_float) do
    current_count = Favorites.count_favorites()

    %{
      country_code: country_code,
      name: Map.get(params, "name", ""),
      state: Map.get(params, "state", ""),
      lat: lat_float,
      lon: lon_float,
      position: current_count
    }
  end

  defp build_favorite_error_message(changeset) do
    Enum.find_value(changeset.errors, fn {field, {msg, opts}} ->
      is_unique_favorite_error =
        Keyword.get(opts, :constraint_name) == :favorite_cities_country_code_state_lat_lon_index ||
          (Keyword.get(opts, :constraint) == :unique &&
             String.contains?(msg, "ya está en favoritos"))

      if is_unique_favorite_error do
        "Error: Esta ciudad ya está en favoritos."
      else
        "Error al añadir: #{Atom.to_string(field)} #{msg}"
      end
    end) || "Error al añadir la ciudad a favoritos. Verifique los datos."
  end
end
