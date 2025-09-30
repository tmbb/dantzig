defmodule Dantzig.DSL.VariableAccessDebugTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  test "Debug variable access in arithmetic" do
    food_names = ["bread", "milk"]
    
    problem = Problem.define do
      new(name: "Debug Test", description: "Debug variable access")
      
      variables("qty", [food <- food_names], :continuous, "Amount of food")
      objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
    end
    
    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
