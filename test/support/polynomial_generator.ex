defmodule Dantzig.Test.PolynomialGenerators do
  alias Dantzig.Polynomial

  def polynomial(opts \\ []) do
    opts = Keyword.put(opts, :nr_of_polynomials, 1)
    StreamData.map(polynomials_and_substitutions(opts), fn {[p], _substitutinos} -> p end)
  end

  def polynomials(opts \\ []) do
    StreamData.map(polynomials_and_substitutions(opts), fn {ps, _substitutinos} -> ps end)
  end

  def variable_name() do
    first_generator = StreamData.string([?a..?z, ?A..?Z], length: 1)

    rest_generator =
      StreamData.string([?a..?z, ?A..?Z, ?0..?9, ?_], min_length: 0, max_length: 32)

    StreamData.map(
      StreamData.tuple({first_generator, rest_generator}),
      fn {first, rest} -> first <> rest end
    )
  end

  def variable() do
    StreamData.map(variable_name(), fn name -> Polynomial.variable(name) end)
  end

  def polynomials_and_substitutions(opts \\ []) do
    coefficient_generator = Keyword.get(opts, :coefficient_generator, &StreamData.integer/0)
    variable_generator = Keyword.get(opts, :variable_generator, &StreamData.integer/0)
    nr_of_polynomials = Keyword.fetch!(opts, :nr_of_polynomials)

    min_nr_of_variables = Keyword.get(opts, :min_nr_of_variables, 1)
    max_nr_of_variables = Keyword.get(opts, :max_nr_of_variables, 16)

    min_degree = Keyword.get(opts, :min_degree, 0)
    max_degree = Keyword.get(opts, :max_degree, 16)

    variable_names_generator =
      StreamData.list_of(
        variable_name(),
        min_length: min_nr_of_variables,
        max_length: max_nr_of_variables
      )

    StreamData.bind(variable_names_generator, fn variable_names ->
      variables = Enum.map(variable_names, fn name -> Polynomial.variable(name) end)
      # Turn the constant variables into generators
      variable_data = Enum.map(variables, &StreamData.constant/1)
      variable_value_generators = List.duplicate(variable_generator.(), length(variables))
      variable_fixed_map = Enum.zip(variable_names, variable_value_generators) |> Enum.into(%{})

      polynomial =
        StreamData.map(
          StreamData.list_of(
            # Build a single term from the variables above
            StreamData.tuple({
              StreamData.list_of(
                StreamData.one_of(variable_data),
                min_length: min_degree,
                max_length: max_degree
              ),
              coefficient_generator.()
            })
          ),
          fn terms ->
            # Build polynomial from terms
            polynomial =
              Enum.reduce(terms, Polynomial.const(0), fn {vars, coeff}, polynomial ->
                Polynomial.add(polynomial, Polynomial.term(vars, coeff))
              end)

            Polynomial.merge_and_simplify_terms_in_polynomial(polynomial)
          end
        )

      StreamData.tuple({
        StreamData.list_of(
          polynomial,
          length: nr_of_polynomials
        ),
        StreamData.fixed_map(variable_fixed_map)
      })
    end)
  end
end
