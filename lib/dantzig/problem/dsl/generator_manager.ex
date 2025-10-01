defmodule Dantzig.Problem.DSL.GeneratorManager do
  @moduledoc """
  Provides a clean interface to generator functionality for the Dantzig DSL.

  This module serves as a facade that delegates to the appropriate specialized
  modules for generator parsing, combination generation, and binding creation.
  """

  # Simple delegation module for generator functions
  # This module provides a clean interface to generator functionality

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
end
