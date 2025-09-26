defmodule Dantzig do
  @moduledoc """
  Public API for solving optimization problems with HiGHS.

  Dantzig provides a modeling layer (`Dantzig.Problem`, `Dantzig.Polynomial`,
  `Dantzig.Constraint`) and integrates with the external `highs` solver to
  compute solutions. Use `solve/1` or `solve!/1` to obtain a `Dantzig.Solution`.

  See `Dantzig.Problem` for building problems, `Dantzig.Polynomial` for
  symbolic algebra, and `Dantzig.Constraint` for constructing constraints.
  """

  alias Dantzig.HiGHS
  alias Dantzig.Problem

  @doc """
  Solve a `Dantzig.Problem`, returning `{:ok, %Dantzig.Solution{}} | :error`.

  Writes a temporary LP/QP model, invokes the external `highs` binary, and
  parses the solver output.
  """
  def solve(%Problem{} = problem) do
    HiGHS.solve(problem)
  end

  @doc """
  Bang variant of `solve/1`. Raises if HiGHS fails to produce a solution.
  """
  def solve!(%Problem{} = problem) do
    {:ok, solution} = HiGHS.solve(problem)
    solution
  end

  @doc """
  Serialize a problem to LP/QP iodata and write it to `path`.

  Useful for debugging or running the model with external tools.
  """
  def dump_problem_to_file(%Problem{} = problem, path) do
    iodata = HiGHS.to_lp_iodata(problem)
    File.write!(path, iodata)
  end
end
