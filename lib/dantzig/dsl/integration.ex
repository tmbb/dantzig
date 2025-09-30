defmodule Dantzig.DSL.Integration do
  @moduledoc """
  Integration module that brings together all DSL components.
  
  This module provides the complete DSL functionality for building optimization
  problems with natural syntax. It integrates variable access, sum functions,
  constraint parsing, and chained constraints.
  
  ## Usage
  
      defmodule MyOptimization do
        use Dantzig.DSL.Integration
        
        def create_nqueens_problem do
          Problem.new(name: "N-Queens")
          |> Problem.variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")
          |> Problem.constraints([i <- 1..4], queen2d(i, :_) == 1, "One queen per row")
          |> Problem.constraints([j <- 1..4], queen2d(:_, j) == 1, "One queen per column")
          |> Problem.objective(sum(queen2d(:_, :_)), direction: :minimize)
        end
      end
  """
  
  defmacro __using__(_opts) do
    quote do
      # Import all DSL components
      import Dantzig.DSL.VariableAccess, only: [var_access: 2]
      import Dantzig.DSL.SumFunction, only: [sum: 1, sum: 3]
      
      # Import Problem module
      require Dantzig.Problem, as: Problem
      
      # Import Math module for sum function
      require Dantzig.Problem.Math, as: Math
    end
  end
  
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
  
  defmacro enable_variable_access(var_names) when is_list(var_names) do
    var_macros = Enum.map(var_names, fn var_name ->
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
    end)
    
    quote do
      unquote(var_macros)
    end
  end
end
