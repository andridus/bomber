defmodule BomberWeb.IndexPage do

  use C4.View
  import Surface, only: [sigil_F: 2]
  import Phoenix.HTML, only: [raw: 1]

  alias Bomber.PlayerContext
  alias BomberWeb.Presence

  @topic "bomber"

  field :session_id, :string, default: nil
  field :stage, :map, default: nil
  field :players, :map, default: nil
  field :users, {:array, :map}, default: []

  event :on_init
  event :onkey_left
  event :onkey_right
  event :onkey_up
  event :onkey_down

  effect :on_init

  command :cmd_presence

  def on_init(state, _) do
    stage = Bomber.StageContext.generate_stage()
    players = stage.players
    session_id = state.__session__["_csrf_token"]
   {
     %{state | 
        stage: stage, 
        players: players,
        session_id: session_id
        },
      [
        {:javascript, :shortcuts},
        :cmd_presence
      ]}
  end

  def onkey_left(state, _params), do: update_movement(state, :left)
  def onkey_right(state, _params), do: update_movement(state, :right)
  def onkey_up(state, _params), do: update_movement(state, :up)
  def onkey_down(state, _params), do: update_movement(state, :down)

  defp update_movement(state, dir) do
    state.players
    |> Enum.find(fn x -> x.associated == state.session_id end)
    |> case do
      nil -> state
      %{id: _} = player ->
        players =
          Enum.map(state.players, fn p ->
            if p.id == player.id,
              do: PlayerContext.move(state.stage, player, dir),
              else: p
          end)

        %{state | players: players}
        |> broadcast()
    end
  end

  def cmd_presence(socket) do
    session_id = socket.assigns.__session__["_csrf_token"]
    BomberWeb.Endpoint.subscribe(@topic)
    BomberWeb.Endpoint.subscribe(@topic<>"-#{session_id}")
    Presence.track(self(), @topic, session_id , %{ online_at: inspect(System.system_time(:second))})
    socket
  end


  ########################### HANDLE INFO

  def handle_info({:test, state}, socket) do
    {:noreply, socket |> assign(:players, state.players)}
  end

  def handle_info(%{event: "presence_diff"}, socket) do
    users =
      Presence.list(@topic)
      |> Enum.map(fn {user_id, data} ->
        data[:metas]
        |> List.first()
        |> Map.merge(%{user_id: user_id})
      end)

      socket =
        socket
        |> assign(:users, users)
        |> assign(:players, associate_user_to_player(socket.assigns.players, users))

      broadcast(socket.assigns)
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
      |> Enum.map(fn {player, user} -> %{ player | associated: user.user_id } end)

    associated_players ++ remained_players_associated
  end
  
  def broadcast(state) do
    Enum.each(state.users, fn u ->
      Phoenix.PubSub.broadcast(Bomber.PubSub, @topic<>"-#{u.user_id}", {:test, state})
    end)
    state
  end

  script {:shortcuts,[:id]} do
    ~J"""
      hotkeys('right,left,up,down', function (event, handler){
        switch (handler.key) {
          case 'left':
            push_self_view("onkey_left", {});
            break;
          case 'right':
            push_self_view("onkey_right", {});
            break;
          case 'up':
            push_self_view("onkey_up", {});
            break;
          case 'down':
            push_self_view("onkey_down", {});
            break;
        }
      });
    """
  end

  view do
    ~F"""
      <div class="">
        {#if !is_nil(@stage)}
          <div class="relative mx-auto mt-10 " style="width: 800px;height: 540px;">
            {render_player(assigns)}
            {render_board(assigns)}
          </div>

          {debug(assigns)}
        {/if}
      </div>
    """
  end

  @spec render_player(any) :: Phoenix.LiveView.Rendered.t()
  def render_player(assigns) do
    ~F"""
      {#for p <- @players}
        <div class="top-0 z-10 absolute w-full grid border m-4" style={"grid-template-columns: repeat(#{elem(@stage.size,1)}, minmax(0, 1fr));"}>
          {#for b <- @stage.blocks}
            <div class="flex justify-center items-center text-center h-12 w-full">
              {#if elem(b.position, 0) == elem(p.position, 0) && elem(b.position, 1) == elem(p.position, 1)}
                  {p.id}
              {/if}
            </div>
          {/for}
      </div>
        {/for}
    """
  end
  def render_board(assigns) do
    ~F"""
      <div class="top-0 absolute  w-full grid border m-4 " style={"grid-template-columns: repeat(#{elem(@stage.size,1)}, minmax(0, 1fr));"}>
        {#for b <- @stage.blocks}
          <div class="flex justify-center items-center text-center h-12 w-full">
            {raw format_block(b.format)}
          </div>
        {/for}
      </div>
    """
  end

  def debug(assigns) do
    ~F"""
      <div class="p-4 bg-gray-100 fixed left-0 bottom-0 w-full z-1 " style="height: 200px; overflow-y: auto">
        board: [{elem(@stage.size, 0)},{elem(@stage.size, 1)}]
        <div class="flex">
          <div class="p-4 bg=gray-400">
          <div class="font-bold"> Jogadores</div>
          {#for p <- @players}
            p-{p.id} (<small>{p.associated}</small>): [{elem(p.position, 0)},{elem(p.position, 1)}]<br/>
          {/for}
          </div>
          <div class="p-4 bg-gray-200">
          <div class="font-bold"> Usuários</div>
          {#for u <- @users}
            {u.user_id}: online {u.online_at}<br />
          {/for}
          </div>
        </div>
      </div>
    """
  end

  defp format_block("1"), do: "<div class='h-12 w-full bg-red-800'></div>"
  defp format_block("2"), do: "<div class='h-12 w-full bg-blue-100'></div>"
  defp format_block(_), do: "<div class='h-12 w-full bg-white border'></div>"
end
