defmodule Dantzig.Constraint do
  @moduledoc """
  TODO
  """

  require Dantzig.Polynomial, as: Polynomial
  alias Dantzig.SolvedConstraint

  @type t :: %__MODULE__{}

  defstruct name: nil,
            operator: nil,
            left_hand_side: nil,
            right_hand_side: nil,
            metadata: nil

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

  @doc """
  Create new (normalized) constraint.
  Doesn't make sure the constraint is linear.

  Expects 3 required arguments:
    - `left`: a polynomial or number for the left hand side
    - `operator`: one of `:==`, `:>=` or `:<=`
    - `right`: a polynomial or number for the right hand side

  Expects the following optional keyword arguments:
    - `:name`: the name for the constraint
  """
  def new(left, operator, right, opts \\ [])
      when operator in @operators do
    name = Keyword.get(opts, :name)
    # Convert raw numbers into polynomials
    left = Polynomial.to_polynomial(left)
    right = Polynomial.to_polynomial(right)

    difference = Polynomial.subtract(left, right)
    new_constraint_from_difference(difference, operator, name)
  end

  @doc """
  Create new (normalized) linear constraint.
  Will raise an error if the constraint is not linear.

  Expects 3 required arguments:
    - `left`: a polynomial or number for the left hand side
    - `operator`: one of `:==`, `:>=` or `:<=`
    - `right`: a polynomial or number for the right hand side

  Expects the following optional keyword arguments:
    - `:name`: the name for the constraint
  """
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

  @doc false
  def arguments_from_comparison!(comparison) do
    case comparison do
      {operator, _meta, [left, right]} when operator in @operators ->
        {Polynomial.replace_operators(left), operator, Polynomial.replace_operators(right)}

      other ->
        raise ArgumentError, """
          Invalid expression in constraint: #{Macro.to_string(other)}.
          """
    end
  end

  @doc """
  Tests whether the coonstraint depends on a given variable.
  Similar to `Dantzig.Polynomial.depends_on?/2`.
  """
  def depends_on?(%__MODULE__{} = constraint, variable_name) do
    Polynomial.depends_on?(constraint.left_hand_side, variable_name) or
      Polynomial.depends_on?(constraint.right_hand_side, variable_name)
  end

  @doc """
  Tests whether the coonstraint depends on a given variable.
  Similar to `Dantzig.Polynomial.depends_on?/2`.
  """
  @spec solve_for_variable(t(), ProblemVariable.variable_name()) :: SolvedConstraint.t()
  def solve_for_variable(%__MODULE__{} = constraint, variable) do
    unless depends_on?(constraint, variable) do
      raise ArgumentError, """
        The constraint doesn't depend on the variable #{inspect(variable)}
        Constraint:

        #{inspect(constraint)}
        """
    end

    # Ensure we are using a canonical representation
    delta = Polynomial.algebra(constraint.left_hand_side - constraint.right_hand_side)
    coef = Polynomial.coefficient_for(delta, [variable])
    monomial = Polynomial.monomial(coef, variable)

    new_right = Polynomial.algebra((monomial - delta) / coef)

    new_operator =
      case {coef, constraint.operator} do
        {_any_sign, :==} ->
          :==

        {c, operator} when c > 0.0 ->
          operator

        {c, :<=} when c < 0.0 ->
          :>=

        {c, :>=} when c < 0.0 ->
          :<=
      end

    %SolvedConstraint{
      name: constraint.name,
      variable: variable,
      operator: new_operator,
      expression: new_right,
      metadata: constraint.metadata
    }
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
