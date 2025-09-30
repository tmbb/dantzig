defmodule Dantzig.DSL.VariableAccess do
  @moduledoc """
  Macros for variable access syntax like queen2d(i, :_)
  
  This module provides the core functionality for enabling natural variable access
  syntax in the DSL. It creates macros that allow expressions like:
  
      queen2d(i, :_)     # Access queen2d variables with fixed i, wildcard j
      queen2d(:_, j)     # Access queen2d variables with wildcard i, fixed j
      queen2d(:_, :_)    # Access all queen2d variables
  """
  
  @doc """
  Use this module to enable variable access syntax.
  
  ## Examples
  
      defmodule MyOptimization do
        use Dantzig.DSL.VariableAccess
        
        def create_problem do
          problem = Problem.new()
          |> Problem.variables("queen2d", [i <- 1..4, j <- 1..4], :binary)
          
          # Now you can use queen2d(i, :_) syntax
          |> Problem.constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
        end
      end
  """
  defmacro __using__(_opts) do
    quote do
      import Dantzig.DSL.VariableAccess, only: [var_access: 2]
    end
  end
  
  @doc """
  Macro for variable access with function call syntax.
  
  This macro enables the natural syntax for accessing variables in the DSL.
  
  ## Examples
  
      queen2d(i, :_)    # Returns {"queen2d", [], [i, :_]}
      queen3d(i, :_, k) # Returns {"queen3d", [], [i, :_, k]}
      qty(food)         # Returns {"qty", [], [food]}
  """
  defmacro var_access(var_name, indices) when is_list(indices) do
    quote do
      {unquote(var_name), [], unquote(indices)}
    end
  end
  
  @doc """
  Generate macros for specific variable names.
  
  This function creates macros like `defmacro queen2d(indices)` that enable
  the natural syntax for variable access.
  """
  def generate_variable_macros(variable_names) when is_list(variable_names) do
    Enum.map(variable_names, fn var_name ->
      quote do
        defmacro unquote(var_name)(indices) when is_list(indices) do
          quote do
            {unquote(var_name), [], unquote(indices)}
          end
        end
        
        defmacro unquote(var_name)(index) do
          quote do
            {unquote(var_name), [], [unquote(index)]}
          end
        end
      end
    end)
  end
  
  @doc """
  Enable variable access for a specific variable name.
  
  This creates a macro that allows natural syntax for accessing variables.
  
  ## Examples
  
      enable_variable_access("queen2d")
      # Now you can use: queen2d(i, :_)
      
      enable_variable_access("qty")
      # Now you can use: qty(food)
  """
  defmacro enable_variable_access(var_name) when is_binary(var_name) do
    var_atom = String.to_atom(var_name)
    
    quote do
      defmacro unquote(var_atom)(indices) when is_list(indices) do
        quote do
          {unquote(var_atom), [], unquote(indices)}
        end
      end
      
      defmacro unquote(var_atom)(index) do
        quote do
          {unquote(var_atom), [], [unquote(index)]}
        end
      end
    end
  end
  
  @doc """
  Parse variable access expression to get variable name and indices.
  
  ## Examples
  
      parse_variable_access(quote do: queen2d(i, :_))
      # Returns: {"queen2d", [i, :_]}
      
      parse_variable_access(quote do: qty(food))
      # Returns: {"qty", [food]}
  """
  def parse_variable_access(ast) do
    case ast do
      {var_name, [], indices} when is_list(indices) ->
        {var_name, indices}
      
      {var_name, [], [index]} ->
        {var_name, [index]}
      
      _ ->
        raise ArgumentError, "Invalid variable access expression: #{inspect(ast)}"
    end
  end
  
  @doc """
  Check if an expression is a variable access expression.
  
  ## Examples
  
      is_variable_access?(quote do: queen2d(i, :_))  # Returns: true
      is_variable_access?(quote do: x + y)           # Returns: false
  """
  def is_variable_access?(ast) do
    case ast do
      {_var_name, [], _indices} when is_list(_indices) ->
        true
      
      _ ->
        false
    end
  end
end
