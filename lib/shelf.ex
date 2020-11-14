defmodule OS.Shelf do
  @moduledoc """
  A Shelf Agent store all kinds of shelves.

  init value structure:

  %{
    Temperature: "Hot",
    Capacity: 10,
    Orders: %{
      order_id: %{}
    }
  }

  is_full: check if the shelf was full.

  place_order: place order on selected shelf.

  pickup_order: courier deliver specific order.
  """

  use Agent

  def start_link([init: init, name: name]) do
    Agent.start_link(fn -> init end, name: name)
  end

  def is_full(shelf) do
    Agent.get(shelf, &(is_full(&1)))
  end

  def place_order(shelf, new_order) do
    Agent.update(shelf, &(place_order(&1, new_order)))
  end

  def pickup_order(shelf, order) do
    Agent.update(shelf, &(pickup_order(&1, order)))
  end

  def is_full(%{capacity: capacity, orders: orders}), do: capacity == length(orders)

  def place_order(%{orders: orders}=state, %{order_id: order_id}=new_order) do
    orders = orders |> Map.put(order_id, new_order)
    %{state | Orders: orders}
  end

  def pickup_order(%{orders: orders}=state, %{order_id: order_id}) do
    orders = orders |> Map.delete(order_id)
    %{state | Orders: orders}
  end

end
