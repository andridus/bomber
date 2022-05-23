defmodule Bomber.Core.Schema.Block do
  import C4.View, only: [sigil_J: 2]
  @derive {Jason.Encoder, only: [:type, :format, :position, :item]}
  defstruct [:type, :position, :format, :item]

  def parse(b, {x, y}), do: __MODULE__.__struct__(type: from_type(b), format: b, position: {x, y}, item: Enum.take_random(available_items(), 1) |> List.first())

  def from_type("0"), do: :floor
  def from_type("1"), do: :wall
  def from_type("2"), do: :brick
  def from_type(x) when x in ["A","B"], do: :initial_player_position

  def available_items(), do: ["fire", "speed", "bomb", nil]

  def class_wall() do
    ~J"""
      class Wall extends Entity {
        constructor(game, x, y, grid) {
          super(game, x, y, grid, 0);
          this.body.moves = false;
          this.body.immovable = true;
          this.slack = 0.5;
          this.body.setSize(32 - this.slack, 32 - this.slack, this.slack * 0.5, this.slack * 0.5)
        }
        kill() {
          // cannot be killed
        }
      }
    """
  end

  def class_bricks() do
    ~J"""
      class Bricks extends Wall {
        constructor(game, x, y, grid, pickup) {
          super(game, x, y, grid);
          this.frame = 1;
          this.pickupClass = pickup;
        }

        kill() {
          const tween = this.game.add.tween(this).to({alpha: 0}, 300, Phaser.Easing.Linear.None, true);
          tween.onComplete.add(() => {
            this.destroy();
          }, this);

          this.dropPickup(this.pickupClass);
        }

        dropPickup(pickupClass) {
          if(pickupClass){
            const place = this.gridPos.clone();
            const screenPos = this.grid.gridToScreen(place.x, place.y);
            const pickup = new (pickupClass)(this.game, screenPos.x, screenPos.y, this.grid);
            this.parent.add(pickup, false, 0);
          }
        }
      }
    """
  end
end
