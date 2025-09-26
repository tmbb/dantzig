# Contributing to Dantzig

Thank you for your interest in contributing to Dantzig! This document provides guidelines for contributing to the project.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/dantzig.git`
3. Install dependencies: `mix deps.get`
4. Run tests: `mix test`
5. Generate documentation: `mix docs`

## Development Guidelines

### Code Style

- Follow Elixir community conventions
- Use `mix format` to format code
- Write comprehensive tests for new features
- Update documentation for API changes

### Testing

- Write tests for all new functionality
- Ensure existing tests continue to pass
- Add property-based tests for complex algorithms using `StreamData`

### Documentation

- Update module documentation for new public APIs
- Add examples in docstrings where helpful
- Update architecture documentation for significant changes

## Architecture

Before making significant changes, please read the [Architecture Documentation](docs/ARCHITECTURE.md) to understand the system design.

## Pull Request Process

1. Create a feature branch from `main`
2. Make your changes with appropriate tests
3. Ensure all tests pass: `mix test`
4. Generate and review documentation: `mix docs`
5. Submit a pull request with a clear description

## Issues

- Use GitHub issues for bug reports and feature requests
- Provide clear reproduction steps for bugs
- Include relevant system information

## Questions?

Feel free to open an issue for questions or discussions about the project.
