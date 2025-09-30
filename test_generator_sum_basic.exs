# Basic test for generator-based sum functionality

# Test 1: Simple generator sum
# sum(x[i] for i <- 1..3) should sum x[1] + x[2] + x[3]

# Test 2: Complex expression
# sum(x[i] * 2 for i <- 1..2) should sum (x[1] * 2) + (x[2] * 2)

# Test 3: Multiple generators
# sum(x[i,j] for i <- 1..2, j <- 1..2) should sum x[1,1] + x[1,2] + x[2,1] + x[2,2]

# Test 4: Diet example syntax
# sum(qty[food] * foods[food]["cost"] for food <- food_names)

# Let's create a simple test case
require Dantzig.Problem, as: Problem

IO.puts("=== Testing Generator-Based Sum Implementation ===")

# Create a simple problem
problem = Problem.new(name: "Test Generator Sum")

# Add variables
problem = Problem.variables(problem, "x", [i <- 1..3], :continuous, description: "Test variables")

IO.puts("Created problem with #{map_size(problem.variables)} variables")

# Test the sum functionality by checking if it compiles
try:
  # This should work now with our new implementation
  sum_expr = quote do: sum(x[i] for i <- 1..3)
  IO.puts("Sum expression created: #{inspect(sum_expr)}")

  # Try to parse it
  parsed = Dantzig.AST.Parser.parse_expression(sum_expr)
  IO.puts("Parsed successfully: #{inspect(parsed)}")

  # Try to transform it
  {final_problem, result} = Dantzig.AST.Transformer.transform_expression(parsed, problem, %{})
  IO.puts("Transformed successfully")
  IO.puts("Result: #{inspect(result)}")

  IO.puts("✅ Basic generator sum test passed!")

catch
  error ->
    IO.puts("❌ Test failed: #{inspect(error)}")
end
