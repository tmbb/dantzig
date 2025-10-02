# Dantzig DSL Comprehensive Tutorial

## 🎯 Overview

This comprehensive tutorial covers all aspects of using the Dantzig DSL for mathematical optimization. The DSL provides an intuitive, mathematical syntax for defining optimization problems with automatic linearization and powerful pattern-based modeling capabilities.

## 📋 Table of Contents

1. [Basic Concepts](#basic-concepts)
2. [Getting Started](#getting-started)
3. [Variable Types and Creation](#variable-types-and-creation)
4. [Constraint Specification](#constraint-specification)
5. [Objective Functions](#objective-functions)
6. [Pattern-Based Modeling](#pattern-based-modeling)
7. [Advanced Features](#advanced-features)
8. [Real-World Examples](#real-world-examples)
9. [Best Practices](#best-practices)
10. [Troubleshooting](#troubleshooting)

## 🔧 Basic Concepts

### What is Dantzig?

Dantzig is an Elixir library for **Linear and Mixed-Integer Programming** that provides:

- **Clean DSL** for modeling optimization problems
- **Automatic linearization** of non-linear expressions
- **Pattern-based modeling** for N-dimensional problems
- **HiGHS solver integration** for high-performance optimization

### Key Features

- **Multiple modeling styles**: Explicit, pattern-based, and simple syntax
- **Automatic linearization**: `abs()`, `max()`, `min()` become linear constraints
- **N-dimensional variables**: `x[i,j]` for `i <- 1..8, j <- 1..8`
- **Symbolic algebra**: Automatic polynomial simplification
- **Comprehensive validation**: Solution and constraint verification

## 🚀 Getting Started

### Installation

Add Dantzig to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:dantzig, "~> 0.2.0"}
  ]
end
```

### Basic Problem Structure

Every Dantzig problem follows this structure:

```elixir
require Dantzig.Problem, as: Problem

problem =
  Problem.define do
    new(direction: :maximize)  # or :minimize

    # Variables
    variables("x", :continuous, min: 0, max: 10)
    variables("y", :binary, description: "Binary decision")

    # Constraints
    constraints(x + 2*y <= 10, "Resource constraint")
    constraints(x >= 0, "Non-negativity")

    # Objective
    objective(3*x + 4*y, direction: :maximize)
  end

# Solve the problem
{:ok, solution} = Dantzig.solve(problem)
```

## 📊 Variable Types and Creation

### Variable Types

Dantzig supports several variable types:

```elixir
# Continuous variables (default)
variables("x", :continuous, min: 0, max: 100)

# Binary variables (0 or 1)
variables("y", :binary, description: "Yes/no decision")

# Integer variables
variables("z", :integer, min: 0, max: 50)
```

### Variable Options

```elixir
variables("product",
  [p <- products],           # Pattern-based creation
  :integer,                  # Variable type
  min: 0,                    # Lower bound
  max: 100,                  # Upper bound
  description: "Production quantity"
)
```

### Simple Variable Creation

For individual variables:

```elixir
# Simple named variables
variables("cost", :continuous, min: 0)
variables("profit", :continuous, max: 1000)
variables("selected", :binary, description: "Selection flag")
```

## 🔒 Constraint Specification

### Basic Constraints

```elixir
# Simple linear constraints
constraints(x + 2*y <= 10, "Resource limit")
constraints(3*x - y >= 5, "Minimum requirement")
constraints(x == y, "Equality constraint")
```

### Pattern-Based Constraints

For N-dimensional problems:

```elixir
# One constraint per index
constraints([i <- 1..5], sum(x(i, :_)) <= capacity, "Row capacity")

# One constraint per combination
constraints([i <- 1..3, j <- 1..3], x(i, j) <= demand[i], "Demand limit")
```

### Advanced Constraint Patterns

```elixir
# Complex constraints with multiple indices
constraints(
  [i <- 1..n, j <- 1..m],
  sum(for k <- 1..k, do: x(i, k)) >= demand[i][j],
  "Complex demand constraint"
)
```

## 🎯 Objective Functions

### Basic Objectives

```elixir
# Maximize profit
objective(5*x + 3*y + 2*z, direction: :maximize)

# Minimize cost
objective(total_cost, direction: :minimize)
```

### Complex Objectives

```elixir
# Multi-dimensional objective
objective(
  sum(for i <- 1..n, j <- 1..m, do: profit[i][j] * x(i, j)),
  direction: :maximize
)
```

## 🔄 Pattern-Based Modeling

### N-Dimensional Variables

```elixir
# 2D variables: x[i,j] for i=1..3, j=1..4
variables("x", [i <- 1..3, j <- 1..4], :binary, "Assignment variable")

# 3D variables: y[i,j,k] for multi-dimensional problems
variables("y", [i <- 1..2, j <- 1..3, k <- 1..4], :continuous)
```

### Generator Syntax

```elixir
# Simple ranges
[i <- 1..5]                    # i = 1, 2, 3, 4, 5
[j <- ["A", "B", "C"]]         # j = "A", "B", "C"

# Complex generators
[k <- 1..10, k != 5]           # k = 1, 2, 3, 4, 6, 7, 8, 9, 10
[m <- Enum.map(data, & &1.id)] # Dynamic lists
```

### Variable Access Patterns

```elixir
# Access specific indices
x(1, 2)        # x[1,2]
x(i, :_)       # sum over second index for fixed first index
x(:_, j)       # sum over first index for fixed second index
x(:_, :_)      # sum over all indices
```

## ⚡ Advanced Features

### Automatic Linearization

Dantzig automatically converts non-linear expressions to linear constraints:

```elixir
# These become linear constraints automatically:
constraints(abs(x) <= 5, "Absolute value")
constraints(max(x, y, z) >= 10, "Maximum value")
constraints(min(x, y) == 0, "Minimum value")
```

### Expression Operators

```elixir
# Arithmetic operators
x + y          # Addition
x - y          # Subtraction
x * 2          # Multiplication by constant
x / 3          # Division by constant

# Comparison operators in constraints
x <= y         # Less than or equal
x >= y         # Greater than or equal
x == y         # Equal
```

## 🌍 Real-World Examples

### 1. Knapsack Problem

```elixir
require Dantzig.Problem, as: Problem

items = ["laptop", "book", "camera", "phone", "headphones"]
values = %{laptop: 10, book: 3, camera: 6, phone: 4, headphones: 2}
weights = %{laptop: 3, book: 1, camera: 2, phone: 1, headphones: 1}
capacity = 5

problem =
  Problem.define do
    new(direction: :maximize)

    variables("select", [item <- items], :binary, "Item selection")

    constraints(
      sum(for item <- items, do: select(item) * weights[item]) <= capacity,
      "Weight capacity"
    )

    objective(
      sum(for item <- items, do: select(item) * values[item]),
      direction: :maximize
    )
  end
```

### 2. Assignment Problem

```elixir
workers = ["Alice", "Bob", "Charlie"]
tasks = ["Task1", "Task2", "Task3"]
costs = %{
  "Alice" => %{"Task1" => 2, "Task2" => 3, "Task3" => 1},
  "Bob" => %{"Task1" => 4, "Task2" => 2, "Task3" => 3},
  "Charlie" => %{"Task1" => 3, "Task2" => 1, "Task3" => 4}
}

problem =
  Problem.define do
    new(direction: :minimize)

    variables("assign", [w <- workers, t <- tasks], :binary, "Assignment")

    # Each worker assigned to exactly one task
    constraints([w <- workers], sum(assign(w, :_)) == 1, "Worker constraint")

    # Each task assigned to exactly one worker
    constraints([t <- tasks], sum(assign(:_, t)) == 1, "Task constraint")

    objective(
      sum(for w <- workers, t <- tasks, do: assign(w, t) * costs[w][t]),
      direction: :minimize
    )
  end
```

### 3. Production Planning

```elixir
periods = [1, 2, 3, 4]
demand = %{1 => 100, 2 => 150, 3 => 80, 4 => 200}
production_cost = %{1 => 10, 2 => 12, 3 => 11, 4 => 13}
holding_cost = 2
initial_inventory = 50

problem =
  Problem.define do
    new(direction: :minimize)

    variables("produce", [t <- periods], :continuous, min: 0, max: 250)
    variables("inventory", [t <- periods], :continuous, min: 0)

    # Inventory balance constraints
    constraints([t <- [1]], produce(t) - demand[1] == -initial_inventory)
    constraints([t <- 2..4], inventory(t-1) + produce(t) - demand[t] == 0)

    objective(
      sum(for t <- periods, do: produce(t) * production_cost[t] + inventory(t) * holding_cost),
      direction: :minimize
    )
  end
```

## 📚 Best Practices

### 1. Problem Structure

```elixir
# Use descriptive names
variables("production_quantity", [product <- products], :continuous)
constraints(total_production <= max_capacity, "Production capacity")

# Add descriptions for clarity
variables("x", :binary, description: "Include item in solution")
```

### 2. Constraint Organization

```elixir
# Group related constraints
constraints([i <- 1..n], sum(x(i, :_)) == 1, "Row coverage")
constraints([j <- 1..m], sum(x(:_, j)) == 1, "Column coverage")
```

### 3. Variable Bounds

```elixir
# Set appropriate bounds to improve solver performance
variables("quantity", :integer, min: 0, max: 1000)
variables("percentage", :continuous, min: 0, max: 1)
```

### 4. Expression Simplification

```elixir
# Use simple expressions when possible
constraints(x + y <= 10)  # Instead of: x <= 10 - y

# Factor constants
constraints(2*x + 4*y <= 20)  # Instead of: x + 2*y <= 10
```

## 🔍 Troubleshooting

### Common Issues

**1. Variable Not Found**

```elixir
# Problem: Undefined variable 'x'
# Solution: Make sure variable is created before use
variables("x", :continuous)  # Create first
constraints(x <= 10)         # Then use
```

**2. Complex Expressions in Constraints**

```elixir
# Problem: sum() expressions in simple constraints
# Solution: Use pattern-based constraints
constraints([i <- 1..n], sum(x(i, :_)) <= capacity)
```

**3. Type Mismatches**

```elixir
# Problem: Mixing variable types
# Solution: Ensure consistent types in expressions
variables("x", :continuous)
variables("y", :continuous)  # Both same type
constraints(x + y <= 10)     # Compatible
```

### Debugging Tips

```elixir
# Enable solver output for debugging
{:ok, solution} = Dantzig.solve(problem, print_optimizer_input: true)

# Check solution status
IO.puts("Status: #{solution.model_status}")
IO.puts("Objective: #{solution.objective}")

# Validate constraints
IO.puts("Feasibility: #{solution.feasibility}")
```

## 🎓 Learning Path

### Beginner

1. Start with simple linear programs
2. Learn basic variable and constraint syntax
3. Practice with 2-3 variable problems

### Intermediate

1. Master pattern-based modeling
2. Work with N-dimensional problems
3. Understand automatic linearization

### Advanced

1. Complex multi-dimensional constraints
2. Time-series and inventory problems
3. Large-scale optimization scenarios

## 📞 Support and Resources

- **Documentation**: Comprehensive guides in `docs/` directory
- **Examples**: Runnable examples in the `examples/` directory
- **Tests**: Test suites demonstrating usage patterns
- **Community**: GitHub issues and discussions

---

**Ready to optimize?** Start with the [Getting Started Guide](GETTING_STARTED.md) or explore the [Examples](../examples/) directory!

## Related Documentation

- **[Getting Started](GETTING_STARTED.md)** - Basic setup and first example
- **[Architecture Guide](ARCHITECTURE.md)** - System design and internals
- **[Pattern-based Operations](PATTERN_BASED_OPERATIONS.md)** - Advanced pattern features
- **[Variadic Operations](VARIADIC_OPERATIONS.md)** - Variadic function support
- **[Macro Guide](README_MACROS.md)** - Macro system documentation
