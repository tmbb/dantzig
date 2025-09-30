defmodule Dantzig.DSL.Regression.RegressionTest do
  @moduledoc """
  Regression test suite for the Dantzig DSL.

  This test suite ensures that existing functionality continues to work as expected
  when new features are added or changes are made to the codebase.

  Key areas covered:
  - N-Queens problems (2D and 3D)
  - Complete problem workflows (variables + constraints + objectives)
  - Solver integration
  - LP file generation
  - Constraint parsing and generation

  Each test is designed to:
  - Verify complete end-to-end functionality
  - Catch regressions in existing features
  - Provide clear error messages for debugging
  - Ensure backward compatibility
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  describe "N-Queens Problem Regression Tests" do
    @tag :nqueens
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

      # Verify problem structure
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert map_size(problem.variable_defs) == 4,
             "Expected 4 variables (2x2 grid), got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 4,
             "Expected 4 constraints (2 rows + 2 columns), got #{map_size(problem.constraints)}"

      # Verify variable names
      expected_vars = ["queen2d_1_1", "queen2d_1_2", "queen2d_2_1", "queen2d_2_2"]

      for var_name <- expected_vars do
        assert Map.has_key?(problem.variable_defs, var_name),
               "Missing variable: #{var_name}. Available: #{Map.keys(problem.variable_defs)}"
      end

      # Verify constraint names
      constraint_names = Map.keys(problem.constraints)

      assert length(constraint_names) == 4,
             "Expected 4 constraint names, got #{length(constraint_names)}: #{constraint_names}"
    end

    @tag :nqueens
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

      # Verify problem structure
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert map_size(problem.variable_defs) == 8,
             "Expected 8 variables (2x2x2 grid), got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 8,
             "Expected 8 constraints (4 rows + 4 columns), got #{map_size(problem.constraints)}"

      # Verify variable names
      expected_vars = [
        "queen3d_1_1_1",
        "queen3d_1_1_2",
        "queen3d_1_2_1",
        "queen3d_1_2_2",
        "queen3d_2_1_1",
        "queen3d_2_1_2",
        "queen3d_2_2_1",
        "queen3d_2_2_2"
      ]

      for var_name <- expected_vars do
        assert Map.has_key?(problem.variable_defs, var_name),
               "Missing variable: #{var_name}. Available: #{Map.keys(problem.variable_defs)}"
      end

      # Verify constraint names
      constraint_names = Map.keys(problem.constraints)

      assert length(constraint_names) == 8,
             "Expected 8 constraint names, got #{length(constraint_names)}: #{constraint_names}"
    end

    @tag :nqueens
    test "N-Queens 2D problem with solver integration" do
      # Test: Complete N-Queens 2D problem that can be solved
      # Expected: Problem created and solved successfully
      # Error context: If this fails, check solver integration regression

      problem =
        Problem.define do
          new(name: "N-Queens 2D Solver", description: "N-Queens 2D with solver")
          variables("queen2d", [i <- 1..2, j <- 1..2], :binary, "Queen position")
          constraints([i <- 1..2], sum(queen2d(i, :_)) == 1, "One queen per row")
          constraints([j <- 1..2], sum(queen2d(:_, j)) == 1, "One queen per column")
          objective(sum(queen2d(:_, :_)), direction: :maximize)
        end

      # Verify problem structure
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert map_size(problem.variable_defs) == 4,
             "Expected 4 variables, got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 4,
             "Expected 4 constraints, got #{map_size(problem.constraints)}"

      # Test solver integration (without actually solving to avoid external dependencies)
      # Just verify the problem can be converted to LP format
      lp_data = Dantzig.HiGHS.to_lp_iodata(problem)

      assert is_list(lp_data),
             "Expected LP data to be a list, got #{inspect(lp_data)}"

      assert length(lp_data) > 0,
             "Expected non-empty LP data, got #{length(lp_data)} items"
    end
  end

  describe "Constraint Parsing Regression Tests" do
    @tag :constraints
    test "Simple equality constraints" do
      # Test: Basic equality constraints with sum expressions
      # Expected: Constraints created successfully
      # Error context: If this fails, check constraint parsing regression

      problem =
        Problem.define do
          new(name: "Simple Constraints", description: "Test simple equality constraints")
          variables("x", [i <- 1..2], :continuous, "Variable x")
          constraints([i <- 1..2], x(i) == 1, "x equals 1")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Verify problem structure
      assert map_size(problem.variable_defs) == 2,
             "Expected 2 variables, got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 2,
             "Expected 2 constraints, got #{map_size(problem.constraints)}"

      # Verify constraint structure
      constraints = problem.constraints

      for {_id, constraint} <- constraints do
        assert constraint.operator == :==,
               "Expected equality operator, got #{constraint.operator}"

        assert constraint.right_hand_side == 1,
               "Expected RHS of 1, got #{constraint.right_hand_side}"
      end
    end

    @tag :constraints
    test "Inequality constraints" do
      # Test: Basic inequality constraints with sum expressions
      # Expected: Constraints created successfully
      # Error context: If this fails, check inequality constraint parsing regression

      problem =
        Problem.define do
          new(name: "Inequality Constraints", description: "Test inequality constraints")
          variables("x", [i <- 1..2], :continuous, "Variable x")
          constraints([i <- 1..2], x(i) <= 1, "x less than or equal to 1")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Verify problem structure
      assert map_size(problem.variable_defs) == 2,
             "Expected 2 variables, got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 2,
             "Expected 2 constraints, got #{map_size(problem.constraints)}"

      # Verify constraint structure
      constraints = problem.constraints

      for {_id, constraint} <- constraints do
        assert constraint.operator == :<=,
               "Expected less-than-or-equal operator, got #{constraint.operator}"

        assert constraint.right_hand_side == 1,
               "Expected RHS of 1, got #{constraint.right_hand_side}"
      end
    end

    @tag :constraints
    test "Wildcard pattern constraints" do
      # Test: Constraints with wildcard patterns like sum(x(:_))
      # Expected: Constraints created successfully with wildcard expansion
      # Error context: If this fails, check wildcard pattern parsing regression

      problem =
        Problem.define do
          new(name: "Wildcard Constraints", description: "Test wildcard pattern constraints")
          variables("x", [i <- 1..2, j <- 1..2], :continuous, "Variable x")
          constraints([i <- 1..2], sum(x(i, :_)) == 1, "Sum of row equals 1")
          objective(sum(x(:_, :_)), direction: :minimize)
        end

      # Verify problem structure
      assert map_size(problem.variable_defs) == 4,
             "Expected 4 variables (2x2 grid), got #{map_size(problem.variable_defs)}"

      assert map_size(problem.constraints) == 2,
             "Expected 2 constraints (2 rows), got #{map_size(problem.constraints)}"

      # Verify constraint structure
      constraints = problem.constraints

      for {_id, constraint} <- constraints do
        assert constraint.operator == :==,
               "Expected equality operator, got #{constraint.operator}"

        assert constraint.right_hand_side == 1,
               "Expected RHS of 1, got #{constraint.right_hand_side}"
      end
    end
  end

  describe "Objective Function Regression Tests" do
    @tag :objectives
    test "Simple sum objective" do
      # Test: Basic sum objective function
      # Expected: Objective created successfully
      # Error context: If this fails, check objective parsing regression

      problem =
        Problem.define do
          new(name: "Simple Objective", description: "Test simple sum objective")
          variables("x", [i <- 1..2], :continuous, "Variable x")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Verify problem structure
      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{problem.objective}"

      # Verify objective structure
      objective_str = to_string(problem.objective)

      assert String.contains?(objective_str, "x_1"),
             "Expected objective to contain x_1, got: #{objective_str}"

      assert String.contains?(objective_str, "x_2"),
             "Expected objective to contain x_2, got: #{objective_str}"
    end

    @tag :objectives
    test "Maximize objective" do
      # Test: Maximize objective function
      # Expected: Objective created successfully with maximize direction
      # Error context: If this fails, check maximize direction regression

      problem =
        Problem.define do
          new(name: "Maximize Objective", description: "Test maximize objective")
          variables("x", [i <- 1..2], :continuous, "Variable x")
          objective(sum(x(:_)), direction: :maximize)
        end

      # Verify problem structure
      assert problem.direction == :maximize,
             "Expected maximize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{problem.objective}"
    end
  end

  describe "LP File Generation Regression Tests" do
    @tag :lp_generation
    test "LP file generation for simple problem" do
      # Test: LP file generation for a simple problem
      # Expected: LP file generated successfully
      # Error context: If this fails, check LP file generation regression

      problem =
        Problem.define do
          new(name: "LP Test", description: "Test LP file generation")
          variables("x", [i <- 1..2], :continuous, "Variable x")
          constraints([i <- 1..2], x(i) == 1, "x equals 1")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Generate LP file
      lp_data = Dantzig.HiGHS.to_lp_iodata(problem)

      # Verify LP file structure
      assert is_list(lp_data),
             "Expected LP data to be a list, got #{inspect(lp_data)}"

      assert length(lp_data) > 0,
             "Expected non-empty LP data, got #{length(lp_data)} items"

      # Convert to string for inspection
      lp_string = IO.iodata_to_binary(lp_data)

      assert is_binary(lp_string),
             "Expected LP string to be binary, got #{inspect(lp_string)}"

      assert String.length(lp_string) > 0,
             "Expected non-empty LP string, got length #{String.length(lp_string)}"

      # Verify LP file contains expected sections
      assert String.contains?(lp_string, "Minimize"),
             "Expected LP file to contain 'Minimize', got: #{lp_string}"

      assert String.contains?(lp_string, "Subject To"),
             "Expected LP file to contain 'Subject To', got: #{lp_string}"

      assert String.contains?(lp_string, "Bounds"),
             "Expected LP file to contain 'Bounds', got: #{lp_string}"

      assert String.contains?(lp_string, "End"),
             "Expected LP file to contain 'End', got: #{lp_string}"
    end

    @tag :lp_generation
    test "LP file generation for binary variables" do
      # Test: LP file generation for binary variables
      # Expected: LP file generated successfully with binary variable bounds
      # Error context: If this fails, check binary variable LP generation regression

      problem =
        Problem.define do
          new(name: "Binary LP Test", description: "Test binary variable LP generation")
          variables("x", [i <- 1..2], :binary, "Binary variable x")
          constraints([i <- 1..2], x(i) == 1, "x equals 1")
          objective(sum(x(:_)), direction: :minimize)
        end

      # Generate LP file
      lp_data = Dantzig.HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Verify LP file contains binary variable bounds
      assert String.contains?(lp_string, "0 <= x_1 <= 1"),
             "Expected LP file to contain binary bounds for x_1, got: #{lp_string}"

      assert String.contains?(lp_string, "0 <= x_2 <= 1"),
             "Expected LP file to contain binary bounds for x_2, got: #{lp_string}"
    end
  end
end
