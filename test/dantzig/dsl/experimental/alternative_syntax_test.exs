defmodule Dantzig.DSL.AlternativeSyntaxTest do
  use ExUnit.Case, async: true
  import Dantzig.Problem.DSL

  test "Alternative syntax - using for comprehension directly" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Alternative Test", description: "Test alternative syntax")

        # Use for comprehension directly in variables
        for food <- food_names do
          variables("qty", [food], :continuous, "Amount of food")
        end
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end

  test "Alternative syntax - using explicit variable creation" do
    food_names = ["bread", "milk"]

    problem =
      Problem.define do
        new(name: "Explicit Test", description: "Test explicit variable creation")

        # Create variables explicitly
        variables("qty_bread", [], :continuous, "Amount of bread")
        variables("qty_milk", [], :continuous, "Amount of milk")
      end

    assert length(problem.variable_defs) == 2
    assert Map.has_key?(problem.variable_defs, "qty_bread")
    assert Map.has_key?(problem.variable_defs, "qty_milk")
  end
end
