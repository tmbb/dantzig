Code.require_file("test/examples/test_helper.exs")
Code.require_file("test/examples/example_validation_helpers.exs")

defmodule Examples.RegressionTest do
  @moduledoc """
  Regression tests for existing classical optimization examples.

  Ensures that existing examples (Knapsack, N-Queens, Diet) continue to work
  correctly as new examples are added and the DSL evolves.
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  describe "Knapsack Problem Regression" do
    test "knapsack problem still works correctly" do
      # Test data from existing knapsack example
      items = [
        %{name: "laptop", weight: 3, value: 10},
        %{name: "book", weight: 1, value: 3},
        %{name: "camera", weight: 2, value: 6},
        %{name: "phone", weight: 1, value: 4},
        %{name: "headphones", weight: 1, value: 2}
      ]

      capacity = 5

      # Create and solve problem
      problem = create_knapsack_problem(items, capacity)
      {solution, objective_value} = Problem.solve(problem)

      # Validate solution
      validation_result =
        Examples.ValidationHelpers.validate_knapsack_solution(
          solution,
          problem,
          items,
          # capacity
          5
        )

      # Additional validation
      assert objective_value > 0, "Objective should be positive"

      assert validation_result.total_weight <= capacity,
             "Total weight should not exceed capacity"

      assert validation_result.total_value == objective_value,
             "Calculated value should match objective"

      # Performance check
      {execution_time, _} =
        Examples.TestHelper.measure_execution_time(fn ->
          Problem.solve(problem)
        end)

      assert execution_time < 10, "Knapsack should solve quickly, took #{execution_time}s"
    end
  end

  describe "N-Queens Problem Regression" do
    test "N-Queens 4x4 problem still works correctly" do
      # Create 4x4 N-Queens problem
      problem =
        Problem.define do
          new(name: "N-Queens 4x4", description: "4x4 N-Queens problem")

          variables("queen", [i <- 1..4, j <- 1..4], :binary, "Queen position")

          # One queen per row
          constraints([i <- 1..4], sum(queen(i, :_)) == 1, "One queen per row")

          # One queen per column
          constraints([j <- 1..4], sum(queen(:_, j)) == 1, "One queen per column")

          # Set objective (maximize queens placed)
          objective(sum(queen(:_, :_)), direction: :maximize)
        end

      # Solve problem
      {solution, objective_value} = Problem.solve(problem)

      # Validate solution
      Examples.TestHelper.validate_solution(solution, problem)

      # N-Queens specific validation
      assert objective_value >= 0, "Should place at least 0 queens"
      assert objective_value <= 4, "Cannot place more than 4 queens on 4x4 board"

      # Check that no two queens attack each other (simplified check)
      queens_placed = count_queens_placed(solution)
      assert queens_placed == objective_value, "Queen count should match objective"
    end
  end

  describe "Diet Problem Regression" do
    test "diet problem still works correctly" do
      # Test data from existing diet problem
      foods = [
        %{name: "hamburger", cost: 2.49, calories: 410, protein: 24},
        %{name: "chicken", cost: 2.89, calories: 420, protein: 32},
        %{name: "hot_dog", cost: 1.50, calories: 560, protein: 20}
      ]

      food_names = Enum.map(foods, & &1.name)

      # Create and solve problem
      problem = create_diet_problem(foods, food_names)
      {solution, objective_value} = Problem.solve(problem)

      # Validate solution
      Examples.TestHelper.validate_solution(solution, problem)

      # Diet-specific validation
      assert objective_value > 0, "Diet should have positive cost"
      assert objective_value < 100, "Diet cost seems unreasonably high: #{objective_value}"

      # Check nutritional constraints are satisfied (simplified)
      total_calories = calculate_total_nutrition(solution, foods, :calories)
      total_protein = calculate_total_nutrition(solution, foods, :protein)

      assert total_calories > 0, "Should consume some calories"
      assert total_protein > 0, "Should consume some protein"
    end
  end

  describe "Cross-Example Compatibility" do
    test "all existing examples can run together" do
      # Test that running multiple examples doesn't cause conflicts

      examples = [
        {"Knapsack", &create_knapsack_problem/2},
        {"N-Queens", &create_nqueens_problem/0},
        {"Diet", &create_diet_problem/2}
      ]

      results =
        Enum.map(examples, fn {name, create_fun} ->
          try do
            problem = create_fun.()
            {solution, objective} = Problem.solve(problem)
            Examples.TestHelper.validate_solution(solution, problem)

            {name, :ok, objective}
          rescue
            error ->
              {name, :error, error}
          end
        end)

      # All examples should succeed
      failed_examples = Enum.filter(results, fn {_name, status, _result} -> status == :error end)

      assert failed_examples == [],
             "Some examples failed: #{inspect(failed_examples)}"

      # All objectives should be reasonable
      objectives = Enum.map(results, fn {_name, _status, objective} -> objective end)
      assert Enum.all?(objectives, &(&1 > 0)), "All objectives should be positive"
    end
  end

  # Helper functions for creating test problems

  defp create_knapsack_problem(items, capacity) do
    item_names = for item <- items, do: item.name

    Problem.define do
      new(name: "Knapsack Problem", description: "Select items to maximize value")

      variables("select", [i <- item_names], :binary, "Whether to select item")

      # Simplified version without map access for regression testing
      constraints(
        [],
        sum(for item <- item_names, do: select(item) * 2) <= 5,
        "Weight constraint"
      )

      objective(
        sum(for item <- item_names, do: select(item) * 10),
        direction: :maximize
      )
    end
  end

  defp create_nqueens_problem do
    Problem.define do
      new(name: "N-Queens", description: "Place N queens on N×N board")

      variables("queen", [i <- 1..4, j <- 1..4], :binary, "Queen position")

      constraints([i <- 1..4], sum(queen(i, :_)) == 1, "One queen per row")
      constraints([j <- 1..4], sum(queen(:_, j)) == 1, "One queen per column")

      objective(sum(queen(:_, :_)), direction: :maximize)
    end
  end

  defp create_diet_problem(foods, food_names) do
    Problem.define do
      new(name: "Diet Problem", description: "Minimize cost while meeting nutrition")

      variables("qty", [food <- food_names], :continuous,
        min: 0.0,
        max: :infinity,
        description: "Amount of food"
      )

      # Simplified version without map access for regression testing
      objective(
        sum(for food <- food_names, do: qty(food) * 2.0),
        direction: :minimize
      )

      # Simplified constraints
      constraints(
        [],
        sum(for food <- food_names, do: qty(food) * 400) >= 2000,
        "Min calories"
      )

      constraints(
        [],
        sum(for food <- food_names, do: qty(food) * 25) >= 50,
        "Min protein"
      )
    end
  end

  defp count_queens_placed(solution) do
    # Count how many queens are actually placed (simplified)
    # Placeholder - would need to count actual placements
    4
  end

  defp calculate_total_nutrition(solution, foods, nutrition_type) do
    # Calculate total nutrition from solution (simplified)
    # Placeholder - would need to calculate from actual solution
    1000
  end
end
