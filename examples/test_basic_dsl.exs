# Test file for basic DSL functionality
# This file tests the new Problem.variables/constraints/objective functions
# Using the modern clean DSL syntax

require Dantzig.Problem, as: Problem

IO.puts("=== Testing Basic DSL Functions ===")

# Test 1: Simple variable creation using modern DSL syntax
problem1 = Problem.new(name: "Test 1")

# Use the modern clean DSL syntax
problem1 =
  Problem.variables(problem1, "x", [i <- 1..2, j <- 1..2], :binary, description: "Test variables")

IO.puts("Created problem: #{problem1.name}")
IO.puts("Variables: #{map_size(problem1.variables)}")

# Test 2: Simple constraints using modern DSL syntax
problem1 = Problem.constraints(problem1, [i <- 1..2], x(i, :_) == 1, "Test constraint")

IO.puts("Constraints: #{map_size(problem1.constraints)}")

# Test 3: Simple objective using modern DSL syntax
problem1 = Problem.objective(problem1, sum(x(:_, :_)), direction: :minimize)

IO.puts("Objective set successfully")
IO.puts("Direction: #{problem1.direction}")

IO.puts("\n=== Basic DSL Test Completed Successfully! ===")
