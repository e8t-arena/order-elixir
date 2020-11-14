defmodule OS.Utils.ConstantsMacro do

  IO.inspect(__MODULE__)

  defmacro __using__(_opts) do
    quote do
      import OS.Utils.ConstantsMacro
      @constants []
    end
  end

  defmacro const(const_var) do
    function_name = const_var
    value = const_var |> Atom.to_string() |> String.replace("-", " ")
    IO.puts("call const (out quote)")
    quote do
      IO.puts("call const (in quote)")
      if @constants |> Enum.member?(unquote(function_name)) do
        raise(RuntimeError, "duplicate constant variable")
      end
      @constants [unquote(function_name) | @constants]
      def unquote(function_name)(), do: unquote(value)
    end
  end

  # defmacro const1(const_var) do
  #   with value <- const_var |> Atom.to_string() |> String.replace("-", " ") do
  #     const(const_var, value)
  #   end
  # end
end

defmodule OS.Utils.Constants.Event do
  use OS.Utils.ConstantsMacro 
  const :produce_order
  const :place_order
  const :pickup_order 
  const :move_order
  const :discard_order
end

# defmodule OS.Utils.Constants.Event1 do
#   use OS.Utils.ConstantsMacro 
# 
#   @events [
#    :produce_order,
#    :place_order,
#    :pickup_order, 
#    :move_order,
#    :discard_order,
#   ]
# 
#   def helper(event) do
#     with value <- event |> Atom.to_string() |> String.replace("-", " ") do
#       const event, value
#     end
#   end
# 
#   def helper() do
#     for event <- @events do
#       helper(event)
#     end
#   end
# 
#   helper()
# end
