defmodule BomberWeb.Js do
  import  C4.View, only: [sigil_J: 2]

  def entity() do
    ~J"""
      class Entity extends Phaser.Sprite {
        constructor(game, x, y, grid, index = 0) {
          super(game, x, y, 'sprites', index);
          this.anchor.setTo(.5);
          this.game.physics.arcade.enable(this);
          this.grid = grid;
          this.grid.add(this);
          if (this.gridPos) {
            this.grid.screenToGrid(this.x, this.y, this.gridPos);
          }
        }
        destroy() {
          this.grid.remove(this);
          super.destroy();
        }

        kill() {
          super.kill();
        }
      }
    """
  end

end
