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
    <div class="favorite-cities shadow-lg p-4 mb-4 bg-white rounded">
  <h2>Ciudades favoritas</h2>

  <%= if Enum.empty?(@favorite_cities) do %>
    <div class="no-favorites">
      <p>No tienes ciudades favoritas aún.</p>
      <p>Busca una ciudad y agrégala a favoritos.</p>
    </div>
      <% else %>
        <div class="cities-list">
          <ul>
            <%= for favorite <- @favorite_cities do %>
              <li class="city-item mb-1">
                <div class="city-info mt-2 mb-2">
                  <span class="text-medium text-gray-700 mb-2"><%= favorite.name %>, <%= favorite.country_code %></span>
                  <hr />
                </div>
                <div class="city-actions d-flex">
                  <button
                    phx-click="get_weather"
                    phx-target={@myself}
                    phx-value-lat={favorite.lat}
                    phx-value-lon={favorite.lon}
                    class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white font-small p-1 px-3 pr-3 rounded-lg text-sm text-center inline-flex items-center dark:border-blue-500 dark:text-blue-500 dark:hover:text-white"
                  >
                    Ver Clima
                  </button>

                  <button
                    phx-click="remove_favorite_city"
                    phx-target={@myself}
                    phx-value-id={favorite.id}
                    class="text-red-700 border border-red-700 hover:bg-red-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-red-300 font-small p-2 rounded-lg text-sm text-center inline-flex items-center me-2 dark:border-red-500 dark:text-red-500 dark:hover:text-white dark:focus:ring-red-800 dark:hover:bg-red-500"
                    data-confirm="¿Estás seguro de eliminar esta ciudad de favoritos?"
                  >
                    <svg class="w-3 h-2.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 18 20">
                      <path d="M17 4h-4V2a2 2 0 0 0-2-2H7a2 2 0 0 0-2 2v2H1a1 1 0 0 0 0 2h1v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2-2V6h1a1 1 0 1 0 0-2ZM7 2h4v2H7V2Zm1 14a1 1 0 1 1-2 0V8a1 1 0 0 1 2 0v8Zm4 0a1 1 0 0 1-2 0V8a1 1 0 0 1 2 0v8Z"/>
                    </svg>
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
