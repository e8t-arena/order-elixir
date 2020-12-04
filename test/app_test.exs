defmodule OS.ApplicationTest do
  use ExUnit.Case
  doctest OS

  alias OS.Utils

  test "stop application" do
    Application.ensure_all_started(Utils.get_app_name())

    pid_alive = OS.ShelfManager |> Utils.is_pid_alive?()
    assert pid_alive == true

    Application.stop(Utils.get_app_name())
    pid_alive = OS.ShelfManager |> Utils.is_pid_alive?()
    assert pid_alive == false
  end
end
