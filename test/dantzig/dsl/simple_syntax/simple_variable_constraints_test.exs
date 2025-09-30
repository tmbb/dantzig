defmodule Dantzig.DSL.SimpleSyntax.SimpleVariableConstraintsTest do
  @moduledoc """
  Test-Driven Development for Simple Syntax Variable Constraints

  This test suite implements TDD for constraints with simple variables:
  - Equality constraints: var1 + var2 == constant
  - Inequality constraints: var <= constant, var >= constant
  - Complex constraints: (var1 + var2) * 2.0 == 1
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  describe "Step 3.1: Simple Variable Equality Constraints" do
    test "single simple variable equality constraint" do
      # Test: Simple variable == constant in constraint
      # Expected: Constraint created with correct variable reference
      # Error context: If this fails, check constraint parsing for simple variables

      problem =
        Problem.define do
          new(
            name: "Single Var Constraint",
            description: "Test single simple variable constraint"
          )

          variables("test_var", :binary, "Test variable")
          constraints(test_var == 1, "Variable equals 1")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      # Verify constraint details
      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Variable equals 1",
             "Constraint name not preserved correctly"
    end

    test "multiple simple variables equality constraint" do
      # Test: Multiple simple variables == constant (like N-Queens pattern)
      # Expected: All variables correctly referenced in constraint

      problem =
        Problem.define do
          new(
            name: "Multiple Var Constraint",
            description: "Test multiple simple variables constraint"
          )

          # Pattern from nqueens_dsl.exs simple example
          variables("queen_1_1", :binary, "Queen position")
          variables("queen_1_2", :binary, "Queen position")
          variables("queen_2_1", :binary, "Queen position")
          variables("queen_2_2", :binary, "Queen position")

          constraints(queen_1_1 + queen_1_2 == 1, "One queen per row")
          constraints(queen_2_1 + queen_2_2 == 1, "One queen per row")
        end

      # Verify constraints were created
      assert map_size(problem.constraints) == 2,
             "Expected 2 constraints, got #{map_size(problem.constraints)}"

      # Verify constraint names
      constraint_names = Enum.map(Map.values(problem.constraints), & &1.name)

      assert "One queen per row" in constraint_names,
             "Expected constraint name not found"
    end
  end

  describe "Step 3.3: Simple Variable Inequality Constraints" do
    test "simple variable <= constant constraint" do
      # Test: Simple variable <= constant
      # Expected: Inequality constraint works with simple variables

      problem =
        Problem.define do
          new(name: "LE Constraint", description: "Test <= constraint")
          variables("test_var", :continuous, "Test variable")
          constraints(test_var <= 10.0, "Variable upper bound")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Variable upper bound",
             "Constraint name not preserved correctly"
    end

    test "simple variable >= constant constraint" do
      # Test: Simple variable >= constant
      # Expected: Inequality constraint works with simple variables

      problem =
        Problem.define do
          new(name: "GE Constraint", description: "Test >= constraint")
          variables("test_var", :continuous, "Test variable")
          constraints(test_var >= 0.0, "Variable lower bound")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Variable lower bound",
             "Constraint name not preserved correctly"
    end
  end

  describe "Step 3.2: Complex Simple Variable Constraints" do
    test "complex constraint with arithmetic: (var1 + var2) == constant" do
      # Test: Complex constraint with multiple variables and arithmetic
      # Expected: Complex arithmetic expressions work in constraints

      problem =
        Problem.define do
          new(name: "Complex Constraint", description: "Test complex constraint expression")
          variables("var1", :binary, "Variable 1")
          variables("var2", :binary, "Variable 2")
          constraints(var1 + var2 == 1, "Sum constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Sum constraint",
             "Constraint name not preserved correctly"
    end

    test "complex constraint with multiplication: var * constant == constant" do
      # Test: Constraint with variable multiplication
      # Expected: Multiplication in constraints works correctly

      problem =
        Problem.define do
          new(name: "Mult Constraint", description: "Test multiplication in constraint")
          variables("test_var", :continuous, "Test variable")
          constraints(test_var * 2.0 == 10.0, "Scaled constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Scaled constraint",
             "Constraint name not preserved correctly"
    end

    test "complex constraint with mixed operations: (var1 + var2) * 2.0 == 1" do
      # Test: Complex constraint with mixed arithmetic operations
      # Expected: Complex expressions work in constraints

      problem =
        Problem.define do
          new(name: "Mixed Constraint", description: "Test mixed operations in constraint")
          variables("var1", :binary, "Variable 1")
          variables("var2", :binary, "Variable 2")
          constraints((var1 + var2) * 2.0 == 1, "Complex constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"

      constraint = Enum.at(Map.values(problem.constraints), 0)

      assert constraint.name == "Complex constraint",
             "Constraint name not preserved correctly"
    end
  end

  describe "Step 3.4: Edge Cases for Simple Variable Constraints" do
    test "constraint with zero coefficient" do
      # Test: Constraint with variable * 0.0
      # Expected: Zero coefficient handled correctly in constraints

      problem =
        Problem.define do
          new(name: "Zero Coeff Constraint", description: "Test zero coefficient in constraint")
          variables("test_var", :binary, "Test variable")
          constraints(test_var * 0.0 == 0, "Zero coefficient constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"
    end

    test "constraint with negative coefficient" do
      # Test: Constraint with variable * -1.0
      # Expected: Negative coefficient handled correctly in constraints

      problem =
        Problem.define do
          new(
            name: "Neg Coeff Constraint",
            description: "Test negative coefficient in constraint"
          )

          variables("test_var", :binary, "Test variable")
          constraints(test_var * -1.0 == -1, "Negative coefficient constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"
    end

    test "constraint with fractional coefficient" do
      # Test: Constraint with variable * 0.5
      # Expected: Fractional coefficient handled correctly in constraints

      problem =
        Problem.define do
          new(
            name: "Frac Coeff Constraint",
            description: "Test fractional coefficient in constraint"
          )

          variables("test_var", :continuous, "Test variable")
          constraints(test_var * 0.5 == 5.0, "Fractional coefficient constraint")
        end

      # Verify constraint was created
      assert map_size(problem.constraints) == 1,
             "Expected 1 constraint, got #{map_size(problem.constraints)}"
    end
  end
end
