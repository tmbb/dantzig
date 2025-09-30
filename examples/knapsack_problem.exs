#!/usr/bin/env elixir

# Knapsack Problem Example
#
# Problem: Given a set of items, each with a weight and value,
# determine the number of each item to include in a collection
# so that the total weight is less than or equal to a given limit
# and the total value is as large as possible.
#
# This is a classic 0-1 knapsack problem where each item can be
# taken at most once.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
items = [
  %{name: "laptop", weight: 3, value: 10},
  %{name: "book", weight: 1, value: 3},
  %{name: "camera", weight: 2, value: 6},
  %{name: "phone", weight: 1, value: 4},
  %{name: "headphones", weight: 1, value: 2}
]

item_names = for item <- items, do: item.name
items_dict = for item <- items, into: %{}, do: {item.name, item}

capacity = 5

IO.puts("Knapsack Problem")
IO.puts("================")
IO.puts("Items:")

Enum.each(items, fn item ->
  IO.puts("  #{item.name}: weight=#{item.weight}, value=#{item.value}")
end)

IO.puts("Knapsack capacity: #{capacity}")
IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(
      name: "Knapsack Problem",
      description: "Select items to maximize value while respecting weight constraint"
    )

    # Binary variables: x[i] = 1 if item i is selected, 0 otherwise
    variables(
      "select",
      [i <- item_names],
      :binary,
      "Whether to select item"
    )

    # Constraint: total weight must not exceed capacity
    constraints(
      sum(for item <- item_names, do: select(item) * items_dict[item].weight) <= capacity,
      "Weight constraint"
    )

    # Objective: maximize total value
    objective(
      sum(for item <- item_names, do: select(item) * items_dict[item].value),
      direction: :maximize
    )
  end

IO.puts("Solving the knapsack problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value (total value): #{objective_value}")
IO.puts("")

IO.puts("Selected items:")

{total_weight, total_value} =
  Enum.reduce(items, {0, 0}, fn item, {acc_weight, acc_value} ->
    selected = Problem.get_variable_value(solution, "select", {item.name})

    if selected > 0.5 do
      IO.puts("  ✓ #{item.name} (weight: #{item.weight}, value: #{item.value})")
      {acc_weight + item.weight, acc_value + item.value}
    else
      IO.puts("  ✗ #{item.name} (weight: #{item.weight}, value: #{item.value})")
      {acc_weight, acc_value}
    end
  end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total weight: #{total_weight}/#{capacity}")
IO.puts("  Total value: #{total_value}")
IO.puts("  Weight constraint satisfied: #{total_weight <= capacity}")
IO.puts("  Optimal solution: #{total_value == objective_value}")

# Validation
if total_weight > capacity do
  IO.puts("ERROR: Weight constraint violated!")
  System.halt(1)
end

if abs(total_value - objective_value) > 0.001 do
  IO.puts("ERROR: Objective value mismatch!")
  System.halt(1)
end

IO.puts("✅ Knapsack problem solved successfully!")
