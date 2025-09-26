defmodule Dantzig.AST.Analyzer do
  @moduledoc """
  Analyzer for Dantzig AST to detect non-linear functions and determine
  what transformations are needed.

  This module identifies which expressions are linear vs non-linear
  and what auxiliary variables and constraints need to be created.
  """

  alias Dantzig.AST

  @doc """
  Analyze an expression to determine its type and transformation requirements
  """
  def analyze_expression(ast) do
    case ast do
      %AST.Abs{} ->
        {:non_linear, :abs, [ast.expr]}

      %AST.Max{} ->
        {:non_linear, :max, ast.args}

      %AST.Min{} ->
        {:non_linear, :min, ast.args}

      %AST.BinaryOp{operator: :*} ->
        # Check if both sides are variables (quadratic)
        left_type = analyze_expression(ast.left)
        right_type = analyze_expression(ast.right)

        if left_type == :variable and right_type == :variable do
          {:non_linear, :quadratic, [ast.left, ast.right]}
        else
          {:linear, :multiplication, [ast.left, ast.right]}
        end

      %AST.BinaryOp{operator: op} when op in [:+, :-, :/] ->
        left_type = analyze_expression(ast.left)
        right_type = analyze_expression(ast.right)

        if left_type == :linear and right_type == :linear do
          {:linear, op, [ast.left, ast.right]}
        else
          {:non_linear, op, [ast.left, ast.right]}
        end

      %AST.Sum{} ->
        {:linear, :sum, [ast.variable]}

      %AST.Variable{} ->
        :variable

      %AST.And{} ->
        {:non_linear, :and, ast.args}

      %AST.Or{} ->
        {:non_linear, :or, ast.args}

      %AST.IfThenElse{} ->
        {:non_linear, :if_then_else, [ast.condition, ast.then_expr, ast.else_expr]}

      %AST.PiecewiseLinear{} ->
        {:non_linear, :piecewise_linear, [ast.expr, ast.breakpoints, ast.slopes, ast.intercepts]}

      literal when is_number(literal) ->
        :constant

      _ ->
        {:unknown, :unknown, [ast]}
    end
  end

  @doc """
  Check if an expression is linear
  """
  def is_linear?(ast) do
    case analyze_expression(ast) do
      {:linear, _, _} -> true
      :variable -> true
      :constant -> true
      _ -> false
    end
  end

  @doc """
  Check if an expression is non-linear
  """
  def is_non_linear?(ast) do
    not is_linear?(ast)
  end

  @doc """
  Get all variables referenced in an expression
  """
  def get_variables(ast) do
    case ast do
      %AST.Variable{name: name} ->
        [name]

      %AST.Sum{variable: var} ->
        get_variables(var)

      %AST.Abs{expr: expr} ->
        get_variables(expr)

      %AST.Max{args: args} ->
        Enum.flat_map(args, &get_variables/1)

      %AST.Min{args: args} ->
        Enum.flat_map(args, &get_variables/1)

      %AST.BinaryOp{left: left, right: right} ->
        get_variables(left) ++ get_variables(right)

      %AST.And{args: args} ->
        Enum.flat_map(args, &get_variables/1)

      %AST.Or{args: args} ->
        Enum.flat_map(args, &get_variables/1)

      %AST.IfThenElse{condition: cond, then_expr: then_expr, else_expr: else_expr} ->
        get_variables(cond) ++ get_variables(then_expr) ++ get_variables(else_expr)

      %AST.PiecewiseLinear{expr: expr} ->
        get_variables(expr)

      %AST.Constraint{left: left, right: right} ->
        get_variables(left) ++ get_variables(right)

      _ ->
        []
    end
  end

  @doc """
  Get the complexity score of an expression (higher = more complex)
  """
  def complexity_score(ast) do
    case ast do
      %AST.Abs{} -> 3
      %AST.Max{} -> 3
      %AST.Min{} -> 3
      %AST.BinaryOp{operator: :*} -> 2
      %AST.BinaryOp{} -> 1
      %AST.Sum{} -> 1
      %AST.Variable{} -> 0
      literal when is_number(literal) -> 0
      _ -> 1
    end
  end

  @doc """
  Check if an expression contains any non-linear functions
  """
  def contains_non_linear?(ast) do
    case ast do
      %AST.Abs{} ->
        true

      %AST.Max{} ->
        true

      %AST.Min{} ->
        true

      %AST.BinaryOp{operator: :*} ->
        left_type = analyze_expression(ast.left)
        right_type = analyze_expression(ast.right)
        left_type == :variable and right_type == :variable

      %AST.And{} ->
        true

      %AST.Or{} ->
        true

      %AST.IfThenElse{} ->
        true

      %AST.PiecewiseLinear{} ->
        true

      %AST.BinaryOp{left: left, right: right} ->
        contains_non_linear?(left) or contains_non_linear?(right)

      %AST.Sum{variable: var} ->
        contains_non_linear?(var)

      %AST.Abs{expr: expr} ->
        contains_non_linear?(expr)

      %AST.Max{args: args} ->
        Enum.any?(args, &contains_non_linear?/1)

      %AST.Min{args: args} ->
        Enum.any?(args, &contains_non_linear?/1)

      %AST.And{args: args} ->
        Enum.any?(args, &contains_non_linear?/1)

      %AST.Or{args: args} ->
        Enum.any?(args, &contains_non_linear?/1)

      %AST.IfThenElse{condition: cond, then_expr: then_expr, else_expr: else_expr} ->
        contains_non_linear?(cond) or contains_non_linear?(then_expr) or
          contains_non_linear?(else_expr)

      %AST.PiecewiseLinear{expr: expr} ->
        contains_non_linear?(expr)

      %AST.Constraint{left: left, right: right} ->
        contains_non_linear?(left) or contains_non_linear?(right)

      _ ->
        false
    end
  end
end
