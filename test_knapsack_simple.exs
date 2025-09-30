#!/usr/bin/env elixir

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Simple test without map access
items = ["laptop", "book", "camera"]
weights = [3, 1, 2]
values = [10, 3, 6]
capacity = 5

IO.puts("Simple Knapsack Test")

problem = Problem.define do
  new(name: "Simple Knapsack")

  variables("select", [i <- items], :binary, "Select item")

  constraints(
    sum(for i <- items, do: select(i) * Enum.at(weights, Enum.find_index(items, &(&1 == i)))) <= capacity,
    "Weight constraint"
  )

  objective(
    sum(for i <- items, do: select(i) * Enum.at(values, Enum.find_index(items, &(&1 == i)))),
    direction: :maximize
  )
end

IO.puts("Problem created successfully!")
IO.puts("Variables: #{inspect(Problem.get_variables(problem))}")
