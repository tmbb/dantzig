defmodule Dantzig.Instances.ClosedFormQuadraticTest do
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  require Dantzig.Polynomial, as: Polynomial

  alias Dantzig.Solution

  test "closed form quadratic: x - x*x" do
    Polynomial.algebra do
      problem = Problem.new(direction: :maximize)
      {problem, x} = Problem.new_variable(problem, "x", min: -2.0, max: 2.0)
      problem = Problem.increment_objective(problem, x - x * x)
    end

    {:ok, solution} = Dantzig.HiGHS.solve(problem)

    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # There are no constraints
    assert solution.constraints == %{}
    # Only a single variable is created
    assert Solution.nr_of_variables(solution) == 1
    # The solution is correct (within a margin of error)
    assert_in_delta(Solution.evaluate(solution, x), 0.5, 0.0001)
    # The objective value is correct (within a margin of error)
    assert_in_delta(solution.objective, 0.25, 0.0001)
  end
end
