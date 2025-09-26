# Advanced AST & Linearization

## Overview

The AST stack (`Parser`, `Analyzer`, `Transformer`) turns high-level expressions into linear models.

## Supported transforms

- abs(x): absolute value is converted into 3 constraints + 1 auxiliary variable (abs_x >= x, abs_x >= -x, abs_x >= 0)
- max/min(args): bound constraints + auxiliary variable (variadic)
- and/or(args): binary auxiliary variable with standard linearization
- piecewise linear: segment binaries + big-M bounds
- max/min(args): bound constraints + auxiliary variable (variadic)
- and/or(args): binary auxiliary variable with standard linearization
- piecewise linear: segment binaries + big-M bounds

## Pattern-based arguments

Expressions like `max(x[_])` are parsed as a Sum over the pattern, then linearized.

## Extensibility

Add new nodes to `Dantzig.AST`, extend `Parser`, analyze with `Analyzer`, and linearize in `Transformer`.
