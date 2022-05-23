defmodule BomberWeb.IndexPage do
  use C4.View
  import Surface, only: [sigil_F: 2]

  field :game, :string, default: ""
  event :new_game
  event :join_game
  event :handle_update_game

  command :cmd_new_game
  command {:cmd_join_game, [:game]}

  def handle_update_game(state, %{"value" => value}) do
    %{state | game: value}
  end

  def new_game(state, _) do
    {state, :cmd_new_game}
  end

  def join_game(state, _) do
    {state, {:cmd_join_game, [state.game]}}
  end

  def cmd_new_game(socket) do
    push_redirect(socket, to: "/g/#{C4.Helpers.unique(10)}?server=true")
  end

  def cmd_join_game(socket, params) do
    IO.inspect params
    push_redirect(socket, to: "/g/#{params.game}")
  end

  view do
    ~F"""
      <div class="flex flex-col  justify-center items-center min-h-screen">
        <div :on-click={:new_game} class="btn btn-lg btn-primary">Criar novo jogo</div>
        <div class="flex flex-col my-10 ">
          <input type="text" placeholder="Código do jogo" :on-keyup={:handle_update_game}>
          <div :on-click={:join_game} class="btn btn-accent">Juntar-se a um jogo existente</div>
        </div>
      </div>
    """
  end
end
