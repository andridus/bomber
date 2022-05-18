defmodule Bomber.StageContext do

  alias Bomber.Core.Schema.{Block,  Stage, Player}

  def generate_stage() do
    Stage.stage_raw_1()
    |> Stage.make()
    |> parse_blocks()
    |> parse_players()
  end


  defp parse_blocks(stage) do
    blocks =
      stage.map
      |> Enum.with_index()
      |> Enum.map(fn {row, x} ->
        row
        |> Enum.with_index()
        |> Enum.map(fn {block, y} ->
          Block.parse(block, {x, y})
        end)
      end)
      |> List.flatten()

    %{stage | blocks: blocks}
  end

  defp parse_players(stage) do
    players =
      stage.blocks
      |> Enum.filter(&(&1.type == :initial_player_position))
      |> Enum.map(&Player.parse(&1.format, &1.position))

    %{stage | players: players}
  end
end
