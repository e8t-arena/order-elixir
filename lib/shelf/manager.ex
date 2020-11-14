defmodule OS.ShelfManager do
  @moduledoc """
  A Genserver that manager all kinds of shelves.

  init_state

  %{
    shelves_state: %{"hot":false}
    order_shelf_map: %{order_id:"hot"}
  }

  
  """

  use GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def place_order do
  end

  def move_order do
  end

  def pickup_order do
  end

  def discard_order do
  end

  def update_shelf_state(tag, state) do
    GenServer.cast(__MODULE__, {:update_shelf_state, tag, state})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true
  def handle_cast({:update_shelf_state, tag, shelf_state}, %{shelves_state: shelves_state}=state) do
    shelves_state = %{shelves_state | %{tag => shelf_state}}
    {:noreply, state |> Map.put(:shelves_state, shelves_state)}
  end

end
