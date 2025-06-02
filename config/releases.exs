import Config

config :weather_app, WeatherAppWeb.Endpoint,
  url: [host: System.get_env("PHX_HOST") || "localhost", port: System.get_env("PORT") || 4000],
  secret_key_base: System.get_env("SECRET_KEY_BASE")

config :weather_app, WeatherApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# It is important to disable the server here, as it will be started
# by the application supervisor.
config :weather_app, WeatherAppWeb.Endpoint, server: false

# Do not print debug messages in production
config :logger, level: :info
