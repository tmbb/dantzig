defmodule Dantzig.DSL.SimpleSyntax.SimpleVariableCreationTest do
  @moduledoc """
  Test-Driven Development for Simple Syntax Variable Creation

  This test suite implements TDD for the simple syntax pattern:
  variables("var_name", :binary, "description")

  Unlike generator syntax: variables("var", [i <- 1..n], :binary, "description")
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  describe "Step 1.1: Basic Simple Variable Creation" do
    test "create single simple variable with binary type" do
      # Test: Create single variable using simple syntax
      # Expected: Variable "test_var" created successfully with :binary type
      # Error context: If this fails, check if DSL handles simple variable creation

      problem =
        Problem.define do
          new(name: "Simple Var Test", description: "Test basic simple variable")
          variables("test_var", :binary, "Test variable")
        end

      # Verify variable was created
      assert Map.has_key?(problem.variables, "test_var"),
             "Variable 'test_var' should exist in problem.variables"

      # Verify variable configuration (stored in variable_defs, not variables)
      assert Map.has_key?(problem.variable_defs, "test_var"),
             "Variable 'test_var' should exist in problem.variable_defs"

      var = problem.variable_defs["test_var"]

      assert var.type == :binary,
             "Expected variable type :binary, got #{var.type}"
    end

    test "create single simple variable with continuous type" do
      # Test: Create single variable with :continuous type
      # Expected: Variable created with correct type and default bounds

      problem =
        Problem.define do
          new(name: "Continuous Var Test", description: "Test continuous variable")
          variables("continuous_var", :continuous, "Continuous test variable")
        end

      # Verify variable exists and has correct type
      assert Map.has_key?(problem.variables, "continuous_var"),
             "Variable 'continuous_var' should exist"

      assert Map.has_key?(problem.variable_defs, "continuous_var"),
             "Variable 'continuous_var' should exist in variable_defs"

      var = problem.variable_defs["continuous_var"]

      assert var.type == :continuous,
             "Expected :continuous type, got #{var.type}"
    end

    test "create single simple variable with integer type" do
      # Test: Create single variable with :integer type
      # Expected: Variable created with integer type

      problem =
        Problem.define do
          new(name: "Integer Var Test", description: "Test integer variable")
          variables("integer_var", :integer, "Integer test variable")
        end

      # Verify variable exists and has correct type
      assert Map.has_key?(problem.variables, "integer_var"),
             "Variable 'integer_var' should exist"

      assert Map.has_key?(problem.variable_defs, "integer_var"),
             "Variable 'integer_var' should exist in variable_defs"

      var = problem.variable_defs["integer_var"]

      assert var.type == :integer,
             "Expected :integer type, got #{var.type}"
    end
  end

  describe "Step 1.3: Multiple Simple Variables" do
    test "create multiple simple variables with different types" do
      # Test: Create multiple variables using simple syntax
      # Expected: All variables created with correct names and types

      problem =
        Problem.define do
          new(name: "Multiple Vars Test", description: "Test multiple simple variables")

          # Create variables one by one (simple syntax style)
          variables("binary_var", :binary, "Binary variable")
          variables("continuous_var", :continuous, "Continuous variable")
          variables("integer_var", :integer, "Integer variable")
        end

      # Verify all variables exist
      expected_vars = ["binary_var", "continuous_var", "integer_var"]

      for var_name <- expected_vars do
        assert Map.has_key?(problem.variables, var_name),
               "Variable '#{var_name}' should exist"
      end

      # Verify variable types
      assert problem.variable_defs["binary_var"].type == :binary
      assert problem.variable_defs["continuous_var"].type == :continuous
      assert problem.variable_defs["integer_var"].type == :integer
    end

    test "create multiple simple variables with same type" do
      # Test: Create multiple variables of same type (like N-Queens pattern)
      # Expected: All variables created successfully

      problem =
        Problem.define do
          new(name: "Same Type Vars Test", description: "Test multiple same-type variables")

          # Pattern from nqueens_dsl.exs simple example
          variables("queen_1_1", :binary, "Queen position")
          variables("queen_1_2", :binary, "Queen position")
          variables("queen_2_1", :binary, "Queen position")
          variables("queen_2_2", :binary, "Queen position")
        end

      # Verify all queen variables exist
      queen_vars = ["queen_1_1", "queen_1_2", "queen_2_1", "queen_2_2"]

      for var_name <- queen_vars do
        assert Map.has_key?(problem.variables, var_name),
               "Queen variable '#{var_name}' should exist"

        assert Map.has_key?(problem.variable_defs, var_name),
               "Queen variable '#{var_name}' should exist in variable_defs"

        var = problem.variable_defs[var_name]

        assert var.type == :binary,
               "Queen variable '#{var_name}' should be :binary, got #{var.type}"
      end
    end
  end

  describe "Step 1.4: Variable Configuration Validation" do
    test "simple variable has correct default bounds" do
      # Test: Simple variables have appropriate default bounds based on type

      problem =
        Problem.define do
          new(name: "Bounds Test", description: "Test variable bounds")
          variables("test_var", :binary, "Test bounds")
        end

      assert Map.has_key?(problem.variable_defs, "test_var"),
             "Variable 'test_var' should exist in variable_defs"

      var = problem.variable_defs["test_var"]

      # Binary variables should default to 0-1 bounds
      assert var.min == 0, "Binary variable should have min bound 0, got #{var.min}"
      assert var.max == 1, "Binary variable should have max bound 1, got #{var.max}"
    end

    test "simple variable preserves description" do
      # Test: Variable description is stored correctly

      problem =
        Problem.define do
          new(name: "Description Test", description: "Test variable description")
          variables("test_var", :binary, "This is a test variable description")
        end

      assert Map.has_key?(problem.variable_defs, "test_var"),
             "Variable 'test_var' should exist in variable_defs"

      var = problem.variable_defs["test_var"]

      assert var.description == "This is a test variable description",
             "Variable description not preserved correctly"
    end
  end
end
