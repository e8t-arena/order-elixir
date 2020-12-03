defmodule OS.Courier do
  use Task

  alias OS.{ShelfManager, Utils}   

  def run(order) do
    # arrive randomly between 2-6 seconds later
    delay = if Utils.is_test?(), do: 0.1, else: 2..6 |> Enum.random()
    IO.inspect("Deliver order: #{order |> inspect()} after #{delay}")
    receive do
    after 
      delay * 1000 -> 
        Task.async(fn -> 
          ShelfManager.pickup_order(order)
        end)
    end
  end
end
