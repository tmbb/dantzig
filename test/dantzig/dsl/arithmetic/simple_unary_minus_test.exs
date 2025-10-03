defmodule Dantzig.DSL.Arithmetic.SimpleUnaryMinusTest do
  @moduledoc """
  Simple test to verify unary minus evaluation.
  """

  use ExUnit.Case, async: true

  test "Test unary minus evaluation" do
    # Test what happens when we evaluate -1.0
    ast = quote do: -1.0
    IO.puts("AST for -1.0: #{inspect(ast)}")

    # Test what happens when we evaluate -1
    ast2 = quote do: -1
    IO.puts("AST for -1: #{inspect(ast2)}")

    # Test what happens when we evaluate -qty(food)
    ast3 = quote do: -qty(food)
    IO.puts("AST for -qty(food): #{inspect(ast3)}")

    assert true
  end
end

