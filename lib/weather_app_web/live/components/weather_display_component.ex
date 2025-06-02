defmodule WeatherAppWeb.WeatherLive.Components.WeatherDisplayComponent do
  use WeatherAppWeb, :live_component

  alias WeatherApp.Weather.TemperatureConverter

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="weather-display">
      <%= if @weather do %>
        <div class="weather-info">
          <h2>🌤️ Clima actual</h2>

          <div class="weather-details">
            <div class="weather-item">
              <span class="weather-label">Temperatura:</span>
              <span class="weather-value">
                <%= @weather.temperature %>°<%= TemperatureConverter.temperature_unit(@temperature_format) %>
              </span>
            </div>

            <div class="weather-item">
              <span class="weather-label">Humedad:</span>
              <span class="weather-value"><%= @weather.humidity %>%</span>
            </div>

            <div class="weather-item">
              <span class="weather-label">Descripción:</span>
              <span class="weather-value"><%= @weather.description %></span>
            </div>

            <div class="weather-item">
              <span class="weather-label">Viento:</span>
              <span class="weather-value"><%= @weather.wind_speed %> m/s</span>
            </div>
          </div>
        </div>
      <% else %>
        <div class="no-weather">
          <p>Selecciona una ciudad para ver el clima actual</p>
        </div>
      <% end %>
    </div>
    """
  end
end
