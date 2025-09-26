# Dantzig Tutorial

A practical, end-to-end guide to model and solve optimization problems in Elixir using Dantzig and the HiGHS solver.

## Prerequisites

- Elixir project with `{:dantzig, "~> 0.2.0"}` in deps
- `highs` binary available. Either:
  - Set `config :dantzig, :highs_binary_path, "/usr/local/bin/highs"`, or
  - Rely on the default `priv/bin/highs` and use the downloader utilities

## 1) Hello, LP

Maximize `3x + 4y` subject to `x + 2y ≤ 14`, `3x - y ≤ 0`, `x, y ≥ 0`.

```elixir
defmodule HelloLP do
  require Dantzig.Problem, as: Problem
  alias Dantzig.Constraint
  alias Dantzig.Solution
  use Dantzig.Polynomial.Operators

  def run() do
    problem = Problem.new(direction: :maximize)

    {problem, x} = Problem.new_variable(problem, "x", min: 0)
    {problem, y} = Problem.new_variable(problem, "y", min: 0)

    problem =
      problem
      |> Problem.add_constraint(Constraint.new_linear(x + 2*y, :<=, 14, name: "c1"))
      |> Problem.add_constraint(Constraint.new_linear(3*x - y, :<=,  0, name: "c2"))
      |> Problem.maximize(3*x + 4*y)

    {:ok, solution} = Dantzig.solve(problem)

    IO.inspect({
      Solution.evaluate(solution, x),
      Solution.evaluate(solution, y),
      solution.objective
    })
  end
end
```

Run it and you should see optimal `x`, `y`, and the objective.

## 2) Quadratic objective (QP)

Minimize `(x - 5)^2 + (y - 2)^2` with bounds `0 ≤ x ≤ 10`, `0 ≤ y ≤ 10`.

```elixir
defmodule QuadraticExample do
  require Dantzig.Problem, as: Problem
  alias Dantzig.Constraint
  alias Dantzig.Solution
  use Dantzig.Polynomial.Operators

  def run() do
    problem = Problem.new(direction: :minimize)
    {problem, x} = Problem.new_variable(problem, "x", min: 0, max: 10)
    {problem, y} = Problem.new_variable(problem, "y", min: 0, max: 10)

    obj = (x - 5) * (x - 5) + (y - 2) * (y - 2)
    problem = Problem.minimize(problem, obj)

    {:ok, solution} = Dantzig.solve(problem)

    {Solution.evaluate(solution, x), Solution.evaluate(solution, y), solution.objective}
  end
end
```

Note: Degree must be ≤ 2; cubic or higher raises.

## 3) Constraints via macros

You can write constraints using `Constraint.new/1` macro form:

```elixir
constraint = Dantzig.Constraint.new(x + y == 10, name: "balance")
```

Or linear-only:

```elixir
constraint = Dantzig.Constraint.new_linear(2*x + 3*y <= 20, name: "capacity")
```

These macros rewrite arithmetic to polynomial operations and normalize the constraint.

## 4) Implicit problem style (macros)

Dantzig supports an implicit style to reduce boilerplate when creating many variables and constraints. Inside the macro block, `v!` declares a variable and binds its monomial, while `constraint!` inserts a new constraint, and `increment_objective!`/`decrement_objective!` adjust the objective.

```elixir
require Dantzig.Problem, as: Problem
use Dantzig.Polynomial.Operators

total_width = 300.0

Problem.with_implicit_problem problem do
  v!(left_margin, min: 0.0)
  v!(center, min: 0.0)
  v!(right_margin, min: 0.0)

  v!(canvas1, min: 0.0)
  v!(canvas2, min: 0.0)
  v!(canvas3, min: 0.0)

  constraint!(canvas1 + canvas2 + canvas3 == center)
  constraint!(canvas1 == 2*canvas2)
  constraint!(canvas1 == 2*canvas3)

  constraint!(left_margin + center + right_margin == total_width)
  increment_objective!(center - left_margin - right_margin)
end
```

This macro-based style expands to the explicit `Problem.new_variable/3`, `Problem.add_constraint/3`, and objective helpers at compile time.

## 4) Evaluating expressions at the solution

```elixir
value = Dantzig.Solution.evaluate(solution, 2*x + y)
# returns a number when all variables are bound
```

If an expression contains free variables, the reduced polynomial is returned instead of a number.

### Evaluating nonlinear expressions

`Solution.evaluate/2` substitutes variable values into any polynomial. If the result has no free variables, a number is returned even for quadratic expressions.

## 5) Debugging: dump the model

```elixir
Dantzig.dump_problem_to_file(problem, "model.lp")
```

Open the file to inspect the exact LP/QP sent to HiGHS.

### Inspecting constraints and variables

You can examine the serialized LP to verify bounds, variable names, and normalized constraints. Consider logging with `IO.iodata_to_binary/1` on `Dantzig.HiGHS.to_lp_iodata(problem)` for quick inspection.

## 6) Tips and pitfalls

- Ensure the HiGHS binary path is correct (see Configuration below)
- Keep objective/constraints at degree ≤ 2
- Variable names from `new_variable/3` are auto-prefixed and zero-padded
- Use `Problem.new_unmangled_variable/3` for custom names
- Keep variable bounds numeric; if you pass a polynomial, it will be coerced using `Polynomial.to_number!/1`
- QP objective uses `[ ... ] / 2` convention; you may see doubled quadratic terms inside the brackets

## 7) Configuration

```elixir
# config/runtime.exs or config/dev.exs
config :dantzig, :highs_binary_path, System.get_env("HIGHS") || "/usr/local/bin/highs"
config :dantzig, :highs_version, "1.9.0"
```

With the default path (`priv/bin/highs`), see downloader utilities in `Dantzig.HiGHSDownloader`.

## 8) Next steps

- Explore `Dantzig.Constraint.solve_for_variable/2` for symbolic insights
- Enforce integrality (future): list integer variables in the LP `General/Binary` sections
- Add domain constraints (reserved `:in` operator)
- Integrate with another solver by implementing a module analogous to `Dantzig.HiGHS`

## 9) Troubleshooting

- "Couldn't generate a solution": open the printed solver output and `model.lp` to diagnose
- Degree errors: simplify expressions or substitute constants to keep degree ≤ 2
- Missing variable errors: ensure variables are created on `Problem` before being referenced
- For intermittent network errors during binary download, set `:highs_binary_path` to a local `highs`

## 10) Advanced example: N-Queens (step-by-step)

Place N queens on an N×N chessboard so no two attack each other. We use binary-like variables x[i,j] ∈ {0,1} (modeled as 0–1 bounds) with:

- Row constraints: ∑_j x[i,j] == 1 for each row i
- Column constraints: ∑_i x[i,j] == 1 for each column j
- Diagonal constraints: for every main and anti-diagonal, ∑ x[i,j] ≤ 1

We’ll build it progressively.

### 10.1 Variables x[i,j]

Step-by-step:

- We iterate rows and columns with nested `Enum.reduce/3` to build N×N variables.
- For each cell `(i, j)` we construct a stable name `"x_#{i}_#{j}"` so constraints can reference it deterministically.
- `Problem.new_unmangled_variable/3` creates a variable with exactly that name and returns `{updated_problem, monomial}`. We bound it to `[0.0, 1.0]` to emulate a binary variable in LP.
- We store the monomial in a map `x` keyed by `{i, j}` for convenient later access when assembling sums for rows, columns, and diagonals.
- The reducer carries the progressively updated `problem` across all creations so that all variables end up in the same model.

```elixir
require Dantzig.Problem, as: Problem
alias Dantzig.Constraint
use Dantzig.Polynomial.Operators

def new_board(problem, n) do
  Enum.reduce(1..n, {problem, %{}}, fn i, {p_acc, x} ->
    Enum.reduce(1..n, {p_acc, x}, fn j, {p2, x_map} ->
      name = "x_#{i}_#{j}"
      {p3, var} = Problem.new_unmangled_variable(p2, name, min: 0.0, max: 1.0)
      {p3, Map.put(x_map, {i, j}, var)}
    end)
  end)
end
```

### 10.2 Row constraints

```elixir
def add_row_constraints(problem, x, n) do
  Enum.reduce(1..n, problem, fn i, p ->
    row_sum =
      1..n
      |> Enum.map(fn j -> x[{i, j}] end)
      |> Enum.reduce(0, &(&1 + &2))

    Problem.add_constraint(p, Constraint.new_linear(row_sum == 1.0, name: "row_#{i}"))
  end)
end
```

### 10.3 Column constraints

```elixir
def add_col_constraints(problem, x, n) do
  Enum.reduce(1..n, problem, fn j, p ->
    col_sum =
      1..n
      |> Enum.map(fn i -> x[{i, j}] end)
      |> Enum.reduce(0, &(&1 + &2))

    Problem.add_constraint(p, Constraint.new_linear(col_sum == 1.0, name: "col_#{j}"))
  end)
end
```

### 10.4 Diagonals (≤ 1)

We handle both main diagonals (i−j constant) and anti-diagonals (i+j constant).

```elixir
def add_diag_constraints(problem, x, n) do
  # Main diagonals: d = i - j ranges from -(n-1) to (n-1)
  problem =
    Enum.reduce(-(n-1)..(n-1), problem, fn d, p ->
      cells = for i <- 1..n, j <- 1..n, i - j == d, do: x[{i, j}]
      case cells do
        [] -> p
        _ ->
          sum = Enum.reduce(cells, 0, &(&1 + &2))
          Problem.add_constraint(p, Constraint.new_linear(sum <= 1.0, name: "main_d_#{d}"))
      end
    end)

  # Anti-diagonals: s = i + j ranges from 2 to 2n
  Enum.reduce(2..(2*n), problem, fn s, p ->
    cells = for i <- 1..n, j <- 1..n, i + j == s, do: x[{i, j}]
    case cells do
      [] -> p
      _ ->
        sum = Enum.reduce(cells, 0, &(&1 + &2))
        Problem.add_constraint(p, Constraint.new_linear(sum <= 1.0, name: "anti_s_#{s}"))
    end
  end)
end
```

### 10.5 Full example (feasibility)

```elixir
defmodule NQueens do
  require Dantzig.Problem, as: Problem
  alias Dantzig.Constraint
  use Dantzig.Polynomial.Operators

  def solve(n) do
    problem = Problem.new(direction: :minimize)
    {problem, x} = new_board(problem, n)
    problem = problem |> add_row_constraints(x, n) |> add_col_constraints(x, n) |> add_diag_constraints(x, n)
    # No objective needed for feasibility; minimize 0
    {:ok, solution} = Dantzig.solve(problem)

    # Extract 1.0 positions
    queens =
      for i <- 1..n, j <- 1..n, Solution.evaluate(solution, x[{i, j}]) >= 0.5, do: {i, j}

    {solution, queens}
  end
end
```

Note: We model binaries with [0,1] bounds. If/when integer sections are emitted, switch these to integer/binary variables for strict integrality.

### 10.6 Rendering the board

```elixir
defmodule NQueens.Render do
  def to_ascii(n, queens) do
    queen_set = MapSet.new(queens)
    1..n
    |> Enum.map(fn i ->
      1..n
      |> Enum.map(fn j -> if MapSet.member?(queen_set, {i, j}), do: "Q", else: "." end)
      |> Enum.join(" ")
    end)
    |> Enum.join("\n")
  end
end

# Example usage:
{
  solution,
  queens
} = NQueens.solve(8)

IO.puts("\nSolution:\n" <> NQueens.Render.to_ascii(8, queens))
```

Unicode alternative (uses the white queen symbol):

```elixir
defmodule NQueens.RenderUnicode do
  @queen "♛"
  @empty "·" # middle dot for better spacing

  def to_unicode(n, queens) do
    queen_set = MapSet.new(queens)
    1..n
    |> Enum.map(fn i ->
      1..n
      |> Enum.map(fn j -> if MapSet.member?(queen_set, {i, j}), do: @queen, else: @empty end)
      |> Enum.intersperse(" ")
      |> IO.iodata_to_binary()
    end)
    |> Enum.intersperse("\n")
    |> IO.iodata_to_binary()
  end
end

IO.puts("\nUnicode:\n" <> NQueens.RenderUnicode.to_unicode(8, queens))
```

### 10.7 Running from IEx

Save the complete `NQueens` module to a file (e.g., `nqueens.ex`) and run:

```bash
# Start IEx with your project
iex -S mix

# Load the module
Code.compile_file("nqueens.ex")

# Solve and display
{solution, queens} = NQueens.solve(8)
IO.puts("\nSolution:\n" <> NQueens.Render.to_ascii(8, queens))
IO.puts("\nUnicode:\n" <> NQueens.RenderUnicode.to_unicode(8, queens))
```

Or paste the module directly into IEx and run the solve/display commands.
