defmodule Dantzig.DSL.MacroParserTest do
  @moduledoc """
  Test to understand why macros can't handle invalid syntax.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "test if macros can handle invalid syntax" do
    # This should fail because 'across' is not a valid Elixir operator
    # The parser will fail before any macro can see it

    # Let's test this theory:
    try do
      # This should fail at parse time, not macro time
      Code.eval_string("sum(1 across 2)")
    rescue
      SyntaxError ->
        # Expected - parser fails before macro can see it
        assert true

      _ ->
        # Unexpected - something else happened
        assert false, "Expected SyntaxError but got something else"
    end
  end

  test "test if macros can handle valid syntax" do
    # This should work because 'in' is a valid Elixir operator
    try do
      # This should parse successfully
      Code.eval_string("sum(1 in 2)")
    rescue
      SyntaxError ->
        # Unexpected - this should parse
        assert false, "Expected this to parse but got SyntaxError"

      _ ->
        # Expected - parser succeeds, macro can process it
        assert true
    end
  end

  test "demonstrate the difference between parser and macro errors" do
    # Parser errors happen before macros can see the code
    # Macro errors happen after parsing but during macro expansion

    # This is a parser error (happens before macros):
    assert_raise SyntaxError, fn ->
      Code.eval_string("sum(1 across 2)")
    end

    # This is a macro error (happens during macro expansion):
    assert_raise CompileError, fn ->
      Code.eval_string("defmacro test_macro(x), do: x + 1; test_macro(1)")
    end
  end
end
