defmodule Dantzig.DSL.Arithmetic.NegativeCoefficientDebugTest do
  @moduledoc """
  Debug test for negative coefficient multiplication issue.

  This test isolates the specific problem where qty(food) * -1.0 results in 0
  instead of negative coefficients.
  """

  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem

  setup do
    food_names = ["bread", "milk"]
    {:ok, %{food_names: food_names}}
  end

  describe "Negative Coefficient Debug Tests" do
    test "Step 1: Simple positive coefficient multiplication", %{food_names: food_names} do
      # Test: qty(food) * 1.0 - should work
      # Expected: Positive coefficients
      # Error context: Baseline test to ensure basic multiplication works

      problem =
        Problem.define do
          new(name: "Positive Coeff", description: "Test positive coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Verify the objective contains positive coefficients
      objective_str = Dantzig.Polynomial.serialize(problem.objective)

      assert String.contains?(objective_str, "1.0 qty_bread"),
             "Expected objective to contain '1.0 qty_bread', got: #{objective_str}"

      assert String.contains?(objective_str, "1.0 qty_milk"),
             "Expected objective to contain '1.0 qty_milk', got: #{objective_str}"
    end

    test "Step 2: Simple negative coefficient multiplication", %{food_names: food_names} do
      # Test: qty(food) * -1.0 - this is failing
      # Expected: Negative coefficients
      # Error context: This is the failing test - need to debug why it results in 0

      problem =
        Problem.define do
          new(name: "Negative Coeff", description: "Test negative coefficient")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * -1.0), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Debug: Print the actual objective to see what we're getting
      objective_str = Dantzig.Polynomial.serialize(problem.objective)
      IO.puts("DEBUG: Objective string: #{objective_str}")
      IO.puts("DEBUG: Objective struct: #{inspect(problem.objective)}")

      # This should fail and show us what we're actually getting
      assert String.contains?(objective_str, "- 1.0 qty_bread"),
             "Expected objective to contain '- 1.0 qty_bread', got: #{objective_str}"
    end

    test "Step 3: Alternative negative coefficient syntax", %{food_names: food_names} do
      # Test: -1.0 * qty(food) - alternative syntax
      # Expected: Negative coefficients
      # Error context: Test if the issue is with the order of multiplication

      problem =
        Problem.define do
          new(
            name: "Negative Coeff Alt",
            description: "Test negative coefficient alternative syntax"
          )

          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: -1.0 * qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Debug: Print the actual objective to see what we're getting
      objective_str = Dantzig.Polynomial.serialize(problem.objective)
      IO.puts("DEBUG: Alternative syntax objective: #{objective_str}")

      # This should fail and show us what we're actually getting
      assert String.contains?(objective_str, "- 1.0 qty_bread"),
             "Expected objective to contain '- 1.0 qty_bread', got: #{objective_str}"
    end

    test "Step 4: Unary minus syntax", %{food_names: food_names} do
      # Test: -qty(food) - unary minus
      # Expected: Negative coefficients
      # Error context: Test if unary minus works correctly

      problem =
        Problem.define do
          new(name: "Unary Minus", description: "Test unary minus")
          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: -qty(food)), direction: :minimize)
        end

      assert problem.direction == :minimize,
             "Expected minimize direction, got #{problem.direction}"

      assert problem.objective != nil,
             "Expected non-nil objective, got #{inspect(problem.objective)}"

      # Debug: Print the actual objective to see what we're getting
      objective_str = Dantzig.Polynomial.serialize(problem.objective)
      IO.puts("DEBUG: Unary minus objective: #{objective_str}")

      # This should fail and show us what we're actually getting
      assert String.contains?(objective_str, "- 1 qty_bread"),
             "Expected objective to contain '- 1 qty_bread', got: #{objective_str}"
    end
  end
end
