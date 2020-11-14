defmodule OS.ShelfManager do
  @moduledoc """
  A Genserver that manager all kinds of shelves.

  init_state

  %{
    shelves_state: %{"hot":false}
    order_shelf_map: %{order_id:"hot"}
  }

  order_shelf_map acts as a local process register.

  
  """

  use GenServer
  alias OS.{Shelf, Utils}

  @overflow "OverflowShelf"
  @shelf_tags for [tag, _] <- Utils.fetch_conf(:shelves), do: tag |> String.downcase()

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def place_order(orders) do
    GenServer.cast(__MODULE__, {:place_order, orders})
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
  def handle_cast({:place_order, orders}, %{order_shelf_map: order_shelf_map}=state) do
    orders
    |> Enum.each(fn %{temperature: tag}=order -> 
      # place_order never failed
      # update manager state
      shelf_state = handle_place_order(order) |> Shelf.is_full()
      update_shelf_state(tag |> String.downcase(), shelf_state)
      # TODO: start order process
    end)
  end

  def handle_place_order(order, state, :overflow) when not state do
    Shelf.place_order(@overflow, order)
    @overflow
  end

  @doc """
  When OverflowShelf is full
  """
  def handle_place_order(order, state, :overflow) do
    
  end

  def handle_place_order(%{name: shelf}=order, state) when not state do
    Shelf.place_order(shelf, order)
    shelf
  end

  def handle_place_order(order, state) do
    shelf_state = Shelf.is_full(@overflow)
    handle_place_order(order, shelf_state, :overflow)
  end

  def handle_place_order(%{name: shelf}=order) do
    shelf_state = Shelf.is_full(shelf)
    handle_place_order(order, shelf_state)
  end

  @impl true
  def handle_cast({:update_shelf_state, tag, shelf_state}, %{shelves_state: shelves_state}=state) do
    shelves_state = shelves_state |> Map.put(tag, shelf_state)
    {:noreply, state |> Map.put(:shelves_state, shelves_state)}
  end
end
