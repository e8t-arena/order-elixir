defmodule OS.ShelfSupervisor do
  @moduledoc """
  A Supervisor that start 
    
    1. all kinds of shelves

    2. shelf manager
  """

  use Supervisor

  alias OS.{Utils}

  @shelves Utils.fetch_conf(:shelves)

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    init_children(OS.Shelf) ++ [
      {OS.ShelfManager, []}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  def init_children(mod) do
    init_shelves() |> Enum.map(fn %{name: name}=init -> 
      {mod, init: init, name: name}
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
