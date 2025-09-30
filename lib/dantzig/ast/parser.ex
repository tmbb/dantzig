defmodule Dantzig.AST.Parser do
  @moduledoc """
  Parser for converting Elixir AST to Dantzig AST representation.

  Handles parsing of:
  - Variable expressions: x[i, j], x[_, j]
  - Sum expressions: sum(x[i, _])
  - Generator-based sum expressions: sum(expr for i <- list, j <- list)
  - Constraint expressions: sum(x[i, _]) == 1
  - Binary operations: x + y, x * 2
  - Non-linear functions: abs(x), max(x, y), min(x, y)
  """

  alias Dantzig.AST

  @doc """
  Parse a variable expression like x[i, j] or x[_, j]
  """
  def parse_variable_expression(ast) do
    case ast do
      # x[i, j] syntax
      {var_name, _, indices} when is_list(indices) ->
        %AST.Variable{name: var_name, indices: indices, pattern: nil}

      # Handle other cases
      var_name when is_atom(var_name) ->
        %AST.Variable{name: var_name, indices: [], pattern: nil}

      _ ->
        raise ArgumentError, "Invalid variable expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse a constraint expression like sum(x[i, _]) == 1
  """
  def parse_constraint_expression(ast) do
    case ast do
      # sum(x[i, _]) == 1
      {op, _, [left, right]} when op in [:==, :!=, :<=, :>=, :<, :>] ->
        %AST.Constraint{
          left: parse_expression(left),
          operator: op,
          right: parse_expression(right)
        }

      _ ->
        raise ArgumentError, "Invalid constraint expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse any expression into AST representation
  """
  def parse_expression(ast) do
    case ast do
      # sum(expr, :for, generators) - generator-based sum
      {:sum, _, [expr, :for, generators]} ->
        %AST.GeneratorSum{
          expression: parse_expression(expr),
          generators: parse_generators_for_sum(generators)
        }

      # sum(x[i, _]) - pattern-based sum
      {:sum, _, [var_expr]} ->
        %AST.Sum{variable: parse_variable_expression(var_expr)}

      # abs(x[i, j])
      {:abs, _, [expr]} ->
        %AST.Abs{expr: parse_expression(expr)}

      # max(x, y, z, ...) or max(x[_])
      {:max, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Max{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Max{args: Enum.map(args, &parse_expression/1)}
        end

      # min(x, y, z, ...) or min(x[_])
      {:min, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Min{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Min{args: Enum.map(args, &parse_expression/1)}
        end

      # x + y, x * 2, etc.
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        %AST.BinaryOp{
          left: parse_expression(left),
          operator: op,
          right: parse_expression(right)
        }

      # x AND y AND z AND ... or x[_] AND y[_]
      {:and, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.And{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.And{args: Enum.map(args, &parse_expression/1)}
        end

      # x OR y OR z OR ... or x[_] OR y[_]
      {:or, _, args} when is_list(args) ->
        case detect_pattern_based_args(args) do
          {:pattern, var_name, pattern} ->
            %AST.Or{
              args: [
                %AST.Sum{
                  variable: %AST.Variable{name: var_name, indices: pattern, pattern: pattern}
                }
              ]
            }

          :explicit ->
            %AST.Or{args: Enum.map(args, &parse_expression/1)}
        end

      # IF condition THEN x ELSE y
      {:if, _, [condition, [do: then_expr, else: else_expr]]} ->
        %AST.IfThenElse{
          condition: parse_expression(condition),
          then_expr: parse_expression(then_expr),
          else_expr: parse_expression(else_expr)
        }

      # Literals
      literal when is_number(literal) ->
        literal

      # Variables
      var when is_atom(var) ->
        %AST.Variable{name: var, indices: [], pattern: nil}

      # Variable expressions
      {var_name, _, indices} when is_list(indices) ->
        %AST.Variable{name: var_name, indices: indices, pattern: nil}

      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(ast)}"
    end
  end

  @doc """
  Parse generators from for comprehension syntax: [i <- 1..8, j <- 1..8]
  """
  def parse_generators(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        {var, Enum.to_list(range)}

      {:<-, _, [var, list]} when is_list(list) ->
        {var, list}

      {:<-, _, [var, expr]} ->
        # Handle computed expressions
        {var, evaluate_expression(expr)}

      _ ->
        raise ArgumentError, "Invalid generator: #{inspect(generators)}"
    end)
  end

  @doc """
  Parse generators for sum expressions: i <- 1..8, j <- 1..8
  """
  def parse_generators_for_sum(generators) do
    case generators do
      # Single generator: i <- 1..3
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        [{var, Enum.to_list(range)}]

      # Single generator with list: i <- [1, 2, 3]
      {:<-, _, [var, list]} when is_list(list) ->
        [{var, list}]

      # Multiple generators: [i <- 1..2, j <- 1..2]
      list when is_list(list) ->
        Enum.map(list, fn
          {:<-, _, [var, range]} when is_struct(range, Range) ->
            {var, Enum.to_list(range)}

          {:<-, _, [var, list]} when is_list(list) ->
            {var, list}

          {:<-, _, [var, expr]} ->
            {var, evaluate_expression(expr)}

          _ ->
            raise ArgumentError, "Invalid generator in sum: #{inspect(list)}"
        end)

      _ ->
        raise ArgumentError, "Invalid generators in sum: #{inspect(generators)}"
    end
  end

  @doc """
  Detect if function arguments contain pattern-based expressions like x[_]
  """
  def detect_pattern_based_args(args) do
    case args do
      # Single pattern-based argument: max(x[_])
      [{var_name, _, indices}] when is_list(indices) ->
        if Enum.all?(indices, &(&1 == :_)) do
          {:pattern, var_name, indices}
        else
          :explicit
        end

      # Multiple pattern-based arguments: max(x[_], y[_])
      args when is_list(args) ->
        if Enum.all?(args, fn
             {var_name, _, indices} when is_list(indices) -> Enum.all?(indices, &(&1 == :_))
             _ -> false
           end) do
          # For now, we'll handle single pattern case
          # Multiple patterns would need more complex handling
          :explicit
        else
          :explicit
        end

      _ ->
        :explicit
    end
  end

  @doc """
  Evaluate a simple expression to get its value
  """
  def evaluate_expression(expr) do
    case expr do
      # Range
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      # List
      list when is_list(list) ->
        list

      # Literal
      literal when is_number(literal) or is_atom(literal) ->
        literal

      # Binary operations
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_val = evaluate_expression(left)
        right_val = evaluate_expression(right)

        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end

      # Function calls
      {func, _, [arg]} when is_atom(func) ->
        arg_val = evaluate_expression(arg)

        case func do
          # Simplified - would need more sophisticated function handling
          :rem -> rem(arg_val, 2)
        end

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end
end
