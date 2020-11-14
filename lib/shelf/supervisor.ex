defmodule OS.ShelfSupervisor do
  @moduledoc """
  A Supervisor that start 
    
    1. all kinds of shelves

    2. shelf manager
  """

  use Supervisor

  alias OS.{Utils}

  @shelves [
    ["Hot", 10],
    ["Cold", 10],
    ["Frozen", 10],
    ["Overflow", 15]
  ]

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    init_children ++ [
      {OS.ShelfManager, []}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  def init_children(mod) do
    init_shelves |> Enum.map(fn %{name: name}=init -> 
      {OS.Shelf, init: init, name: name}
    end)
  end

  def init_shelves do
    init_keys = [:name, :orders, :temperature, :capacity]
    @shelves |> Enum.map(fn [temp, _]=shelf -> 
      shelf = shelf 
      |> Utils.add_elems(["#{temp}Shelf", %{}] |> Enum.reverse)
      Enum.zip(init_keys, shelf) |> Map.new
    end)
  end
end
