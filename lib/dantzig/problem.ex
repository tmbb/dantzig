defmodule Dantzig.Problem do
  alias Dantzig.Polynomial

  defmodule Variable do
    defstruct name: nil,
              min: nil,
              max: nil,
              type: :real
  end

  defmodule Constraint do
    defstruct name: nil,
              operator: nil,
              left_hand_side: nil,
              right_hand_side: nil
  end

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

  defp left_pad_with_zeros(number) when is_integer(number) do
    String.pad_leading(to_string(number), 5, "0")
  end

  def increment_objective(problem, polynomial) do
    new_problem = %{problem | objective: Polynomial.add(problem.objective, polynomial)}
    {new_problem, new_problem.objective}
  end

  def decrement_objective(problem, polynomial) do
    new_problem = %{problem | objective: Polynomial.subtract(problem.objective, polynomial)}
    {new_problem, new_problem.objective}
  end

  def new_variable(%__MODULE__{} = problem, suffix, opts \\ []) when is_binary(suffix) do
    name = "x#{left_pad_with_zeros(problem.variable_counter)}_#{suffix}"
    min = Keyword.get(opts, :min, nil)
    max = Keyword.get(opts, :max, nil)
    type = Keyword.get(opts, :type, :real)

    variable = %Variable{name: name, min: min, max: max, type: type}
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

  @operators [
    :=,
    :==,
    :<,
    :>,
    :>=,
    :<=
  ]

  defmacro new_linear_constraint(problem, comparison, opts \\ []) do
    {left, operator, right} = parse_comparison!(comparison)

    quote do
      unquote(__MODULE__).new_linear_constraint(
        unquote(problem),
        unquote(left),
        unquote(operator),
        unquote(right),
        unquote(opts)
      )
    end
  end

  defmacro new_constraint(problem, comparison, opts \\ []) do
    {left, operator, right} = parse_comparison!(comparison)

    quote do
      unquote(__MODULE__).new_constraint(
        unquote(problem),
        unquote(left),
        unquote(operator),
        unquote(right),
        unquote(opts)
      )
    end
  end

  defp parse_comparison!(expression) do
    case expression do
      {operator, _meta, [left, right]} when operator in @operators ->
        {left, operator, right}

      other ->
        raise CompileError, """
        Invalid expression in constraint: #{Macro.to_string(other)}.
        """
    end
  end

  def new_linear_constraint(%__MODULE__{} = problem, left, operator, right, opts \\ [])
      when operator in @operators do
    name = Keyword.get(opts, :name)
    # Convert raw numbers into polynomials
    left = Polynomial.to_polynomial(left)
    right = Polynomial.to_polynomial(right)

    difference = Polynomial.subtract(left, right)
    validate_linear_constraint!(problem, left, right, difference)
    new_constraint_from_difference(problem, difference, operator, name)
  end

  def new_constraint(%__MODULE__{} = problem, left, operator, right, opts \\ [])
      when operator in @operators do
    name = Keyword.get(opts, :name)
    # Convert raw numbers into polynomials
    left = Polynomial.to_polynomial(left)
    right = Polynomial.to_polynomial(right)

    validate_constraint_variables!(problem, left, right)
    difference = Polynomial.subtract(left, right)
    new_constraint_from_difference(problem, difference, operator, name)
  end

  defp new_constraint_from_difference(%__MODULE__{} = problem, difference, operator, name)
       when operator in @operators do
    {%Polynomial{} = left_hand_side, minus_right_hand_side} =
      Polynomial.split_constant(difference)

    # The left_hand_side is a polynomial and the minus_right_side is a polynomial
    suffix = if name do "_#{name}" else "" end
    name = "c#{left_pad_with_zeros(problem.constraint_counter)}#{suffix}"

    constraint = %Constraint{
      name: name,
      operator: operator,
      left_hand_side: left_hand_side,
      right_hand_side: -minus_right_hand_side
    }

    new_constraints = Map.put(problem.constraints, name, constraint)

    new_problem = %{
      problem
      | constraints: new_constraints,
        constraint_counter: problem.constraint_counter + 1
    }

    {new_problem, constraint}
  end

  defp into_textual_list(list) do
    Enum.join(list, ", ")
  end

  defp validate_linear_constraint!(_problem, _left, _right, difference) do
    unless Polynomial.degree(difference) < 2 do
      raise RuntimeError, """
      Error when adding constraint to Linear Problem. Constraint is not linear.
      """
    end
  end

  defp validate_constraint_variables!(problem, left, right) do
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

  defmacro with_implicit_problem(problem_variable, do: body) do
    file = __CALLER__.file
    line = __CALLER__.line

    Macro.prewalk(body, fn
      {:<~, _meta1, [constraint, {:assert, _meta, [{operator, _meta2, [left, right]}]}]} ->
        actual_operator = if operator == :==, do: :=, else: operator

        quote do
          {unquote(problem_variable), unquote(constraint)} =
            Dantzig.Problem.new_constraint(
              unquote(problem_variable),
              unquote(left),
              unquote(actual_operator),
              unquote(right)
            )
        end

      {:constraint!, _meta1, [{operator, _meta2, [left, right]}]} ->
        actual_operator = if operator == :==, do: :=, else: operator

        quote do
          {unquote(problem_variable), _} =
            Dantzig.Problem.new_constraint(
              unquote(problem_variable),
              unquote(left),
              unquote(actual_operator),
              unquote(right)
            )
        end

      {:<~, _meta1, [constraint, {:assert_linear, _meta2, {operator, _meta3, [left, right]}}]} ->
        actual_operator = if operator == :==, do: :=, else: operator

        quote do
          {unquote(problem_variable), unquote(constraint)} =
            Dantzig.Problem.new_linear_constraint(
              unquote(problem_variable),
              unquote(left),
              unquote(actual_operator),
              unquote(right)
            )
        end

      {:<~, _meta1, [left, {f, meta2, args}]} when is_list(args) ->
        new_function_call = {f, meta2, [problem_variable | args]}

        quote file: file, line: Keyword.get(meta2, :line, line) do
          {unquote(problem_variable), unquote(left)} = unquote(new_function_call)
        end

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
