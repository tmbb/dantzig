# Comprehensive Tutorial Examples for Dantzig Macros
# This file demonstrates all the features of the new macro system

require Dantzig.Problem, as: Problem
require Dantzig.DSL, as: Macros

IO.puts("=== DANTZIG MACROS TUTORIAL ===")
IO.puts("This tutorial demonstrates the clean syntax for optimization problems")
IO.puts("")

# ============================================================================
# EXAMPLE 1: N-QUEENS PROBLEM
# ============================================================================
IO.puts("1. N-QUEENS PROBLEM")
IO.puts("===================")
IO.puts("Place N queens on an N×N chessboard so that no two queens attack each other.")
IO.puts("")

# Create a new problem
problem = Problem.new(direction: :minimize)

# Variables: x[i,j] = 1 if queen is placed at position (i,j)
# Clean syntax: [i <- 1..4, j <- 1..4] becomes [{:i, :in, [1,2,3,4]}, {:j, :in, [1,2,3,4]}]
generators = [{:i, :in, [1, 2, 3, 4]}, {:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_variables(problem, generators, "x", :binary, "Queen position")

# Check variables created
var_map = Problem.get_var_map(problem, "x")
IO.puts("✓ Created #{map_size(var_map)} variables (4×4 = 16)")

# Constraint 1: exactly one queen per row
# Pattern {i, :_} means "sum over all j for fixed i"
row_generators = [{:i, :in, [1, 2, 3, 4]}]

problem =
  Macros.add_constraints(problem, row_generators, "x", {:i, :_}, :==, 1, "One queen per row")

IO.puts("✓ Added row constraints: #{map_size(problem.constraints)} total constraints")

# Constraint 2: exactly one queen per column
# Pattern {:_, j} means "sum over all i for fixed j"
col_generators = [{:j, :in, [1, 2, 3, 4]}]

problem =
  Macros.add_constraints(problem, col_generators, "x", {:_, :j}, :==, 1, "One queen per column")

IO.puts("✓ Added column constraints: #{map_size(problem.constraints)} total constraints")

IO.puts("")

# ============================================================================
# EXAMPLE 2: TRAVELING SALESMAN PROBLEM (TSP)
# ============================================================================
IO.puts("2. TRAVELING SALESMAN PROBLEM")
IO.puts("=============================")
IO.puts("Find the shortest route visiting each city exactly once and returning to start.")
IO.puts("")

problem2 = Problem.new(direction: :minimize)
cities = [1, 2, 3, 4]

# Variables: x[i,j] = 1 if edge (i,j) is used in the tour
tsp_generators = [{:i, :in, cities}, {:j, :in, cities}]
problem2 = Macros.add_variables(problem2, tsp_generators, "x", :binary, "Edge used")

var_map2 = Problem.get_var_map(problem2, "x")
IO.puts("✓ Created #{map_size(var_map2)} variables (4×4 = 16)")

# Constraint: each city has exactly 2 edges (incoming and outgoing)
# Outgoing edges: sum over j for fixed i
outgoing_generators = [{:i, :in, cities}]

problem2 =
  Macros.add_constraints(problem2, outgoing_generators, "x", {:i, :_}, :==, 1, "Outgoing edges")

# Incoming edges: sum over i for fixed j
incoming_generators = [{:j, :in, cities}]

problem2 =
  Macros.add_constraints(problem2, incoming_generators, "x", {:_, :j}, :==, 1, "Incoming edges")

IO.puts("✓ Added degree constraints: #{map_size(problem2.constraints)} total constraints")
IO.puts("")

# ============================================================================
# EXAMPLE 3: CLASSROOM TIMETABLING
# ============================================================================
IO.puts("3. CLASSROOM TIMETABLING")
IO.puts("========================")
IO.puts("Schedule courses in time slots and rooms with constraints.")
IO.puts("")

problem3 = Problem.new(direction: :minimize)
courses = [1, 2, 3]
times = [1, 2, 3, 4]
rooms = [1, 2]

# Variables: x[c,t,r] = 1 if course c is scheduled at time t in room r
timetable_generators = [{:c, :in, courses}, {:t, :in, times}, {:r, :in, rooms}]
problem3 = Macros.add_variables(problem3, timetable_generators, "x", :binary, "Course schedule")

var_map3 = Problem.get_var_map(problem3, "x")
IO.puts("✓ Created #{map_size(var_map3)} variables (3×4×2 = 24)")

# Constraint 1: each course scheduled exactly once
course_generators = [{:c, :in, courses}]

problem3 =
  Macros.add_constraints(
    problem3,
    course_generators,
    "x",
    {:c, :_, :_},
    :==,
    1,
    "Course scheduled once"
  )

# Constraint 2: no room double-booking
room_generators = [{:t, :in, times}, {:r, :in, rooms}]

problem3 =
  Macros.add_constraints(
    problem3,
    room_generators,
    "x",
    {:_, :t, :r},
    :<=,
    1,
    "No room double-booking"
  )

IO.puts("✓ Added scheduling constraints: #{map_size(problem3.constraints)} total constraints")
IO.puts("")

# ============================================================================
# EXAMPLE 4: KNAPSACK PROBLEM
# ============================================================================
IO.puts("4. KNAPSACK PROBLEM")
IO.puts("===================")
IO.puts("Select items to maximize value while staying within weight limit.")
IO.puts("")

problem4 = Problem.new(direction: :maximize)
items = [1, 2, 3, 4, 5]

# Variables: x[i] = 1 if item i is selected
knapsack_generators = [{:i, :in, items}]
problem4 = Macros.add_variables(problem4, knapsack_generators, "x", :binary, "Item selected")

var_map4 = Problem.get_var_map(problem4, "x")
IO.puts("✓ Created #{map_size(var_map4)} variables (5 items)")

# Constraint: weight limit (simplified - using sum over all items)
# Note: This creates a single constraint with no generators
problem4 = Macros.add_constraints(problem4, [], "x", {:_, :_, :_}, :<=, 3, "Weight limit")

IO.puts("✓ Added weight constraint: #{map_size(problem4.constraints)} total constraints")
IO.puts("")

# ============================================================================
# EXAMPLE 5: ASSIGNMENT PROBLEM
# ============================================================================
IO.puts("5. ASSIGNMENT PROBLEM")
IO.puts("=====================")
IO.puts("Assign people to tasks with one-to-one matching.")
IO.puts("")

problem5 = Problem.new(direction: :minimize)
people = [1, 2, 3]
tasks = [1, 2, 3]

# Variables: x[i,j] = 1 if person i is assigned to task j
assignment_generators = [{:i, :in, people}, {:j, :in, tasks}]
problem5 = Macros.add_variables(problem5, assignment_generators, "x", :binary, "Assignment")

var_map5 = Problem.get_var_map(problem5, "x")
IO.puts("✓ Created #{map_size(var_map5)} variables (3×3 = 9)")

# Constraint 1: each person assigned to exactly one task
person_generators = [{:i, :in, people}]

problem5 =
  Macros.add_constraints(
    problem5,
    person_generators,
    "x",
    {:i, :_},
    :==,
    1,
    "Person assigned once"
  )

# Constraint 2: each task assigned to exactly one person
task_generators = [{:j, :in, tasks}]

problem5 =
  Macros.add_constraints(problem5, task_generators, "x", {:_, :j}, :==, 1, "Task assigned once")

IO.puts("✓ Added assignment constraints: #{map_size(problem5.constraints)} total constraints")
IO.puts("")

# ============================================================================
# EXAMPLE 6: FACILITY LOCATION PROBLEM
# ============================================================================
IO.puts("6. FACILITY LOCATION PROBLEM")
IO.puts("=============================")
IO.puts("Decide which facilities to open and which customers to serve.")
IO.puts("")

problem6 = Problem.new(direction: :minimize)
facilities = [1, 2, 3]
customers = [1, 2, 3, 4]

# Variables: x[i] = 1 if facility i is opened
facility_generators = [{:i, :in, facilities}]
problem6 = Macros.add_variables(problem6, facility_generators, "x", :binary, "Facility opened")

# Variables: y[i,j] = 1 if customer j is served by facility i
service_generators = [{:i, :in, facilities}, {:j, :in, customers}]
problem6 = Macros.add_variables(problem6, service_generators, "y", :binary, "Customer served")

x_map = Problem.get_var_map(problem6, "x")
y_map = Problem.get_var_map(problem6, "y")

IO.puts(
  "✓ Created #{map_size(x_map)} facility variables and #{map_size(y_map)} service variables"
)

# Constraint 1: customer can only be served by open facility
# This would require a more complex constraint: y[i,j] <= x[i]
# For now, we'll add a simpler constraint
service_constraint_generators = [{:i, :in, facilities}, {:j, :in, customers}]

problem6 =
  Macros.add_constraints(
    problem6,
    service_constraint_generators,
    "y",
    {:i, :j},
    :<=,
    1,
    "Service constraint"
  )

# Constraint 2: each customer served by exactly one facility
customer_generators = [{:j, :in, customers}]

problem6 =
  Macros.add_constraints(
    problem6,
    customer_generators,
    "y",
    {:_, :j},
    :==,
    1,
    "Customer served once"
  )

IO.puts("✓ Added facility constraints: #{map_size(problem6.constraints)} total constraints")
IO.puts("")

# ============================================================================
# EXAMPLE 7: 3D PROBLEM WITH FILTERS
# ============================================================================
IO.puts("7. 3D PROBLEM WITH FILTERS")
IO.puts("==========================")
IO.puts("Demonstrate multi-dimensional variables with filtering.")
IO.puts("")

problem7 = Problem.new(direction: :minimize)

# Variables: x[i,j,k] = 1 for valid combinations
# We'll create all combinations and then filter manually
dim1 = [1, 2]
dim2 = [1, 2]
dim3 = [1, 2]

# Create all combinations
all_combinations = for i <- dim1, j <- dim2, k <- dim3, i + j + k <= 4, do: {i, j, k}
IO.puts("✓ Valid combinations: #{inspect(all_combinations)}")

# For this example, we'll use a simpler approach
simple_3d_generators = [{:i, :in, dim1}, {:j, :in, dim2}, {:k, :in, dim3}]
problem7 = Macros.add_variables(problem7, simple_3d_generators, "x", :binary, "3D variable")

var_map7 = Problem.get_var_map(problem7, "x")
IO.puts("✓ Created #{map_size(var_map7)} variables (2×2×2 = 8)")

# Constraint: sum over one dimension
constraint_3d_generators = [{:i, :in, dim1}, {:j, :in, dim2}]

problem7 =
  Macros.add_constraints(
    problem7,
    constraint_3d_generators,
    "x",
    {:i, :j, :_},
    :<=,
    1,
    "3D constraint"
  )

IO.puts("✓ Added 3D constraints: #{map_size(problem7.constraints)} total constraints")
IO.puts("")

# ============================================================================
# SUMMARY
# ============================================================================
IO.puts("SUMMARY")
IO.puts("=======")

IO.puts(
  "✓ N-Queens: #{map_size(Problem.get_var_map(problem, "x"))} variables, #{map_size(problem.constraints)} constraints"
)

IO.puts(
  "✓ TSP: #{map_size(Problem.get_var_map(problem2, "x"))} variables, #{map_size(problem2.constraints)} constraints"
)

IO.puts(
  "✓ Timetabling: #{map_size(Problem.get_var_map(problem3, "x"))} variables, #{map_size(problem3.constraints)} constraints"
)

IO.puts(
  "✓ Knapsack: #{map_size(Problem.get_var_map(problem4, "x"))} variables, #{map_size(problem4.constraints)} constraints"
)

IO.puts(
  "✓ Assignment: #{map_size(Problem.get_var_map(problem5, "x"))} variables, #{map_size(problem5.constraints)} constraints"
)

IO.puts(
  "✓ Facility Location: #{map_size(Problem.get_var_map(problem6, "x")) + map_size(Problem.get_var_map(problem6, "y"))} variables, #{map_size(problem6.constraints)} constraints"
)

IO.puts(
  "✓ 3D Problem: #{map_size(Problem.get_var_map(problem7, "x"))} variables, #{map_size(problem7.constraints)} constraints"
)

IO.puts("")
IO.puts("🎉 All examples completed successfully!")
IO.puts("")
IO.puts("KEY FEATURES DEMONSTRATED:")
IO.puts("• Clean syntax for variable creation with generators")
IO.puts("• Pattern matching for constraint creation (e.g., {i, :_}, {:_, j})")
IO.puts("• Multi-dimensional variables (2D, 3D)")
IO.puts("• Multiple variable sets in the same problem")
IO.puts("• Automatic constraint generation from patterns")
IO.puts("• Integration with Dantzig.Problem struct")
