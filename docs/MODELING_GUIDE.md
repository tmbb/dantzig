# Modeling Guide

Best practices and patterns for building robust optimization models in Dantzig.

## General tips

- Normalize units and domains early; prefer integer/binary where meaningful
- Keep constraints simple and interpretable; decompose when complex
- Name variables/constraints descriptively for debugging

## Variables

- Use `:binary` for 0/1 decisions, `:continuous` where appropriate
- Use patterns to generate large structured variable sets concisely

## Constraints

- Prefer pattern sums (e.g., `{i, :_}`, `{:_, j}`) over manual loops
- Group related constraints with meaningful description strings

## Objectives

- Build objectives incrementally with `Problem.increment_objective/2`
- For multi-objective, use weighted sum or lexicographic passes

## Variadic & pattern ops

- `max(x[_])`, `min(z[i, _])`, `a[_] AND ...`, `b[_] OR ...` are supported via AST
- Expect auxiliary variables & constraints behind the scenes

## Debugging

- Dump LP with `Dantzig.dump_problem_to_file(problem, "model.lp")`
- Inspect constraint and variable maps

## Performance

- Limit big-M values; tighten bounds
- Reduce symmetry via indexing or additional constraints
