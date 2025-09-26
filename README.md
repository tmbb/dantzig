# Dantzig

[![Hex.pm](https://img.shields.io/hexpm/v/dantzig.svg)](https://hex.pm/packages/dantzig)
[![Hex.pm](https://img.shields.io/hexpm/dt/dantzig.svg)](https://hex.pm/packages/dantzig)
[![Build Status](https://github.com/tmbb/dantzig/workflows/CI/badge.svg)](https://github.com/tmbb/dantzig/actions)

**Linear and Mixed-Integer Programming for Elixir** with a clean modeling DSL, AST-powered transformations, and the HiGHS solver.

## 🚀 Features

- **Multiple Modeling Styles**: From explicit variable creation to pattern-based N-dimensional modeling
- **Automatic Linearization**: Transform non-linear expressions (`abs`, `max/min`, logical operations) into linear constraints
- **Pattern-based Modeling**: Create N-dimensional variables with generators: `x[i, j]` for `i <- 1..8, j <- 1..8`
- **Symbolic Algebra**: Operator overloading for polynomials with automatic simplification
- **HiGHS Integration**: Automatic binary download and seamless solver integration
- **Comprehensive Documentation**: ExDoc-powered docs with tutorials and examples

## 📦 Installation

Add `dantzig` to your dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dantzig, "~> 0.2.0"}
  ]
end
```

## ⚡ Quick Start

### Simple Linear Programming

```elixir
alias Dantzig.{Problem, Constraint}
use Dantzig.Polynomial.Operators

problem = Problem.new(direction: :maximize)
{problem, x} = Problem.new_variable(problem, "x", min: 0)
{problem, y} = Problem.new_variable(problem, "y", min: 0)

problem =
  problem
  |> Problem.add_constraint(Constraint.new_linear(x + 2*y, :<=, 14))
  |> Problem.add_constraint(Constraint.new_linear(3*x - y, :<=, 0))
  |> Problem.maximize(3*x + 4*y)

{:ok, solution} = Dantzig.solve(problem)
IO.inspect({solution.objective, solution.variables})
```

### Pattern-based N-Queens

```elixir
require Dantzig.DSL, as: DSL

problem = Problem.new(direction: :minimize)

# Create 8x8 binary variables: x[i,j] = 1 if queen at position (i,j)
problem = DSL.add_variables(problem, [i <- 1..8, j <- 1..8], "x", :binary)

# One queen per row
problem = DSL.add_constraints(problem, [i <- 1..8], "x", {i, :_}, :==, 1)

# One queen per column
problem = DSL.add_constraints(problem, [j <- 1..8], "x", {:_, j}, :==, 1)

solution = Dantzig.solve!(problem)
```

### Non-linear with Automatic Linearization

```elixir
# abs(x) and max(x, y, z) automatically become linear constraints
problem = Problem.new(direction: :minimize)
{problem, x} = Problem.new_variable(problem, "x", min: -10, max: 10)
{problem, y} = Problem.new_variable(problem, "y", min: -10, max: 10)

# These non-linear expressions are automatically linearized
problem = Problem.add_constraint(problem, Constraint.new(abs(x) + max(x, y) <= 5))
```

## 🎯 Modeling Styles

Dantzig supports multiple modeling approaches:

### 1. **Explicit Modeling**

Direct manipulation with full control:

```elixir
{problem, x} = Problem.new_variable(problem, "x", min: 0, max: 10)
problem = Problem.add_constraint(problem, Constraint.new(x <= 5))
```

### 2. **Pattern-based Modeling (DSL)**

High-level macros for N-dimensional problems:

```elixir
problem = DSL.add_variables(problem, [i <- 1..n, j <- 1..m], "x", :binary)
problem = DSL.add_constraints(problem, [i <- 1..n], "x", {i, :_}, :==, 1)
```

### 3. **Implicit Modeling**

Monadic-style syntax:

```elixir
Problem.with_implicit_problem problem do
  v!(x, min: 0.0, max: 10.0)
  constraint!(x <= 5)
  increment_objective!(x)
end
```

### 4. **AST-based Modeling**

Non-linear expressions with automatic linearization:

```elixir
# abs(x), max(x, y), and(x, y, z) automatically become linear
```

## 📚 Documentation

- **[Getting Started](docs/GETTING_STARTED.md)** - Your first optimization problem
- **[Tutorial](docs/TUTORIAL.md)** - Comprehensive guide with N-Queens example
- **[Modeling Guide](docs/MODELING_GUIDE.md)** - Best practices and advanced techniques
- **[Pattern-based Operations](docs/PATTERN_BASED_OPERATIONS.md)** - N-dimensional modeling patterns
- **[Variadic Operations](docs/VARIADIC_OPERATIONS.md)** - Advanced pattern matching
- **[Macros Guide](docs/README_MACROS.md)** - Macro-based modeling techniques
- **[Advanced AST](docs/ADVANCED_AST.md)** - Automatic linearization and AST transformations
- **[Architecture](docs/ARCHITECTURE.md)** - System design and implementation details

Generate full documentation:

```bash
mix docs
```

## 🔧 Configuration

Dantzig automatically downloads the HiGHS binary for your platform. Customize:

```elixir
# Custom HiGHS binary path
config :dantzig, :highs_binary_path, "/usr/local/bin/highs"

# HiGHS version (default: "1.9.0")
config :dantzig, :highs_version, "1.9.0"
```

## 🎨 Examples

Check out the `examples/` directory for runnable examples:

- `simple_working_example.exs` - Basic pattern-based modeling
- `pattern_based_operations_example.exs` - N-dimensional modeling
- `variadic_operations_example.exs` - Advanced pattern matching

Run any example with: `mix run examples/filename.exs`

**Note**: Examples must be run with `mix run` (not `elixir`) to access the Dantzig modules.

## 🚧 Current Limitations

- **Mixed-integer**: Variable types are tracked but not yet serialized to LP format
- **Degree limits**: Only linear and quadratic expressions (degree ≤ 2)
- **Operators**: Supports `:==`, `:<=`, `:>=` (reserved `:in` for future)

## 🤝 Contributing

Contributions are welcome! Please see our [contributing guidelines](CONTRIBUTING.md) and check out the [architecture documentation](docs/ARCHITECTURE.md) to understand the system design.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE.TXT](LICENSE.TXT) file for details.

## 🙏 Acknowledgments

- [HiGHS](https://github.com/ERGO-Code/HiGHS) - High-performance optimization solver
- [JuliaBinaryWrappers](https://github.com/JuliaBinaryWrappers) - Pre-compiled HiGHS binaries
- The Elixir community for inspiration and feedback

---

**Ready to optimize?** Start with the [Getting Started Guide](docs/GETTING_STARTED.md) or dive into the [Tutorial](docs/TUTORIAL.md)!
