defmodule OS.Logger do
  require Logger

  alias OS.Order

  def info(:event, msg) do
    info("[Event] #{msg |> String.upcase()}")
  end

  def info(:shelves, msg) do
    info("[Shelves] #{msg}")
  end

  def info(:order, %{"id" => id}, value) do 
    info(~s([Order]:\n  id: #{id}\n  value: #{value}))
  end

  def info(:order, %{"id" => id}=order) do 
    order_value = Order.get_value(id)
    info(:order, order, order_value)
  end

  def info(message), do: Logger.info(message)
  
  # defdelegate
  
  def warn(message), do: Logger.warn(message)
  def error(message), do: Logger.error(message)
end

defmodule OS.Logger1 do
  require Logger

  alias OS.{Order, ShelfManager}

  def info(:event, event) do
    Logger.info("[Event] #{event |> String.upcase()}")
  end

  def info(:order, order) do Logger.info("Order: #{format(:order, order)}")
  end

  def info(:event, event, :order, order) do
    info(:event, event)
    info(:order, order)
  end

  def info(:event, event, :shelves) do
    info(:event, event)
    info(:shelves)
  end

  def info(:shelves) do
    ShelfManager.get_shelves()
  end

  def info(message), do: Logger.info(message)

  def format(:order, order) do
    # TODO order_id
    "#{inspect(order)}, value: #{Order}"
    "order"
  end

  # defdelegate
  
  def warn(message), do: Logger.warn(message)
  def error(message), do: Logger.error(message)
end
