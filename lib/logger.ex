defmodule OS.Logger do
  require Logger

  alias OS.{Order}

  def info(:event, event) do
    Logger.info("Event: #{inspect(event)}")
  end

  def info(:order, order) do
    Logger.info("Order: #{format(:order, order)}")
  end

  def info(:shelves) do
    ShelfManger.get_shelves()
  end

  def info(event: event, order: order) do
    info(:event, event)
    info(:order, order)
  end

  def info(event: event, :shelves) do
    info(:event, event)
    info(:shelves)
  end

  def format(:order, order) do
    # TODO order_id
    "#{inspect(order)}, value: #{Order.get_value()}"
    "order"
  end

  # defdelegate
  
  def info(message), do: Logger.info(message)
  def warn(message), do: Logger.warn(message)
  def error(message), do: Logger.error(message)
end
