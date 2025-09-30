defmodule Dantzig.DSL.IntegrationTest do
  @moduledoc """
  Integration tests for the complete DSL functionality
  """
  use ExUnit.Case, async: true

  alias Dantzig.Problem, as: Problem

  # Enable variable access for testing
  use Dantzig.DSL.Integration
  enable_variable_access("queen2d")
  enable_variable_access("queen3d")
  enable_variable_access("qty")

  test "nqueens 2D example works end-to-end" do
    # Test the exact syntax from nqueens_dsl.exs
    problem =
      Problem.new(
        name: "N-Queens",
        description:
          "Place N queens on an N×N chessboard so that no two queens attack each other."
      )
      |> Problem.variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
      |> Problem.constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
      |> Problem.constraints([j <- 1..4], queen2d(:_, j) == 1, "One queen per column")
      |> Problem.objective(sum(queen2d(:_, :_)), direction: :minimize)

    # Verify problem structure
    assert problem.name == "N-Queens"
    assert map_size(problem.variables) > 0
    assert map_size(problem.constraints) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    queen2d_vars = Problem.get_variables_nd(problem, "queen2d")
    assert queen2d_vars != nil
    # 4x4 = 16 variables
    assert map_size(queen2d_vars) == 16

    # Verify constraints were created
    # At least 4 row + 4 column constraints
    assert map_size(problem.constraints) >= 8
  end

  test "nqueens 3D example works end-to-end" do
    # Test the 3D version from nqueens_dsl.exs
    problem =
      Problem.new(
        name: "N-Queens-3D",
        description:
          "Place N queens on an N×N×N chessboard so that no two queens attack each other."
      )
      |> Problem.variables(
        "queen3d",
        [i <- 1..4, j <- 1..4, k <- 1..4],
        :binary,
        "Queen position"
      )
      |> Problem.constraints([i <- 1..4, k <- 1..4], queen3d(i, :_, k) == 1, "One queen per row")
      |> Problem.constraints(
        [j <- 1..4, k <- 1..4],
        queen3d(:_, j, k) == 1,
        "One queen per column"
      )
      |> Problem.constraints(
        [i <- 1..4, j <- 1..4],
        queen3d(i, j, :_) == 1,
        "One queen per vertical"
      )
      |> Problem.objective(sum(queen3d(:_, :_, :_)), direction: :minimize)

    # Verify problem structure
    assert problem.name == "N-Queens-3D"
    assert map_size(problem.variables) > 0
    assert map_size(problem.constraints) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    queen3d_vars = Problem.get_variables_nd(problem, "queen3d")
    assert queen3d_vars != nil
    # 4x4x4 = 64 variables
    assert map_size(queen3d_vars) == 64

    # Verify constraints were created
    # At least 4x3 = 12 constraints
    assert map_size(problem.constraints) >= 12
  end

  test "diet problem example works end-to-end" do
    # Test the diet problem from nqueens_dsl.exs
    food_names = ["apple", "banana", "orange"]

    problem =
      Problem.new(
        name: "Diet Problem",
        description: "Minimize cost of food while meeting nutritional requirements"
      )
      |> Problem.variables("qty", [food <- food_names], :continuous, "Amount of food to buy")
      |> Problem.objective({:sum, [], [{:qty, [], [{:food, [], nil}]}]}, direction: :minimize)

    # Verify problem structure
    assert problem.name == "Diet Problem"
    assert map_size(problem.variables) > 0
    assert problem.direction == :minimize

    # Verify variables were created
    qty_vars = Problem.get_variables_nd(problem, "qty")
    assert qty_vars != nil
    # 3 food items
    assert map_size(qty_vars) == 3

    # Verify objective was set
    assert problem.objective != nil
  end

  test "chained constraints work correctly" do
    # Test chained constraints with single generator
    problem =
      Problem.new(name: "Chained Test")
      |> Problem.variables("x", [i <- 1..3], :binary, "Test variable")
      |> Problem.constraints([i <- 1..3], x(i) == 1, "row_#{i}")

    # Should create 3 constraints
    assert map_size(problem.constraints) == 3

    # Verify constraint names
    constraint_names = Map.keys(problem.constraints)
    assert "row_1" in constraint_names
    assert "row_2" in constraint_names
    assert "row_3" in constraint_names
  end

  test "chained constraints with multiple generators work correctly" do
    # Test chained constraints with multiple generators
    problem =
      Problem.new(name: "Multi-Generator Test")
      |> Problem.variables("x", [i <- 1..2, j <- 1..2], :binary, "Test variable")
      |> Problem.constraints([i <- 1..2, j <- 1..2], x(i, j) <= 1, "pos_#{i}_#{j}")

    # Should create 4 constraints (2x2)
    assert map_size(problem.constraints) == 4

    # Verify constraint names
    constraint_names = Map.keys(problem.constraints)
    assert "pos_1_1" in constraint_names
    assert "pos_1_2" in constraint_names
    assert "pos_2_1" in constraint_names
    assert "pos_2_2" in constraint_names
  end

  test "sum function works with different patterns" do
    problem =
      Problem.new(name: "Sum Test")
      |> Problem.variables("x", [i <- 1..3, j <- 1..3], :binary, "Test variable")

    # Test sum(x(:_, :_)) - sum all variables
    all_sum = sum(x(:_, :_))
    assert is_tuple(all_sum)
    assert elem(all_sum, 0) == :sum

    # Test sum(x(i, :_)) - sum for fixed i
    row_sum = sum(x(i, :_))
    assert is_tuple(row_sum)
    assert elem(row_sum, 0) == :sum

    # Test sum(x(:_, j)) - sum for fixed j
    col_sum = sum(x(:_, j))
    assert is_tuple(col_sum)
    assert elem(col_sum, 0) == :sum
  end

  test "variable access works with different patterns" do
    problem =
      Problem.new(name: "Variable Access Test")
      |> Problem.variables("x", [i <- 1..3, j <- 1..3], :binary, "Test variable")

    # Test x(i, :_) - fixed i, wildcard j
    var_access1 = x(i, :_)
    assert is_tuple(var_access1)
    assert elem(var_access1, 0) == :x
    assert elem(var_access1, 2) == [i, :_]

    # Test x(:_, j) - wildcard i, fixed j
    var_access2 = x(:_, j)
    assert is_tuple(var_access2)
    assert elem(var_access2, 0) == :x
    assert elem(var_access2, 2) == [:_, j]

    # Test x(:_, :_) - all wildcards
    var_access3 = x(:_, :_)
    assert is_tuple(var_access3)
    assert elem(var_access3, 0) == :x
    assert elem(var_access3, 2) == [:_, :_]
  end
end
