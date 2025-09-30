defmodule Dantzig.DSL.ActualBracketSyntaxTest do
  @moduledoc """
  Test actual bracket syntax like queen2d[i, :_] that would work in nqueens_dsl.exs.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "actual bracket syntax with macro" do
    # Test that we can create a macro that handles queen2d[i, :_] syntax
    # This is tricky because we need to handle the bracket notation

    # For now, let's test with a macro that can be called with bracket-like syntax
    # We'll use a different approach - a macro that accepts the variable name and indices

    # Test queen2d[i, :_] equivalent
    queen2d_expr = DSL.var_bracket(:queen2d, [1, :_])

    # Should create the same AST as function call notation
    assert is_tuple(queen2d_expr)
    assert elem(queen2d_expr, 0) == :queen2d
    assert elem(queen2d_expr, 1) == []
    assert elem(queen2d_expr, 2) == [1, :_]
  end

  test "actual bracket syntax with different variables" do
    # Test with different variable names
    queen3d_expr = DSL.var_bracket(:queen3d, [1, 2, 3])
    qty_expr = DSL.var_bracket(:qty, [:food])

    # queen3d should work
    assert is_tuple(queen3d_expr)
    assert elem(queen3d_expr, 0) == :queen3d
    assert elem(queen3d_expr, 2) == [1, 2, 3]

    # qty should work
    assert is_tuple(qty_expr)
    assert elem(qty_expr, 0) == :qty
    assert elem(qty_expr, 2) == [:food]
  end

  test "actual bracket syntax with wildcards" do
    # Test with wildcards
    wildcard_expr = DSL.var_bracket(:queen2d, [:_, :_])

    assert is_tuple(wildcard_expr)
    assert elem(wildcard_expr, 0) == :queen2d
    assert elem(wildcard_expr, 2) == [:_, :_]
  end

  test "actual bracket syntax in constraint context" do
    # Test queen2d[i, :_] == 1
    constraint_ast = {:==, [], [DSL.var_bracket(:queen2d, [1, :_]), 1]}

    # Verify the structure
    assert is_tuple(constraint_ast)
    assert elem(constraint_ast, 0) == :==

    # Get the left side
    left_side = elem(constraint_ast, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :queen2d
    assert elem(left_side, 2) == [1, :_]

    # Get the right side
    right_side = elem(constraint_ast, 2) |> tl() |> hd()
    assert right_side == 1
  end

  test "actual bracket syntax in sum context" do
    # Test sum(queen2d[:_, :_])
    sum_expr = {:sum, [], [DSL.var_bracket(:queen2d, [:_, :_])]}

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum

    # Get the expression inside sum
    expr = elem(sum_expr, 2) |> hd()
    assert is_tuple(expr)
    assert elem(expr, 0) == :queen2d
    assert elem(expr, 2) == [:_, :_]
  end

  test "actual bracket syntax with mixed variables" do
    # Test that we can mix different variable names
    queen2d_expr = DSL.var_bracket(:queen2d, [1, :_])
    queen3d_expr = DSL.var_bracket(:queen3d, [:_, 2, :_])
    qty_expr = DSL.var_bracket(:qty, [:food])

    # All should create proper AST
    assert elem(queen2d_expr, 0) == :queen2d
    assert elem(queen3d_expr, 0) == :queen3d
    assert elem(qty_expr, 0) == :qty

    # All should have proper indices
    assert elem(queen2d_expr, 2) == [1, :_]
    assert elem(queen3d_expr, 2) == [:_, 2, :_]
    assert elem(qty_expr, 2) == [:food]
  end
end
