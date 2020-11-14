defmodule OS.ShelfTest do
  use ExUnit.Case
  doctest OS.Shelf

  test "init shelves" do
    hot_shelf = OS.ShelfSupervisor.init_shelves |> hd
    assert hot_shelf == %{name: "HotShelf", orders: %{}, temperature: "Hot", capacity: 10}
  end
end
