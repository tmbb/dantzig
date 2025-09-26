defmodule Dantzig.AST.TransformerTest do
  use ExUnit.Case, async: true

  alias Dantzig.{Problem, AST, AST.Transformer, Polynomial}

  describe "abs/1 transformation" do
    test "transforms abs(x) into auxiliary variable and constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      abs_expr = AST.abs(x)
      {new_problem, transformed} = Transformer.transform_expression(abs_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "abs_x_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 3 constraints: abs_x >= x, abs_x >= -x, abs_x >= 0
      assert map_size(new_problem.constraints) == 3

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms abs(x) with different constraint names" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      abs_expr = AST.abs(x)

      {new_problem, _transformed} =
        Transformer.transform_expression(abs_expr, problem, "constraint1")

      # Should create auxiliary variable with different name
      aux_vars = Problem.get_variables_nd(new_problem, "abs_x_constraint1")
      assert aux_vars != nil
    end

    test "transforms nested abs expressions" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      nested_expr = AST.abs(AST.add(x, AST.abs(y)))

      {new_problem, _transformed} =
        Transformer.transform_expression(nested_expr, problem, "nested")

      # Should create auxiliary variables for both abs operations
      abs_x_vars = Problem.get_variables_nd(new_problem, "abs_x_nested")
      abs_y_vars = Problem.get_variables_nd(new_problem, "abs_y_nested")

      assert abs_x_vars != nil
      assert abs_y_vars != nil

      # Should create constraints for both abs operations
      # 3 for each abs
      assert map_size(new_problem.constraints) >= 6
    end

    test "transforms abs with polynomial expressions" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      poly_expr = AST.add(x, AST.multiply(y, 2.0))
      abs_expr = AST.abs(poly_expr)
      {new_problem, _transformed} = Transformer.transform_expression(abs_expr, problem, "poly")

      # Should create auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "abs_poly_poly")
      assert aux_vars != nil

      # Should create 3 constraints
      assert map_size(new_problem.constraints) == 3
    end
  end

  describe "variadic max transformation" do
    test "transforms max(x1, x2, x3) into auxiliary variable and constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :continuous)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :continuous)
      {problem, x3} = Problem.new_variable(problem, "x3", type: :continuous)

      max_expr = AST.max([x1, x2, x3])
      {new_problem, transformed} = Transformer.transform_expression(max_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "max_variadic_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 4 constraints: max >= x1, max >= x2, max >= x3, max <= x1 + x2 + x3
      assert map_size(new_problem.constraints) == 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms max with 2 arguments" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :continuous)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :continuous)

      max_expr = AST.max([x1, x2])
      {new_problem, _transformed} = Transformer.transform_expression(max_expr, problem, "test")

      # Should create 3 constraints: max >= x1, max >= x2, max <= x1 + x2
      assert map_size(new_problem.constraints) == 3
    end

    test "transforms max with 5 arguments" do
      problem = Problem.new(direction: :minimize)

      variables =
        for i <- 1..5 do
          {problem, var} = Problem.new_variable(problem, "x#{i}", type: :continuous)
          var
        end

      max_expr = AST.max(variables)
      {new_problem, _transformed} = Transformer.transform_expression(max_expr, problem, "test")

      # Should create 6 constraints: 5 for max >= xi, 1 for max <= sum
      assert map_size(new_problem.constraints) == 6
    end

    test "transforms max with mixed variable types" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :binary)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :continuous)
      {problem, x3} = Problem.new_variable(problem, "x3", type: :integer)

      max_expr = AST.max([x1, x2, x3])
      {new_problem, _transformed} = Transformer.transform_expression(max_expr, problem, "mixed")

      # Should create auxiliary variable and constraints
      aux_vars = Problem.get_variables_nd(new_problem, "max_variadic_mixed")
      assert aux_vars != nil
      assert map_size(new_problem.constraints) == 4
    end
  end

  describe "variadic min transformation" do
    test "transforms min(x1, x2, x3) into auxiliary variable and constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :continuous)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :continuous)
      {problem, x3} = Problem.new_variable(problem, "x3", type: :continuous)

      min_expr = AST.min([x1, x2, x3])
      {new_problem, transformed} = Transformer.transform_expression(min_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "min_variadic_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 4 constraints: min <= x1, min <= x2, min <= x3, min >= x1 + x2 + x3 - 2
      assert map_size(new_problem.constraints) == 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms min with 2 arguments" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :continuous)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :continuous)

      min_expr = AST.min([x1, x2])
      {new_problem, _transformed} = Transformer.transform_expression(min_expr, problem, "test")

      # Should create 3 constraints: min <= x1, min <= x2, min >= x1 + x2 - 1
      assert map_size(new_problem.constraints) == 3
    end

    test "transforms min with 4 arguments" do
      problem = Problem.new(direction: :minimize)

      variables =
        for i <- 1..4 do
          {problem, var} = Problem.new_variable(problem, "x#{i}", type: :continuous)
          var
        end

      min_expr = AST.min(variables)
      {new_problem, _transformed} = Transformer.transform_expression(min_expr, problem, "test")

      # Should create 5 constraints: 4 for min <= xi, 1 for min >= sum - 3
      assert map_size(new_problem.constraints) == 5
    end
  end

  describe "variadic and transformation" do
    test "transforms and(x1, x2, x3) into auxiliary variable and constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :binary)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :binary)
      {problem, x3} = Problem.new_variable(problem, "x3", type: :binary)

      and_expr = AST.and([x1, x2, x3])
      {new_problem, transformed} = Transformer.transform_expression(and_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "and_variadic_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 4 constraints: and <= x1, and <= x2, and <= x3, and >= x1 + x2 + x3 - 2
      assert map_size(new_problem.constraints) == 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms and with 2 arguments" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :binary)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :binary)

      and_expr = AST.and([x1, x2])
      {new_problem, _transformed} = Transformer.transform_expression(and_expr, problem, "test")

      # Should create 3 constraints: and <= x1, and <= x2, and >= x1 + x2 - 1
      assert map_size(new_problem.constraints) == 3
    end

    test "transforms and with 4 arguments" do
      problem = Problem.new(direction: :minimize)

      variables =
        for i <- 1..4 do
          {problem, var} = Problem.new_variable(problem, "x#{i}", type: :binary)
          var
        end

      and_expr = AST.and(variables)
      {new_problem, _transformed} = Transformer.transform_expression(and_expr, problem, "test")

      # Should create 5 constraints: 4 for and <= xi, 1 for and >= sum - 3
      assert map_size(new_problem.constraints) == 5
    end
  end

  describe "variadic or transformation" do
    test "transforms or(x1, x2, x3) into auxiliary variable and constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :binary)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :binary)
      {problem, x3} = Problem.new_variable(problem, "x3", type: :binary)

      or_expr = AST.or([x1, x2, x3])
      {new_problem, transformed} = Transformer.transform_expression(or_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "or_variadic_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 4 constraints: or >= x1, or >= x2, or >= x3, or <= x1 + x2 + x3
      assert map_size(new_problem.constraints) == 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms or with 2 arguments" do
      problem = Problem.new(direction: :minimize)
      {problem, x1} = Problem.new_variable(problem, "x1", type: :binary)
      {problem, x2} = Problem.new_variable(problem, "x2", type: :binary)

      or_expr = AST.or([x1, x2])
      {new_problem, _transformed} = Transformer.transform_expression(or_expr, problem, "test")

      # Should create 3 constraints: or >= x1, or >= x2, or <= x1 + x2
      assert map_size(new_problem.constraints) == 3
    end

    test "transforms or with 4 arguments" do
      problem = Problem.new(direction: :minimize)

      variables =
        for i <- 1..4 do
          {problem, var} = Problem.new_variable(problem, "x#{i}", type: :binary)
          var
        end

      or_expr = AST.or(variables)
      {new_problem, _transformed} = Transformer.transform_expression(or_expr, problem, "test")

      # Should create 5 constraints: 4 for or >= xi, 1 for or <= sum
      assert map_size(new_problem.constraints) == 5
    end
  end

  describe "if-then-else transformation" do
    test "transforms if-then-else with binary condition" do
      problem = Problem.new(direction: :minimize)
      {problem, condition} = Problem.new_variable(problem, "condition", type: :binary)
      {problem, then_expr} = Problem.new_variable(problem, "then_expr", type: :continuous)
      {problem, else_expr} = Problem.new_variable(problem, "else_expr", type: :continuous)

      if_expr = AST.if_then_else(condition, then_expr, else_expr)
      {new_problem, transformed} = Transformer.transform_expression(if_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "if_then_else_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create 4 constraints for if-then-else
      assert map_size(new_problem.constraints) == 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms nested if-then-else expressions" do
      problem = Problem.new(direction: :minimize)
      {problem, c1} = Problem.new_variable(problem, "c1", type: :binary)
      {problem, c2} = Problem.new_variable(problem, "c2", type: :binary)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :continuous)

      nested_if = AST.if_then_else(c1, x, AST.if_then_else(c2, y, z))
      {new_problem, _transformed} = Transformer.transform_expression(nested_if, problem, "nested")

      # Should create auxiliary variables for both if-then-else operations
      if1_vars = Problem.get_variables_nd(new_problem, "if_then_else_nested")
      if2_vars = Problem.get_variables_nd(new_problem, "if_then_else_nested_2")

      assert if1_vars != nil
      assert if2_vars != nil

      # Should create constraints for both if-then-else operations
      # 4 for each if-then-else
      assert map_size(new_problem.constraints) >= 8
    end

    test "transforms if-then-else with polynomial expressions" do
      problem = Problem.new(direction: :minimize)
      {problem, condition} = Problem.new_variable(problem, "condition", type: :binary)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      then_expr = AST.add(x, AST.multiply(y, 2.0))
      else_expr = AST.subtract(x, y)

      if_expr = AST.if_then_else(condition, then_expr, else_expr)
      {new_problem, _transformed} = Transformer.transform_expression(if_expr, problem, "poly")

      # Should create auxiliary variable and constraints
      aux_vars = Problem.get_variables_nd(new_problem, "if_then_else_poly")
      assert aux_vars != nil
      assert map_size(new_problem.constraints) == 4
    end
  end

  describe "piecewise linear transformation" do
    test "transforms piecewise linear function with 3 breakpoints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      breakpoints = [0.0, 1.0, 2.0]
      slopes = [1.0, 2.0, 0.5]
      intercepts = [0.0, -1.0, 1.0]

      piecewise_expr = AST.piecewise_linear(x, breakpoints, slopes, intercepts)

      {new_problem, transformed} =
        Transformer.transform_expression(piecewise_expr, problem, "test")

      # Should create auxiliary variables for each segment
      aux_vars = Problem.get_variables_nd(new_problem, "piecewise_linear_test")
      assert aux_vars != nil

      # Should create constraints for piecewise linear
      # Multiple constraints per segment
      assert map_size(new_problem.constraints) >= 6

      # Check that the transformed expression is the sum of auxiliary variables
      assert transformed != nil
    end

    test "transforms piecewise linear function with 2 breakpoints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      breakpoints = [0.0, 1.0]
      slopes = [1.0, 2.0]
      intercepts = [0.0, -1.0]

      piecewise_expr = AST.piecewise_linear(x, breakpoints, slopes, intercepts)

      {new_problem, _transformed} =
        Transformer.transform_expression(piecewise_expr, problem, "test")

      # Should create auxiliary variables and constraints
      aux_vars = Problem.get_variables_nd(new_problem, "piecewise_linear_test")
      assert aux_vars != nil
      assert map_size(new_problem.constraints) >= 4
    end

    test "transforms piecewise linear function with 4 breakpoints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      breakpoints = [0.0, 1.0, 2.0, 3.0]
      slopes = [1.0, 2.0, 0.5, 1.5]
      intercepts = [0.0, -1.0, 1.0, -0.5]

      piecewise_expr = AST.piecewise_linear(x, breakpoints, slopes, intercepts)

      {new_problem, _transformed} =
        Transformer.transform_expression(piecewise_expr, problem, "test")

      # Should create auxiliary variables and constraints
      aux_vars = Problem.get_variables_nd(new_problem, "piecewise_linear_test")
      assert aux_vars != nil
      assert map_size(new_problem.constraints) >= 8
    end
  end

  describe "pattern-based operations" do
    test "transforms max(x[_]) with 1D variables" do
      problem = Problem.new(direction: :minimize)

      problem =
        Problem.put_variables_nd(problem, "x", %{
          {1} => Polynomial.variable("x1"),
          {2} => Polynomial.variable("x2"),
          {3} => Polynomial.variable("x3")
        })

      max_expr = AST.max([AST.variable("x", pattern: :_)])
      {new_problem, transformed} = Transformer.transform_expression(max_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "max_x_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create constraints for max
      assert map_size(new_problem.constraints) >= 3

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms min(x[_]) with 2D variables" do
      problem = Problem.new(direction: :minimize)

      problem =
        Problem.put_variables_nd(problem, "x", %{
          {1, 1} => Polynomial.variable("x1_1"),
          {1, 2} => Polynomial.variable("x1_2"),
          {2, 1} => Polynomial.variable("x2_1"),
          {2, 2} => Polynomial.variable("x2_2")
        })

      min_expr = AST.min([AST.variable("x", pattern: :_)])
      {new_problem, transformed} = Transformer.transform_expression(min_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "min_x_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create constraints for min
      assert map_size(new_problem.constraints) >= 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms and(x[_]) with 3D variables" do
      problem = Problem.new(direction: :minimize)

      problem =
        Problem.put_variables_nd(problem, "x", %{
          {1, 1, 1} => Polynomial.variable("x1_1_1"),
          {1, 1, 2} => Polynomial.variable("x1_1_2"),
          {2, 1, 1} => Polynomial.variable("x2_1_1"),
          {2, 1, 2} => Polynomial.variable("x2_1_2")
        })

      and_expr = AST.and([AST.variable("x", pattern: :_)])
      {new_problem, transformed} = Transformer.transform_expression(and_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "and_x_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create constraints for and
      assert map_size(new_problem.constraints) >= 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end

    test "transforms or(x[_]) with 4D variables" do
      problem = Problem.new(direction: :minimize)

      problem =
        Problem.put_variables_nd(problem, "x", %{
          {1, 1, 1, 1} => Polynomial.variable("x1_1_1_1"),
          {1, 1, 1, 2} => Polynomial.variable("x1_1_1_2"),
          {2, 1, 1, 1} => Polynomial.variable("x2_1_1_1"),
          {2, 1, 1, 2} => Polynomial.variable("x2_1_1_2")
        })

      or_expr = AST.or([AST.variable("x", pattern: :_)])
      {new_problem, transformed} = Transformer.transform_expression(or_expr, problem, "test")

      # Should create an auxiliary variable
      aux_vars = Problem.get_variables_nd(new_problem, "or_x_test")
      assert aux_vars != nil
      assert Map.has_key?(aux_vars, {})

      # Should create constraints for or
      assert map_size(new_problem.constraints) >= 4

      # Check that the transformed expression is the auxiliary variable
      assert transformed == Map.get(aux_vars, {})
    end
  end

  describe "complex nested expressions" do
    test "transforms complex expression with multiple operations" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :binary)

      # Complex expression: max(abs(x), abs(y)) + if-then-else(z, x, y)
      abs_x = AST.abs(x)
      abs_y = AST.abs(y)
      max_abs = AST.max([abs_x, abs_y])
      if_expr = AST.if_then_else(z, x, y)
      complex_expr = AST.add(max_abs, if_expr)

      {new_problem, _transformed} =
        Transformer.transform_expression(complex_expr, problem, "complex")

      # Should create auxiliary variables for abs, max, and if-then-else
      abs_x_vars = Problem.get_variables_nd(new_problem, "abs_x_complex")
      abs_y_vars = Problem.get_variables_nd(new_problem, "abs_y_complex")
      max_vars = Problem.get_variables_nd(new_problem, "max_variadic_complex")
      if_vars = Problem.get_variables_nd(new_problem, "if_then_else_complex")

      assert abs_x_vars != nil
      assert abs_y_vars != nil
      assert max_vars != nil
      assert if_vars != nil

      # Should create many constraints
      assert map_size(new_problem.constraints) >= 10
    end

    test "transforms expression with piecewise linear and variadic operations" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :continuous)

      # Expression: piecewise_linear(x) + max(y, z)
      piecewise = AST.piecewise_linear(x, [0.0, 1.0], [1.0, 2.0], [0.0, -1.0])
      max_expr = AST.max([y, z])
      complex_expr = AST.add(piecewise, max_expr)

      {new_problem, _transformed} =
        Transformer.transform_expression(complex_expr, problem, "mixed")

      # Should create auxiliary variables for both operations
      piecewise_vars = Problem.get_variables_nd(new_problem, "piecewise_linear_mixed")
      max_vars = Problem.get_variables_nd(new_problem, "max_variadic_mixed")

      assert piecewise_vars != nil
      assert max_vars != nil

      # Should create many constraints
      assert map_size(new_problem.constraints) >= 8
    end
  end

  describe "error handling" do
    test "raises error for invalid constraint name" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      abs_expr = AST.abs(x)

      assert_raise ArgumentError, fn ->
        Transformer.transform_expression(abs_expr, problem, "")
      end
    end

    test "raises error for empty variadic operation" do
      problem = Problem.new(direction: :minimize)

      max_expr = AST.max([])

      assert_raise ArgumentError, fn ->
        Transformer.transform_expression(max_expr, problem, "test")
      end
    end

    test "raises error for single argument variadic operation" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      max_expr = AST.max([x])

      assert_raise ArgumentError, fn ->
        Transformer.transform_expression(max_expr, problem, "test")
      end
    end

    test "raises error for invalid piecewise linear parameters" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Mismatched lengths
      piecewise_expr = AST.piecewise_linear(x, [0.0, 1.0], [1.0], [0.0, -1.0])

      assert_raise ArgumentError, fn ->
        Transformer.transform_expression(piecewise_expr, problem, "test")
      end
    end
  end

  describe "linear expressions (no transformation)" do
    test "leaves linear expressions unchanged" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Linear expression: 2x + 3y + 5
      linear_expr = AST.add(AST.add(AST.multiply(x, 2.0), AST.multiply(y, 3.0)), 5.0)

      {new_problem, transformed} =
        Transformer.transform_expression(linear_expr, problem, "linear")

      # Should not create any auxiliary variables or constraints
      assert new_problem == problem
      assert transformed == linear_expr
    end

    test "leaves simple variable references unchanged" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      var_expr = x
      {new_problem, transformed} = Transformer.transform_expression(var_expr, problem, "var")

      # Should not create any auxiliary variables or constraints
      assert new_problem == problem
      assert transformed == var_expr
    end

    test "leaves constant expressions unchanged" do
      problem = Problem.new(direction: :minimize)

      const_expr = AST.constant(42.0)
      {new_problem, transformed} = Transformer.transform_expression(const_expr, problem, "const")

      # Should not create any auxiliary variables or constraints
      assert new_problem == problem
      assert transformed == const_expr
    end
  end
end
