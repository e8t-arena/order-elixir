defmodule OS.ShelfTest do
  use ExUnit.Case, async: true
  doctest OS.Shelf

  alias OS.{Utils, ShelfManager, Order}

  @overflow "overflow" |> Utils.get_shelf()
  # @hot "hot" |> Utils.get_shelf()
  @frozen "frozen" |> Utils.get_shelf()
  # @cold "cold" |> Utils.get_shelf()

  def place_cold_order_on_overflow(orders) do
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold"))
    [order | rest] = cold_orders
    ShelfManager.place_orders(rest |> Enum.take(2))
    ShelfManager.place_orders([order])
    ShelfManager.get_shelf(@overflow)
  end

  setup do
    start_supervised!(ShelfManager)
    start_supervised!({DynamicSupervisor, name: OS.OrderSupervisor, strategy: :one_for_one})
    start_supervised!({Task.Supervisor, name: OS.Courier, strategy: :one_for_one})
    {:ok, orders} = Utils.load_orders()
    %{orders: orders |> Enum.take(15)}
  end

  test "init shelves" do
    hot_shelf = ShelfManager.init_shelves |> Map.get(Utils.get_shelf("hot"))
    assert hot_shelf == %{name: "HotShelf", orders: [], temperature: "Hot", capacity: 2}
  end

  test "place order", %{orders: orders} do
    # place two order
    ShelfManager.place_orders(orders |> Enum.take(2))

    with orders <- ShelfManager.get_orders(),
         order <- orders |> Map.values() |> hd,
         pid_name <- order |> Map.get(:pid_name) do
    # check order process is alive
      assert is_nil(pid_name) == false
      assert Utils.is_order_alive?(order)
      assert orders |> Enum.count() == 2
      assert orders |> Map.values() |> hd |> Map.has_key?(:shelf)
    end
  end

  # test "shelfmanager monitor order process", %{orders: orders} do
  #   ShelfManager.place_orders(orders |> Enum.take(2))
  # end

  test "place order: when matched shelf is full", %{orders: orders} do
    shelf = place_cold_order_on_overflow(orders)
    assert shelf["Cold"] |> Enum.count() == 1
  end

  test "place order: when matched shelf and overflow shelf are full, and move is possible", %{orders: orders} do
    # fill in cold shelf
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold"))
    [cold_order | rest] = cold_orders
    ShelfManager.place_orders(rest |> Enum.take(2))

    # fill in overflow shelf
    frozen_orders = orders |> Enum.filter(&(&1["temp"] == "frozen")) |> Enum.take(5)
    ShelfManager.place_orders(frozen_orders)

    frozen_shelf = ShelfManager.get_shelf(@frozen)
    assert frozen_shelf[:orders] |> Enum.count() == 2

    overflow_shelf = ShelfManager.get_shelf(@overflow)
    assert overflow_shelf[:orders] |> Enum.count() == 3
    assert overflow_shelf["Cold"] |> Enum.count() == 0
    overflow_frozen_order_ids = overflow_shelf["Frozen"]
    assert overflow_frozen_order_ids |> Enum.count() == 3

    orders = ShelfManager.get_orders()
    assert orders |> Map.values() |> hd() |> Map.has_key?(:pid_name)

    with shelves <- ShelfManager.get_shelves(),
         unfilled_shelves <- ShelfManager.get_unfilled_shelves(shelves),
         not_full <- unfilled_shelves |> Enum.map(&(Utils.get_shelf(&1))) |> Enum.member?(@frozen) do
      assert not not_full
    end

    # after picking up frozen order, move order from overflow to frozen is possible, shelf in order map will change
    pickedup_order = frozen_orders |> hd
    ShelfManager.pickup_order(pickedup_order)
    with shelf <- ShelfManager.get_shelf(@frozen),
         order_id <- pickedup_order |> Map.get("id"),
         orders <- shelf |> Map.get(:orders) do
      assert not(orders |> Enum.member?(order_id))
    end

    # TODO: pick up cold order, no move, place cold order to cold shelf directly

    with shelves <- ShelfManager.get_shelves(),
         unfilled_shelves <- ShelfManager.get_unfilled_shelves(shelves),
         not_full <- unfilled_shelves |> Enum.map(&(Utils.get_shelf(&1))) |> Enum.member?(@frozen) do
      assert not_full
    end

    # place cold order
    ShelfManager.place_orders([cold_order])
     
    frozen_shelf = ShelfManager.get_shelf(@frozen)
    fronzen_ids = frozen_shelf[:orders]
    common_ids = overflow_frozen_order_ids -- (overflow_frozen_order_ids -- fronzen_ids)
    assert common_ids |> Enum.count() == 1

    moved_id = common_ids |> hd()
    %{shelf: old_shelf_name} = orders |> Map.get(moved_id)

    orders = ShelfManager.get_orders()
    %{shelf: shelf_new_shelf_name, pid_name: pid_name} = orders |> Map.get(moved_id)
    assert old_shelf_name == shelf_new_shelf_name

    order_new_shelf_name = Order.get_shelf_name(pid_name |> Utils.get_order_pid())
    assert old_shelf_name == order_new_shelf_name
    assert order_new_shelf_name == shelf_new_shelf_name

    overflow_shelf = ShelfManager.get_shelf(@overflow)
    assert overflow_shelf["Cold"] |> hd == cold_order["id"]
  end

  test "place order: when matched shelf and overflow shelf are full, and move is impossible", %{orders: orders} do
    # fill in cold shelf
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold"))
    [order | rest] = cold_orders
    ShelfManager.place_orders(rest |> Enum.take(2))

    # fill in overflow shelf
    frozen_orders = orders |> Enum.filter(&(&1["temp"] == "frozen")) |> Enum.take(5)
    ShelfManager.place_orders(frozen_orders)

    shelf = ShelfManager.get_shelf(@frozen)
    assert shelf[:orders] |> Enum.count() == 2

    shelf = ShelfManager.get_shelf(@overflow)
    assert shelf[:orders] |> Enum.count() == 3
    assert shelf["Cold"] |> Enum.count() == 0
    overflow_frozen_order_ids = shelf["Frozen"]
    assert overflow_frozen_order_ids |> Enum.count() == 3

    with shelves <- ShelfManager.get_shelves(),
         unfilled_shelves <- ShelfManager.get_unfilled_shelves(shelves),
         not_full <- unfilled_shelves |> Enum.map(&(Utils.get_shelf(&1))) |> Enum.member?(@frozen) do
      assert not not_full, "move is not possible"
    end

    with shelves <- ShelfManager.get_shelves(),
         unfilled_shelves <- ShelfManager.get_unfilled_shelves(shelves),
         not_full <- unfilled_shelves |> Enum.map(&(Utils.get_shelf(&1))) |> Enum.member?(@frozen) do
      assert not not_full, "move is not possible"
    end

    # place cold order
    ShelfManager.place_orders([order])
     
    shelf = ShelfManager.get_shelf(@frozen)
    with count <- shelf[:orders] 
      |> Enum.filter(&(Enum.member?(overflow_frozen_order_ids, &1)))
      |> Enum.count() do 
      assert count == 0
    end
    shelf = ShelfManager.get_shelf(@overflow)
    assert shelf["Cold"] |> hd == order["id"]
    ShelfManager.get_orders()
  end

  test "discard order: order value is equal to zero", %{orders: orders} do
    ShelfManager.place_orders(orders |> Enum.take(2))

    %{"id" => order_id} = orders |> hd
    %{pid_name: pid_name} = ShelfManager.get_order(order_id)
    assert pid_name |> Utils.is_order_alive?() == true

    ShelfManager.get_order(order_id)

    # discard order
    # ShelfManager.discard_order(order)
    Order.update_value(pid_name |> Utils.get_order_pid(), 0)
    Utils.sleep(0.1)
    orders = ShelfManager.get_orders()
    assert orders |> Map.has_key?(order_id) == false
    assert pid_name |> Utils.is_order_alive?() == false
  end

  test "pickup order: on single temperature shelf", %{orders: orders} do
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold")) |> Enum.take(2)
    ShelfManager.place_orders(cold_orders)

    %{"id" => order_id} = cold_orders |> hd
    order = ShelfManager.get_order(order_id)
    
    # pick up order
    ShelfManager.pickup_order(order)
    orders = ShelfManager.get_orders()
    assert orders |> Map.has_key?(order_id) == false
    assert order |> Utils.is_order_alive?() == false
  end

  test "pickup order: on overflow shelf", %{orders: orders} do
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold")) |> Enum.take(5)
    ShelfManager.place_orders(cold_orders)

    # pick up last order
    %{"id" => order_id} = cold_orders |> List.last()
    order = ShelfManager.get_order(order_id)
    
    # pick up order
    ShelfManager.pickup_order(order)
    orders = ShelfManager.get_orders()
    assert orders |> Map.has_key?(order_id) == false
    assert order |> Utils.is_order_alive?() == false
  end

  test "dispatch courier", %{orders: orders} do
    cold_orders = orders |> Enum.filter(&(&1["temp"] == "cold")) |> Enum.take(5)
    ShelfManager.place_orders(cold_orders)
    ShelfManager.get_orders()

    delivered_order = cold_orders |> hd()
    assert Utils.is_order_alive?(delivered_order) == true
    order = ShelfManager.dispatch_courier(delivered_order, true)
    Utils.sleep(2)
    assert is_nil(order) == false
    assert Utils.is_order_alive?(order) == false
  end

  test "update producer state" do
    state = ShelfManager.get_producer_state()
    assert state == :running

    ShelfManager.update_producer_state()

    state = ShelfManager.get_producer_state()
    assert state == :done
  end

end
