defmodule Dantzig.DSL do
  @moduledoc """
  Domain-specific modeling API for creating variables and constraints.

  Formerly `Dantzig.Macros`.
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial

  @doc """
  Create variables with clean syntax: x[i, j] for i <- 1..8, j <- 1..8

  ## Examples

      problem = Macros.add_variables(problem, [i <- 1..8, j <- 1..8], "x", :binary, "Position of queen")
      problem = Macros.add_variables(problem, [i <- 1..5, j <- 1..5, k <- 1..3], "x", :binary, "3D variables")
  """
  defmacro add_variables(problem, generators, var_name, var_type, description \\ nil) do
    quote do
      unquote(__MODULE__).__add_variables__(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(var_type),
        unquote(description)
      )
    end
  end

  @doc """
  Create constraints with clean syntax: sum(x[i, _]) == 1

  ## Examples

      problem = Macros.add_constraints(problem, [i <- 1..8], "x", {i, :_}, :==, 1, "One queen per row")
      problem = Macros.add_constraints(problem, [j <- 1..8], "x", {:_, j}, :==, 1, "One queen per column")
  """
  defmacro add_constraints(
             problem,
             generators,
             var_name,
             pattern,
             operator,
             value,
             description \\ nil
           ) do
    quote do
      unquote(__MODULE__).__add_constraints__(
        unquote(problem),
        unquote(generators),
        unquote(var_name),
        unquote(pattern),
        unquote(operator),
        unquote(value),
        unquote(description)
      )
    end
  end

  # Implementation functions

  def __add_variables__(problem, generators, var_name, var_type, _description) do
    # 1. Parse generators to get variable ranges
    parsed_generators = parse_generators(generators)

    # 2. Generate all combinations from generators
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    # 3. Create variables for each combination
    var_map =
      Enum.reduce(combinations, %{}, fn index_vals, acc ->
        # Create variable name with indices
        var_name_with_indices = create_var_name(var_name, index_vals)

        # Create the variable
        {_new_problem, monomial} =
          Problem.new_variable(problem, var_name_with_indices, type: var_type)

        # Store in variable map
        key = List.to_tuple(index_vals)
        Map.put(acc, key, monomial)
      end)

    # 4. Store the variable map in the problem
    Problem.put_variables_nd(problem, var_name, var_map)
  end

  def __add_constraints__(problem, generators, var_name, pattern, operator, value, description) do
    # 1. Parse generators to get variable ranges
    parsed_generators = parse_generators(generators)

    # 2. Generate all combinations from generators
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    # 3. Get the variable map
    var_map = Problem.get_variables_nd(problem, var_name)

    if var_map do
      # 4. Create constraints for each combination
      Enum.reduce(combinations, problem, fn index_vals, current_problem ->
        # Create binding environment for this combination
        bindings = create_bindings(parsed_generators, index_vals)

        # Create pattern from bindings
        constraint_pattern = create_pattern_from_bindings(pattern, bindings)

        # Sum all matching variables
        sum_poly =
          var_map
          |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, constraint_pattern) end)
          |> Enum.reduce(Polynomial.const(0), fn {_key, monomial}, acc ->
            Polynomial.add(acc, monomial)
          end)

        # Create constraint name
        constraint_name =
          if description do
            create_constraint_name(description, index_vals)
          else
            nil
          end

        # Create the constraint
        constraint =
          Constraint.new_linear(sum_poly, operator, Polynomial.const(value),
            name: constraint_name
          )

        # Add to problem
        Problem.add_constraint(current_problem, constraint)
      end)
    else
      raise ArgumentError, "Variable map not found for: #{var_name}"
    end
  end

  # Helper functions

  defp parse_generators(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        {var, Enum.to_list(range)}

      {:<-, _, [var, list]} when is_list(list) ->
        {var, list}

      {:<-, _, [var, expr]} ->
        # Handle computed expressions
        {var, evaluate_expression(expr)}

      {var, :in, values} when is_list(values) ->
        {var, values}

      {var, :in, range} when is_struct(range, Range) ->
        {var, Enum.to_list(range)}

      _ ->
        raise ArgumentError, "Invalid generator: #{inspect(generators)}"
    end)
  end

  defp evaluate_expression(expr) do
    case expr do
      # Range
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      # List
      list when is_list(list) ->
        list

      # Literal
      literal when is_number(literal) or is_atom(literal) ->
        literal

      # Binary operations
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_val = evaluate_expression(left)
        right_val = evaluate_expression(right)

        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end

      # Function calls
      {func, _, [arg]} when is_atom(func) ->
        arg_val = evaluate_expression(arg)

        case func do
          # Simplified - would need more sophisticated function handling
          :rem -> rem(arg_val, 2)
        end

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  defp generate_combinations_from_parsed_generators(parsed_generators) do
    # Extract variable names and value lists
    {_var_names, value_lists} = Enum.unzip(parsed_generators)

    # Generate cartesian product
    generate_cartesian_product(value_lists)
  end

  defp generate_cartesian_product([]), do: [[]]

  defp generate_cartesian_product([values | rest]) do
    for value <- values,
        combination <- generate_cartesian_product(rest) do
      [value | combination]
    end
  end

  defp create_bindings(parsed_generators, index_vals) do
    # Create a map of variable names to their values
    parsed_generators
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {{var, _values}, idx}, acc ->
      Map.put(acc, var, Enum.at(index_vals, idx))
    end)
  end

  defp create_pattern_from_bindings(pattern, bindings) do
    case pattern do
      {left, right} ->
        {substitute_in_pattern(left, bindings), substitute_in_pattern(right, bindings)}

      {left, middle, right} ->
        {substitute_in_pattern(left, bindings), substitute_in_pattern(middle, bindings),
         substitute_in_pattern(right, bindings)}

      _ ->
        substitute_in_pattern(pattern, bindings)
    end
  end

  defp substitute_in_pattern(pattern, bindings) do
    case pattern do
      :_ -> :_
      var when is_atom(var) -> Map.get(bindings, var, var)
      literal -> literal
    end
  end

  defp matches_pattern(key, pattern) do
    key_list = Tuple.to_list(key)

    pattern_list =
      case pattern do
        {left, right} -> [left, right]
        {left, middle, right} -> [left, middle, right]
        single -> [single]
      end

    if length(key_list) == length(pattern_list) do
      Enum.zip(key_list, pattern_list)
      |> Enum.all?(fn {key_val, pattern_val} ->
        pattern_val == :_ or pattern_val == key_val
      end)
    else
      false
    end
  end

  defp create_var_name(var_name, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{var_name}_#{index_str}"
  end

  defp create_constraint_name(description, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{description}_#{index_str}"
  end
end
