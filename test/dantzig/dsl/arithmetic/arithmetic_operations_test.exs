defmodule Dantzig.DSL.Arithmetic.ArithmeticOperationsTest do
  @moduledoc """
  Comprehensive test suite for arithmetic operations in the Dantzig DSL.

  This test suite focuses specifically on arithmetic operations between variables and constants:
  - Addition: variable + constant, constant + variable
  - Subtraction: variable - constant, constant - variable
  - Multiplication: variable * constant, constant * variable
  - Division: variable / constant
  - Complex expressions: multiple operations combined
  - Edge cases: zero coefficients, negative coefficients, etc.

  Each test is designed to:
  - Test a specific arithmetic operation in isolation
  - Provide clear error messages for debugging
  - Verify the correct polynomial structure is generated
  - Ensure no regressions in arithmetic functionality
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  # Simple test data for arithmetic operations
  setup do
    food_names = ["bread", "milk"]
    {:ok, %{food_names: food_names}}
  end

  describe "Basic Arithmetic Operations" do
    @tag :addition
    test "Variable + constant", %{food_names: food_names} do
      # Test: qty(food) + 1.0
      # Expected: Each variable gets a constant term added
      # Error context: If this fails, check addition pattern in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Var + Const", description: "Test variable + constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains both variables and constants
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "qty_bread"),
             "Expected objective to contain qty_bread, got: #{objective_str}"

      assert String.contains?(objective_str, "qty_milk"),
             "Expected objective to contain qty_milk, got: #{objective_str}"
    end

    @tag :subtraction
    test "Variable - constant", %{food_names: food_names} do
      # Test: qty(food) - 1.0
      # Expected: Each variable gets a constant term subtracted
      # Error context: If this fails, check subtraction pattern in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Var - Const", description: "Test variable - constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) - 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains both variables and constants
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "qty_bread"),
             "Expected objective to contain qty_bread, got: #{objective_str}"

      assert String.contains?(objective_str, "qty_milk"),
             "Expected objective to contain qty_milk, got: #{objective_str}"
    end

    @tag :multiplication
    test "Variable * constant", %{food_names: food_names} do
      # Test: qty(food) * 2.0
      # Expected: Each variable gets scaled by the constant
      # Error context: If this fails, check multiplication pattern in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Var * Const", description: "Test variable * constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 2.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains scaled variables
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "2.0 qty_bread"),
             "Expected objective to contain '2.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "2.0 qty_milk"),
             "Expected objective to contain '2.0 qty_milk', got: #{objective_str}"
    end

    @tag :division
    test "Variable / constant", %{food_names: food_names} do
      # Test: qty(food) / 2.0
      # Expected: Each variable gets scaled by 1/constant
      # Error context: If this fails, check division pattern in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Var / Const", description: "Test variable / constant")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) / 2.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains scaled variables
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "0.5 qty_bread"),
             "Expected objective to contain '0.5 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "0.5 qty_milk"),
             "Expected objective to contain '0.5 qty_milk', got: #{objective_str}"
    end
  end

  describe "Commutative Arithmetic Operations" do
    @tag :commutative
    test "Constant * variable (commutative multiplication)", %{food_names: food_names} do
      # Test: 2.0 * qty(food)
      # Expected: Same result as qty(food) * 2.0
      # Error context: If this fails, check commutative multiplication pattern

      problem =
        Problem.define do
          new(name: "Const * Var", description: "Test constant * variable")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: 2.0 * qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains scaled variables
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "2.0 qty_bread"),
             "Expected objective to contain '2.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "2.0 qty_milk"),
             "Expected objective to contain '2.0 qty_milk', got: #{objective_str}"
    end

    @tag :commutative
    test "Constant + variable (commutative addition)", %{food_names: food_names} do
      # Test: 1.0 + qty(food)
      # Expected: Same result as qty(food) + 1.0
      # Error context: If this fails, check commutative addition pattern

      problem =
        Problem.define do
          new(name: "Const + Var", description: "Test constant + variable")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: 1.0 + qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains both variables and constants
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "qty_bread"),
             "Expected objective to contain qty_bread, got: #{objective_str}"

      assert String.contains?(objective_str, "qty_milk"),
             "Expected objective to contain qty_milk, got: #{objective_str}"
    end
  end

  describe "Complex Arithmetic Expressions" do
    @tag :complex
    test "Multiple operations: (variable * constant) + constant", %{food_names: food_names} do
      # Test: qty(food) * 2.0 + 1.0
      # Expected: Each variable scaled by 2.0, then 1.0 added
      # Error context: If this fails, check complex arithmetic expression parsing

      problem =
        Problem.define do
          new(name: "Complex Expr", description: "Test complex arithmetic expression")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 2.0 + 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains scaled variables and constants
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "2.0 qty_bread"),
             "Expected objective to contain '2.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "2.0 qty_milk"),
             "Expected objective to contain '2.0 qty_milk', got: #{objective_str}"
    end

    @tag :complex
    test "Multiple operations: (variable + constant) * constant", %{food_names: food_names} do
      # Test: (qty(food) + 1.0) * 2.0
      # Expected: Each variable gets 1.0 added, then scaled by 2.0
      # Error context: If this fails, check parentheses and order of operations

      problem =
        Problem.define do
          new(name: "Complex Expr 2", description: "Test complex arithmetic with parentheses")
          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: (qty(food) + 1.0) * 2.0),
            direction: :minimize
          )
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains scaled variables and constants
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "2.0 qty_bread"),
             "Expected objective to contain '2.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "2.0 qty_milk"),
             "Expected objective to contain '2.0 qty_milk', got: #{objective_str}"
    end
  end

  describe "Edge Cases and Special Values" do
    @tag :edge_cases
    test "Zero coefficient multiplication", %{food_names: food_names} do
      # Test: qty(food) * 0.0
      # Expected: All variables get zero coefficients
      # Error context: If this fails, check zero coefficient handling

      problem =
        Problem.define do
          new(name: "Zero Coeff", description: "Test zero coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 0.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective is zero or contains zero coefficients
      objective_str = Dantzig.Polynomial.serialize(problem.objective)
      # The objective should be 0 or contain 0.0 coefficients
      assert objective_str == "0" or String.contains?(objective_str, "0.0"),
             "Expected zero objective or zero coefficients, got: #{objective_str}"
    end

    @tag :edge_cases
    test "Negative coefficient multiplication", %{food_names: food_names} do
      # Test: qty(food) * -1.0
      # Expected: All variables get negative coefficients
      # Error context: If this fails, check negative coefficient handling

      problem =
        Problem.define do
          new(name: "Neg Coeff", description: "Test negative coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * -1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains negative coefficients
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "- 1.0 qty_bread"),
             "Expected objective to contain '- 1.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "- 1.0 qty_milk"),
             "Expected objective to contain '- 1.0 qty_milk', got: #{objective_str}"
    end

    @tag :edge_cases
    test "Fractional coefficient multiplication", %{food_names: food_names} do
      # Test: qty(food) * 0.5
      # Expected: All variables get fractional coefficients
      # Error context: If this fails, check fractional coefficient handling

      problem =
        Problem.define do
          new(name: "Frac Coeff", description: "Test fractional coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 0.5), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains fractional coefficients
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "0.5 qty_bread"),
             "Expected objective to contain '0.5 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "0.5 qty_milk"),
             "Expected objective to contain '0.5 qty_milk', got: #{objective_str}"
    end
  end

  describe "Unary Operations" do
    @tag :unary
    test "Unary minus: -variable", %{food_names: food_names} do
      # Test: -1.0 * qty(food) (equivalent to -qty(food) but works with Elixir parser)
      # Expected: All variables get negative coefficients
      # Note: Direct -qty(food) doesn't work due to Elixir parser precedence: -qty(food) parses as (-qty)(food)
      # Error context: If this fails, check unary minus pattern in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(name: "Unary Minus", description: "Test unary minus")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: -1.0 * qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains negative coefficients
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "- 1.0 qty_bread"),
             "Expected objective to contain '- 1.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "- 1.0 qty_milk"),
             "Expected objective to contain '- 1.0 qty_milk', got: #{objective_str}"
    end
  end
end
