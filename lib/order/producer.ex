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
    order_count = Utils.fetch_conf(:order_count)
    with {:ok, orders} <- Utils.load_orders(order_file_path) do
      orders
      |> take_orders(order_count)
      |> Enum.chunk_every(order_rate * order_interval) 
      |> produce([], order_interval)
    end
  end
  
  def produce([], head, _) do
    # update producer state in ShelfManager
    Logger.info("no more orders")
    ShelfManager.update_producer_state()
    head
  end

  def produce([head | tail], _, order_interval) do
    duration = case Utils.fetch_conf(:producer_duration) do
      :nil -> order_interval
      value -> value
    end
    Logger.info(event, Event.produce_order())
    # place orders
    head |> ShelfManager.place_orders()
    Utils.sleep(duration)
    produce(tail, head, order_interval)
  end

  def take_orders(orders, count) when is_integer(count), do: orders |> Enum.take(count)

  def take_orders(orders, :all), do: orders

  def take_orders([head | _], _), do: head
end
