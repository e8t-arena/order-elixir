defmodule  OS.OrderProducer do
  use Task

  alias OS.{Utils, Logger, ShelfManager}
  alias OS.Utils.Constants.Event

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run([order_file_path: order_file_path]) do
    order_rate = Utils.fetch_conf(:order_rate)
    order_interval = Utils.fetch_conf(:order_interval)
    with {:ok, orders} <- Utils.load_orders(order_file_path) do
      orders
      |> Enum.chunk_every(order_rate * order_interval) 
      |> produce(order_interval)
    end
  end
  
  def produce([], _) do

  end

  def produce([head | tail], order_interval) do
    # head = head |> Enum.map(fn item -> item |> Map.put(:produced_at, Utils.get_time) end)
    Logger.info(event: Event.produce_order(), order: head)
    if order_interval == 0 do
      head
    else
      # place orders
      # head |> ShelfManager.place_orders
      Utils.sleep(order_interval)
      produce(tail, order_interval)
    end
  end
end
