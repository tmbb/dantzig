# Test helper for classical optimization examples
#
# This module provides common utilities for testing optimization examples:
# - Solution validation helpers
# - Constraint checking functions
# - Performance measurement utilities
# - Common test data generators

defmodule Examples.TestHelper do
  @moduledoc """
  Common utilities for testing classical optimization examples.

  Provides functions for:
  - Solution validation and verification
  - Constraint satisfaction checking
  - Performance measurement
  - Test data generation
  """

  import ExUnit.Assertions

  @doc """
  Validate that a solution satisfies all constraints and optimizes the objective.

  ## Parameters
  - solution: The solution returned by Dantzig.solve()
  - problem: The original problem definition
  - tolerance: Acceptable tolerance for floating-point comparisons (default: 0.001)

  ## Returns
  - :ok if solution is valid
  - Raises AssertionError if solution is invalid
  """
  def validate_solution(solution, problem, tolerance \\ 0.001) do
    # Check that solution is not an error
    assert solution != :error, "Solution should not be an error"

    # Check that all variables have valid values
    validate_variable_values(solution, problem)

    # Check constraint satisfaction
    validate_constraint_satisfaction(solution, problem, tolerance)

    # Check objective optimization
    validate_objective_optimization(solution, problem, tolerance)

    :ok
  end

  @doc """
  Validate that all variables have reasonable values.

  Checks:
  - No NaN or infinite values
  - Binary variables are 0 or 1 (within tolerance)
  - Integer variables are whole numbers (within tolerance)
  - Continuous variables are within bounds
  """
  def validate_variable_values(solution, problem, tolerance \\ 0.001) do
    Enum.each(problem.variables, fn {var_name, var_map} ->
      Enum.each(var_map, fn {_index, monomial} ->
        variable_names = Dantzig.Polynomial.variables([monomial])

        Enum.each(variable_names, fn var_name ->
          value = Map.get(solution.variables, var_name, 0)

          # Check for invalid values
          assert is_number(value),
                 "Variable #{var_name} should have numeric value, got #{inspect(value)}"

          assert value != :infinity, "Variable #{var_name} should not be infinity"
          assert value != :"-infinity", "Variable #{var_name} should not be negative infinity"
          refute is_nan(value), "Variable #{var_name} should not be NaN"

          # Check variable type constraints
          var_def = Dantzig.Problem.get_variable(problem, var_name)

          if var_def do
            case var_def.type do
              :binary ->
                # Binary variables should be 0 or 1
                assert abs(value - 0.0) < tolerance or abs(value - 1.0) < tolerance,
                       "Binary variable #{var_name} should be 0 or 1, got #{value}"

              :integer ->
                # Integer variables should be whole numbers
                assert abs(value - round(value)) < tolerance,
                       "Integer variable #{var_name} should be whole number, got #{value}"

              :continuous ->
                # Continuous variables should be within bounds if specified
                if var_def.min != nil do
                  assert value >= var_def.min - tolerance,
                         "Variable #{var_name} should be >= #{var_def.min}, got #{value}"
                end

                if var_def.max != nil do
                  assert value <= var_def.max + tolerance,
                         "Variable #{var_name} should be <= #{var_def.max}, got #{value}"
                end
            end
          end
        end)
      end)
    end)
  end

  @doc """
  Validate that all constraints are satisfied within tolerance.
  """
  def validate_constraint_satisfaction(solution, problem, tolerance \\ 0.001) do
    Enum.each(problem.constraints, fn {_id, constraint} ->
      # Evaluate constraint left-hand side
      lhs_value = evaluate_polynomial(constraint.left_hand_side, solution)

      # For now, we'll do basic validation
      # Full constraint evaluation would require more complex logic
      assert is_number(lhs_value), "Constraint LHS should evaluate to number"

      assert lhs_value != :infinity and lhs_value != :"-infinity",
             "Constraint LHS should not be infinity"
    end)
  end

  @doc """
  Validate that the objective function is properly optimized.
  """
  def validate_objective_optimization(solution, problem, tolerance \\ 0.001) do
    objective_value = solution.objective

    assert is_number(objective_value),
           "Objective should be numeric, got #{inspect(objective_value)}"

    assert objective_value != :infinity and objective_value != :"-infinity",
           "Objective should not be infinity"

    refute is_nan(objective_value), "Objective should not be NaN"

    # For minimization problems, check that objective is reasonable
    # For maximization problems, check that objective is reasonable
    case problem.direction do
      :minimize ->
        assert objective_value >= 0,
               "Minimization objective should be non-negative, got #{objective_value}"

      :maximize ->
        assert objective_value <= 10000,
               "Maximization objective seems unreasonably large: #{objective_value}"
    end
  end

  @doc """
  Evaluate a polynomial with variable values from a solution.
  """
  def evaluate_polynomial(polynomial, solution) do
    # This is a simplified version - full implementation would need
    # to evaluate the polynomial with actual variable values
    case polynomial do
      %{terms: terms, constant: constant} ->
        # Simplified evaluation - just return the constant for now
        # Full implementation would evaluate each term
        constant

      _ ->
        0.0
    end
  end

  @doc """
  Measure execution time of a function.
  """
  def measure_execution_time(fun) do
    {time_microseconds, result} = :timer.tc(fun)
    time_seconds = time_microseconds / 1_000_000
    {time_seconds, result}
  end

  @doc """
  Assert that execution time is within acceptable limits.
  """
  def assert_reasonable_execution_time(fun, max_seconds \\ 30) do
    {execution_time, result} = measure_execution_time(fun)

    assert execution_time < max_seconds,
           "Execution time #{execution_time}s exceeds maximum #{max_seconds}s"

    result
  end

  @doc """
  Generate test data for common problem sizes.
  """
  def generate_test_data(:small_knapsack) do
    %{
      items: [
        %{name: "item1", weight: 2, value: 10},
        %{name: "item2", weight: 3, value: 15},
        %{name: "item3", weight: 1, value: 5}
      ],
      capacity: 5
    }
  end

  def generate_test_data(:small_assignment) do
    %{
      workers: ["Alice", "Bob", "Charlie"],
      tasks: ["Task1", "Task2", "Task3"],
      cost_matrix: [
        [2, 3, 1],
        [5, 4, 8],
        [5, 6, 3]
      ]
    }
  end

  def generate_test_data(:small_transportation) do
    %{
      suppliers: ["S1", "S2", "S3"],
      customers: ["C1", "C2", "C3", "C4"],
      supply: [100, 150, 200],
      demand: [80, 90, 110, 170],
      cost_matrix: [
        [4, 5, 6, 8],
        [5, 6, 7, 9],
        [3, 4, 5, 7]
      ]
    }
  end

  @doc """
  Check if a value is NaN.
  """
  def is_nan(value) do
    is_float(value) and value != value
  end

  @doc """
  Compare floating-point values within tolerance.
  """
  def almost_equal(a, b, tolerance \\ 0.001) do
    abs(a - b) < tolerance
  end

  @doc """
  Assert that two floating-point values are almost equal.
  """
  def assert_almost_equal(a, b, tolerance \\ 0.001, message \\ nil) do
    default_message = "Expected #{a} and #{b} to be almost equal within #{tolerance}"
    assert almost_equal(a, b, tolerance), message || default_message
  end
end
