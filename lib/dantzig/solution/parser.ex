defmodule Dantzig.Solution.Parser do
  import NimbleParsec

  @example_solution """
  Model status
  Optimal

  # Primal solution values
  Feasible
  Objective 0.499999975
  # Columns 1
  x00000_x 0.499999975
  # Rows 1
  c00000 0.499999975

  # Dual solution values
  Feasible
  # Columns 1
  x00000_x 0
  # Rows 1
  c00000 0

  # Basis
  HiGHS v1
  None
  """

  newline =
    ignore(
      choice([
        string("\r\n"),
        string("\n")
      ])
    )

  skipping_newlines = fn combinators ->
    Enum.reduce(combinators, empty(), fn comb, acc ->
      acc
      |> ignore(repeat(newline))
      |> concat(comb)
    end)
  end

  defp build_float(parts) do
    {f, ""} = Float.parse(to_string(parts))
    f
  end

  defp build_integer(parts) do
    {i, ""} = Integer.parse(to_string(parts))
    i
  end

  line = utf8_string([not: ?\n, not: ?\r], min: 0)

  model_status =
    ignore(string("Model status") |> concat(newline))
    |> concat(line)
    |> unwrap_and_tag(:model_status)

  float =
    optional(string("-"))
    |> ascii_string([?0..?9], min: 1)
    |> string(".")
    |> ascii_string([?0..?9], min: 1)
    |> reduce(:build_float)

  integer =
    optional(string("-"))
    |> ascii_string([?0..?9], min: 1)
    |> reduce(:build_integer)

  number = choice([float, integer])

  feasibility =
    line |> unwrap_and_tag(:feasibility)

  objective =
    # Assume that the objective is separated from the value
    # by only a single space
    ignore(string("Objective "))
    |> concat(number)
    |> unwrap_and_tag(:objective)

  variable = ascii_string([not: ?\s, not: ?\n, not: ?\r], min: 1)

  defp build_variable([name, value]) do
    {name, value}
  end

  defp build_variable_map(pairs) do
    Enum.into(pairs, %{})
  end

  columns =
    skipping_newlines.([
      ignore(string("# Columns ") |> concat(integer) |> concat(newline)),
      repeat(
        variable
        |> ignore(string(" "))
        |> concat(number)
        |> concat(newline)
        |> reduce(:build_variable)
      )
    ])
    |> reduce(:build_variable_map)
    |> unwrap_and_tag(:variables)

  rows =
    skipping_newlines.([
      ignore(string("# Rows ") |> concat(integer) |> concat(newline)),
      repeat(
        variable
        |> ignore(string(" "))
        |> concat(number)
        |> concat(newline)
        |> reduce(:build_variable)
      )
    ])
    |> reduce(:build_variable_map)
    |> unwrap_and_tag(:constraints)

  primal_solution_values =
    skipping_newlines.([
      ignore(string("# Primal solution values") |> concat(newline)),
      feasibility,
      objective,
      columns,
      rows
    ])

  solution_file =
    skipping_newlines.([
      model_status,
      primal_solution_values
    ])

  defparsec :solution_file, solution_file

  def parse!(text) do
    {:ok, parsed, _rest, _context, _, _} = solution_file(text)
    parsed
  end

  def example() do
    parse!(@example_solution)
  end
end
