defmodule OS.Order do
  @moduledoc """

  init_state
    [order: order]

    order

    %{
      :placed_at => 1605388603,
      "decayRate" => 0.63,
      "id" => "a8cfcb76-7f24-4420-a5ba-d46dd77bdffd",
      "name" => "Banana Split",
      "shelfLife" => 20,
      "temp" => "frozen",
      :pid => <PID>,
      :shelf => "OverflowShelf",
      :value => 1
    }

  get_value

  update_placed_at

  update_shelf

  update_shelf_life

  discard order

  """

  use GenServer

  alias OS.Utils

  def start_link(arg) do
    GenServer.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def update_placed_at(pid), do: GenServer.cast(pid, :update_placed_at)

  def update_shelf(pid, shelf_name), do: GenServer.cast(pid, {:update_placed_at, shelf_name})

  def update_shelf_life(pid, shelf_life), do: GenServer.cast(pid, {:update_shelf_life, shelf_life})

  def discard_order(pid), do: GenServer.cast(pid, :discard)

  def get_value(pid), do: GenServer.call(pid, :get_value)

  @impl true
  def init(order) do
    # cal value

    {skip, order} =  order |> Map.pop(:skip_check_value, false)

    state = with order <- update_order(order, :pid, self()),
         order <- update_order(order, :placed_at, Utils.get_time()),
         order <- update_order(
           order, 
           :value, 
           Utils.calculate_order_value(order)) do
      order
    end

    state |> IO.inspect()

    unless skip, do: check_value()

    {:ok, state}
  end

  @impl true
  def handle_cast(:update_placed_at, state) do
    {:noreply, %{state | placed_at: Utils.get_time()}}
  end

  @impl true
  def handle_cast({:update_shelf, shelf_name}, state) do
    {:noreply, %{state | shelf: shelf_name}}
  end

  @impl true
  def handle_cast({:update_shelf_life, shelf_life}, state) do
    {:noreply, %{state | "shelfLife" => shelf_life}}
  end

  @impl true
  def handle_cast(:discard, state) do
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_value, _From, %{value: value}) do
    {:reply, value}
  end

  @doc """
  Order is wasted.

  exit order process
  """
  @impl true
  def handle_info(:check_value, %{value: value}=state) when value <= 0 do
    {:normal, "order is wasted: #{value}", state}
  end
  
  @impl true
  def handle_info(:check_value, %{value: value}=order) do
    IO.puts("Check order value: #{value}")
    Utils.get_time |> IO.inspect()
    order |> IO.inspect(label: "current state")
    
    state = update_order(
      order, 
      :value,
      Utils.calculate_order_value(order)
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

  defp update_order(order, key, value), do: order |> Map.put(key, value)
end
