defmodule WeatherAppWeb.WeatherLive do
  use WeatherAppWeb, :live_view

  alias WeatherApp.Controllers.Weather.FindCities
  alias WeatherApp.Controllers.Weather.WeatherData
  alias WeatherApp.Controllers.Weather.Favorites

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, cities: [], weather: nil, error: nil, temperature_format: "celsius")}
  end

  def handle_event("change_temperature_format", %{"format" => format}, socket) do
    # Actualizar el formato de temperatura y reconvertir si ya hay datos de clima
    socket = assign(socket, temperature_format: format)

    socket = if socket.assigns.weather do
      # Si ya tenemos datos de clima, reconvertir la temperatura
      converted_weather = convert_temperature(socket.assigns.weather, format)
      assign(socket, weather: converted_weather)
    else
      socket
    end

    {:noreply, socket}
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
      # Convertir la temperatura al formato seleccionado antes de asignar
      converted_weather = convert_temperature(weather, socket.assigns.temperature_format)
      {:noreply, assign(socket, weather: converted_weather, error: nil)}
    else
      {:error, reason} ->
        Logger.warning("Weather fetch failed: #{inspect(reason)}")
        {:noreply, assign(socket, error: reason)}
    end
  end

  defp convert_temperature(weather, format) do
    # Usamos original_temperature como base para todos los cálculos
    # ya que temperature puede haber sido modificada anteriormente
    temp_kelvin = weather.original_temperature

    converted_temp = case format do
      "celsius" -> temp_kelvin - 273.15
      "fahrenheit" -> (temp_kelvin - 273.15) * 9 / 5 + 32
      "kelvin" -> temp_kelvin
      _ -> temp_kelvin - 273.15  # Default a celsius
    end

    %{weather | temperature: Float.round(converted_temp, 1)}
  end

  def handle_event("add_favorite_city", params, socket) do
    with %{"country_code" => country_code, "lat" => lat, "lon" => lon} <- params,
         {:ok, {lat_float, lon_float}} <- parse_coordinates(lat, lon) do

      # Get current count of favorites to determine next position
      current_count = Favorites.count_favorites()

      city_data = %{
        country_code: country_code,
        state: Map.get(params, "state", ""),
        lat: lat_float,
        lon: lon_float,
        position: current_count  # Sequential position based on current count
      }

      case Favorites.add_favorite(city_data) do
        {:ok, _favorite_city} ->
          socket = put_flash(socket, :info, "Ciudad añadida a favoritos.")
          {:noreply, socket}
        {:error, changeset} ->
          error_messages = Enum.map_join(changeset.errors, ", ", fn {field, {msg, _opts}} ->
            "#{Atom.to_string(field)} #{msg}"
          end)
          socket = put_flash(socket, :error, "Error al añadir a favoritos: #{error_messages}")
          {:noreply, socket}
      end
    else
      _mismatch_or_error ->
        socket = put_flash(socket, :error, "Datos de ciudad inválidos para añadir a favoritos.")
        {:noreply, socket}
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
        <form phx-change="change_temperature_format">
          <select
            id="temperature_format"
            name="format"
            value={@temperature_format}
          >
            <option value="celsius" selected={@temperature_format == "celsius"}>Celsius (°C)</option>
            <option value="fahrenheit" selected={@temperature_format == "fahrenheit"}>Fahrenheit (°F)</option>
            <option value="kelvin" selected={@temperature_format == "kelvin"}>Kelvin (K)</option>
          </select>
        </form>
      </div>

      <%= if @error do %>
        <p class="error"><%= @error %></p>
      <% end %>

      <ul>
        <%= for city <- @cities do %>
          <li>
            <span><%= city["name"] %>, <%= city["country"] %></span>
            <button phx-click="get_weather" phx-value-lat={city["lat"]} phx-value-lon={city["lon"]}>Get Weather</button>
            <button phx-click="add_favorite_city"
                    phx-value-country_code={city["country"]}
                    phx-value-state={city["state"]}
                    phx-value-name={city["name"]}
                    phx-value-lat={city["lat"]}
                    phx-value-lon={city["lon"]}>
              Añadir a Favoritas
            </button>
          </li>
        <% end %>
      </ul>

      <%= if @weather do %>
        <div class="weather-info">
          <h2>🌤️ Clima actual</h2>
          <p><strong>Temperatura:</strong> <%= @weather.temperature %>°<%= temperature_unit(@temperature_format) %></p>
          <p><strong>Humedad:</strong> <%= @weather.humidity %>%</p>
          <p><strong>Descripción:</strong> <%= @weather.description %></p>
          <p><strong>Viento:</strong> <%= @weather.wind_speed %> m/s</p>
        </div>
      <% end %>

      <div class="favorite-cities">
        <h2>Ciudades favoritas</h2>
        <p>Aquí puedes agregar y gestionar tus ciudades favoritas.</p>
        <!-- Aquí podrías implementar la lógica para manejar las ciudades favoritas -->
      </div>
    </div>
    """
  end

  defp temperature_unit("celsius"), do: "C"
  defp temperature_unit("fahrenheit"), do: "F"
  defp temperature_unit("kelvin"), do: "K"
  defp temperature_unit(_), do: "C"
end
