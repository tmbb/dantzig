defmodule Dantzig.Constraint do
  @moduledoc """
  TODO
  """
  defstruct name: nil,
            operator: nil,
            left_hand_side: nil,
            right_hand_side: nil,
            metadata: nil

  alias Dantzig.Polynomial

  @operators [
    :==,
    :>=,
    :<=,
    :in
  ]

  defmacro new(comparison, opts \\ []) do
    {left, operator, right} = arguments_from_comparison!(comparison)

    quote do
      unquote(__MODULE__).new(
        unquote(left),
        unquote(operator),
        unquote(right),
        unquote(opts)
      )
    end
  end

  def new(left, operator, right, opts \\ [])
      when operator in @operators do
    name = Keyword.get(opts, :name)
    # Convert raw numbers into polynomials
    left = Polynomial.to_polynomial(left)
    right = Polynomial.to_polynomial(right)

    difference = Polynomial.subtract(left, right)
    new_constraint_from_difference(difference, operator, name)
  end

  def new_linear(left, operator, right, opts \\ [])
      when operator in @operators do
    name = Keyword.get(opts, :name)
    # Convert raw numbers into polynomials
    left = Polynomial.to_polynomial(left)
    right = Polynomial.to_polynomial(right)

    difference = Polynomial.subtract(left, right)
    validate_linear_constraint!(left, right, difference)
    new_constraint_from_difference(difference, operator, name)
  end

  defmacro new_linear(comparison, opts \\ []) do
    {left, operator, right} = arguments_from_comparison!(comparison)

    quote do
      unquote(__MODULE__).new_linear(
        unquote(left),
        unquote(operator),
        unquote(right),
        unquote(opts)
      )
    end
  end

  defp new_constraint_from_difference(difference, operator, name)
       when operator in @operators do
    {%Polynomial{} = left_hand_side, minus_right_hand_side} =
      Polynomial.split_constant(difference)

    %__MODULE__{
      name: name,
      operator: operator,
      left_hand_side: left_hand_side,
      right_hand_side: -minus_right_hand_side
    }
  end

  defp validate_linear_constraint!(_left, _right, difference) do
    unless Polynomial.degree(difference) < 2 do
      raise RuntimeError, """
      Error when adding constraint to Linear Problem. Constraint is not linear.
      """
    end
  end

  def arguments_from_comparison!(comparison) do
    case comparison do
      {operator, _meta, [left, right]} when operator in @operators ->
        {Polynomial.replace_operators(left), operator, Polynomial.replace_operators(right)}

      other ->
        raise CompileError, """
        Invalid expression in constraint: #{Macro.to_string(other)}.
        """
    end
  end

  def get_variables_by(%__MODULE__{} = constraint, fun) do
    lhs_variables = Polynomial.get_variables_by(constraint.left_hand_side, fun)
    rhs_variables = Polynomial.get_variables_by(constraint.right_hand_side, fun)

    # Merge all variables
    all_variables = lhs_variables ++ rhs_variables

    # Don't return the same variable twice in the unlikely case that we have
    # a constraint with the same variable on both sides
    Enum.uniq(all_variables)
  end
end
