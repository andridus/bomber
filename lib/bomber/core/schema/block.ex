defmodule Bomber.Core.Schema.Block do
  defstruct [:type, :position, :format, :item]



  def parse(b, {x, y}), do: __MODULE__.__struct__(type: from_type(b), format: b, position: {x, y})

  def from_type("0"), do: :floor
  def from_type("1"), do: :strong
  def from_type("2"), do: :soft
  def from_type(x) when x in ["A","B"], do: :initial_player_position
end
