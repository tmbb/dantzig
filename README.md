# Dantzig

[![Hex.pm](https://img.shields.io/hexpm/v/dantzig.svg)](https://hex.pm/packages/dantzig)
[![Hex.pm](https://img.shields.io/hexpm/dt/dantzig.svg)](https://hex.pm/packages/dantzig)
[![Build Status](https://github.com/tmbb/dantzig/workflows/CI/badge.svg)](https://github.com/tmbb/dantzig/actions)

**Mathematical Optimization for Elixir** — Write optimization problems naturally, like mathematical notation, with automatic linearization and powerful pattern-based modeling.

```elixir
require Dantzig.Problem, as: Problem

# Pattern-based N-dimensional modeling
problem =
  Problem.define do
    new(direction: :maximize)

    # Create x[i,j] for i=1..8, j=1..8 — that's 64 variables in one line!
    variables("x", [i <- 1..8, j <- 1..8], :binary, "Queen position")

    # One queen per row: sum over j for each i
    constraints([i <- 1..8], sum(x(i, :_)) == 1, "One queen per row")

    # One queen per column: sum over i for each j
    constraints([j <- 1..8], sum(x(:_, j)) == 1, "One queen per column")

    # Maximize queens placed (will be 8 for valid N-Queens solution)
    objective(sum(x(:_, :_)), direction: :maximize)
  end

{:ok, solution} = Dantzig.solve(problem)
```

## ✨ What Makes Dantzig Special

**Pattern-Based Modeling**: Create N-dimensional variables with intuitive generator syntax

```elixir
# Instead of manually creating x11, x12, x13, x21, x22, x23, ...
variables("x", [i <- 1..3, j <- 1..3], :binary)

# Use natural patterns: x(i, :_) sums over second dimension
constraints([i <- 1..3], sum(x(i, :_)) == 1, "Row constraint")
```

**Automatic Linearization**: Non-linear expressions become linear constraints automatically

```elixir
# These work out of the box — no manual linearization needed!
constraints(abs(x) + max(x, y, z) <= 5, "Non-linear with auto-linearization")
constraints(a AND b AND c, "Logical AND constraint")
```

**Multiple Modeling Styles**: Choose the approach that fits your problem

- **Simple syntax** for basic problems
- **Pattern-based** for N-dimensional problems
- **Explicit control** when you need it
- **AST transformations** for advanced use cases

## 🚀 Quick Start

### Installation

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:dantzig, "~> 0.2.0"}
  ]
end
```

### Your First Problem

```elixir
require Dantzig.Problem, as: Problem

problem =
  Problem.define do
    new(direction: :maximize)

    variables("x", :continuous, min: 0, description: "Items to produce")
    variables("y", :continuous, min: 0, description: "Items to sell")

    constraints(x + 2*y <= 14, "Resource constraint")
    constraints(3*x - y <= 0, "Quality constraint")

    objective(3*x + 4*y, direction: :maximize)
  end

{:ok, solution} = Dantzig.solve(problem)
IO.inspect({solution.objective, solution.variables})
```

## 📖 Documentation & Learning

| Level               | Guide                                          | Description                     |
| ------------------- | ---------------------------------------------- | ------------------------------- |
| 🏃 **Beginner**     | [Getting Started](docs/GETTING_STARTED.md)     | Your first optimization problem |
| 📚 **Intermediate** | [DSL Tutorial](docs/COMPREHENSIVE_TUTORIAL.md) | Complete guide with examples    |
| 🏗️ **Advanced**     | [Architecture](docs/ARCHITECTURE.md)           | System design deep dive         |
| 🔧 **Reference**    | [API Docs](https://hexdocs.pm/dantzig)         | Complete function reference     |

**Generate full docs locally:**

```bash
mix docs
```

## 🎯 Core Features

### Pattern-Based Variables

Create complex variable structures with simple generators:

```elixir
# 2D transportation problem: supply[i] to demand[j]
variables("transport", [i <- 1..3, j <- 1..4], :continuous, min: 0)

# 3D production planning: product[p] in period[t] at plant[f]
variables("produce", [p <- products, t <- 1..12, f <- facilities], :integer, min: 0)

# 4D chess tournament: player[a] vs player[b] in round[r] at table[t]
variables("game", [a <- 1..8, b <- 1..8, r <- 1..7, t <- 1..4], :binary)
```

### Automatic Linearization

Non-linear expressions become linear constraints behind the scenes:

```elixir
# Absolute values
constraints(abs(inventory) <= max_inventory, "Absolute inventory")

# Maximum functions
constraints(max(profit1, profit2, profit3) >= target, "Max profit")

# Minimum functions
constraints(min(cost1, cost2) <= budget, "Min cost")

# Logical operations (binary variables)
constraints(decision1 AND decision2 AND decision3, "All decisions required")
constraints(decision1 OR decision2 OR decision3, "At least one decision")
```

### Flexible Constraint Patterns

Express complex constraints naturally:

```elixir
# Sum over specific dimensions
constraints([i <- 1..5], sum(x(i, :_)) == 1, "One per row")
constraints([j <- 1..5], sum(x(:_, j)) == 1, "One per column")

# Complex aggregations
constraints([i <- 1..3], sum(x(i, :_)) >= demand[i], "Demand satisfaction")

# Multi-dimensional constraints
constraints([i <- 1..3, j <- 1..3], x(i, j) <= capacity[i][j], "Capacity limits")
```

## 💡 Examples by Complexity

### **Simple Problems**

- **Resource Allocation**: `mix run examples/simple_working_example.exs`
- **Knapsack**: `mix run examples/knapsack_problem.exs`
- **Assignment**: `mix run examples/assignment_problem.exs`

### **Medium Problems**

- **Transportation**: `mix run examples/transportation_problem.exs`
- **Production Planning**: `mix run examples/production_planning.exs`
- **Blending**: `mix run examples/blending_problem.exs`

### **Complex Problems**

- **School Timetabling**: `mix run examples/school_timetabling.exs` (60 variables!)
- **N-Queens**: `mix run examples/nqueens_dsl.exs`
- **Pattern Operations**: `mix run examples/pattern_based_operations_example.exs`

## 🏫 School Timetabling Showcase

**Problem**: Schedule 5 teachers across 3 subjects, 4 time slots, and 3 rooms with complex constraints.

**Generated Timetable**:

| Time Slot  | Room 1                  | Room 2                  | Room 3                  |
| ---------- | ----------------------- | ----------------------- | ----------------------- |
| **Slot 1** | Teacher4<br/>📐 Math    | Teacher2<br/>📚 English | Teacher1<br/>🔬 Science |
| **Slot 2** | Teacher3<br/>📚 English | Teacher5<br/>🔬 Science | Available               |
| **Slot 3** | Teacher4<br/>🔬 Science | Teacher1<br/>📐 Math    | Teacher2<br/>📐 Math    |
| **Slot 4** | Teacher3<br/>🔬 Science | Teacher5<br/>🔬 Science | Teacher4<br/>📚 English |

**Legend:** 📐 Math, 🔬 Science, 📚 English

**Key Results**:

- ✅ **60 decision variables** automatically created
- ✅ **Complex multi-dimensional constraints** handled elegantly
- ✅ **Real-world scheduling scenario** successfully optimized
- ✅ **Teacher qualifications** properly enforced
- ✅ **No room conflicts** or double-booking

This demonstrates Dantzig's power for complex, real-world optimization problems.

## 🔧 Configuration

Dantzig automatically downloads the HiGHS solver binary for your platform:

```elixir
# Custom binary path (optional)
config :dantzig, :highs_binary_path, "/usr/local/bin/highs"

# HiGHS version (default: "1.9.0")
config :dantzig, :highs_version, "1.9.0"
```

## 📊 Current Capabilities

| Feature                     | Status      | Notes                                   |
| --------------------------- | ----------- | --------------------------------------- |
| **Linear Programming**      | ✅ Complete | Full support                            |
| **Quadratic Programming**   | ✅ Complete | Degree ≤ 2 expressions                  |
| **Pattern-based Modeling**  | ✅ Complete | N-dimensional variables                 |
| **Automatic Linearization** | ✅ Complete | abs, max/min, logical ops               |
| **Mixed-Integer Variables** | ⚠️ Tracked  | Types defined, LP serialization pending |
| **Custom Operators**        | 🚧 Reserved | `:in` operator for future use           |

## 🤝 Contributing

We welcome contributions! Explore the [architecture docs](docs/ARCHITECTURE.md) to understand the system design, and feel free to submit issues and pull requests on GitHub.

**Key Areas for Contribution**:

- Mixed-integer LP serialization
- Additional non-linear function support
- Performance optimizations
- Documentation and examples

## 📜 License

MIT License - see [LICENSE.TXT](LICENSE.TXT) for details.

## 🙏 Acknowledgments

- **[HiGHS](https://github.com/ERGO-Code/HiGHS)** - World-class optimization solver
- **[JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers)** - Pre-compiled binaries
- **Elixir Community** - Inspiration and valuable feedback

---

**Ready to optimize?** Start with the [Getting Started Guide](docs/GETTING_STARTED.md) or dive into the [DSL Tutorial](docs/COMPREHENSIVE_TUTORIAL.md) for comprehensive examples!
