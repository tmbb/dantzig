defmodule Dantzig.Problem.DSL.VariableManager do
  @moduledoc """
  Manages variable creation and generator processing for the Dantzig DSL.

  This module handles:
  - Variable creation with pattern-based generators
  - Variable name generation with index combinations
  - Generator parsing and validation
  - Expression evaluation for generator domains
  """

  require Dantzig.Problem, as: Problem

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

  def create_var_name(var_name, index_vals) do
    index_str = index_vals |> Enum.map(&to_string/1) |> Enum.join("_")
    "#{var_name}_#{index_str}"
  end

  # Generator parsing and management
  def parse_generators(generators) do
    Enum.map(generators, fn
      {:<-, _, [var, range]} when is_struct(range, Range) -> {var, Enum.to_list(range)}
      {:<-, _, [var, list]} when is_list(list) -> {var, list}
      {:<-, _, [var, expr]} -> {var, evaluate_expression(expr)}
      _ -> raise ArgumentError, "Invalid generator: #{inspect(generators)}"
    end)
  end

  def generate_combinations_from_parsed_generators(parsed_generators) do
    {_var_names, value_lists} = Enum.unzip(parsed_generators)
    generate_cartesian_product(value_lists)
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

  # Expression evaluation for generators
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

  # Cartesian product generation
  defp generate_cartesian_product([]), do: [[]]

  defp generate_cartesian_product([values | rest]) do
    for value <- values,
        combination <- generate_cartesian_product(rest),
        do: [value | combination]
  end

  # Environment evaluation helper
  defp eval_with_env(quoted) do
    case Process.get(:dantzig_eval_env) do
      env when is_list(env) ->
        {value, _} = Code.eval_quoted(quoted, env)
        value

      _ ->
        raise ArgumentError, "Cannot evaluate expression without environment: #{inspect(quoted)}"
    end
  end

  # Safe atom conversion
  defp safe_to_atom(bin) when is_binary(bin) do
    try do
      String.to_existing_atom(bin)
    rescue
      ArgumentError -> nil
    end
  end
end
