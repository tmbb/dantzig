defmodule Dantzig.DSL.VariableAccessArithmeticTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  describe "Variable Access in Arithmetic Operations" do
    test "Level 1: Simple variable access without arithmetic" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Simple Variable Access", description: "Test basic variable access")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 2: Variable access with constant multiplication" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Variable Access with Constant", description: "Test variable * constant")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 3: Variable access with constant addition" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Variable Access with Addition", description: "Test variable + constant")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) + 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 4: Variable access with constant subtraction" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Variable Access with Subtraction", description: "Test variable - constant")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) - 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 5: Variable access with constant division" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Variable Access with Division", description: "Test variable / constant")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) / 2.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 6: Multiple variables with arithmetic" do
      food_names = ["bread", "milk"]
      
      problem = Problem.define do
        new(name: "Multiple Variables with Arithmetic", description: "Test multiple variables")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 7: Complex arithmetic expression" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Complex Arithmetic", description: "Test complex arithmetic")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) * 2.0 + 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 8: Variable access with map access" do
      food_names = ["bread"]
      foods = %{"bread" => %{"cost" => 0.5}}
      
      problem = Problem.define do
        new(name: "Variable with Map Access", description: "Test variable * map access")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 9: Regression test - N-Queens still works" do
      problem = Problem.define do
        new(name: "N-Queens Regression", description: "Ensure N-Queens still works")
        variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
        objective(sum(queen2d(:_, :_)), direction: :maximize)
      end
      
      assert problem.direction == :maximize
      assert map_size(problem.variable_defs) == 4
      assert map_size(problem.constraints) == 2
    end
  end

  describe "Error Cases and Edge Cases" do
    test "Empty food list with arithmetic" do
      problem = Problem.define do
        new(name: "Empty List", description: "Test empty list")
        variables("qty", [food <- []], :continuous, "Amount of food")
        objective(sum(for food <- [], do: qty(food) * 1.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Zero coefficient multiplication" do
      food_names = ["bread"]
      
      problem = Problem.define do
        new(name: "Zero Coefficient", description: "Test zero coefficient")
        variables("qty", [food <- food_names], :continuous, "Amount of food")
        objective(sum(for food <- food_names, do: qty(food) * 0.0), direction: :minimize)
      end
      
      assert problem.direction == :minimize
      assert problem.objective != nil
    end
  end
end
