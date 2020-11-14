defmodule OS.Order do
  @module """

  get_value

  update_placed_at

  update_shelf

  update_shelf_life

  discard order

  """

  use GenServer

  alias OS.Utils

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init([order: order]=state) do
    # cal value

    order = order |> Map.put(
      :pid, self()
    )

    state = state |> Map.put(
      :value,
      Utils.calculate_order_value(order)
    ) |> Map.put(
      :order, order
    )

    state |> IO.inspect()

    unless state |> Keyword.get(:skip_check_value), do: check_value()

    {:ok, state}
  end

  @doc """
  Order is wasted.

  exit order process
  """
  @impl true
  def handle_info(:check_value, [order: %{value: value}]=state) when value <= 0 do
    {:normal, "order is wasted", state}
  end
  
  @impl true
  def handle_info(:check_value, [order: %{value: value}=order]=state) do
    IO.puts("Check order value:")
    Utils.get_time |> IO.inspect()
    state |> IO.inspect(label: "current state")

    state = state
    |> Keyword.put(:order, order |> 
      Map.put(
        :value,
        # order |> Utils.calculate_order_value()
        0
      )
    )

    check_value()
    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    {reason, state} |> IO.inspect()
  end

  defp check_value() do
    Process.send_after(self(), :check_value, 3 * 1000)
  end
end
