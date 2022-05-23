defmodule Bomber.Core.Schema.Stage do
  import C4.View, only: [sigil_J: 2]
  @derive {Jason.Encoder, only: [:items, :blocks, :total_blocks, :available_slots, :size,  :map, :players]}
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
      111111111111111
      1A0000120000001
      101010101010101
      100000200000001
      101010101010101
      100000020000001
      101010101010101
      100002010000001
      101010121010101
      100000002000001
      101210101010101
      100200000000001
      101010101010101
      1000002100000B1
      111111111111111
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


  def class_grid() do
    ~J"""
    class Grid {
      constructor(width, height, size = 32) {
        this.width = width;
        this.height = height;
        this.size = size;
        this.items = [];
      }

      add(item) {
        this.items.push(item);
        item.gridPos = this.screenToGrid(item.x, item.y);
      }

      remove(item) {
        if (this.items.indexOf(item) !== -1) {
          this.items.splice(this.items.indexOf(item), 1);
        }
      }

      getAt(x, y, ignore) {
        if (x >= 0 && x < this.width && y >= 0 && y < this.height) {
          for (let i = 0; i < this.items.length; i++) {
            let item = this.items[i];
            if (item !== ignore && item.gridPos.x === x && item.gridPos.y === y) {
              return item;
            }
          }
          return null;
        }
        return -1;
      }

      screenToGrid(x, y, point) {
        if (point) {
          point.x = Math.round(x / this.size);
          point.y = Math.round(y / this.size);
          return point;
        }
        return new Phaser.Point(Math.round(x / this.size), Math.round(y / this.size));
      }

      gridToScreen(x, y, point) {
        if (point) {
          point.x = x * this.size;
          point.y = y * this.size;
          return point;
        }
        return new Phaser.Point(x * this.size, y * this.size);
      }
    }
    """
  end

  def class_level() do
    ~J"""
    class Level extends Phaser.State {
      preload() {
        this.stage.disableVisibilityChange = true;
        this.game.load.spritesheet('sprites', '/images/cbimage1.png', SCREEN_BLOCK, SCREEN_BLOCK);
      }

      create() {

        const self = this;
        this.game.renderer.renderSession.roundPixels = true;
        this.game.physics.startSystem(Phaser.Physics.ARCADE);
        this.game.input.keyboard.addKeyCapture([
            Phaser.Keyboard.UP,
            Phaser.Keyboard.DOWN,
            Phaser.Keyboard.LEFT,
            Phaser.Keyboard.RIGHT,
            Phaser.Keyboard.X
            ]);

        this.grid = new Grid(GRID_W, GRID_H);


        this.background = this.game.add.group();
        this.items = this.game.add.physicsGroup();
        this.items.x = this.background.x = BLOCK_SIZE;
        this.items.y = this.background.y = BLOCK_SIZE;
        params.stage.blocks.forEach(function(b){
          const [x,y] = b.position;
          self.background.create((x * self.grid.size), (y * self.grid.size), 'sprites', 7).anchor.set(.5);
          switch(b.type){
            case "brick":
              let pickupClass = null;
              switch(b.item){
                case "bomb":
                 pickupClass = PickupBomb;
                 break;
                case "fire":
                 pickupClass = PickupFire;
                 break;
                case "speed":
                 pickupClass = PickupSpeed;
                 break;
              }
              const bricks = new Bricks(self.game, x * self.grid.size, y * self.grid.size, self.grid, pickupClass);
              self.items.add(bricks,false, 0);
              break;
            case "wall":
              const wall = new Wall(self.game, x * self.grid.size, y * self.grid.size, self.grid);
              self.items.add(wall,false, 0);
              break;
            default:
              null;
          }
        })
      };

      update() {
        UPDATE_LEVEL_CALLBACK.forEach(f => typeof f == "function" ? f(this) : null)
      };

      render() {};
    };
    """
  end


end
