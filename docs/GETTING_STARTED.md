# Getting Started

This guide shows how to model a simple optimization problem and solve it with Dantzig.

## Setup

- Ensure the HiGHS binary downloads automatically (handled in this repo)
- Generate docs and explore:

```bash
mix deps.get
mix compile
mix docs
```

## Minimal model

```elixir
alias Dantzig.{Problem, Constraint}
require Dantzig.Polynomial, as: P

P.algebra do
  problem = Problem.new(direction: :maximize)
  {problem, x} = Problem.new_variable(problem, "x", min: 0.0, max: 10.0)
  {problem, y} = Problem.new_variable(problem, "y", min: 0.0, max: 10.0)

  problem =
    problem
    |> Problem.add_constraint(Constraint.new(x + y <= 12))
    |> Problem.increment_objective(2 * x + 3 * y)

  solution = Dantzig.solve!(problem)
  IO.inspect({solution.objective})
end
```

## Next Steps

- **[DSL Tutorial](COMPREHENSIVE_TUTORIAL.md)** - Complete guide with pattern-based modeling
- **[Modeling Guide](MODELING_GUIDE.md)** - Best practices and patterns
- **[Advanced AST](ADVANCED_AST.md)** - Automatic linearization details

## Related Documentation

- **[Architecture Guide](ARCHITECTURE.md)** - System design and internals
- **[Pattern-based Operations](PATTERN_BASED_OPERATIONS.md)** - Advanced pattern features
- **[Examples Directory](../examples/)** - Runnable examples for learning
