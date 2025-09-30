defmodule Dantzig.DSL.ComprehensiveDSLTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  # Test data setup
  setup do
    food_names = ["bread", "milk", "cheese", "potato", "fish", "yogurt"]

    foods = %{
      "bread" => %{"cost" => 0.5, "calories" => 200, "protein" => 10, "calcium" => 20},
      "milk" => %{"cost" => 0.3, "calories" => 150, "protein" => 8, "calcium" => 250},
      "cheese" => %{"cost" => 0.8, "calories" => 300, "protein" => 20, "calcium" => 400},
      "potato" => %{"cost" => 0.2, "calories" => 80, "protein" => 2, "calcium" => 10},
      "fish" => %{"cost" => 1.0, "calories" => 120, "protein" => 25, "calcium" => 50},
      "yogurt" => %{"cost" => 0.8, "calories" => 120, "protein" => 12, "calcium" => 200}
    }

    foods_dict = foods
    limits_names = ["calories", "protein", "calcium"]

    limits_dict = %{
      "calories" => %{"min" => 2000, "max" => 3000},
      "protein" => %{"min" => 100, "max" => 150},
      "calcium" => %{"min" => 800, "max" => 1200}
    }

    {:ok,
     %{
       food_names: food_names,
       foods: foods,
       foods_dict: foods_dict,
       limits_names: limits_names,
       limits_dict: limits_dict
     }}
  end

  describe "Level 1: Basic Variable Creation" do
    test "Simple variable creation with string names", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test basic variable creation")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
        end

      assert map_size(problem.variable_defs) == 6
      assert Map.has_key?(problem.variable_defs, "qty_bread")
      assert Map.has_key?(problem.variable_defs, "qty_milk")
      assert Map.has_key?(problem.variable_defs, "qty_cheese")
      assert Map.has_key?(problem.variable_defs, "qty_potato")
      assert Map.has_key?(problem.variable_defs, "qty_fish")
      assert Map.has_key?(problem.variable_defs, "qty_yogurt")
    end

    test "N-Queens variable creation still works" do
      problem =
        Problem.define do
          new(name: "N-Queens", description: "Test N-Queens variables")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        end

      assert map_size(problem.variable_defs) == 4
      assert Map.has_key?(problem.variable_defs, "queen2d_1_1")
      assert Map.has_key?(problem.variable_defs, "queen2d_1_2")
      assert Map.has_key?(problem.variable_defs, "queen2d_2_1")
      assert Map.has_key?(problem.variable_defs, "queen2d_2_2")
    end
  end

  describe "Level 2: Basic Variable Access" do
    test "Simple variable access without arithmetic", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Simple Variable Access", description: "Test basic variable access")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "N-Queens variable access still works" do
      problem =
        Problem.define do
          new(name: "N-Queens Access", description: "Test N-Queens variable access")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
          objective(sum(queen2d(:_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize
      assert problem.objective != nil
    end
  end

  describe "Level 3: Variable Access with Arithmetic" do
    test "Variable access with constant multiplication", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Variable with Constant", description: "Test variable * constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Variable access with constant addition", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Variable with Addition", description: "Test variable + constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Variable access with constant subtraction", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Variable with Subtraction", description: "Test variable - constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) - 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Variable access with constant division", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Variable with Division", description: "Test variable / constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) / 2.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end
  end

  describe "Level 4: Complex Arithmetic Expressions" do
    test "Complex arithmetic expression", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Complex Arithmetic", description: "Test complex arithmetic")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 2.0 + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "N-Queens complex expressions still work" do
      problem =
        Problem.define do
          new(name: "N-Queens Complex", description: "Test N-Queens complex expressions")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
          objective(sum(queen2d(:_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize
      assert map_size(problem.variable_defs) == 4
      assert map_size(problem.constraints) == 2
    end
  end

  describe "Level 5: Map Access (Known Limitation)" do
    test "Map access in for comprehensions - currently fails", %{
      food_names: food_names,
      foods: foods
    } do
      # This test documents the current limitation
      # The issue is that map access like foods[food]["cost"] doesn't work
      # because the 'food' variable binding from the for comprehension
      # is not available in the evaluate_expression function

      assert_raise CompileError, fn ->
        Problem.define do
          new(name: "Map Access Test", description: "Test map access")
          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
            direction: :minimize
          )
        end
      end
    end
  end

  describe "Level 6: Edge Cases and Error Handling" do
    test "Empty food list with arithmetic" do
      problem =
        Problem.define do
          new(name: "Empty List", description: "Test empty list")
          variables("qty", [food <- []], :continuous, "Amount of food")
          objective(sum(for food <- [], do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Zero coefficient multiplication", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Zero Coefficient", description: "Test zero coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 0.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Single food item", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Single Food", description: "Test single food")
          variables("qty", [food <- ["bread"]], :continuous, "Amount of food")
          objective(sum(for food <- ["bread"], do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end
  end

  describe "Level 7: Regression Tests" do
    test "N-Queens 2D problem still works completely" do
      problem =
        Problem.define do
          new(name: "N-Queens 2D", description: "Complete N-Queens 2D problem")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
          constraints([j <- 1..2], sum(queen2d(:_, j)) == 1, "One queen per column")
          objective(sum(queen2d(:_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize
      assert map_size(problem.variable_defs) == 4
      assert map_size(problem.constraints) == 4
    end

    test "N-Queens 3D problem still works completely" do
      problem =
        Problem.define do
          new(name: "N-Queens 3D", description: "Complete N-Queens 3D problem")
          variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2, k <- 1..2], sum(queen3d(i, :_, k)) == 1, "One queen per row")
          constraints([j <- 1..2, k <- 1..2], sum(queen3d(:_, j, k)) == 1, "One queen per column")
          objective(sum(queen3d(:_, :_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize
      assert map_size(problem.variable_defs) == 8
      assert map_size(problem.constraints) == 8
    end
  end

  describe "Level 8: Future Work - Map Access" do
    test "Document the map access limitation", %{food_names: food_names, foods: foods} do
      # This test documents what we need to implement next
      # The issue is in the interaction between:
      # 1. For comprehension bindings (food <- food_names)
      # 2. Map access evaluation (foods[food]["cost"])
      # 3. The evaluate_expression function not having access to the for comprehension bindings

      # Current status: This fails with "undefined variable 'food'"
      # Future work: Need to fix the binding resolution in evaluate_expression
      # to handle variables bound in for comprehensions

      assert_raise CompileError, fn ->
        Problem.define do
          new(name: "Future Map Access", description: "Test future map access")
          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
            direction: :minimize
          )
        end
      end
    end
  end
end
