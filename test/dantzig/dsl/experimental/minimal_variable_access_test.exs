defmodule Dantzig.DSL.MinimalVariableAccessTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  test "Minimal variable access without arithmetic" do
    food_names = ["bread"]
    
    problem = Problem.define do
      new(name: "Minimal Test", description: "Test basic variable access")
      variables("qty", [food <- food_names], :continuous, "Amount of food")
      objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
    end
    
    assert problem.direction == :minimize
    assert problem.objective != nil
  end

  test "Minimal variable access with constant multiplication" do
    food_names = ["bread"]
    
    problem = Problem.define do
      new(name: "Minimal Test", description: "Test variable * constant")
      variables("qty", [food <- food_names], :continuous, "Amount of food")
      objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
    end
    
    assert problem.direction == :minimize
    assert problem.objective != nil
  end
end
