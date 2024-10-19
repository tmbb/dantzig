defmodule Dantzig.FunctionCall do
  defstruct name: nil,
            context_dependent: false,
            function: nil,
            arguments: []

  def new(name, function, arguments) do
    %__MODULE__{name: name, function: function, arguments: arguments}
  end

  def new_context_dependent(name, function, arguments) do
    %__MODULE__{name: name, function: function, arguments: arguments}
  end
end
