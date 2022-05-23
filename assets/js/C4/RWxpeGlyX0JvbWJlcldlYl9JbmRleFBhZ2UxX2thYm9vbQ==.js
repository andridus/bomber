/*
This file was generated automatically by the C4 compiler.
*/

const push = function(atom, module = "Elixir_BomberWeb_IndexPage1", id, payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"]["+id+"]["+atom+"]", payload)
}
const push_self = function(atom, id, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage1]["+id+"]["+atom+"]", payload)
}
const push_self_view = function(atom, payload) {
  liveSocket.getSocket().channels[0].push("port[Elixir_BomberWeb_IndexPage1][undefined]["+atom+"]", payload)
}
const push_view = function(atom, module = "Elixir_BomberWeb_IndexPage1", payload) {
  liveSocket.getSocket().channels[0].push("port["+module+"][undefined]["+atom+"]", payload)
}


export default function(e){
 const params = e.detail;
const k = kaboom({
    height: 390,
    width: 390,
    scale: 2,
    debug: true,
    font: "sinko",
    background: [ 0, 0, 0, 1],
    clearColor: [0,0,0,1],
    root: document.querySelector("#game"),
  });
  const MOVE_SPEED = 60;
  const ENEMY_SPEED = 60;

  loadRoot("/images/");

  loadSprite('block', 'block.png');
  loadSprite('brick1', 'brick1.png');
  loadSprite('brick2', 'brick2.png');
  loadSprite('brick3', 'brick3.png');
  loadSprite('ground', 'ground.png');
  loadSprite('bomber', 'bomber.png', {
    sliceX: 7,
    sliceY: 4,
    anims: {
      //stopped
      idleLeft: {from: 21, to: 21},
      idleRight: {from: 7, to: 7},
      idleUp: {from: 0, to: 0},
      idleDown: {from: 14, to: 14},

      //move
      moveLeft: {from: 22, to: 27, loop: true},
      moveRight: {from: 8, to: 13, loop: true},
      moveUp: {from: 0, to: 6, loop: true},
      moveDown: {from: 14, to: 20, loop: true}
    }
  });

  loadSprite('enemy1', 'enemy1.png', {sliceX: 3})
  loadSprite('enemy2', 'enemy2.png', {sliceX: 3})
  loadSprite('enemy3', 'enemy3.png', {sliceX: 3})
  loadSprite('bomb', 'bomb.png', {
    sliceX: 3, anims: { move: {from: 0, to: 2, loop: true} }
  })
  loadSprite('explosion', 'explosion.png', {
    sliceX: 5,
    sliceY: 5

  })

  scene('game', ({level, score}) => {
    layers(['bg', 'obj','ui'], 'obj');
    const maps = [
      [
        'aaaaaaaaaaaaaaa',
        'azzzz  *zzzzzda',
        'azazazazazazaza',
        'azzzzzzzzzzzzza',
        'azazazazazaza a',
        'azzzz* zzzzzz}a',
        'azazazazazaza a',
        'a zzzzzzzzzzz a',
        'a azazazazazaza',
        'a  zzzdzzzzzzza',
        'a azazazazazaza',
        'azzzzzzzzzzzzza',
        'azazazazazazaza',
        'azzzzz   &   za',
        'aaaaaaaaaaaaaaa',
      ]
    ];

    const a = _ => [area({scale: 0.8})]
    const levelCfg = {
      width: 26,
      height: 26,
      a: () => [sprite('block'), 'block', a(), solid(), 'wall'].flat(),
      z: () => [sprite('brick1'), 'brick1', a(), solid(), 'wall', 'brick'].flat(),
      d: () => [sprite('brick1'), 'brick1-door', a(), solid(), 'wall', 'brick'].flat(),
      w: () => [sprite('brick2'), 'brick2-door', a(), solid(), 'wall', 'brick'].flat(),
      p: () => [sprite('brick2'), 'brick2-door', a(), solid(), 'wall', 'brick'].flat(),
      b: () => [sprite('brick3'), 'brick3', a(), solid(), 'wall', 'brick'].flat(),
      t: () => [sprite('brick3'), 'brick3', a(), solid(), 'wall', 'brick'].flat(),
      '}': () => [sprite('enemy1'), 'enemy1', a(), solid(), 'dangerous', { dir: -1, timer: 0 }].flat(),
      '&': () => [sprite('enemy2'), 'enemy2', a(), solid(), { dir: -1 }, 'dangerous', { dir: -1, timer: 0 }].flat(),
      '*': () => [sprite('enemy3'), 'enemy3', a(), solid(), { dir: -1 }, 'dangerous', { dir: -1, timer: 0 }].flat(),
    }

    const gameLevel = addLevel(maps[0], levelCfg);



    add([sprite('ground'), layer('bg')]);

    const scoreLabel = add([
      text('Score: ' + score),
      pos(20,10),
      layer('ui'),
      {
        value: score
      },
      scale(1)
    ])

    onKeyDown('left', () =>{
      player.move(-MOVE_SPEED,0);
      player.dir = vec2(-1,0)
    });

    onKeyDown('right', () =>{
      player.move(MOVE_SPEED,0);
      player.dir = vec2(-1,0)
    })
    onKeyDown('up', () =>{
      player.move(0,-MOVE_SPEED);
      player.dir = vec2(-1,0)
    })
    onKeyDown('down', () =>{
      player.move(0,MOVE_SPEED);
      player.dir = vec2(-1,0)
    })
    onKeyPress('left', () =>{
      player.move(-MOVE_SPEED,0);
      player.play('moveLeft');
      player.dir = vec2(-1,0)
    });

    onKeyPress('right', () =>{
      player.play('moveRight');
    })
    onKeyPress('up', () =>{
      player.play('moveUp');
    })
    onKeyPress('down', () =>{
      player.play('moveDown');
    })

    onKeyPress('x', () =>{
      spawnBomb(player.pos.add(player.dir.scale(0.8)))
    })

    onKeyRelease('left', () =>{
      player.play('idleLeft')
    })
    onKeyRelease('right', () =>{
      player.play('idleRight')
    })
    onKeyRelease('up', () =>{
      player.play('idleUp')
    })
    onKeyRelease('down', () =>{
      player.play('idleDown')
    })

    const player = add([
      sprite('bomber',{
        animeSpeed: 0.1,
        frame: 14,
      }),
      health(3),
      pos(28,190),
      area({ width: 22, height: 22 , offset: vec2(-2, 5) }),
      solid(),
      z(10),
      scale(1.1),
      {dir: vec2(1,0)}
    ])
    player.action(() => {
     // player.pushOutAll();
    })

    //ACTIONS
    action('enemy1', (s) =>{
      s.move(s.dir * ENEMY_SPEED, 0);
      s.timer -= dt();
      if(s.timer <= 0) {
        s.dir = -s.dir;
        s.timer = rand(5);
      }
    })
    action('enemy2', (s) =>{
      s.move(s.dir * ENEMY_SPEED, 0);
      s.timer -= dt();
      if(s.timer <= 0) {
        s.dir = -s.dir;
        s.timer = rand(5);
      }
    })
    action('enemy3', (s) =>{
      s.move(s.dir * ENEMY_SPEED, 0);
      s.timer -= dt();
      if(s.timer <= 0) {
        s.dir = -s.dir;
        s.timer = rand(15);
      }

    })



    // FUNCTIONSvb

    function spawnBomb(p){
      const obj = add([
        sprite('bomb'),
        ('move'),
        area({ width: 20, height: 15 , offset: vec2(-3, 5) }),
        solid(),
        pos(p),
        z(1),
        scale(1.5),
        'bomb']);

      obj.play('move');
      wait(4, () => {
        destroy(obj);
        obj.dir = vec2(1,0);
        spawnExplosion(obj.pos.add(obj.dir.scale(0)), 12);

        obj.dir = vec2(0,-1);
        spawnExplosion(obj.pos.add(obj.dir.scale(20)), 2);

        obj.dir = vec2(0,1);
        spawnExplosion(obj.pos.add(obj.dir.scale(20)), 22);

        obj.dir = vec2(-1,0);
        spawnExplosion(obj.pos.add(obj.dir.scale(20)), 10);
        obj.dir = vec2(1,0);
        spawnExplosion(obj.pos.add(obj.dir.scale(20)), 14);
      })
    }
    /*onUpdate("bomb", (b) => {
      b.solid = b.pos.dist(player.pos) > 18    && b.pos.dist(player.pos) <= 64
    })*/

    function spawnExplosion(p, frame){
      const obj = add([sprite('explosion',{animeSpeed: 0.1, frame}),area({scale:0.8}),solid(), pos(p), scale(1.5),'boom']);
      wait(0.1, () => {
        destroy(obj);
      })
    }

    //collisions

    player.collides();

    collides('explosion', 'dangerous', (k, s) => {
      shake(4);
      wait(1, () =>{
        destroy(k)
      });
      destroy(s);
      scoreLabel.value++;
      scoreLabel.text = 'Score: ' + scoreLabel.value
    })

    collides('boom', 'brick', (k, s) => {
      addKaboom(k.pos);
      shake(4);
      wait(1, () =>{
        destroy(k)
      });
      destroy(s);
    })

    collides('boom', 'brick', (k,s) => {
      shake(4);
       wait(1, () => {
         destroy(k)
       })
       destroy(s);

    })
    collides('boom', 'brick-door', (k,s) => {
      shake(4);
      wait(1, () => {
        destroy(k);
      })
      destroy(s);
      gameLevel.spawn('t', s.gridPos.sub(0,0))
    })

    collides('enemy1', 'wall', (s) => {
      s.dir = -s.dir
    })
    collides('enemy2', 'wall', (s) => {
      s.dir = -s.dir
    })
    collides('enemy3', 'wall', (s) => {
      s.dir = -s.dir
    })
    player.onCollide('dangerous', () => {
      player.hurt(1)
    })

    player.onCollide('boom', () => {
     player.hurt(1)
    })

    player.on("death", () => {
      destroy(player)
      go('lose', {score: scoreLabel.value})
    })
    scene('lose', ( { score } ) => {
      add([text('Score: '+ score, 32), origin('center'), pos(width() / 2, height() / 2)])

      keyPress('space', () => {
        go('game', { level: 0, score: 0 });
      })
    })


  })
  go('game', {level: 0, score: 0});
}