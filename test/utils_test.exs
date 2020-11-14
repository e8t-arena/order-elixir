defmodule OS.UtilsTest do
  use ExUnit.Case
  doctest OS.Utils

  alias OS.Utils

  test "calculate order value" do
    time_span = 5
    order = 
      [Utils.get_priv_path(), "orders.json"] 
      |> Path.join() 
      |> Utils.load_orders()
      |> elem(1)
      |> hd
      |> Map.put(:produced_at, Utils.get_time()+5)
      |> IO.inspect()
    assert order["temp"] == "frozen"
  end
end
