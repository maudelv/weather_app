defmodule WeatherAppWeb.WeatherLive do
  use WeatherAppWeb, :live_view

  alias WeatherApp.Controllers.Weather.FindCities
  alias WeatherApp.Controllers.Weather.WeatherData

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, cities: [], weather: nil, error: nil)}
  end

  def handle_event("change_temperature_format", %{"format" => format}, socket) do
    {:noreply}
  end

  def handle_event("search_cities", params, socket) do
    query = case params do
      # If we try to get the query from a text input, submit form or an page load
      # try to extract the value from expected cases.
      %{"value" => q} -> q
      %{"query" => q} -> q
      _ -> ""
    end

    # Limpiar resultados anteriores
    socket = assign(socket, cities: [], error: nil)

    if query == "" do
      {:noreply, socket}
    else
      case FindCities.find_cities(query) do
        {:ok, cities} ->
          {:noreply, assign(socket, cities: cities, error: nil)}
        {:error, reason} ->
          {:noreply, assign(socket, error: reason, cities: [])}
      end
    end
  end

  @impl true
  def handle_event("get_weather", %{"lat" => lat, "lon" => lon}, socket) do
    with {:ok, {lat_float, lon_float}} <- parse_coordinates(lat, lon),
        {:ok, weather} <- WeatherData.get_current_weather(lat_float, lon_float) do
      {:noreply, assign(socket, weather: weather, error: nil)}
    else
      {:error, reason} ->
        Logger.warning("Weather fetch failed: #{inspect(reason)}")
        {:noreply, assign(socket, error: reason)}
    end
  end

  defp parse_coordinates(lat, lon) do
    try do
      lat_float = String.to_float(lat)
      lon_float = String.to_float(lon)
      {:ok, {lat_float, lon_float}}
    rescue
      ArgumentError -> {:error, "Invalid coordinates format"}
    end
  end

  def render(assigns) do
    ~H"""
    <div>
      <h1>Buscar ciudad</h1>
      <form phx-submit="search_cities">
        <input type="text" name="value" phx-debounce="300" phx-keyup="search_cities" placeholder="Introduce el nombre de la ciudad" required />
        <button type="submit">Buscar</button>
      </form>

      <div>
        <label for="temperature_format">Formato de temperatura:</label>
        <select id="temperature_format" name="format" phx-change="change_temperature_format">
          <option value="default">Selecciona formato</option>
          <option value="kelvin">Kelvin</option>
          <option value="celsius" selected>Celsius</option>
          <option value="fahrenheit">Fahrenheit</option>
        </select>
      </div>

      <%= if @error do %>
        <p class="error"><%= @error %></p>
      <% end %>

      <ul>
        <%= for city <- @cities do %>
          <li>
            <span><%= city["name"] %>, <%= city["country"] %></span>
            <button phx-click="get_weather" phx-value-lat={city["lat"]} phx-value-lon={city["lon"]}>Get Weather</button>
          </li>
        <% end %>
      </ul>

      <%= if @weather do %>
        <div class="weather-info">
          <h2>Clima actual</h2>
          <p>Temperature: <%= @weather.temperature %></p>
          <p>Humidity: <%= @weather.humidity %>%</p>
          <p>Description: <%= @weather.description %></p>
          <p>Wind Speed: <%= @weather.wind_speed %> m/s</p>
        </div>
      <% end %>
    </div>
    """
  end
end
