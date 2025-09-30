defmodule Dantzig.DSL.SimpleGeneratorTest do
  use ExUnit.Case, async: true
  import Dantzig.Problem.DSL

  test "Simple generator syntax" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator syntax")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end

  test "Generator with objective" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Simple Test", description: "Test generator with objective")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
      end

    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
