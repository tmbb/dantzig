defmodule Dantzig.ASTTest do
  use ExUnit.Case, async: true

  alias Dantzig.AST

  describe "AST node creation" do
    test "creates variable node" do
      var = %AST.Variable{name: "x", indices: [], pattern: nil}
      assert var.name == "x"
      assert var.indices == []
      assert var.pattern == nil
    end

    test "creates indexed variable node" do
      var = %AST.Variable{name: "x", indices: [1, 2], pattern: nil}
      assert var.name == "x"
      assert var.indices == [1, 2]
      assert var.pattern == nil
    end

    test "creates pattern variable node" do
      var = %AST.Variable{name: "x", indices: [], pattern: :_}
      assert var.name == "x"
      assert var.indices == []
      assert var.pattern == :_
    end

    test "creates indexed pattern variable node" do
      var = %AST.Variable{name: "x", indices: [1, :_], pattern: nil}
      assert var.name == "x"
      assert var.indices == [1, :_]
      assert var.pattern == nil
    end

    test "creates sum node" do
      var = %AST.Variable{name: "x", indices: [1, :_], pattern: nil}
      sum = %AST.Sum{variable: var}
      assert sum.variable == var
    end

    test "creates abs node" do
      var = %AST.Variable{name: "x", indices: [], pattern: nil}
      abs = %AST.Abs{expr: var}
      assert abs.expr == var
    end

    test "creates max node with two arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      max = %AST.Max{args: [x, y]}
      assert max.args == [x, y]
    end

    test "creates max node with three arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}
      max = %AST.Max{args: [x, y, z]}
      assert max.args == [x, y, z]
    end

    test "creates min node with two arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      min = %AST.Min{args: [x, y]}
      assert min.args == [x, y]
    end

    test "creates min node with three arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}
      min = %AST.Min{args: [x, y, z]}
      assert min.args == [x, y, z]
    end

    test "creates and node with two arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      and_op = %AST.And{args: [x, y]}
      assert and_op.args == [x, y]
    end

    test "creates and node with three arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}
      and_op = %AST.And{args: [x, y, z]}
      assert and_op.args == [x, y, z]
    end

    test "creates or node with two arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      or_op = %AST.Or{args: [x, y]}
      assert or_op.args == [x, y]
    end

    test "creates or node with three arguments" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}
      or_op = %AST.Or{args: [x, y, z]}
      assert or_op.args == [x, y, z]
    end

    test "creates constraint node" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      constraint = %AST.Constraint{left: x, operator: :==, right: y}
      assert constraint.left == x
      assert constraint.operator == :==
      assert constraint.right == y
    end

    test "creates binary operation node" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      binary_op = %AST.BinaryOp{left: x, operator: :+, right: y}
      assert binary_op.left == x
      assert binary_op.operator == :+
      assert binary_op.right == y
    end

    test "creates if-then-else node" do
      condition = %AST.Variable{name: "c", indices: [], pattern: nil}
      then_expr = %AST.Variable{name: "x", indices: [], pattern: nil}
      else_expr = %AST.Variable{name: "y", indices: [], pattern: nil}

      if_then_else = %AST.IfThenElse{
        condition: condition,
        then_expr: then_expr,
        else_expr: else_expr
      }

      assert if_then_else.condition == condition
      assert if_then_else.then_expr == then_expr
      assert if_then_else.else_expr == else_expr
    end

    test "creates piecewise linear node" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      breakpoints = [0.0, 1.0, 2.0]
      slopes = [1.0, 2.0, 0.5]
      intercepts = [0.0, -1.0, 1.0]

      piecewise = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      }

      assert piecewise.expr == x
      assert piecewise.breakpoints == breakpoints
      assert piecewise.slopes == slopes
      assert piecewise.intercepts == intercepts
    end
  end

  describe "AST node properties" do
    test "variable node has correct properties" do
      var = %AST.Variable{name: "x", indices: [1, 2], pattern: nil}
      assert var.name == "x"
      assert var.indices == [1, 2]
      assert var.pattern == nil
    end

    test "pattern variable node has correct properties" do
      var = %AST.Variable{name: "x", indices: [], pattern: :_}
      assert var.name == "x"
      assert var.indices == []
      assert var.pattern == :_
    end

    test "sum node has correct properties" do
      var = %AST.Variable{name: "x", indices: [1, :_], pattern: nil}
      sum = %AST.Sum{variable: var}
      assert sum.variable == var
    end

    test "abs node has correct properties" do
      var = %AST.Variable{name: "x", indices: [], pattern: nil}
      abs = %AST.Abs{expr: var}
      assert abs.expr == var
    end

    test "variadic operation nodes have correct properties" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}

      max = %AST.Max{args: [x, y, z]}
      assert max.args == [x, y, z]

      min = %AST.Min{args: [x, y, z]}
      assert min.args == [x, y, z]

      and_op = %AST.And{args: [x, y, z]}
      assert and_op.args == [x, y, z]

      or_op = %AST.Or{args: [x, y, z]}
      assert or_op.args == [x, y, z]
    end

    test "constraint node has correct properties" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      constraint = %AST.Constraint{left: x, operator: :==, right: y}
      assert constraint.left == x
      assert constraint.operator == :==
      assert constraint.right == y
    end

    test "binary operation node has correct properties" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      binary_op = %AST.BinaryOp{left: x, operator: :+, right: y}
      assert binary_op.left == x
      assert binary_op.operator == :+
      assert binary_op.right == y
    end

    test "if-then-else node has correct properties" do
      condition = %AST.Variable{name: "c", indices: [], pattern: nil}
      then_expr = %AST.Variable{name: "x", indices: [], pattern: nil}
      else_expr = %AST.Variable{name: "y", indices: [], pattern: nil}

      if_then_else = %AST.IfThenElse{
        condition: condition,
        then_expr: then_expr,
        else_expr: else_expr
      }

      assert if_then_else.condition == condition
      assert if_then_else.then_expr == then_expr
      assert if_then_else.else_expr == else_expr
    end

    test "piecewise linear node has correct properties" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      breakpoints = [0.0, 1.0, 2.0]
      slopes = [1.0, 2.0, 0.5]
      intercepts = [0.0, -1.0, 1.0]

      piecewise = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      }

      assert piecewise.expr == x
      assert piecewise.breakpoints == breakpoints
      assert piecewise.slopes == slopes
      assert piecewise.intercepts == intercepts
    end
  end

  describe "AST node equality" do
    test "variable nodes are equal when properties are equal" do
      var1 = %AST.Variable{name: "x", indices: [1, 2], pattern: nil}
      var2 = %AST.Variable{name: "x", indices: [1, 2], pattern: nil}
      var3 = %AST.Variable{name: "x", indices: [1, 3], pattern: nil}
      var4 = %AST.Variable{name: "y", indices: [1, 2], pattern: nil}

      assert var1 == var2
      refute var1 == var3
      refute var1 == var4
    end

    test "pattern variable nodes are equal when properties are equal" do
      var1 = %AST.Variable{name: "x", indices: [], pattern: :_}
      var2 = %AST.Variable{name: "x", indices: [], pattern: :_}
      var3 = %AST.Variable{name: "x", indices: [], pattern: nil}
      var4 = %AST.Variable{name: "y", indices: [], pattern: :_}

      assert var1 == var2
      refute var1 == var3
      refute var1 == var4
    end

    test "variadic operation nodes are equal when arguments are equal" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}

      max1 = %AST.Max{args: [x, y, z]}
      max2 = %AST.Max{args: [x, y, z]}
      max3 = %AST.Max{args: [x, y]}
      max4 = %AST.Max{args: [y, x, z]}

      assert max1 == max2
      refute max1 == max3
      refute max1 == max4
    end

    test "constraint nodes are equal when components are equal" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}

      constraint1 = %AST.Constraint{left: x, operator: :==, right: y}
      constraint2 = %AST.Constraint{left: x, operator: :==, right: y}
      constraint3 = %AST.Constraint{left: y, operator: :==, right: x}

      assert constraint1 == constraint2
      refute constraint1 == constraint3
    end

    test "if-then-else nodes are equal when components are equal" do
      condition = %AST.Variable{name: "c", indices: [], pattern: nil}
      then_expr = %AST.Variable{name: "x", indices: [], pattern: nil}
      else_expr = %AST.Variable{name: "y", indices: [], pattern: nil}

      if1 = %AST.IfThenElse{condition: condition, then_expr: then_expr, else_expr: else_expr}
      if2 = %AST.IfThenElse{condition: condition, then_expr: then_expr, else_expr: else_expr}
      if3 = %AST.IfThenElse{condition: condition, then_expr: else_expr, else_expr: then_expr}

      assert if1 == if2
      refute if1 == if3
    end

    test "piecewise linear nodes are equal when components are equal" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      breakpoints = [0.0, 1.0, 2.0]
      slopes = [1.0, 2.0, 0.5]
      intercepts = [0.0, -1.0, 1.0]

      pw1 = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      }

      pw2 = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      }

      pw3 = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: [0.0, 1.0],
        slopes: [1.0, 2.0],
        intercepts: [0.0, -1.0]
      }

      assert pw1 == pw2
      refute pw1 == pw3
    end
  end

  describe "AST node inspection" do
    test "variable node can be inspected" do
      var = %AST.Variable{name: "x", indices: [1, 2], pattern: nil}
      inspect_string = inspect(var)

      assert String.contains?(inspect_string, "Variable")
      assert String.contains?(inspect_string, "x")
      assert String.contains?(inspect_string, "[1, 2]")
    end

    test "pattern variable node can be inspected" do
      var = %AST.Variable{name: "x", indices: [], pattern: :_}
      inspect_string = inspect(var)

      assert String.contains?(inspect_string, "Variable")
      assert String.contains?(inspect_string, "x")
      assert String.contains?(inspect_string, "pattern: :_")
    end

    test "variadic operation node can be inspected" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      y = %AST.Variable{name: "y", indices: [], pattern: nil}
      z = %AST.Variable{name: "z", indices: [], pattern: nil}
      max = %AST.Max{args: [x, y, z]}
      inspect_string = inspect(max)

      assert String.contains?(inspect_string, "Max")
      assert String.contains?(inspect_string, "x")
      assert String.contains?(inspect_string, "y")
      assert String.contains?(inspect_string, "z")
    end

    test "if-then-else node can be inspected" do
      condition = %AST.Variable{name: "c", indices: [], pattern: nil}
      then_expr = %AST.Variable{name: "x", indices: [], pattern: nil}
      else_expr = %AST.Variable{name: "y", indices: [], pattern: nil}

      if_then_else = %AST.IfThenElse{
        condition: condition,
        then_expr: then_expr,
        else_expr: else_expr
      }

      inspect_string = inspect(if_then_else)

      assert String.contains?(inspect_string, "IfThenElse")
      assert String.contains?(inspect_string, "c")
      assert String.contains?(inspect_string, "x")
      assert String.contains?(inspect_string, "y")
    end

    test "piecewise linear node can be inspected" do
      x = %AST.Variable{name: "x", indices: [], pattern: nil}
      breakpoints = [0.0, 1.0, 2.0]
      slopes = [1.0, 2.0, 0.5]
      intercepts = [0.0, -1.0, 1.0]

      piecewise = %AST.PiecewiseLinear{
        expr: x,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      }

      inspect_string = inspect(piecewise)

      assert String.contains?(inspect_string, "PiecewiseLinear")
      assert String.contains?(inspect_string, "x")
      assert String.contains?(inspect_string, "[0.0, 1.0, 2.0]")
    end
  end
end
