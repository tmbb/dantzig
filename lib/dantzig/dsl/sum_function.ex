defmodule Dantzig.DSL.SumFunction do
  @moduledoc """
  Sum function for DSL expressions
  
  This module provides the sum() macro that enables natural mathematical syntax
  for summing variables and expressions in the DSL.
  
  ## Examples
  
      sum(queen2d(:_, :_))  # Sum all queen2d variables
      sum(queen2d(i, :_))   # Sum queen2d variables for fixed i
      sum(qty(food) * cost(food) for food <- food_names)  # Generator-based sum
  """
  
  @doc """
  Sum macro for pattern-based expressions.
  
  This macro creates a sum expression that can be used in constraints and objectives.
  
  ## Examples
  
      sum(queen2d(:_, :_))  # Sum all queen2d variables
      sum(queen2d(i, :_))   # Sum queen2d variables for fixed i
      sum(qty(food))        # Sum qty variables
  """
  defmacro sum(expr) do
    quote do
      {:sum, unquote(expr)}
    end
  end
  
  @doc """
  Sum macro for generator-based expressions.
  
  This macro creates a sum expression with a generator, similar to Python's
  generator expressions or Julia's generator syntax.
  
  ## Examples
  
      sum(qty(food) * cost(food) for food <- food_names)
      sum(x(i) * c(i) for i <- 1..n)
      sum(queen2d(i, j) * weight(i, j) for i <- 1..4, j <- 1..4)
  """
  defmacro sum(expr, :for, generators) do
    quote do
      {:sum, {:for, unquote(expr), unquote(generators)}}
    end
  end
  
  @doc """
  Parse a sum expression to extract its components.
  
  ## Examples
  
      parse_sum_expression(quote do: sum(queen2d(:_, :_)))
      # Returns: {:pattern, {:"queen2d", [], [:_ , :_]}}
      
      parse_sum_expression(quote do: sum(qty(food) for food <- food_names))
      # Returns: {:generator, qty(food), [food <- food_names]}
  """
  def parse_sum_expression(ast) do
    case ast do
      {:sum, expr} ->
        {:pattern, expr}
      
      {:sum, {:for, expr, generators}} ->
        {:generator, expr, generators}
      
      _ ->
        raise ArgumentError, "Invalid sum expression: #{inspect(ast)}"
    end
  end
  
  @doc """
  Check if an expression is a sum expression.
  
  ## Examples
  
      is_sum_expression?(quote do: sum(queen2d(:_, :_)))  # Returns: true
      is_sum_expression?(quote do: x + y)                # Returns: false
  """
  def is_sum_expression?(ast) do
    case ast do
      {:sum, _expr} ->
        true
      
      _ ->
        false
    end
  end
  
  @doc """
  Extract the inner expression from a sum expression.
  
  ## Examples
  
      extract_sum_expression(quote do: sum(queen2d(:_, :_)))
      # Returns: {:"queen2d", [], [:_ , :_]}
  """
  def extract_sum_expression(ast) do
    case ast do
      {:sum, expr} ->
        expr
      
      _ ->
        raise ArgumentError, "Not a sum expression: #{inspect(ast)}"
    end
  end
  
  @doc """
  Check if a sum expression uses generator syntax.
  
  ## Examples
  
      is_generator_sum?(quote do: sum(qty(food) for food <- food_names))  # Returns: true
      is_generator_sum?(quote do: sum(queen2d(:_, :_)))                   # Returns: false
  """
  def is_generator_sum?(ast) do
    case ast do
      {:sum, {:for, _expr, _generators}} ->
        true
      
      _ ->
        false
    end
  end
  
  @doc """
  Extract generator information from a generator-based sum expression.
  
  ## Examples
  
      extract_generator_info(quote do: sum(qty(food) for food <- food_names))
      # Returns: {qty(food), [food <- food_names]}
  """
  def extract_generator_info(ast) do
    case ast do
      {:sum, {:for, expr, generators}} ->
        {expr, generators}
      
      _ ->
        raise ArgumentError, "Not a generator sum expression: #{inspect(ast)}"
    end
  end
end
