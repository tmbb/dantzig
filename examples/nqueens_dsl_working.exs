# N-Queens problem using the new DSL
require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL
require Dantzig.Problem.Math, as: Math

# Import DSL components
use Dantzig.DSL.Integration
import Dantzig.DSL.Integration, only: [enable_variable_access: 1]

# Enable variable access for the variables we'll use
enable_variable_access("queen2d")
enable_variable_access("queen3d")
enable_variable_access("qty")

IO.puts("=== N-Queens DSL Example ===")

# Create the problem
problem2d =
  Problem.new(
    name: "N-Queens",
    description: "Place N queens on an N×N chessboard so that no two queens attack each other."
  )
  # Add binary variables for queen positions (4x4 board)
  |> Problem.variables("queen2d", [{:<-, [], [quote(do: i), 1..4]}, {:<-, [], [quote(do: j), 1..4]}], :binary, description: "Queen position")
  # Add constraints: one queen per row
  |> Problem.constraints([{:<-, [], [quote(do: i), 1..4]}], quote(do: queen2d(i, :_) == 1), "One queen per row")
  # Add constraints: one queen per column
  |> Problem.constraints([{:<-, [], [quote(do: j), 1..4]}], quote(do: queen2d(:_, j) == 1), "One queen per column")
  # Set objective (minimize total number of queens (should be 4))
  |> Problem.objective(quote(do: sum(queen2d(:_, :_))), direction: :minimize)

IO.puts("Created problem: #{problem2d.name}")
IO.puts("Variables: #{map_size(problem2d.variables)}")
IO.puts("Constraints: #{map_size(problem2d.constraints)}")
IO.puts("Objective: #{inspect(problem2d.objective)}")
IO.puts("Direction: #{inspect(problem2d.direction)}")

IO.puts("\n=== N-Queens DSL Example 2 ===")

# Create the problem
problem3d =
  Problem.new(
    name: "N-Queens-3D",
    description: "Place N queens on an N×N×N chessboard so that no two queens attack each other."
  )
  |> tap(&IO.puts("Created problem: #{&1.name}"))

  # Add binary variables for queen positions (4x4x4 board)
  |> Problem.variables("queen3d", [{:<-, [], [quote(do: i), 1..4]}, {:<-, [], [quote(do: j), 1..4]}, {:<-, [], [quote(do: k), 1..4]}], :binary, description: "Queen position")
  |> tap(&IO.puts("Variables: #{map_size(&1.variables)}"))

  # Add constraints: one queen per row
  |> Problem.constraints([{:<-, [], [quote(do: i), 1..4]}, {:<-, [], [quote(do: k), 1..4]}], quote(do: queen3d(i, :_, k) == 1), "One queen per row")
  # Add constraints: one queen per column
  |> Problem.constraints([{:<-, [], [quote(do: j), 1..4]}, {:<-, [], [quote(do: k), 1..4]}], quote(do: queen3d(:_, j, k) == 1), "One queen per column")
  # Add constraints: one queen per vertical
  |> Problem.constraints([{:<-, [], [quote(do: i), 1..4]}, {:<-, [], [quote(do: j), 1..4]}], quote(do: queen3d(i, j, :_) == 1), "One queen per vertical")
  |> tap(&IO.puts("Constraints: #{map_size(&1.constraints)}"))

  # Set objective (minimize total number of queens)
  |> Problem.objective(quote(do: sum(queen3d(:_, :_, :_))), direction: :minimize)

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem3d.variables)}")
IO.puts("Constraints: #{map_size(problem3d.constraints)}")
IO.puts("Objective: #{inspect(problem3d.objective)}")
IO.puts("Direction: #{inspect(problem3d.direction)}")

IO.puts("\n=== N-Queens problem created with DSL! ===")
IO.puts("Note: This example demonstrates the DSL structure.")
IO.puts("Full constraint parsing with patterns is still being implemented.")

IO.puts("\n=== Diet Problem DSL Example ===")

# Food data
foods = [
  %{name: "hamburger", cost: 2.49, calories: 410, protein: 24, fat: 26, sodium: 730},
  %{name: "chicken", cost: 2.89, calories: 420, protein: 32, fat: 10, sodium: 1190},
  %{name: "hot dog", cost: 1.50, calories: 560, protein: 20, fat: 32, sodium: 1800},
  %{name: "fries", cost: 1.89, calories: 380, protein: 4, fat: 19, sodium: 270},
  %{name: "macaroni", cost: 2.09, calories: 320, protein: 12, fat: 10, sodium: 930},
  %{name: "pizza", cost: 1.99, calories: 320, protein: 15, fat: 12, sodium: 820},
  %{name: "salad", cost: 2.49, calories: 320, protein: 31, fat: 12, sodium: 1230},
  %{name: "milk", cost: 0.89, calories: 100, protein: 8, fat: 2.5, sodium: 125},
  %{name: "ice cream", cost: 1.59, calories: 330, protein: 8, fat: 10, sodium: 180}
]
food_names = Enum.map(foods, & &1.name)
foods_dict = for food_entry <- foods, into: %{}, do: {food_entry.name, food_entry}

# Nutritional limits
limits = [
  %{nutrient: "calories", min: 1800, max: 2200},
  %{nutrient: "protein", min: 91, max: :infinity},
  %{nutrient: "fat", min: 0, max: 65},
  %{nutrient: "sodium", min: 0, max: 1779}
]
limits_names = Enum.map(limits, & &1.nutrient)
limits_dict = for limit_entry <- limits, into: %{}, do: {limit_entry.nutrient, limit_entry}

# Create the problem
problem_diet =
  Problem.new(
    name: "Diet Problem",
    description: "Minimize cost of food while meeting nutritional requirements"
  )
  |> Problem.variables(
    "qty", 
    [{:<-, [], [quote(do: food), food_names]}],
    :continuous,
    min: 0.0, max: :infinity,
    description: "Amount of food to buy"
  )
  # Note: The objective with generator syntax would need special handling
  # For now, we'll use a simple sum
  |> Problem.objective(quote(do: sum(qty(food))), direction: :minimize)

IO.puts("Created problem: #{problem_diet.name}")
IO.puts("Foods: #{inspect(food_names)}")

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem_diet.variables)}")
IO.puts("Constraints: #{map_size(problem_diet.constraints)}")
IO.puts("Objective: #{inspect(problem_diet.objective)}")
IO.puts("Direction: #{inspect(problem_diet.direction)}")

IO.puts("\n=== Diet problem created with DSL! ===")
IO.puts("Note: This demonstrates the basic structure.")
IO.puts("Full implementation would need coefficient multiplication and complex constraints.")
