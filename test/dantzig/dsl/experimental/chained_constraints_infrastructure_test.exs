defmodule Dantzig.DSL.ChainedConstraintsInfrastructureTest do
  @moduledoc """
  Test that the chained constraints infrastructure works.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "chained constraints infrastructure works with simple expressions" do
    # Test that the basic chained constraint infrastructure works
    limits_names = ["calories", "protein", "fat"]

    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["hamburger", "chicken"]]}],
        :continuous,
        description: "Test variables"
      )

    # Test with a simple constraint expression that doesn't use sum
    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, limits_names]}],
        # Simple constraint: 1 <= 2
        {:<=, [], [1, 2]},
        "Test constraint for #{:l_name}"
      )

    # Should create multiple constraints
    assert result.name == "test"
    # One for each limit name
    assert map_size(result.constraints) == 3

    # Check that we have constraints for each limit name
    constraints = Map.values(result.constraints)
    names = Enum.map(constraints, & &1.name)

    # Should have interpolated names
    assert "Test constraint for l_name_calories" in names
    assert "Test constraint for l_name_protein" in names
    assert "Test constraint for l_name_fat" in names
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

    result =
      DSL.constraints(
        problem,
        generators,
        # Simple constraint
        {:<=, [], [1, 2]},
        "Test constraint for #{:l_name} and #{:food}"
      )

    # Should create constraints for each combination
    assert result.name == "test"
    # 2 limits × 2 foods
    assert map_size(result.constraints) == 4

    # Check names
    constraints = Map.values(result.constraints)
    names = Enum.map(constraints, & &1.name)

    # Should have combinations like "Test constraint for l_name and food_calories_hamburger"
    assert "Test constraint for l_name and food_calories_hamburger" in names
    assert "Test constraint for l_name and food_calories_chicken" in names
    assert "Test constraint for l_name and food_protein_hamburger" in names
    assert "Test constraint for l_name and food_protein_chicken" in names
  end

  test "chained constraints with empty generator list" do
    # Test edge case: empty generator list
    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, ["hamburger"]]}], :continuous,
        description: "Test variables"
      )

    result =
      DSL.constraints(
        problem,
        [],
        # Simple constraint
        {:<=, [], [1, 2]},
        "No generators"
      )

    # Should create one constraint
    assert result.name == "test"
    assert map_size(result.constraints) == 1

    # Check name
    constraints = Map.values(result.constraints)
    names = Enum.map(constraints, & &1.name)
    assert "No generators_" in names
  end

  test "chained constraints with single element generator" do
    # Test edge case: single element generator
    problem =
      Problem.new(name: "test")
      |> Problem.variables("qty", [{:<-, [], [{:food, [], nil}, ["hamburger"]]}], :continuous,
        description: "Test variables"
      )

    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:l_name, [], nil}, ["single"]]}],
        # Simple constraint
        {:<=, [], [1, 2]},
        "Single generator: #{:l_name}"
      )

    # Should create one constraint
    assert result.name == "test"
    assert map_size(result.constraints) == 1

    # Check name
    constraints = Map.values(result.constraints)
    names = Enum.map(constraints, & &1.name)
    assert "Single generator: l_name_single" in names
  end

  test "chained constraints with complex generator ranges" do
    # Test with more complex generator ranges
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "qty",
        [{:<-, [], [{:food, [], nil}, ["hamburger", "chicken", "pizza"]]}],
        :continuous,
        description: "Test variables"
      )

    # Test with range generators
    generators = [
      # Range generator
      {:<-, [], [{:i, [], nil}, 1..3]},
      # List generator
      {:<-, [], [{:food, [], nil}, ["hamburger", "chicken"]]}
    ]

    result =
      DSL.constraints(
        problem,
        generators,
        # Simple constraint
        {:<=, [], [1, 2]},
        "Constraint #{:i} for #{:food}"
      )

    # Should create constraints for each combination: 3 × 2 = 6 constraints
    assert result.name == "test"
    assert map_size(result.constraints) == 6

    # Check names
    constraints = Map.values(result.constraints)
    names = Enum.map(constraints, & &1.name)

    # Should have combinations like "Constraint i for food_1_hamburger"
    assert "Constraint i for food_1_hamburger" in names
    assert "Constraint i for food_1_chicken" in names
    assert "Constraint i for food_2_hamburger" in names
    assert "Constraint i for food_2_chicken" in names
    assert "Constraint i for food_3_hamburger" in names
    assert "Constraint i for food_3_chicken" in names
  end
end
