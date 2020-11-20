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
      :pid_name => {:global, ""}
      :shelf => "OverflowShelf",
      :value => 1
    }

  get_value

  update_placed_at

  update_shelf

  update_shelf_life

  discard order

  """

  use GenServer, restart: :transient

  alias OS.{Utils, ShelfManager} 

  def start_link({order, name}) do
    GenServer.start_link(__MODULE__, order, name: {:global, {__MODULE__, name}})
  end

  def update_placed_at(pid), do: GenServer.cast(pid, :update_placed_at)

  def update_shelf(pid, shelf_name), do: GenServer.cast(pid, {:update_placed_at, shelf_name})

  def update_shelf_life(pid, shelf_life), do: GenServer.cast(pid, {:update_shelf_life, shelf_life})

  def update_value(pid), do: GenServer.cast(pid, :update_value)

  def discard_order(pid), do: GenServer.cast(pid, :discard)

  def get_value(pid), do: GenServer.call(pid, :get_value)
  def get_shelf_name(pid), do: GenServer.call(pid, :get_shelf_name)

  @impl true
  def init(%{"id"=>id}=order) do
    # calculate value

    {skip, order} =  order |> Map.pop(:skip_check_value, false)
    {check_time, order} =  order |> Map.pop(:check_time)

    state = with order <- update_order(order, :pid_name, {:global, id}),
         order <- update_order(order, :placed_at, Utils.get_time()),
         value <- Utils.calculate_order_value(order, check_time, skip),
         order <- update_order(order, :value, value) do
      order
    end

    state # |> IO.inspect()

    unless skip, do: check_value()

    {:ok, state}
  end

  @impl true
  def handle_cast(:update_placed_at, state) do
    {:noreply, %{state | placed_at: Utils.get_time()}}
  end

  @impl true
  def handle_cast({:update_shelf, shelf_name}, %{value: value}=state) do
    state = state |> Map.put(:shelf, shelf_name)
                  |> Map.put("shelfLife", value)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_shelf_life, shelf_life}, state) do
    {:noreply, %{state | "shelfLife" => shelf_life}}
  end

  @impl true
  def handle_cast(:update_value, state) do
    IO.inspect("Order: #{state["id"]} Value: #{state[:value]}")
    state = update_order(
      state, 
      :value,
      Utils.calculate_order_value(state)
    )
    check_value()
    {:noreply, state}
  end

  @impl true
  def handle_cast(:discard, state) do
    # cast() ShelfManager
    {:noreply, state}
  end

  @impl true
  def handle_call(:get_value, _From, %{value: value}=state) do
    {:reply, value, state}
  end

  @impl true
  def handle_call(:get_shelf_name, _From, %{shelf: shelf_name}=state) do
    {:reply, shelf_name, state}
  end

  @impl true
  def handle_call(:check_value, _From, state) do
    # call ShelfManager to discard order (used in test)
    state = %{state | value: 0}
    ShelfManager.discard_order(state)
    {:reply, {0, state}, state}
  end

  @doc """
  Order is wasted.

  exit order process
  """
  @impl true
  def handle_info(:check_value, %{value: value}=state) when value <= 0 do
    # {:normal, "order is wasted: #{value}", state}
    ShelfManager.discard_order(state)
    {:noreply, state}
  end
  
  @impl true
  def handle_info(:check_value, %{value: value}=order) do
    IO.puts("Check order value: #{value}")
    Utils.get_time() |> IO.inspect()
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

  def check_value(pid), do: GenServer.call(pid, :check_value)

  def check_value() do
    # Process.send_after(self(), :check_value, 1000)
    Task.async(fn -> 
      receive do
      after 
        1000 -> OS.Order.update_value(self() |> Utils.get_order_pid())
      end
    end)
  end

  defp update_order(order, key, value), do: order |> Map.put(key, value)
end
