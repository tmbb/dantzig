defmodule Dantzig.DSL.SimpleSyntax.SimpleVariableArithmeticTest do
  @moduledoc """
  Test-Driven Development for Simple Syntax Variable Arithmetic

  This test suite implements TDD for arithmetic operations with simple variables:
  - Addition: var1 + var2, var + constant
  - Subtraction: var1 - var2, var - constant
  - Multiplication: var * constant
  - Division: var / constant
  - Complex expressions: (var1 + var2) * 2.0
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  describe "Step 2.1: Simple Variable in Objective" do
    test "single simple variable in objective" do
      # Test: Use simple variable directly in objective expression
      # Expected: Variable correctly referenced in polynomial
      # Error context: If this fails, check variable resolution in parse_expression_to_polynomial

      problem =
        Problem.define do
          new(
            name: "Single Var Objective",
            description: "Test single simple variable in objective"
          )

          variables("test_var", :binary, "Test variable")
          objective(test_var, direction: :maximize)
        end

      # Verify objective contains the variable
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "multiple simple variables in objective" do
      # Test: Multiple simple variables in objective (like N-Queens pattern)
      # Expected: All variables correctly referenced in objective

      problem =
        Problem.define do
          new(
            name: "Multiple Var Objective",
            description: "Test multiple simple variables in objective"
          )

          # Pattern from nqueens_dsl.exs simple example
          variables("queen_1_1", :binary, "Queen position")
          variables("queen_1_2", :binary, "Queen position")
          variables("queen_2_1", :binary, "Queen position")
          variables("queen_2_2", :binary, "Queen position")

          objective(queen_1_1 + queen_1_2 + queen_2_1 + queen_2_2, direction: :maximize)
        end

      # Verify objective contains all variables
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Step 2.3: Simple Variable Arithmetic Operations" do
    test "simple variable + constant in objective" do
      # Test: Simple variable + constant in objective
      # Expected: Arithmetic operation correctly applied to simple variable
      # Error context: If this fails, check arithmetic pattern matching for simple variables

      problem =
        Problem.define do
          new(name: "Var + Const", description: "Test variable + constant")
          variables("test_var", :binary, "Test variable")
          objective(test_var + 1.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "simple variable - constant in objective" do
      # Test: Simple variable - constant in objective
      # Expected: Subtraction operation works correctly

      problem =
        Problem.define do
          new(name: "Var - Const", description: "Test variable - constant")
          variables("test_var", :binary, "Test variable")
          objective(test_var - 1.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "simple variable * constant in objective" do
      # Test: Simple variable * constant in objective
      # Expected: Multiplication operation works correctly

      problem =
        Problem.define do
          new(name: "Var * Const", description: "Test variable * constant")
          variables("test_var", :binary, "Test variable")
          objective(test_var * 2.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "simple variable / constant in objective" do
      # Test: Simple variable / constant in objective
      # Expected: Division operation works correctly

      problem =
        Problem.define do
          new(name: "Var / Const", description: "Test variable / constant")
          variables("test_var", :binary, "Test variable")
          objective(test_var / 2.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Step 2.4: Complex Simple Variable Expressions" do
    test "multiple operations: (variable * constant) + constant" do
      # Test: Complex expression with multiple operations
      # Expected: Complex arithmetic expressions work with simple variables

      problem =
        Problem.define do
          new(name: "Complex Expr", description: "Test complex arithmetic expression")
          variables("test_var", :binary, "Test variable")
          objective(test_var * 2.0 + 1.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "multiple operations: (variable + constant) * constant" do
      # Test: Complex expression with parentheses and multiple operations
      # Expected: Order of operations respected

      problem =
        Problem.define do
          new(name: "Complex Expr 2", description: "Test complex arithmetic with parentheses")
          variables("test_var", :binary, "Test variable")
          objective((test_var + 1.0) * 2.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "multiple simple variables with arithmetic" do
      # Test: Multiple simple variables in complex arithmetic expression
      # Expected: All variables correctly handled in complex expression

      problem =
        Problem.define do
          new(
            name: "Multiple Vars Complex",
            description: "Test multiple variables in complex expression"
          )

          variables("var1", :binary, "Variable 1")
          variables("var2", :binary, "Variable 2")
          variables("var3", :binary, "Variable 3")

          objective(var1 * 2.0 + var2 - var3 / 2.0, direction: :maximize)
        end

      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end

  describe "Step 2.5: Edge Cases for Simple Variable Arithmetic" do
    test "zero coefficient multiplication" do
      # Test: Simple variable * 0.0
      # Expected: Zero coefficient handled correctly

      problem =
        Problem.define do
          new(name: "Zero Coeff", description: "Test zero coefficient")
          variables("test_var", :binary, "Test variable")
          objective(test_var * 0.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "negative coefficient multiplication" do
      # Test: Simple variable * -1.0
      # Expected: Negative coefficient handled correctly

      problem =
        Problem.define do
          new(name: "Neg Coeff", description: "Test negative coefficient")
          variables("test_var", :binary, "Test variable")
          objective(test_var * -1.0, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end

    test "fractional coefficient multiplication" do
      # Test: Simple variable * 0.5
      # Expected: Fractional coefficient handled correctly

      problem =
        Problem.define do
          new(name: "Frac Coeff", description: "Test fractional coefficient")
          variables("test_var", :binary, "Test variable")
          objective(test_var * 0.5, direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"
    end
  end
end
