defmodule Dantzig.Core.ProblemTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Dantzig.{Problem, Constraint, Polynomial}

  describe "new/1" do
    test "creates minimization problem" do
      problem = Problem.new(direction: :minimize)

      assert problem.direction == :minimize
      assert problem.variable_counter == 0
      assert problem.constraint_counter == 0
      assert problem.objective == Polynomial.const(0.0)
      assert problem.variable_defs == %{}
      assert problem.variables == %{}
      assert problem.constraints == %{}
    end

    test "creates maximization problem" do
      problem = Problem.new(direction: :maximize)

      assert problem.direction == :maximize
      assert problem.variable_counter == 0
      assert problem.constraint_counter == 0
      assert problem.objective == Polynomial.const(0.0)
      assert problem.variable_defs == %{}
      assert problem.variables == %{}
      assert problem.constraints == %{}
    end

    test "raises error for missing direction" do
      assert_raise RuntimeError, fn ->
        Problem.new([])
      end
    end

    test "raises error for invalid direction" do
      assert_raise RuntimeError, fn ->
        Problem.new(direction: :invalid)
      end
    end
  end

  describe "new_variable/3" do
    test "creates continuous variable with default options" do
      problem = Problem.new(direction: :minimize)
      {new_problem, variable} = Problem.new_variable(problem, "x")

      # Check variable definition
      var_def = Problem.get_variable(new_problem, "x")
      assert var_def != nil
      assert var_def.name == "x"
      assert var_def.type == :continuous
      assert var_def.min == nil
      assert var_def.max == nil

      # Check that variable is mirrored in variables map
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert x_vars != nil
      assert Map.has_key?(x_vars, {})

      # Check that the variable is a monomial
      assert Polynomial.degree(variable) == 1
      assert Polynomial.number_of_terms(variable) == 1
      assert Polynomial.has_constant_term?(variable) == false

      # Check counter increment
      assert new_problem.variable_counter == 1
    end

    test "creates binary variable" do
      problem = Problem.new(direction: :minimize)
      {new_problem, variable} = Problem.new_variable(problem, "x", type: :binary)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.type == :binary

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "creates integer variable" do
      problem = Problem.new(direction: :minimize)
      {new_problem, variable} = Problem.new_variable(problem, "x", type: :integer)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.type == :integer

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "creates variable with bounds" do
      problem = Problem.new(direction: :minimize)

      {new_problem, variable} =
        Problem.new_variable(problem, "x", type: :continuous, min: 0.0, max: 10.0)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.min == 0.0
      assert var_def.max == 10.0

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "creates variable with only lower bound" do
      problem = Problem.new(direction: :minimize)
      {new_problem, variable} = Problem.new_variable(problem, "x", type: :continuous, min: 0.0)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.min == 0.0
      assert var_def.max == nil

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "creates variable with only upper bound" do
      problem = Problem.new(direction: :minimize)
      {new_problem, variable} = Problem.new_variable(problem, "x", type: :continuous, max: 10.0)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.min == nil
      assert var_def.max == 10.0

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "creates variable with negative bounds" do
      problem = Problem.new(direction: :minimize)

      {new_problem, variable} =
        Problem.new_variable(problem, "x", type: :continuous, min: -5.0, max: 5.0)

      var_def = Problem.get_variable(new_problem, "x")
      assert var_def.min == -5.0
      assert var_def.max == 5.0

      # Check that variable is mirrored
      x_vars = Problem.get_variables_nd(new_problem, "x")
      assert Map.has_key?(x_vars, {})
      assert variable == Map.get(x_vars, {})
    end

    test "increments variable counter" do
      problem = Problem.new(direction: :minimize)
      {new_problem1, _} = Problem.new_variable(problem, "x")
      {new_problem2, _} = Problem.new_variable(new_problem1, "y")
      {new_problem3, _} = Problem.new_variable(new_problem2, "z")

      assert new_problem1.variable_counter == 1
      assert new_problem2.variable_counter == 2
      assert new_problem3.variable_counter == 3
    end

    test "creates multiple variables with same name" do
      problem = Problem.new(direction: :minimize)
      {new_problem1, x1} = Problem.new_variable(problem, "x")
      {new_problem2, x2} = Problem.new_variable(new_problem1, "x")

      # Should create separate variable definitions
      var_def1 = Problem.get_variable(new_problem2, "x")
      assert var_def1 != nil

      # Should have different monomials
      refute Polynomial.equal?(x1, x2)

      # Should have different variable counters
      assert new_problem2.variable_counter == 2
    end
  end

  describe "get_variable/2" do
    test "returns variable definition for existing variable" do
      problem = Problem.new(direction: :minimize)
      {problem, _} = Problem.new_variable(problem, "x", type: :binary, min: 0.0, max: 1.0)

      var_def = Problem.get_variable(problem, "x")
      assert var_def != nil
      assert var_def.name == "x"
      assert var_def.type == :binary
      assert var_def.min == 0.0
      assert var_def.max == 1.0
    end

    test "returns nil for non-existing variable" do
      problem = Problem.new(direction: :minimize)

      var_def = Problem.get_variable(problem, "nonexistent")
      assert var_def == nil
    end
  end

  describe "get_variables_nd/2" do
    test "returns N-D variable map for existing variable set" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      x_vars = Problem.get_variables_nd(problem, "x")
      assert x_vars != nil
      assert Map.has_key?(x_vars, {})
      assert x_vars[{}] == x
    end

    test "returns nil for non-existing variable set" do
      problem = Problem.new(direction: :minimize)

      x_vars = Problem.get_variables_nd(problem, "nonexistent")
      assert x_vars == nil
    end
  end

  describe "put_variables_nd/3" do
    test "puts N-D variable map" do
      problem = Problem.new(direction: :minimize)

      x_vars = %{
        {1, 1} => Polynomial.variable("x1_1"),
        {1, 2} => Polynomial.variable("x1_2"),
        {2, 1} => Polynomial.variable("x2_1"),
        {2, 2} => Polynomial.variable("x2_2")
      }

      new_problem = Problem.put_variables_nd(problem, "x", x_vars)

      retrieved_vars = Problem.get_variables_nd(new_problem, "x")
      assert retrieved_vars == x_vars
    end

    test "overwrites existing N-D variable map" do
      problem = Problem.new(direction: :minimize)
      {problem, _} = Problem.new_variable(problem, "x")

      x_vars = %{
        {1, 1} => Polynomial.variable("x1_1"),
        {1, 2} => Polynomial.variable("x1_2")
      }

      new_problem = Problem.put_variables_nd(problem, "x", x_vars)

      retrieved_vars = Problem.get_variables_nd(new_problem, "x")
      assert retrieved_vars == x_vars
      # Original scalar should be overwritten
      refute Map.has_key?(retrieved_vars, {})
    end
  end

  describe "add_constraint/3" do
    test "adds constraint with name" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")
      {problem, y} = Problem.new_variable(problem, "y")

      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      new_problem = Problem.add_constraint(problem, constraint, "constraint1")

      assert map_size(new_problem.constraints) == 1
      assert Map.has_key?(new_problem.constraints, "constraint1")
      assert new_problem.constraint_counter == 1
    end

    test "adds constraint without name" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")
      {problem, y} = Problem.new_variable(problem, "y")

      constraint = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      new_problem = Problem.add_constraint(problem, constraint)

      assert map_size(new_problem.constraints) == 1
      assert new_problem.constraint_counter == 1

      # Should have auto-generated name
      constraint_names = Map.keys(new_problem.constraints)
      assert length(constraint_names) == 1
      assert String.starts_with?(hd(constraint_names), "constraint_")
    end

    test "adds multiple constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")
      {problem, y} = Problem.new_variable(problem, "y")

      constraint1 = Constraint.new(x, :>=, 0.0)
      constraint2 = Constraint.new(y, :>=, 0.0)
      constraint3 = Constraint.new(Polynomial.add(x, y), :<=, 1.0)

      problem = Problem.add_constraint(problem, constraint1, "constraint1")
      problem = Problem.add_constraint(problem, constraint2, "constraint2")
      problem = Problem.add_constraint(problem, constraint3, "constraint3")

      assert map_size(problem.constraints) == 3
      assert problem.constraint_counter == 3
    end

    test "increments constraint counter" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      constraint1 = Constraint.new(x, :>=, 0.0)
      constraint2 = Constraint.new(x, :<=, 1.0)

      problem = Problem.add_constraint(problem, constraint1, "constraint1")
      problem = Problem.add_constraint(problem, constraint2, "constraint2")

      assert problem.constraint_counter == 2
    end

    test "overwrites constraint with same name" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      constraint1 = Constraint.new(x, :>=, 0.0)
      constraint2 = Constraint.new(x, :<=, 1.0)

      problem = Problem.add_constraint(problem, constraint1, "constraint1")
      problem = Problem.add_constraint(problem, constraint2, "constraint1")

      assert map_size(problem.constraints) == 1
      assert problem.constraint_counter == 2
    end
  end

  describe "increment_objective/2" do
    test "adds variable to objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      new_problem = Problem.increment_objective(problem, x)

      assert new_problem.objective == x
    end

    test "adds multiple variables to objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")
      {problem, y} = Problem.new_variable(problem, "y")

      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, y)

      expected = Polynomial.add(x, y)
      assert Polynomial.equal?(problem.objective, expected)
    end

    test "adds constant to objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, Polynomial.constant(5.0))

      expected = Polynomial.add(x, Polynomial.constant(5.0))
      assert Polynomial.equal?(problem.objective, expected)
    end

    test "adds polynomial to objective" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")
      {problem, y} = Problem.new_variable(problem, "y")

      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, Polynomial.multiply(y, 2.0))

      expected = Polynomial.add(x, Polynomial.multiply(y, 2.0))
      assert Polynomial.equal?(problem.objective, expected)
    end
  end

  describe "deprecated functions" do
    test "get_var_map/2 still works" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      x_vars = Problem.get_var_map(problem, "x")
      assert x_vars != nil
      assert Map.has_key?(x_vars, {})
      assert x_vars[{}] == x
    end

    test "put_var_map/3 still works" do
      problem = Problem.new(direction: :minimize)

      x_vars = %{
        {1, 1} => Polynomial.variable("x1_1"),
        {1, 2} => Polynomial.variable("x1_2")
      }

      new_problem = Problem.put_var_map(problem, "x", x_vars)

      retrieved_vars = Problem.get_var_map(new_problem, "x")
      assert retrieved_vars == x_vars
    end
  end

  describe "integration tests" do
    test "creates complete problem with variables, constraints, and objective" do
      problem = Problem.new(direction: :minimize)

      # Create variables
      {problem, x} = Problem.new_variable(problem, "x", type: :continuous, min: 0.0, max: 10.0)
      {problem, y} = Problem.new_variable(problem, "y", type: :binary)
      {problem, z} = Problem.new_variable(problem, "z", type: :integer, min: 0.0, max: 100.0)

      # Add objective
      problem = Problem.increment_objective(problem, x)
      problem = Problem.increment_objective(problem, Polynomial.multiply(y, 2.0))
      problem = Problem.increment_objective(problem, Polynomial.multiply(z, 3.0))

      # Add constraints
      constraint1 = Constraint.new(Polynomial.add(x, y), :>=, 1.0)
      constraint2 = Constraint.new(Polynomial.add(y, z), :<=, 5.0)
      constraint3 = Constraint.new(x, :==, y)

      problem = Problem.add_constraint(problem, constraint1, "constraint1")
      problem = Problem.add_constraint(problem, constraint2, "constraint2")
      problem = Problem.add_constraint(problem, constraint3, "constraint3")

      # Verify problem structure
      assert problem.direction == :minimize
      assert problem.variable_counter == 3
      assert problem.constraint_counter == 3

      # Verify variables
      assert Problem.get_variable(problem, "x").type == :continuous
      assert Problem.get_variable(problem, "y").type == :binary
      assert Problem.get_variable(problem, "z").type == :integer

      # Verify N-D variable maps
      x_vars = Problem.get_variables_nd(problem, "x")
      y_vars = Problem.get_variables_nd(problem, "y")
      z_vars = Problem.get_variables_nd(problem, "z")

      assert Map.has_key?(x_vars, {})
      assert Map.has_key?(y_vars, {})
      assert Map.has_key?(z_vars, {})

      # Verify constraints
      assert map_size(problem.constraints) == 3
      assert Map.has_key?(problem.constraints, "constraint1")
      assert Map.has_key?(problem.constraints, "constraint2")
      assert Map.has_key?(problem.constraints, "constraint3")

      # Verify objective
      expected_objective =
        Polynomial.add(
          x,
          Polynomial.add(
            Polynomial.multiply(y, 2.0),
            Polynomial.multiply(z, 3.0)
          )
        )

      assert Polynomial.equal?(problem.objective, expected_objective)
    end

    test "handles large number of variables" do
      problem = Problem.new(direction: :minimize)

      # Create 100 variables
      for i <- 1..100 do
        {problem, _} = Problem.new_variable(problem, "x#{i}", type: :continuous)
      end

      assert problem.variable_counter == 100
      assert map_size(problem.variable_defs) == 100
      assert map_size(problem.variables) == 100

      # Verify all variables exist
      for i <- 1..100 do
        var_def = Problem.get_variable(problem, "x#{i}")
        assert var_def != nil
        assert var_def.name == "x#{i}"

        x_vars = Problem.get_variables_nd(problem, "x#{i}")
        assert x_vars != nil
        assert Map.has_key?(x_vars, {})
      end
    end

    test "handles large number of constraints" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      # Create 100 constraints
      for i <- 1..100 do
        constraint = Constraint.new(x, :>=, i)
        problem = Problem.add_constraint(problem, constraint, "constraint#{i}")
      end

      assert problem.constraint_counter == 100
      assert map_size(problem.constraints) == 100

      # Verify all constraints exist
      for i <- 1..100 do
        assert Map.has_key?(problem.constraints, "constraint#{i}")
      end
    end
  end

  describe "error handling" do
    test "raises error for invalid variable type" do
      problem = Problem.new(direction: :minimize)

      assert_raise ArgumentError, fn ->
        Problem.new_variable(problem, "x", type: :invalid)
      end
    end

    test "raises error for invalid bounds" do
      problem = Problem.new(direction: :minimize)

      assert_raise ArgumentError, fn ->
        Problem.new_variable(problem, "x", type: :continuous, min: 10.0, max: 5.0)
      end
    end

    test "raises error for invalid constraint operator" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x")

      constraint = Constraint.new(x, :!=, 0.0)

      assert_raise ArgumentError, fn ->
        Problem.add_constraint(problem, constraint, "invalid")
      end
    end
  end
end
