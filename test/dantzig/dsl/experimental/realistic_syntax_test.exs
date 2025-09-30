defmodule Dantzig.DSL.RealisticSyntaxTest do
  @moduledoc """
  Test realistic syntax that can actually work in Elixir.
  Since queen2d[i, :_] is invalid Elixir syntax, we need alternative approaches.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "function call syntax works" do
    # Test that queen2d(i, :_) syntax works (this is valid Elixir)
    # We need to create a macro that can handle this

    # For now, let's test with a macro that accepts function call syntax
    queen2d_expr = DSL.func_call(:queen2d, [1, :_])

    # Should create the same AST as function call notation
    assert is_tuple(queen2d_expr)
    assert elem(queen2d_expr, 0) == :queen2d
    assert elem(queen2d_expr, 1) == []
    assert elem(queen2d_expr, 2) == [1, :_]
  end

  test "single argument bracket syntax works" do
    # Test that queen2d[i] syntax works (this is valid Elixir)
    # But queen2d[i, :_] doesn't work because of multiple arguments

    # For single argument, we can use bracket notation
    single_expr = DSL.single_bracket(:queen2d, [1])

    assert is_tuple(single_expr)
    assert elem(single_expr, 0) == :queen2d
    assert elem(single_expr, 2) == [1]
  end

  test "alternative syntax approaches" do
    # Since queen2d[i, :_] is invalid, let's test alternative approaches

    # Approach 1: Function call syntax queen2d(i, :_)
    func_expr = DSL.func_call(:queen2d, [1, :_])
    assert elem(func_expr, 0) == :queen2d
    assert elem(func_expr, 2) == [1, :_]

    # Approach 2: Helper macro DSL.var("queen2d", [i, :_])
    helper_expr = DSL.var_helper("queen2d", [1, :_])
    assert elem(helper_expr, 0) == :queen2d
    assert elem(helper_expr, 2) == [1, :_]

    # Approach 3: Access protocol with single argument queen2d[i]
    access_expr = DSL.single_bracket(:queen2d, [1])
    assert elem(access_expr, 0) == :queen2d
    assert elem(access_expr, 2) == [1]
  end

  test "constraint with function call syntax" do
    # Test queen2d(i, :_) == 1
    constraint_ast = {:==, [], [DSL.func_call(:queen2d, [1, :_]), 1]}

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

  test "sum with function call syntax" do
    # Test sum(queen2d(:_, :_))
    sum_expr = {:sum, [], [DSL.func_call(:queen2d, [:_, :_])]}

    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum

    # Get the expression inside sum
    expr = elem(sum_expr, 2) |> hd()
    assert is_tuple(expr)
    assert elem(expr, 0) == :queen2d
    assert elem(expr, 2) == [:_, :_]
  end

  test "mixed syntax approaches" do
    # Test that we can mix different approaches
    func_expr = DSL.func_call(:queen2d, [1, :_])
    helper_expr = DSL.var_helper("queen3d", [1, 2, 3])
    single_expr = DSL.single_bracket(:qty, [:food])

    # All should create proper AST
    assert elem(func_expr, 0) == :queen2d
    assert elem(helper_expr, 0) == :queen3d
    assert elem(single_expr, 0) == :qty

    # All should have proper indices
    assert elem(func_expr, 2) == [1, :_]
    assert elem(helper_expr, 2) == [1, 2, 3]
    assert elem(single_expr, 2) == [:food]
  end
end
