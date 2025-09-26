defmodule Dantzig.Solver.HiGHSTest do
  use ExUnit.Case, async: true

  alias Dantzig.{Problem, Solver.HiGHS, Polynomial, Constraint}

  describe "to_lp_iodata/1" do
    test "generates LP format for simple minimization problem" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Constraint: x + y >= 1
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      problem = Problem.add_constraint(problem, constraint, "constraint1")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "x + y")

      # Check that it contains the constraint
      assert String.contains?(lp_string, "Subject To")
      assert String.contains?(lp_string, "constraint1: x + y >= 1")

      # Check that it contains variable bounds
      assert String.contains?(lp_string, "Bounds")
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "y free")

      # Check that it contains the end marker
      assert String.contains?(lp_string, "End")
    end

    test "generates LP format for maximization problem" do
      problem = Problem.new(direction: :maximize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: maximize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Constraint: x + y <= 1
      constraint = Constraint.new(Polynomial.add(x, y), :<=, 1.0)
      problem = Problem.add_constraint(problem, constraint, "constraint1")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective
      assert String.contains?(lp_string, "Maximize")
      assert String.contains?(lp_string, "x + y")

      # Check that it contains the constraint
      assert String.contains?(lp_string, "constraint1: x + y <= 1")
    end

    test "generates LP format with binary variables" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :binary)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains binary variables
      assert String.contains?(lp_string, "Binary")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
    end

    test "generates LP format with integer variables" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :integer)
      {problem, y} = Problem.new_variable(problem, "y", type: :integer)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains integer variables
      assert String.contains?(lp_string, "Integer")
      assert String.contains?(lp_string, "x")
      assert String.contains?(lp_string, "y")
    end

    test "generates LP format with variable bounds" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous, min: 0.0, max: 10.0)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous, min: -5.0, max: 5.0)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains variable bounds
      assert String.contains?(lp_string, "0 <= x <= 10")
      assert String.contains?(lp_string, "-5 <= y <= 5")
    end

    test "generates LP format with unnamed constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Constraint without name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      problem = Problem.add_constraint(problem, constraint)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon
      assert String.contains?(lp_string, "x + y >= 1")
      refute String.contains?(lp_string, ": x + y >= 1")
    end

    test "generates LP format with empty constraint names" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Constraint with empty name
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      problem = Problem.add_constraint(problem, constraint, "")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the constraint without colon
      assert String.contains?(lp_string, "x + y >= 1")
      refute String.contains?(lp_string, ": x + y >= 1")
    end

    test "generates LP format with complex constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :continuous)

      # Objective: minimize x + y + z
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.increment_objective(problem, z)

      # Constraint: 2x + 3y - z >= 5
      constraint =
        Constraint.new(
          Polynomial.add(
            Polynomial.add(Polynomial.multiply(x, 2.0), Polynomial.multiply(y, 3.0)),
            Polynomial.multiply(z, -1.0)
          ),
          :>=,
          5.0
        )

      problem = Problem.add_constraint(problem, constraint, "complex_constraint")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the complex constraint
      assert String.contains?(lp_string, "complex_constraint: 2 x + 3 y - z >= 5")
    end

    test "generates LP format with equality constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Constraint: x + y == 1
      constraint = Constraint.new(Polynomial.add(x, y), :==, 1.0)
      problem = Problem.add_constraint(problem, constraint, "equality_constraint")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the equality constraint
      assert String.contains?(lp_string, "equality_constraint: x + y = 1")
    end

    test "generates LP format with negative coefficients" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x - y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, Polynomial.multiply(y, -1.0))

      # Constraint: x - y >= 0
      constraint =
        Constraint.new(
          Polynomial.subtract(x, y),
          :>=,
          0.0
        )

      problem = Problem.add_constraint(problem, constraint, "negative_constraint")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains negative coefficients
      assert String.contains?(lp_string, "x - y")
      assert String.contains?(lp_string, "negative_constraint: x - y >= 0")
    end

    test "generates LP format with zero objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # No objective (zero)

      # Constraint: x + y >= 1
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      problem = Problem.add_constraint(problem, constraint, "constraint1")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains zero objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "0")
    end

    test "generates LP format with constant objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Objective: minimize 5 (constant)
      problem = Problem.increment_objective(problem, Polynomial.constant(5.0))

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains constant objective
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "5")
    end

    test "generates LP format with mixed variable types" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)
      {problem, z} = Problem.new_variable(problem, "z", type: :integer)

      # Objective: minimize x + y + z
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)
      problem = Problem.increment_objective(problem, z)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all variable types
      assert String.contains?(lp_string, "x free")
      assert String.contains?(lp_string, "Binary")
      assert String.contains?(lp_string, "y")
      assert String.contains?(lp_string, "Integer")
      assert String.contains?(lp_string, "z")
    end

    test "generates LP format with long variable names" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "very_long_variable_name", type: :continuous)

      {problem, y} =
        Problem.new_variable(problem, "another_very_long_variable_name", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains long variable names
      assert String.contains?(lp_string, "very_long_variable_name")
      assert String.contains?(lp_string, "another_very_long_variable_name")
    end

    test "generates LP format with special characters in variable names" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x_1", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y_2", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains variable names with underscores
      assert String.contains?(lp_string, "x_1")
      assert String.contains?(lp_string, "y_2")
    end

    test "generates LP format with multiple constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      # Objective: minimize x + y
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      # Multiple constraints
      constraint1 = Constraint.new(x, :>=, 0.0)
      constraint2 = Constraint.new(y, :>=, 0.0)
      constraint3 = Constraint.new(Polynomial.add(x, y), :<=, 1.0)

      problem = Problem.add_constraint(problem, constraint1, "constraint1")
      problem = Problem.add_constraint(problem, constraint2, "constraint2")
      problem = Problem.add_constraint(problem, constraint3, "constraint3")

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains all constraints
      assert String.contains?(lp_string, "constraint1: x >= 0")
      assert String.contains?(lp_string, "constraint2: y >= 0")
      assert String.contains?(lp_string, "constraint3: x + y <= 1")
    end

    test "generates LP format with no constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous)

      # Objective: minimize x
      problem = Problem.increment_objective(problem, x)

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the objective but no constraints
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "x")
      refute String.contains?(lp_string, "Subject To")
    end

    test "generates LP format with no variables" do
      problem = Problem.new(direction: :minimize)

      # No variables, no objective, no constraints

      lp_data = HiGHS.to_lp_iodata(problem)
      lp_string = IO.iodata_to_binary(lp_data)

      # Check that it contains the basic structure
      assert String.contains?(lp_string, "Minimize")
      assert String.contains?(lp_string, "0")
      assert String.contains?(lp_string, "End")
    end
  end

  describe "constraint_to_iodata/1" do
    test "formats constraint with name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "constraint1")
      string = IO.iodata_to_binary(iodata)

      assert string == "constraint1: x >= 0\n"
    end

    test "formats constraint without name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, nil)
      string = IO.iodata_to_binary(iodata)

      assert string == "x >= 0\n"
    end

    test "formats constraint with empty name" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 0.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "")
      string = IO.iodata_to_binary(iodata)

      assert string == "x >= 0\n"
    end

    test "formats equality constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :==, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "equality")
      string = IO.iodata_to_binary(iodata)

      assert string == "equality: x = 1\n"
    end

    test "formats less than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :<=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "less_equal")
      string = IO.iodata_to_binary(iodata)

      assert string == "less_equal: x <= 1\n"
    end

    test "formats greater than or equal constraint" do
      constraint = Constraint.new(Polynomial.variable("x"), :>=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "greater_equal")
      string = IO.iodata_to_binary(iodata)

      assert string == "greater_equal: x >= 1\n"
    end

    test "formats complex constraint" do
      x = Polynomial.variable("x")
      y = Polynomial.variable("y")
      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      iodata = HiGHS.constraint_to_iodata(constraint, "complex")
      string = IO.iodata_to_binary(iodata)

      assert string == "complex: x + y >= 1\n"
    end
  end

  describe "variable_bounds/1" do
    test "formats continuous variable with bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min: 0.0,
        max: 10.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "0 <= x <= 10\n"
    end

    test "formats continuous variable with only lower bound" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min: 0.0,
        max: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "x >= 0\n"
    end

    test "formats continuous variable with only upper bound" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min: nil,
        max: 10.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "x <= 10\n"
    end

    test "formats continuous variable with no bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min: nil,
        max: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "x free\n"
    end

    test "formats continuous variable with negative bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :continuous,
        min: -5.0,
        max: 5.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "-5 <= x <= 5\n"
    end

    test "formats binary variable" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :binary,
        min: nil,
        max: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == ""
    end

    test "formats integer variable" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :integer,
        min: nil,
        max: nil
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == ""
    end

    test "formats integer variable with bounds" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :integer,
        min: 0.0,
        max: 100.0
      }

      iodata = HiGHS.variable_bounds(var_def)
      string = IO.iodata_to_binary(iodata)

      assert string == "0 <= x <= 100\n"
    end
  end

  describe "error handling" do
    test "handles invalid constraint operator" do
      constraint = Constraint.new(Polynomial.variable("x"), :!=, 0.0)

      assert_raise ArgumentError, fn ->
        HiGHS.constraint_to_iodata(constraint, "invalid")
      end
    end

    test "handles invalid variable type" do
      var_def = %Dantzig.ProblemVariable{
        name: "x",
        type: :invalid,
        min: nil,
        max: nil
      }

      assert_raise ArgumentError, fn ->
        HiGHS.variable_bounds(var_def)
      end
    end
  end
end
