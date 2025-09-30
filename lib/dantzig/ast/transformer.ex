defmodule Dantzig.AST.Transformer do
  @moduledoc """
  Transformer for converting Dantzig AST expressions into linear constraints.

  This is the core module that handles the linearization of non-linear functions
  like abs(), max(), min(), etc. by creating auxiliary variables and constraints.

  Supports generator-based sum expressions: sum(expr for i <- list, j <- list)
  """

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial
  alias Dantzig.AST
  # alias Dantzig.AST.Analyzer

  @big_m 1000

  @doc """
  Transform an expression into a polynomial, creating any necessary auxiliary variables and constraints
  """
  def transform_expression(ast, problem, bindings) do
    case ast do
      %AST.Abs{expr: inner_expr} ->
        transform_abs(inner_expr, problem, bindings)

      %AST.Max{args: args} ->
        transform_max_variadic(args, problem, bindings)

      %AST.Min{args: args} ->
        transform_min_variadic(args, problem, bindings)

      %AST.Sum{variable: var} ->
        transform_sum(var, problem, bindings)

      %AST.GeneratorSum{expression: expr, generators: generators} ->
        transform_generator_sum(expr, generators, problem, bindings)

      %AST.BinaryOp{left: left, operator: op, right: right} ->
        transform_binary_op(left, op, right, problem, bindings)

      %AST.Variable{name: name, indices: indices} ->
        transform_variable(name, indices, problem, bindings)

      %AST.And{args: args} ->
        transform_and_variadic(args, problem, bindings)

      %AST.Or{args: args} ->
        transform_or_variadic(args, problem, bindings)

      %AST.IfThenElse{condition: condition, then_expr: then_expr, else_expr: else_expr} ->
        transform_if_then_else(condition, then_expr, else_expr, problem, bindings)

      %AST.PiecewiseLinear{
        expr: expr,
        breakpoints: breakpoints,
        slopes: slopes,
        intercepts: intercepts
      } ->
        transform_piecewise_linear(expr, breakpoints, slopes, intercepts, problem, bindings)

      literal when is_number(literal) ->
        {problem, Polynomial.const(literal)}

      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(ast)}"
    end
  end

  @doc """
  Transform absolute value: abs(x) = z where z >= x, z >= -x, z >= 0
  """
  def transform_abs(expr, problem, bindings) do
    # 1. Evaluate the inner expression
    {problem, inner_polynomial} = transform_expression(expr, problem, bindings)

    # 2. Create a new variable for the absolute value
    abs_var_name = generate_abs_var_name(expr, bindings)
    {problem, abs_monomial} = Problem.new_variable(problem, abs_var_name, type: :continuous)

    # 3. Create the three constraints: abs_x >= x, abs_x >= -x, abs_x >= 0
    problem =
      problem
      |> add_constraint(abs_monomial, :>=, inner_polynomial, "abs_ge_x")
      |> add_constraint(
        abs_monomial,
        :>=,
        Polynomial.multiply(inner_polynomial, -1),
        "abs_ge_neg_x"
      )
      |> add_constraint(abs_monomial, :>=, Polynomial.const(@big_m), "abs_ge_zero")

    {problem, abs_monomial}
  end

  @doc """
  Transform maximum: max(x, y) = z where z >= x, z >= y
  """
  def transform_max(left_expr, right_expr, problem, bindings) do
    # 1. Evaluate both expressions
    {problem, left_poly} = transform_expression(left_expr, problem, bindings)
    {problem, right_poly} = transform_expression(right_expr, problem, bindings)

    # 2. Create new variable for maximum
    max_var_name = generate_max_var_name(left_expr, right_expr, bindings)
    {problem, max_monomial} = Problem.new_variable(problem, max_var_name, type: :continuous)

    # 3. Create constraints: z >= x, z >= y
    problem =
      problem
      |> add_constraint(max_monomial, :>=, left_poly, "max_ge_left")
      |> add_constraint(max_monomial, :>=, right_poly, "max_ge_right")

    {problem, max_monomial}
  end

  @doc """
  Transform variadic maximum: max(x, y, z, ...) = w where w >= x, w >= y, w >= z, ...
  Also handles pattern-based: max(x[_]) = w where w >= x[i] for all i
  """
  def transform_max_variadic(args, problem, bindings) do
    # Check if this is a pattern-based operation like max(x[_])
    case args do
      [%AST.Sum{variable: %AST.Variable{name: var_name, pattern: pattern}}] ->
        transform_max_pattern(var_name, pattern, problem, bindings)

      _ ->
        # Regular variadic operation
        # 1. Evaluate all expressions
        {problem, arg_polynomials} =
          Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
            {new_problem, poly} = transform_expression(arg, current_problem, bindings)
            {new_problem, [poly | acc]}
          end)

        arg_polynomials = Enum.reverse(arg_polynomials)

        # 2. Create new variable for maximum
        max_var_name = generate_max_variadic_var_name(args, bindings)
        {problem, max_monomial} = Problem.new_variable(problem, max_var_name, type: :continuous)

        # 3. Create constraints: w >= x, w >= y, w >= z, ...
        problem =
          Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
            add_constraint(current_problem, max_monomial, :>=, arg_poly, "max_ge_arg")
          end)

        {problem, max_monomial}
    end
  end

  @doc """
  Transform minimum: min(x, y) = z where z <= x, z <= y
  """
  def transform_min(left_expr, right_expr, problem, bindings) do
    # 1. Evaluate both expressions
    {problem, left_poly} = transform_expression(left_expr, problem, bindings)
    {problem, right_poly} = transform_expression(right_expr, problem, bindings)

    # 2. Create new variable for minimum
    min_var_name = generate_min_var_name(left_expr, right_expr, bindings)
    {problem, min_monomial} = Problem.new_variable(problem, min_var_name, type: :continuous)

    # 3. Create constraints: z <= x, z <= y
    problem =
      problem
      |> add_constraint(min_monomial, :<=, left_poly, "min_le_left")
      |> add_constraint(min_monomial, :<=, right_poly, "min_le_right")

    {problem, min_monomial}
  end

  @doc """
  Transform variadic minimum: min(x, y, z, ...) = w where w <= x, w <= y, w <= z, ...
  Also handles pattern-based: min(x[_]) = w where w <= x[i] for all i
  """
  def transform_min_variadic(args, problem, bindings) do
    # Check if this is a pattern-based operation like min(x[_])
    case args do
      [%AST.Sum{variable: %AST.Variable{name: var_name, pattern: pattern}}] ->
        transform_min_pattern(var_name, pattern, problem, bindings)

      _ ->
        # Regular variadic operation
        # 1. Evaluate all expressions
        {problem, arg_polynomials} =
          Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
            {new_problem, poly} = transform_expression(arg, current_problem, bindings)
            {new_problem, [poly | acc]}
          end)

        arg_polynomials = Enum.reverse(arg_polynomials)

        # 2. Create new variable for minimum
        min_var_name = generate_min_variadic_var_name(args, bindings)
        {problem, min_monomial} = Problem.new_variable(problem, min_var_name, type: :continuous)

        # 3. Create constraints: w <= x, w <= y, w <= z, ...
        problem =
          Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
            add_constraint(current_problem, min_monomial, :<=, arg_poly, "min_le_arg")
          end)

        {problem, min_monomial}
    end
  end

  @doc """
  Transform pattern-based maximum: max(x[_]) = w where w >= x[i] for all i
  """
  def transform_max_pattern(var_name, pattern, problem, bindings) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, var_name)

    if var_map do
      # Create pattern from bindings
      resolved_pattern = create_pattern(pattern, bindings)

      # Get all matching variables
      matching_vars =
        var_map
        |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, resolved_pattern) end)

      if Enum.empty?(matching_vars) do
        raise ArgumentError,
              "No variables found matching pattern #{var_name}#{inspect(resolved_pattern)}"
      end

      # Create new variable for maximum
      max_var_name = generate_max_pattern_var_name(var_name, pattern, bindings)
      {problem, max_monomial} = Problem.new_variable(problem, max_var_name, type: :continuous)

      # Create constraints: w >= x[i] for all matching variables
      problem =
        Enum.reduce(matching_vars, problem, fn {_key, monomial}, current_problem ->
          add_constraint(current_problem, max_monomial, :>=, monomial, "max_pattern_ge")
        end)

      {problem, max_monomial}
    else
      raise ArgumentError, "Variable map not found for #{var_name}"
    end
  end

  @doc """
  Transform pattern-based minimum: min(x[_]) = w where w <= x[i] for all i
  """
  def transform_min_pattern(var_name, pattern, problem, bindings) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, var_name)

    if var_map do
      # Create pattern from bindings
      resolved_pattern = create_pattern(pattern, bindings)

      # Get all matching variables
      matching_vars =
        var_map
        |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, resolved_pattern) end)

      if Enum.empty?(matching_vars) do
        raise ArgumentError,
              "No variables found matching pattern #{var_name}#{inspect(resolved_pattern)}"
      end

      # Create new variable for minimum
      min_var_name = generate_min_pattern_var_name(var_name, pattern, bindings)
      {problem, min_monomial} = Problem.new_variable(problem, min_var_name, type: :continuous)

      # Create constraints: w <= x[i] for all matching variables
      problem =
        Enum.reduce(matching_vars, problem, fn {_key, monomial}, current_problem ->
          add_constraint(current_problem, min_monomial, :<=, monomial, "min_pattern_le")
        end)

      {problem, min_monomial}
    else
      raise ArgumentError, "Variable map not found for #{var_name}"
    end
  end

  @doc """
  Transform sum operation: sum(x[i, _])
  """
  def transform_sum(var, problem, bindings) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, var.name)

    if var_map do
      # Create pattern from bindings
      pattern = create_pattern(var.indices, bindings)

      # Sum all matching variables
      sum_poly =
        var_map
        |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, pattern) end)
        |> Enum.reduce(Polynomial.const(0), fn {_key, monomial}, acc ->
          Polynomial.add(acc, monomial)
        end)

      {problem, sum_poly}
    else
      raise ArgumentError, "Variable map not found for: #{var.name}"
    end
  end

  @doc """
  Transform generator-based sum operation: sum(expr for i <- list, j <- list)
  """
  def transform_generator_sum(expr, generators, problem, bindings) do
    # Parse generators to get variable names and their ranges
    parsed_generators = parse_generators_for_sum(generators)

    # Generate all combinations of generator values
    combinations = generate_combinations(parsed_generators)

    # For each combination, evaluate the expression and sum the results
    {problem, sum_poly} =
      Enum.reduce(combinations, {problem, Polynomial.const(0)}, fn combination,
                                                                   {current_problem, acc} ->
        # Create bindings for this combination
        combination_bindings =
          create_combination_bindings(parsed_generators, combination, bindings)

        # Evaluate the expression with the new bindings
        {new_problem, expr_poly} =
          transform_expression(expr, current_problem, combination_bindings)

        # Add to the running sum
        new_sum = Polynomial.add(acc, expr_poly)

        {new_problem, new_sum}
      end)

    {problem, sum_poly}
  end

  # Helper functions for generator-based sum

  defp parse_generators_for_sum(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) ->
        {var, Enum.to_list(range)}

      {:<-, _, [var, list]} when is_list(list) ->
        {var, list}

      {:<-, _, [var, expr]} ->
        # Handle computed expressions
        {var, evaluate_expression_for_sum(expr)}

      _ ->
        raise ArgumentError, "Invalid generator: #{inspect(generators)}"
    end)
  end

  defp evaluate_expression_for_sum(expr) do
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
        left_val = evaluate_expression_for_sum(left)
        right_val = evaluate_expression_for_sum(right)

        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  defp generate_combinations(parsed_generators) do
    # Extract value lists from generators
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

  defp create_combination_bindings(parsed_generators, combination, original_bindings) do
    # Create a map of variable names to their values for this combination
    {var_names, _value_lists} = Enum.unzip(parsed_generators)

    new_bindings =
      Enum.zip(var_names, combination)
      |> Enum.reduce(original_bindings, fn {var_name, value}, acc ->
        Map.put(acc, var_name, value)
      end)

    new_bindings
  end

  @doc """
  Transform binary operation: x + y, x * 2, etc.
  """
  def transform_binary_op(left, op, right, problem, bindings) do
    {problem, left_poly} = transform_expression(left, problem, bindings)
    {problem, right_poly} = transform_expression(right, problem, bindings)

    result_poly =
      case op do
        :+ -> Polynomial.add(left_poly, right_poly)
        :- -> Polynomial.subtract(left_poly, right_poly)
        :* -> Polynomial.multiply(left_poly, right_poly)
        :/ -> Polynomial.divide(left_poly, right_poly)
      end

    {problem, result_poly}
  end

  @doc """
  Transform variable reference: x[i, j]
  """
  def transform_variable(name, indices, problem, bindings) do
    # Get the variable map
    var_map = Problem.get_variables_nd(problem, name)

    if var_map do
      # Create key from indices and bindings
      key = create_key_from_indices(indices, bindings)

      # Look up the monomial
      case Map.get(var_map, key) do
        nil ->
          raise ArgumentError, "Variable not found: #{name}#{inspect(key)}"

        monomial ->
          {problem, monomial}
      end
    else
      raise ArgumentError, "Variable map not found for: #{name}"
    end
  end

  @doc """
  Transform AND operation: x AND y (where x, y are binary)
  """
  def transform_and(left, right, problem, bindings) do
    {problem, left_poly} = transform_expression(left, problem, bindings)
    {problem, right_poly} = transform_expression(right, problem, bindings)

    # Create binary variable for AND result
    and_var_name = generate_and_var_name(left, right, bindings)
    {problem, and_monomial} = Problem.new_variable(problem, and_var_name, type: :binary)

    # Constraints: z <= x, z <= y, z >= x + y - 1
    problem =
      problem
      |> add_constraint(and_monomial, :<=, left_poly, "and_le_left")
      |> add_constraint(and_monomial, :<=, right_poly, "and_le_right")
      |> add_constraint(
        and_monomial,
        :>=,
        Polynomial.subtract(Polynomial.add(left_poly, right_poly), Polynomial.const(@big_m)),
        "and_ge_sum_minus_one"
      )

    {problem, and_monomial}
  end

  @doc """
  Transform OR operation: x OR y (where x, y are binary)
  """
  def transform_or(left, right, problem, bindings) do
    {problem, left_poly} = transform_expression(left, problem, bindings)
    {problem, right_poly} = transform_expression(right, problem, bindings)

    # Create binary variable for OR result
    or_var_name = generate_or_var_name(left, right, bindings)
    {problem, or_monomial} = Problem.new_variable(problem, or_var_name, type: :binary)

    # Constraints: z >= x, z >= y, z <= x + y
    problem =
      problem
      |> add_constraint(or_monomial, :>=, left_poly, "or_ge_left")
      |> add_constraint(or_monomial, :>=, right_poly, "or_ge_right")
      |> add_constraint(or_monomial, :<=, Polynomial.add(left_poly, right_poly), "or_le_sum")

    {problem, or_monomial}
  end

  @doc """
  Transform variadic AND operation: x AND y AND z AND ... (where all are binary)
  """
  def transform_and_variadic(args, problem, bindings) do
    # 1. Evaluate all expressions
    {problem, arg_polynomials} =
      Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
        {new_problem, poly} = transform_expression(arg, current_problem, bindings)
        {new_problem, [poly | acc]}
      end)

    arg_polynomials = Enum.reverse(arg_polynomials)

    # 2. Create binary variable for AND result
    and_var_name = generate_and_variadic_var_name(args, bindings)
    {problem, and_monomial} = Problem.new_variable(problem, and_var_name, type: :binary)

    # 3. Create constraints: z <= x, z <= y, z <= z, ... (for all args)
    problem =
      Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
        add_constraint(current_problem, and_monomial, :<=, arg_poly, "and_le_arg")
      end)

    # 4. Create constraint: z >= sum(args) - (n-1) where n is number of args
    n = length(arg_polynomials)

    sum_poly =
      Enum.reduce(arg_polynomials, Polynomial.const(0), fn poly, acc ->
        Polynomial.add(acc, poly)
      end)

    problem =
      add_constraint(
        problem,
        and_monomial,
        :>=,
        Polynomial.subtract(sum_poly, Polynomial.const(n - 1)),
        "and_ge_sum_minus_n_minus_one"
      )

    {problem, and_monomial}
  end

  @doc """
  Transform variadic OR operation: x OR y OR z OR ... (where all are binary)
  """
  def transform_or_variadic(args, problem, bindings) do
    # 1. Evaluate all expressions
    {problem, arg_polynomials} =
      Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
        {new_problem, poly} = transform_expression(arg, current_problem, bindings)
        {new_problem, [poly | acc]}
      end)

    arg_polynomials = Enum.reverse(arg_polynomials)

    # 2. Create binary variable for OR result
    or_var_name = generate_or_variadic_var_name(args, bindings)
    {problem, or_monomial} = Problem.new_variable(problem, or_var_name, type: :binary)

    # 3. Create constraints: z >= x, z >= y, z >= z, ... (for all args)
    problem =
      Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
        add_constraint(current_problem, or_monomial, :>=, arg_poly, "or_ge_arg")
      end)

    # 4. Create constraint: z <= sum(args)
    sum_poly =
      Enum.reduce(arg_polynomials, Polynomial.const(0), fn poly, acc ->
        Polynomial.add(acc, poly)
      end)

    problem = add_constraint(problem, or_monomial, :<=, sum_poly, "or_le_sum")

    {problem, or_monomial}
  end

  @doc """
  Transform IF-THEN-ELSE: IF condition THEN x ELSE y
  """
  def transform_if_then_else(condition, then_expr, else_expr, problem, bindings) do
    {_problem_unused, _condition_poly} = transform_expression(condition, problem, bindings)
    {problem, then_poly} = transform_expression(then_expr, problem, bindings)
    {problem, else_poly} = transform_expression(else_expr, problem, bindings)

    # Create binary variable for condition
    cond_var_name = generate_condition_var_name(condition, bindings)
    {problem, cond_monomial} = Problem.new_variable(problem, cond_var_name, type: :binary)

    # Create variable for result
    result_var_name = generate_if_then_else_var_name(condition, then_expr, else_expr, bindings)
    {problem, result_monomial} = Problem.new_variable(problem, result_var_name, type: :continuous)

    # Constraints using big-M method
    # Large constant
    problem =
      problem
      |> add_constraint(
        result_monomial,
        :<=,
        Polynomial.add(
          then_poly,
          Polynomial.multiply(
            Polynomial.const(@big_m),
            Polynomial.subtract(Polynomial.const(1), cond_monomial)
          )
        ),
        "if_then_upper"
      )
      |> add_constraint(
        result_monomial,
        :>=,
        Polynomial.subtract(
          then_poly,
          Polynomial.multiply(
            Polynomial.const(@big_m),
            Polynomial.subtract(Polynomial.const(1), cond_monomial)
          )
        ),
        "if_then_lower"
      )
      |> add_constraint(
        result_monomial,
        :<=,
        Polynomial.add(else_poly, Polynomial.multiply(Polynomial.const(@big_m), cond_monomial)),
        "if_else_upper"
      )
      |> add_constraint(
        result_monomial,
        :>=,
        Polynomial.subtract(
          else_poly,
          Polynomial.multiply(Polynomial.const(@big_m), cond_monomial)
        ),
        "if_else_lower"
      )

    {problem, result_monomial}
  end

  @doc """
  Transform piecewise linear function
  """
  def transform_piecewise_linear(expr, breakpoints, slopes, intercepts, problem, bindings) do
    {problem, x_poly} = transform_expression(expr, problem, bindings)

    # Create binary variables for each piece
    pieces = length(breakpoints) - 1

    {problem, piece_vars} =
      Enum.reduce(1..pieces, {problem, []}, fn i, {current_problem, acc} ->
        piece_var_name = generate_piece_var_name(expr, i, bindings)

        {new_problem, piece_monomial} =
          Problem.new_variable(current_problem, piece_var_name, type: :binary)

        {new_problem, [piece_monomial | acc]}
      end)

    piece_vars = Enum.reverse(piece_vars)

    # Create continuous variable for the function value
    f_var_name = generate_piecewise_var_name(expr, bindings)
    {problem, f_monomial} = Problem.new_variable(problem, f_var_name, type: :continuous)

    # Constraint: exactly one piece is active
    problem =
      add_constraint(
        problem,
        sum_polynomials(piece_vars),
        :==,
        Polynomial.const(1),
        "exactly_one_piece"
      )

    # Constraints: function value for each piece
    problem =
      Enum.reduce(1..pieces, problem, fn i, current_problem ->
        piece_var = Enum.at(piece_vars, i - 1)
        slope = Enum.at(slopes, i - 1)
        intercept = Enum.at(intercepts, i - 1)

        current_problem
        |> add_constraint(
          f_monomial,
          :>=,
          Polynomial.subtract(
            Polynomial.add(Polynomial.multiply(x_poly, slope), Polynomial.const(intercept)),
            Polynomial.multiply(
              Polynomial.const(@big_m),
              Polynomial.subtract(Polynomial.const(1), piece_var)
            )
          ),
          "piece_lower_#{i}"
        )
        |> add_constraint(
          f_monomial,
          :<=,
          Polynomial.add(
            Polynomial.add(Polynomial.multiply(x_poly, slope), Polynomial.const(intercept)),
            Polynomial.multiply(
              Polynomial.const(@big_m),
              Polynomial.subtract(Polynomial.const(1), piece_var)
            )
          ),
          "piece_upper_#{i}"
        )
      end)

    {problem, f_monomial}
  end

  # Helper functions

  defp add_constraint(problem, left, operator, right, name) do
    constraint = Constraint.new_linear(left, operator, right, name: name)
    Problem.add_constraint(problem, constraint)
  end

  defp create_pattern(indices, bindings) do
    Enum.map(indices, fn
      :_ -> :_
      var when is_atom(var) -> Map.get(bindings, var, var)
      literal -> literal
    end)
  end

  defp matches_pattern(key, pattern) do
    key_list = Tuple.to_list(key)
    pattern_list = pattern

    if length(key_list) == length(pattern_list) do
      Enum.zip(key_list, pattern_list)
      |> Enum.all?(fn {key_val, pattern_val} ->
        pattern_val == :_ or pattern_val == key_val
      end)
    else
      false
    end
  end

  defp create_key_from_indices(indices, bindings) do
    values =
      Enum.map(indices, fn
        var when is_atom(var) -> Map.get(bindings, var, var)
        literal -> literal
      end)

    List.to_tuple(values)
  end

  defp sum_polynomials(polynomials) do
    Enum.reduce(polynomials, Polynomial.const(0), fn poly, acc ->
      Polynomial.add(acc, poly)
    end)
  end

  # Variable name generators
  defp generate_abs_var_name(expr, bindings) do
    "abs_#{generate_expr_hash(expr, bindings)}"
  end

  defp generate_max_var_name(left, right, bindings) do
    "max_#{generate_expr_hash(left, bindings)}_#{generate_expr_hash(right, bindings)}"
  end

  defp generate_min_var_name(left, right, bindings) do
    "min_#{generate_expr_hash(left, bindings)}_#{generate_expr_hash(right, bindings)}"
  end

  defp generate_max_variadic_var_name(args, bindings) do
    arg_hashes = Enum.map(args, &generate_expr_hash(&1, bindings))
    "max_#{Enum.join(arg_hashes, "_")}"
  end

  defp generate_min_variadic_var_name(args, bindings) do
    arg_hashes = Enum.map(args, &generate_expr_hash(&1, bindings))
    "min_#{Enum.join(arg_hashes, "_")}"
  end

  defp generate_max_pattern_var_name(var_name, pattern, bindings) do
    pattern_str =
      Enum.map(pattern, fn
        :_ -> "all"
        var when is_atom(var) -> to_string(Map.get(bindings, var, var))
        literal -> to_string(literal)
      end)
      |> Enum.join("_")

    "max_#{var_name}_#{pattern_str}"
  end

  defp generate_min_pattern_var_name(var_name, pattern, bindings) do
    pattern_str =
      Enum.map(pattern, fn
        :_ -> "all"
        var when is_atom(var) -> to_string(Map.get(bindings, var, var))
        literal -> to_string(literal)
      end)
      |> Enum.join("_")

    "min_#{var_name}_#{pattern_str}"
  end

  defp generate_and_var_name(left, right, bindings) do
    "and_#{generate_expr_hash(left, bindings)}_#{generate_expr_hash(right, bindings)}"
  end

  defp generate_or_var_name(left, right, bindings) do
    "or_#{generate_expr_hash(left, bindings)}_#{generate_expr_hash(right, bindings)}"
  end

  defp generate_and_variadic_var_name(args, bindings) do
    arg_hashes = Enum.map(args, &generate_expr_hash(&1, bindings))
    "and_#{Enum.join(arg_hashes, "_")}"
  end

  defp generate_or_variadic_var_name(args, bindings) do
    arg_hashes = Enum.map(args, &generate_expr_hash(&1, bindings))
    "or_#{Enum.join(arg_hashes, "_")}"
  end

  defp generate_condition_var_name(condition, bindings) do
    "cond_#{generate_expr_hash(condition, bindings)}"
  end

  defp generate_if_then_else_var_name(condition, then_expr, else_expr, bindings) do
    "if_#{generate_expr_hash(condition, bindings)}_#{generate_expr_hash(then_expr, bindings)}_#{generate_expr_hash(else_expr, bindings)}"
  end

  defp generate_piece_var_name(expr, i, bindings) do
    "piece_#{i}_#{generate_expr_hash(expr, bindings)}"
  end

  defp generate_piecewise_var_name(expr, bindings) do
    "piecewise_#{generate_expr_hash(expr, bindings)}"
  end

  defp generate_expr_hash(expr, bindings) do
    # Create a simple hash from the expression and bindings
    content = inspect({expr, bindings})
    :crypto.hash(:md5, content) |> Base.encode16(case: :lower) |> String.slice(0, 8)
  end
end
