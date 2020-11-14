defmodule OS.Utils do

  @app_name Mix.Project.config()[:app]

  def get_app_name, do: @app_name

  def get_priv_path, do: get_app_name |> Application.app_dir("priv")

  def load_orders(order_file_path) do
    with {:ok, binary} <- File.read(order_file_path),
      {:ok, json} <- Jason.decode(binary) do
      {:ok, json}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  def sleep(seconds \\ 0), do: :timer.sleep(seconds * 1000)

  def get_time(), do: DateTime.utc_now |> DateTime.to_unix

  def add_elems(list, []), do: list
  def add_elems(list, [head | tail]) do
    add_elems([head | list], tail)
  end

  def get_shelf(shelf_tag), do: "#{shelf_tag |> String.capitalize}Shelf"

  def fetch_conf(key), do: Application.fetch_env!(get_app_name(), key)

  def is_test(), do: Mix.env() == :test

  def get_shelf_decay_modifier(shelf), do: if shelf == "overflow", do: 2, else: 1

  def calculate_order_value(%{
    "shelfLife" => shelf_life, 
    "decayRate" => decay_rate,
    placed_at: placed_at,
    shelf: shelf
  }, check_time \\ get_time()) do
    with order_age <- check_time - placed_at,
         shelf <- shelf |> String.downcase(),
         shelf_decay_modifier <- get_shelf_decay_modifier(shelf) do
      # (shelf_life - order_age - decay_rate * order_age * shelf_decay_modifier) / shelf_life 
      shelf_life - order_age - decay_rate * order_age * shelf_decay_modifier
    end
  end
end
