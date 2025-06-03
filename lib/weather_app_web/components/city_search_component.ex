defmodule WeatherAppWeb.WeatherLive.Components.CitySearchComponent do
  use WeatherAppWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("search_cities", params, socket) do
    query = extract_query(params)
    send(self(), {:cities_searched, %{"query" => query}})
    {:noreply, socket}
  end

  def handle_event("get_weather", %{"lat" => lat, "lon" => lon}, socket) do
    send(self(), {:weather_requested, %{"lat" => lat, "lon" => lon}})
    {:noreply, socket}
  end

  def handle_event("add_favorite_city", params, socket) do
    send(self(), {:favorite_added, params})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
      <div class="city-search col-span-3 shadow-lg p-6 mb-6 bg-white rounded-lg">
        <div class="search-header flex justify-between items-center mb-4">
          <h2 class="text-xl font-bold text-blue-700">Buscar ciudad</h2>
        </div>
        <div class="search-form">
          <form phx-submit="search_cities" phx-target={@myself} class="space-y-4">
            <div>
              <label for="city_search_input" class="sr-only">Introduce el nombre de la ciudad</label>
              <input
                id="city_search_input"
                class="block w-full p-3 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 text-sm text-gray-900 placeholder-gray-500"
                type="text"
                name="value"
                phx-debounce="300"
                phx-keyup="search_cities"
                phx-target={@myself}
                placeholder="Introduce el nombre de la ciudad"
                required
              />
            </div>
            <button type="submit" class="w-full text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 font-medium rounded-lg text-sm px-5 py-2.5 dark:bg-blue-600 dark:hover:bg-blue-700 focus:outline-none dark:focus:ring-blue-800">Buscar</button>
          </form>
        </div>

        <%= if @error do %>
          <p class="error mt-4 p-3 text-sm text-red-700 bg-red-100 border border-red-300 rounded-md"><%= @error %></p>
        <% end %>

        <%= if @loading do %>
          <div class="mt-6 loading-spinner flex items-center justify-center py-4 bg-blue-50 border border-blue-200 rounded-md">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mr-2"></div>
          </div>
        <% end %>

        <%= if not Enum.empty?(@cities) && !@loading do %>
          <div class="cities-list mt-6">
            <ul class="space-y-3">
              <%= for city <- @cities do %>
                <li class="city-item p-4 bg-blue-50 border border-blue-200 rounded-md shadow-sm">
                  <div class="city-info flex justify-between items-center mb-2">
                      <span class="text-md font-semibold text-blue-800"><%= city["name"] %>, <%= city["country"] %></span>
                  </div>
                  <div class="city-actions flex space-x-2">
                      <button
                      phx-click="get_weather"
                      phx-target={@myself}
                      phx-value-lat={city["lat"]}
                      phx-value-lon={city["lon"]}
                      class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium rounded-lg text-xs px-4 py-2 text-center dark:border-blue-500 dark:text-blue-500 dark:hover:text-white dark:focus:ring-blue-800 dark:hover:bg-blue-500"
                    >
                      Ver Clima
                    </button>

                    <button
                      phx-click="add_favorite_city"
                      phx-target={@myself}
                      phx-value-country_code={city["country"]}
                      phx-value-state={city["state"]}
                      phx-value-name={city["name"]}
                      phx-value-lat={city["lat"]}
                      phx-value-lon={city["lon"]}
                      class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-blue-300 font-medium p-2 rounded-lg text-xs text-center inline-flex items-center dark:border-blue-500 dark:text-blue-500 dark:hover:text-white dark:focus:ring-blue-800 dark:hover:bg-blue-500"
                      title="Añadir a favoritos"
                    >
                    <svg class="w-4 h-4" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 18 18">
                      <path d="M3 7H1a1 1 0 0 0-1 1v8a2 2 0 0 0 4 0V8a1 1 0 0 0-1-1Zm12.954 0H12l1.558-4.5a1.778 1.778 0 0 0-3.331-1.06A24.859 24.859 0 0 1 6 6.8v9.586h.114C8.223 16.969 11.015 18 13.6 18c1.4 0 1.592-.526 1.88-1.317l2.354-7A2 2 0 0 0 15.954 7Z"/>
                    </svg>
                    <span class="sr-only">Añadir a favoritos</span>
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

  defp extract_query(params) do
    (case params do
       %{"value" => q} -> q
       %{"query" => q} -> q
       _ -> ""
     end)
    |> String.trim()
  end
end
