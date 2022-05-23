/*
This file was generated automatically by the C4 compiler.
*/

const push = function(atom, module = "Elixir_BomberWeb_IndexPage", id, payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"]["+id+"]["+atom+"]", payload)
}
const push_self = function(atom, id, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage]["+id+"]["+atom+"]", payload)
}
const push_self_view = function(atom, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage][undefined]["+atom+"]", payload)
}
const push_view = function(atom, module = "Elixir_BomberWeb_IndexPage", payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"][undefined]["+atom+"]", payload)
}


export default function(e){
 const params = e.detail;
  const ME = params.session;
  const SCREEN_BLOCK = 32;
  const BLOCK_SIZE = 16;
  const [GRID_W, GRID_H] = params.stage.size;
  let PLAYERS = params.players;
  let CURRENT_OTHER_PLAYERS = [];
  let UPDATE_LEVEL_CALLBACK = [];


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

    class PickupBomb extends Pickup {
    constructor(game, x, y, grid) {
      super(game, x, y, grid, 8);
    }

    collect(player) {
      super.collect(player);
      player.totalBombs += 1;
    }
  }

    class PickupFire extends Pickup {
    constructor(game, x, y, grid) {
      super(game, x, y, grid, 9);
    }

    collect(player) {
      super.collect(player);
      player.bombSize += 1;
    }
  }

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

  class Bomb extends Entity {
  constructor(game, x, y, grid, owner) {
    super(game, x, y, grid, 2);

    this.owner = owner;
    this.depth=10;

    this.body.immovable = true;
    this.body.moves = false;

    if (this.owner) {
      this.owner.currentBombs += 1;
    }

    this.size = this.owner.bombSize || 3;

    this.duration = Phaser.Timer.SECOND * 3;
    this.explodeTimer = this.game.time.events.add(this.duration, this.explode, this);

    const tween1 = this.game.add.tween(this.scale).to({x: 1.1, y: 0.9}, this.duration / 9, Phaser.Easing.Circular.InOut, true, 0, -1);
    tween1.yoyo(true, 0);
    const tween2 = this.game.add.tween(this.anchor).to({y: 0.45}, this.duration / 9, Phaser.Easing.Circular.InOut, true, 0, -1);
    tween2.yoyo(true, 0);
  }

  explode() {
    this.game.time.events.remove(this.explodeTimer);
    if (this.owner) {
      this.owner.currentBombs -= 1;
    }
    this.grid.remove(this);

    const explosion = new Explosion(this.game, this.x, this.y, this.grid, this.owner, this.size, this.parent);

    this.destroy();
  }

  kill() {
    this.explode();
  }
}

  class Explosion extends Entity {
  constructor(game, x, y, grid, owner, size = 3, parent = null) {
    super(game, x, y, grid, 5);
    this.size = size;
    this.owner = owner;
    this.body.immovable = true;
    this.body.moves = false;


    this.game.camera.shake(0.0075, 500);

    this.duration = Phaser.Timer.SECOND * .5;
    this.decayTimer = this.game.time.events.add(this.duration, this.destroy, this);

    parent.add(this);

    this.locs = this.getExplosionLocations();
    this.doExplosion();
  }

  doExplosion() {
    this.blast = [];

    // Urgh. Improve plz.
    for (let i = 0; i < this.locs.left.length; i++) {
      const blastPos = this.grid.gridToScreen(this.locs.left[i].x, this.locs.left[i].y);
      const blast = new Blast(this.game, blastPos.x, blastPos.y, this.grid, this.owner);
      blast.angle = -90;
      if (i === this.size - 2) {
        blast.frame = 3;
      }
      this.blast.push(blast);
      this.parent.add(blast);
    }

    for (let i = 0; i < this.locs.right.length; i++) {
      const blastPos = this.grid.gridToScreen(this.locs.right[i].x, this.locs.right[i].y);
      const blast = new Blast(this.game, blastPos.x, blastPos.y, this.grid, this.owner);
      blast.angle = 90;
      if (i === this.size - 2) {
        blast.frame = 3;
      }
      this.blast.push(blast);
      this.parent.add(blast);
    }

    for (let i = 0; i < this.locs.up.length; i++) {
      const blastPos = this.grid.gridToScreen(this.locs.up[i].x, this.locs.up[i].y);
      const blast = new Blast(this.game, blastPos.x, blastPos.y, this.grid, this.owner);
      blast.angle = 0;
      if (i === this.size - 2) {
        blast.frame = 3;
      }
      this.blast.push(blast);
      this.parent.add(blast);
    }

    for (let i = 0; i < this.locs.down.length; i++) {
      const blastPos = this.grid.gridToScreen(this.locs.down[i].x, this.locs.down[i].y);
      const blast = new Blast(this.game, blastPos.x, blastPos.y, this.grid, this.owner);
      blast.angle = 180;
      if (i === this.size - 2) {
        blast.frame = 3;
      }
      this.blast.push(blast);
      this.parent.add(blast);
    }
  }

  getExplosionLocations() {
    const x = this.gridPos.x;
    const y = this.gridPos.y;
    const points = {
      left: [],
      right: [],
      up: [],
      down: []
    };
    const obstructed = {
      left: false,
      right: false,
      up: false,
      down: false
    }

    // Jesus, these explosion routines... gotta fix these :(
    for (let w = 1; w < this.size; w++) {
      let entity;
      if (!obstructed.right) {
        entity = this.grid.getAt(x + w, y);
        if (!entity || entity.blastThrough) {
          points.right.push(new Phaser.Point(x + w, y));
        }
        else {
          obstructed.right = true;
          if (entity && entity instanceof Entity) {
            entity.kill();
          }
        }
      }

      if (!obstructed.left) {
        entity = this.grid.getAt(x - w, y);
        if (!entity || entity.blastThrough) {
          points.left.push(new Phaser.Point(x - w, y));
        }
        else {
          obstructed.left = true;
          if (entity && entity instanceof Entity) {
            entity.kill();
          }
        }
      }

      if (!obstructed.down) {
        entity = this.grid.getAt(x, y + w);
        if (!entity || entity.blastThrough) {
          points.down.push(new Phaser.Point(x, y + w));
        }
        else {
          obstructed.down = true;
          if (entity && entity instanceof Entity) {
            entity.kill();
          }
        }
      }

      if (!obstructed.up) {
        entity = this.grid.getAt(x, y - w);
        if (!entity || entity.blastThrough) {
          points.up.push(new Phaser.Point(x, y - w));
        }
        else {
          obstructed.up = true;
          if (entity && entity instanceof Entity) {
            entity.kill();
          }
        }
      }
    }
    return points;
  }

  destroy() {
    this.game.time.events.remove(this.decayTimer);
    for (let i = 0; i < this.blast.length; i++) {
      this.blast[i].destroy();
    }
    const tween = this.game.add.tween(this).to({alpha: 0}, 300, Phaser.Easing.Linear.None, true);
    tween.onComplete.add(() => {
      super.destroy();
    }, this);
  }

  kill() {
    // cannot be killed
  }
}

    class Blast extends Entity {
    constructor(game, x, y, grid, owner) {
      super(game, x, y, grid, 4);
      this.body.moves = false;
      this.body.immovable = true;
      this.slack = 18;
      this.body.setSize(32 - this.slack, 32 - this.slack, this.slack * 0.5, this.slack * 0.5)

      this.blastThrough = true;
    }

    kill() {
      // cannot be killed
    }

    destroy() {
      this.body.enable = false;
      const tween = this.game.add.tween(this).to({alpha: 0}, 300, Phaser.Easing.Linear.None, true);
      tween.onComplete.add(() => {
        super.destroy();
      }, this);
    }
  }


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


  class Game extends Phaser.Game {
    constructor() {
      super(GRID_W*SCREEN_BLOCK,GRID_H*SCREEN_BLOCK, Phaser.AUTO, 'game', null);
      this.state.add('Level', Level, false);
      this.state.start('Level');
    };
  };

  const game = new Game();

  setTimeout(function(){
    const level = game.state.states.Level;
    PLAYERS.forEach(function(player){
      if(player.associated == ME){
        const p = new Player(player, level, level.grid);
        level.items.add(p);
        console.log("CREATE PLAYER", ME)
        UPDATE_LEVEL_CALLBACK.push(function(self){
          game.physics.arcade.collide(p, level.items, (a, b) => {
            if (a instanceof Player && (b instanceof Blast || b instanceof Explosion)) {
              a.kill();
            }
          });
        });
      }else{
        const other = new OtherPlayer(player, level, level.grid);
        console.log("CREATE OTHER", player.associated)
        level.items.add(other, 3);
        UPDATE_LEVEL_CALLBACK.push(function(self){
          game.physics.arcade.collide(other, level.items, (a, b) => {
            if (a instanceof OtherPlayer && (b instanceof Blast || b instanceof Explosion)) {
              a.kill();
            }
          });
        });
        CURRENT_OTHER_PLAYERS.push(other)
      }
    })
  }, 500)

  window.addEventListener(`phx:update_player`, function({detail: payload}){
    CURRENT_OTHER_PLAYERS.forEach(function(p){
      if(p.id == payload.player_id){
        p.x = payload.player_x;
        p.y = payload.player_y;
      }
    })
  });

  window.addEventListener(`phx:drop_bomb`, function({detail: payload}){
    const level = game.state.states.Level;
    const other = CURRENT_OTHER_PLAYERS.filter(p => p.id == payload.player_id);
    if(other){
      const bomb = new Bomb(level.game, payload.bomb_pos_x, payload.bomb_pos_y, level.grid, other);
      level.items.add(bomb);
    }
  });
}