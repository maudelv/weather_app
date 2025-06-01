defmodule WeatherAppWeb.WeatherLive do
  use WeatherAppWeb, :live_view

  alias WeatherApp.Controllers.Weather.FindCities
  alias WeatherApp.Controllers.Weather.WeatherData
  alias WeatherApp.Controllers.Weather.Favorites

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       cities: [],
       weather: nil,
       temperature_format: "celsius",
       error: nil,
       favorite_cities: Favorites.list_favorites()
     )}
  end

  def handle_event("change_temperature_format", %{"format" => format}, socket) do
    socket = assign(socket, temperature_format: format)

    socket = if socket.assigns.weather do
      converted_weather = convert_temperature(socket.assigns.weather, format)
      assign(socket, weather: converted_weather)
    else
      socket
    end

    {:noreply, socket}
  end

  def handle_event("search_cities", params, socket) do
    query =
      (case params do
         %{"value" => q} -> q
         %{"query" => q} -> q
         _ -> ""
       end)
      |> String.trim()

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
      converted_weather = convert_temperature(weather, socket.assigns.temperature_format)
      {:noreply, assign(socket, weather: converted_weather, error: nil)}
    else
      {:error, reason} ->
        {:noreply, assign(socket, error: reason)}
    end
  end

  defp convert_temperature(weather, format) do
    temp_kelvin = weather.original_temperature

    converted_temp = case format do
      "celsius" -> temp_kelvin - 273.15
      "fahrenheit" -> (temp_kelvin - 273.15) * 9 / 5 + 32
      "kelvin" -> temp_kelvin
      _ -> temp_kelvin - 273.15
    end

    %{weather | temperature: Float.round(converted_temp, 1)}
  end

  def handle_event("add_favorite_city", params, socket) do
    with %{"country_code" => country_code, "lat" => lat, "lon" => lon} <- params,
         {:ok, {lat_float, lon_float}} <- parse_coordinates(lat, lon) do

      current_count = Favorites.count_favorites()

      # TODO: 'state' en verdad no es necesario, por lo que podriamos removerlo, sin embargo para removerlo tenemos que corregir el unique_index en la migracion.

      city_data = %{
        country_code: country_code,
        name: Map.get(params, "name", ""),
        state: Map.get(params, "state", ""),
        lat: lat_float,
        lon: lon_float,
        position: current_count
      }

      try do
        case Favorites.add_favorite(city_data) do
          {:ok, _favorite_city} ->
            # Actualizar la lista de favoritos en el socket
            updated_favorites = Favorites.list_favorites()

            socket =
              socket
              |> put_flash(:info, "Ciudad añadida a favoritos.")
              |> assign(:favorite_cities, updated_favorites)

            {:noreply, socket}

          {:error, changeset} ->
            custom_error_message =
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

            socket = put_flash(socket, :error, custom_error_message)
            {:noreply, socket}
        end
      rescue
        e in Ecto.ConstraintError ->
          socket = put_flash(socket, :error, "Error: Esta ciudad ya está en favoritos.")
          {:noreply, socket}
        e ->
          socket = put_flash(socket, :error, "Error inesperado al procesar la solicitud.")
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
      ArgumentError -> {:error, "Formato de coordenadas inválido. Asegúrate de que son números."}
    end
  end

  def handle_event("remove_favorite_city", %{"id" => id}, socket) do
    case Favorites.delete_favorite(id) do
      {:ok, _} ->
        favorite_cities = Favorites.list_favorites()
        socket =
          socket
          |> assign(:favorite_cities, favorite_cities)
          |> put_flash(:info, "Ciudad eliminada de favoritos.")

        {:noreply, socket}
      {:error, _} ->
        socket = put_flash(socket, :error, "Error al eliminar ciudad de favoritos.")
        {:noreply, socket}
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

        <%= if Enum.empty?(@favorite_cities) do %>
          <p>No tienes ciudades favoritas aún. Busca una ciudad y agrégala a favoritos.</p>
        <% else %>
          <div class="favorite-cities-list">
            <%= for favorite <- @favorite_cities do %>
              <div class="favorite-city-item">
                <div class="city-info">
                  <h3><%= favorite.country_code %></h3>
                  <%= if favorite.name do %>
                    <p class="name"><%= favorite.name %></p>
                  <% end %>
                </div>

                <div class="city-actions">
                  <button
                    type="button"
                    phx-click="get_weather"
                    phx-value-lat={favorite.lat}
                    phx-value-lon={favorite.lon}
                    class="btn btn-primary"
                  >
                    Ver clima
                  </button>

                  <button
                    type="button"
                    phx-click="remove_favorite_city"
                    phx-value-id={favorite.id}
                    class="btn btn-danger"
                    data-confirm="¿Estás seguro de eliminar esta ciudad de favoritos?"
                  >
                    Eliminar
                  </button>
                </div>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp temperature_unit("celsius"), do: "C"
  defp temperature_unit("fahrenheit"), do: "F"
  defp temperature_unit("kelvin"), do: "K"
  defp temperature_unit(_), do: "C"
end
