defmodule Dantzig.DSL.GeneratorSyntaxTest do
  @moduledoc """
  Test the generator syntax macro that handles [i <- 1..4, j <- 1..4] format.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "generator syntax macro works" do
    # Test that the generators macro can handle the invalid syntax
    # We need to use a different approach - test with actual AST
    generators =
      DSL.generators([{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}])

    # Should transform to proper AST format
    assert is_list(generators)
    assert length(generators) == 2

    # Check first generator
    first_gen = Enum.at(generators, 0)
    assert is_tuple(first_gen)
    assert elem(first_gen, 0) == :<-

    # Check second generator
    second_gen = Enum.at(generators, 1)
    assert is_tuple(second_gen)
    assert elem(second_gen, 0) == :<-
  end

  test "DSL.variables macro handles generator syntax" do
    # Test that DSL.variables can accept the [i <- 1..4, j <- 1..4] syntax
    problem = Problem.new(name: "test")

    # This should work with the generator syntax - use proper AST
    result =
      DSL.variables(
        problem,
        "x",
        [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}],
        :binary,
        description: "Test variables"
      )

    # Verify the result
    assert result.name == "test"
    x_vars = Problem.get_variables_nd(result, "x")
    assert x_vars != nil
    # 4x4 = 16 variables
    assert map_size(x_vars) == 16
  end

  test "DSL.constraints macro handles generator syntax" do
    # Test that DSL.constraints can accept the [i <- 1..4] syntax
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "x",
        [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}],
        :binary,
        description: "Test variables"
      )

    # This should work with the generator syntax - use proper AST
    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:i, [], nil}, 1..4]}],
        {:==, [], [{:x, [], [{:i, [], nil}, :_]}, 1]},
        "Test constraint"
      )

    # Verify the result
    assert result.name == "test"
    constraints = result.constraints
    # One constraint per i value
    assert map_size(constraints) == 4
  end

  test "DSL.objective macro works" do
    # Test that DSL.objective works
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "x",
        [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}],
        :binary,
        description: "Test variables"
      )

    # This should work
    result = DSL.objective(problem, {:sum, [], [{:x, [], [:_, :_]}]}, direction: :minimize)

    # Verify the result
    assert result.name == "test"
    assert result.direction == :minimize
    assert result.objective != nil
  end
end
