defmodule OS.Logger do
  require Logger

  def info(:event, event) do
    Logger.info("Event: #{inspect(event)}")
  end

  def info(:order, order) do
    Logger.info("Order: #{format(:order, order)}")
  end

  def info([event: event, order: order]) do
    info(:event, event)
    info(:order, order)
  end

  def format(:order, order) do
    "order"
  end

  # defdelegate
  
  def info(message), do: Logger.info(message)
  def warn(message), do: Logger.warn(message)
  def error(message), do: Logger.error(message)
end
