defmodule OS.Order do
  use GenServer

  alias OS.Utils

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg)
  end

  @impl true
  def init([order: %{value: value}]=state) do
    state |> IO.inspect()
    check_value()
    {:ok, state}
  end

  @doc """
  Order is wasted.

  exit order process
  """
  @impl true
  def handle_info(:check_value, [order: %{value: value}]=state) when value < 3 do
    {:normal, "order is wasted", state}
  end
  
  @impl true
  def handle_info(:check_value, [order: %{value: value}=order]=state) do
    IO.puts("Check order value:")
    Utils.get_time |> IO.inspect()
    state |> IO.inspect()
    state = state
    |> Keyword.put(:order, order |> 
      Map.put(:value, value - 2)
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
