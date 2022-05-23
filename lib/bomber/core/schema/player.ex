defmodule Bomber.Core.Schema.Player do
  import C4.View, only: [sigil_J: 2]

  @derive {Jason.Encoder, only: [:name, :me,  :associated, :score, :id, :properties, :position]}
  defstruct [:name, :score, :items,
    id: "",
    me: false,
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

  def class_player() do
    ~J"""
      class Player extends Entity {
        constructor(p, game,grid) {

          const [posx, posy] =  p.position;
          super(game, posx*SCREEN_BLOCK, posy*SCREEN_BLOCK, grid, 6);
          this.id = p.associated;
          this.controls = this.game.input.keyboard.createCursorKeys();
          this.speed = 96;
          this.z = -1;
          this.depth=11;

          this.totalBombs = 1;
          this.currentBombs = 0;
          this.bombSize = 3;

          this.body.setCircle(16);
          this.body.drag.set(768);

          this.lastGridPos = this.gridPos.clone();
          this.me = p.me;
          this.blastThrough = true;
        }

        update_position(){
          push_self_view("update_state", {
            event: "update_player",
            player_id: this.id,
            player_x: this.x,
            player_y: this.y
          });
          //push_self_view("update_player", {id: this.id, x: this.x, y: this.y});
        }

        update() {
          super.update();

          if (!this.alive) {
            return;
          }
          if (this.controls.up.isDown) {
            this.body.velocity.y = this.speed * -1;
            this.update_position()
          }
          else if (this.controls.down.isDown) {
            this.body.velocity.y = this.speed;
            this.update_position()
          }

          if (this.controls.left.isDown) {
            this.body.velocity.x = this.speed * -1;
            this.update_position()
          }
          else if (this.controls.right.isDown) {
            this.body.velocity.x = this.speed;
            this.update_position()
          }

          if (this.game.input.keyboard.justPressed(Phaser.Keyboard.X)) {
            this.dropBomb();

          }
          if (this.gridPos) {
            this.grid.screenToGrid(this.x, this.y, this.gridPos);
          }

          if (!this.gridPos.equals(this.lastGridPos)) {
            this.lastGridPos.copyFrom(this.gridPos);
            this.checkGrid();
          }
        }

        kill() {
          this.body.moves = false;
          super.kill();
        }

        canPlaceBomb(place) {
          const item = this.grid.getAt(place.x, place.y, this);
          if (!item) {
            return true;
          }
          return false;
        }

        dropBomb() {
          const place = this.gridPos.clone();
          const screenPos = this.grid.gridToScreen(place.x, place.y);
          if (this.currentBombs < this.totalBombs && this.canPlaceBomb(place)) {
            const bomb = new Bomb(this.game, screenPos.x, screenPos.y, this.grid, this);
            this.parent.add(bomb,false,0);
            push_self_view("update_state", {
              event: "drop_bomb",
              player_id: this.id,
              bomb_pos_x: screenPos.x,
              bomb_pos_y: screenPos.y
              });
          }
        }

        checkGrid() {
          const item = this.grid.getAt(this.gridPos.x, this.gridPos.y, this);
          if (item && item instanceof Pickup) {
            item.collect(this);
          }
        }
      }
    """
  end

  def class_other_player() do
    ~J"""
      class OtherPlayer extends Entity {
        constructor(p, game,grid) {

          const [posx, posy] =  p.position;
          super(game, posx*SCREEN_BLOCK, posy*SCREEN_BLOCK, grid, 6);
          this.id = p.associated;
          this.controls = this.game.input.keyboard.createCursorKeys();
          this.speed = 96;

          this.totalBombs = 1;
          this.currentBombs = 0;
          this.bombSize = 3;

          this.body.setCircle(16);
          this.body.drag.set(768);

          this.lastGridPos = this.gridPos.clone();
          this.me = p.me;
          this.blastThrough = true;
        }
        update() {
          super.update();

          if (!this.gridPos.equals(this.lastGridPos)) {
            this.lastGridPos.copyFrom(this.gridPos);
            this.checkGrid();
          }
          if (this.gridPos) {
            this.grid.screenToGrid(this.x, this.y, this.gridPos);
          }
        }
        kill() {
          this.body.moves = false;
          super.kill();
        }
        checkGrid() {
          const item = this.grid.getAt(this.gridPos.x, this.gridPos.y, this);

          if (item && item instanceof Pickup) {
            item.collect(this);
          }
        }
      }
    """
  end
end
