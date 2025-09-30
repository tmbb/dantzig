defmodule Dantzig.Problem.DSL do
  @moduledoc """
  Domain-specific language for building optimization problems with natural syntax.

  This module provides the exact DSL syntax as specified by the user.
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial
  alias Dantzig.Problem.DSL.Internal

  # Import DSL components (if needed)

  @doc """
  Macro to handle function call syntax like queen2d(i, :_).
  This is valid Elixir syntax and works in IEx/Livebook.
  """
  defmacro var_access(var_name, indices) do
    # Transform function call notation to AST
    quote do
      {unquote(var_name), [], unquote(indices)}
    end
  end

  @doc """
  Macro to handle sum expressions with 'in' syntax.
  This transforms sum(expr in var <- list) into valid Elixir.

  Example:
    sum(qty(food) * foods[food]["cost"] in food <- food_names)

  Future: Will support 'where' for filtering:
    sum(qty(food) in food <- food_names where food != "ice_cream")
  """
  defmacro sum(expr) do
    case expr do
      # Handle sum(expr in var <- list) syntax
      {:in, meta, [inner_expr, [{:<-, _, [var, list]}]]} ->
        # Transform the in syntax into a sum expression
        quote do
          {:sum, [],
           [
             {:in, unquote(meta),
              [unquote(inner_expr), [{:<-, [], [unquote(var), unquote(list)]}]]}
           ]}
        end

      # Handle simple sum expressions
      simple_expr ->
        quote do
          {:sum, [], [unquote(simple_expr)]}
        end
    end
  end

  @doc """
  Macro to handle generator syntax like [i <- 1..4, j <- 1..4].
  This transforms the invalid Elixir syntax into proper AST representation.
  """
  defmacro generators(generator_list) do
    # Handle both direct lists and quoted expressions
    case generator_list do
      {:quote, _, [[do: list]]} ->
        # Handle quoted expressions like quote(do: [i <- 1..4, j <- 1..4])
        transformed_generators =
          Enum.map(list, fn
            {:<-, meta, [var, range]} ->
              # Convert to proper AST format
              {:<-, meta, [quote(do: unquote(var)), range]}

            other ->
              other
          end)

        quote do
          unquote(transformed_generators)
        end

      list when is_list(list) ->
        # Handle direct lists
        transformed_generators =
          Enum.map(list, fn
            {:<-, meta, [var, range]} ->
              # Convert to proper AST format
              {:<-, meta, [quote(do: unquote(var)), range]}

            other ->
              other
          end)

        quote do
          unquote(transformed_generators)
        end

      other ->
        quote do
          unquote(other)
        end
    end
  end

  @doc """
  Add variables to a problem using generator syntax.

  ## Examples

      # 2D binary variables
      problem = Problem.DSL.add_variables(problem, [i <- 1..4, j <- 1..4], "x", :binary, "Queen position")
  """
  defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
    quote do
      unquote(__MODULE__).__add_variables__(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(var_type),
        unquote(description)
      )
    end
  end

  @doc """
  Public DSL macro for variables - matches nqueens_dsl.exs syntax.
  """
  defmacro variables(problem, var_name, generators, var_type, opts \\ []) do
    # The generators parameter contains the raw AST from [i <- 1..4, j <- 1..4]
    # We need to transform this into a valid format
    transformed_generators =
      case generators do
        # Handle list syntax like [i <- 1..4, j <- 1..4]
        list when is_list(list) ->
          # Check if this looks like generator syntax
          if Enum.all?(list, fn
               {:<-, _, [var, _range]} when is_atom(var) -> true
               _ -> false
             end) do
            # Transform to proper AST format
            Enum.map(list, fn {:<-, meta, [var, range]} ->
              {:<-, meta, [quote(do: unquote(var)), range]}
            end)
          else
            generators
          end

        other ->
          other
      end

    quote do
      Problem.variables(
        unquote(problem),
        unquote(var_name),
        unquote(transformed_generators),
        unquote(var_type),
        unquote(opts)
      )
    end
  end

  @doc """
  Public DSL macro for constraints - matches nqueens_dsl.exs syntax.
  """
  defmacro constraints(problem, generators, constraint_expr, description \\ nil) do
    # The generators parameter contains the raw AST from [i <- 1..4]
    # We need to transform this into a valid format
    transformed_generators =
      case generators do
        # Handle list syntax like [i <- 1..4]
        list when is_list(list) ->
          # Check if this looks like generator syntax
          if Enum.all?(list, fn
               {:<-, _, [var, _range]} when is_atom(var) -> true
               _ -> false
             end) do
            # Transform to proper AST format
            Enum.map(list, fn {:<-, meta, [var, range]} ->
              {:<-, meta, [quote(do: unquote(var)), range]}
            end)
          else
            generators
          end

        other ->
          other
      end

    quote do
      Problem.constraints(
        unquote(problem),
        unquote(transformed_generators),
        unquote(constraint_expr),
        unquote(description)
      )
    end
  end

  @doc """
  Public DSL macro for objective - matches nqueens_dsl.exs syntax.
  """
  defmacro objective(problem, objective_expr, opts \\ []) do
    quote do
      unquote(__MODULE__).__set_objective__(
        unquote(problem),
        unquote(objective_expr),
        unquote(opts)
      )
    end
  end

  # Backward compatibility shims - delegate to new Problem module functions
  # These maintain compatibility with existing code while providing new API

  @doc """
  Shim for backward compatibility - delegates to Problem.variables/5
  """
  def add_variables_shim(problem, generators, var_name, var_type, description) do
    Problem.variables(problem, var_name, generators, var_type, description: description)
  end

  @doc """
  Add constraints to a problem using natural mathematical syntax.

  ## Examples

      # One queen per row
      problem = Problem.DSL.add_constraints(problem, [i <- 1..4], x[i, _] == 1, "One queen per row")
  """
  defmacro add_constraints(problem, generators, constraint_expr, description \\ nil) do
    quote do
      unquote(__MODULE__).__add_constraints__(
        unquote(problem),
        unquote(generators),
        unquote(constraint_expr),
        unquote(description)
      )
    end
  end

  @doc """
  Shim for backward compatibility - delegates to Problem.constraints/4
  """
  def add_constraints_shim(problem, generators, constraint_expr, description) do
    Problem.constraints(problem, generators, constraint_expr, description)
  end

  @doc """
  Set the objective function with direction.

  ## Examples

      # Minimize total cost
      problem = Problem.DSL.set_objective(problem, sum(x[_, _]), direction: :minimize)
  """
  defmacro set_objective(problem, objective_expr, opts \\ []) do
    quote do
      unquote(__MODULE__).__set_objective__(
        unquote(problem),
        unquote(objective_expr),
        unquote(opts)
      )
    end
  end

  @doc """
  Shim for backward compatibility - delegates to Problem.objective/3
  """
  def set_objective_shim(problem, objective_expr, opts) do
    Problem.objective(problem, objective_expr, opts)
  end

  # Implementation functions

  def __add_variables__(problem, generators, var_name, var_type, description),
    do: Internal.add_variables(problem, generators, var_name, var_type, description)

  def __add_constraints__(problem, generators, constraint_expr, description),
    do: Internal.add_constraints(problem, generators, constraint_expr, description)

  def __set_objective__(problem, objective_expr, opts),
    do: Internal.set_objective(problem, objective_expr, opts)

  # Helper functions

  defp transform_generators(generators) do
    case generators do
      # Handle list syntax like [i <- 1..4, j <- 1..4]
      list when is_list(list) ->
        # Check if this looks like generator syntax
        if Enum.all?(list, fn
             {:<-, _, [var, _range]} when is_atom(var) -> true
             _ -> false
           end) do
          # Transform to proper AST format
          Enum.map(list, fn {:<-, meta, [var, range]} ->
            {:<-, meta, [quote(do: unquote(var)), range]}
          end)
        else
          generators
        end

      other ->
        other
    end
  end

  defp parse_generators(generators), do: Internal.parse_generators(generators)

  defp evaluate_expression(expr), do: Internal.evaluate_expression(expr)

  defp generate_combinations_from_parsed_generators(parsed_generators),
    do: Internal.generate_combinations_from_parsed_generators(parsed_generators)

  defp create_bindings(parsed_generators, index_vals),
    do: Internal.create_bindings(parsed_generators, index_vals)

  defp parse_constraint_expression(constraint_expr, bindings, problem),
    do: Internal.parse_constraint_expression(constraint_expr, bindings, problem)

  defp parse_expression_to_polynomial(expr, bindings, problem),
    do: Internal.parse_expression_to_polynomial(expr, bindings, problem)

  defp parse_objective_expression(objective_expr, problem),
    do: Internal.parse_objective_expression(objective_expr, problem)

  defp parse_sum_expression(expr, bindings, problem),
    do: Internal.parse_sum_expression(expr, bindings, problem)

  # Normalize remote-call sum ASTs into tuple form expected by the parser
  defp normalize_sum_ast(expr), do: Internal.normalize_sum_ast(expr)

  defp create_var_name(var_name, index_vals), do: Internal.create_var_name(var_name, index_vals)

  defp create_constraint_name(description, index_vals),
    do: Internal.create_constraint_name(description, index_vals)
end
