defmodule Dantzig.Problem do
  alias Dantzig.Polynomial
  alias Dantzig.ProblemVariable
  alias Dantzig.Constraint

  defstruct variable_counter: 0,
            constraint_counter: 0,
            objective: Polynomial.const(0.0),
            direction: nil,
            variables: %{},
            constraints: %{}

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

  def add_constraint(problem, constraint) do
    constraint_id =
      if constraint.name do
        "c#{problem.constraint_counter}_#{constraint.name}"
      else
        "c#{problem.constraint_counter}"
      end

    # Add the unique ID as a new name for the constraint;
    # Because of how we serialize linear problems, the constraint name should be unique.
    new_constraint = %{constraint | name: constraint_id}

    new_constraints = Map.put(problem.constraints, constraint_id, new_constraint)

    %{problem | constraints: new_constraints, constraint_counter: problem.constraint_counter + 1}
  end

  defp left_pad_with_zeros(number) when is_integer(number) do
    String.pad_leading(to_string(number), 5, "0")
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

  def new_variable(%__MODULE__{} = problem, suffix, opts \\ []) when is_binary(suffix) do
    name = "x#{left_pad_with_zeros(problem.variable_counter)}_#{suffix}"
    min = Keyword.get(opts, :min, nil)
    max = Keyword.get(opts, :max, nil)
    type = Keyword.get(opts, :type, :real)

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

  defmacro with_implicit_problem(problem_variable, do: body) do
    file = __CALLER__.file
    line = __CALLER__.line

    Macro.prewalk(body, fn
      {:decrement_objective!, _meta, [polynomial]} ->

        quote do
          unquote(problem_variable) =
            Dantzig.Problem.decrement_objective(
              unquote(problem_variable),
              unquote(polynomial)
            )
        end

      {:increment_objective!, _meta, [polynomial]} ->

        quote do
          unquote(problem_variable) =
            Dantzig.Problem.increment_objective(
              unquote(problem_variable),
              unquote(polynomial)
            )
        end

      {:constraint!, _meta, [comparison]} ->
        {left, operator, right} = Constraint.arguments_from_comparison!(comparison)

        quote do
          unquote(problem_variable) =
            Dantzig.Problem.add_constraint(
              unquote(problem_variable),
              Dantzig.Constraint.new(
                unquote(left),
                unquote(operator),
                unquote(right)
              )
            )
        end

      {:linear_constraint!, _meta, [comparison]} ->
        {left, operator, right} = Constraint.arguments_from_comparison!(comparison)

        quote do
          unquote(problem_variable) =
            Dantzig.Problem.add_constraint(
              unquote(problem_variable),
              Dantzig.Constraint.new_linear(
                unquote(left),
                unquote(operator),
                unquote(right)
              )
            )
        end

      # {:<~, _meta1, [left, {f, meta2, args}]} when is_list(args) ->
      #   new_function_call = {f, meta2, [problem_variable | args]}

      #   quote file: file, line: Keyword.get(meta2, :line, line) do
      #     {unquote(problem_variable), unquote(left)} = unquote(new_function_call)
      #   end

      {:v!, meta1, [{var_name, _meta2, atom} | rest]} when is_atom(var_name) and is_atom(atom) ->
        unhygienic_var = Macro.var(var_name, nil)
        var_name_as_string = Atom.to_string(var_name)
        args = [problem_variable, var_name_as_string | rest]

        quote file: file, line: Keyword.get(meta1, :line, line) do
          {unquote(problem_variable), unquote(unhygienic_var)} =
            apply(Dantzig.Problem, :new_variable, unquote(args))
        end

      other ->
        other
    end)
  end
end
