defmodule WeatherAppWeb.WeatherLive.Components.FavoriteCitiesComponent do
  use WeatherAppWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("get_weather", %{"lat" => lat, "lon" => lon}, socket) do
    send(self(), {:weather_requested, %{"lat" => lat, "lon" => lon}})
    {:noreply, socket}
  end

  def handle_event("remove_favorite_city", %{"id" => id}, socket) do
    send(self(), {:favorite_removed, %{"id" => id}})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="favorite-cities shadow-lg p-6 mb-6 bg-white rounded-lg">
      <div class="flex justify-between items-center mb-4">
        <h2 class="block text-md font-medium text-gray-700">Ciudades favoritas</h2>
        <span class="text-sm text-gray-500">(<%= length(@favorite_cities) %>/5)</span>
      </div>

      <%= if Enum.empty?(@favorite_cities) do %>
        <div class="no-favorites text-center py-6 px-4 bg-blue-50 rounded-md border border-blue-200">
          <p class="text-md text-blue-700 mb-1">No tienes ciudades favoritas aún.</p>
          <p class="text-sm text-blue-600">Busca una ciudad y agrégala a favoritos.</p>
        </div>
      <% else %>
        <div class="cities-list">
          <ul class="space-y-3">
            <%= for favorite <- @favorite_cities do %>
              <li class="city-item p-4 bg-blue-50 border border-blue-200 rounded-md shadow-sm">
                <div class="city-info flex justify-between items-center mb-2">
                  <span class="text-md font-semibold text-blue-800"><%= favorite.name %>, <%= favorite.country_code %></span>
                </div>
                <div class="city-actions flex space-x-2">
                  <button
                    phx-click="get_weather"
                    phx-target={@myself}
                    phx-value-lat={favorite.lat}
                    phx-value-lon={favorite.lon}
                    class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-xs px-4 py-2 text-center dark:border-blue-500 dark:text-blue-500 dark:hover:text-white dark:focus:ring-blue-800 dark:hover:bg-blue-500"
                  >
                    Ver Clima
                  </button>

                  <button
                    phx-click="remove_favorite_city"
                    phx-target={@myself}
                    phx-value-id={favorite.id}
                    class="text-red-700 border border-red-700 hover:bg-red-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-red-300 font-medium p-2 rounded-lg text-xs text-center inline-flex items-center dark:border-red-500 dark:text-red-500 dark:hover:text-white dark:focus:ring-red-800 dark:hover:bg-red-500"
                    data-confirm="¿Estás seguro de eliminar esta ciudad de favoritos?"
                    title="Eliminar de favoritos"
                  >
                    <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 18 20">
                      <path d="M17 4h-4V2a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v2H1a1 1 0 0 0 0 2h1v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V6h1a1 1 0 1 0 0-2ZM7 2h4v2H7V2Zm1 14a1 1 0 1 1-2 0V8a1 1 0 0 1 2 0v8Zm4 0a1 1 0 0 1-2 0V8a1 1 0 0 1 2 0v8Z"/>
                    </svg>
                    <span class="sr-only">Eliminar de favoritos</span>
                  </button>
                </div>
              </li>
            <% end %>
          </ul>
        </div>
      <% end %>
    </div>
    """
  end
end
