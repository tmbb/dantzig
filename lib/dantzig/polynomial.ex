defmodule Dantzig.Polynomial do
  defstruct simplified: %{},
            operations: nil,
            substitutions: %{}

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(p, _opts) do
      concat([
        "#Polynomial<",
        Dantzig.Polynomial.to_iodata(p) |> to_string(),
        ">"
      ])
    end
  end

  # def fetch_single_variable_name(%__MODULE__{} = p) do
  #   case p do
  #     %{simplified: %{[name] => coeff} = simplified} when
  #         coeff in [1, 1.0] and map_size(simplified) == 1 ->
  #       {:ok, name}

  #     _other ->
  #       :error
  #   end
  # end

  @doc false
  def to_lp_iodata_objective(p) do
    # Raise an error if the polynomial is cubic or higher
    unless degree(p) in [0, 1, 2] do
      raise RuntimeError, """
        Polynomials of degree < 2 are not supported by the LP solver.
            Please try to convert your constraints and objective function \
        into polynomials of degree 0, 1 or 2.
        """
    end

    # The degree of all terms will be at maximum two from now on
    by_degree = Enum.group_by(p.simplified, fn {vars, _coeff} -> length(vars) end)
    true = Enum.all?(Map.keys(by_degree), fn degree -> degree < 3 end)

    terms_of_degree_0 = Map.get(by_degree, 0, [])
    terms_of_degree_1 = Map.get(by_degree, 1, [])
    terms_of_degree_2 = Map.get(by_degree, 2, [])

    doubled_terms_of_degree_2 = for {vars, coeff} <- terms_of_degree_2 do
      {vars, 2 * coeff}
    end

    linear_terms = terms_of_degree_0 ++ terms_of_degree_1
    linear_terms_iodata = terms_to_iodata(linear_terms)

    terms_of_degree_2_iodata =
      case terms_of_degree_2 do
        [] ->
          ""

        _other ->[
            " + [ ",
            terms_to_iodata(doubled_terms_of_degree_2),
            " ] / 2"
          ]
      end

    [linear_terms_iodata, terms_of_degree_2_iodata]
  end

  def to_lp_constraint(p) do
    # Raise an error if the polynomial is cubic or higher
    unless degree(p) in [0, 1, 2] do
      raise RuntimeError, """
        Polynomials of degree < 2 are not supported by the LP solver.
            Please try to convert your constraints and objective function \
        into polynomials of degree 0, 1 or 2.
        """
    end

    # The degree of all terms will be at maximum two from now on
    by_degree = Enum.group_by(p.simplified, fn {vars, _coeff} -> length(vars) end)
    true = Enum.all?(Map.keys(by_degree), fn degree -> degree < 3 end)

    terms_of_degree_0 = Map.get(by_degree, 0, [])
    terms_of_degree_1 = Map.get(by_degree, 1, [])
    terms_of_degree_2 = Map.get(by_degree, 2, [])

    # doubled_terms_of_degree_2 = for {vars, coeff} <- terms_of_degree_2 do
    #   {vars, 2 * coeff}
    # end

    linear_terms = terms_of_degree_0 ++ terms_of_degree_1
    linear_terms_iodata = terms_to_iodata(linear_terms)

    terms_of_degree_2_iodata =
      case terms_of_degree_2 do
        [] ->
          ""

        _other ->[
            " + [ ",
            terms_to_iodata(terms_of_degree_2),
            " ]"
          ]
      end

    [linear_terms_iodata, terms_of_degree_2_iodata]
  end

  def to_iodata(p) do
    terms_to_iodata(p.simplified)
  end

  defp terms_to_iodata([]), do: "0"

  defp terms_to_iodata(map) when map == %{}, do: "0"

  defp terms_to_iodata(terms) do
    # Ensure deterministic order if terms are in a dictionary
    terms = Enum.sort(terms)

    signed_terms =
      for {vars, coeff} <- terms do
        case coeff > 0 do
          true ->
            {"+ ", to_string(coeff), vars_to_iodata(vars)}

          false ->
            {"- ", to_string(abs(coeff)), vars_to_iodata(vars)}
        end
      end

    case signed_terms do
      [{"+ ", coeff1, vars1}] ->
        [coeff1, " ", vars1]

      [{"- ", coeff1, vars1}] ->
        ["- ", coeff1, " ", vars1]

      [{"+ ", coeff1, vars1} | rest] ->
        [coeff1, " ", vars1, " " | rest_of_coeffs_to_iodata(rest)]

      [{"- ", coeff1, vars1} | rest] ->
        ["- ", coeff1, " ", vars1, " " | rest_of_coeffs_to_iodata(rest)]
    end
  end


  defp vars_to_iodata([]), do: ""

  defp vars_to_iodata(vars) do
    counts =
      vars
      |> Enum.frequencies()
      |> Enum.sort()

    grouped_vars =
      Enum.map(counts, fn {var, count} ->
        case count == 1 do
          true ->
            var

          false ->
            "#{var}^#{count}"
        end
      end)

    grouped_vars
    |> Enum.map(&to_string/1)
    |> Enum.intersperse(" * ")
  end

  def serialize(p) do
    p
    |> to_iodata()
    |> IO.iodata_to_binary()
  end

  defp rest_of_coeffs_to_iodata(rest) do
    parts =
      Enum.map(rest, fn {sign, coeff, vars} ->
        [sign, coeff, " ", vars]
      end)

    Enum.intersperse(parts, " ")
  end

  def constant?(p) do
    degree(p) == 0
  end

  def split_constant(p) do
    case Map.fetch(p.simplified, []) do
      {:ok, value} ->
        {subtract(p, const(value)), value}

      :error ->
        {p, 0}
    end
  end

  def equal?(p1, p2) do
    p1.simplified == p2.simplified
  end

  def has_constant_term?(p) do
    case Map.fetch(p, []) do
      {:ok, _coeff} -> true
      :error -> false
    end
  end

  def number_of_terms(p) do
    map_size(p.simplified)
  end

  def separate_constant(p) do
    case p.simplified do
      # The polynomial contains a constant term
      %{[] => constant_value} ->
        # Subtrct the constant so that the subtraction of the constant
        # is added to the operastions
        new_p = subtract(p, constant_value)
        new_simplified = Map.delete(p.simplified, [])

        # Return the pair
        {constant_value, %{new_p | simplified: new_simplified}}

      # The polynomial doesn't contain a constant term
      _ ->
        {0, p}
    end
  end

  def const(value) when is_number(value) do
    %__MODULE__{simplified: %{[] => value}, operations: {:const, value}}
  end

  def variable(name) when not is_number(name) do
    # NOTE: the variable name can't be a number, otherwise it would be too confusing!
    %__MODULE__{simplified: %{[name] => 1}, operations: {:var, name}}
  end

  def term(variables, coefficient) do
    Enum.reduce(variables, const(coefficient), fn name, p ->
      multiply(p, variable(name))
    end)
  end

  def substitute(p, substitutions) when is_map(substitutions) do
    terms =
      for {vars, coeff} <- p.simplified do
        substituted_vars = Enum.map(vars, fn v -> Map.get(substitutions, v, v) end)
        {constants, variables} = Enum.split_with(substituted_vars, &is_number/1)
        new_coeff = coeff * Enum.product(constants)

        {variables, new_coeff}
      end

    simplified = merge_and_simplify_terms(terms)
    operations = {:substitute, p.operations, substitutions}
    substitutions = Map.merge(p.substitutions, substitutions)

    %__MODULE__{simplified: simplified, operations: operations, substitutions: substitutions}
  end

  def evaluate(p, substitutions) when is_map(substitutions) do
    case substitute(p, substitutions) do
      %__MODULE__{simplified: %{[] => constant} = simplified} when map_size(simplified) == 1 ->
        {:ok, constant}

      result ->
        free_variables = variables(result)
        {:error, {:free_variables, free_variables}}
    end
  end

  def evaluate!(p, substitutions) when is_map(substitutions) do
    {:ok, constant} = evaluate(p, substitutions)
    constant
  end

  def degree(%{simplified: simplified} = _p) when simplified == %{} do
    0
  end

  def degree(p) do
    # Count all variables
    p.simplified
    |> Enum.map(fn {vars, _coeff} -> Enum.count(vars) end)
    |> Enum.max()
  end

  def degree_on(p, var) do
    # Count only the times the variable is multiplied
    p.simplified
    |> Enum.map(fn {vars, _coeff} -> Enum.count(vars, fn v -> v == var end) end)
    |> Enum.max()
  end

  def to_polynomial(p) when is_number(p), do: const(p)
  def to_polynomial(p) when is_struct(p, __MODULE__), do: p

  def variables(p) do
    p.simplified
    |> Enum.flat_map(fn {vars, _coeff} -> vars end)
    |> Enum.uniq()
    |> Enum.sort()
  end

  def power(_p, 0), do: const(1)
  def power(p, exponent) when exponent > 0, do: multiply(p, power(p, exponent - 1))

  def add(p1, p2) do
    p1 = to_polynomial(p1)
    p2 = to_polynomial(p2)

    terms =
      Map.merge(p1.simplified, p2.simplified, fn _var, coeff1, coeff2 ->
        coeff1 + coeff2
      end)

    simplified = cancel_terms(terms)

    operations = {:add, p1.operations, p2.operations}

    %__MODULE__{simplified: simplified, operations: operations}
  end

  def sum(polynomials) do
    Enum.reduce(polynomials, const(0), fn p, current_sum ->
      add(p, current_sum)
    end)
  end

  def subtract(p1, p2) do
    p1 = to_polynomial(p1)
    p2 = multiply(to_polynomial(p2), -1)

    terms =
      Map.merge(p1.simplified, p2.simplified, fn _var, coeff1, coeff2 ->
        coeff1 + coeff2
      end)

    simplified = cancel_terms(terms)
    operations = {:subtract, p1.operations, p2.operations}

    %__MODULE__{simplified: simplified, operations: operations}
  end

  def scale(%__MODULE__{} = _p, m) when m in [0, 0.0] do
    const(m)
  end

  def scale(%__MODULE__{} = p, m) when is_number(m) do
    terms =
      for {vars, coeff} <- p.simplified, into: %{} do
        {vars, m * coeff}
      end

    simplified_terms = merge_and_simplify_terms(terms)
    operations = {:scale, p.operations}

    %{p | simplified: simplified_terms, operations: operations}
  end

  def multiply(p1, p2) do
    p1 = to_polynomial(p1)
    p2 = to_polynomial(p2)

    terms =
      for {vars1, coeff1} <- p1.simplified, {vars2, coeff2} <- p2.simplified do
        vars = Enum.sort(vars1 ++ vars2)
        coeff = coeff1 * coeff2

        {vars, coeff}
      end

    simplified = merge_and_simplify_terms(terms)
    operations = {:multiply, p1.operations, p2.operations}

    %__MODULE__{simplified: simplified, operations: operations}
  end

  defp cancel_terms(terms) do
    terms
    |> Enum.reject(fn {_vars, coeff} -> coeff == 0 or coeff == 0.0 end)
    |> Enum.into(%{})
  end

  def merge_and_simplify_terms_in_polynomial(p) do
    %{p | simplified: merge_and_simplify_terms(p.simplified)}
  end

  defp merge_and_simplify_terms(terms) do
    terms
    |> Enum.group_by(fn {vars, _coeff} -> vars end, fn {_vars, coeff} -> coeff end)
    |> Enum.map(fn {vars, coeffs} -> {vars, Enum.sum(coeffs)} end)
    |> cancel_terms()
  end
end
