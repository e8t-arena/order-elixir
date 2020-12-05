defmodule OS.Utils.ConstantsMacro do

  defmacro __using__(_opts) do
    quote do
      import OS.Utils.ConstantsMacro
      @constants []
    end
  end

  defmacro const(const_var) do
    function_name = const_var
    value = const_var |> Atom.to_string() |> String.replace("-", " ")
    quote do
      if @constants |> Enum.member?(unquote(function_name)) do
        raise(RuntimeError, "duplicate constant variable")
      end
      @constants [unquote(function_name) | @constants]
      def unquote(function_name)(), do: unquote(value)
    end
  end
end

defmodule OS.Utils.Constants.Event do
  use OS.Utils.ConstantsMacro 
  const :produce_order
  const :receive_order
  const :place_order
  const :pickup_order 
  const :move_order
  const :discard_order
  const :dispatch_courier
end
