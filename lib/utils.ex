defmodule OS.Utils do

  alias OS.Logger

  @app_name Mix.Project.config()[:app]

  def get_app_name, do: @app_name

  def get_priv_path, do: get_app_name() |> Application.app_dir("priv")
  
  def load_orders(order_file_path) do
    with {:ok, binary} <- File.read(order_file_path),
      {:ok, json} <- Jason.decode(binary) do
      {:ok, json}
    else
      {:error, reason} ->
        Logger.warn(reason)
        {:ok, []}
    end
  end

  def load_orders() do
    [get_priv_path(), "orders.json"]
    |> Path.join() 
    |> load_orders()
  end

  def sleep(seconds \\ 0), do: :timer.sleep(seconds * 1000 |> trunc())

  def get_time(), do: DateTime.utc_now |> DateTime.to_unix

  def add_elems(list, []), do: list
  def add_elems(list, [head | tail]) do
    add_elems([head | list], tail)
  end

  def get_shelf(%{shelf: shelf_name}), do: shelf_name

  def get_shelf(%{"temperature" => tag}), do: tag |> get_shelf()

  def get_shelf(%{"temp" => tag}), do: tag |> get_shelf()

  def get_shelf(shelf_tag) when is_bitstring(shelf_tag), do: "#{shelf_tag |> String.capitalize}Shelf"

  def fetch_conf(key) do 
    case Application.fetch_env(get_app_name(), key) do
      {:ok, value} -> value
      :error -> nil
    end
  end

  def is_test?(), do: Mix.env() == :test

  def get_shelf_decay_modifier(shelf), do: if shelf == "overflow", do: 2, else: 1

  def calculate_order_value(_, _, skip) when skip == true, do: 0 

  def calculate_order_value(order, check_time, _) do
    check_time = if is_nil(check_time), do: get_time(), else: check_time
    calculate_order_value(order, check_time)
  end

  def calculate_order_value(%{
    "shelfLife" => shelf_life, 
    "decayRate" => decay_rate,
    placed_at: placed_at,
    shelf: shelf
  }, check_time) do
    with order_age <- check_time - placed_at,
         shelf <- shelf |> String.downcase(),
         shelf_decay_modifier <- get_shelf_decay_modifier(shelf) do
      (shelf_life - order_age - decay_rate * order_age * shelf_decay_modifier) / shelf_life 
      # (shelf_life - order_age - decay_rate * order_age * shelf_decay_modifier) / shelf_life |> Float.round(4)
    end
  end

  def calculate_order_value(order), do: calculate_order_value(order, get_time())

  @doc """
  Group orders by shelf 
  """
  def format_shelves(orders) do
    orders
    |> Enum.group_by(
      fn {_, {key, _}} -> key end, 
      fn (id, {_, pid}) -> %{id: id, pid: pid} end
    )
  end

  def get_order_pid_name(id), do: {OS.Order, id}

  def get_order_pid(%{pid_name: pid_name}=order) when is_map(order), do: get_order_pid(pid_name)

  def get_order_pid(%{"id" => id}=order) when is_map(order), do: id |> get_order_pid_name() |> get_order_pid()

  def get_order_pid(pid_name) when is_tuple(pid_name), do: pid_name |> :global.whereis_name()

  def get_order_pid(id), do: id |> get_order_pid_name() |> get_order_pid()

  def is_order_alive?(%{pid_name: pid_name}=order) when is_map(order), do: is_order_alive?(pid_name) 

  def is_order_alive?(%{"id" => id}=order) when is_map(order), do: id |> get_order_pid_name() |> is_order_alive?() 

  def is_order_alive?(pid_name) do 
    case pid_name |> get_order_pid() do
      :undefined -> false
      pid -> Process.alive?(pid)
    end
  end

  def is_pid_alive?(nil), do: false

  def is_pid_alive?(pid) when is_pid(pid), do: Process.alive?(pid)

  def is_pid_alive?(pid), do: pid |> Process.whereis() |> is_pid_alive?()

  def stop_app() do
    # Application.stop(@app_name)
    System.stop(0)
  end

  def format_value(value) when is_float(value), do: value |> Float.round(4)

  def format_value(value) when is_integer(value), do: value

  def format_value(_value), do: format_value(0)
end
