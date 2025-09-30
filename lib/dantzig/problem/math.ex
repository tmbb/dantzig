defmodule Dantzig.Problem.Math do
  @moduledoc """
  Mathematical functions for use in optimization expressions.

  This module provides functions like `sum/1` that can be used
  in constraint and objective expressions with pattern-based syntax.
  """

  @doc """
  Sum function for pattern-based expressions.

  ## Examples

      sum(x[_, _])     # Sum all x variables
      sum(x[i, _])     # Sum x variables for fixed i
      sum(x[_, j])     # Sum x variables for fixed j
  """
  defmacro sum(expr) do
    quote do
      {:sum, unquote(expr)}
    end
  end
end

