# Dantzig

Opimitizion library for elixir, using the HiGHS solver.
Supports linear programming (LP), mixed linear integer programming (MILP) and quadratic programming (QP).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `dantzig` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:dantzig, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/dantzig>.

## Example

Example taken from the tests

```elixir
  test "more complex layout problem" do
    require Dantzig.Problem, as: Problem
    alias Dantzig.Solution
    use Dantzig.Polynomial.Operators

    total_width = 300.0

    problem = Problem.new(direction: :maximize)

    # Define a custom utility function to specify declaratively
    # that one element fits inside another.
    fits_inside = fn problem, inside, outside ->
      Problem.add_constraint(problem, Constraint.new(inside <= outside))
    end

    # Suppose we need to have the sizes of our boxes calculated
    # by a call to an external program which returns the sizes
    # all at once.
    long_calculation_by_external_program = fn _boxes ->
      [15, 40, 38.0]
    end

    # Use the implicit style of description.
    # This macro will perform some simple AST rewriting to allow us
    # to use something like a "monadic" style from Haskell.
    Problem.with_implicit_problem problem do
      # The v!() is special syntax which creates variables
      # in implicit problems. Each of the lines below is rewritten as
      # `{problem, variable} = Problem.new_variable(problem, variable, optional_args)`

      # Margins for our drawing
      v!(left_margin, min: 0.0)
      v!(center, min: 0.0)
      v!(right_margin, min: 0.0)

      # Widths of some boxes we want to draw
      v!(box1_width, min: 0.0)
      v!(box2_width, min: 0.0)
      v!(box3_width, min: 0.0)

      # Canvases which will fit inside the center,
      # with specific constraints
      v!(canvas1_width, min: 0.0)
      v!(canvas2_width, min: 0.0)
      v!(canvas3_width, min: 0.0)

      # constraint!() is special syntax to add a constraint to the problem
      constraint!(canvas1_width + canvas2_width + canvas3_width == center)
      constraint!(canvas1_width == 2*canvas2_width)
      constraint!(canvas1_width == 2*canvas3_width)

      # Now it's better to use the `problem` variable
      problem =
        problem
        |> fits_inside.(box1_width, left_margin)
        |> fits_inside.(box2_width, left_margin)
        # The last box must fit in the right margin
        |> fits_inside.(box3_width, right_margin)

      # Get the box widths from our "slow call to an external program"
      # We get the widths all at once and only once the all the variables
      # are defined so that we can ask for all widths in a single call.
      [box1_w, box2_w, box3_w] = long_calculation_by_external_program.([
        box1_width,
        box2_width,
        box3_width
      ])

      constraint!(box1_width == box1_w)
      constraint!(box2_width == box2_w)
      constraint!(box3_width == box3_w)

      # All the margins must add to the given total length
      # NOTE: total_width is not a variable! It's a constant we've defined before
      # The custom operators from the `Dantzig.Polynomial.Operators` module handle
      # both numbers and polynomials
      constraint!(left_margin + center + right_margin == total_width)

      # Minimize the margins and maximize the center
      increment_objective!(center - left_margin - right_margin)
    end

    solution = Dantzig.solve(problem)

    # Test properties of the solution
    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # One constraint and three variables
    assert Solution.nr_of_constraints(solution) == 10
    assert Solution.nr_of_variables(solution) == 9
    # The solution gets the right values
    # (note: in this case, equalities should be exact)
    assert Solution.evaluate(solution, left_margin) == 40.0
    assert Solution.evaluate(solution, center) == 222.0
    assert Solution.evaluate(solution, right_margin) == 38.0

    assert Solution.evaluate(solution, box1_width) == 15.0
    assert Solution.evaluate(solution, box2_width) == 40.0
    assert Solution.evaluate(solution, box3_width) == 38.0
    # The canvases widths sum to the center width and respect
    # the poportions we've picked (or any other proportion,
    # as long as the constraints are linear)
    assert Solution.evaluate(solution, canvas1_width) == 111.0
    assert Solution.evaluate(solution, canvas2_width) == 55.5
    assert Solution.evaluate(solution, canvas3_width) == 55.5
    # The objective has the right value
    assert solution.objective == 144.0
  end
```


## Documentation

TODO