defmodule OS.ShelfSupervisor do
  @moduledoc """
  A Supervisor that start 
    
    1. all kinds of shelves

    2. shelf manager
  """

  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    [
      {OS.ShelfManager, []}
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end
end
