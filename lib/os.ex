defmodule OS do
  @moduledoc """
  Documentation for `OS`.
  """

  @doc """
  Start Application
  """
  def start(_type, _args) do
    OS.Supervisor.start_link(name: OS.Supervisor)
  end
end
