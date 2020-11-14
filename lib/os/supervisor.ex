defmodule OS.Supervisor do
  use Supervisor

  alias OS.{Utils}

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    priv_path = Utils.get_app_name |> Application.app_dir("priv")
    order_file_path = Path.join([priv_path, 'orders.json'])
    children = [
      # OS.Register
      # OS.OrderProducer
      # OS.OrderSupervisor
      # OS.ShelfStore
      # OS.Shelf

      {OS.ShelfStore},
      # {OS.OrderProducer, order_file_path: order_file_path }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
