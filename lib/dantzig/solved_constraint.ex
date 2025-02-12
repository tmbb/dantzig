defmodule Dantzig.SolvedConstraint do
  @moduledoc """
  A constraint that has been solved for the value of one of the variables
  """

  @type t :: %__MODULE__{}

  defstruct name: nil,
            variable: nil,
            operator: nil,
            expression: nil,
            metadata: nil
end
