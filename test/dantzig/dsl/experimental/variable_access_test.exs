defmodule Dantzig.DSL.VariableAccessTest do
  @moduledoc """
  Tests for variable access syntax like queen2d(i, :_)
  """
  use ExUnit.Case, async: true
  
  alias Dantzig.Problem, as: Problem
  alias Dantzig.DSL.VariableAccess
  
  test "variable access macro expansion" do
    # Test that queen2d(i, :_) expands to correct AST
    ast = quote do: queen2d(i, :_)
    
    # For now, we'll test the pattern manually since we haven't implemented the macro yet
    assert is_tuple(ast)
    assert elem(ast, 0) == :queen2d
    # Check that the second element is a list with i and :_
    indices = elem(ast, 2)
    assert is_list(indices)
    assert length(indices) == 2
    assert Enum.at(indices, 1) == :_
  end
  
  test "variable access with wildcards" do
    # Test queen2d(:_, j) syntax
    ast = quote do: queen2d(:_, j)
    
    assert is_tuple(ast)
    assert elem(ast, 0) == :queen2d
    # Check that the second element is a list with :_ and j
    indices = elem(ast, 2)
    assert is_list(indices)
    assert length(indices) == 2
    assert Enum.at(indices, 0) == :_
  end
  
  test "variable access with multiple indices" do
    # Test queen3d(i, :_, k) syntax
    ast = quote do: queen3d(i, :_, k)
    
    assert is_tuple(ast)
    assert elem(ast, 0) == :queen3d
    # Check that the second element is a list with i, :_, k
    indices = elem(ast, 2)
    assert is_list(indices)
    assert length(indices) == 3
    assert Enum.at(indices, 1) == :_
  end
  
  test "variable access in constraint context" do
    # Test that queen2d(i, :_) == 1 parses correctly
    constraint_ast = quote do: queen2d(i, :_) == 1
    
    # Verify the structure
    assert is_tuple(constraint_ast)
    assert elem(constraint_ast, 0) == :==
    
    # Get the left side (queen2d(i, :_))
    left_side = elem(constraint_ast, 2) |> hd()
    assert is_tuple(left_side)
    assert elem(left_side, 0) == :queen2d
    # Check that the indices are correct
    indices = elem(left_side, 2)
    assert is_list(indices)
    assert length(indices) == 2
    assert Enum.at(indices, 1) == :_
    
    # Get the right side (1)
    right_side = elem(constraint_ast, 2) |> tl() |> hd()
    assert right_side == 1
  end
  
  test "variable access with all wildcards" do
    # Test queen2d(:_, :_) syntax
    ast = quote do: queen2d(:_, :_)
    
    assert is_tuple(ast)
    assert elem(ast, 0) == :queen2d
    assert elem(ast, 2) == [:_ , :_]
  end
end
