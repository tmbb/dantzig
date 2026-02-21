defmodule Dantzig do
  @moduledoc """
  Documentation for `Dantzig`.
  """

  alias Dantzig.Format.CPLEX
  alias Dantzig.HiGHS
  alias Dantzig.Problem

  def solve(%Problem{} = problem) do
    HiGHS.solve(problem)
  end

  def solve!(%Problem{} = problem) do
    {:ok, solution} = HiGHS.solve(problem)
    solution
  end

  def dump_problem_to_file(%Problem{} = problem, path) do
    iodata = CPLEX.to_iodata(problem)
    File.write!(path, iodata)
  end
end
