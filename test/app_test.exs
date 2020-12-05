defmodule OS.ApplicationTest do
  use ExUnit.Case
  doctest OS

  alias OS.{Utils, ShelfManager}

  @app_name Utils.get_app_name()

  test "stop application" do
    Application.ensure_all_started(@app_name)

    pid_alive = OS.ShelfManager |> Utils.is_pid_alive?()
    assert pid_alive == true

    Application.stop(@app_name)
    pid_alive = OS.ShelfManager |> Utils.is_pid_alive?()
    assert pid_alive == false
  end

  test "stop application when producer and shelf empty" do
    Application.put_env(@app_name, :order_count, 1)
    Application.put_env(@app_name, :producer_duration, 0)
    Application.ensure_all_started(@app_name)

    {_, producer_pid, _, _} = Supervisor.which_children(OS.Supervisor) |> hd()

    pid_alive = producer_pid |> Utils.is_pid_alive?()
    assert pid_alive == true

    order_count = Utils.fetch_conf(:order_count)
    assert order_count == 1

    {reason, _} = catch_exit(:sys.get_state(self(), 1000))
    assert reason == :timeout

    order = ShelfManager.get_orders() |> Map.values() |> hd()

    # dispatch courier
    ShelfManager.dispatch_courier(order, true)

    {reason, _} = catch_exit(:sys.get_state(self(), 300))
    assert reason == :timeout

    # assert ShelfManager.get_orders() == %{}

    # assert ShelfManager.get_producer_state() == :done

    pid_alive = OS.ShelfManager |> Utils.is_pid_alive?()
    assert pid_alive == false
  end
end
