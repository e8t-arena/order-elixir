defmodule OS.Shelf do
  @moduledoc """
  A Shelf Agent store all kinds of shelves.

  init value structure:

  %{
    temperature: "Hot",
    capacity: 10,
    orders: %{
      order_id: %{}
    }
  }

  is_full: check if the shelf was full.

  place_order: place order on selected shelf.

  pickup_order: courier deliver specific order.
  """

  use Agent

  @overflow "OverflowShelf"

  def start_link([init: init, name: name]) when name == @overflow do
    # support choosing randomly or choosing by value
    extra_map = %{
      "hot": [],
      "cold": [],
      "frozen": []
    }
    Agent.start_link(fn -> init |> Map.merge(extra_map) end, name: name)
  end

  def start_link([init: init, name: name]) do
    Agent.start_link(fn -> init end, name: name)
  end

  def is_full(%{capacity: capacity, orders: orders}), do: capacity == length(orders)

  def is_full(shelf) do
    Agent.get(shelf, &(is_full(&1)))
  end

  def place_order(%{orders: orders, name: name}=state, %{order_id: order_id, temperature: tag}=new_order) when name == @overflow do
    state = place_order(state, new_order)
  end

  def place_order(%{orders: orders, name: name}=state, %{order_id: order_id}=new_order) do
    orders = orders |> Map.put(order_id, new_order)
    %{state | orders: orders}
  end

  def place_order(shelf, new_order) do
    Agent.update(shelf, &(place_order(&1, new_order)))
  end

  def update_tag_orders(%{orders: orders}=state, %{order_id: order_id, temperature: tag}=new_order) do
    %{^tag => tag_orders} = state
    [order_id | tag_orders]
    |> Enum.sort()
  end

  def pickup_order(%{orders: orders}=state, %{order_id: order_id}) do
    orders = orders |> Map.delete(order_id)
    %{state | Orders: orders}
  end

  def pickup_order(shelf, order) do
    Agent.update(shelf, &(pickup_order(&1, order)))
  end
end
