defmodule Bomber.Core.Schema.Stage do
  defstruct [
    map: [],
    size: {0,0},
    items: 0,
    available_items: [
      fire: 2,
      speed: 2
    ],
    total_blocks: 0,
    available_slots: 0, #not implemented (random scenario)

    blocks: [],
    players: [],
    events: [],
  ]

  def stage_raw_1() do
    """
      A000012000000
      0101010101010
      0000020000000
      0101010101010
      0000002000000
      0101010101010
      0000201000000
      0101012101010
      0000000200000
      0121010101010
      0020000000000
      0101010101010
      000002100000B
    """
  end

  def parse_from_string(str) do
    str
    |> String.trim()
    |> String.split("\n")
    |> Enum.map(&(String.trim(&1) |> String.codepoints()))
  end
  def apply_size(stage, parsed) do
    blocks_x = parsed |> List.first() |> Enum.count()
    blocks_y = parsed |> Enum.count()
    %{stage | size: {blocks_x, blocks_y}}
  end

  def apply_total_blocks(stage) do
    {x,y} = stage.size
    %{stage | total_blocks: x*y}
  end
  def make(str) do
    parsed = parse_from_string(str)
    __MODULE__.__struct__(map: parsed)
    |> apply_size(parsed)
    |> apply_total_blocks()
  end

end
