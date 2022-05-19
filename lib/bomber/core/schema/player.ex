defmodule Bomber.Core.Schema.Player do
  @derive {Jason.Encoder, only: [:name, :associated, :score, :id, :properties]}
  defstruct [:name, :score, :items,
    id: "",
    associated: nil,
    position: {0,0},
    properties: %{
      speed: 1,
      bombs: 1,
      bomb_type: :basic, #[:basic, :clock, :mine, power]
      firepower: 1,
      hearth: 1
    }]

  def parse(p, {x, y}), do: __MODULE__.__struct__(id: p, position: {x, y})
end
