defmodule OS.UtilsTest do
  use ExUnit.Case
  doctest OS.Utils

  alias OS.Utils

  test "calculate order value" do
    time_span = 5
    current_time = Utils.get_time()
    order = 
      [Utils.get_priv_path(), "orders.json"] 
      |> Path.join() 
      |> Utils.load_orders()
      |> elem(1)
      |> hd
      |> Map.put(:placed_at, current_time)
    check_time = current_time + time_span
    assert Utils.calculate_order_value(order |> Map.put(:shelf, order["temp"]), check_time) == 11.85
  end

  test "fetch configuration" do
    assert Utils.fetch_conf(:nonkey) |> is_nil() == true
  end
end
