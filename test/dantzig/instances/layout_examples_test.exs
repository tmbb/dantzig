defmodule Danztig.Instances.LayoutExampleTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  alias Dantzig.Solution

  require Dantzig.Polynomial, as: Polynomial

  test "trivial sum" do
    Polynomial.algebra do
      total_width = 300.0

      problem = Problem.new(direction: :maximize)
      {problem, left_margin} = Problem.new_variable(problem, "left_margin", min: 0.0)
      {problem, center} = Problem.new_variable(problem, "center", min: 0.0)
      {problem, right_margin} = Problem.new_variable(problem, "right_margin", min: 0.0)

      problem =
        problem
        |> Problem.add_constraint(
          Constraint.new(left_margin + center + right_margin == total_width)
        )
        |> Problem.increment_objective(center - left_margin - right_margin)
    end

    solution = Dantzig.solve!(problem)

    # Test properties of the solution
    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # One constraint and three variables
    assert Solution.nr_of_constraints(solution) == 1
    assert Solution.nr_of_variables(solution) == 3
    # The solution gets the right values
    # (note: in this case, equalities should be exact)
    assert Solution.evaluate(solution, left_margin) == 0.0
    assert Solution.evaluate(solution, center) == 300.0
    assert Solution.evaluate(solution, right_margin) == 0.0
    # The objective has the right value
    assert solution.objective == 300.0
  end
end
