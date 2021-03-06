defmodule BomberWeb.GamePage do

  use C4.View
  import Surface, only: [sigil_F: 2]

  alias BomberWeb.Presence
  alias Phoenix.PubSub

  @topic "bomber"

  field :session_id, :string, default: nil
  field :game, :string, default: nil
  field :stage, :map, default: nil
  field :players, :map, default: nil
  field :users, {:array, :map}, default: []
  field :creator, :boolean, default: false
  field :started, :boolean, default: false
  field :running, :boolean, default: false

  event :on_init
  event :join
  event :update_state
  event :enter_game
  event :delivery_all_state

  effect :on_init

  command :cmd_presence

  def topic_name(game) do
    "#{@topic}-#{game}"
  end
  def topic_name(game, user) do
    "#{@topic}-#{game}-#{user}"
  end
  def on_init(state, _) do
    stage = Bomber.StageContext.generate_stage()
    players = stage.players
    session_id = state.__session__["_csrf_token"]
    creator = if state.__path__.path_params["server"] == "true", do: true, else: false
    game = state.__path__.path_params["game"]
    { %{state | game: game, creator: creator, stage: stage, players: players, session_id: session_id }, :cmd_presence}
  end

  def join(state, _) do
    state = %{state | started:  true}
    Enum.each(state.users, fn u ->
        PubSub.broadcast(Bomber.PubSub, topic_name(state.game, u.user_id), {:enter_game, state})
    end)
    state
  end

  def enter_game(state, params) do
    state = %{state | players: params.players, stage: params.stage}
    {%{state | running: true }, {:javascript, {:start, [state.session_id, state.stage, state.players]}}}
  end
  def update_state(state, params) do
    Enum.each(state.users, fn u ->
      if u.user_id != params["player_id"] do
        Phoenix.PubSub.broadcast(Bomber.PubSub, topic_name(state.game, u.user_id), {:delivery_state, {params["event"], params}})
      end
    end)
    state
  end

  def cmd_presence(socket) do
    session_id = socket.assigns.__session__["_csrf_token"]
    game = socket.assigns.__params__["game"]


    BomberWeb.Endpoint.subscribe(topic_name(game))
    BomberWeb.Endpoint.subscribe(topic_name(game, session_id))
    Presence.track(self(), topic_name(game), session_id , %{ online_at: inspect(System.system_time(:second))})

    socket
  end

  def delivery_all_state(state, params) do
    %{state | stage: params.stage}
  end


  def handle_info({:delivery_state, {event, params}}, socket) do
    {:noreply, socket |> push_event(event, params)}
  end
  def handle_info({:delivery, {state, args}}, socket) do
    {:noreply,
      socket
      |> assign(:players, state.players)
      |> push_event("join_players", %{players: state.players})
      |> push_event("leave_players", %{players: args[:leave]})
    }
  end
  def handle_info(%{event: "presence_diff", payload: p}, socket) do
    session_id = socket.assigns.__session__["_csrf_token"]
    game = socket.assigns.__params__["game"]
    joins =
      p.joins
      |> Enum.map(fn {user_id, data} ->
        data[:metas]
        |> List.first()
        |> Map.merge(%{user_id: user_id})
      end)
    leaves =
      p.leaves
      |> Enum.map(fn {user_id, data} ->
        data[:metas]
        |> List.first()
        |> Map.merge(%{user_id: user_id, me: user_id == session_id})
      end)
    users =
      Presence.list(@topic<>"-#{game}")
      |> Enum.map(fn {user_id, data} ->
        data[:metas]
        |> List.first()
        |> Map.merge(%{user_id: user_id, me: user_id == session_id})
      end)

    players = associate_user_to_player(socket.assigns.players, users)
    socket =
      socket
      |> assign(:users, users)
      |> assign(:players, players)

    broadcast(socket.assigns, [players: players, joins: joins, leaves: leaves])
    {:noreply, socket}
  end

  defp associate_user_to_player(players, users) do
    associated_user_ids = Enum.map(users, &(&1.user_id ))
    associated_players = Enum.filter(players, &(&1.associated in associated_user_ids))
    associated_players_ids = Enum.map(players, &(&1.associated ))
    remained_players = Enum.filter(players, &(not(&1.associated in associated_user_ids)))
    remained_users = Enum.filter(users, &(not(&1.user_id in associated_players_ids)))
    remained_players_associated =
      Enum.zip(remained_players, remained_users)
      |> Enum.map(fn {player, user} -> %{ player | associated: user.user_id, me: user.me } end)

    associated_players ++ remained_players_associated
  end

  def broadcast(state, args \\ []) do
    Enum.each(state.users, &(Phoenix.PubSub.broadcast(Bomber.PubSub,topic_name(state.game, &1.user_id), {:delivery, {state, args}})))
    state
  end

  script {:start, [:session, :stage, :players]} do

    ~J"""
      const ME = params.session;
      const SCREEN_BLOCK = 32;
      const BLOCK_SIZE = 16;
      const [GRID_W, GRID_H] = params.stage.size;
      let PLAYERS = params.players;
      let CURRENT_OTHER_PLAYERS = [];
      let UPDATE_LEVEL_CALLBACK = [];


      <%= BomberWeb.Js.entity() %>
      <%= Bomber.Core.Schema.Block.class_wall() %>
      <%= Bomber.Core.Schema.Block.class_bricks() %>
      <%= Bomber.Core.Schema.Player.class_player() %>
      <%= Bomber.Core.Schema.Player.class_other_player() %>
      <%= Bomber.Core.Schema.Pickup.class_pickup() %>
      <%= Bomber.Core.Schema.Pickup.class_pickup_bomb() %>
      <%= Bomber.Core.Schema.Pickup.class_pickup_fire() %>
      <%= Bomber.Core.Schema.Pickup.class_pickup_speed() %>
      <%= Bomber.Core.Schema.Bomb.class_bomb() %>
      <%= Bomber.Core.Schema.Bomb.class_explosion() %>
      <%= Bomber.Core.Schema.Bomb.class_blast() %>
      <%= Bomber.Core.Schema.Stage.class_grid() %>
      <%= Bomber.Core.Schema.Stage.class_level() %>

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
    """
  end

  view do
    ~F"""
      <div phx-update="ignore">
        <div id="game" class="flex justify-center items-center min-h-screen"></div>
      </div>
      {#if !is_nil(@stage)}
        {debug(assigns)}
      {/if}
    """
  end
  def debug(assigns) do
    ~F"""
      <div class="p-4 bg-gray-100 fixed left-0 bottom-0 w-full z-1 " style="height: 120px">
        <div class="flex justify-center items-center" style="height: 100px; overflow-y: auto">
          <div class="flex flex-col justify-center items-center">
          <div class="p-4 bg-gray-200 m-4"><small>C??DIGO DO JOGO</small> <b>{@game}</b></div>
          {#case {@creator,@running}}
            {#match {true, true}}
              ON
            {#match {false, true}}
              ON
            {#match {true, false}}
              <div class="button" :on-click={:join}>COME??AR</div>
            {#match _}
              Aguarde come??ar
          {/case}
          </div>
          <div class="p-4 bg=gray-400">
          <div class="font-bold"> Jogadores</div>
          {#for p <- @players}
            p-{p.id} (<small>{p.associated}</small>): [{elem(p.position, 0)},{elem(p.position, 1)}]<br/>
          {/for}
          </div>
          <div class="p-4 bg-gray-200">
          <div class="font-bold"> Usu??rios</div>
          {#for u <- @users}
            {u.user_id}: online {u.online_at}<br />
          {/for}
          </div>
        </div>
      </div>
    """
  end
end
