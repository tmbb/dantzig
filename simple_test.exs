# Simple test for generator sum functionality
require Dantzig.AST.Parser, as: Parser

IO.puts("Testing generator sum parsing...")

# Test the new syntax: sum(expr, :for, generators)
try do
  expr = quote do: sum(x(i), :for, i <- 1..3)
  parsed = Parser.parse_expression(expr)
  IO.puts("✅ Parsing successful: #{inspect(parsed)}")
rescue
  error ->
    IO.puts("❌ Parsing failed: #{inspect(error)}")
    IO.puts("Expression was: #{inspect(expr)}")
end
