# Dantzig Documentation Style Guide

## Purpose

This style guide ensures consistent, professional documentation that reads like it was written by experienced developers for other developers, rather than marketing copy.

## General Principles

### 1. Professional Tone

- **Use technical language** appropriate for developers
- **Avoid marketing hype** like "enterprise-scale", "world-class", "revolutionary"
- **Be factual and precise** rather than promotional
- **Focus on capabilities** rather than superiority claims

### 2. Clear Structure

- **Logical organization** with clear headings
- **Consistent formatting** throughout all documents
- **Proper use of emphasis** (bold for important terms, not decoration)
- **Minimal visual clutter** (emojis, excessive formatting)

### 3. Technical Accuracy

- **Precise terminology** for mathematical and programming concepts
- **Accurate descriptions** of features and limitations
- **Clear examples** that actually work
- **Honest limitations** and future improvements

## Specific Guidelines

### Section Headers

```markdown
## Features # ✅ Good

## 🚀 Features # ❌ Too promotional

## Installation # ✅ Good

## 📦 Installation # ❌ Too decorative
```

### Feature Descriptions

```markdown
## Features

- **Multiple Modeling Styles**: Support for explicit, pattern-based, and simple syntax approaches
- **Automatic Linearization**: Transform non-linear expressions into linear constraints
- **Pattern-based Modeling**: Create N-dimensional variables with generator expressions
- **Symbolic Algebra**: Operator overloading for polynomial manipulation
- **HiGHS Integration**: Automatic binary download and solver integration
- **Comprehensive Documentation**: Complete guides and examples

## ❌ Avoid:

## 🚀 Features

- **Multiple Modeling Styles**: Revolutionary approach to N-dimensional modeling
- **Automatic Linearization**: Cutting-edge transformation capabilities
- **Pattern-based Modeling**: Industry-leading generator expressions
- **World-class Documentation**: Enterprise-grade documentation suite
```

### Example Code

````markdown
## Quick Start

```elixir
require Dantzig.Problem, as: Problem

problem =
  Problem.define do
    new(direction: :maximize)
    variables("x", :continuous, min: 0)
    constraints(x <= 10)
    objective(x)
  end

{:ok, solution} = Dantzig.solve(problem)
```
````

## ❌ Avoid:

## ⚡ Quick Start

```elixir
# Revolutionary new syntax for optimization!
require Dantzig.Problem, as: Problem

problem =
  Problem.define do
    new(direction: :maximize)  # 🚀 So easy!
    variables("x", :continuous, min: 0)
    constraints(x <= 10)       # ✨ Magic!
    objective(x)              # 🎯 Profit!
  end

{:ok, solution} = Dantzig.solve(problem)  # 🚀 Blazing fast!
```

````

### Success Indicators
```markdown
## Implementation Results

**Variables:** 60 decision variables across 4 dimensions
**Constraints:** Multi-dimensional scheduling constraints enforced
**Solution:** Feasible timetable generated with no conflicts
**Validation:** All constraints satisfied within tolerance

## ❌ Avoid:
## ✅ Key Achievements

- 🚀 **60 decision variables** (5×3×3×4 = 180 possible combinations)
- ✨ **Complex multi-dimensional constraints** handled efficiently
- 🎯 **Real-world scheduling scenario** successfully optimized
- 💫 **Teacher qualification constraints** properly enforced
- 🌟 **Room and time conflict prevention** working correctly

This example showcases how Dantzig can handle **enterprise-scale optimization problems** with complex business rules and multi-dimensional constraints.
````

### Call-to-Action

```markdown
## Getting Started

Begin with the [Getting Started Guide](docs/GETTING_STARTED.md) or explore the [Tutorial](docs/TUTORIAL.md) for detailed examples.

## ❌ Avoid:

**Ready to optimize?** Start with the [Getting Started Guide](docs/GETTING_STARTED.md) or dive into the [Tutorial](docs/TUTORIAL.md)!
```

## Visual Elements

### Emojis

- **Use sparingly** for clear visual organization
- **Avoid decorative emojis** in technical content
- **Consider accessibility** - not all readers can see emojis

```markdown
## Examples # ✅ Good

## 🎨 Examples # ❌ Too decorative

## Documentation # ✅ Good

## 📚 Documentation # ❌ Too decorative
```

### Code Blocks

- **Syntax highlighting** for all code examples
- **Clear comments** explaining complex parts
- **Realistic examples** that actually work
- **Error handling** shown where appropriate

### Tables and Lists

- **Use for organization** when it improves clarity
- **Keep formatting simple** and consistent
- **Focus on information** rather than visual appeal

## Language Guidelines

### Technical Terms

- **Use standard terminology** for mathematical optimization
- **Define acronyms** on first use
- **Be consistent** with naming throughout documentation

### Comparisons

- **Avoid superiority claims** ("best", "fastest", "most advanced")
- **Focus on capabilities** ("supports", "handles", "provides")
- **Be honest about limitations** and future improvements

### User Guidance

- **Clear instructions** for common tasks
- **Troubleshooting section** for common issues
- **Best practices** based on experience
- **Migration guides** for breaking changes

## Document Structure

### README.md

- **Project overview** with clear value proposition
- **Installation instructions** with copy-paste commands
- **Quick start** with working example
- **Feature summary** with technical descriptions
- **Example showcase** with real use cases
- **Documentation links** for further reading

### Tutorial Documentation

- **Progressive learning** from basic to advanced
- **Working examples** with complete code
- **Clear explanations** of concepts
- **Practical applications** of features
- **Troubleshooting guidance** for common issues

### API Documentation

- **Complete function signatures** with types
- **Parameter descriptions** with examples
- **Return value documentation** with examples
- **Usage examples** for complex functions

## Review Checklist

Before publishing documentation, verify:

- [ ] **Professional tone** - No marketing hype or promotional language
- [ ] **Technical accuracy** - All descriptions are factually correct
- [ ] **Working examples** - All code examples compile and run
- [ ] **Clear structure** - Logical organization and navigation
- [ ] **Consistent formatting** - Uniform style throughout
- [ ] **Minimal decoration** - Focus on content over visual appeal
- [ ] **Proper emphasis** - Bold for important terms, not decoration
- [ ] **Accessibility** - Consider readers who can't see emojis or colors

## Examples of Good Documentation

### Technical Description

````markdown
## Multi-dimensional Variables

Dantzig supports N-dimensional variable creation using generator expressions:

```elixir
variables("x", [i <- 1..5, j <- 1..3], :binary)
```
````

This creates 15 binary variables x[1,1], x[1,2], x[1,3], x[2,1], etc.

````

### Feature Description
```markdown
## Automatic Linearization

Non-linear expressions are automatically converted to linear constraints:

```elixir
constraints(abs(x) + max(x, y, z) <= 5)
````

This creates the necessary binary variables and linear constraints to represent the absolute value and maximum functions.

```

## Maintenance

This style guide should be reviewed and updated as the project evolves to maintain consistent, professional documentation quality.
```
