defmodule Dantzig.DSL.SimpleIntegrationTest do
  @moduledoc """
  Simple integration tests for the DSL functionality
  """
  use ExUnit.Case, async: true

  alias Dantzig.Problem, as: Problem

  # Enable variable access for testing
  use Dantzig.DSL.Integration
  import Dantzig.DSL.Integration, only: [enable_variable_access: 1]
  enable_variable_access("queen2d")

  test "basic DSL functionality works" do
    # Test the exact syntax from nqueens_dsl.exs
    problem =
      Problem.new(
        name: "N-Queens",
        description:
          "Place N queens on an N×N chessboard so that no two queens attack each other."
      )
      |> Problem.variables(
        "queen2d",
        [{:<-, [], [quote(do: i), 1..4]}, {:<-, [], [quote(do: j), 1..4]}],
        :binary,
        description: "Queen position"
      )

    # Verify problem structure
    assert problem.name == "N-Queens"
    assert map_size(problem.variables) > 0

    # Verify variables were created
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    # 4x4 = 16 variables
    assert map_size(queen2d_vars) == 16
  end

  test "variable access macros work" do
    # Test that the variable access macros are working
    var_access = queen2d(i, :_)

    assert is_tuple(var_access)
    assert elem(var_access, 0) == :queen2d
    # Check that the indices are correct
    indices = elem(var_access, 2)
    assert is_list(indices)
    assert length(indices) == 2
    assert Enum.at(indices, 1) == :_
  end

  test "sum function works" do
    # Test that the sum function is working
    sum_expr = sum(queen2d(:_, :_))

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum
    # Check that the expression is correct
    expr = elem(sum_expr, 2)
    assert is_list(expr)
    assert length(expr) == 1
    assert hd(expr) == {:queen2d, [], [:_, :_]}
  end
end
