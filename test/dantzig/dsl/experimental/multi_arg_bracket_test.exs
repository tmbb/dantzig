defmodule Dantzig.DSL.MultiArgBracketTest do
  @moduledoc """
  Test multi-argument bracket notation like queen2d[i, :_].
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "multi-argument bracket syntax works" do
    # Test that we can handle queen2d[i, :_] syntax
    # This should create the same AST as queen2d(i, :_)

    # For now, let's test with a macro that accepts the multi-arg syntax
    bracket_expr = DSL.multi_arg_bracket(:queen2d, [1, :_])

    # Should create the same AST as function call notation
    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen2d
    assert elem(bracket_expr, 1) == []
    assert elem(bracket_expr, 2) == [1, :_]
  end

  test "multi-argument bracket with wildcards" do
    # Test queen2d[:_, :_]
    bracket_expr = DSL.multi_arg_bracket(:queen2d, [:_, :_])

    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen2d
    assert elem(bracket_expr, 2) == [:_, :_]
  end

  test "multi-argument bracket with 3D indices" do
    # Test queen3d[i, j, k]
    bracket_expr = DSL.multi_arg_bracket(:queen3d, [1, 2, 3])

    assert is_tuple(bracket_expr)
    assert elem(bracket_expr, 0) == :queen3d
    assert elem(bracket_expr, 2) == [1, 2, 3]
  end

  test "multi-argument bracket in constraint context" do
    # Test queen2d[i, :_] == 1
    constraint_ast = {:==, [], [DSL.multi_arg_bracket(:queen2d, [1, :_]), 1]}

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

  test "multi-argument bracket in sum context" do
    # Test sum(queen2d[:_, :_])
    sum_expr = {:sum, [], [DSL.multi_arg_bracket(:queen2d, [:_, :_])]}

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum

    # Get the expression inside sum
    expr = elem(sum_expr, 2) |> hd()
    assert is_tuple(expr)
    assert elem(expr, 0) == :queen2d
    assert elem(expr, 2) == [:_, :_]
  end
end
