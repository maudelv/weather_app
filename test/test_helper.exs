ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(WeatherApp.Repo, :manual)

Mox.defmock(WeatherApp.HTTPoisonMock, for: HTTPoison.Base)
