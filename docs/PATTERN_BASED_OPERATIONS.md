# Pattern-Based Operations in Dantzig AST

## Overview

The Dantzig AST system now supports **pattern-based operations** that allow you to write concise expressions like `max(x[_])` instead of `max(x[1], x[2], x[3], x[4], x[5])`. This makes optimization modeling much more elegant and maintainable.

## What Are Pattern-Based Operations?

Pattern-based operations use the `_` (underscore) wildcard to represent "all variables" in a dimension. This allows you to write expressions that automatically scale with the number of variables.

### Basic Pattern Syntax

| Pattern   | Meaning                                 | Example                               |
| --------- | --------------------------------------- | ------------------------------------- |
| `x[_]`    | All x variables                         | `x[1], x[2], x[3], ..., x[n]`         |
| `x[_, j]` | All x variables with fixed second index | `x[1,j], x[2,j], x[3,j], ..., x[n,j]` |
| `x[i, _]` | All x variables with fixed first index  | `x[i,1], x[i,2], x[i,3], ..., x[i,m]` |
| `x[_, _]` | All x variables (2D)                    | `x[1,1], x[1,2], ..., x[n,m]`         |

## Supported Operations

### Max Operation

```elixir
# Pattern-based syntax
max(x[_])           # Maximum of all x variables
max(x[_, j])        # Maximum over first dimension
max(x[i, _])        # Maximum over second dimension
max(x[_, _])        # Maximum of all 2D x variables

# Equivalent explicit syntax
max(x[1], x[2], x[3], x[4], x[5])
max(x[1,j], x[2,j], x[3,j])
max(x[i,1], x[i,2], x[i,3])
max(x[1,1], x[1,2], x[2,1], x[2,2], x[3,1], x[3,2])
```

### Min Operation

```elixir
# Pattern-based syntax
min(y[_])           # Minimum of all y variables
min(y[_, j])        # Minimum over first dimension
min(y[i, _])        # Minimum over second dimension
min(y[_, _])        # Minimum of all 2D y variables

# Equivalent explicit syntax
min(y[1], y[2], y[3])
min(y[1,j], y[2,j], y[3,j])
min(y[i,1], y[i,2], y[i,3])
min(y[1,1], y[1,2], y[2,1], y[2,2], y[3,1], y[3,2])
```

### And Operation (Binary Variables)

```elixir
# Pattern-based syntax
a[_] AND a[_] AND a[_] AND a[_]    # All a variables must be true

# Equivalent explicit syntax
a[1] AND a[2] AND a[3] AND a[4]
```

### Or Operation (Binary Variables)

```elixir
# Pattern-based syntax
b[_] OR b[_] OR b[_]               # At least one b variable must be true

# Equivalent explicit syntax
b[1] OR b[2] OR b[3]
```

## Implementation Details

### Parser Enhancement

The parser now detects pattern-based arguments in function calls:

```elixir
def detect_pattern_based_args(args) do
  case args do
    # Single pattern-based argument: max(x[_])
    [{var_name, _, indices}] when is_list(indices) ->
      if Enum.all?(indices, &(&1 == :_)) do
        {:pattern, var_name, indices}
      else
        :explicit
      end

    # Multiple arguments - for now, treat as explicit
    _ ->
      :explicit
  end
end
```

### AST Representation

Pattern-based operations are represented as `Sum` expressions within the variadic operations:

```elixir
# max(x[_]) becomes:
%AST.Max{
  args: [
    %AST.Sum{
      variable: %AST.Variable{
        name: "x",
        indices: [:_],
        pattern: [:_]
      }
    }
  ]
}
```

### Transformer Enhancement

The transformer handles pattern-based operations by:

1. **Detecting Pattern-Based Arguments**: Checks if arguments contain `Sum` expressions with pattern variables
2. **Resolving Patterns**: Uses the variable map to find all matching variables
3. **Creating Constraints**: Generates appropriate constraints for each matching variable

```elixir
def transform_max_pattern(var_name, pattern, problem, bindings) do
  # Get the variable map
  var_map = Problem.get_var_map(problem, var_name)

  if var_map do
    # Create pattern from bindings
    resolved_pattern = create_pattern(pattern, bindings)

    # Get all matching variables
    matching_vars = var_map
    |> Enum.filter(fn {key, _monomial} -> matches_pattern(key, resolved_pattern) end)

    # Create new variable for maximum
    max_var_name = generate_max_pattern_var_name(var_name, pattern, bindings)
    {problem, max_monomial} = Problem.new_variable(problem, max_var_name, type: :continuous)

    # Create constraints: w >= x[i] for all matching variables
    problem = Enum.reduce(matching_vars, problem, fn {_key, monomial}, current_problem ->
      add_constraint(current_problem, max_monomial, :>=, monomial, "max_pattern_ge")
    end)

    {problem, max_monomial}
  else
    raise ArgumentError, "Variable map not found for #{var_name}"
  end
end
```

## Linearization Rules

### Pattern-Based Max

For `max(x[_]) = z` where `x[_]` represents `x[1], x[2], ..., x[n]`:

- **Constraints**: `z ≥ x[i]` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Pattern-Based Min

For `min(x[_]) = z` where `x[_]` represents `x[1], x[2], ..., x[n]`:

- **Constraints**: `z ≤ x[i]` for all `i = 1, 2, ..., n`
- **Variable**: `z` is continuous

### Pattern-Based And

For `x[_] AND x[_] AND ... AND x[_] = z` (where all `x[i]` are binary):

- **Constraints**:
  - `z ≤ x[i]` for all `i = 1, 2, ..., n`
  - `z ≥ ∑x[i] - (n-1)`
- **Variable**: `z` is binary

### Pattern-Based Or

For `x[_] OR x[_] OR ... OR x[_] = z` (where all `x[i]` are binary):

- **Constraints**:
  - `z ≥ x[i]` for all `i = 1, 2, ..., n`
  - `z ≤ ∑x[i]`
- **Variable**: `z` is binary

## Examples

### Basic Examples

```elixir
# 1D variables
max(x[_])                    # max(x[1], x[2], x[3], x[4], x[5])
min(y[_])                    # min(y[1], y[2], y[3])

# 2D variables
max(z[_, j])                 # max(z[1,j], z[2,j], z[3,j])
min(z[i, _])                 # min(z[i,1], z[i,2])
max(z[_, _])                 # max(z[1,1], z[1,2], z[2,1], z[2,2], z[3,1], z[3,2])

# Binary variables
a[_] AND a[_] AND a[_]       # a[1] AND a[2] AND a[3]
b[_] OR b[_] OR b[_]         # b[1] OR b[2] OR b[3]
```

### 4D Variables (busy[i, j, k, l])

```elixir
# Create 4D variables busy[i, j, k, l]
max(busy[_, j, k, l])   # max over i dimension
min(busy[i, _, k, l])   # min over j dimension
max(busy[i, j, _, l])   # max over k dimension
min(busy[i, j, k, _])   # min over l dimension
max(busy[_, _, _, _])   # max across all 4D entries
```

### Complex Combinations

```elixir
# Mixed operations
max(x[_]) + min(y[_])        # max(x[1],...,x[n]) + min(y[1],...,y[m])
max(x[_, j]) - min(x[i, _])  # max(x[1,j],...,x[n,j]) - min(x[i,1],...,x[i,m])

# Nested operations
max(min(x[_, j]), min(x[i, _]))  # max of minimums
a[_] AND (b[_] OR c[_])          # all a's AND (at least one b OR at least one c)

# With arithmetic
max(x[_]) * min(y[_])        # max(x[1],...,x[n]) * min(y[1],...,y[m])
sum(x[_]) == max(x[_]) * count(x[_])  # sum equals max times count
```

### Practical Use Cases

#### Portfolio Optimization

```elixir
# Maximize best return while minimizing worst risk
max(return[_]) - min(risk[_])
```

#### Facility Location

```elixir
# Find minimum distance to any customer
min(distance[_, customer])
```

#### Resource Allocation

```elixir
# All resources must be available
resource[_] AND resource[_] AND resource[_]
```

#### Quality Control

```elixir
# Best quality with fewest defects
max(quality[_]) AND min(defect[_])
```

#### Network Optimization

```elixir
# Maximum flow to any destination
max(flow[_, destination])
```

## Benefits

### 1. **Concise Syntax**

- `max(x[_])` instead of `max(x[1], x[2], x[3], x[4], x[5])`
- Reduces code verbosity significantly

### 2. **Automatic Scaling**

- Works with any number of variables
- No need to update code when adding/removing variables

### 3. **Less Error-Prone**

- No need to list variables explicitly
- Reduces chance of missing variables or typos

### 4. **More Readable**

- Intent is clearer: "maximum of all x variables"
- Easier to understand the mathematical meaning

### 5. **Maintainable**

- Adding variables doesn't require code changes
- Easier to refactor and modify

### 6. **Flexible**

- Supports complex patterns like `x[_, j]` or `x[i, _]`
- Can be combined with other operations

## Variable Naming

Pattern-based operations generate descriptive variable names:

```elixir
# max(x[_]) creates variable: max_x_all
# min(y[_, j]) creates variable: min_y_all_j
# max(z[i, _]) creates variable: max_z_i_all
```

The naming convention is:

- `{operation}_{var_name}_{pattern_description}`
- `_` becomes `all`
- Fixed indices are included as-is

## Error Handling

The system provides clear error messages for common issues:

```elixir
# No variables found matching pattern
raise ArgumentError, "No variables found matching pattern x#{inspect([:_])}"

# Variable map not found
raise ArgumentError, "Variable map not found for x"
```

## Future Enhancements

The pattern-based system provides a foundation for:

1. **More Complex Patterns**: `x[1..5]`, `x[even]`, `x[prime]`
2. **Conditional Patterns**: `x[_ where condition]`
3. **Set Operations**: `union(x[_], y[_])`, `intersection(x[_], y[_])`
4. **Statistical Functions**: `mean(x[_])`, `variance(x[_])`, `median(x[_])`
5. **Aggregation Functions**: `count(x[_])`, `product(x[_])`

## Conclusion

Pattern-based operations make the Dantzig AST system much more powerful and user-friendly. They provide a natural, mathematical syntax that scales automatically and reduces the complexity of optimization modeling. This enhancement brings the system closer to the expressiveness of mathematical optimization languages while maintaining the power and flexibility of Elixir.
