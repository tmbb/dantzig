defmodule Dantzig.Format.CPLEX do
  alias Dantzig.Constraint
  alias Dantzig.Polynomial
  alias Dantzig.Problem
  alias Dantzig.ProblemVariable

  def to_iodata(%Problem{} = problem) do
    constraints = Enum.sort(problem.constraints)

    constraints_iodata =
      Enum.map(constraints, fn {_id, constraint} ->
        constraint_to_iodata(constraint)
      end)

    bounds = all_variable_bounds(Map.values(problem.variables))
    integers = variables_by_type(problem.variables, :integer)
    binaries = variables_by_type(problem.variables, :binary)

    [
      direction_to_iodata(problem.direction),
      "\n  ",
      Polynomial.to_lp_iodata_objective(problem.objective),
      "\n",
      "Subject To\n",
      constraints_iodata,
      "Bounds\n",
      bounds,
      "General\n",
      list_variables(integers),
      "Binary\n",
      list_variables(binaries),
      "End\n"
    ]
  end

  defp constraint_to_iodata(constraint = %Constraint{}) do
    [
      "  ",
      constraint.name,
      ": ",
      Polynomial.to_lp_constraint(constraint.left_hand_side),
      " ",
      operator_to_iodata(constraint.operator),
      " ",
      to_string(constraint.right_hand_side),
      "\n"
    ]
  end

  defp operator_to_iodata(operator) do
    case operator do
      :== -> "="
      other -> to_string(other)
    end
  end

  defp direction_to_iodata(:maximize), do: "Maximize"
  defp direction_to_iodata(:minimize), do: "Minimize"


  # Bounds have higher priority than variable type. So we need to exclude the :binary type here.
  defp variable_bounds(%ProblemVariable{type: :binary}), do: ""

  defp variable_bounds(%ProblemVariable{} = v) do
    case {v.min, v.max} do
      {nil, nil} ->
        "  #{v.name} free\n"

      {nil, max} ->
        "  #{v.name} <= #{max}\n"

      {min, nil} ->
        "  #{min} <= #{v.name}\n"

      {min, max} ->
        "  #{min} <= #{v.name}\n  #{v.name} <= #{max}\n"
    end
  end

  defp all_variable_bounds(variables) do
    Enum.map(variables, &variable_bounds/1)
  end

  defp variables_by_type(variables, type) do
    for {name, %{type: ^type}} <- variables, do: name
  end

  defp list_variables([]), do: []

  defp list_variables(variables) do
    for name <- variables, do: "  #{name}\n"
  end
end
