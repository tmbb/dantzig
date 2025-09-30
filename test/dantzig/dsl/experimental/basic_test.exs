defmodule Dantzig.DSL.BasicTest do
  @moduledoc """
  Basic tests for DSL functionality
  """
  use ExUnit.Case, async: true

  alias Dantzig.Problem, as: Problem

  test "basic problem creation works" do
    # Test basic problem creation
    problem = Problem.new(name: "test")

    assert problem.name == "test"
    assert is_map(problem.variables)
    assert is_map(problem.constraints)
  end

  test "variable creation works" do
    # Test variable creation with generators
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "x",
        [{:<-, [], [quote(do: i), 1..2]}, {:<-, [], [quote(do: j), 1..2]}],
        :binary,
        description: "Test variable"
      )

    # Verify variables were created
    x_vars = Problem.get_variables_nd(problem, "x")
    assert x_vars != nil
    # 2x2 = 4 variables
    assert map_size(x_vars) == 4
  end

  test "sum macro works" do
    # Test that the sum macro creates the correct structure
    import Dantzig.DSL.SumFunction, only: [sum: 1]

    sum_expr = sum({:x, [], [:_, :_]})

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum
    assert elem(sum_expr, 1) == {:x, [], [:_, :_]}
  end

  test "variable access macro works" do
    # Test that the variable access macro creates the correct structure
    import Dantzig.DSL.VariableAccess, only: [var_access: 2]

    var_expr = var_access(:x, [1, :_])

    assert is_tuple(var_expr)
    assert elem(var_expr, 0) == :x
    assert elem(var_expr, 2) == [1, :_]
  end
end
