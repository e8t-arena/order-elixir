defmodule  OS.OrderProducer do
  alias OS.{Utils, Logger}
  use Task

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run([order_file_path: order_file_path]) do
    with {:ok, orders} <- Utils.load_orders(order_file_path) do
      orders |> produce
    end
  end
  
  def produce([]), do: Logger.info("End of Orders")
  def produce([head | tail]) do
    head = head |> Map.put(:produced_at, Utils.get_time)
    Logger.info(event: "order received", order: head)
    Utils.sleep(2)
    produce(tail)
  end
end
