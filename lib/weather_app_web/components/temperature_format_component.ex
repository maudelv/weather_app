defmodule WeatherAppWeb.WeatherLive.Components.TemperatureFormatComponent do
  use WeatherAppWeb, :live_component

  @impl true
  def update(assigns, socket) do
    {:ok, assign(socket, assigns)}
  end

  @impl true
  def handle_event("change_temperature_format", %{"format" => format}, socket) do
    send(self(), {:temperature_format_changed, %{"format" => format}})
    {:noreply, socket}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="temperature-format-selector shadow-lg p-4 mb-6 bg-white rounded-lg">
      <form phx-change="change_temperature_format" phx-target={@myself}>
        <div class="form-group">
          <label for="temperature_format" class="block text-sm font-medium text-gray-700 mb-1 sm:mb-0">Formato de temperatura:</label>
          <select
            id="temperature_format"
            name="format"
            value={@temperature_format}
            class="block w-full border border-gray-300 text-gray-900 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 shadow-sm"
          >
            <option value="celsius" selected={@temperature_format == "celsius"}>
              Celsius (°C)
            </option>
            <option value="fahrenheit" selected={@temperature_format == "fahrenheit"}>
              Fahrenheit (°F)
            </option>
            <option value="kelvin" selected={@temperature_format == "kelvin"}>
              Kelvin (K)
            </option>
          </select>
        </div>
      </form>
    </div>
    """
  end
end
