defmodule OS.ShelfManager do
  @moduledoc """
  A Genserver that manager all kinds of shelves.

  init_state

  %{
    orders: %{order_id: pid},
    hot: %{},
    cold: frozen: overflow:
  }

  orders acts as a local process register.

  get_shelves()
    %{"Hot shelf":[]}

  get_orders()

  get_order(order_id)

  """

  use GenServer
  alias OS.{Shelf, Utils}

  @overflow "OverflowShelf"
  @shelves Utils.fetch_conf(:shelves)

  def start_link(_state) do
    GenServer.start_link(__MODULE__, :ok)
  end

  def place_orders(orders) do
    orders
    |> Enum.map(&(GenServer.cast(__MODULE__, {:place_order, &1})))
  end

  @impl true
  def handle_cast({:place_order, order}, state) do
    state = handle_place_order(order, state)
    # fn %{temperature: tag}=order -> 
    #   # place_order never failed
    #   # update manager state
    #   shelf_state = handle_place_order(order) |> Shelf.is_full()
    #   update_shelf_state(tag |> String.downcase(), shelf_state)
    #   # TODO: start order process
    # end)
    {:noreply, state}
  end

  def handle_place_order(%{"temp" => tag}=order, %{shelves: shelves, orders: orders}=state) do
    # place order
    state = with shelf_name <- Utils.get_shelf(tag),
         %{"capacity" => capacity, orders: old_orders} = old_shelf <- shelves[shelf_name],
         is_full <- capacity <= length(old_orders),
         shelves <- handle_place_order(is_full, {order, shelves, shelf_name, old_shelf}) do
      update_state(state, :shelves, shelves)
    end
    # handle_place_order()
    # start order process
    # update orders
  end

  @doc """
  If matched shelf is not full.
  """
  def handle_place_order(false, {order, shelves, shelf_name, old_shelf}) do
    with shelf_orders <- [order | old_shelf[:orders]],
         # shelf <- %{old_shelf | orders: shelf_orders},
         shelves <- %{shelves | shelf_name => shelf} do
      shelves
    end
  end

  def update_shelf_orders(shelf, shelf_name) when shelf_name == @overflow do
    # update "Hot"

  end

  def update_shelf_orders(shelf, shelf_name), do: %{shelf | orders: shelf_orders}

  @doc """
  If matched shelf is full.

  Check overflow shelf

  If overflow shelf is not full

  If overflow shelf is full

  (move)

  get_unfilled_shelves

  get_match_orders_in_overflow_shelf

  """
  def handle_place_order(true, {order, shelves, shelf_name, _old_shelf}) do
    with %{"capacity" => capacity, orders: old_orders} = old_shelf <- shelves[@overflow],
         is_full <- capacity <= length(old_orders) do
      if not is_full do
        handle_place_order(is_full, {order, shelves, :overflow, old_shelf})
      else
        move_order()
        # after move, overflow shelf is unfilled
        is_full = false
        handle_place_order(is_full, {order, shelves, @overflow, old_shelf})
      end
    end
  end


  @doc """
  From Overflow shelf to Other unfilled shelf

  return shelves, shelf
  """
  def move_order do
  end

  def pickup_order do
  end

  def discard_order do
  end

  def update_shelf_state(tag, state) do
    GenServer.cast(__MODULE__, {:update_shelf_state, tag, state})
  end

  def get_shelves() do
    GenServer.call(__MODULE__, :get_shelves)
  end

  def get_order(order_id) do
    GenServer.call(__MODULE__, {:get_order, order_id})
  end

  @impl true
  def init(:ok) do
    state = init_state()
    {:ok, state}
  end

  @impl true
  def handle_cast({:place_order, orders}, %{order_shelf_map: order_shelf_map}=state) do
    orders
    |> Enum.each(fn %{temperature: tag}=order -> 
      # place_order never failed
      # update manager state
      shelf_state = handle_place_order(order) |> Shelf.is_full()
      update_shelf_state(tag |> String.downcase(), shelf_state)
      # TODO: start order process
    end)
  end

  def handle_place_order(order, state, :overflow) when not state do
    Shelf.place_order(@overflow, order)
    @overflow
  end

  @doc """
  TODO
  When OverflowShelf is full
  """
  def handle_place_order(order, state, :overflow) do
    
  end

  def handle_place_order(%{name: shelf}=order, state) when not state do
    Shelf.place_order(shelf, order)
    shelf
  end

  def handle_place_order(order, state) do
    shelf_state = Shelf.is_full(@overflow)
    handle_place_order(order, shelf_state, :overflow)
  end

  def handle_place_order(%{name: shelf}=order) do
    shelf_state = Shelf.is_full(shelf)
    handle_place_order(order, shelf_state)
  end

  @impl true
  def handle_cast({:update_shelf_state, tag, shelf_state}, %{shelves_state: shelves_state}=state) do
    shelves_state = shelves_state |> Map.put(tag, shelf_state)
    {:noreply, state |> Map.put(:shelves_state, shelves_state)}
  end

  @impl true
  def handle_call(:get_shelves, _from, state) do
    {:reply, state}
  end

  @impl true
  def handle_call({:get_order, order_id}, _from, %{orders: orders}) do
    {:reply, orders[order_id]}
  end

  def init_shelves do
    init_keys = [:name, :orders, :temperature, :capacity]
    for %{name: name} = shelf <- @shelves |> Enum.map(fn [temp, _]=shelf -> 
        shelf = shelf 
        |> Utils.add_elems(["#{temp}Shelf", []] |> Enum.reverse)
        Enum.zip(init_keys, shelf) |> Map.new
      end), into: %{} do
        case name
          _ -> {name, shelf}
          @overflow -> 
            extra_map = %{
              "Hot" => [],
              "Cold" => [],
              "Frozen" => []
            }
        end
    end
  end

  def init_state() do
    %{
      orders: %{},
      shelves: init_shelves()
    }
  end

  def get_unfilled_shelves(%{shelves: shelves}) do
    for %{capacity: capacity, orders: orders, temperature: temp} <- shelves, capacity > length(orders) do temp
    end
  end

  def update_state(state, key, value), do: %{state | key => value}
end
