# Dantzig Macros - Enhanced Optimization Syntax

This document describes the new macro system for Dantzig that provides clean, readable syntax for creating optimization problems.

## Overview

The new macro system allows you to write optimization problems in a more intuitive way, similar to mathematical notation. Instead of nested `Enum.reduce` calls, you can use clean generator syntax and pattern matching.

## Key Features

- **Clean Variable Creation**: Create multi-dimensional variables with generator syntax
- **Pattern-Based Constraints**: Use patterns like `{i, :_}` to create constraints automatically
- **Multi-Dimensional Support**: Handle 2D, 3D, and higher-dimensional problems
- **Multiple Variable Sets**: Create different variable sets in the same problem
- **Automatic Constraint Generation**: Generate constraints from patterns and generators

## Basic Syntax

### Variable Creation

```elixir
# Old way (cumbersome)
problem = Enum.reduce(1..4, problem, fn i, acc_problem ->
  Enum.reduce(1..4, acc_problem, fn j, acc_problem2 ->
    var_name = "x_#{i}_#{j}"
    {new_problem, _monomial} = Problem.new_variable(acc_problem2, var_name, type: :binary)
    new_problem
  end)
end)

# New way (clean)
generators = [{:i, :in, [1, 2, 3, 4]}, {:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_variables(problem, generators, "x", :binary, "Queen position")
```

### Constraint Creation

```elixir
# Old way (cumbersome)
problem = Enum.reduce(1..4, problem, fn i, acc_problem ->
  # Create constraint for row i
  # ... complex constraint creation code
end)

# New way (clean)
row_generators = [{:i, :in, [1, 2, 3, 4]}]
problem = Macros.add_constraints(problem, row_generators, "x", {:i, :_}, :==, 1, "One queen per row")
```

## Generator Syntax

Generators define the ranges for your variables. They support:

### Basic Lists

```elixir
[{:i, :in, [1, 2, 3, 4]}]
```

### Ranges

```elixir
[{:i, :in, 1..4}]  # Automatically converted to [1, 2, 3, 4]
```

### Multiple Dimensions

```elixir
[{:i, :in, [1, 2, 3]}, {:j, :in, [1, 2, 3]}, {:k, :in, [1, 2]}]
```

## Pattern Matching

Patterns define which variables to include in constraints:

### Wildcard Patterns

- `{i, :_}` - Sum over all j for fixed i
- `{:_, j}` - Sum over all i for fixed j
- `{i, j, :_}` - Sum over all k for fixed i and j

### Specific Patterns

- `{i, j}` - Single variable x[i,j]
- `{1, :_}` - Sum over all j for i=1

## Examples

### 1. N-Queens Problem

```elixir
# Variables: x[i,j] = 1 if queen at position (i,j)
generators = [{:i, :in, [1, 2, 3, 4]}, {:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_variables(problem, generators, "x", :binary, "Queen position")

# Constraint: exactly one queen per row
row_generators = [{:i, :in, [1, 2, 3, 4]}]
problem = Macros.add_constraints(problem, row_generators, "x", {:i, :_}, :==, 1, "One queen per row")

# Constraint: exactly one queen per column
col_generators = [{:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_constraints(problem, col_generators, "x", {:_, :j}, :==, 1, "One queen per column")
```

### 2. Traveling Salesman Problem

```elixir
cities = [1, 2, 3, 4]

# Variables: x[i,j] = 1 if edge (i,j) is used
tsp_generators = [{:i, :in, cities}, {:j, :in, cities}]
problem = Macros.add_variables(problem, tsp_generators, "x", :binary, "Edge used")

# Constraint: each city has exactly 2 edges
outgoing_generators = [{:i, :in, cities}]
problem = Macros.add_constraints(problem, outgoing_generators, "x", {:i, :_}, :==, 1, "Outgoing edges")

incoming_generators = [{:j, :in, cities}]
problem = Macros.add_constraints(problem, incoming_generators, "x", {:_, :j}, :==, 1, "Incoming edges")
```

### 3. Classroom Timetabling

```elixir
courses = [1, 2, 3]
times = [1, 2, 3, 4]
rooms = [1, 2]

# Variables: x[c,t,r] = 1 if course c at time t in room r
timetable_generators = [{:c, :in, courses}, {:t, :in, times}, {:r, :in, rooms}]
problem = Macros.add_variables(problem, timetable_generators, "x", :binary, "Course schedule")

# Constraint: each course scheduled exactly once
course_generators = [{:c, :in, courses}]
problem = Macros.add_constraints(problem, course_generators, "x", {:c, :_, :_}, :==, 1, "Course scheduled once")

# Constraint: no room double-booking
room_generators = [{:t, :in, times}, {:r, :in, rooms}]
problem = Macros.add_constraints(problem, room_generators, "x", {:_, :t, :r}, :<=, 1, "No room double-booking")
```

### 4. Multiple Variable Sets

```elixir
# Facility variables
facility_generators = [{:i, :in, [1, 2, 3]}]
problem = Macros.add_variables(problem, facility_generators, "x", :binary, "Facility opened")

# Service variables
service_generators = [{:i, :in, [1, 2, 3]}, {:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_variables(problem, service_generators, "y", :binary, "Customer served")

# Constraints using different variable sets
customer_generators = [{:j, :in, [1, 2, 3, 4]}]
problem = Macros.add_constraints(problem, customer_generators, "y", {:_, :j}, :==, 1, "Customer served once")
```

## API Reference

### `Macros.add_variables/5`

```elixir
Macros.add_variables(problem, generators, var_name, var_type, description)
```

**Parameters:**

- `problem`: The Dantzig.Problem struct
- `generators`: List of generators defining variable ranges
- `var_name`: String name for the variable set
- `var_type`: Atom type (`:binary`, `:continuous`, `:integer`)
- `description`: Optional description string

**Returns:** Updated problem with variables and var_map

### `Macros.add_constraints/7`

```elixir
Macros.add_constraints(problem, generators, var_name, pattern, operator, value, description)
```

**Parameters:**

- `problem`: The Dantzig.Problem struct
- `generators`: List of generators for constraint iteration
- `var_name`: String name of the variable set to use
- `pattern`: Pattern defining which variables to include
- `operator`: Constraint operator (`:==`, `:<=`, `:>=`, `:<`, `:>`, `:!=`)
- `value`: Right-hand side value (number)
- `description`: Optional description string

**Returns:** Updated problem with constraints

## Advanced Features

### Variable Maps

The system automatically creates and manages variable maps in the problem struct:

```elixir
# Access variable map
var_map = Problem.get_var_map(problem, "x")

# Variable map structure:
# %{
#   {1, 1} => %Dantzig.Polynomial{...},
#   {1, 2} => %Dantzig.Polynomial{...},
#   ...
# }
```

### Pattern Matching Details

The pattern matching system supports:

1. **Wildcards**: `:_` matches any value
2. **Variables**: `i`, `j`, `k` match the corresponding generator variable
3. **Literals**: `1`, `2`, `3` match specific values
4. **Mixed patterns**: `{i, :_, 1}` matches all j for fixed i and k=1

### Constraint Generation

For each combination of generator values, the system:

1. Creates bindings from generator variables to their values
2. Applies the pattern to select matching variables
3. Sums the selected variables
4. Creates a constraint: `sum <= value` (or other operator)

## Future Enhancements

The current implementation provides the foundation for more advanced features:

1. **Non-linear Functions**: Support for `abs()`, `max()`, `min()` with automatic linearization
2. **Complex Expressions**: Support for expressions like `sum(x[i, _]) + sum(y[_, j])`
3. **Filtering**: Support for generator filters like `[i <- 1..4, j <- 1..4, i != j]`
4. **Nested Patterns**: Support for more complex pattern matching

## Migration Guide

To migrate from the old system:

1. **Replace nested Enum.reduce with generators**:

   ```elixir
   # Old
   Enum.reduce(1..4, problem, fn i, acc -> ... end)

   # New
   generators = [{:i, :in, [1, 2, 3, 4]}]
   Macros.add_variables(problem, generators, "x", :binary, "Description")
   ```

2. **Replace manual constraint creation with patterns**:

   ```elixir
   # Old
   # Manual constraint creation code

   # New
   Macros.add_constraints(problem, generators, "x", {:i, :_}, :==, 1, "Description")
   ```

3. **Use var_maps for variable access**:

   ```elixir
   # Old
   # Manual variable name construction

   # New
   var_map = Problem.get_var_map(problem, "x")
   monomial = var_map[{i, j}]
   ```

## Examples

See the following files for complete examples:

- `examples/simple_working_example.exs` - Basic working examples
- `examples/tutorial_examples.exs` - Comprehensive tutorial with all problem types
- `test/dantzig/macros_v2_test.exs` - Test suite demonstrating all features

## Conclusion

The new macro system makes Dantzig optimization problems much more readable and maintainable. The clean syntax reduces errors and makes the mathematical structure of problems more apparent. This foundation enables future enhancements for even more powerful optimization modeling capabilities.
