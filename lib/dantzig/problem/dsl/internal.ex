defmodule Dantzig.Problem.DSL.Internal do
  @moduledoc false

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial

  # Public implementation entrypoints used by macros in Dantzig.Problem.DSL
  # Now delegates to specialized modules for better organization

  def add_variables(problem, generators, var_name, var_type, description) do
    Dantzig.Problem.DSL.VariableManager.add_variables(
      problem,
      generators,
      var_name,
      var_type,
      description
    )
  end

  def add_constraints(problem, generators, constraint_expr, description) do
    Dantzig.Problem.DSL.ConstraintManager.add_constraints(
      problem,
      generators,
      constraint_expr,
      description
    )
  end

  def set_objective(problem, objective_expr, opts) do
    Dantzig.Problem.DSL.ConstraintManager.set_objective(problem, objective_expr, opts)
  end

  # Legacy function delegations for backward compatibility
  # These functions now delegate to the appropriate specialized modules

  def parse_generators(generators),
    do: Dantzig.Problem.DSL.VariableManager.parse_generators(generators)

  def generate_combinations_from_parsed_generators(generators),
    do:
      Dantzig.Problem.DSL.VariableManager.generate_combinations_from_parsed_generators(generators)

  def create_bindings(generators, index_vals),
    do: Dantzig.Problem.DSL.VariableManager.create_bindings(generators, index_vals)

  def create_var_name(var_name, index_vals),
    do: Dantzig.Problem.DSL.VariableManager.create_var_name(var_name, index_vals)

  def create_constraint_name(description, index_vals),
    do: Dantzig.Problem.DSL.ConstraintManager.create_constraint_name(description, index_vals)

  def parse_constraint_expression(expr, bindings, problem),
    do: Dantzig.Problem.DSL.ConstraintManager.parse_constraint_expression(expr, bindings, problem)

  def parse_expression_to_polynomial(expr, bindings, problem),
    do:
      Dantzig.Problem.DSL.ExpressionParser.parse_expression_to_polynomial(expr, bindings, problem)

  def parse_sum_expression(expr, bindings, problem),
    do: Dantzig.Problem.DSL.ExpressionParser.parse_sum_expression(expr, bindings, problem)

  def normalize_sum_ast(expr), do: Dantzig.Problem.DSL.ExpressionParser.normalize_sum_ast(expr)
end
