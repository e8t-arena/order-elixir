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
      {Task.Supervisor, name: OS.Courier},

      {DynamicSupervisor, name: OS.OrderSupervisor, strategy: :one_for_one},

      OS.ShelfSupervisor,

      {OS.OrderProducer, order_file_path: order_file_path }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
