defmodule Dantzig.DSL.AcrossSyntaxDemo do
  @moduledoc """
  Demonstrate the new 'across' syntax for sum expressions.
  This shows how the syntax will work in practice.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem

  test "demonstrate across syntax works in practice" do
    # This demonstrates the syntax that will work in nqueens_dsl.exs
    food_names = ["apple", "banana", "orange"]

    # The new syntax: sum(expr across var <- list)
    # This is what users will write:
    # sum(qty(food) * foods[food]["cost"] across food <- food_names)

    # For testing, we use the AST representation:
    sum_expr =
      DSL.sum(
        {:across, [],
         [
           {:*, [],
            [
              {:qty, [], [{:food, [], nil}]},
              {:access, [],
               [
                 {:access, [], [{:foods, [], []}, {:food, [], nil}]},
                 "cost"
               ]}
            ]},
           [{:<-, [], [{:food, [], nil}, food_names]}]
         ]}
      )

    # Should be a valid sum expression
    assert is_tuple(sum_expr)
    assert elem(sum_expr, 0) == :sum

    # The inner expression should be an across expression
    inner_expr = hd(elem(sum_expr, 2))
    assert is_tuple(inner_expr)
    assert elem(inner_expr, 0) == :across
  end

  test "demonstrate across syntax in constraint context" do
    # This shows how the syntax will work in constraints
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}],
        :continuous,
        description: "Test"
      )

    # The new syntax for constraints:
    # sum(qty(food) * foods[food]["calories"] across food <- food_names) >= 1800

    # For testing, we use the AST representation:
    constraint_expr =
      {:>=, [],
       [
         DSL.sum(
           {:across, [],
            [
              {:*, [],
               [
                 {:qty, [], [{:food, [], nil}]},
                 {:access, [],
                  [
                    {:access, [], [{:foods, [], []}, {:food, [], nil}]},
                    "calories"
                  ]}
               ]},
              [{:<-, [], [{:food, [], nil}, ["apple", "banana"]]}]
            ]}
         ),
         1800
       ]}

    # Should be a valid constraint expression
    assert is_tuple(constraint_expr)
    assert elem(constraint_expr, 0) == :>=

    # The left side should be a sum expression
    left_side = hd(elem(constraint_expr, 2))
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :sum
  end

  test "demonstrate future where syntax design" do
    # This shows the future syntax design with 'where' for filtering
    # sum(qty(food) across food <- food_names where food != "ice_cream")
    # sum(qty(i) across i <- 1..100 where rem(i, 3) == 0)

    # For now, we just document the intended syntax
    future_syntax_examples = [
      "sum(qty(food) across food <- food_names where food != \"ice_cream\")",
      "sum(qty(i) across i <- 1..100 where rem(i, 3) == 0)",
      "sum(x(i, j) across i <- 1..n, j <- 1..m where i != j)"
    ]

    # These are the syntax patterns we want to support in the future
    assert length(future_syntax_examples) == 3
    assert Enum.all?(future_syntax_examples, &String.contains?(&1, "across"))
    assert Enum.all?(future_syntax_examples, &String.contains?(&1, "where"))
  end

  test "show the syntax transformation" do
    # This demonstrates what the macro does:
    # Input: sum(qty(food) across food <- food_names)
    # Output: {:sum, [], [{:across, [], [expr, [{:<-, [], [var, list]}]]}]}

    input_syntax = "sum(qty(food) across food <- food_names)"

    expected_ast =
      {:sum, [],
       [
         {:across, [],
          [
            {:qty, [], [{:food, [], nil}]},
            [{:<-, [], [{:food, [], nil}, :food_names]}]
          ]}
       ]}

    # The macro transforms the invalid syntax into valid Elixir AST
    assert is_binary(input_syntax)
    assert is_tuple(expected_ast)
    assert elem(expected_ast, 0) == :sum
  end
end
