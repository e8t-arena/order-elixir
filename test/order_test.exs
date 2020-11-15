defmodule OS.OrderTest do
  use ExUnit.Case
  doctest OS.Order

  alias OS.OrderProducer

  test "produce orders" do
    orders = [List.duplicate(%{}, 2)] |> OrderProducer.produce(0)
    
    assert length(orders) == 2
    assert orders |> hd |> Map.has_key?(:placed_at) == false
  end

  test "place order" do
    # Order.
  end
end
