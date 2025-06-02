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
    <div class="city-search col-span-3 shadow-lg p-4 mb-4 bg-white rounded">
      <div class="search-header d-flex justify-content-between">
        <h2 class="text-lg">Buscar ciudad</h2>
      </div>
      <div class="search-form">
        <form phx-submit="search_cities" phx-target={@myself}>
          <input
            class="text-sm font-medium text-gray-900 light:text-white rounded"
            type="text"
            name="value"
            phx-debounce="300"
            phx-keyup="search_cities"
            phx-target={@myself}
            placeholder="Introduce el nombre de la ciudad"
            required
          />
          <button type="submit" class="mt-3 text-white bg-blue-700 hover:bg-blue-800 font-medium rounded-lg text-sm px-5 py-2.5 me-2 mb-2 dark:bg-blue-600 dark:hover:bg-blue-700">Buscar</button>
        </form>
      </div>

      <%= if @error do %>
        <p class="error"><%= @error %></p>
      <% end %>

      <%= if not Enum.empty?(@cities) do %>
        <div class="cities-list">
          <ul>
            <%= for city <- @cities do %>
              <li class="city-item mb-1">
                <div class="city-info mt-2 mb-2">
                    <span class="text-medium text-gray-700 mb-2"><%= city["name"] %>, <%= city["country"] %></span>
                <hr />
                </div>
                <div class="city-actions d-flex">
                    <button
                    phx-click="get_weather"
                    phx-target={@myself}
                    phx-value-lat={city["lat"]}
                    phx-value-lon={city["lon"]}
                    class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white font-small p-1 px-3 pr-3 rounded-lg text-sm text-center inline-flex items-center dark:border-blue-500 dark:text-blue-500 dark:hover:text-white"
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
                    class="text-blue-700 border border-blue-700 hover:bg-blue-700 hover:text-white focus:ring-4 focus:outline-none focus:ring-blue-300 font-small p-2 rounded-lg text-sm text-center inline-flex items-center me-2 dark:border-blue-500 dark:text-blue-500 dark:hover:text-white dark:focus:ring-blue-800 dark:hover:bg-blue-500"
                  >
                  <svg class="w-3 h-2.5" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="currentColor" viewBox="0 0 18 18">
                    <path d="M3 7H1a1 1 0 0 0-1 1v8a2 2 0 0 0 4 0V8a1 1 0 0 0-1-1Zm12.954 0H12l1.558-4.5a1.778 1.778 0 0 0-3.331-1.06A24.859 24.859 0 0 1 6 6.8v9.586h.114C8.223 16.969 11.015 18 13.6 18c1.4 0 1.592-.526 1.88-1.317l2.354-7A2 2 0 0 0 15.954 7Z"/>
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

  defp extract_query(params) do
    (case params do
       %{"value" => q} -> q
       %{"query" => q} -> q
       _ -> ""
     end)
    |> String.trim()
  end
end
