defmodule Dantzig.Format.CPLEXTest do
  use ExUnit.Case, async: true
  use Mneme

  use Dantzig.Polynomial.Operators

  alias Dantzig.Constraint
  alias Dantzig.Problem

  @subject Dantzig.Format.CPLEX

  test "generates continuous variables correctly and uses them as default" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x")
    {problem, y} = Problem.new_variable(problem, "y", min: 1)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    data = IO.iodata_to_binary(@subject.to_iodata(problem))

    auto_assert(
      """
      Maximize
        1 x00000000_x
      Subject To
        c00000000: 1 x00000000_x + 2 x00000001_y = 10
      Bounds
        x00000000_x free
        1 <= x00000001_y
      General
      Binary
      End
      """ <- data
    )
  end

  test "generates integer variables correctly" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x", type: :integer)
    {problem, y} = Problem.new_variable(problem, "y", min: 1)
    {problem, _z} = Problem.new_variable(problem, "z", min: 5, type: :integer)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    data = IO.iodata_to_binary(@subject.to_iodata(problem))

    auto_assert(
      """
      Maximize
        1 x00000000_x
      Subject To
        c00000000: 1 x00000000_x + 2 x00000001_y = 10
      Bounds
        x00000000_x free
        1 <= x00000001_y
        5 <= x00000002_z
      General
        x00000000_x
        x00000002_z
      Binary
      End
      """ <- data
    )
  end

  test "generates binary variables correctly" do
    problem = Problem.new(direction: :maximize)
    {problem, x} = Problem.new_variable(problem, "x", type: :binary)
    {problem, y} = Problem.new_variable(problem, "y", min: 1)

    problem = Problem.add_constraint(problem, Constraint.new(x + 2 * y, :==, 10))
    problem = Problem.increment_objective(problem, x)

    data = IO.iodata_to_binary(@subject.to_iodata(problem))

    auto_assert(
      """
      Maximize
        1 x00000000_x
      Subject To
        c00000000: 1 x00000000_x + 2 x00000001_y = 10
      Bounds
        1 <= x00000001_y
      General
      Binary
        x00000000_x
      End
      """ <- data
    )
  end
end
