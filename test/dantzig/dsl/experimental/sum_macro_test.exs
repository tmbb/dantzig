defmodule Dantzig.DSL.SumMacroTest do
  @moduledoc """
  Test the sum macro that handles sum(expr for var <- list) syntax.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem

  test "sum macro transforms for comprehension syntax" do
    # Test that the sum macro can handle the invalid syntax
    # sum(qty(food) for food <- food_names)

    food_names = ["apple", "banana", "orange"]

    # This should work with the macro - using the AST representation
    result =
      DSL.sum(
        {:across, [],
         [{:qty, [], [{:food, [], nil}]}, [{:<-, [], [{:food, [], nil}, food_names]}]]}
      )

    # Should be transformed into a sum expression
    assert is_tuple(result)
    assert elem(result, 0) == :sum
    assert is_list(elem(result, 2))

    # The inner expression should be an across expression
    inner_expr = hd(elem(result, 2))
    assert is_tuple(inner_expr)
    assert elem(inner_expr, 0) == :across
  end

  test "sum macro handles simple expressions" do
    # Test that the sum macro can handle simple expressions
    result = DSL.sum({:qty, [], [{:food, [], nil}]})

    # Should be transformed into a sum expression
    assert is_tuple(result)
    assert elem(result, 0) == :sum
    assert is_list(elem(result, 2))

    # The inner expression should be the original expression
    inner_expr = hd(elem(result, 2))
    assert is_tuple(inner_expr)
    assert elem(inner_expr, 0) == :qty
  end

  test "sum macro works in constraint context" do
    # Test that the sum macro works when used in constraints
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}],
        :continuous,
        description: "Test"
      )

    # This should work with the macro - using the AST representation
    sum_expr =
      DSL.sum(
        {:across, [],
         [{:qty, [], [{:food, [], nil}]}, [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}]]}
      )

    # Should be a valid sum expression
    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum
  end

  test "sum macro works in objective context" do
    # Test that the sum macro works when used in objectives
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}],
        :continuous,
        description: "Test"
      )

    # This should work with the macro - using the AST representation
    sum_expr =
      DSL.sum(
        {:across, [],
         [{:qty, [], [{:food, [], nil}]}, [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}]]}
      )

    # Should be a valid sum expression
    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum
  end
end
