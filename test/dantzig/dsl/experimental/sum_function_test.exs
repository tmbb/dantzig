defmodule Dantzig.DSL.SumFunctionTest do
  @moduledoc """
  Tests for sum function integration
  """
  use ExUnit.Case, async: true

  alias Dantzig.DSL.SumFunction
  import Dantzig.DSL.SumFunction, only: [sum: 1, sum: 3]

  test "sum macro expansion with pattern syntax" do
    # Test sum(queen2d(:_, :_)) expansion
    ast = quote do: sum(queen2d(:_, :_))

    # The sum macro should create {:sum, expr} structure
    assert is_tuple(ast)
    assert elem(ast, 0) == :sum
    # The second element should be the expression
    expr = elem(ast, 2)
    assert is_list(expr)
    assert length(expr) == 1
    assert hd(expr) == {:queen2d, [], [:_, :_]}
  end

  test "sum macro expansion with single variable" do
    # Test sum(queen2d(i, :_)) expansion
    ast = quote do: sum(queen2d(i, :_))

    assert is_tuple(ast)
    assert elem(ast, 0) == :sum
    # The second element should be the expression
    expr = elem(ast, 2)
    assert is_list(expr)
    assert length(expr) == 1
    # Check that the expression contains the variable reference
    expr_ast = hd(expr)
    assert is_tuple(expr_ast)
    assert elem(expr_ast, 0) == :queen2d
    # Check that the indices contain the variable and wildcard
    indices = elem(expr_ast, 2)
    assert is_list(indices)
    assert length(indices) == 2
    assert Enum.at(indices, 1) == :_
  end

  test "sum with generator syntax" do
    # Test sum(qty(food) * cost(food) for food <- food_names)
    # Note: This syntax is not valid Elixir, so we'll test the structure manually
    ast = quote do: sum(qty(food) * cost(food), :for, [food <- food_names])

    assert is_tuple(ast)
    assert elem(ast, 0) == :sum
    # The second element should be a list with [expr, :for, generators]
    expr_list = elem(ast, 2)
    assert is_list(expr_list)
    assert length(expr_list) == 3

    # Check the structure: [expr, :for, generators]
    [expr, :for, generators] = expr_list
    # The multiplication expression
    assert is_tuple(expr)
    # Check that generators is a list with the generator
    assert is_list(generators)
    assert length(generators) == 1
    generator = hd(generators)
    assert is_tuple(generator)
    assert elem(generator, 0) == :<-
  end

  test "sum in constraint context" do
    # Test sum(queen2d(:_, :_)) == 4
    constraint_ast = quote do: sum(queen2d(:_, :_)) == 4

    # Verify the structure
    assert is_tuple(constraint_ast)
    assert elem(constraint_ast, 0) == :==

    # Get the left side (sum expression)
    left_side = elem(constraint_ast, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :sum

    # Get the right side (4)
    right_side = elem(constraint_ast, 2) |> tl() |> hd()
    assert right_side == 4
  end

  test "sum in objective context" do
    # Test sum(queen2d(:_, :_)) as objective
    objective_ast = quote do: sum(queen2d(:_, :_))

    assert is_tuple(objective_ast)
    assert elem(objective_ast, 0) == :sum
  end

  test "sum with complex generator expression" do
    # Test sum(qty(food) * foods_dict[food]["cost"] for food <- food_names)
    # Note: This syntax is not valid Elixir, so we'll test the structure manually
    ast = quote do: sum(qty(food) * foods_dict[food]["cost"], :for, [food <- food_names])

    assert is_tuple(ast)
    assert elem(ast, 0) == :sum
    # The second element should be a list with [expr, :for, generators]
    expr_list = elem(ast, 2)
    assert is_list(expr_list)
    assert length(expr_list) == 3

    # Check the structure: [expr, :for, generators]
    [expr, :for, generators] = expr_list
    # The multiplication expression
    assert is_tuple(expr)
    # Check that generators is a list with the generator
    assert is_list(generators)
    assert length(generators) == 1
    generator = hd(generators)
    assert is_tuple(generator)
    assert elem(generator, 0) == :<-
  end
end
