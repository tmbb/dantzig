# N-Queens problem using the new DSL
require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

IO.puts("=== N-Queens DSL No-index Example ===")

# Create the problem
problem2d_simple =
  Problem.define do
    new(
      name: "2-Queens",
      description: "Place queens on an 2x2 chessboard so that no two queens attack each other."
    )

    # Add binary variables for queen positions (2x2 board)
    variables("queen2d_1_1", :binary, "Queen position")
    variables("queen2d_1_2", :binary, "Queen position")
    variables("queen2d_2_1", :binary, "Queen position")
    variables("queen2d_2_2", :binary, "Queen position")

    # Add constraints: one queen per row
    constraints(queen2d_1_1 + queen2d_1_2 == 1, "One queen per row")
    constraints(queen2d_2_1 + queen2d_2_2 == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints(queen2d_1_1 + queen2d_2_1 == 1, "One queen per column")
    constraints(queen2d_1_2 + queen2d_2_2 == 1, "One queen per column")

    # Set objective (squeeze as many queens as possible)
    objective(queen2d_1_1 + queen2d_1_2 + queen2d_2_1 + queen2d_2_2, direction: :maximize)
  end

{solution, objective} = Problem.solve(problem2d_simple, print_optimizer_input: true)

IO.puts("Created problem: #{problem2d_simple.name}")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem2d_simple.variables)}")
IO.puts("Constraints: #{map_size(problem2d_simple.constraints)}")
IO.puts("Objective: #{inspect(problem2d_simple.objective)}")
IO.puts("Direction: #{inspect(problem2d_simple.direction)}")

IO.puts("")
IO.puts("")
IO.puts("")
IO.puts("=== N-Queens DSL Example ===")

# Create the problem
problem2d =
  Problem.define do
    new(
      name: "N-Queens",
      description: "Place N queens on an N×N chessboard so that no two queens attack each other."
    )

    # Add binary variables for queen positions (4x4 board)
    variables("queen2d", [i <- 1..4, j <- 1..4], :binary, "Queen position")

    # Add constraints: one queen per row
    constraints([i <- 1..4], sum(queen2d(i, :_)) == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints([j <- 1..4], sum(queen2d(:_, j)) == 1, "One queen per column")

    # Set objective (squeeze as many queens as possible)
    objective(sum(queen2d(:_, :_)), direction: :maximize)
  end

{solution, objective} = Problem.solve(problem2d, print_optimizer_input: true)

IO.puts("Created problem: #{problem2d.name}")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\nProblem summary:")
IO.puts("Variables: #{map_size(problem2d.variables)}")
IO.puts("Constraints: #{map_size(problem2d.constraints)}")
IO.puts("Objective: #{inspect(problem2d.objective)}")
IO.puts("Direction: #{inspect(problem2d.direction)}")

IO.puts("")
IO.puts("")
IO.puts("")
IO.puts("=== N-Queens DSL Example 2 ===")

# Create the problem
problem3d =
  Problem.define do
    new(
      name: "N-Queens",
      description:
        "Place N queens on an N×N×N chessboard so that no two queens attack each other."
    )

    tap(&IO.puts("Created problem: #{&1.name}"))

    # Add binary variables for queen positions (4x4 board)
    variables("queen3d", [i <- 1..4, j <- 1..4, k <- 1..4], :binary, "Queen position")
    tap(&IO.puts("Variables: #{map_size(&1.variables)}"))

    # Add constraints: one queen per row
    constraints([i <- 1..4, k <- 1..4], sum(queen3d(i, :_, k)) == 1, "One queen per row")

    # Add constraints: one queen per column
    constraints([j <- 1..4, k <- 1..4], sum(queen3d(:_, j, k)) == 1, "One queen per column")

    # Add constraints: one queen per vertical
    constraints([i <- 1..4, j <- 1..4], queen3d(i, j, :_) == 1, "One queen per vertical")
    tap(&IO.puts("Constraints: #{map_size(&1.constraints)}"))

    # Set objective (squeeze as many queens as possible)
    objective([], sum(queen3d(:_, :_, :_)), direction: :maximize)
  end

{solution, objective} = Problem.solve(problem3d)

IO.puts("\nProblem summary:")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\n=== N-Queens problem created with DSL! ===")
IO.puts("Note: This example demonstrates the DSL structure.")
IO.puts("Full constraint parsing with patterns is still being implemented.")

IO.puts("")
IO.puts("")
IO.puts("")
IO.puts("=== Diet Problem DSL Example ===")

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
foods_dict = for food_entry <- foods, do: %{food_entry.name => food_entry}

# Nutritional limits
limits = [
  %{nutrient: "calories", min: 1800, max: 2200},
  %{nutrient: "protein", min: 91, max: :infinity},
  %{nutrient: "fat", min: 0, max: 65},
  %{nutrient: "sodium", min: 0, max: 1779}
]

limits_names = Enum.map(limits, & &1.nutrient)
limits_dict = for limit_entry <- limits, do: %{limit_entry.nutrient => limit_entry}

# create a list of constraints piped one after the other taking each limit entry
# and creating a constraint for each nutrient

# Create the problem
problem_diet =
  Problem.define do
    new(
      name: "Diet Problem",
      description: "Minimize cost of food while meeting nutritional requirements"
    )

    variables(
      "qty",
      [food <- food_names],
      :continuous,
      min: 0.0,
      max: :infinity,
      description: "Amount of food to buy"
    )

    objective(
      sum(for food <- food_names, do: qty(food) * foods[food]["cost"]),
      direction: :minimize
    )

    #
    # We should be able to write any of the following syntaxes:
    #

    # A - Single constraint
    # constraints(
    #     sum( for food <- food_names, do: qty(food) * foods_dict[food]["calories"] ) >= limits_dict["calories"]["min"],
    #     "Min calories")

    # constraints(
    #     sum( for food <- food_names, do: qty(food) * foods_dict[food]["calories"] ) <= limits_dict["calories"]["max"],
    #     "Max calories")

    # B - double constraint (not sure about any existing JuMP syntax)
    # constraints(
    #   sum(qty(food) * foods_dict[food]["calories"] ) between (limits_dict["calories"]["max"], limits_dict["calories"]["max"]),
    #   "Min and max calories")

    # C - Chained constraint
    constraints(
      [l_name <- limits_names],
      sum(for food <- food_names, do: qty(food) * foods_dict[food][l_name]) <=
        limits_dict[l_name]["max"],
      "Min and max #{l_name}"
    )
  end

{solution, objective} = Problem.solve(problem_diet)

IO.puts("\nProblem summary:")
IO.puts("Solution: #{inspect(solution)}")
IO.puts("Objective: #{objective}")

IO.puts("\n=== Diet problem created with DSL! ===")
IO.puts("Note: This example demonstrates the DSL structure.")
IO.puts("Full constraint parsing with patterns is still being implemented.")
