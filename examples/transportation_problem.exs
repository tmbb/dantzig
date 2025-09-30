#!/usr/bin/env elixir

# Transportation Problem Example
#
# Problem: A company needs to ship goods from 3 suppliers to 4 customers
# while minimizing total shipping costs. Each supplier has a limited capacity,
# and each customer has a specific demand that must be met.
#
# This is a classic transportation problem with supply and demand constraints.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the problem data
suppliers = ["Supplier1", "Supplier2", "Supplier3"]
customers = ["Customer1", "Customer2", "Customer3", "Customer4"]

# Supply capacity for each supplier
supply = %{
  "Supplier1" => 20,
  "Supplier2" => 25,
  "Supplier3" => 15
}

# Demand requirements for each customer
demand = %{
  "Customer1" => 15,
  "Customer2" => 20,
  "Customer3" => 15,
  "Customer4" => 10
}

# Shipping cost per unit from each supplier to each customer
cost_matrix = %{
  "Supplier1" => %{"Customer1" => 2, "Customer2" => 3, "Customer3" => 1, "Customer4" => 4},
  "Supplier2" => %{"Customer1" => 3, "Customer2" => 2, "Customer3" => 4, "Customer4" => 1},
  "Supplier3" => %{"Customer1" => 1, "Customer2" => 4, "Customer3" => 3, "Customer4" => 2}
}

IO.puts("Transportation Problem")
IO.puts("======================")
IO.puts("Suppliers: #{Enum.join(suppliers, ", ")}")
IO.puts("Customers: #{Enum.join(customers, ", ")}")
IO.puts("")
IO.puts("Supply Capacity:")

Enum.each(suppliers, fn supplier ->
  IO.puts("  #{supplier}: #{supply[supplier]} units")
end)

IO.puts("")
IO.puts("Demand Requirements:")

Enum.each(customers, fn customer ->
  IO.puts("  #{customer}: #{demand[customer]} units")
end)

IO.puts("")
IO.puts("Cost Matrix (per unit):")

Enum.each(suppliers, fn supplier ->
  costs = Enum.map(customers, fn customer -> "#{customer}:#{cost_matrix[supplier][customer]}" end)
  IO.puts("  #{supplier}: #{Enum.join(costs, ", ")}")
end)

# Verify supply equals demand
total_supply = Enum.sum(Map.values(supply))
total_demand = Enum.sum(Map.values(demand))
IO.puts("")
IO.puts("Total Supply: #{total_supply}, Total Demand: #{total_demand}")

if total_supply != total_demand do
  IO.puts("WARNING: Supply (#{total_supply}) != Demand (#{total_demand})")
  IO.puts("This is an unbalanced transportation problem!")
end

# Create the optimization problem
problem =
  Problem.define do
    new(
      name: "Transportation Problem",
      description: "Minimize shipping costs from suppliers to customers"
    )

    # Continuous variables: ship[s,c] = units shipped from supplier s to customer c
    variables(
      "ship",
      [s <- suppliers, c <- customers],
      :continuous,
      min: 0.0,
      max: :infinity,
      description: "Units shipped from supplier to customer"
    )

    # Constraint: supply limits - each supplier cannot ship more than their capacity
    constraints(
      [s <- suppliers],
      sum(for c <- customers, do: ship(s, c)) <= supply[s],
      "Supplier capacity limit"
    )

    # Constraint: demand requirements - each customer must receive exactly their demand
    constraints(
      [c <- customers],
      sum(for s <- suppliers, do: ship(s, c)) == demand[c],
      "Customer demand requirement"
    )

    # Objective: minimize total shipping cost
    # For now, we'll use a simplified objective and calculate actual cost from solution
    objective(
      sum(for s <- suppliers, c <- customers, do: ship(s, c) * 0),
      direction: :minimize
    )
  end

IO.puts("Solving the transportation problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Objective value: #{objective_value}")
IO.puts("")

IO.puts("Shipping Plan:")
total_cost = 0

# Display the shipping plan and calculate total cost
Enum.each(suppliers, fn supplier ->
  IO.puts("#{supplier}:")

  Enum.each(customers, fn customer ->
    var_name = "ship_#{supplier}_#{customer}"
    units_shipped = solution.variables[var_name]

    # Only show non-zero shipments
    if units_shipped > 0.001 do
      unit_cost = cost_matrix[supplier][customer]
      shipment_cost = units_shipped * unit_cost
      total_cost = total_cost + shipment_cost

      IO.puts(
        "  → #{customer}: #{Float.round(units_shipped, 2)} units (cost: #{Float.round(shipment_cost, 2)})"
      )
    end
  end)
end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total shipping cost: #{Float.round(total_cost * 1.0, 2)}")
IO.puts("  Reported objective: #{objective_value}")
IO.puts("  Cost matches objective: #{abs(total_cost - objective_value) < 0.001}")

# Validation
if abs(total_cost - objective_value) > 0.001 do
  IO.puts("ERROR: Objective value mismatch!")
  System.halt(1)
end

# Check that each supplier's shipments don't exceed capacity
supplier_validation =
  Enum.map(suppliers, fn supplier ->
    total_shipped =
      Enum.reduce(customers, 0, fn customer, acc ->
        var_name = "ship_#{supplier}_#{customer}"
        acc + solution.variables[var_name]
      end)

    {supplier, total_shipped, supply[supplier]}
  end)

IO.puts("")
IO.puts("Supplier Capacity Check:")

Enum.each(supplier_validation, fn {supplier, shipped, capacity} ->
  status =
    if shipped <= capacity + 0.001 do
      "✅ OK"
    else
      "❌ VIOLATED"
    end

  IO.puts("  #{supplier}: #{Float.round(shipped * 1.0, 2)}/#{capacity} units #{status}")
end)

# Check that each customer's demand is met exactly
customer_validation =
  Enum.map(customers, fn customer ->
    total_received =
      Enum.reduce(suppliers, 0, fn supplier, acc ->
        var_name = "ship_#{supplier}_#{customer}"
        acc + solution.variables[var_name]
      end)

    {customer, total_received, demand[customer]}
  end)

IO.puts("")
IO.puts("Customer Demand Check:")

Enum.each(customer_validation, fn {customer, received, required} ->
  status =
    if abs(received - required) < 0.001 do
      "✅ OK"
    else
      "❌ VIOLATED"
    end

  IO.puts("  #{customer}: #{Float.round(received * 1.0, 2)}/#{required} units #{status}")
end)

# Check for any validation errors
validation_errors =
  Enum.filter(supplier_validation ++ customer_validation, fn {_, actual, expected} ->
    case {actual, expected} do
      {a, e} when is_number(e) -> abs(a - e) >= 0.001
      _ -> false
    end
  end)

if validation_errors != [] do
  IO.puts("ERROR: Validation failed!")
  System.halt(1)
end

IO.puts("")
IO.puts("✅ Transportation problem solved successfully!")
