defmodule OS.Supervisor do
  use Supervisor

  alias OS.{Utils}

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    order_file_path = [Utils.get_priv_path(), "orders.json"] |> Path.join()
    children = [
      # OS.OrderSupervisor

      OS.ShelfSupervisor,
      # {OS.OrderProducer, order_file_path: order_file_path }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
