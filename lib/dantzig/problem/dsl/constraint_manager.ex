defmodule Dantzig.Problem.DSL.ConstraintManager do
  @moduledoc """
  Manages constraint creation and objective setting for the Dantzig DSL.

  This module handles:
  - Constraint creation with pattern-based generators
  - Objective function parsing and setting
  - Constraint expression parsing and validation
  - Integration with the core Problem module
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial

  # Public implementation entrypoints used by macros in Dantzig.Problem.DSL
  def add_constraints(problem, generators, constraint_expr, description) do
    parsed_generators = parse_generators(generators)
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    Enum.reduce(combinations, problem, fn index_vals, current_problem ->
      bindings = create_bindings(parsed_generators, index_vals)
      constraint = parse_constraint_expression(constraint_expr, bindings, current_problem)

      constraint_name =
        if description, do: create_constraint_name(description, index_vals), else: nil

      constraint = if constraint_name, do: %{constraint | name: constraint_name}, else: constraint
      Problem.add_constraint(current_problem, constraint)
    end)
  end

  def set_objective(problem, objective_expr, opts) do
    direction = Keyword.get(opts, :direction)

    if direction not in [:minimize, :maximize] do
      raise ArgumentError,
            "Objective direction must be :minimize or :maximize, got: #{inspect(direction)}"
    end

    objective = parse_objective_expression(objective_expr, problem)
    %{problem | objective: objective, direction: direction}
  end

  def parse_constraint_expression(constraint_expr, bindings, problem) do
    case constraint_expr do
      {:==, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :==, right_poly)

      {:<=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :<=, right_poly)

      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :>=, right_poly)

      _ ->
        raise ArgumentError, "Unsupported constraint expression: #{inspect(constraint_expr)}"
    end
  end

  def parse_objective_expression(objective_expr, problem) do
    expr = normalize_sum_ast(objective_expr)

    case expr do
      {:sum, expr} -> parse_sum_expression(expr, %{}, problem)
      expr when is_tuple(expr) -> parse_expression_to_polynomial(expr, %{}, problem)
      value when is_number(value) -> Polynomial.const(value)
      _ -> raise ArgumentError, "Unsupported objective expression: #{inspect(expr)}"
    end
  end

  def create_constraint_name(description, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{description}_#{index_str}"
  end

  # Import functions from VariableManager
  def parse_generators(generators),
    do: Dantzig.Problem.DSL.VariableManager.parse_generators(generators)

  def generate_combinations_from_parsed_generators(generators),
    do:
      Dantzig.Problem.DSL.VariableManager.generate_combinations_from_parsed_generators(generators)

  def create_bindings(generators, index_vals),
    do: Dantzig.Problem.DSL.VariableManager.create_bindings(generators, index_vals)

  def parse_expression_to_polynomial(expr, bindings, problem),
    do:
      Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(expr, bindings, problem)

  def parse_sum_expression(expr, bindings, problem),
    do: Dantzig.Problem.DSL.ExpressionParser.parse_sum_expression(expr, bindings, problem)

  def normalize_sum_ast(expr), do: Dantzig.Problem.DSL.ExpressionParser.normalize_sum_ast(expr)
end
