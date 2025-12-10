defmodule Dantzig.ProblemTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Dantzig.Problem
  alias Dantzig.Constraint
  alias Dantzig.Polynomial

  test "creating a problem requires specifying the optimization direction" do
    assert_raise RuntimeError, fn ->
      Problem.new([])
    end
  end

  test "can create a linear maximization problem" do
    _problem = Problem.new(direction: :maximize)
  end

  test "can create a linear minimization problem" do
    _problem = Problem.new(direction: :minimize)
  end

  property "can create a variable with the given suffix" do
    check all(
            suffix <- StreamData.string([?a..?z, ?A..?Z, ?0..?9, ?_], min_length: 1),
            direction <- StreamData.one_of([:minimize, :maximize])
          ) do
      problem = Problem.new(direction: direction)
      {problem, variable} = Problem.new_variable(problem, suffix)

      assert Enum.any?(problem.variables, fn {variable_name, _variable} ->
               String.ends_with?(variable_name, suffix)
             end)

      assert Enum.any?(Polynomial.variables(variable), fn variable_name ->
               String.ends_with?(variable_name, suffix)
             end)

      assert %Problem{} = problem
    end
  end

  test "variables are monomials (i.e. have a single term) of degree 1 and with no constant term" do
    check all(
            suffix <- StreamData.string([?a..?z, ?A..?Z, ?0..?9, ?_], min_length: 1),
            direction <- StreamData.one_of([:minimize, :maximize])
          ) do
      problem = Problem.new(direction: direction)
      {_problem, variable} = Problem.new_variable(problem, suffix)

      assert Polynomial.degree(variable) == 1
      assert Polynomial.number_of_terms(variable) == 1
      assert Polynomial.has_constant_term?(variable) == false
    end
  end

  test "the right hand side of a constraint is a number (and not a polynomial)" do
    check all(
            terms1 <-
              StreamData.list_of(
                StreamData.tuple({
                  StreamData.float(),
                  StreamData.string([?a..?z, ?A..?Z, ?0..?9, ?_], min_length: 1)
                }),
                min_length: 1
              ),
            terms2 <-
              StreamData.list_of(
                StreamData.tuple({
                  StreamData.float(),
                  StreamData.string([?a..?z, ?A..?Z, ?0..?9, ?_], min_length: 1)
                }),
                min_length: 1
              ),
            const1 <- StreamData.float(),
            const2 <- StreamData.float(),
            direction <- StreamData.one_of([:minimize, :maximize]),
            operator <- StreamData.one_of([:==, :<=, :>=])
          ) do
      variable_suffixes_left = Enum.map(terms1, fn {_coeff, var} -> var end)
      variable_suffixes_right = Enum.map(terms2, fn {_coeff, var} -> var end)

      problem = Problem.new(direction: direction)
      # Add variables top the problem based on the suffixes we've generated
      {problem, variables_left} = Problem.new_variables(problem, variable_suffixes_left)
      {problem, variables_right} = Problem.new_variables(problem, variable_suffixes_right)

      p_left = Polynomial.sum(variables_left) |> Polynomial.add(const1)
      p_right = Polynomial.sum(variables_right) |> Polynomial.add(const2)

      problem = Problem.add_constraint(problem, Constraint.new(p_left, operator, p_right))

      [constraint] = Map.values(problem.constraints)

      assert map_size(problem.constraints) == 1
      assert is_number(constraint.right_hand_side)
      assert constraint.right_hand_side == const2 - const1
    end
  end

  test "can solve problem with different variable types" do
    use Dantzig.Polynomial.Operators

    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x", type: :binary)
    {problem, y} = Problem.new_variable(problem, "y", type: :real, min: 1)
    {problem, z} = Problem.new_variable(problem, "z", type: :integer, min: 5, max: 20)

    problem = Problem.add_constraint(problem, Constraint.new(x + y, :==, 20))
    problem = Problem.increment_objective(problem, x + y + z)

    assert {:ok, solution} = Dantzig.HiGHS.solve(problem)
    assert solution.feasibility == "Feasible"
  end
end
