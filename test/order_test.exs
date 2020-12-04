defmodule OS.OrderTest do
  use ExUnit.Case, async: true
  doctest OS.Order

  alias OS.{Utils, OrderProducer, Order, ShelfManager}

  setup do
    start_supervised!(ShelfManager)
    start_supervised!({DynamicSupervisor, name: OS.OrderSupervisor, strategy: :one_for_one})
    {:ok, orders} = Utils.load_orders()
    %{orders: orders |> Enum.take(15)}
  end

  test "produce orders" do
    orders = [List.duplicate(%{}, 2)] |> OrderProducer.produce(0)
    
    assert length(orders) == 2
    assert orders |> hd |> Map.has_key?(:placed_at) == false
  end

  test "start order process", %{orders: orders} do
    with order <- orders |> hd,
         order <- order 
                  |> Map.put(:shelf, Utils.get_shelf(order))
                  |> Map.put(:check_time, Utils.get_time() + 10) do
      %{pid_name: pid_name} = ShelfManager.handle_start_order(order)
      assert pid_name |> Utils.is_order_alive?() == true
      assert Order.get_value(pid_name |> Utils.get_order_pid()) == 3.7
    end
  end
end
