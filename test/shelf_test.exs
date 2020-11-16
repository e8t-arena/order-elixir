defmodule OS.ShelfTest do
  use ExUnit.Case, async: true
  doctest OS.Shelf

  alias OS.{Utils,ShelfManager}

  @overflow "OverflowShelf"

  setup do
    manager = start_supervised!(ShelfManager)
    {:ok, orders} = Utils.load_orders()
    %{manager: manager, orders: orders |> Enum.take(10)}
  end

  test "init shelves" do
    hot_shelf = ShelfManager.init_shelves |> Map.get(Utils.get_shelf("hot"))
    assert hot_shelf == %{name: "HotShelf", orders: [], temperature: "Hot", capacity: 2}
  end

  test "place order", %{manager: _manager, orders: orders} do
    # place two order
    ShelfManager.place_orders(orders |> Enum.take(2))
    %{shelves: _shelves, orders: orders} = ShelfManager.get_shelves()
    assert orders |> Enum.count() == 2
  end

  test "place order: when matched shelf is full", %{manager: _manager, orders: orders} do
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold"))
    [order | rest] = cold_orders
    ShelfManager.place_orders(cold_orders |> Enum.take(2))
    ShelfManager.place_orders([order])
    shelf = ShelfManager.get_shelve(@overflow)
    assert shelf["Cold"] |> Enum.count() == 1
  end

  test "place order: when matched shelf and overflow shelf are full, and move is possible" do
  end

  test "place order: when matched shelf and overflow shelf are full, and move is impossible" do
  end
end
