# Variadic Operations in Dantzig AST

## Overview

The Dantzig AST system now supports **variadic operations** for `max()`, `min()`, `and()`, and `or()` functions. This means these operations can take any number of arguments, just like the `sum()` function.

## What Changed

### Before (Binary Only)

```elixir
# Only supported 2 arguments
max(x, y)
min(x, y)
x AND y
x OR y
```

### After (Variadic)

```elixir
# Supports any number of arguments
max(x, y, z, w, ...)
min(x, y, z, w, ...)
x AND y AND z AND w AND ...
x OR y OR z OR w OR ...
```

## AST Representation Changes

### Max Operation

```elixir
# Before
defmodule Max do
  defstruct [:left, :right]
end

# After
defmodule Max do
  defstruct [:args]  # List of arguments
end
```

### Min Operation

```elixir
# Before
defmodule Min do
  defstruct [:left, :right]
end

# After
defmodule Min do
  defstruct [:args]  # List of arguments
end
```

### And Operation

```elixir
# Before
defmodule And do
  defstruct [:left, :right]
end

# After
defmodule And do
  defstruct [:args]  # List of arguments
end
```

### Or Operation

```elixir
# Before
defmodule Or do
  defstruct [:left, :right]
end

# After
defmodule Or do
  defstruct [:args]  # List of arguments
end
```

## Parser Changes

The parser now handles variadic function calls:

```elixir
# max(x, y, z, ...)
{:max, _, args} when is_list(args) ->
  %AST.Max{args: Enum.map(args, &parse_expression/1)}

# min(x, y, z, ...)
{:min, _, args} when is_list(args) ->
  %AST.Min{args: Enum.map(args, &parse_expression/1)}

# x AND y AND z AND ...
{:and, _, args} when is_list(args) ->
  %AST.And{args: Enum.map(args, &parse_expression/1)}

# x OR y OR z OR ...
{:or, _, args} when is_list(args) ->
  %AST.Or{args: Enum.map(args, &parse_expression/1)}
```

## Transformer Changes

### Variadic Max Transformation

```elixir
def transform_max_variadic(args, problem, bindings) do
  # 1. Evaluate all expressions
  {problem, arg_polynomials} =
    Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
      {new_problem, poly} = transform_expression(arg, current_problem, bindings)
      {new_problem, [poly | acc]}
    end)

  arg_polynomials = Enum.reverse(arg_polynomials)

  # 2. Create new variable for maximum
  max_var_name = generate_max_variadic_var_name(args, bindings)
  {problem, max_monomial} = Problem.new_variable(problem, max_var_name, type: :continuous)

  # 3. Create constraints: w >= x, w >= y, w >= z, ...
  problem = Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
    add_constraint(current_problem, max_monomial, :>=, arg_poly, "max_ge_arg")
  end)

  {problem, max_monomial}
end
```

### Variadic Min Transformation

```elixir
def transform_min_variadic(args, problem, bindings) do
  # 1. Evaluate all expressions
  {problem, arg_polynomials} =
    Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
      {new_problem, poly} = transform_expression(arg, current_problem, bindings)
      {new_problem, [poly | acc]}
    end)

  arg_polynomials = Enum.reverse(arg_polynomials)

  # 2. Create new variable for minimum
  min_var_name = generate_min_variadic_var_name(args, bindings)
  {problem, min_monomial} = Problem.new_variable(problem, min_var_name, type: :continuous)

  # 3. Create constraints: w <= x, w <= y, w <= z, ...
  problem = Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
    add_constraint(current_problem, min_monomial, :<=, arg_poly, "min_le_arg")
  end)

  {problem, min_monomial}
end
```

### Variadic And Transformation

```elixir
def transform_and_variadic(args, problem, bindings) do
  # 1. Evaluate all expressions
  {problem, arg_polynomials} =
    Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
      {new_problem, poly} = transform_expression(arg, current_problem, bindings)
      {new_problem, [poly | acc]}
    end)

  arg_polynomials = Enum.reverse(arg_polynomials)

  # 2. Create binary variable for AND result
  and_var_name = generate_and_variadic_var_name(args, bindings)
  {problem, and_monomial} = Problem.new_variable(problem, and_var_name, type: :binary)

  # 3. Create constraints: z <= x, z <= y, z <= z, ... (for all args)
  problem = Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
    add_constraint(current_problem, and_monomial, :<=, arg_poly, "and_le_arg")
  end)

  # 4. Create constraint: z >= sum(args) - (n-1) where n is number of args
  n = length(arg_polynomials)
  sum_poly = Enum.reduce(arg_polynomials, Polynomial.const(0), fn poly, acc ->
    Polynomial.add(acc, poly)
  end)
  problem = add_constraint(problem, and_monomial, :>=,
    Polynomial.subtract(sum_poly, Polynomial.const(n - 1)), "and_ge_sum_minus_n_minus_one")

  {problem, and_monomial}
end
```

### Variadic Or Transformation

```elixir
def transform_or_variadic(args, problem, bindings) do
  # 1. Evaluate all expressions
  {problem, arg_polynomials} =
    Enum.reduce(args, {problem, []}, fn arg, {current_problem, acc} ->
      {new_problem, poly} = transform_expression(arg, current_problem, bindings)
      {new_problem, [poly | acc]}
    end)

  arg_polynomials = Enum.reverse(arg_polynomials)

  # 2. Create binary variable for OR result
  or_var_name = generate_or_variadic_var_name(args, bindings)
  {problem, or_monomial} = Problem.new_variable(problem, or_var_name, type: :binary)

  # 3. Create constraints: z >= x, z >= y, z >= z, ... (for all args)
  problem = Enum.reduce(arg_polynomials, problem, fn arg_poly, current_problem ->
    add_constraint(current_problem, or_monomial, :>=, arg_poly, "or_ge_arg")
  end)

  # 4. Create constraint: z <= sum(args)
  sum_poly = Enum.reduce(arg_polynomials, Polynomial.const(0), fn poly, acc ->
    Polynomial.add(acc, poly)
  end)
  problem = add_constraint(problem, or_monomial, :<=, sum_poly, "or_le_sum")

  {problem, or_monomial}
end
```

## Linearization Rules

### Max Operation

For `max(x₁, x₂, ..., xₙ) = z`:

- **Constraints**: `z ≥ xᵢ` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Min Operation

For `min(x₁, x₂, ..., xₙ) = z`:

- **Constraints**: `z ≤ xᵢ` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### And Operation

For `x₁ AND x₂ AND ... AND xₙ = z` (where all `xᵢ` are binary):

- **Constraints**:
  - `z ≤ xᵢ` for all `i = 1, 2, ..., n`
  - `z ≥ ∑xᵢ - (n-1)`
- **Variable**: `z` is binary

### Or Operation

For `x₁ OR x₂ OR ... OR xₙ = z` (where all `xᵢ` are binary):

- **Constraints**:
  - `z ≥ xᵢ` for all `i = 1, 2, ..., n`
  - `z ≤ ∑xᵢ`
- **Variable**: `z` is binary

## Examples

### Basic Variadic Operations

```elixir
# Max of 4 variables
max(x[1], x[2], x[3], x[4])

# Min of 3 variables
min(y[1], y[2], y[3])

# All must be true
a[1] AND a[2] AND a[3] AND a[4] AND a[5]

# At least one must be true
b[1] OR b[2] OR b[3]
```

### Complex Combinations

```elixir
# Nested operations
max(min(x[1], x[2]), min(x[3], x[4]))

# Mixed operations
a[1] AND (b[1] OR b[2] OR b[3])

# Multiple levels
max(x[1], x[2]) AND min(y[1], y[2], y[3])
```

### Practical Use Cases

#### Portfolio Optimization

```elixir
# Maximize best return while minimizing worst risk
max(return1, return2, return3, return4) - min(risk1, risk2, risk3)
```

#### Facility Location

```elixir
# Find minimum distance to any facility
min(distance1, distance2, distance3, distance4)
```

#### Resource Allocation

```elixir
# All resources must be available
resource1 AND resource2 AND resource3
```

#### Backup Systems

```elixir
# At least one system must be working
system1 OR system2 OR system3
```

#### Quality Control

```elixir
# Best quality with fewest defects
max(quality1, quality2) AND min(defect1, defect2)
```

## Benefits

1. **Natural Syntax**: Matches mathematical notation exactly
2. **Automatic Linearization**: No manual constraint creation needed
3. **Scalable**: Works with any number of arguments
4. **Composable**: Can be nested and combined freely
5. **Efficient**: Creates optimal number of constraints
6. **Type Safe**: Maintains proper variable types (binary/continuous)

## Implementation Notes

- **Backward Compatibility**: Binary versions still work
- **Variable Naming**: Automatic generation of unique auxiliary variable names
- **Constraint Naming**: Descriptive constraint names for debugging
- **Error Handling**: Proper error messages for invalid usage
- **Performance**: Efficient constraint generation for large argument lists

## Future Enhancements

The variadic operation system provides a foundation for:

1. **Custom Functions**: User-defined variadic operations
2. **Aggregation Functions**: `sum()`, `product()`, `count()`, etc.
3. **Statistical Functions**: `mean()`, `median()`, `variance()`, etc.
4. **Set Operations**: `union()`, `intersection()`, `difference()`, etc.
5. **Conditional Aggregation**: `sum_if()`, `max_if()`, etc.

This enhancement makes the Dantzig AST system much more powerful and user-friendly for complex optimization problems!
