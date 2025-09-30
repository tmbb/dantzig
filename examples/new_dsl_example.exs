# Example demonstrating the modern DSL syntax
# This shows the clean, modern approach to building optimization problems

require Dantzig.Problem, as: Problem

IO.puts("=== Modern DSL Example ===")

# Create a problem with metadata
problem = Problem.new(
  name: "Simple Test",
  description: "Testing the modern DSL syntax"
)

IO.puts("Created problem: #{problem.name}")
IO.puts("Description: #{problem.description}")

# Add variables using the modern DSL syntax
problem = Problem.variables(problem, "x", [i <- 1..2, j <- 1..2], :binary, description: "Test variables")

IO.puts("Added variables:")
var_map = Problem.get_variables_nd(problem, "x")
IO.puts("Variable map keys: #{inspect(Map.keys(var_map))}")

# Test the sum function (placeholder)
# Note: x[_, _] syntax will be implemented as a macro
# For now, we'll just test the basic structure
IO.puts("Variables created: #{map_size(var_map)}")

IO.puts("\n=== Modern DSL structure working! ===")
IO.puts("Next steps: Implement constraint and objective parsing")
