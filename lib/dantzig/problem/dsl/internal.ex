defmodule Dantzig.Problem.DSL.Internal do
  @moduledoc false

  require Dantzig.Problem, as: Problem
  require Dantzig.Constraint, as: Constraint
  require Dantzig.Polynomial, as: Polynomial

  # Public implementation entrypoints used by macros in Dantzig.Problem.DSL
  def add_variables(problem, generators, var_name, var_type, _description) do
    parsed_generators = parse_generators(generators)
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    {final_problem, var_map} =
      Enum.reduce(combinations, {problem, %{}}, fn index_vals, {current_problem, acc} ->
        var_name_with_indices = create_var_name(var_name, index_vals)

        {new_problem, monomial} =
          Problem.new_variable(current_problem, var_name_with_indices, type: var_type)

        key = List.to_tuple(index_vals)
        new_acc = Map.put(acc, key, monomial)
        {new_problem, new_acc}
      end)

    Problem.put_variables_nd(final_problem, var_name, var_map)
  end

  def add_constraints(problem, generators, constraint_expr, description) do
    parsed_generators = parse_generators(generators)
    combinations = generate_combinations_from_parsed_generators(parsed_generators)

    Enum.reduce(combinations, problem, fn index_vals, current_problem ->
      bindings = create_bindings(parsed_generators, index_vals)
      constraint = parse_constraint_expression(constraint_expr, bindings, current_problem)

      constraint_name =
        if description, do: create_constraint_name(description, index_vals), else: nil

      constraint = if constraint_name, do: %{constraint | name: constraint_name}, else: constraint
      Problem.add_constraint(current_problem, constraint)
    end)
  end

  def set_objective(problem, objective_expr, opts) do
    direction = Keyword.get(opts, :direction)

    if direction not in [:minimize, :maximize] do
      raise ArgumentError,
            "Objective direction must be :minimize or :maximize, got: #{inspect(direction)}"
    end

    objective = parse_objective_expression(objective_expr, problem)
    %{problem | objective: objective, direction: direction}
  end

  # Parsing helpers (were private in DSL)
  def parse_generators(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) -> {var, Enum.to_list(range)}
      {:<-, _, [var, list]} when is_list(list) -> {var, list}
      {:<-, _, [var, expr]} -> {var, evaluate_expression(expr)}
      _ -> raise ArgumentError, "Invalid generator: #{inspect(generators)}"
    end)
  end

  def evaluate_expression(expr) do
    case expr do
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      {:.., _, [from_ast, to_ast]} ->
        from_val = evaluate_expression(from_ast)
        to_val = evaluate_expression(to_ast)
        Enum.to_list(from_val..to_val)

      list when is_list(list) ->
        list

      literal when is_number(literal) or is_atom(literal) ->
        literal

      # Unary minus
      {:-, _meta, [v]} ->
        -evaluate_expression(v)

      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_val = evaluate_expression(left)
        right_val = evaluate_expression(right)

        case op do
          :+ -> left_val + right_val
          :- -> left_val - right_val
          :* -> left_val * right_val
          :/ -> left_val / right_val
        end

      # Handle bracket access: container[key]
      {{:., _, [Access, :get]}, _, [container_ast, key_ast]} ->
        container = evaluate_expression(container_ast)
        key = evaluate_expression(key_ast)

        cond do
          is_map(container) ->
            case key do
              k when is_binary(k) ->
                Map.get(container, k) || Map.get(container, safe_to_atom(k))

              _ ->
                Map.get(container, key)
            end

          is_list(container) ->
            case container do
              [%{} | _] ->
                Enum.find_value(container, fn
                  %{} = m ->
                    cond do
                      Map.has_key?(m, key) -> Map.get(m, key)
                      Map.has_key?(m, :name) and Map.get(m, :name) == key -> m
                      Map.has_key?(m, "name") and Map.get(m, "name") == key -> m
                      true -> nil
                    end

                  _ ->
                    nil
                end)

              _ ->
                nil
            end

          true ->
            nil
        end

      {:__aliases__, _, _} = quoted ->
        eval_with_env(quoted)

      {name, _, ctx} = var when is_atom(name) and (is_atom(ctx) or is_nil(ctx)) ->
        eval_with_env(var)

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  defp eval_with_env(quoted) do
    case Process.get(:dantzig_eval_env) do
      env when is_list(env) ->
        {value, _} = Code.eval_quoted(quoted, env)
        value

      _ ->
        raise ArgumentError, "Cannot evaluate expression without environment: #{inspect(quoted)}"
    end
  end

  defp safe_to_atom(bin) when is_binary(bin) do
    try do
      String.to_existing_atom(bin)
    rescue
      ArgumentError -> nil
    end
  end

  def generate_combinations_from_parsed_generators(parsed_generators) do
    {_var_names, value_lists} = Enum.unzip(parsed_generators)
    generate_cartesian_product(value_lists)
  end

  defp generate_cartesian_product([]), do: [[]]

  defp generate_cartesian_product([values | rest]) do
    for value <- values,
        combination <- generate_cartesian_product(rest),
        do: [value | combination]
  end

  def create_bindings(parsed_generators, index_vals) do
    parsed_generators
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {{var_ast, _values}, idx}, acc ->
      # Extract the atom from the AST node for consistent binding keys
      var_atom =
        case var_ast do
          {atom, _, _} when is_atom(atom) -> atom
          atom when is_atom(atom) -> atom
          _ -> var_ast
        end

      Map.put(acc, var_atom, Enum.at(index_vals, idx))
    end)
  end

  def parse_constraint_expression(constraint_expr, bindings, problem) do
    case constraint_expr do
      {:==, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :==, right_poly)

      {:<=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :<=, right_poly)

      {:>=, _, [left_expr, right_value]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        right_poly =
          case right_value do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(right_value, bindings, problem)
          end

        Constraint.new_linear(left_poly, :>=, right_poly)

      {:between, _, [left_expr, min_val, max_val]} ->
        left_poly = parse_expression_to_polynomial(left_expr, bindings, problem)

        _min_poly =
          case min_val do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(min_val, bindings, problem)
          end

        max_poly =
          case max_val do
            val when is_number(val) -> Polynomial.const(val)
            _ -> parse_expression_to_polynomial(max_val, bindings, problem)
          end

        Constraint.new_linear(left_poly, :<=, max_poly)

      _ ->
        raise ArgumentError, "Unsupported constraint expression: #{inspect(constraint_expr)}"
    end
  end

  def parse_expression_to_polynomial(expr, bindings, problem) do
    expr = normalize_sum_ast(expr)

    case expr do
      {:sum, [], [sum_expr]} ->
        parse_sum_expression(sum_expr, bindings, problem)

      {:sum, sum_expr} ->
        parse_sum_expression(sum_expr, bindings, problem)

      # Unary minus (must come before binary arithmetic)
      {:-, _meta, [v]} ->
        # Check if this is a variable access pattern (e.g., qty(food))
        case v do
          {var_name, _, indices} when is_atom(var_name) and is_list(indices) ->
            # This is a variable access pattern, parse it directly
            case parse_expression_to_polynomial(v, bindings, problem) do
              %Polynomial{} = p ->
                Polynomial.scale(p, -1)

              other ->
                raise ArgumentError,
                      "Unsupported unary minus on variable access: #{inspect(other)}"
            end

          _ ->
            # Try to evaluate as a number first
            case evaluate_expression_with_bindings(v, bindings) do
              val when is_number(val) ->
                Polynomial.const(-val)

              _ ->
                case parse_expression_to_polynomial(v, bindings, problem) do
                  %Polynomial{} = p -> Polynomial.scale(p, -1)
                  other -> raise ArgumentError, "Unsupported unary minus: #{inspect(other)}"
                end
            end
        end

      # Arithmetic between expressions
      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        left_poly_or_val =
          case parse_expression_to_polynomial(left, bindings, problem) do
            %Polynomial{} = p ->
              p

            _ ->
              case evaluate_expression_with_bindings(left, bindings) do
                v when is_number(v) ->
                  Polynomial.const(v)

                nil ->
                  Polynomial.const(0)

                other ->
                  raise ArgumentError,
                        "Cannot use non-numeric value in arithmetic: #{inspect(other)}"
              end
          end

        right_poly_or_val =
          case parse_expression_to_polynomial(right, bindings, problem) do
            %Polynomial{} = p ->
              p

            _ ->
              case evaluate_expression_with_bindings(right, bindings) do
                v when is_number(v) ->
                  Polynomial.const(v)

                nil ->
                  Polynomial.const(0)

                other ->
                  raise ArgumentError,
                        "Cannot use non-numeric value in arithmetic: #{inspect(other)}"
              end
          end

        case {op, left_poly_or_val, right_poly_or_val} do
          {:+, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, p2)

          {:+, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(v))

          {:+, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), p)

          {:-, %Polynomial{} = p1, %Polynomial{} = p2} ->
            Polynomial.add(p1, Polynomial.scale(p2, -1))

          {:-, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.add(p, Polynomial.const(-v))

          {:-, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.add(Polynomial.const(v), Polynomial.scale(p, -1))

          {:*, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, v, %Polynomial{} = p} when is_number(v) ->
            Polynomial.scale(p, v)

          {:*, %Polynomial{} = p1, %Polynomial{} = p2} ->
            # Handle polynomial * polynomial (e.g., variable * constant polynomial)
            # This should only happen when one is a constant polynomial
            cond do
              Polynomial.constant?(p1) ->
                {_non_constant, constant_val} = Polynomial.split_constant(p1)
                Polynomial.scale(p2, constant_val)

              Polynomial.constant?(p2) ->
                {_non_constant, constant_val} = Polynomial.split_constant(p2)
                Polynomial.scale(p1, constant_val)

              true ->
                raise ArgumentError,
                      "Multiplication of non-constant polynomials is not supported: #{inspect({p1, p2})}"
            end

          {:/, %Polynomial{} = p, v} when is_number(v) ->
            Polynomial.scale(p, 1.0 / v)

          {:/, %Polynomial{} = p1, %Polynomial{} = p2} ->
            # Handle polynomial / polynomial (e.g., variable / constant polynomial)
            # This should only happen when the second is a constant polynomial
            if Polynomial.constant?(p2) do
              {_non_constant, constant_val} = Polynomial.split_constant(p2)
              Polynomial.scale(p1, 1.0 / constant_val)
            else
              raise ArgumentError,
                    "Division of non-constant polynomials is not supported: #{inspect({p1, p2})}"
            end

          _ ->
            raise ArgumentError, "Unsupported arithmetic: #{inspect({op, left, right})}"
        end

      # Simple variable access: {var_name, _, nil} (no indices)
      {var_name, _, nil} when is_atom(var_name) or is_binary(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        # For simple variables, check if they exist in the problem
        var_def = Problem.get_variable(problem, var_name_str)

        if var_def do
          Polynomial.variable(var_name_str)
        else
          raise ArgumentError, "Undefined variable: #{var_name_str}"
        end

      # Generator-based variable access: {var_name, _, indices} with indices
      {var_name, _, indices} when is_list(indices) and is_atom(var_name) ->
        resolved_indices =
          Enum.map(indices, fn
            :_ ->
              :_

            {var_atom, _, _} = var_ast when is_atom(var_atom) ->
              # Find the binding by matching the atom name, ignoring line/column info
              Enum.find_value(bindings, fn {key, value} ->
                case key do
                  {^var_atom, _, _} -> value
                  _ -> nil
                end
              end) || var_ast

            var when is_atom(var) ->
              # Try to find the binding by atom, or by full AST node
              Map.get(
                bindings,
                var,
                Enum.find_value(bindings, fn {key, _value} ->
                  case key do
                    {^var, _, _} -> true
                    _ -> false
                  end
                end) || var
              )

            val ->
              val
          end)

        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        var_map = Problem.get_variables_nd(problem, var_name_str)

        cond do
          is_map(var_map) and Enum.any?(resolved_indices, &(&1 == :_)) ->
            matching_vars =
              Enum.filter(var_map, fn {key, _mono} ->
                key_list = Tuple.to_list(key)

                Enum.zip_with(resolved_indices, key_list, fn p, a ->
                  if p == :_, do: true, else: p == a
                end)
                |> Enum.all?()
              end)

            Enum.reduce(matching_vars, Polynomial.const(0), fn {_k, mono}, acc ->
              Polynomial.add(acc, mono)
            end)

          is_map(var_map) ->
            key = List.to_tuple(resolved_indices)
            Map.get(var_map, key, Polynomial.const(0))

          true ->
            Polynomial.const(0)
        end

      val when is_number(val) ->
        Polynomial.const(val)

      # Resolve bracket access etc. to a numeric constant if possible
      {{:., _, [Access, :get]}, _, _} ->
        value = evaluate_expression_with_bindings(expr, bindings)
        Polynomial.const(value)

      _ ->
        raise ArgumentError, "Unsupported expression: #{inspect(expr)}"
    end
  end

  # Evaluate an arbitrary quoted expression to a literal value, using DSL for-loop bindings first
  defp evaluate_expression_with_bindings(expr, bindings) do
    case expr do
      range when is_struct(range, Range) ->
        Enum.to_list(range)

      {:.., _, [from_ast, to_ast]} ->
        from_val = evaluate_expression_with_bindings(from_ast, bindings)
        to_val = evaluate_expression_with_bindings(to_ast, bindings)
        Enum.to_list(from_val..to_val)

      list when is_list(list) ->
        list

      literal when is_number(literal) or is_atom(literal) ->
        literal

      {op, _, [left, right]} when op in [:+, :-, :*, :/] ->
        l = evaluate_expression_with_bindings(left, bindings)
        r = evaluate_expression_with_bindings(right, bindings)

        case op do
          :+ -> l + r
          :- -> l - r
          :* -> l * r
          :/ -> l / r
        end

      # Access.get handling with recursion
      {{:., _, [Access, :get]}, _, [container_ast, key_ast]} ->
        container = evaluate_expression_with_bindings(container_ast, bindings)
        key = evaluate_expression_with_bindings(key_ast, bindings)

        cond do
          is_map(container) ->
            case key do
              k when is_binary(k) -> Map.get(container, k) || Map.get(container, safe_to_atom(k))
              _ -> Map.get(container, key)
            end

          is_list(container) ->
            case container do
              [%{} | _] ->
                Enum.find_value(container, fn
                  %{} = m ->
                    cond do
                      Map.has_key?(m, key) -> Map.get(m, key)
                      Map.has_key?(m, :name) and Map.get(m, :name) == key -> m
                      Map.has_key?(m, "name") and Map.get(m, "name") == key -> m
                      true -> nil
                    end

                  _ ->
                    nil
                end)

              _ ->
                nil
            end

          true ->
            nil
        end

      # Variables: prefer loop bindings, then env
      {name, _, _ctx} = var when is_atom(name) ->
        case Map.fetch(bindings, name) do
          {:ok, v} -> v
          :error -> eval_with_env(var)
        end

      {:__aliases__, _, _} = quoted ->
        eval_with_env(quoted)

      _ ->
        raise ArgumentError, "Cannot evaluate expression: #{inspect(expr)}"
    end
  end

  def parse_objective_expression(objective_expr, problem) do
    expr = normalize_sum_ast(objective_expr)

    case expr do
      {:sum, expr} -> parse_sum_expression(expr, %{}, problem)
      expr when is_tuple(expr) -> parse_expression_to_polynomial(expr, %{}, problem)
      value when is_number(value) -> Polynomial.const(value)
      _ -> raise ArgumentError, "Unsupported objective expression: #{inspect(expr)}"
    end
  end

  def parse_sum_expression(expr, bindings, problem) do
    expr = normalize_sum_ast(expr)

    case expr do
      # Handle Elixir for-comprehension inside sum/1
      {:for, _, parts} when is_list(parts) ->
        {gens, body} =
          case List.last(parts) do
            [do: do_body] -> {Enum.slice(parts, 0, length(parts) - 1), do_body}
            _ -> {parts, nil}
          end

        if body == nil do
          raise ArgumentError, "for-comprehension in sum/1 must have a do: ... block"
        end

        enumerate_for_bindings(gens, bindings)
        |> Enum.reduce(Polynomial.const(0), fn local_bindings, acc ->
          inner_poly = parse_expression_to_polynomial(body, local_bindings, problem)
          Polynomial.add(acc, inner_poly)
        end)

      {:in, _, [inner_expr, [{:<-, _, [var, list]}]]} ->
        list_values =
          case list do
            {:__aliases__, _, _} -> Module.get_attribute(__MODULE__, list) || []
            list when is_list(list) -> list
            _ -> []
          end

        Enum.reduce(list_values, Polynomial.const(0), fn list_value, acc ->
          new_bindings = Map.put(bindings, var, list_value)
          inner_poly = parse_expression_to_polynomial(inner_expr, new_bindings, problem)
          Polynomial.add(acc, inner_poly)
        end)

      {var_name, _, indices} when is_list(indices) and is_atom(var_name) ->
        var_name_str =
          case var_name do
            str when is_binary(str) -> str
            atom when is_atom(atom) -> to_string(atom)
            _ -> raise ArgumentError, "Invalid variable name: #{inspect(var_name)}"
          end

        var_map = Problem.get_variables_nd(problem, var_name_str)

        if var_map do
          resolved_indices =
            Enum.map(indices, fn
              :_ ->
                :_

              {var_atom, _, _} when is_atom(var_atom) ->
                Map.get(bindings, var_atom, {var_atom, [], nil})

              var when is_atom(var) ->
                Map.get(bindings, var, var)

              val ->
                val
            end)

          matching =
            Enum.filter(var_map, fn {key, _m} ->
              key_list = Tuple.to_list(key)

              Enum.zip_with(resolved_indices, key_list, fn p, a ->
                if p == :_, do: true, else: p == a
              end)
              |> Enum.all?()
            end)

          Enum.reduce(matching, Polynomial.const(0), fn {_k, mono}, acc ->
            Polynomial.add(acc, mono)
          end)
        else
          Polynomial.const(0)
        end

      _ ->
        raise ArgumentError, "Unsupported sum expression: #{inspect(expr)}"
    end
  end

  # Expand a list of for-comprehension generators (and ignore filters for now)
  defp enumerate_for_bindings([], bindings), do: [bindings]

  defp enumerate_for_bindings([{:<-, _, [var, domain_ast]} | rest], bindings) do
    domain_values = evaluate_expression(domain_ast)

    Enum.flat_map(domain_values, fn v ->
      enumerate_for_bindings(rest, Map.put(bindings, var, v))
    end)
  end

  # Skip unsupported items (e.g., filters) for now
  defp enumerate_for_bindings([_other | rest], bindings) do
    enumerate_for_bindings(rest, bindings)
  end

  def normalize_sum_ast(expr) do
    case expr do
      {{:., _, [Dantzig.Problem.DSL, :sum]}, _, [inner]} -> {:sum, [], [normalize_sum_ast(inner)]}
      {:sum, _, _} = s -> s
      {op, meta, args} when is_list(args) -> {op, meta, Enum.map(args, &normalize_sum_ast/1)}
      other -> other
    end
  end

  def create_var_name(var_name, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{var_name}_#{index_str}"
  end

  def create_constraint_name(description, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{description}_#{index_str}"
  end
end
