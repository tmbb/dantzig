defmodule Dantzig.ProblemVariable do
  @moduledoc false
  defstruct name: nil,
            min: nil,
            max: nil,
            type: :real,
            description: nil

  @type variable_name :: binary()
end
