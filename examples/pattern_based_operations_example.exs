# Pattern-Based Operations Example
# Demonstrates the new pattern-based syntax: max(x[_]), min(x[_]), etc.

require Dantzig.Problem, as: Problem
require Dantzig.DSL, as: Macros

IO.puts("=== PATTERN-BASED OPERATIONS DEMONSTRATION ===")
IO.puts("This example shows the new pattern-based syntax for variadic operations")
IO.puts("")

# ============================================================================
# EXAMPLE 1: PATTERN-BASED MAX OPERATION
# ============================================================================
IO.puts("1. PATTERN-BASED MAX OPERATION")
IO.puts("===============================")
IO.puts("Instead of: max(x[1], x[2], x[3], x[4], x[5])")
IO.puts("You can write: max(x[_])")
IO.puts("")

# Create variables
problem = Problem.new(direction: :minimize)
generators = [{:i, :in, [1, 2, 3, 4, 5]}]
problem = Macros.add_variables(problem, generators, "x", :continuous, "Continuous variables")

# Get the variable map to show what variables were created
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("✓ Created #{map_size(var_map)} continuous variables:")

Enum.each(var_map, fn {key, _monomial} ->
  IO.puts("  - x#{inspect(key)}")
end)

IO.puts("")
IO.puts("Pattern-based syntax: max(x[_]) would create constraints:")
IO.puts("  - max_x_all >= x[1]")
IO.puts("  - max_x_all >= x[2]")
IO.puts("  - max_x_all >= x[3]")
IO.puts("  - max_x_all >= x[4]")
IO.puts("  - max_x_all >= x[5]")
IO.puts("")

# ============================================================================
# EXAMPLE 2: PATTERN-BASED MIN OPERATION
# ============================================================================
IO.puts("2. PATTERN-BASED MIN OPERATION")
IO.puts("===============================")
IO.puts("Instead of: min(y[1], y[2], y[3])")
IO.puts("You can write: min(y[_])")
IO.puts("")

# Create more variables
generators2 = [{:i, :in, [1, 2, 3]}]

problem =
  Macros.add_variables(problem, generators2, "y", :continuous, "More continuous variables")

var_map2 = Problem.get_variables_nd(problem, "y")
IO.puts("✓ Created #{map_size(var_map2)} continuous variables:")

Enum.each(var_map2, fn {key, _monomial} ->
  IO.puts("  - y#{inspect(key)}")
end)

IO.puts("")
IO.puts("Pattern-based syntax: min(y[_]) would create constraints:")
IO.puts("  - min_y_all <= y[1]")
IO.puts("  - min_y_all <= y[2]")
IO.puts("  - min_y_all <= y[3]")
IO.puts("")

# ============================================================================
# EXAMPLE 3: 2D PATTERN-BASED OPERATIONS
# ============================================================================
IO.puts("3. 2D PATTERN-BASED OPERATIONS")
IO.puts("===============================")
IO.puts("For 2D variables, you can use patterns like:")
IO.puts("  - max(x[_, j]) - maximum over first dimension")
IO.puts("  - min(x[i, _]) - minimum over second dimension")
IO.puts("  - max(x[_, _]) - maximum over all variables")
IO.puts("")

# Create 2D variables
generators3 = [{:i, :in, [1, 2, 3]}, {:j, :in, [1, 2]}]
problem = Macros.add_variables(problem, generators3, "z", :continuous, "2D continuous variables")

var_map3 = Problem.get_variables_nd(problem, "z")
IO.puts("✓ Created #{map_size(var_map3)} 2D continuous variables:")

Enum.each(var_map3, fn {key, _monomial} ->
  IO.puts("  - z#{inspect(key)}")
end)

IO.puts("")
IO.puts("Pattern examples:")
IO.puts("  • max(z[_, 1]) - max of z[1,1], z[2,1], z[3,1]")
IO.puts("  • min(z[2, _]) - min of z[2,1], z[2,2]")
IO.puts("  • max(z[_, _]) - max of all z variables")
IO.puts("")

# ============================================================================
# EXAMPLE 4: BINARY VARIABLES WITH PATTERNS
# ============================================================================
IO.puts("4. BINARY VARIABLES WITH PATTERNS")
IO.puts("==================================")
IO.puts("Pattern-based operations work with binary variables too:")
IO.puts("  - a[1] AND a[2] AND a[3] AND a[4] → a[_] AND a[_] AND a[_] AND a[_]")
IO.puts("  - b[1] OR b[2] OR b[3] → b[_] OR b[_] OR b[_]")
IO.puts("")

# Create binary variables
generators4 = [{:i, :in, [1, 2, 3, 4]}]
problem = Macros.add_variables(problem, generators4, "a", :binary, "Binary variables")

var_map4 = Problem.get_variables_nd(problem, "a")
IO.puts("✓ Created #{map_size(var_map4)} binary variables:")

Enum.each(var_map4, fn {key, _monomial} ->
  IO.puts("  - a#{inspect(key)}")
end)

IO.puts("")
IO.puts("Pattern-based logical operations:")
IO.puts("  • a[_] AND a[_] AND a[_] AND a[_] - all must be true")
IO.puts("  • b[_] OR b[_] OR b[_] - at least one must be true")
IO.puts("")

# ============================================================================
# EXAMPLE 5: COMPLEX PATTERN COMBINATIONS
# ============================================================================
IO.puts("5. COMPLEX PATTERN COMBINATIONS")
IO.puts("================================")
IO.puts("You can combine patterns with other operations:")
IO.puts("")

examples = [
  "max(x[_]) + min(y[_])",
  "max(x[_, j]) - min(x[i, _])",
  "a[_] AND (b[_] OR c[_])",
  "max(x[_]) * min(y[_])",
  "sum(x[_]) == max(x[_]) * count(x[_])"
]

Enum.each(examples, fn example ->
  IO.puts("  • #{example}")
end)

IO.puts("")

# ============================================================================
# EXAMPLE 6: PRACTICAL USE CASES
# ============================================================================
IO.puts("6. PRACTICAL USE CASES")
IO.puts("=======================")
IO.puts("")

use_cases = [
  {
    "Portfolio Optimization",
    "max(return[_]) - min(risk[_])",
    "Maximize best return while minimizing worst risk across all assets"
  },
  {
    "Facility Location",
    "min(distance[_, customer])",
    "Find minimum distance to any customer across all facilities"
  },
  {
    "Resource Allocation",
    "resource[_] AND resource[_] AND resource[_]",
    "All resources must be available (simplified syntax)"
  },
  {
    "Quality Control",
    "max(quality[_]) AND min(defect[_])",
    "Best quality with fewest defects across all products"
  },
  {
    "Network Optimization",
    "max(flow[_, destination])",
    "Maximum flow to any destination across all sources"
  }
]

Enum.each(use_cases, fn {name, expression, description} ->
  IO.puts("  #{name}:")
  IO.puts("    Expression: #{expression}")
  IO.puts("    Purpose: #{description}")
  IO.puts("")
end)

# ============================================================================
# EXAMPLE 7: SYNTAX COMPARISON
# ============================================================================
IO.puts("7. SYNTAX COMPARISON")
IO.puts("====================")
IO.puts("")

comparisons = [
  {
    "Old Syntax",
    "max(x[1], x[2], x[3], x[4], x[5])",
    "Verbose, error-prone, hard to maintain"
  },
  {
    "New Pattern Syntax",
    "max(x[_])",
    "Concise, clear, automatically scales"
  },
  {
    "Old Syntax",
    "min(y[1], y[2], y[3])",
    "Must list all variables explicitly"
  },
  {
    "New Pattern Syntax",
    "min(y[_])",
    "Automatically includes all y variables"
  },
  {
    "Old Syntax",
    "a[1] AND a[2] AND a[3] AND a[4]",
    "Repetitive, easy to miss variables"
  },
  {
    "New Pattern Syntax",
    "a[_] AND a[_] AND a[_] AND a[_]",
    "Still explicit but more concise"
  }
]

Enum.each(comparisons, fn {type, syntax, note} ->
  IO.puts("  #{type}:")
  IO.puts("    #{syntax}")
  IO.puts("    #{note}")
  IO.puts("")
end)

IO.puts("🎉 Pattern-based operations make optimization modeling much more elegant!")
IO.puts("")
IO.puts("KEY BENEFITS:")
IO.puts("• Concise syntax: max(x[_]) instead of max(x[1], x[2], ..., x[n])")
IO.puts("• Automatic scaling: works with any number of variables")
IO.puts("• Less error-prone: no need to list variables explicitly")
IO.puts("• More readable: intent is clearer")
IO.puts("• Maintainable: adding variables doesn't require code changes")
IO.puts("• Flexible: supports complex patterns like x[_, j] or x[i, _]")
IO.puts("")

# ============================================================================
# EXAMPLE 8: 4D PATTERN-BASED OPERATIONS (busy[i, j, k, l])
# ============================================================================
IO.puts("8. 4D PATTERN-BASED OPERATIONS (busy[i, j, k, l])")
IO.puts("===================================================")
IO.puts("Demonstrates patterns with four indices:")
IO.puts("  - max(busy[_, j, k, l])   # max over i dimension")
IO.puts("  - min(busy[i, _, k, l])   # min over j dimension")
IO.puts("  - max(busy[i, j, _, l])   # max over k dimension")
IO.puts("  - min(busy[i, j, k, _])   # min over l dimension")
IO.puts("  - max(busy[_, _, _, _])   # max across all 4D entries")
IO.puts("")

# Create 4D variables busy[i, j, k, l]
generators5 = [
  {:i, :in, [1, 2]},
  {:j, :in, [1, 2]},
  {:k, :in, [1, 2]},
  {:l, :in, [1, 2]}
]

problem = Macros.add_variables(problem, generators5, "busy", :continuous, "4D busy variables")

var_map5 = Problem.get_variables_nd(problem, "busy")
IO.puts("✓ Created #{map_size(var_map5)} 4D continuous variables:")

Enum.each(var_map5, fn {key, _monomial} ->
  IO.puts("  - busy#{inspect(key)}")
end)

IO.puts("")
IO.puts("Pattern examples (4D):")
IO.puts("  • max(busy[_, 1, 2, 1]) - over i: busy[1,1,2,1], busy[2,1,2,1]")
IO.puts("  • min(busy[2, _, 1, 1]) - over j: busy[2,1,1,1], busy[2,2,1,1]")
IO.puts("  • max(busy[1, 2, _, 2]) - over k: busy[1,2,1,2], busy[1,2,2,2]")
IO.puts("  • min(busy[1, 1, 2, _]) - over l: busy[1,1,2,1], busy[1,1,2,2]")
IO.puts("  • max(busy[_, _, _, _]) - max of all 16 busy variables")
IO.puts("")
