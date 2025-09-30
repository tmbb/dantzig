defmodule Dantzig.Problem.Vars do
  @moduledoc """
  Variable access macros for the DSL.

  This module provides macros that allow natural syntax like `x[i, j]` and `x[i, _]`
  for accessing variables in constraints and objectives.
  """

  @doc """
  Macro for variable access with indices.

  This macro enables the syntax `x[i, j]` and `x[i, _]` in the DSL.
  """
  defmacro var_access(var_name, indices) do
    quote do
      {unquote(var_name), [], unquote(indices)}
    end
  end
end

