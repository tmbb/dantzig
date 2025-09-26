# Variadic Operations Example
# Demonstrates the enhanced support for variadic operations: max(), min(), and(), or()

require Dantzig.Problem, as: Problem
require Dantzig.DSL, as: Macros

IO.puts("=== VARIADIC OPERATIONS DEMONSTRATION ===")
IO.puts("This example shows how max(), min(), and(), or() can take any number of arguments")
IO.puts("")

# ============================================================================
# EXAMPLE 1: VARIADIC MAX OPERATION
# ============================================================================
IO.puts("1. VARIADIC MAX OPERATION")
IO.puts("=========================")
IO.puts("max(x, y, z, w) creates constraints: result >= x, result >= y, result >= z, result >= w")
IO.puts("")

# Create variables
problem = Problem.new(direction: :minimize)
generators = [{:i, :in, [1, 2, 3]}]
problem = Macros.add_variables(problem, generators, "x", :continuous, "Continuous variables")

# Get the variable map to demonstrate the concept
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("✓ Created #{map_size(var_map)} continuous variables")

# In a real implementation, we would use the AST system like this:
# problem = Macros.add_constraints(problem, [], "x", {:_, :_, :_}, :<=,
#   max(x[1], x[2], x[3]), "Max constraint")

IO.puts("")

# ============================================================================
# EXAMPLE 2: VARIADIC MIN OPERATION
# ============================================================================
IO.puts("2. VARIADIC MIN OPERATION")
IO.puts("=========================")
IO.puts("min(x, y, z, w) creates constraints: result <= x, result <= y, result <= z, result <= w")
IO.puts("")

# In a real implementation:
# problem = Macros.add_constraints(problem, [], "x", {:_, :_, :_}, :>=,
#   min(x[1], x[2], x[3]), "Min constraint")

IO.puts("✓ Min operation would create constraints: result <= each argument")
IO.puts("")

# ============================================================================
# EXAMPLE 3: VARIADIC AND OPERATION
# ============================================================================
IO.puts("3. VARIADIC AND OPERATION")
IO.puts("==========================")
IO.puts("x AND y AND z AND w creates constraints:")
IO.puts("  - result <= x, result <= y, result <= z, result <= w")
IO.puts("  - result >= sum(x, y, z, w) - (n-1) where n is number of arguments")
IO.puts("")

# Create binary variables for AND demonstration
problem2 = Problem.new(direction: :minimize)
generators2 = [{:i, :in, [1, 2, 3, 4]}]
problem2 = Macros.add_variables(problem2, generators2, "b", :binary, "Binary variables")

var_map2 = Problem.get_variables_nd(problem2, "b")
IO.puts("✓ Created #{map_size(var_map2)} binary variables")

# In a real implementation:
# problem = Macros.add_constraints(problem, [], "b", {:_, :_, :_}, :==,
#   b[1] AND b[2] AND b[3] AND b[4], "All must be true")

IO.puts("✓ AND operation would ensure all variables are 1")
IO.puts("")

# ============================================================================
# EXAMPLE 4: VARIADIC OR OPERATION
# ============================================================================
IO.puts("4. VARIADIC OR OPERATION")
IO.puts("=========================")
IO.puts("x OR y OR z OR w creates constraints:")
IO.puts("  - result >= x, result >= y, result >= z, result >= w")
IO.puts("  - result <= sum(x, y, z, w)")
IO.puts("")

# In a real implementation:
# problem = Macros.add_constraints(problem, [], "b", {:_, :_, :_}, :==,
#   b[1] OR b[2] OR b[3] OR b[4], "At least one must be true")

IO.puts("✓ OR operation would ensure at least one variable is 1")
IO.puts("")

# ============================================================================
# EXAMPLE 5: COMPLEX COMBINATIONS
# ============================================================================
IO.puts("5. COMPLEX COMBINATIONS")
IO.puts("========================")
IO.puts("You can combine variadic operations:")
IO.puts("")

# Example combinations that would be supported:
examples = [
  "max(x[1], x[2], x[3], x[4])",
  "min(y[1], y[2], y[3])",
  "a[1] AND a[2] AND a[3] AND a[4] AND a[5]",
  "b[1] OR b[2] OR b[3]",
  "max(min(x[1], x[2]), min(x[3], x[4]))",
  "a[1] AND (b[1] OR b[2] OR b[3])"
]

Enum.each(examples, fn example ->
  IO.puts("  • #{example}")
end)

IO.puts("")

# ============================================================================
# EXAMPLE 6: LINEARIZATION BENEFITS
# ============================================================================
IO.puts("6. LINEARIZATION BENEFITS")
IO.puts("==========================")
IO.puts("All these operations are automatically linearized:")
IO.puts("")

benefits = [
  "✓ max(x, y, z) → creates auxiliary variable + constraints",
  "✓ min(x, y, z) → creates auxiliary variable + constraints",
  "✓ x AND y AND z → creates auxiliary binary variable + constraints",
  "✓ x OR y OR z → creates auxiliary binary variable + constraints",
  "✓ Nested combinations → all automatically linearized",
  "✓ Any number of arguments → scales automatically"
]

Enum.each(benefits, fn benefit ->
  IO.puts("  #{benefit}")
end)

IO.puts("")

# ============================================================================
# EXAMPLE 7: PRACTICAL USE CASES
# ============================================================================
IO.puts("7. PRACTICAL USE CASES")
IO.puts("=======================")
IO.puts("")

use_cases = [
  {
    "Portfolio Optimization",
    "max(return1, return2, return3, return4) - min(risk1, risk2, risk3)",
    "Maximize best return while minimizing worst risk"
  },
  {
    "Facility Location",
    "min(distance1, distance2, distance3, distance4)",
    "Find minimum distance to any facility"
  },
  {
    "Resource Allocation",
    "resource1 AND resource2 AND resource3",
    "All resources must be available"
  },
  {
    "Backup Systems",
    "system1 OR system2 OR system3",
    "At least one system must be working"
  },
  {
    "Quality Control",
    "max(quality1, quality2) AND min(defect1, defect2)",
    "Best quality with fewest defects"
  }
]

Enum.each(use_cases, fn {name, expression, description} ->
  IO.puts("  #{name}:")
  IO.puts("    Expression: #{expression}")
  IO.puts("    Purpose: #{description}")
  IO.puts("")
end)

IO.puts("🎉 Variadic operations provide powerful, flexible modeling capabilities!")
IO.puts("")
IO.puts("KEY ADVANTAGES:")
IO.puts("• Natural mathematical syntax")
IO.puts("• Automatic linearization")
IO.puts("• Scalable to any number of arguments")
IO.puts("• Composable with other operations")
IO.puts("• No manual constraint creation needed")
