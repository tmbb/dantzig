defmodule Dantzig.DSL.Core.DSLComprehensiveTest do
  @moduledoc """
  Comprehensive test suite for the Dantzig DSL functionality.

  This test suite covers all core DSL features in a progressive manner:
  - Level 1: Basic variable creation and access
  - Level 2: Variable access with arithmetic operations
  - Level 3: Complex arithmetic expressions
  - Level 4: Edge cases and error handling
  - Level 5: Regression tests for existing functionality
  - Level 6: Known limitations and future work

  Each test is designed to be:
  - Self-contained and isolated
  - Well-documented with clear error messages
  - Progressive in complexity
  - Protective against regressions
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  # Test data setup - comprehensive data for all test scenarios
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

  describe "Level 1: Basic Variable Creation and Access" do
    @tag :basic
    test "Simple variable creation with string names", %{food_names: food_names} do
      # Test: Create variables using generator syntax [food <- food_names]
      # Expected: 6 variables created with names like "qty_bread", "qty_milk", etc.
      # Error context: If this fails, check generator syntax parsing in Problem.define

      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test basic variable creation")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
        end

      assert map_size(problem.variable_defs) == 6,
             "Expected 6 variables (one per food), got #{map_size(problem.variable_defs)}"

      # Verify all expected variables exist
      expected_vars = [
        "qty_bread",
        "qty_milk",
        "qty_cheese",
        "qty_potato",
        "qty_fish",
        "qty_yogurt"
      ]

      for var_name <- expected_vars do
        assert Map.has_key?(problem.variable_defs, var_name),
               "Missing variable: #{var_name}. Available: #{Map.keys(problem.variable_defs)}"
      end
    end

    @tag :basic
    test "N-Queens variable creation with multi-dimensional indices" do
      # Test: Create variables with multiple generator dimensions [i <- 1..2, j <- 1..2]
      # Expected: 4 variables created with names like "queen2d_1_1", "queen2d_1_2", etc.
      # Error context: If this fails, check multi-dimensional generator parsing

      problem =
        Problem.define do
          new(name: "N-Queens", description: "Test N-Queens variables")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
        end

      assert map_size(problem.variable_defs) == 4,
             "Expected 4 variables (2x2 grid), got #{map_size(problem.variable_defs)}"

      # Verify all expected variables exist
      expected_vars = ["queen2d_1_1", "queen2d_1_2", "queen2d_2_1", "queen2d_2_2"]

      for var_name <- expected_vars do
        assert Map.has_key?(problem.variable_defs, var_name),
               "Missing variable: #{var_name}. Available: #{Map.keys(problem.variable_defs)}"
      end
    end

    @tag :basic
    test "Simple variable access without arithmetic", %{food_names: food_names} do
      # Test: Access variables in sum expressions without arithmetic operations
      # Expected: Objective created successfully with sum of all variables
      # Error context: If this fails, check variable access resolution in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Simple Variable Access", description: "Test basic variable access")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Level 2: Variable Access with Arithmetic Operations" do
    @tag :arithmetic
    test "Variable access with constant multiplication", %{food_names: food_names} do
      # Test: qty(food) * 1.0 - basic multiplication of variable by constant
      # Expected: Objective created successfully
      # Error context: If this fails, check arithmetic pattern matching in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Variable with Constant", description: "Test variable * constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    @tag :arithmetic
    test "Variable access with constant addition", %{food_names: food_names} do
      # Test: qty(food) + 1.0 - basic addition of variable and constant
      # Expected: Objective created successfully
      # Error context: If this fails, check addition pattern matching

      problem =
        Problem.define do
          new(name: "Variable with Addition", description: "Test variable + constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    @tag :arithmetic
    test "Variable access with constant subtraction", %{food_names: food_names} do
      # Test: qty(food) - 1.0 - basic subtraction of constant from variable
      # Expected: Objective created successfully
      # Error context: If this fails, check subtraction pattern matching

      problem =
        Problem.define do
          new(name: "Variable with Subtraction", description: "Test variable - constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) - 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    @tag :arithmetic
    test "Variable access with constant division", %{food_names: food_names} do
      # Test: qty(food) / 2.0 - basic division of variable by constant
      # Expected: Objective created successfully
      # Error context: If this fails, check division pattern matching

      problem =
        Problem.define do
          new(name: "Variable with Division", description: "Test variable / constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) / 2.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Level 3: Complex Arithmetic Expressions" do
    @tag :complex
    test "Complex arithmetic expression with multiple operations", %{food_names: food_names} do
      # Test: qty(food) * 2.0 + 1.0 - complex expression with multiplication and addition
      # Expected: Objective created successfully
      # Error context: If this fails, check complex arithmetic expression parsing

      problem =
        Problem.define do
          new(name: "Complex Arithmetic", description: "Test complex arithmetic")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 2.0 + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Level 4: Edge Cases and Error Handling" do
    @tag :edge_cases
    test "Empty food list with arithmetic operations" do
      # Test: Handle empty generator lists gracefully
      # Expected: Problem created successfully with empty objective
      # Error context: If this fails, check empty list handling in sum expressions

      problem =
        Problem.define do
          new(name: "Empty List", description: "Test empty list")
          variables("qty", [food <- []], :continuous, "Amount of food")
          objective(sum(for food <- [], do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    @tag :edge_cases
    test "Zero coefficient multiplication" do
      # Test: Handle zero coefficients in arithmetic operations
      # Expected: Problem created successfully
      # Error context: If this fails, check zero coefficient handling

      problem =
        Problem.define do
          new(name: "Zero Coefficient", description: "Test zero coefficient")
          variables("qty", [food <- ["bread"]], :continuous, "Amount of food")
          objective(sum(for food <- ["bread"], do: qty(food) * 0.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    @tag :edge_cases
    test "Single food item with arithmetic" do
      # Test: Handle single-item generators
      # Expected: Problem created successfully
      # Error context: If this fails, check single-item generator handling

      problem =
        Problem.define do
          new(name: "Single Food", description: "Test single food")
          variables("qty", [food <- ["bread"]], :continuous, "Amount of food")
          objective(sum(for food <- ["bread"], do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Level 5: Regression Tests for Existing Functionality" do
    @tag :regression
    test "N-Queens 2D problem complete workflow" do
      # Test: Complete N-Queens 2D problem with variables, constraints, and objective
      # Expected: Problem created successfully with correct structure
      # Error context: If this fails, check N-Queens functionality regression

      problem =
        Problem.define do
          new(name: "N-Queens 2D", description: "Complete N-Queens 2D problem")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
          constraints([j <- 1..2], sum(queen2d(:_, j)) == 1, "One queen per column")
          objective(sum(queen2d(:_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert map_size(problem.variable_defs) == 4,
             "Expected 4 variables (2x2 grid), got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 4,
             "Expected 4 constraints (2 rows + 2 columns), got #{map_size(problem.constraints)}"
    end

    @tag :regression
    test "N-Queens 3D problem complete workflow" do
      # Test: Complete N-Queens 3D problem with variables, constraints, and objective
      # Expected: Problem created successfully with correct structure
      # Error context: If this fails, check N-Queens 3D functionality regression

      problem =
        Problem.define do
          new(name: "N-Queens 3D", description: "Complete N-Queens 3D problem")
          variables("queen3d", [i <- 1..2, j <- 1..2, k <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2, k <- 1..2], sum(queen3d(i, :_, k)) == 1, "One queen per row")
          constraints([j <- 1..2, k <- 1..2], sum(queen3d(:_, j, k)) == 1, "One queen per column")
          objective(sum(queen3d(:_, :_, :_)), direction: :maximize)
        end

      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert map_size(problem.variable_defs) == 8,
             "Expected 8 variables (2x2x2 grid), got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 8,
             "Expected 8 constraints (4 rows + 4 columns), got #{map_size(problem.constraints)}"
    end
  end

  describe "Level 6: Known Limitations and Future Work" do
    @tag :limitations
    test "Map access in for comprehensions - currently unsupported", %{
      food_names: food_names,
      foods: foods
    } do
      # Test: Document the current limitation with map access in for comprehensions
      # Expected: This should fail with a clear error message
      # Error context: This documents the known limitation that needs to be fixed
      #
      # The issue is that expressions like foods[food]["cost"] don't work because:
      # 1. The 'food' variable is bound in the for comprehension
      # 2. The evaluate_expression function doesn't have access to these bindings
      # 3. This requires fixing the binding resolution in evaluate_expression

      assert_raise CompileError, fn ->
        Problem.define do
          new(name: "Map Access Test", description: "Test map access limitation")
          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
            direction: :minimize
          )
        end
      end
    end

    @tag :limitations
    test "Document the map access limitation for future implementation", %{
      food_names: food_names,
      foods: foods
    } do
      # Test: Document what needs to be implemented next
      # Expected: This should fail with a clear error message
      # Error context: This documents the specific issue that needs to be resolved
      #
      # Future work required:
      # 1. Fix binding resolution in evaluate_expression to handle for comprehension bindings
      # 2. Ensure map access like foods[food]["cost"] works correctly
      # 3. Maintain backward compatibility with existing functionality

      assert_raise CompileError, fn ->
        Problem.define do
          new(name: "Future Map Access", description: "Test future map access implementation")
          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
            direction: :minimize
          )
        end
      end
    end
  end
end
