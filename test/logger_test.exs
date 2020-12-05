defmodule OS.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

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
    assert capture_log(fn -> Logger.info(:order, order) end)  =~ "[Order]"
  end
end
