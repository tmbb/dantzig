defmodule Dantzig.Problem do
  alias Dantzig.Polynomial
  alias Dantzig.ProblemVariable
  alias Dantzig.Constraint
  alias Dantzig.SolvedConstraint

  @nr_of_zeros 8

  @type t :: %__MODULE__{}

  defstruct variable_counter: 0,
            constraint_counter: 0,
            objective: Polynomial.const(0.0),
            direction: nil,
            variables: %{},
            constraints: %{},
            contraints_metadata: %{}

  @spec solve_for_all_variables(t()) :: %{ProblemVariable.variable_namme() => SolvedConstraint.t()}
  def solve_for_all_variables(%__MODULE__{} = problem) do
    # There are two ways of solving for all variables:
    #
    #   1. Iterate over all variables and solve constraints that depend on that variable
    #   2. Iterate over all constraints and solve for the variables in each constraint
    #
    # The second one is much more performant, so we pick that one
    Enum.reduce(problem.constraints, %{}, fn {_constraint_name, constraint}, solved_constraints ->
      # Get all variables from that constraint
      variable_names = Polynomial.variables(constraint.left_hand_side)
      # Iterate over all constraints
      Enum.reduce(variable_names, solved_constraints, fn variable_name, solved_constraints ->
        # Put the new solved constraint in the constraint map
        solved_constraint = Constraint.solve_for_variable(constraint, variable_name)
        Map.update(solved_constraints, variable_name, [solved_constraint], fn constraints ->
          [solved_constraint | constraints]
        end)
      end)
    end)
  end

  @spec new(Keyword.t()) :: t()
  def new(opts) when is_list(opts) do
    direction =
      case Keyword.fetch(opts, :direction) do
        {:ok, direction} ->
          direction

        :error ->
          raise RuntimeError, """
          Optimization direction is required when creating a Dantzig.Problem. \
          Please specify one of :maximize or :minimize\
          """
      end

    %__MODULE__{direction: direction}
  end

  @spec add_constraint(t(), Constraint.t(), ConstraintMetadata.t()) :: t()
  def add_constraint(problem, constraint, metadata \\ nil) do
    constraint_id =
      if constraint.name do
        "c#{left_pad_with_zeros(problem.constraint_counter)}_#{constraint.name}"
      else
        "c#{left_pad_with_zeros(problem.constraint_counter)}"
      end

    # Add the unique ID as a new name for the constraint;
    # Because of how we serialize linear problems, the constraint name should be unique.
    new_constraint = %{constraint | name: constraint_id, metadata: metadata}

    new_constraints = Map.put(problem.constraints, constraint_id, new_constraint)

    %{
      problem
      | constraints: new_constraints,
        constraint_counter: problem.constraint_counter + 1
    }
  end

  defp left_pad_with_zeros(number) when is_integer(number) do
    String.pad_leading(to_string(number), @nr_of_zeros, "0")
  end

  def increment_objective(problem, polynomial) do
    %{problem | objective: Polynomial.add(problem.objective, polynomial)}
  end

  def decrement_objective(problem, polynomial) do
    %{problem | objective: Polynomial.subtract(problem.objective, polynomial)}
  end

  def maximize(problem, polynomial) do
    case problem.direction do
      :minimize -> decrement_objective(problem, polynomial)
      :maximize -> increment_objective(problem, polynomial)
    end
  end

  def minimize(problem, polynomial) do
    case problem.direction do
      :minimize -> increment_objective(problem, polynomial)
      :maximize -> decrement_objective(problem, polynomial)
    end
  end

  def new_unmangled_variable(%__MODULE__{} = problem, name, opts \\ []) do
    min = Keyword.get(opts, :min, nil)
    max = Keyword.get(opts, :max, nil)
    type = Keyword.get(opts, :type, :real)

    variable = %ProblemVariable{name: name, min: min, max: max, type: type}
    monomial = Polynomial.variable(name)
    new_variables = Map.put(problem.variables, name, variable)

    # Even though we don't use the counter, it's better to increment it
    # for the sake of consistency

    new_problem = %{
      problem
      | variables: new_variables,
        variable_counter: problem.variable_counter + 1
    }

    {new_problem, monomial}
  end

  def new_variable(%__MODULE__{} = problem, suffix, opts \\ []) do
    prefix = Keyword.get(opts, :prefix, nil)

    name =
      case suffix do
        bin when is_binary(bin) ->
          case prefix do
            nil ->
              "x#{left_pad_with_zeros(problem.variable_counter)}_#{suffix}"

            bin2 when is_binary(bin2) ->
              "x#{left_pad_with_zeros(problem.variable_counter)}_#{prefix}_#{suffix}"
          end

        nil ->
          raise "Suffix can't be nil!"

        other ->
          other
      end

    min = Keyword.get(opts, :min, nil)
    max = Keyword.get(opts, :max, nil)
    type = Keyword.get(opts, :type, :real)

    # Convert min and max to numbers.
    # They might have been converted into polynomials by the
    # overloadad operators.
    min = min && Polynomial.to_number!(min)
    max = max && Polynomial.to_number!(max)

    variable = %ProblemVariable{name: name, min: min, max: max, type: type}
    monomial = Polynomial.variable(name)
    new_variables = Map.put(problem.variables, name, variable)

    new_problem = %{
      problem
      | variables: new_variables,
        variable_counter: problem.variable_counter + 1
    }

    {new_problem, monomial}
  end

  def new_variables(%__MODULE__{} = problem, prefixes, opts \\ []) do
    {new_problem, monomials} =
      Enum.reduce(prefixes, {problem, []}, fn new_prefix, {current_problem, current_monomials} ->
        {new_problem, new_monomial} = new_variable(current_problem, new_prefix, opts)
        {new_problem, [new_monomial | current_monomials]}
      end)

    {new_problem, Enum.reverse(monomials)}
  end

  @doc false
  def validate_constraint_variables!(problem, left, right) do
    syntax_colors = IO.ANSI.syntax_colors()

    left_extra =
      left
      |> Polynomial.variables()
      |> Enum.filter(fn var_name -> not Map.has_key?(problem.variables, var_name) end)

    right_extra =
      right
      |> Polynomial.variables()
      |> Enum.filter(fn var_name -> not Map.has_key?(problem.variables, var_name) end)

    unless left_extra == [] do
      raise RuntimeError, """
      Error when adding constant to Linear Problem: \
      variable(s) #{into_textual_list(left_extra)} \
      don't exist in the problem

      #{inspect(problem, pretty: true, syntax_colors: syntax_colors)}

      #{IO.ANSI.red()}left side of constraint:

      #{inspect(left, pretty: true, syntax_colors: syntax_colors)}
      """
    end

    unless right_extra == [] do
      raise RuntimeError, """
      Error when adding constant to Linear Problem: \
      variable(s) #{into_textual_list(right_extra)} \
      don't exist in the problem

      #{inspect(problem, pretty: true, syntax_colors: syntax_colors)}

      #{IO.ANSI.red()}right side of constraint:

      #{inspect(right, pretty: true, syntax_colors: syntax_colors)}
      """
    end
  end

  defp into_textual_list(list) do
    Enum.join(list, ", ")
  end
end
