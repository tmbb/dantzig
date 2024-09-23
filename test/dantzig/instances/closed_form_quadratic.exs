defmodule Dantzig.Instances.ClosedFormQuadraticTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  test "closed form quadratic: x - x*x" do
    Polynomial.algebra do
      problem = Problem.new(direction: :maximize)
      {problem, x} = Problem.new_variable(problem, "x", min: -2.0, max: 2.0)
      {problem, _obj} = Problem.increment_objective(problem, x - x*x)
    end

    solution = Dantzig.solve(problem)

    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # There are no constraints
    assert solution.constraints == %{}
    # Only a single variable is created
    assert Solution.nr_of_variables(solution) == 1
    # The solution is correct (within a margin of error)
    assert_in_delta(Solution.evaluate(solution, x), 0.5, 0.0001)
    # The objective value is correct (within a margin of error)
    assert_in_delta(solution.objective, 0.5, 0.0001)
  end

  test "closed form quadratic: x - x*x (implicit problem)" do
    Polynomial.algebra do
      problem = Problem.new(direction: :maximize)
      Problem.with_implicit_problem problem do
        v!(x, min: -2.0, max: 2.0)
        increment_objective!(x - x*x)
      end
    end

    solution = Dantzig.solve(problem)

    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # There are no constraints
    assert solution.constraints == %{}
    # Only a single variable is created
    assert Solution.nr_of_variables(solution) == 1
    # The solution is correct (within a margin of error)
    assert_in_delta(Solution.evaluate(solution, x), 0.5, 0.0001)
    # The objective value is correct (within a margin of error)
    assert_in_delta(solution.objective, 0.5, 0.0001)
  end
end
