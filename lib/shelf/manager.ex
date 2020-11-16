defmodule OS.ShelfManager do
  @moduledoc """
  A Genserver that manager all kinds of shelves.

  init_state

  %{
    orders: %{order_id: %{pid: pid, value: value}},
    shelves: %{
      "HotShelf": %{
        orders: []
      },
      "ColdShelf": %{},
      ...
      "OverflowShelf": %{
        name: "OverflowShelf"
        temperature: "Overflow",
        capacity: 10,
        orders: []
        "Hot": [],
        "Frozen": [],
      }
    }
  }

  orders acts as a local process register.

  get_shelves()

  get_orders()

  get_order(order_id)

  """

  use GenServer
  alias OS.{Utils}

  @overflow "OverflowShelf"
  @shelves Utils.fetch_conf(:shelves)

  def start_link(_state) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def place_orders(orders) do
    # orders
    # |> Enum.map(&(GenServer.cast(__MODULE__, {:place_order, &1})))
    GenServer.cast(__MODULE__, {:place_orders, orders})
  end

  def pickup_order do

  end

  def discard_order do
  end

  def update_shelf_state(tag, state) do
    GenServer.cast(__MODULE__, {:update_shelf_state, tag, state})
  end

  def get_shelves(), do: GenServer.call(__MODULE__, :get_shelves)

  def get_shelf(shelf_name), do: GenServer.call(__MODULE__, {:shelf_name, shelf_name})

  def get_order(orders, id) when is_map(orders), do: orders[id]

  def get_order(id), do: GenServer.call(__MODULE__, {:get_order, id})

  def get_order_value(orders, id), do: get_order(orders, id)[:value]

  @impl true
  def init(:ok) do
    state = init_state()
    {:ok, state}
  end

  @impl true
  def handle_cast({:place_orders, orders}, state) do
    # state = handle_place_order(order, state)
    state = orders
    |> List.foldl(state, fn order, acc -> 
      handle_place_order(order, acc)
    end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_shelf_state, tag, shelf_state}, %{shelves_state: shelves_state}=state) do
    shelves_state = shelves_state |> Map.put(tag, shelf_state)
    {:noreply, state |> Map.put(:shelves_state, shelves_state)}
  end

  @impl true
  def handle_call(:get_shelves, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call(:get_orders, _from, %{orders: orders}=state) do
    {:reply, orders, state}
  end

  @impl true
  def handle_call({:get_order, order_id}, _from, %{orders: orders}=state) do
    {:reply, orders[order_id], state}
  end

  @impl true
  def handle_call({:get_shelf, shelf_name}, _from, %{shelves: shelves}=state) do
    {:reply, shelves[shelf_name], state}
  end

  # Helpers

  def handle_place_order_shelves(tag, order, shelves, orders) do
    with shelf_name <- Utils.get_shelf(tag),
         %{capacity: capacity, orders: old_orders} = old_shelf <- shelves[shelf_name],
         is_full <- capacity <= length(old_orders) do 
      handle_place_order(is_full, {order, orders, shelves, shelf_name, old_shelf})
    end
  end

  def handle_place_order_orders(%{"id" => id}, orders, :discard) do 
    # TODO: stop order process
    Map.delete(orders, id)
  end

  def handle_place_order_orders(%{"id" => id}=order, orders), do: orders |> Map.put(id, order)

  def handle_place_order(%{"temp" => tag}=order, %{shelves: shelves, orders: orders}=state) do
    # place order
    {state, shelves, shelf_name} = case handle_place_order_shelves(tag, order, shelves, orders) do
      {shelves, shelf_name, discarded_order} ->
        orders = handle_place_order_orders(discarded_order, orders, :discard)
        {update_state(state, :orders, orders), shelves, shelf_name}
      {shelves, shelf_name} -> {state, shelves, shelf_name}
    end

    state = update_state(state, :shelves, shelves)
    order = order |> Map.put(:shelf, shelf_name)
    # start order process
    order = start_order_child(order)
    # update orders
    orders = handle_place_order_orders(order, orders)
    update_state(state, :orders, orders)
  end

  @doc """
  If matched shelf is not full.
  """
  def handle_place_order(false, {order, _orders, shelves, shelf_name, old_shelf}) do
    shelf_order_ids =  [order["id"] | old_shelf[:orders]]
    {update_shelf_orders(old_shelf, shelf_order_ids, shelf_name, order, shelves), shelf_name}
  end

  """
  If matched shelf is full.

  Check overflow shelf

    If overflow shelf is not full

    If overflow shelf is full

  """
  def handle_place_order(true, {order, orders, shelves, _shelf_name, _old_shelf}) do
    with %{capacity: capacity, orders: old_orders} = old_shelf <- shelves[@overflow],
         is_full <- capacity <= length(old_orders) do
      if not is_full do
        handle_place_order(is_full, {order, orders, shelves, @overflow, old_shelf})
      else
        {label, old_shelf, moved_order} = move_order(old_shelf, orders, shelves)
        is_full = false
        shelves = if label == :move do
          # move to matched shelf
          shelves = handle_place_order(is_full, {moved_order, orders, shelves, moved_order |> Utils.get_shelf(), old_shelf})
          # TODO: update order process (:shelf, :placed_at)
          shelves 
        else
          shelves 
        end
        # after move, overflow shelf is unfilled, place new order to overflow shelf
        shelves = handle_place_order(is_full, {order, orders, shelves, @overflow, old_shelf})
        shelf_name = @overflow
        if label == :discard do
          {shelves, shelf_name, moved_order}
        else
          {shelves, shelf_name}
        end
      end
    end
  end

  @doc """
  Overflow shelf is not full
  """
  def update_shelf_orders(shelf, shelf_order_ids, shelf_name, %{"id" => order_id, "temp" => tag}, shelves) when shelf_name == @overflow do
    # update "Hot"
    with key <- tag |> String.capitalize(),
         temp_orders <- [order_id | shelf[key]],
         shelf <- %{shelf | key => temp_orders},
         shelf <- %{shelf | orders: shelf_order_ids} do
      %{shelves | shelf_name => shelf}
    end
  end

  """
  Single Tempreture shelf is not full
  """
  def update_shelf_orders(shelf, shelf_order_ids, shelf_name, _, shelves) do
    shelf = %{shelf | orders: shelf_order_ids}
    %{shelves | shelf_name => shelf}
  end

  @doc """
  From Overflow shelf to Other unfilled shelf

  return shelves, shelf
  """
  def move_order(overflow_shelf, orders, shelves) do
    # [[],[]]
    order_ids = for shelf_tag <- get_unfilled_shelves(shelves) do
      overflow_shelf[shelf_tag]
    end
    case order_ids |> List.flatten() do
      # randomly discard order
      [] ->
        order_ids =  overflow_shelf["orders"]
        with order_id <- choose_order(:random, order_ids) do
          order = get_order(orders, order_id)
          {:discard, remove_shelf_order(overflow_shelf, order), order}
        end
      # select order
      # remove order
      # place order to single temperature shelf
      order_ids -> 
        with order_id <- choose_order(:random, order_ids) do
          order = get_order(orders, order_id)
          {:move, remove_shelf_order(overflow_shelf, order), order}
        end
    end
  end

  def remove_shelf_order(%{orders: order_ids, name: name}=shelf, %{"id" => id, "temp" => tag}) when name == @overflow do 
    # remove order from 
    with temp_order_ids <- shelf[tag] do
      # overflow_shelf temp orders
      # oveflow_shelf orders 
      shelf |> Map.put(
        tag,
        remove_order_id(temp_order_ids, id)
      ) |> Map.put(
        :orders,
        remove_order_id(order_ids, id)
      )
    end
  end

  def remove_shelf_order(%{orders: order_ids}=shelf, id) do 
    shelf |> Map.put(
      :orders,
      remove_order_id(order_ids, id)
    )
  end

  def remove_order_id(order_ids, id), do: order_ids |> List.delete(id)

  @doc """
  alternative orders
  """
  def choose_order(:random, ids), do: ids |> Enum.random()

  def choose_order(:lowest_value, ids) do
    {_, shelf_orders} = GenServer.call(__MODULE__, :get_all_orders)
    ids
    |> Enum.sort(&(get_order_value(shelf_orders, &1) < get_order_value(shelf_orders, &2)))
    |> hd
  end

  def init_shelves do
    init_keys = [:name, :orders, :temperature, :capacity]
    for %{name: name} = shelf <- @shelves |> Enum.map(fn [temp, _]=shelf -> 
        shelf = shelf 
        |> Utils.add_elems(["#{temp}Shelf", []] |> Enum.reverse)
        Enum.zip(init_keys, shelf) |> Map.new
      end), into: %{} do
        case name do
          @overflow -> 
            extra_map = %{
              "Hot" => [],
              "Cold" => [],
              "Frozen" => []
            }
            {name, shelf |> Map.merge(extra_map)}
          _ -> {name, shelf}
        end
    end
  end

  def init_state() do
    %{
      orders: %{},
      shelves: init_shelves()
    }
  end

  def get_unfilled_shelves(shelves) do
    for %{capacity: capacity, orders: orders, temperature: temp} <- shelves, capacity > length(orders) and temp != "Overflow", do: temp
  end

  def update_state(state, key, value), do: %{state | key => value}

  def start_order_child(order) do
    pid = 0
    order |> Map.put(:pid, pid)
  end

  def terminate(_order_id), do: :ok
end
