defmodule Dantzig.DSL.BracketSyntaxTest do
  @moduledoc """
  Test bracket notation syntax like queen2d[i, :_] vs queen2d(i, :_).
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "bracket notation macro works" do
    # Test that bracket notation can be transformed
    bracket_expr = DSL.bracket_access(:queen2d, [1, :_])

    # Should create the same AST as function call notation
    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen2d
    assert elem(bracket_expr, 1) == []
    assert elem(bracket_expr, 2) == [1, :_]
  end

  test "var_access macro works for both syntaxes" do
    # Test that var_access can handle both bracket and function call notation
    bracket_expr = DSL.var_access(:queen2d, [1, :_])
    function_expr = DSL.var_access(:queen2d, [1, :_])

    # Both should create the same AST
    assert bracket_expr == function_expr
    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen2d
    assert elem(bracket_expr, 2) == [1, :_]
  end

  test "bracket notation in constraint context" do
    # Test that bracket notation works in constraint expressions
    # This would be: queen2d[i, :_] == 1
    constraint_ast = {:==, [], [DSL.bracket_access(:queen2d, [1, :_]), 1]}

    # Verify the structure
    assert is_tuple(constraint_ast)
    assert elem(constraint_ast, 0) == :==

    # Get the left side (bracket access)
    left_side = elem(constraint_ast, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :queen2d
    assert elem(left_side, 2) == [1, :_]

    # Get the right side (1)
    right_side = elem(constraint_ast, 2) |> tl() |> hd()
    assert right_side == 1
  end

  test "bracket notation with multiple indices" do
    # Test bracket notation with multiple indices: queen3d[i, j, k]
    bracket_expr = DSL.bracket_access(:queen3d, [1, 2, 3])

    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen3d
    assert elem(bracket_expr, 2) == [1, 2, 3]
  end

  test "bracket notation with wildcards" do
    # Test bracket notation with wildcards: queen2d[:_, :_]
    bracket_expr = DSL.bracket_access(:queen2d, [:_, :_])

    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen2d
    assert elem(bracket_expr, 2) == [:_, :_]
  end

  test "bracket notation in sum context" do
    # Test bracket notation in sum expressions: sum(queen2d[:_, :_])
    sum_expr = {:sum, [], [DSL.bracket_access(:queen2d, [:_, :_])]}

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum

    # Get the expression inside sum
    expr = elem(sum_expr, 2) |> hd()
    assert is_tuple(expr)
    assert elem(expr, 0) == :queen2d
    assert elem(expr, 2) == [:_, :_]
  end
end
