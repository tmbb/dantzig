defmodule Dantzig.DSL.MixedSyntaxTest do
  @moduledoc """
  Test mixed syntax: both bracket notation queen2d[i, :_] and function call queen2d(i, :_).
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "mixed syntax works in constraints" do
    # Test that we can use both bracket and function call syntax
    # This would be: queen2d[i, :_] == 1 and queen2d(i, :_) == 1

    # Bracket notation constraint
    bracket_constraint = {:==, [], [DSL.bracket_access(:queen2d, [1, :_]), 1]}

    # Function call notation constraint
    function_constraint = {:==, [], [DSL.var_access(:queen2d, [1, :_]), 1]}

    # Both should create the same AST structure
    assert bracket_constraint == function_constraint

    # Verify the structure
    assert is_tuple(bracket_constraint)
    assert elem(bracket_constraint, 0) == :==

    # Get the left side
    left_side = elem(bracket_constraint, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :queen2d
    assert elem(left_side, 2) == [1, :_]
  end

  test "mixed syntax works in sum expressions" do
    # Test that we can use both bracket and function call syntax in sums
    # This would be: sum(queen2d[:_, :_]) and sum(queen2d(:_, :_))

    # Bracket notation sum
    bracket_sum = {:sum, [], [DSL.bracket_access(:queen2d, [:_, :_])]}

    # Function call notation sum
    function_sum = {:sum, [], [DSL.var_access(:queen2d, [:_, :_])]}

    # Both should create the same AST structure
    assert bracket_sum == function_sum

    # Verify the structure
    assert is_tuple(bracket_sum)
    assert elem(bracket_sum, 0) == :sum

    # Get the expression inside sum
    expr = elem(bracket_sum, 2) |> hd()
    assert is_tuple(expr)
    assert elem(expr, 0) == :queen2d
    assert elem(expr, 2) == [:_, :_]
  end

  test "mixed syntax works with different variable names" do
    # Test with different variable names: qty[food] vs qty(food)

    # Bracket notation for diet problem
    bracket_qty = DSL.bracket_access(:qty, [:food])

    # Function call notation for diet problem
    function_qty = DSL.var_access(:qty, [:food])

    # Both should create the same AST structure
    assert bracket_qty == function_qty

    # Verify the structure
    assert is_tuple(bracket_qty)
    assert elem(bracket_qty, 0) == :qty
    assert elem(bracket_qty, 2) == [:food]
  end

  test "mixed syntax works with 3D variables" do
    # Test with 3D variables: queen3d[i, j, k] vs queen3d(i, j, k)

    # Bracket notation for 3D
    bracket_3d = DSL.bracket_access(:queen3d, [1, 2, 3])

    # Function call notation for 3D
    function_3d = DSL.var_access(:queen3d, [1, 2, 3])

    # Both should create the same AST structure
    assert bracket_3d == function_3d

    # Verify the structure
    assert is_tuple(bracket_3d)
    assert elem(bracket_3d, 0) == :queen3d
    assert elem(bracket_3d, 2) == [1, 2, 3]
  end

  test "mixed syntax works in complex expressions" do
    # Test complex expressions with both syntaxes
    # This would be: queen2d[i, :_] + queen2d[:_, j] == 1

    # Create a complex constraint using both syntaxes
    complex_constraint = {
      :==,
      [],
      [
        {
          :+,
          [],
          [
            # Bracket notation
            DSL.bracket_access(:queen2d, [1, :_]),
            # Function call notation
            DSL.var_access(:queen2d, [:_, 2])
          ]
        },
        1
      ]
    }

    # Verify the structure
    assert is_tuple(complex_constraint)
    assert elem(complex_constraint, 0) == :==

    # Get the left side (addition)
    left_side = elem(complex_constraint, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :+

    # Get the operands
    operands = elem(left_side, 2)
    assert length(operands) == 2

    # First operand (bracket notation)
    first_operand = Enum.at(operands, 0)
    assert is_tuple(first_operand)
    assert elem(first_operand, 0) == :queen2d
    assert elem(first_operand, 2) == [1, :_]

    # Second operand (function call notation)
    second_operand = Enum.at(operands, 1)
    assert is_tuple(second_operand)
    assert elem(second_operand, 0) == :queen2d
    assert elem(second_operand, 2) == [:_, 2]
  end
end
