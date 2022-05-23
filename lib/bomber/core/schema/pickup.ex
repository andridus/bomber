defmodule Bomber.Core.Schema.Pickup do
  import C4.View, only: [sigil_J: 2]

  def class_pickup() do
    ~J"""
      class Pickup extends Entity {
        constructor(game, x, y, grid, index) {
          if (new.target === Pickup) {
            throw new TypeError("Cannot construct Abstract instances directly");
          }
          super(game, x, y, grid, index);
          this.body.enable = false;
          this.body.moves = false;
        }

        collect(player) {
          this.destroy();
        }
      }
    """
  end

  def class_pickup_bomb() do
    ~J"""
      class PickupBomb extends Pickup {
        constructor(game, x, y, grid) {
          super(game, x, y, grid, 8);
        }

        collect(player) {
          super.collect(player);
          player.totalBombs += 1;
        }
      }
    """
  end

  def class_pickup_fire() do
    ~J"""
      class PickupFire extends Pickup {
        constructor(game, x, y, grid) {
          super(game, x, y, grid, 9);
        }

        collect(player) {
          super.collect(player);
          player.bombSize += 1;
        }
      }
    """
  end

  def class_pickup_speed() do
    ~J"""
      class PickupSpeed extends Pickup {
        constructor(game, x, y, grid) {
          super(game, x, y, grid, 10);
        }

        collect(player) {
          super.collect(player);
          if(player.speed <= 196){
            player.speed += 8 ;
          }
        }
      }
    """
  end
end
