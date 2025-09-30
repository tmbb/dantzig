#!/usr/bin/env elixir

# Network Flow Problem Example
#
# Problem: Maximize flow through a 5-node network from source to sink.
# Each arc has a capacity limit, and flow must be conserved at each node.
#
# This is a classic maximum flow problem with flow conservation constraints.

require Dantzig.Problem, as: Problem
require Dantzig.Problem.DSL, as: DSL

# Define the network structure
# S=source, T=sink
nodes = ["S", "A", "B", "C", "T"]

# Network arcs with capacities
arcs = [
  # Source to A: capacity 10
  {"S", "A", 10},
  # Source to B: capacity 8
  {"S", "B", 8},
  # A to B: capacity 4
  {"A", "B", 4},
  # A to C: capacity 6
  {"A", "C", 6},
  # B to C: capacity 5
  {"B", "C", 5},
  # B to T: capacity 7
  {"B", "T", 7},
  # C to T: capacity 12
  {"C", "T", 12}
]

# Create lookup maps for easier access
arc_capacity = for {from, to, cap} <- arcs, into: %{}, do: {{from, to}, cap}
arc_list = for {from, to, _} <- arcs, do: {from, to}

IO.puts("Network Flow Problem")
IO.puts("====================")
IO.puts("Nodes: #{Enum.join(nodes, ", ")}")
IO.puts("Source: S, Sink: T")
IO.puts("")
IO.puts("Network Arcs (from → to: capacity):")

Enum.each(arcs, fn {from, to, capacity} ->
  IO.puts("  #{from} → #{to}: #{capacity} units")
end)

IO.puts("")

# Create the optimization problem
problem =
  Problem.define do
    new(
      name: "Network Flow Problem",
      description: "Maximize flow from source S to sink T"
    )

    # Flow variables: flow[f,t] = units flowing from node f to node t
    # Create variables for each existing arc
    variables(
      "flow",
      [arc <- arcs],
      :continuous,
      min: 0.0,
      max: :infinity,
      description: "Flow on arc #{arc |> elem(0)} → #{arc |> elem(1)}"
    )

    # Capacity constraints: flow cannot exceed arc capacity
    constraints(
      [arc <- arcs],
      flow(arc) <= arc |> elem(2),
      "Capacity constraint for arc #{arc |> elem(0)} → #{arc |> elem(1)}"
    )

    # Flow conservation constraints for intermediate nodes (A, B, C)
    # Flow in = Flow out for each intermediate node
    constraints(
      [n <- ["A", "B", "C"]],
      # Flow into node n
      # Flow out of node n
      sum(for {from, to, _} <- arcs, to == n, do: flow({from, to})) ==
        sum(for {from, to, _} <- arcs, from == n, do: flow({from, to})),
      "Flow conservation at node #{n}"
    )

    # No flow conservation needed for source (S) and sink (T) - they have net flow

    # Objective: maximize total flow into sink (or equivalently, out of source)
    objective(
      sum(for {_, to, _} <- arcs, to == "T", do: flow({to |> elem(0), to |> elem(1)})),
      direction: :maximize
    )
  end

IO.puts("Solving the network flow problem...")
{solution, objective_value} = Problem.solve(problem, print_optimizer_input: false)

IO.puts("Solution:")
IO.puts("=========")
IO.puts("Maximum flow: #{Float.round(objective_value, 2)} units")
IO.puts("")

IO.puts("Flow on each arc:")
total_flow = 0

Enum.each(arcs, fn {from, to, capacity} ->
  var_name = "flow_{#{from}, #{to}}"
  flow_amount = solution.variables[var_name]

  if flow_amount > 0.001 do
    total_flow = total_flow + flow_amount
    utilization = if capacity > 0, do: flow_amount / capacity * 100, else: 0

    IO.puts(
      "  #{from} → #{to}: #{Float.round(flow_amount, 2)}/#{capacity} units (#{Float.round(utilization, 1)}% utilized)"
    )
  else
    IO.puts("  #{from} → #{to}: 0.0/#{capacity} units (0.0% utilized)")
  end
end)

IO.puts("")
IO.puts("Summary:")
IO.puts("  Total flow calculated: #{Float.round(total_flow, 2)}")
IO.puts("  Reported maximum flow: #{Float.round(objective_value, 2)}")
IO.puts("  Flow values match: #{abs(total_flow - objective_value) < 0.001}")

# Validation
if abs(total_flow - objective_value) > 0.001 do
  IO.puts("ERROR: Flow value mismatch!")
  System.halt(1)
end

# Validate capacity constraints
IO.puts("")
IO.puts("Capacity Constraint Validation:")

capacity_violations =
  Enum.filter(arcs, fn {from, to, capacity} ->
    var_name = "flow_{#{from}, #{to}}"
    flow_amount = solution.variables[var_name]
    flow_amount > capacity + 0.001
  end)

if capacity_violations == [] do
  IO.puts("  ✅ All capacity constraints satisfied")
else
  IO.puts("  ❌ Capacity violations found: #{inspect(capacity_violations)}")
  System.halt(1)
end

# Validate flow conservation for intermediate nodes
IO.puts("")
IO.puts("Flow Conservation Validation:")

conservation_violations =
  Enum.filter(["A", "B", "C"], fn node ->
    # Calculate flow in
    flow_in =
      Enum.reduce(arcs, 0, fn {from_node, to_node, _}, acc ->
        if to_node == node do
          var_name = "flow_{#{from_node}, #{to_node}}"
          acc + solution.variables[var_name]
        else
          acc
        end
      end)

    # Calculate flow out
    flow_out =
      Enum.reduce(arcs, 0, fn {from_node, to_node, _}, acc ->
        if from_node == node do
          var_name = "flow_{#{from_node}, #{to_node}}"
          acc + solution.variables[var_name]
        else
          acc
        end
      end)

    abs(flow_in - flow_out) >= 0.001
  end)

if conservation_violations == [] do
  IO.puts("  ✅ Flow conservation satisfied at all intermediate nodes")
else
  IO.puts("  ❌ Flow conservation violations at nodes: #{inspect(conservation_violations)}")
  System.halt(1)
end

# Check source and sink net flow
source_outflow =
  Enum.reduce(nodes, 0, fn to_node, acc ->
    if to_node != "S" do
      var_name = "flow_S_#{to_node}"
      acc + solution.variables[var_name]
    else
      acc
    end
  end)

sink_inflow =
  Enum.reduce(nodes, 0, fn from_node, acc ->
    if from_node != "T" do
      var_name = "flow_#{from_node}_T"
      acc + solution.variables[var_name]
    else
      acc
    end
  end)

IO.puts("")
IO.puts("Network Flow Summary:")
IO.puts("  Source total outflow: #{Float.round(source_outflow, 2)}")
IO.puts("  Sink total inflow: #{Float.round(sink_inflow, 2)}")
IO.puts("  Maximum flow achieved: #{Float.round(objective_value, 2)}")

IO.puts("")
IO.puts("✅ Network flow problem solved successfully!")
