defmodule OS.LoggerTest do
  use ExUnit.Case, async: true
  doctest OS.Utils

  alias OS.{Utils, Logger}

  test "display order value" do
    order = 
      [Utils.get_priv_path(), "orders.json"] 
      |> Path.join() 
      |> Utils.load_orders()
      |> elem(1)
      |> hd
    # start order process
    assert Logger.format(:order, order) == "order"
  end
end
