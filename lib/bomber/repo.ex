defmodule Bomber.Repo do
  use Ecto.Repo,
    otp_app: :bomber,
    adapter: Ecto.Adapters.Postgres
end
