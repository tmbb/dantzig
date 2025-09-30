defmodule Dantzig.DSL.ValidSyntaxTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  test "Valid syntax - using quoted expressions" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Valid Test", description: "Test valid syntax")

        # Use the raw generator syntax
        variables("qty", [food <- food_names], :continuous, "Amount of food")
      end

    assert map_size(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end
end
