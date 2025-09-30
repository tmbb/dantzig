defmodule Dantzig.Problem.Syntax do
  @moduledoc """
  Syntax macros for the DSL.

  This module provides macros that enable natural syntax for accessing variables
  in constraints and objectives.
  """

  @doc """
  Enable variable access syntax for the DSL.

  This macro should be used at the top of files that use the DSL.
  """
  defmacro enable_dsl_syntax do
    quote do
      import Dantzig.Problem.Syntax, only: [x: 1]

      # Create a macro for x that can handle the [i, _] syntax
      defmacro x(indices) when is_list(indices) do
        quote do
          {"x", [], unquote(indices)}
        end
      end

      defmacro x(index) do
        quote do
          {"x", [], [unquote(index)]}
        end
      end
    end
  end

  @doc """
  Variable access macro that enables x syntax.

  This macro is automatically imported when using enable_dsl_syntax/0.
  """
  defmacro x(indices) when is_list(indices) do
    quote do
      {"x", [], unquote(indices)}
    end
  end

  defmacro x(index) do
    quote do
      {"x", [], [unquote(index)]}
    end
  end
end
