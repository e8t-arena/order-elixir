defmodule OS.Courier do
  use Task

  alias OS.ShelfManager   

  def run(order) do
    # arrive randomly between 2-6 seconds later
    delay = 2..6 |> Enum.random()
    receive do
    after 
      delay -> 
        ShelfManager.pickup_order(order)
    end
  end
end
