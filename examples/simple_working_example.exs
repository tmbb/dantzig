# Simple working example demonstrating the modern Dantzig DSL
# This shows the clean syntax for creating variables and constraints

require Dantzig.Problem, as: Problem

# Example 1: N-Queens Problem
IO.puts("=== N-Queens Problem ===")

# Create a new problem
problem = Problem.new(direction: :minimize)

# Create variables: x[i,j] = 1 if queen is placed at position (i,j)
# Using the modern clean syntax
problem =
  Problem.variables(problem, "x", [i <- 1..4, j <- 1..4], :binary, description: "Queen position")

# Check that we have 16 variables (4 * 4)
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("Created #{map_size(var_map)} variables")

# Check that all combinations are present
expected_keys = for i <- 1..4, j <- 1..4, do: {i, j}
actual_keys = Map.keys(var_map) |> Enum.sort()
IO.puts("Expected keys: #{inspect(expected_keys)}")
IO.puts("Actual keys: #{inspect(actual_keys)}")
IO.puts("Keys match: #{expected_keys == actual_keys}")

# Constraint: exactly one queen per row
problem = Problem.constraints(problem, [i <- 1..4], x(i, :_) == 1, "One queen per row")

# Check that we have 4 constraints (one for each row)
IO.puts("Created #{map_size(problem.constraints)} constraints")

# Constraint: exactly one queen per column
problem = Problem.constraints(problem, [j <- 1..4], x(:_, j) == 1, "One queen per column")

# Check that we have 8 constraints total (4 rows + 4 columns)
IO.puts("Total constraints: #{map_size(problem.constraints)}")

IO.puts("\n=== Traveling Salesman Problem ===")

# Example 2: TSP
cities = [1, 2, 3]
problem2 = Problem.new(direction: :minimize)

# Variables: x[i,j] = 1 if edge (i,j) is used in the tour
problem2 =
  Problem.variables(problem2, "x", [i <- cities, j <- cities], :binary, description: "Edge used")

# Check that we have 9 variables (3*3)
var_map2 = Problem.get_variables_nd(problem2, "x")
IO.puts("Created #{map_size(var_map2)} variables for TSP")

# Constraint: each city has exactly 2 edges (incoming and outgoing)
problem2 = Problem.constraints(problem2, [i <- cities], x(i, :_) == 1, "Outgoing edges")
problem2 = Problem.constraints(problem2, [i <- cities], x(:_, i) == 1, "Incoming edges")

IO.puts("Created #{map_size(problem2.constraints)} constraints for TSP")

IO.puts("\n=== Classroom Timetabling ===")

# Example 3: Classroom Timetabling
courses = [1, 2]
times = [1, 2, 3]
rooms = [1, 2]

problem3 = Problem.new(direction: :minimize)

problem3 =
  Problem.variables(problem3, "x", [c <- courses, t <- times, r <- rooms], :binary,
    description: "Course schedule"
  )

# Check that we have 12 variables (2 * 3 * 2)
var_map3 = Problem.get_variables_nd(problem3, "x")
IO.puts("Created #{map_size(var_map3)} variables for timetabling")

# Constraint: each course scheduled exactly once
problem3 = Problem.constraints(problem3, [c <- courses], x(c, :_, :_) == 1, "Course scheduled once")

# Constraint: no room double-booking
problem3 = Problem.constraints(problem3, [t <- times, r <- rooms], x(:_, t, r) <= 1, "No room double-booking")

IO.puts("Created #{map_size(problem3.constraints)} constraints for timetabling")

IO.puts("\n=== All examples completed successfully! ===")
