defmodule Dantzig.AST.AnalyzerTest do
  use ExUnit.Case, async: true

  alias Dantzig.{AST, AST.Analyzer, Polynomial}

  describe "analyze_expression/1" do
    test "analyzes simple variable" do
      expr = AST.variable("x")
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes constant" do
      expr = AST.constant(42.0)
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == []
      assert analysis.contains_non_linear == false
    end

    test "analyzes addition of variables" do
      expr = AST.add(AST.variable("x"), AST.variable("y"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes subtraction of variables" do
      expr = AST.subtract(AST.variable("x"), AST.variable("y"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes multiplication by constant" do
      expr = AST.multiply(AST.variable("x"), 2.0)
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes division by constant" do
      expr = AST.divide(AST.variable("x"), 2.0)
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes multiplication of variables as non-linear" do
      expr = AST.multiply(AST.variable("x"), AST.variable("y"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes division of variables as non-linear" do
      expr = AST.divide(AST.variable("x"), AST.variable("y"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes abs function as non-linear" do
      expr = AST.abs(AST.variable("x"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes max function as non-linear" do
      expr = AST.max([AST.variable("x"), AST.variable("y")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes min function as non-linear" do
      expr = AST.min([AST.variable("x"), AST.variable("y")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes and function as non-linear" do
      expr = AST.and([AST.variable("x"), AST.variable("y")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes or function as non-linear" do
      expr = AST.or([AST.variable("x"), AST.variable("y")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes if-then-else as non-linear" do
      expr = AST.if_then_else(AST.variable("c"), AST.variable("x"), AST.variable("y"))
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["c", "x", "y"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes piecewise linear as non-linear" do
      expr = AST.piecewise_linear(AST.variable("x"), [0.0, 1.0], [1.0, 2.0], [0.0, -1.0])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes sum function as linear" do
      expr = AST.sum([AST.variable("x"), AST.variable("y"), AST.variable("z")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y", "z"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes complex linear expression" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), 2.0),
          AST.subtract(AST.variable("y"), AST.multiply(AST.variable("z"), 3.0))
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y", "z"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes complex non-linear expression" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), AST.variable("y")),
          AST.abs(AST.variable("z"))
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes nested non-linear expressions" do
      expr =
        AST.max([
          AST.abs(AST.variable("x")),
          AST.min([AST.variable("y"), AST.variable("z")])
        ])

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes variadic max function" do
      expr = AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes variadic min function" do
      expr = AST.min([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes variadic and function" do
      expr = AST.and([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes variadic or function" do
      expr = AST.or([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes variadic sum function" do
      expr = AST.sum([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == false
    end

    test "analyzes pattern-based max function" do
      expr = AST.max([AST.variable("x", pattern: :_)])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes pattern-based min function" do
      expr = AST.min([AST.variable("x", pattern: :_)])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes pattern-based and function" do
      expr = AST.and([AST.variable("x", pattern: :_)])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes pattern-based or function" do
      expr = AST.or([AST.variable("x", pattern: :_)])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "analyzes pattern-based sum function" do
      expr = AST.sum([AST.variable("x", pattern: :_)])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == false
    end
  end

  describe "get_variables/1" do
    test "extracts variables from simple expression" do
      expr = AST.variable("x")
      variables = Analyzer.get_variables(expr)

      assert variables == ["x"]
    end

    test "extracts variables from constant" do
      expr = AST.constant(42.0)
      variables = Analyzer.get_variables(expr)

      assert variables == []
    end

    test "extracts variables from addition" do
      expr = AST.add(AST.variable("x"), AST.variable("y"))
      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y"]
    end

    test "extracts variables from complex expression" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), 2.0),
          AST.subtract(AST.variable("y"), AST.multiply(AST.variable("z"), 3.0))
        )

      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y", "z"]
    end

    test "extracts variables from non-linear expression" do
      expr = AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z")])
      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y", "z"]
    end

    test "extracts variables from nested expression" do
      expr =
        AST.add(
          AST.abs(AST.variable("x")),
          AST.min([AST.variable("y"), AST.variable("z")])
        )

      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y", "z"]
    end

    test "extracts variables from variadic expression" do
      expr = AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z"), AST.variable("w")])
      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y", "z", "w"]
    end

    test "extracts variables from pattern-based expression" do
      expr = AST.max([AST.variable("x", pattern: :_)])
      variables = Analyzer.get_variables(expr)

      assert variables == ["x"]
    end

    test "extracts unique variables from expression with duplicates" do
      expr =
        AST.add(
          AST.variable("x"),
          AST.add(AST.variable("y"), AST.variable("x"))
        )

      variables = Analyzer.get_variables(expr)

      assert variables == ["x", "y"]
    end
  end

  describe "contains_non_linear?/1" do
    test "returns false for linear expressions" do
      expr = AST.add(AST.variable("x"), AST.variable("y"))
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns false for constants" do
      expr = AST.constant(42.0)
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns false for simple variables" do
      expr = AST.variable("x")
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns false for multiplication by constant" do
      expr = AST.multiply(AST.variable("x"), 2.0)
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns false for division by constant" do
      expr = AST.divide(AST.variable("x"), 2.0)
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns false for sum function" do
      expr = AST.sum([AST.variable("x"), AST.variable("y")])
      assert Analyzer.contains_non_linear?(expr) == false
    end

    test "returns true for multiplication of variables" do
      expr = AST.multiply(AST.variable("x"), AST.variable("y"))
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for division of variables" do
      expr = AST.divide(AST.variable("x"), AST.variable("y"))
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for abs function" do
      expr = AST.abs(AST.variable("x"))
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for max function" do
      expr = AST.max([AST.variable("x"), AST.variable("y")])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for min function" do
      expr = AST.min([AST.variable("x"), AST.variable("y")])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for and function" do
      expr = AST.and([AST.variable("x"), AST.variable("y")])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for or function" do
      expr = AST.or([AST.variable("x"), AST.variable("y")])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for if-then-else function" do
      expr = AST.if_then_else(AST.variable("c"), AST.variable("x"), AST.variable("y"))
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for piecewise linear function" do
      expr = AST.piecewise_linear(AST.variable("x"), [0.0, 1.0], [1.0, 2.0], [0.0, -1.0])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for nested non-linear expressions" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), AST.variable("y")),
          AST.abs(AST.variable("z"))
        )

      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for variadic non-linear functions" do
      expr = AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z")])
      assert Analyzer.contains_non_linear?(expr) == true
    end

    test "returns true for pattern-based non-linear functions" do
      expr = AST.max([AST.variable("x", pattern: :_)])
      assert Analyzer.contains_non_linear?(expr) == true
    end
  end

  describe "is_linear?/1" do
    test "returns true for linear expressions" do
      expr = AST.add(AST.variable("x"), AST.variable("y"))
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns true for constants" do
      expr = AST.constant(42.0)
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns true for simple variables" do
      expr = AST.variable("x")
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns true for multiplication by constant" do
      expr = AST.multiply(AST.variable("x"), 2.0)
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns true for division by constant" do
      expr = AST.divide(AST.variable("x"), 2.0)
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns true for sum function" do
      expr = AST.sum([AST.variable("x"), AST.variable("y")])
      assert Analyzer.is_linear?(expr) == true
    end

    test "returns false for multiplication of variables" do
      expr = AST.multiply(AST.variable("x"), AST.variable("y"))
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for division of variables" do
      expr = AST.divide(AST.variable("x"), AST.variable("y"))
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for abs function" do
      expr = AST.abs(AST.variable("x"))
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for max function" do
      expr = AST.max([AST.variable("x"), AST.variable("y")])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for min function" do
      expr = AST.min([AST.variable("x"), AST.variable("y")])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for and function" do
      expr = AST.and([AST.variable("x"), AST.variable("y")])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for or function" do
      expr = AST.or([AST.variable("x"), AST.variable("y")])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for if-then-else function" do
      expr = AST.if_then_else(AST.variable("c"), AST.variable("x"), AST.variable("y"))
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for piecewise linear function" do
      expr = AST.piecewise_linear(AST.variable("x"), [0.0, 1.0], [1.0, 2.0], [0.0, -1.0])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for nested non-linear expressions" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), AST.variable("y")),
          AST.abs(AST.variable("z"))
        )

      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for variadic non-linear functions" do
      expr = AST.max([AST.variable("x"), AST.variable("y"), AST.variable("z")])
      assert Analyzer.is_linear?(expr) == false
    end

    test "returns false for pattern-based non-linear functions" do
      expr = AST.max([AST.variable("x", pattern: :_)])
      assert Analyzer.is_linear?(expr) == false
    end
  end

  describe "edge cases" do
    test "handles empty variadic functions" do
      expr = AST.max([])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == []
      assert analysis.contains_non_linear == true
    end

    test "handles single argument variadic functions" do
      expr = AST.max([AST.variable("x")])
      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x"]
      assert analysis.contains_non_linear == true
    end

    test "handles very deep nesting" do
      expr =
        AST.add(
          AST.add(
            AST.add(AST.variable("x"), AST.variable("y")),
            AST.add(AST.variable("z"), AST.variable("w"))
          ),
          AST.add(
            AST.add(AST.variable("a"), AST.variable("b")),
            AST.add(AST.variable("c"), AST.variable("d"))
          )
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y", "z", "w", "a", "b", "c", "d"]
      assert analysis.contains_non_linear == false
    end

    test "handles mixed linear and non-linear parts" do
      expr =
        AST.add(
          # Linear part
          AST.add(AST.variable("x"), AST.variable("y")),
          # Non-linear part
          AST.max([AST.variable("z"), AST.variable("w")])
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == false
      assert analysis.variables == ["x", "y", "z", "w"]
      assert analysis.contains_non_linear == true
    end

    test "handles expressions with zero coefficients" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), 0.0),
          AST.variable("y")
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == false
    end

    test "handles expressions with negative coefficients" do
      expr =
        AST.add(
          AST.multiply(AST.variable("x"), -2.0),
          AST.variable("y")
        )

      analysis = Analyzer.analyze_expression(expr)

      assert analysis.is_linear == true
      assert analysis.variables == ["x", "y"]
      assert analysis.contains_non_linear == false
    end
  end
end
