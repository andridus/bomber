defmodule Bomber.PlayerContext do

  def move(_stage, %{ position: {px, py} } = player, :up) when px > 0 , do: %{player | position: {px - 1, py}}
  def move(%{size: {x, _y}}, %{ position: {px, py } } = player, :down) when px < x - 1, do: %{player | position: {px + 1, py}}
  def move(_stage, %{ position: {px, py} } = player, :left) when py > 0, do: %{player | position: {px , py - 1}}
  def move(%{size: {_x, y}}, %{ position: {px, py } } = player, :right) when py < y - 1, do: %{player | position: {px, py + 1}}
  def move(_,player, _), do: player
end
