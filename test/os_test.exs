defmodule OSTest do
  use ExUnit.Case
  doctest OS

  test "greets the world" do
    assert OS.hello() == :world
  end
end
