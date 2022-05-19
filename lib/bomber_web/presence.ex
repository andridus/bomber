defmodule BomberWeb.Presence do
  use Phoenix.Presence, otp_app: :bomber, pubsub_server: Bomber.PubSub
end
