# Comprehensive test for generator-based sum functionality
# This tests all the syntax variations that need to be supported

require Dantzig.Problem, as: Problem
require Dantzig.AST.Parser, as: Parser
require Dantzig.AST.Transformer, as: Transformer

IO.puts("=== Comprehensive Generator Sum Tests ===")

# Test 1: Basic generator sum parsing
IO.puts("\n1. Testing basic generator sum parsing...")

try do
  # Use function call syntax instead of square brackets: sum(x(i), :for, i <- 1..3)
  expr1 = quote do: sum(x(i), :for, i <- 1..3)
  parsed1 = Parser.parse_expression(expr1)
  IO.puts("✅ Basic parsing works: #{inspect(parsed1)}")
rescue
  error -> IO.puts("❌ Basic parsing failed: #{inspect(error)}")
end

# Test 2: Complex expression parsing
IO.puts("\n2. Testing complex expression parsing...")

try do
  expr2 = quote do: sum(x(i) * y(i), :for, i <- 1..2)
  parsed2 = Parser.parse_expression(expr2)
  IO.puts("✅ Complex expression parsing works: #{inspect(parsed2)}")
rescue
  error -> IO.puts("❌ Complex expression parsing failed: #{inspect(error)}")
end

# Test 3: Multiple generators parsing
IO.puts("\n3. Testing multiple generators parsing...")

try do
  expr3 = quote do: sum(x(i, j), :for, [i <- 1..2, j <- 1..2])
  parsed3 = Parser.parse_expression(expr3)
  IO.puts("✅ Multiple generators parsing works: #{inspect(parsed3)}")
rescue
  error -> IO.puts("❌ Multiple generators parsing failed: #{inspect(error)}")
end

# Test 4: Diet example syntax parsing
IO.puts("\n4. Testing diet example syntax parsing...")

try do
  expr4 = quote do: sum(qty(food) * foods(food, "cost"), :for, [food <- food_names])
  parsed4 = Parser.parse_expression(expr4)
  IO.puts("✅ Diet example syntax parsing works: #{inspect(parsed4)}")
rescue
  error -> IO.puts("❌ Diet example syntax parsing failed: #{inspect(error)}")
end

# Test 5: Full problem creation with generator sums
IO.puts("\n5. Testing full problem creation...")

try do
  # Create a simple problem
  problem = Problem.new(name: "Test Problem")

  # Add variables
  problem =
    Problem.variables(problem, "x", [i <- 1..3], :continuous, description: "Test variables")

  # Test constraint with generator sum
  constraint_expr = quote do: sum(x(i), :for, i <- 1..3) == 6
  parsed_constraint = Parser.parse_constraint_expression(constraint_expr)

  IO.puts("✅ Problem creation with generator sums works")
  IO.puts("Problem has #{map_size(problem.variables)} variables")
rescue
  error -> IO.puts("❌ Problem creation failed: #{inspect(error)}")
end

IO.puts("\n=== Test Summary ===")
IO.puts("If all tests pass, the generator-based sum implementation is working correctly!")
