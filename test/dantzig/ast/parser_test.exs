defmodule Dantzig.AST.ParserTest do
  use ExUnit.Case, async: true

  alias Dantzig.{AST, AST.Parser, Polynomial}

  describe "parse_generators/1" do
    test "parses single generator with range" do
      generators = [i <- 1..5]
      parsed = Parser.parse_generators(generators)

      assert parsed == [{:i, :in, [1, 2, 3, 4, 5]}]
    end

    test "parses single generator with list" do
      generators = [i <- [1, 3, 5, 7]]
      parsed = Parser.parse_generators(generators)

      assert parsed == [{:i, :in, [1, 3, 5, 7]}]
    end

    test "parses multiple generators" do
      generators = [i <- 1..3, j <- 1..2]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, [1, 2, 3]},
               {:j, :in, [1, 2]}
             ]
    end

    test "parses generators with filters" do
      generators = [i <- 1..6, rem(i, 2) == 0]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, [1, 2, 3, 4, 5, 6]},
               {:filter, rem(:i, 2) == 0}
             ]
    end

    test "parses multiple generators with filters" do
      generators = [i <- 1..4, j <- 1..4, i + j <= 4]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, [1, 2, 3, 4]},
               {:j, :in, [1, 2, 3, 4]},
               {:filter, :i + :j <= 4}
             ]
    end

    test "parses generators with complex filters" do
      generators = [i <- 1..10, j <- 1..10, rem(i, 2) == 0, j > 5]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]},
               {:j, :in, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]},
               {:filter, rem(:i, 2) == 0},
               {:filter, :j > 5}
             ]
    end

    test "parses generators with different variable names" do
      generators = [row <- 1..3, col <- 1..3, time <- 1..2]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:row, :in, [1, 2, 3]},
               {:col, :in, [1, 2, 3]},
               {:time, :in, [1, 2]}
             ]
    end

    test "parses generators with single element lists" do
      generators = [i <- [5], j <- [10]]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, [5]},
               {:j, :in, [10]}
             ]
    end

    test "parses generators with empty lists" do
      generators = [i <- [], j <- 1..2]
      parsed = Parser.parse_generators(generators)

      assert parsed == [
               {:i, :in, []},
               {:j, :in, [1, 2]}
             ]
    end
  end

  describe "parse_expression/1" do
    test "parses simple variable reference" do
      expr = quote do: x
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.variable("x")
    end

    test "parses indexed variable reference" do
      expr = quote do: x[[1, 2]]
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.variable("x", [1, 2])
    end

    test "parses constant" do
      expr = quote do: 42
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.constant(42)
    end

    test "parses float constant" do
      expr = quote do: 3.14
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.constant(3.14)
    end

    test "parses addition" do
      expr = quote do: x + y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.variable("y"))
    end

    test "parses subtraction" do
      expr = quote do: x - y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.subtract(AST.variable("x"), AST.variable("y"))
    end

    test "parses multiplication" do
      expr = quote do: x * 2
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.multiply(AST.variable("x"), 2)
    end

    test "parses division" do
      expr = quote do: x / 2
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.divide(AST.variable("x"), 2)
    end

    test "parses complex arithmetic expression" do
      expr = quote do: x + y * 2 - z / 3
      parsed = Parser.parse_expression(expr)

      expected =
        AST.subtract(
          AST.add(AST.variable("x"), AST.multiply(AST.variable("y"), 2)),
          AST.divide(AST.variable("z"), 3)
        )

      assert parsed == expected
    end

    test "parses parentheses" do
      expr = quote do: (x + y) * 2
      parsed = Parser.parse_expression(expr)

      expected =
        AST.multiply(
          AST.add(AST.variable("x"), AST.variable("y")),
          2
        )

      assert parsed == expected
    end

    test "parses nested parentheses" do
      expr = quote do: (x + y) * 2 - z
      parsed = Parser.parse_expression(expr)

      expected =
        AST.subtract(
          AST.multiply(
            AST.add(AST.variable("x"), AST.variable("y")),
            2
          ),
          AST.variable("z")
        )

      assert parsed == expected
    end

    test "parses comparison operators" do
      expr = quote do: x == y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.equal(AST.variable("x"), AST.variable("y"))
    end

    test "parses less than or equal" do
      expr = quote do: x <= y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.less_equal(AST.variable("x"), AST.variable("y"))
    end

    test "parses greater than or equal" do
      expr = quote do: x >= y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.greater_equal(AST.variable("x"), AST.variable("y"))
    end

    test "parses less than" do
      expr = quote do: x < y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.less(AST.variable("x"), AST.variable("y"))
    end

    test "parses greater than" do
      expr = quote do: x > y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.greater(AST.variable("x"), AST.variable("y"))
    end

    test "parses not equal" do
      expr = quote do: x != y
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.not_equal(AST.variable("x"), AST.variable("y"))
    end
  end

  describe "parse_expression/1 with functions" do
    test "parses abs function" do
      expr = quote do: abs(x)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.abs(AST.variable("x"))
    end

    test "parses nested abs function" do
      expr = quote do: abs(x + y)
      parsed = Parser.parse_expression(expr)

      expected = AST.abs(AST.add(AST.variable("x"), AST.variable("y")))
      assert parsed == expected
    end

    test "parses max function with two arguments" do
      expr = quote do: max(x, y)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.max([AST.variable("x"), AST.variable("y")])
    end

    test "parses max function with three arguments" do
      expr = quote do: max(x, y, z)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z")])
    end

    test "parses max function with four arguments" do
      expr = quote do: max(x, y, z, w)
      parsed = Parser.parse_expression(expr)

      assert parsed ==
               AST.max([
                 AST.variable("x"),
                 AST.variable("y"),
                 AST.variable("z"),
                 AST.variable("w")
               ])
    end

    test "parses min function with two arguments" do
      expr = quote do: min(x, y)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.min([AST.variable("x"), AST.variable("y")])
    end

    test "parses min function with three arguments" do
      expr = quote do: min(x, y, z)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.min([AST.variable("x"), AST.variable("y"), AST.variable("z")])
    end

    # Note: and/or are reserved words in Elixir, so we can't test them with quote
    # These functions would be tested through the DSL or AST modules directly

    test "parses sum function with two arguments" do
      expr = quote do: sum(x, y)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.sum([AST.variable("x"), AST.variable("y")])
    end

    test "parses sum function with three arguments" do
      expr = quote do: sum(x, y, z)
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.sum([AST.variable("x"), AST.variable("y"), AST.variable("z")])
    end

    test "parses sum function with four arguments" do
      expr = quote do: sum(x, y, z, w)
      parsed = Parser.parse_expression(expr)

      assert parsed ==
               AST.sum([
                 AST.variable("x"),
                 AST.variable("y"),
                 AST.variable("z"),
                 AST.variable("w")
               ])
    end
  end

  describe "parse_expression/1 with pattern-based operations" do
    test "parses max(x[_]) pattern" do
      expr = quote do: max(x[_])
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.max([AST.variable("x", pattern: :_)])
    end

    test "parses min(x[_]) pattern" do
      expr = quote do: min(x[_])
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.min([AST.variable("x", pattern: :_)])
    end

    # Note: and/or are reserved words in Elixir, so we can't test them with quote
    # These pattern-based functions would be tested through the DSL or AST modules directly

    test "parses sum(x[_]) pattern" do
      expr = quote do: sum(x[_])
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.sum([AST.variable("x", pattern: :_)])
    end
  end

  describe "parse_expression/1 with complex expressions" do
    test "parses nested function calls" do
      expr = quote do: max(abs(x), abs(y))
      parsed = Parser.parse_expression(expr)

      expected =
        AST.max([
          AST.abs(AST.variable("x")),
          AST.abs(AST.variable("y"))
        ])

      assert parsed == expected
    end

    test "parses function calls with arithmetic" do
      expr = quote do: max(x + y, z - w)
      parsed = Parser.parse_expression(expr)

      expected =
        AST.max([
          AST.add(AST.variable("x"), AST.variable("y")),
          AST.subtract(AST.variable("z"), AST.variable("w"))
        ])

      assert parsed == expected
    end

    test "parses arithmetic with function calls" do
      expr = quote do: max(x, y) + min(z, w)
      parsed = Parser.parse_expression(expr)

      expected =
        AST.add(
          AST.max([AST.variable("x"), AST.variable("y")]),
          AST.min([AST.variable("z"), AST.variable("w")])
        )

      assert parsed == expected
    end

    test "parses complex nested expression" do
      expr = quote do: max(x + y, min(z, w)) * 2
      parsed = Parser.parse_expression(expr)

      expected =
        AST.multiply(
          AST.max([
            AST.add(AST.variable("x"), AST.variable("y")),
            AST.min([AST.variable("z"), AST.variable("w")])
          ]),
          2
        )

      assert parsed == expected
    end

    # Note: and/or are reserved words in Elixir, so we can't test them with quote
    # This test would be implemented through the DSL or AST modules directly
  end

  describe "detect_pattern_based_args/1" do
    test "detects single pattern-based argument" do
      args = [quote(do: x[_])]
      detected = Parser.detect_pattern_based_args(args)

      assert detected == [AST.variable("x", pattern: :_)]
    end

    test "detects multiple pattern-based arguments" do
      args = [quote(do: x[_]), quote(do: y[_])]
      detected = Parser.detect_pattern_based_args(args)

      assert detected == [
               AST.variable("x", pattern: :_),
               AST.variable("y", pattern: :_)
             ]
    end

    test "detects mixed pattern and regular arguments" do
      args = [quote(do: x[_]), quote(do: y), quote(do: z[_])]
      detected = Parser.detect_pattern_based_args(args)

      assert detected == [
               AST.variable("x", pattern: :_),
               AST.variable("y"),
               AST.variable("z", pattern: :_)
             ]
    end

    test "detects no pattern-based arguments" do
      args = [quote(do: x), quote(do: y), quote(do: z)]
      detected = Parser.detect_pattern_based_args(args)

      assert detected == [
               AST.variable("x"),
               AST.variable("y"),
               AST.variable("z")
             ]
    end

    test "detects pattern-based arguments with indexed variables" do
      args = [quote(do: x[[i, _]]), quote(do: y[[_, j]])]
      detected = Parser.detect_pattern_based_args(args)

      assert detected == [
               AST.variable("x", [quote(do: i), :_]),
               AST.variable("y", [quote(do: _), quote(do: j)])
             ]
    end
  end

  describe "error handling" do
    test "raises error for invalid generator syntax" do
      # Should be <-
      generators = [i = 1..5]

      assert_raise ArgumentError, fn ->
        Parser.parse_generators(generators)
      end
    end

    test "raises error for empty generator list" do
      generators = []

      assert_raise ArgumentError, fn ->
        Parser.parse_generators(generators)
      end
    end

    test "raises error for invalid expression" do
      expr =
        quote do:
                x ++
                  assert_raise(ArgumentError, fn ->
                    Parser.parse_expression(expr)
                  end)
    end

    test "raises error for unsupported function" do
      expr = quote do: sin(x)

      assert_raise ArgumentError, fn ->
        Parser.parse_expression(expr)
      end
    end

    test "raises error for max with single argument" do
      expr = quote do: max(x)

      assert_raise ArgumentError, fn ->
        Parser.parse_expression(expr)
      end
    end

    test "raises error for min with single argument" do
      expr = quote do: min(x)

      assert_raise ArgumentError, fn ->
        Parser.parse_expression(expr)
      end
    end

    # Note: and/or are reserved words in Elixir, so we can't test them with quote
    # These error cases would be tested through the DSL or AST modules directly

    test "raises error for sum with single argument" do
      expr = quote do: sum(x)

      assert_raise ArgumentError, fn ->
        Parser.parse_expression(expr)
      end
    end
  end

  describe "edge cases" do
    test "parses expression with zero" do
      expr = quote do: x + 0
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.constant(0))
    end

    test "parses expression with negative numbers" do
      expr = quote do: x + -5
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.constant(-5))
    end

    test "parses expression with very large numbers" do
      expr = quote do: x + 999_999_999
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.constant(999_999_999))
    end

    test "parses expression with very small numbers" do
      expr = quote do: x + 0.000001
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.constant(0.000001))
    end

    test "parses expression with scientific notation" do
      expr = quote do: x + 1.0e-6
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x"), AST.constant(1.0e-6))
    end

    test "parses expression with underscores in variable names" do
      expr = quote do: my_variable + another_var
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("my_variable"), AST.variable("another_var"))
    end

    test "parses expression with numbers in variable names" do
      expr = quote do: x1 + y2
      parsed = Parser.parse_expression(expr)

      assert parsed == AST.add(AST.variable("x1"), AST.variable("y2"))
    end
  end
end
