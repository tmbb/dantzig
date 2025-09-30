defmodule Dantzig.DSL.ConstraintParsingTest do
  @moduledoc """
  Tests for constraint parsing functionality
  """
  use ExUnit.Case, async: true

  alias Dantzig.Problem, as: Problem
  alias Dantzig.DSL.ConstraintParser

  setup do
    # Create a test problem with variables using proper generator syntax
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "queen2d",
        [{:<-, [], [quote(do: i), 1..2]}, {:<-, [], [quote(do: j), 1..2]}],
        :binary,
        description: "Queen position"
      )
      |> Problem.variables(
        "qty",
        [{:<-, [], [quote(do: food), ["apple", "banana"]]}],
        :continuous,
        description: "Food quantity"
      )

    %{problem: problem}
  end

  test "simple constraint parsing", %{problem: problem} do
    # Test queen2d(i, :_) == 1
    constraint_ast = quote do: queen2d(i, :_) == 1
    bindings = %{i: 1}

    result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 1
  end

  test "sum constraint parsing", %{problem: problem} do
    # Test sum(queen2d(:_, :_)) == 4
    constraint_ast = quote do: sum(queen2d(:_, :_)) == 4

    result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 4
  end

  test "inequality constraint parsing", %{problem: problem} do
    # Test sum(qty(food)) <= 10
    constraint_ast = quote do: sum(qty(food)) <= 10

    result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :<=
    assert result.right_hand_side == 10
  end

  test "greater than or equal constraint parsing", %{problem: problem} do
    # Test sum(qty(food)) >= 5
    constraint_ast = quote do: sum(qty(food)) >= 5

    result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :>=
    assert result.right_hand_side == 5
  end

  test "constraint with variable bindings", %{problem: problem} do
    # Test queen2d(i, :_) == 1 with i = 1
    constraint_ast = quote do: queen2d(i, :_) == 1
    bindings = %{i: 1}

    result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 1
  end

  test "constraint with complex expression", %{problem: problem} do
    # Test sum(queen2d(i, :_)) == 1 with i = 1
    constraint_ast = quote do: sum(queen2d(i, :_)) == 1
    bindings = %{i: 1}

    result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 1
  end

  test "constraint with numeric right hand side", %{problem: problem} do
    # Test sum(queen2d(:_, :_)) == 4
    constraint_ast = quote do: sum(queen2d(:_, :_)) == 4

    result = ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 4
  end

  test "constraint with variable right hand side", %{problem: problem} do
    # Test sum(queen2d(:_, :_)) == n
    constraint_ast = quote do: sum(queen2d(:_, :_)) == n
    bindings = %{n: 4}

    result = ConstraintParser.parse_constraint_expression(constraint_ast, bindings, problem)

    assert is_struct(result, Dantzig.Constraint)
    assert result.operator == :==
    assert result.right_hand_side == 4
  end

  test "error handling for invalid constraint", %{problem: problem} do
    # Test invalid constraint expression
    constraint_ast = quote do: invalid_expression

    assert_raise ArgumentError, fn ->
      ConstraintParser.parse_constraint_expression(constraint_ast, %{}, problem)
    end
  end
end
