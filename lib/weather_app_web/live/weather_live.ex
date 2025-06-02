# lib/weather_app_web/live/weather_live.ex
defmodule WeatherAppWeb.WeatherLive do
  use WeatherAppWeb, :live_view

  alias WeatherAppWeb.WeatherLive.Components.{
    CitySearchComponent,
    WeatherDisplayComponent,
    FavoriteCitiesComponent,
    TemperatureFormatComponent
  }
  alias WeatherApp.Weather.WeatherService

  @impl true
  def mount(_params, _session, socket) do
    {:ok, WeatherService.initialize_weather_state(socket)}
  end

  @impl true
  def handle_event("temperature_format_changed", %{"format" => format}, socket) do
    {:noreply, WeatherService.update_temperature_format(socket, format)}
  end

  def handle_event("weather_requested", %{"lat" => lat, "lon" => lon}, socket) do
    {:noreply, WeatherService.fetch_weather_data(socket, lat, lon)}
  end

  def handle_event("favorite_added", city_params, socket) do
    {:noreply, WeatherService.add_city_to_favorites(socket, city_params)}
  end

  def handle_event("favorite_removed", %{"id" => id}, socket) do
    {:noreply, WeatherService.remove_city_from_favorites(socket, id)}
  end

  def handle_event("cities_searched", %{"query" => query}, socket) do
    {:noreply, WeatherService.search_cities(socket, query)}
  end

  # Handle messages sent from components
  @impl true
  def handle_info({:temperature_format_changed, params}, socket) do
    handle_event("temperature_format_changed", params, socket)
  end

  def handle_info({:weather_requested, params}, socket) do
    handle_event("weather_requested", params, socket)
  end

  def handle_info({:favorite_added, params}, socket) do
    handle_event("favorite_added", params, socket)
  end

  def handle_info({:favorite_removed, params}, socket) do
    handle_event("favorite_removed", params, socket)
  end

  def handle_info({:cities_searched, params}, socket) do
    handle_event("cities_searched", params, socket)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="weather-app p-4">
      <div class="grid grid-cols-12 gap-x-4">
        <div class="col-span-3 space-y-4">
          <.live_component
            module={CitySearchComponent}
            id="city-search"
            cities={@cities}
            error={@error}
          />
          <.live_component
            module={TemperatureFormatComponent}
            id="temperature-format"
            temperature_format={@temperature_format}
          />
          <.live_component
            module={FavoriteCitiesComponent}
            id="favorite-cities"
            favorite_cities={@favorite_cities}
          />
        </div>
        <div class="col-span-9 shadow-lg p-4 mb-4 bg-white rounded">
          <.live_component
            module={WeatherDisplayComponent}
            id="weather-display"
            weather={@weather}
            temperature_format={@temperature_format}
          />
        </div>
      </div>
    </div>
    """
  end
end
