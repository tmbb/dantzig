# Simple test for DSL functionality
require Dantzig.Problem, as: Problem

IO.puts("Testing DSL functionality...")

# Test basic problem creation
try do
  problem =
    Problem.define do
      new(direction: :maximize)
      variables("x", :continuous, min: 0)
      constraints(x <= 10)
      objective(x)
    end

  IO.puts("✅ Problem creation successful")
  IO.puts("Variables: #{map_size(problem.variables)}")
  IO.puts("Constraints: #{map_size(problem.constraints)}")
rescue
  error ->
    IO.puts("❌ Problem creation failed: #{inspect(error)}")
end
