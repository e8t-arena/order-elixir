defmodule OS.Logger do
  require Logger

  alias OS.{Order, Utils}

  def info(:event, event, reason) when is_atom(reason) do
    info("\n[Event] #{event |> String.upcase()} reason: #{reason}", ansi_color: :yellow)
  end

  def info(:order, %{"id" => id}, value) do 
    info(~s(\n[Order]:\n  id: #{id}\n  value: #{value |> Utils.format_value()}), :show, [])
  end

  def info(message, :show, arg) do
    Logger.info(message, arg)
  end

  def info(message, arg \\ [])

  def info(:event, msg) do
    info("\n[Event] #{msg |> String.upcase()}", ansi_color: :yellow)
  end

  def info(:shelves, msg) do
    info("\n[Shelves] #{msg}")
  end

  def info(:order, %{"id" => id}=order) do 
    order_value = Order.get_value(id)
    info(:order, order, order_value)
  end

  def info(message, arg) do
    unless Utils.is_test?() do
      info(message, :show, arg)
    end
  end
  
  # defdelegate
  
  def warn(message), do: Logger.warn(message)
  def error(message), do: Logger.error(message)
end
