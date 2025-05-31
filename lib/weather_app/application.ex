defmodule WeatherApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Dotenv.load(".env")
    children = [
      WeatherAppWeb.Telemetry,
      WeatherApp.Repo,
      {DNSCluster, query: Application.get_env(:weather_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WeatherApp.PubSub},
      # Start a worker by calling: WeatherApp.Worker.start_link(arg)
      # {WeatherApp.Worker, arg},
      # Start to serve requests, typically the last entry
      WeatherAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WeatherApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WeatherAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
