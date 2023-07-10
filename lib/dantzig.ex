defmodule Dantzig do
  @moduledoc """
  Documentation for `Dantzig`.
  """

  alias Dantzig.HiGHS
  alias Dantzig.Problem

  def solve(%Problem{} = problem) do
    HiGHS.solve(problem)
  end
end
