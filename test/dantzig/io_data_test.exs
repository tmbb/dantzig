defmodule Dantzig.IoDataTest do
  use ExUnit.Case, async: true

  require Dantzig.Problem, as: Problem
  use Dantzig.Polynomial.Operators
  alias Dantzig.Constraint
  alias Dantzig.HiGHS

  test "generates continuous variables correctly and uses them as default" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x")
    {problem, y} = Problem.new_variable(problem, "y", min: 1)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    io_data = HiGHS.to_lp_iodata(problem)

    expected = [
      "Maximize",
      "\n  ",
      [["1", " ", ["x00000000_x"]], ""],
      "\n",
      "Subject To\n",
      [
        [
          "  ",
          "c00000000",
          ": ",
          [["1", " ", ["x00000000_x"], " ", ["+ ", "2", " ", ["x00000001_y"]]], ""],
          " ",
          "=",
          " ",
          "10",
          "\n"
        ]
      ],
      "Bounds\n",
      ["  x00000000_x free\n", "  1 <= x00000001_y\n"],
      "General\n",
      [],
      "Binary\n",
      [],
      "End\n"
    ]

    assert io_data == expected
  end

  test "generates integer variables correctly" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x", type: :integer)
    {problem, y} = Problem.new_variable(problem, "y", min: 1)
    {problem, _z} = Problem.new_variable(problem, "z", min: 5, type: :integer)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    io_data = HiGHS.to_lp_iodata(problem)

    expected = [
      "Maximize",
      "\n  ",
      [["1", " ", ["x00000000_x"]], ""],
      "\n",
      "Subject To\n",
      [
        [
          "  ",
          "c00000000",
          ": ",
          [["1", " ", ["x00000000_x"], " ", ["+ ", "2", " ", ["x00000001_y"]]], ""],
          " ",
          "=",
          " ",
          "10",
          "\n"
        ]
      ],
      "Bounds\n",
      ["  x00000000_x free\n", "  1 <= x00000001_y\n", "  5 <= x00000002_z\n"],
      "General\n",
      ["  x00000000_x\n", "  x00000002_z\n"],
      "Binary\n",
      [],
      "End\n"
    ]

    assert io_data == expected
  end

  test "generates binary varialbes correctly" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x", type: :binary)
    {problem, y} = Problem.new_variable(problem, "y", min: 1)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    io_data = HiGHS.to_lp_iodata(problem)

    expected = [
      "Maximize",
      "\n  ",
      [["1", " ", ["x00000000_x"]], ""],
      "\n",
      "Subject To\n",
      [
        [
          "  ",
          "c00000000",
          ": ",
          [["1", " ", ["x00000000_x"], " ", ["+ ", "2", " ", ["x00000001_y"]]], ""],
          " ",
          "=",
          " ",
          "10",
          "\n"
        ]
      ],
      "Bounds\n",
      ["", "  1 <= x00000001_y\n"],
      "General\n",
      [],
      "Binary\n",
      ["  x00000000_x\n"],
      "End\n"
    ]

    assert io_data == expected
  end
end
