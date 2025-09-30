defmodule Dantzig.DSL.Arithmetic.ASTDebugTest do
  @moduledoc """
  Debug test to see what the AST looks like for unary minus expressions.
  """

  use ExUnit.Case, async: true

  test "Debug AST for unary minus expressions" do
    # Let's see what the AST looks like for different unary minus expressions

    # Test 1: -1.0
    ast1 = quote do: -1.0
    IO.puts("AST for -1.0: #{inspect(ast1)}")

    # Test 2: -qty(food) - this won't work because qty is not defined
    # But we can see the structure
    ast2 = quote do: -qty(food)
    IO.puts("AST for -qty(food): #{inspect(ast2)}")

    # Test 3: -variable
    ast3 = quote do: -variable
    IO.puts("AST for -variable: #{inspect(ast3)}")

    # Test 4: -1
    ast4 = quote do: -1
    IO.puts("AST for -1: #{inspect(ast4)}")

    # Test 5: -1.0 * qty(food)
    ast5 = quote do: -1.0 * qty(food)
    IO.puts("AST for -1.0 * qty(food): #{inspect(ast5)}")

    # Test 6: qty(food) * -1.0
    ast6 = quote do: qty(food) * -1.0
    IO.puts("AST for qty(food) * -1.0: #{inspect(ast6)}")

    assert true
  end
end
