defmodule Bomber.Core.Schema.Bomb do
  import C4.View, only: [sigil_J: 2]

  def class_bomb() do
    ~J"""
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
    """
  end
  def class_explosion() do
    ~J"""
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
    """
  end
  def class_blast() do
    ~J"""
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

    """
  end
end
