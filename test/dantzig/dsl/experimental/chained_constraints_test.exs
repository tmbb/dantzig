defmodule Dantzig.DSL.ChainedConstraintsTest do
  @moduledoc """
  Test chained constraints implementation.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "chained constraints with simple iteration" do
    # Test the basic chained constraint pattern
    # DSL.constraints([l_name <- limits_names], constraint_expr, description)

    limits_names = ["calories", "protein", "fat"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["hamburger", "chicken"]]}],
        :continuous,
        description: "Test variables"
      )

    # Test chained constraints
    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, limits_names]}],
        {:<=, [],
         [
           {:sum, [], [{:qty, [], [{:food, [], nil}]}]},
           {:limits_dict, [], [{:l_name, [], nil}, "max"]}
         ]},
        "Test constraint for #{:l_name}"
      )

    # Should create multiple constraints
    assert result.name == "test"
    # One for each limit name
    assert map_size(result.constraints) == 3
  end

  test "chained constraints with complex expression" do
    # Test the more complex chained constraint from nqueens_dsl.exs
    limits_names = ["calories", "protein"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["hamburger", "chicken"]]}],
        :continuous,
        description: "Test variables"
      )

    # Test the complex constraint expression
    constraint_expr = {
      :<=,
      [],
      [
        {
          :sum,
          [],
          [
            {
              :*,
              [],
              [
                {:qty, [], [{:food, [], nil}]},
                {:foods_dict, [], [{:food, [], nil}, {:l_name, [], nil}]}
              ]
            }
          ]
        },
        {:limits_dict, [], [{:l_name, [], nil}, "max"]}
      ]
    }

    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, limits_names]}],
        constraint_expr,
        "Min and max #{:l_name}"
      )

    # Should create multiple constraints
    assert result.name == "test"
    # One for each limit name
    assert map_size(result.constraints) == 2
  end

  test "chained constraints with multiple generators" do
    # Test chained constraints with multiple generators
    limits_names = ["calories", "protein"]
    food_names = ["hamburger", "chicken"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, food_names]}], :continuous,
        description: "Test variables"
      )

    # Test with multiple generators
    generators = [
      {:<-, [], [{:l_name, [], nil}, limits_names]},
      {:<-, [], [{:food, [], nil}, food_names]}
    ]

    constraint_expr = {
      :<=,
      [],
      [
        {:qty, [], [{:food, [], nil}]},
        1
      ]
    }

    result = DSL.constraints(problem, generators, constraint_expr, "Test constraint")

    # Should create constraints for each combination
    assert result.name == "test"
    # 2 limits × 2 foods
    assert map_size(result.constraints) == 4
  end

  test "chained constraints with nested sum" do
    # Test chained constraints with nested sum expressions
    limits_names = ["calories"]
    food_names = ["hamburger", "chicken"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, food_names]}], :continuous,
        description: "Test variables"
      )

    # Test with nested sum
    constraint_expr = {
      :<=,
      [],
      [
        {
          :sum,
          [],
          [
            {
              :*,
              [],
              [
                {:qty, [], [{:food, [], nil}]},
                {:foods_dict, [], [{:food, [], nil}, {:l_name, [], nil}]}
              ]
            }
          ]
        },
        {:limits_dict, [], [{:l_name, [], nil}, "max"]}
      ]
    }

    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, limits_names]}],
        constraint_expr,
        "Nested sum constraint"
      )

    # Should create one constraint
    assert result.name == "test"
    assert map_size(result.constraints) == 1
  end

  test "chained constraints with variable interpolation in description" do
    # Test that variable interpolation works in description
    limits_names = ["calories", "protein"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, ["hamburger"]]}], :continuous,
        description: "Test variables"
      )

    # Test with variable interpolation in description
    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, limits_names]}],
        {:<=, [], [{:qty, [], [{:food, [], nil}]}, 1]},
        "Constraint for #{:l_name}"
      )

    # Should create multiple constraints with interpolated descriptions
    assert result.name == "test"
    assert map_size(result.constraints) == 2

    # Check that constraints have different descriptions
    constraints = Map.values(result.constraints)
    descriptions = Enum.map(constraints, & &1.description)

    # Should have interpolated descriptions
    assert "Constraint for calories" in descriptions
    assert "Constraint for protein" in descriptions
  end

  test "chained constraints edge cases" do
    # Test edge cases for chained constraints

    # Empty generator list
    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, ["hamburger"]]}], :continuous,
        description: "Test variables"
      )

    result =
      DSL.constraints(
        problem,
        [],
        {:<=, [], [{:qty, [], [{:food, [], nil}]}, 1]},
        "No generators"
      )

    # Should create one constraint
    assert result.name == "test"
    assert map_size(result.constraints) == 1

    # Single element generator
    result2 =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, ["single"]]}],
        {:<=, [], [{:qty, [], [{:food, [], nil}]}, 1]},
        "Single generator"
      )

    # Should create one constraint
    assert result2.name == "test"
    assert map_size(result2.constraints) == 1
  end
end
