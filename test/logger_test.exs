defmodule OS.LoggerTest do
  use ExUnit.Case
  doctest OS.Utils

  alias OS.Utils

  test "display order value" do
    order = 
      [Utils.get_priv_path(), "orders.json"] 
      |> Path.join() 
      |> Utils.load_orders()
      |> elem(1)
      |> hd
    # start order process
    assert Map.has_key?(order, :value)
  end
end
