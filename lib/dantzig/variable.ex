defmodule Dantzig.ProblemVariable do
  @moduledoc false
  defstruct name: nil,
            min: nil,
            max: nil,
            type: :real
end
