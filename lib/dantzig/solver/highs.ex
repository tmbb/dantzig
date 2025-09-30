defmodule Dantzig.HiGHS do
  @moduledoc false

  require Dantzig.Problem, as: Problem
  alias Dantzig.Config
  alias Dantzig.Constraint
  alias Dantzig.ProblemVariable
  alias Dantzig.Solution
  alias Dantzig.Polynomial

  @max_random_prefix 2 ** 32

  def solve(%Problem{} = problem) do
    iodata = to_lp_iodata(problem)
    iodata_bin = IO.iodata_to_binary(iodata)

    command = Config.default_highs_binary_path()

    with_temporary_files(["model.lp", "solution.lp"], fn [model_path, solution_path] ->
      File.write!(model_path, iodata_bin)

      {output, _error_code} =
        System.cmd(command, [
          model_path,
          "--solution_file",
          solution_path
        ])

      solution_contents =
        case File.read(solution_path) do
          {:ok, contents} ->
            contents

          {:error, :enoent} ->
            raise RuntimeError, """
            Couldn't generate a solution for the given problem.

            Input problem/model file:

            #{indent(iodata_bin, 4)}
            Output from the HiGHS solver:

            #{indent(output, 4)}
            """
        end

      Solution.from_file_contents(solution_contents)
    end)
  end

  defp indent(iodata, indent_level) do
    binary = to_string(iodata)
    spaces = String.duplicate(" ", indent_level)

    binary
    |> String.split("\n")
    |> Enum.map(fn line -> [spaces, line, "\n"] end)
  end

  defp with_temporary_files(basenames, fun) do
    dir = System.tmp_dir!()
    prefix = :rand.uniform(@max_random_prefix) |> Integer.to_string(32)

    paths =
      for basename <- basenames do
        Path.join(dir, "#{prefix}_#{basename}")
      end

    try do
      fun.(paths)
    after
      for path <- paths do
        try do
          File.rm!(path)
        rescue
          _ -> :ok
        end
      end
    end
  end

  defp constraint_to_iodata(constraint = %Constraint{}) do
    # Polynomial.to_lp_constraint returns [linear_terms, quadratic_terms]
    # We need to flatten this into a single iodata
    [linear_terms, quadratic_terms] = Polynomial.to_lp_constraint(constraint.left_hand_side)

    # Flatten the iodata to ensure proper string conversion
    polynomial_iodata = [linear_terms, quadratic_terms]

    base = [
      "  ",
      polynomial_iodata,
      " ",
      operator_to_iodata(constraint.operator),
      " ",
      to_string(constraint.right_hand_side),
      "\n"
    ]

    case constraint.name do
      nil ->
        base

      "" ->
        base

      name ->
        sanitized_name = sanitize_name(name)

        [
          "  ",
          sanitized_name,
          ": ",
          polynomial_iodata,
          " ",
          operator_to_iodata(constraint.operator),
          " ",
          to_string(constraint.right_hand_side),
          "\n"
        ]
    end
  end

  defp operator_to_iodata(operator) do
    case operator do
      :== -> "="
      other -> to_string(other)
    end
  end

  # Sanitize row/constraint names for LP format
  defp sanitize_name(name) when is_binary(name) do
    sanitized =
      name
      |> String.replace(~r/[^A-Za-z0-9_\.]+/, "_")
      |> String.trim("_")

    case sanitized do
      <<first::binary-size(1), _rest::binary>> ->
        if first =~ ~r/[A-Za-z_]/ do
          sanitized
        else
          "c_" <> sanitized
        end

      _ ->
        "c_"
    end
  end

  defp direction_to_iodata(:maximize), do: "Maximize"
  defp direction_to_iodata(:minimize), do: "Minimize"

  def to_lp_iodata(%Problem{} = problem) do
    constraints = Enum.sort(problem.constraints)

    constraints_iodata =
      Enum.map(constraints, fn {_id, constraint} ->
        constraint_to_iodata(constraint)
      end)

    bounds = all_variable_bounds(Map.values(problem.variable_defs))
    general_vars = all_general_variables(Map.values(problem.variable_defs))

    [
      direction_to_iodata(problem.direction),
      "\n  ",
      Polynomial.to_lp_iodata_objective(problem.objective),
      "\n",
      "Subject To\n",
      constraints_iodata,
      "Bounds\n",
      bounds,
      "General\n",
      general_vars,
      "End\n"
    ]
  end

  defp variable_bounds(%ProblemVariable{} = v) do
    # For binary variables, set bounds to 0 <= variable <= 1
    case v.type do
      :binary ->
        "  0 <= #{v.name} <= 1\n"

      _ ->
        case {v.min, v.max} do
          {nil, nil} ->
            "  #{v.name} free\n"

          {nil, max} ->
            "  #{v.name} <= #{max}\n"

          {min, nil} ->
            min_str =
              if is_struct(min, Polynomial), do: Polynomial.serialize(min), else: to_string(min)

            "  #{min_str} <= #{v.name}\n"

          {min, max} ->
            min_str =
              if is_struct(min, Polynomial), do: Polynomial.serialize(min), else: to_string(min)

            max_str =
              if is_struct(max, Polynomial), do: Polynomial.serialize(max), else: to_string(max)

            "  #{min_str} <= #{v.name}\n  #{v.name} <= #{max_str}\n"
        end
    end
  end

  defp all_variable_bounds(variables) do
    Enum.map(variables, &variable_bounds/1)
  end

  defp all_general_variables(variables) do
    general_vars =
      variables
      |> Enum.filter(fn v -> v.type == :binary or v.type == :integer end)
      |> Enum.map(fn v -> "  #{v.name}\n" end)

    if general_vars == [] do
      ""
    else
      general_vars
    end
  end
end
