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
    <div class="weather-display max-w-5xl mx-auto p-4 md:p-6">
      <%= if @loading do %>
        <div class="loading-weather flex flex-col items-center justify-center py-16 bg-blue-50 border border-blue-200 rounded-lg">
          <div class="animate-spin rounded-full h-16 w-16 border-b-4 border-blue-600 mb-4"></div>
        </div>
      <% end %>
      <%= if @weather && !@loading do %>
        <!-- Clima Actual -->
        <div class="weather-section current-weather bg-white p-6 rounded-lg shadow-lg mb-8">
          <h2 class="text-2xl font-bold text-blue-700 mb-6 text-center md:text-left">
            🌤️ Clima actual
          </h2>
          <div class="current-weather-details md:items-center">
            <div class="temperature-main text-center md:text-left mb-6 md:mb-0 flex-shrink-0">
              <span class="current-temp text-6xl sm:text-7xl font-bold text-blue-800">
                {round(@weather.current_weather.temperature)}
              </span>
              <span class="text-3xl sm:text-4xl font-semibold text-blue-700 align-top">
                °{TemperatureConverter.temperature_unit(@temperature_format)}
              </span>
              <%= if @weather.current_weather.icon && @weather.current_weather.icon != "" do %>
                <img
                  src={"https://openweathermap.org/img/wn/#{@weather.current_weather.icon}@2x.png"}
                  alt="weather icon"
                  class="w-16 h-16 mx-auto md:mx-0 md:inline-block md:ml-4 align-middle"
                />
              <% end %>
            </div>

            <div class="weather-grid grid grid-cols-1 sm:grid-cols-4 gap-4 flex-grow">
              <%= for day <- Enum.take(@weather.weekly_weather, 1) do %>
                <div class="weather-item bg-blue-50 p-4 rounded-md shadow-sm">
                  <span class="weather-label block text-sm font-medium text-blue-600 mb-1">
                    Temperatura máxima:
                  </span>
                  <span class="weather-value text-m font-semibold text-blue-800">
                    {round(day.temp_max || day.temperature)}°
                  </span>
                </div>

                <div class="weather-item bg-blue-50 p-4 rounded-md shadow-sm">
                  <span class="weather-label block text-sm font-medium text-blue-600 mb-1">
                    Temperatura mínima
                  </span>
                  <span class="weather-value text-m font-semibold text-blue-800">
                    {round(day.temp_min || day.temperature)}°
                  </span>
                </div>
              <% end %>

              <div class="weather-item bg-blue-50 p-4 rounded-md shadow-sm">
                <span class="weather-label block text-sm font-medium text-blue-600 mb-1">
                  Humedad:
                </span>
                <span class="weather-value text-m font-semibold text-blue-800">
                  {@weather.current_weather.humidity}%
                </span>
              </div>

              <div class="weather-item bg-blue-50 p-4 rounded-md shadow-sm">
                <span class="weather-label block text-sm font-medium text-blue-600 mb-1">
                  Descripción:
                </span>
                <span class="weather-value text-m font-semibold text-blue-800 capitalize">
                  {@weather.current_weather.description}
                </span>
              </div>

              <div class="weather-item bg-blue-50 p-4 rounded-md shadow-sm sm:col-span-2 md:col-span-1">
                <!-- Ajuste para ocupar toda la fila en sm si es el tercero, o una columna en md+ -->
                <span class="weather-label block text-sm font-medium text-blue-600 mb-1">
                  Viento:
                </span>
                <span class="weather-value text-m font-semibold text-blue-800">
                  {@weather.current_weather.wind_speed} {@weather.current_weather.wind_speed_unit}
                </span>
              </div>
            </div>
          </div>
        </div>

    <!-- Pronóstico por Horas (Próximas 24 horas) -->
        <div class="weather-section hourly-weather bg-white p-6 rounded-lg shadow-lg mb-8">
          <h3 class="text-xl font-bold text-blue-700 mb-4">📊 Próximas 24 horas</h3>
          <div class="hourly-scroll flex overflow-x-auto overflow-y-hidden pb-4 space-x-4">
            <%= for hour <- Enum.take(@weather.hourly_weather, 24) do %>
              <div class="hourly-item flex-shrink-0 w-28 bg-blue-50 p-3 rounded-md border border-blue-200 text-center shadow-sm">
                <div class="hour-time text-sm font-semibold text-blue-600">
                  {DateTime.from_unix!(hour.time)
                  |> DateTime.to_time()
                  |> Time.to_string()
                  |> String.slice(0..4)}
                </div>
                <div class="hour-icon my-2">
                  <%= if hour.icon && hour.icon != "" do %>
                    <img
                      src={"https://openweathermap.org/img/wn/#{hour.icon}@2x.png"}
                      alt="weather icon"
                      class="w-12 h-12 mx-auto"
                    />
                  <% end %>
                </div>
                <div class="hour-temp text-3xl font-bold text-blue-800">
                  {round(hour.temperature)}°
                </div>
                <div class="hour-humidity text-xs text-blue-500 mt-1">
                  💧 {hour.humidity}%
                </div>
                <div class="hour-wind text-xs text-blue-500 mt-0.5">
                  💨 {hour.wind_speed} {hour.wind_speed_unit}
                </div>
              </div>
            <% end %>
          </div>
        </div>

    <!-- Pronóstico Semanal -->
        <div class="weather-section weekly-weather bg-white p-6 rounded-lg shadow-lg">
          <h3 class="text-xl font-bold text-blue-700 mb-4">📅 Resto de la semana</h3>
          <div class="weekly-list flex overflow-x-auto overflow-y-hidden pb-4 space-x-4">
            <%= for day <- Enum.take(@weather.weekly_weather, 7) do %>
              <div class="daily-item flex-shrink-0 w-40 bg-blue-50 p-4 rounded-md border border-blue-200 text-center shadow-sm">
                <div class="day-info mb-1">
                  <div class="day-name text-md font-bold text-blue-700">
                    {DateTime.from_unix!(day.date)
                    |> DateTime.to_date()
                    |> Date.day_of_week()
                    |> day_name()}
                  </div>
                  <div class="day-date text-xs text-blue-500">
                    {DateTime.from_unix!(day.date) |> DateTime.to_date() |> Calendar.strftime("%d/%m")}
                  </div>
                </div>

                <div class="day-icon my-2">
                  <%= if day.icon do %>
                    <img
                      src={"https://openweathermap.org/img/wn/#{day.icon}@2x.png"}
                      alt="weather icon"
                      class="w-16 h-16 mx-auto"
                    />
                  <% end %>
                </div>

                <div class="day-description text-sm text-blue-600 capitalize mb-1">
                  {day.description |> List.first() |> Map.get("description") |> String.capitalize()}
                </div>

                <div class="day-temps text-2xl font-bold text-blue-800 my-2">
                  <span class="temp-max">{round(day.temp_max || day.temperature)}°</span>
                  <span class="temp-separator text-blue-400 mx-1">/</span>
                  <span class="temp-min text-blue-600">
                    {round(day.temp_min || day.temperature)}°
                  </span>
                </div>

                <div class="day-details text-xs text-blue-500 mt-1">
                  <span class="day-humidity inline-block mr-2">💧 {day.humidity}%</span>
                  <span class="day-wind inline-block">💨 {day.wind_speed} {day.wind_speed_unit}</span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
      <%= if  !@weather && !@loading do %>
        <div class="no-weather bg-white p-8 rounded-lg shadow-lg text-center">
          <p class="text-lg text-gray-600">Selecciona una ciudad para ver el clima actual</p>
        </div>
      <% end %>
    </div>
    """
  end

  # Función auxiliar para convertir número de día a nombre
  defp day_name(day_number) do
    case day_number do
      1 -> "Lun"
      2 -> "Mar"
      3 -> "Mié"
      4 -> "Jue"
      5 -> "Vie"
      6 -> "Sáb"
      7 -> "Dom"
    end
  end
end
