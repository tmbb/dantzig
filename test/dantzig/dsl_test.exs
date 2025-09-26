defmodule Dantzig.DSLTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Dantzig.{Problem, DSL, Polynomial}

  describe "add_variables/4" do
    test "creates 2D variables with proper indexing" do
      problem = Problem.new(direction: :minimize)

      problem = DSL.__add_variables__(problem, [i <- 1..3, j <- 1..2], "x", :binary)

      # Check that variables are stored in the variables map
      x_vars = Problem.get_variables_nd(problem, "x")
      assert x_vars != nil
      # 3 * 2 = 6 variables
      assert map_size(x_vars) == 6

      # Check specific indices exist
      assert Map.has_key?(x_vars, {1, 1})
      assert Map.has_key?(x_vars, {1, 2})
      assert Map.has_key?(x_vars, {2, 1})
      assert Map.has_key?(x_vars, {2, 2})
      assert Map.has_key?(x_vars, {3, 1})
      assert Map.has_key?(x_vars, {3, 2})

      # Check that each variable is a monomial
      for {_idx, monomial} <- x_vars do
        assert Polynomial.degree(monomial) == 1
        assert Polynomial.number_of_terms(monomial) == 1
      end
    end

    test "creates 3D variables with proper indexing" do
      problem = Problem.new(direction: :minimize)

      problem =
        DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2, k <- 1..2], "y", :continuous)

      y_vars = Problem.get_variables_nd(problem, "y")
      assert y_vars != nil
      # 2 * 2 * 2 = 8 variables
      assert map_size(y_vars) == 8

      # Check specific indices exist
      assert Map.has_key?(y_vars, {1, 1, 1})
      assert Map.has_key?(y_vars, {1, 1, 2})
      assert Map.has_key?(y_vars, {2, 2, 2})
    end

    test "creates 4D variables with proper indexing" do
      problem = Problem.new(direction: :minimize)

      problem =
        DSL.__add_variables__(
          problem,
          [i <- 1..2, j <- 1..2, k <- 1..2, l <- 1..2],
          "z",
          :integer
        )

      z_vars = Problem.get_variables_nd(problem, "z")
      assert z_vars != nil
      # 2^4 = 16 variables
      assert map_size(z_vars) == 16

      # Check specific indices exist
      assert Map.has_key?(z_vars, {1, 1, 1, 1})
      assert Map.has_key?(z_vars, {2, 2, 2, 2})
    end

    test "creates 1D variables (single generator)" do
      problem = Problem.new(direction: :minimize)

      problem = DSL.__add_variables__(problem, [i <- 1..5], "w", :binary)

      w_vars = Problem.get_variables_nd(problem, "w")
      assert w_vars != nil
      assert map_size(w_vars) == 5

      # Check specific indices exist
      assert Map.has_key?(w_vars, {1})
      assert Map.has_key?(w_vars, {2})
      assert Map.has_key?(w_vars, {5})
    end

    test "handles filtered generators" do
      problem = Problem.new(direction: :minimize)

      problem = DSL.__add_variables__(problem, [i <- 1..6, rem(i, 2) == 0], "even", :binary)

      even_vars = Problem.get_variables_nd(problem, "even")
      assert even_vars != nil
      # 2, 4, 6
      assert map_size(even_vars) == 3

      # Check specific indices exist
      assert Map.has_key?(even_vars, {2})
      assert Map.has_key?(even_vars, {4})
      assert Map.has_key?(even_vars, {6})

      # Check that odd indices don't exist
      refute Map.has_key?(even_vars, {1})
      refute Map.has_key?(even_vars, {3})
      refute Map.has_key?(even_vars, {5})
    end

    test "handles multiple filtered generators" do
      problem = Problem.new(direction: :minimize)

      problem = DSL.__add_variables__(problem, [i <- 1..4, j <- 1..4, i + j <= 4], "sum", :binary)

      sum_vars = Problem.get_variables_nd(problem, "sum")
      assert sum_vars != nil

      # Should have variables where i + j <= 4
      expected_indices = [
        {1, 1},
        {1, 2},
        {1, 3},
        {2, 1},
        {2, 2},
        {3, 1}
      ]

      for idx <- expected_indices do
        assert Map.has_key?(sum_vars, idx), "Missing index #{inspect(idx)}"
      end

      # Should not have variables where i + j > 4
      refute Map.has_key?(sum_vars, {2, 3})
      refute Map.has_key?(sum_vars, {3, 2})
      refute Map.has_key?(sum_vars, {4, 1})
    end

    test "supports different variable types" do
      problem = Problem.new(direction: :minimize)

      # Test binary
      problem = DSL.__add_variables__(problem, [i <- 1..2], "bin", :binary)
      bin_vars = Problem.get_variables_nd(problem, "bin")
      assert bin_vars != nil

      # Test continuous
      problem = DSL.__add_variables__(problem, [i <- 1..2], "cont", :continuous)
      cont_vars = Problem.get_variables_nd(problem, "cont")
      assert cont_vars != nil

      # Test integer
      problem = DSL.__add_variables__(problem, [i <- 1..2], "int", :integer)
      int_vars = Problem.get_variables_nd(problem, "int")
      assert int_vars != nil
    end

    test "handles list ranges instead of range literals" do
      problem = Problem.new(direction: :minimize)

      problem = DSL.__add_variables__(problem, [i <- [1, 3, 5], j <- [2, 4]], "list", :binary)

      list_vars = Problem.get_variables_nd(problem, "list")
      assert list_vars != nil
      # 3 * 2 = 6 variables
      assert map_size(list_vars) == 6

      # Check specific indices exist
      assert Map.has_key?(list_vars, {1, 2})
      assert Map.has_key?(list_vars, {3, 4})
      assert Map.has_key?(list_vars, {5, 2})
    end
  end

  describe "add_constraints/4" do
    test "creates row sum constraints" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..3, j <- 1..2], "x", :binary)

      problem = DSL.__add_constraints__(problem, [i <- 1..3], "x", {i, :_}, :==, 1, "row_sum")

      # Should have 3 constraints (one per row)
      assert map_size(problem.constraints) == 3

      # Check constraint names
      constraint_names = Map.keys(problem.constraints)
      assert "row_sum_1" in constraint_names
      assert "row_sum_2" in constraint_names
      assert "row_sum_3" in constraint_names
    end

    test "creates column sum constraints" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..3, j <- 1..2], "x", :binary)

      problem = DSL.__add_constraints__(problem, [j <- 1..2], "x", {:_, j}, :==, 1, "col_sum")

      # Should have 2 constraints (one per column)
      assert map_size(problem.constraints) == 2

      # Check constraint names
      constraint_names = Map.keys(problem.constraints)
      assert "col_sum_1" in constraint_names
      assert "col_sum_2" in constraint_names
    end

    test "creates 3D constraints with pattern matching" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2, k <- 1..2], "y", :binary)

      problem =
        DSL.__add_constraints__(problem, [i <- 1..2], "y", {i, :_, :_}, :==, 1, "plane_sum")

      # Should have 2 constraints (one per i value)
      assert map_size(problem.constraints) == 2

      constraint_names = Map.keys(problem.constraints)
      assert "plane_sum_1" in constraint_names
      assert "plane_sum_2" in constraint_names
    end

    test "creates 4D constraints with pattern matching" do
      problem = Problem.new(direction: :minimize)

      problem =
        DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2, k <- 1..2, l <- 1..2], "z", :binary)

      problem =
        DSL.__add_constraints__(
          problem,
          [i <- 1..2, j <- 1..2],
          "z",
          {i, j, :_, :_},
          :==,
          1,
          "hyperplane_sum"
        )

      # Should have 4 constraints (2 * 2 = 4)
      assert map_size(problem.constraints) == 4

      constraint_names = Map.keys(problem.constraints)
      assert "hyperplane_sum_1_1" in constraint_names
      assert "hyperplane_sum_1_2" in constraint_names
      assert "hyperplane_sum_2_1" in constraint_names
      assert "hyperplane_sum_2_2" in constraint_names
    end

    test "creates constraints with filtered generators" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..4, j <- 1..4], "x", :binary)

      problem =
        DSL.__add_constraints__(
          problem,
          [i <- 1..4, rem(i, 2) == 0],
          "x",
          {i, :_},
          :==,
          1,
          "even_row_sum"
        )

      # Should have 2 constraints (for i = 2, 4)
      assert map_size(problem.constraints) == 2

      constraint_names = Map.keys(problem.constraints)
      assert "even_row_sum_2" in constraint_names
      assert "even_row_sum_4" in constraint_names
    end

    test "creates constraints with different operators" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2], "x", :binary)

      # Test ==
      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :==, 1, "eq")
      # Test <=
      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :<=, 2, "le")
      # Test >=
      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :>=, 0, "ge")

      # Should have 6 constraints total
      assert map_size(problem.constraints) == 6
    end

    test "creates constraints with constant right-hand sides" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2], "x", :binary)

      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :==, 5, "const_rhs")

      # Check that constraints have the correct RHS
      constraints = Map.values(problem.constraints)

      for constraint <- constraints do
        assert constraint.right_hand_side == 5.0
      end
    end

    test "creates constraints with variable right-hand sides" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2], "x", :binary)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)

      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :==, y, "var_rhs")

      # Should have 2 constraints
      assert map_size(problem.constraints) == 2
    end

    test "handles constraints without names" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2], "x", :binary)

      problem = DSL.__add_constraints__(problem, [i <- 1..2], "x", {i, :_}, :==, 1)

      # Should have 2 constraints with auto-generated names
      assert map_size(problem.constraints) == 2
    end
  end

  describe "scalar variable mirroring" do
    test "scalar variables are mirrored at {} index" do
      problem = Problem.new(direction: :minimize)
      {problem, x} = Problem.new_variable(problem, "x", type: :binary)

      # Check that the variable is stored in variable_defs
      var_def = Problem.get_variable(problem, "x")
      assert var_def != nil
      assert var_def.name == "x"
      assert var_def.type == :binary

      # Check that the variable is mirrored in variables["x"][{}]
      x_vars = Problem.get_variables_nd(problem, "x")
      assert x_vars != nil
      assert Map.has_key?(x_vars, {})

      # The mirrored variable should be the same monomial
      mirrored_x = Map.get(x_vars, {})
      assert Polynomial.equal?(x, mirrored_x)
    end

    test "N-D variables don't interfere with scalar mirroring" do
      problem = Problem.new(direction: :minimize)

      # Create a scalar variable
      {problem, x} = Problem.new_variable(problem, "x", type: :binary)

      # Create N-D variables with the same name
      problem = DSL.__add_variables__(problem, [i <- 1..2, j <- 1..2], "x", :binary)

      # Check that both exist
      x_vars = Problem.get_variables_nd(problem, "x")
      # Scalar
      assert Map.has_key?(x_vars, {})
      # N-D
      assert Map.has_key?(x_vars, {1, 1})
      # N-D
      assert Map.has_key?(x_vars, {2, 2})

      # Check that the scalar is still accessible
      var_def = Problem.get_variable(problem, "x")
      assert var_def != nil
      assert var_def.name == "x"
    end

    test "multiple scalar variables are properly mirrored" do
      problem = Problem.new(direction: :minimize)

      {problem, x} = Problem.new_variable(problem, "x", type: :binary)
      {problem, y} = Problem.new_variable(problem, "y", type: :continuous)
      {problem, z} = Problem.new_variable(problem, "z", type: :integer)

      # Check that all are mirrored
      x_vars = Problem.get_variables_nd(problem, "x")
      y_vars = Problem.get_variables_nd(problem, "y")
      z_vars = Problem.get_variables_nd(problem, "z")

      assert Map.has_key?(x_vars, {})
      assert Map.has_key?(y_vars, {})
      assert Map.has_key?(z_vars, {})

      # Check that they're the same monomials
      assert Polynomial.equal?(x, Map.get(x_vars, {}))
      assert Polynomial.equal?(y, Map.get(y_vars, {}))
      assert Polynomial.equal?(z, Map.get(z_vars, {}))
    end
  end

  describe "error handling" do
    test "raises error for invalid variable type" do
      problem = Problem.new(direction: :minimize)

      assert_raise ArgumentError, fn ->
        DSL.__add_variables__(problem, [i <- 1..2], "x", :invalid_type)
      end
    end

    test "raises error for empty generator list" do
      problem = Problem.new(direction: :minimize)

      assert_raise ArgumentError, fn ->
        DSL.__add_variables__(problem, [], "x", :binary)
      end
    end

    test "raises error for invalid constraint operator" do
      problem = Problem.new(direction: :minimize)
      problem = DSL.__add_variables__(problem, [i <- 1..2], "x", :binary)

      assert_raise ArgumentError, fn ->
        DSL.__add_constraints__(problem, [i <- 1..2], "x", {i}, :!=, 1, "invalid")
      end
    end
  end

  describe "integration tests" do
    test "N-Queens problem can be modeled" do
      problem = Problem.new(direction: :minimize)

      # Create variables for queen positions
      problem = DSL.__add_variables__(problem, [i <- 1..4, j <- 1..4], "x", :binary)

      # One queen per row
      problem = DSL.__add_constraints__(problem, [i <- 1..4], "x", {i, :_}, :==, 1, "row")

      # One queen per column
      problem = DSL.__add_constraints__(problem, [j <- 1..4], "x", {:_, j}, :==, 1, "col")

      # Check that we have the right number of variables and constraints
      x_vars = Problem.get_variables_nd(problem, "x")
      # 4x4 = 16 variables
      assert map_size(x_vars) == 16

      # 4 rows + 4 columns
      assert map_size(problem.constraints) == 8
    end

    test "assignment problem can be modeled" do
      problem = Problem.new(direction: :minimize)

      # Create variables for assignments
      problem = DSL.__add_variables__(problem, [i <- 1..3, j <- 1..3], "x", :binary)

      # Each worker assigned to exactly one job
      problem = DSL.__add_constraints__(problem, [i <- 1..3], "x", {i, :_}, :==, 1, "worker")

      # Each job assigned to exactly one worker
      problem = DSL.__add_constraints__(problem, [j <- 1..3], "x", {:_, j}, :==, 1, "job")

      # Check that we have the right number of variables and constraints
      x_vars = Problem.get_variables_nd(problem, "x")
      # 3x3 = 9 variables
      assert map_size(x_vars) == 9

      # 3 workers + 3 jobs
      assert map_size(problem.constraints) == 6
    end
  end
end
