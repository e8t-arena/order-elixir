defmodule OS.ShelfManager do
  @moduledoc """
  A Genserver that manager all kinds of shelves.

  init_state

  %{
    orders: %{order_id: %{pid_name: {}, value: value}},
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
  alias OS.{Utils, Order, Logger}

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

  def pickup_order(id) do
    GenServer.call(__MODULE__, {:pickup_order, id})
  end

  @doc """
  when
    order value <= 0
      Order process terminate, Manager get :DOWN message
    move is not impossible
      discard random order (in move_order)
  """
  def discard_order(order) do
    GenServer.cast(__MODULE__, {:discard_order, order})
  end

  def update_shelf_state(tag, state) do
    GenServer.cast(__MODULE__, {:update_shelf_state, tag, state})
  end

  def get_shelves(), do: GenServer.call(__MODULE__, :get_shelves)

  def get_shelf(shelf_name), do: GenServer.call(__MODULE__, {:get_shelf, shelf_name})

  def get_orders(), do: GenServer.call(__MODULE__, :get_orders)

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
    orders|>IO.inspect()
    state = orders
    |> List.foldl(state, fn order, acc -> 
      {new_state, order} = handle_place_order(order, acc)
      # dispatch courier
      dispatch_courier(order, Utils.is_test?())
      new_state
    end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:update_shelf_state, tag, shelf_state}, %{shelves: shelves}=state) do
    shelves = shelves |> Map.put(tag, shelf_state)
    {:noreply, state |> Map.put(:shelves, shelves)}
  end

  @impl true
  def handle_cast({:discard_order, %{shelf: shelf_name}=order}, %{orders: orders, shelves: shelves}) do
    # Call OrderSupervisor to stop Order process (in handle_place_order_orders)
    with shelf <- shelves |> Map.get(shelf_name),
         shelf <- remove_shelf_order(shelf, order) do
      shelves = %{shelves | shelf_name => shelf}
      orders = handle_place_order_orders(order, orders, :discard)
      {:noreply, %{orders: orders, shelves: shelves}}
    end
  end

  @impl true
  def handle_call({:pickup_order, %{"id" => id, pid_name: pid_name}}, _from, %{orders: orders, shelves: shelves}) do
    {removed_order, orders, shelves} = handle_pickup_order(id, pid_name, orders, shelves)
    {:reply, removed_order, %{orders: orders, shelves: shelves}}
  end

  @impl true
  def handle_call({:pickup_order, %{"id" => id}}, _from, %{orders: orders, shelves: shelves}) do 
    {removed_order, orders, shelves} = handle_pickup_order(id, orders, shelves)
    {:reply, removed_order, %{orders: orders, shelves: shelves}}
  end

  @impl true
  def handle_call(:get_shelves, _from, %{shelves: shelves}=state) do
    {:reply, shelves, state}
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

  def handle_place_order_orders(%{"id" => id, pid_name: pid_name}, orders, :discard) do 
    # stop order process
    case Utils.get_order_pid(pid_name) do
      :undefined -> orders
      pid -> 
        DynamicSupervisor.terminate_child(OS.OrderSupervisor, pid)
        Map.delete(orders, id)
    end
  end

  def handle_place_order_orders(%{"id" => id}=order, orders, :update), do: orders |> Map.put(id, order)

  def handle_place_order(%{"temp" => tag}=order, %{shelves: shelves, orders: orders}=state) do
    # place order
    {state, shelves, shelf_name} = case handle_place_order_shelves(tag, order, shelves, orders) do
      {shelves, shelf_name, updated_order, label} ->
        orders = handle_place_order_orders(updated_order, orders, label)
        {update_state(state, :orders, orders), shelves, shelf_name}
      {shelves, shelf_name} -> {state, shelves, shelf_name}
    end
    
    # shelves |> IO.inspect()
    pid = Utils.get_order_pid(order)
    with state <- update_state(state, :shelves, shelves),
         order <- order |> Map.put(:shelf, shelf_name), 
    # start order process 
         order <- handle_order_process(order, pid),
    # update orders of shelf manager
         orders <- handle_place_order_orders(order, orders, :update) do
      {update_state(state, :orders, orders), order}
    end
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
        {label, shelves, updated_order} = move_order(old_shelf, orders, shelves)
        is_full = false
        # after move, overflow shelf is unfilled, place new order to overflow shelf
        {shelves, shelf_name} = handle_place_order(is_full, {order, orders, shelves, @overflow, old_shelf})
        {shelves, shelf_name, updated_order, label}
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
        order_ids =  overflow_shelf[:orders]
        with order_id <- choose_order(:random, order_ids),
             order <- get_order(orders, order_id),
             # -> order (just for overflow shelf order)
             shelf <- remove_shelf_order(overflow_shelf, order) do
          {:discard, %{shelves | @overflow => shelf}, order}
        end
      # select order
      # remove order
      # place order to single temperature shelf
      order_ids -> 
        with order_id <- choose_order(:random, order_ids),
             order <- get_order(orders, order_id),
             shelf_name <- Utils.get_shelf(order),
             old_shelf <- shelves[shelf_name],
             order <- %{order | shelf: shelf_name},
             shelves <- %{ shelves | @overflow => remove_shelf_order(overflow_shelf, order) } do
          # place moved_order
          {shelves, _} = handle_place_order(false, {order, orders, shelves, shelf_name, old_shelf})
          # TODO: update moved order process state
          {:update, shelves, order}
        end
    end
  end

  def remove_shelf_order(%{orders: order_ids, name: name}=shelf, %{"id" => id, "temp" => tag}) when name == @overflow do 
    # remove order from 
    tag = tag |> String.capitalize()
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

  def remove_shelf_order(%{orders: order_ids}=shelf, %{"id" => id}) do 
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
    # TODO: use tuple instead of map (?)
    %{
      orders: %{},
      shelves: init_shelves()
    }
  end

  def get_unfilled_shelves(shelves) do
    for {_, %{capacity: capacity, orders: orders, temperature: temp}} <- shelves, capacity > length(orders) and temp != "Overflow", do: temp
  end

  def update_state(state, key, value), do: %{state | key => value}

  def handle_pickup_order(id, pid_name, orders, shelves) do
    # remove from state order
    {%{^id => removed_order}, orders} = orders |> Map.split([id])
    # remove from state shelves
    shelves = with shelf_name <- removed_order[:shelf],
         shelf <- shelves[shelf_name] do
      shelf = remove_shelf_order(shelf, removed_order)
      %{shelves | shelf_name => shelf}
    end
    # stop order process
    case Utils.get_order_pid(pid_name) do
      :undefined -> 
        Logger.warn("#{pid_name} not found")
      pid -> 
        DynamicSupervisor.terminate_child(OS.OrderSupervisor, pid)
    end
    {removed_order, orders, shelves}
  end

  def handle_pickup_order(id, orders, shelves) do
    pid_name = {OS.Order, id}
    handle_pickup_order(id, pid_name, orders, shelves)
  end

  def handle_order_process(%{"id" => id}=order, :undefined) do
    spec = Supervisor.child_spec({Order, {order, id}}, id: id)
    case DynamicSupervisor.start_child(OS.OrderSupervisor, spec) do
      {:ok, _pid} ->
        order |> Map.put(:pid_name, {OS.Order, id})
      {:error, reason} ->
        reason
    end
  end

  def handle_order_process(%{shelf: shelf_name}=order, order_pid) do
    # update shelf_name in Order process
    Order.update_shelf(order_pid, shelf_name)
    order
  end

  def dispatch_courier(order, run_task \\ true)
  def dispatch_courier(order, run_task) do
    case Task.Supervisor.async(OS.Courier, OS.Courier, :run, [order]) |> Task.await() do
      nil -> 
        Logger.info("not found order")
        nil
      order -> 
        Logger.info("Deliver order #{order |> inspect()}")
        order
    end
  end

  def dispatch_courier(order, false), do: nil

  def terminate(_order_id), do: :ok
end
