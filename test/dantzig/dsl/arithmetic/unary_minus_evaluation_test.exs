defmodule Dantzig.DSL.Arithmetic.UnaryMinusEvaluationTest do
  @moduledoc """
  Progressive test to isolate and fix unary minus evaluation issues.

  This test focuses specifically on the unary minus evaluation in the evaluate_expression function.
  """

  use ExUnit.Case, async: true

  describe "Step 1: Direct unary minus evaluation" do
    test "evaluate_expression with -1.0" do
      # Test: Direct evaluation of -1.0
      # Expected: -1.0
      # Error context: This should work with the unary minus handler we added

      ast = quote do: -1.0
      result = Dantzig.Problem.DSL.Internal.evaluate_expression(ast)

      assert result == -1.0,
             "Expected -1.0, got #{inspect(result)}"
    end

    test "evaluate_expression with -1" do
      # Test: Direct evaluation of -1
      # Expected: -1
      # Error context: This should work with the unary minus handler we added

      ast = quote do: -1
      result = Dantzig.Problem.DSL.Internal.evaluate_expression(ast)

      assert result == -1,
             "Expected -1, got #{inspect(result)}"
    end

    test "evaluate_expression with -2.5" do
      # Test: Direct evaluation of -2.5
      # Expected: -2.5
      # Error context: This should work with the unary minus handler we added

      ast = quote do: -2.5
      result = Dantzig.Problem.DSL.Internal.evaluate_expression(ast)

      assert result == -2.5,
             "Expected -2.5, got #{inspect(result)}"
    end
  end

  describe "Step 2: Unary minus with variables (expected to fail)" do
    test "evaluate_expression with -variable (expected to fail)" do
      # Test: Direct evaluation of -variable
      # Expected: This should fail because 'variable' is not defined
      # Error context: This tests the unary minus handler with undefined variables

      ast = quote do: -variable

      assert_raise ArgumentError, ~r/undefined variable|Cannot evaluate expression/, fn ->
        Dantzig.Problem.DSL.Internal.evaluate_expression(ast)
      end
    end
  end

  describe "Step 3: Unary minus in polynomial context" do
    test "parse_expression_to_polynomial with -1.0" do
      # Test: Parse -1.0 to polynomial
      # Expected: Polynomial.const(-1.0)
      # Error context: This tests the unary minus handler in polynomial parsing

      ast = quote do: -1.0

      result =
        Dantzig.Problem.DSL.Internal.parse_expression_to_polynomial(ast, %{}, %Dantzig.Problem{})

      assert %Dantzig.Polynomial{} = result,
             "Expected a polynomial, got #{inspect(result)}"

      # Check that it's a constant polynomial with value -1.0
      assert Dantzig.Polynomial.serialize(result) == "- 1.0 ",
             "Expected '- 1.0 ', got '#{Dantzig.Polynomial.serialize(result)}'"
    end

    test "parse_expression_to_polynomial with -2.5" do
      # Test: Parse -2.5 to polynomial
      # Expected: Polynomial.const(-2.5)
      # Error context: This tests the unary minus handler in polynomial parsing

      ast = quote do: -2.5

      result =
        Dantzig.Problem.DSL.Internal.parse_expression_to_polynomial(ast, %{}, %Dantzig.Problem{})

      assert %Dantzig.Polynomial{} = result,
             "Expected a polynomial, got #{inspect(result)}"

      # Check that it's a constant polynomial with value -2.5
      assert Dantzig.Polynomial.serialize(result) == "- 2.5 ",
             "Expected '- 2.5 ', got '#{Dantzig.Polynomial.serialize(result)}'"
    end
  end
end
