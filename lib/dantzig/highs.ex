defmodule Dantzig.HiGHS do
  @moduledoc """
  Find solutions using [HiGHS solver][highs].

  [highs]: https://highs.dev
  """

  alias Dantzig.Config
  alias Dantzig.Format.CPLEX
  alias Dantzig.Problem
  alias Dantzig.Solution

  @max_random_prefix 2 ** 32

  def solve(%Problem{} = problem) do
    iodata = CPLEX.to_iodata(problem)

    command = Config.get_highs_binary_path()

    with_temporary_files(["model.lp", "solution.lp"], fn [model_path, solution_path] ->
      File.write!(model_path, iodata)

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

              #{indent(iodata, 4)}
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
    suffix = :rand.uniform(@max_random_prefix) |> Integer.to_string(32)
    dirname = "dantzig_highs_#{suffix}"

    dirpath = Path.join(dir, dirname)

    File.mkdir!(dirpath)

    paths =
      for basename <- basenames do
        Path.join(dirpath, basename)
      end

    try do
      fun.(paths)
    after
      File.rm_rf(dirpath)
    end
  end
end
