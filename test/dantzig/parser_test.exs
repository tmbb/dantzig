defmodule Dantzig.ParserTest do
  use ExUnit.Case, async: true

  alias Dantzig.Solution

  test "parses solution correctly" do
    solution_text = """
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

    solution = Solution.from_file_contents!(solution_text)

    assert %Solution{} = solution
    # Parses "metadata" correctly
    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # Parses the objective correctly
    assert_in_delta solution.objective, 0.5, 0.0001
    # Parses variables correctly
    assert_in_delta solution.variables["x00000_x"], 0.5, 0.0001
    # Parses constraints correctly
    assert_in_delta solution.constraints["c00000"], 0.5, 0.0001
  end
end
