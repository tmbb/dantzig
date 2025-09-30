defmodule Dantzig.DSL.DietProblemProgressiveTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  require Dantzig.Problem.DSL, as: DSL

  # Test data setup
  setup do
    food_names = ["bread", "milk", "cheese", "potato", "fish", "yogurt"]

    foods = %{
      "bread" => %{"cost" => 0.5, "calories" => 200, "protein" => 10, "calcium" => 20},
      "milk" => %{"cost" => 0.3, "calories" => 150, "protein" => 8, "calcium" => 250},
      "cheese" => %{"cost" => 1.2, "calories" => 300, "protein" => 25, "calcium" => 400},
      "potato" => %{"cost" => 0.2, "calories" => 100, "protein" => 3, "calcium" => 10},
      "fish" => %{"cost" => 2.0, "calories" => 250, "protein" => 30, "calcium" => 50},
      "yogurt" => %{"cost" => 0.8, "calories" => 120, "protein" => 12, "calcium" => 200}
    }

    foods_dict = foods

    limits_names = ["calories", "protein", "calcium"]

    limits_dict = %{
      "calories" => %{"min" => 2000, "max" => 3000},
      "protein" => %{"min" => 50, "max" => 100},
      "calcium" => %{"min" => 400, "max" => 800}
    }

    %{
      food_names: food_names,
      foods: foods,
      foods_dict: foods_dict,
      limits_names: limits_names,
      limits_dict: limits_dict
    }
  end

  describe "Progressive Diet Problem Tests" do
    test "Level 1: Simple variable creation with string names", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test basic variable creation")

          variables("qty", [food <- food_names], :continuous, "Amount of food")
        end

      assert map_size(problem.variable_defs) == 6
      assert Map.has_key?(problem.variable_defs, "qty_bread")
      assert Map.has_key?(problem.variable_defs, "qty_milk")
      assert Map.has_key?(problem.variable_defs, "qty_cheese")
    end

    test "Level 2: Simple objective with constant coefficients", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test basic objective")

          variables("qty", [food <- food_names], :continuous, "Amount of food")
          objective(sum(for food <- food_names, do: qty(food) * 1.0), direction: :minimize)
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 3: Objective with map access - single level", %{
      food_names: food_names,
      foods: foods
    } do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test map access in objective")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
            direction: :minimize
          )
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Level 4: Simple constraint with constant RHS", %{food_names: food_names} do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test basic constraint")

          variables("qty", [food <- food_names], :continuous, "Amount of food")
          constraints([], sum(for food <- food_names, do: qty(food)) >= 1, "Min total food")
        end

      assert length(problem.constraints) == 1
    end

    test "Level 5: Constraint with map access - single level", %{
      food_names: food_names,
      foods: foods
    } do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test map access in constraint")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          constraints(
            [],
            sum(for food <- food_names, do: qty(food) * foods[food]["calories"]) >= 2000,
            "Min calories"
          )
        end

      assert length(problem.constraints) == 1
    end

    test "Level 6: Constraint with map access - nested level", %{
      food_names: food_names,
      foods_dict: foods_dict
    } do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test nested map access in constraint")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          constraints(
            [],
            sum(for food <- food_names, do: qty(food) * foods_dict[food]["calories"]) >= 2000,
            "Min calories"
          )
        end

      assert length(problem.constraints) == 1
    end

    test "Level 7: Constraint with map access - RHS from map", %{
      food_names: food_names,
      foods_dict: foods_dict,
      limits_dict: limits_dict
    } do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test map access in RHS")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          constraints(
            [],
            sum(for food <- food_names, do: qty(food) * foods_dict[food]["calories"]) >=
              limits_dict["calories"]["min"],
            "Min calories"
          )
        end

      assert length(problem.constraints) == 1
    end

    test "Level 8: Multiple constraints with generator", %{
      food_names: food_names,
      foods_dict: foods_dict,
      limits_names: limits_names,
      limits_dict: limits_dict
    } do
      problem =
        Problem.define do
          new(name: "Simple Diet", description: "Test multiple constraints with generator")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          constraints(
            [l_name <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) >=
              limits_dict[l_name]["min"],
            "Min #{l_name}"
          )
        end

      assert length(problem.constraints) == 3
    end

    test "Level 9: Full Diet Problem - Complete", %{
      food_names: food_names,
      foods_dict: foods_dict,
      limits_names: limits_names,
      limits_dict: limits_dict
    } do
      problem =
        Problem.define do
          new(
            name: "Diet Problem",
            description: "Minimize cost of food while meeting nutritional requirements"
          )

          variables("qty", [food <- food_names], :continuous,
            min: 0.0,
            max: :infinity,
            description: "Amount of food to buy"
          )

          objective(sum(for food <- food_names, do: qty(food) * foods_dict[food]["cost"]),
            direction: :minimize
          )

          constraints(
            [l_name <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) >=
              limits_dict[l_name]["min"],
            "Min #{l_name}"
          )

          constraints(
            [l_name <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) <=
              limits_dict[l_name]["max"],
            "Max #{l_name}"
          )
        end

      # Verify problem structure
      assert problem.direction == :minimize
      assert map_size(problem.variable_defs) == 6
      # 3 min + 3 max constraints
      assert length(problem.constraints) == 6

      # Verify variables
      for food <- food_names do
        assert Map.has_key?(problem.variable_defs, "qty_#{food}")
      end

      # Verify constraints
      constraint_names = Map.keys(problem.constraints) |> Enum.map(fn {_id, c} -> c.name end)
      assert "Min calories" in constraint_names
      assert "Min protein" in constraint_names
      assert "Min calcium" in constraint_names
      assert "Max calories" in constraint_names
      assert "Max protein" in constraint_names
      assert "Max calcium" in constraint_names
    end

    test "Level 10: Diet Problem - Solve", %{
      food_names: food_names,
      foods_dict: foods_dict,
      limits_names: limits_names,
      limits_dict: limits_dict
    } do
      problem =
        Problem.define do
          new(
            name: "Diet Problem",
            description: "Minimize cost of food while meeting nutritional requirements"
          )

          variables("qty", [food <- food_names], :continuous,
            min: 0.0,
            max: :infinity,
            description: "Amount of food to buy"
          )

          objective(sum(for food <- food_names, do: qty(food) * foods_dict[food]["cost"]),
            direction: :minimize
          )

          constraints(
            [l_name <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) >=
              limits_dict[l_name]["min"],
            "Min #{l_name}"
          )

          constraints(
            [l_name <- limits_names],
            sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) <=
              limits_dict[l_name]["max"],
            "Max #{l_name}"
          )
        end

      # Solve the problem
      {solution, objective} = Problem.solve(problem, print_optimizer_input: false)

      # Verify solution
      assert solution.model_status == "Optimal"
      assert is_number(objective)
      assert objective > 0

      # Verify all variables have values
      for food <- food_names do
        assert Map.has_key?(solution.variables, "qty_#{food}")
        assert is_number(solution.variables["qty_#{food}"])
        assert solution.variables["qty_#{food}"] >= 0
      end
    end
  end

  describe "Edge Cases and Error Handling" do
    test "Empty food list", %{foods_dict: foods_dict} do
      problem =
        Problem.define do
          new(name: "Empty Diet", description: "Test with empty food list")

          variables("qty", [food <- []], :continuous, "Amount of food")

          objective(sum(for food <- [], do: qty(food) * foods_dict[food]["cost"]),
            direction: :minimize
          )
        end

      assert map_size(problem.variable_defs) == 0
    end

    test "Single food item", %{foods_dict: foods_dict} do
      problem =
        Problem.define do
          new(name: "Single Food Diet", description: "Test with single food")

          variables("qty", [food <- ["bread"]], :continuous, "Amount of food")

          objective(sum(for food <- ["bread"], do: qty(food) * foods_dict[food]["cost"]),
            direction: :minimize
          )

          constraints(
            [],
            sum(for food <- ["bread"], do: qty(food) * foods_dict[food]["calories"]) >= 2000,
            "Min calories"
          )
        end

      assert map_size(problem.variable_defs) == 1
      assert length(problem.constraints) == 1
    end

    test "Missing map keys - should handle gracefully", %{food_names: food_names} do
      # Create a foods dict with missing keys
      incomplete_foods = %{
        # Missing calories, protein, calcium
        "bread" => %{"cost" => 0.5},
        # Missing protein, calcium
        "milk" => %{"cost" => 0.3, "calories" => 150}
      }

      problem =
        Problem.define do
          new(name: "Incomplete Diet", description: "Test with incomplete food data")

          variables("qty", [food <- ["bread", "milk"]], :continuous, "Amount of food")

          objective(
            sum(for food <- ["bread", "milk"], do: qty(food) * incomplete_foods[food]["cost"]),
            direction: :minimize
          )
        end

      assert problem.objective != nil
    end

    test "Zero coefficients", %{food_names: food_names} do
      zero_foods = %{
        "bread" => %{"cost" => 0.0, "calories" => 0, "protein" => 0, "calcium" => 0},
        "milk" => %{"cost" => 0.0, "calories" => 0, "protein" => 0, "calcium" => 0}
      }

      problem =
        Problem.define do
          new(name: "Zero Diet", description: "Test with zero coefficients")

          variables("qty", [food <- ["bread", "milk"]], :continuous, "Amount of food")

          objective(sum(for food <- ["bread", "milk"], do: qty(food) * zero_foods[food]["cost"]),
            direction: :minimize
          )

          constraints(
            [],
            sum(for food <- ["bread", "milk"], do: qty(food) * zero_foods[food]["calories"]) >= 0,
            "Min calories"
          )
        end

      assert problem.objective != nil
      assert length(problem.constraints) == 1
    end
  end

  describe "Syntax Variations" do
    test "Alternative sum syntax with in", %{food_names: food_names, foods_dict: foods_dict} do
      problem =
        Problem.define do
          new(name: "Alternative Sum", description: "Test alternative sum syntax")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum((qty(food) * foods_dict[food]["cost"]) in food <- food_names),
            direction: :minimize
          )
        end

      assert problem.direction == :minimize
      assert problem.objective != nil
    end

    test "Mixed sum syntaxes", %{food_names: food_names, foods_dict: foods_dict} do
      problem =
        Problem.define do
          new(name: "Mixed Sum", description: "Test mixed sum syntaxes")

          variables("qty", [food <- food_names], :continuous, "Amount of food")

          objective(sum(for food <- food_names, do: qty(food) * foods_dict[food]["cost"]),
            direction: :minimize
          )

          constraints([], sum(qty(food) in food <- food_names) >= 1, "Min total")
        end

      assert problem.direction == :minimize
      assert length(problem.constraints) == 1
    end
  end
end
