defmodule Danztig.Instances.LayoutExamplesTest do
  use ExUnit.Case, async: true
  require Dantzig.Problem, as: Problem
  alias Dantzig.Solution
  use Dantzig.Polynomial.Operators


  test "trivial sum" do
    total_width = 300.0

    problem = Problem.new(direction: :maximize)
    {problem, left_margin} = Problem.new_variable(problem, "left_margin", min: 0.0)
    {problem, center} = Problem.new_variable(problem, "center", min: 0.0)
    {problem, right_margin} = Problem.new_variable(problem, "right_margin", min: 0.0)

    {problem, _c} = Problem.new_constraint(problem, left_margin + center + right_margin == total_width)

    {problem, _obj} = Problem.increment_objective(problem, center - left_margin - right_margin)

    solution = Dantzig.solve(problem)

    # Test properties of the solution
    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # One constraint and three variables
    assert Solution.nr_of_constraints(solution) == 1
    assert Solution.nr_of_variables(solution) == 3
    # The solution gets the right values
    # (note: in this case, equalities should be exact)
    assert Solution.evaluate(solution, left_margin) == 0.0
    assert Solution.evaluate(solution, center) == 300.0
    assert Solution.evaluate(solution, right_margin) == 0.0
    # The objective has the right value
    assert solution.objective == 300.0
  end

  test "trivial sum (implicit problem operations)" do
    total_width = 300.0
    problem = Problem.new(direction: :maximize)

    Problem.with_implicit_problem problem do
      v!(left_margin, min: 0.0)
      v!(center, min: 0.0)
      v!(right_margin, min: 0.0)

      _c1 <~ Problem.new_constraint(left_margin + center + right_margin == total_width)
      _obj <~ Problem.increment_objective(center - left_margin - right_margin)
    end

    solution = Dantzig.solve(problem)

    # Test properties of the solution
    assert solution.model_status == "Optimal"
    assert solution.feasibility == "Feasible"
    # One constraint and three variables
    assert Solution.nr_of_constraints(solution) == 1
    assert Solution.nr_of_variables(solution) == 3
    # The solution gets the right values
    # (note: in this case, equalities should be exact)
    assert Solution.evaluate(solution, left_margin) == 0.0
    assert Solution.evaluate(solution, center) == 300.0
    assert Solution.evaluate(solution, right_margin) == 0.0
    # The objective has the right value
    assert solution.objective == 300.0
  end

  test "trivial sum (implicit == explicit)" do
    total_width = 300.0

    # Implicit problem description
    problem_implicit = Problem.new(direction: :maximize)

    Problem.with_implicit_problem problem_implicit do
      v!(left_margin, min: 0.0)
      v!(center, min: 0.0)
      v!(right_margin, min: 0.0)

      _c1 <~ Problem.new_constraint(left_margin + center + right_margin == total_width)
      _obj <~ Problem.increment_objective(center - left_margin - right_margin)
    end

    # Explicit problem description (not how much more verbose it is)
    problem_explicit = Problem.new(direction: :maximize)
    {problem_explicit, left_margin} = Problem.new_variable(problem_explicit, "left_margin", min: 0.0)
    {problem_explicit, center} = Problem.new_variable(problem_explicit, "center", min: 0.0)
    {problem_explicit, right_margin} = Problem.new_variable(problem_explicit, "right_margin", min: 0.0)

    {problem_explicit, _c} = Problem.new_constraint(problem_explicit, left_margin + center + right_margin == total_width)

    {problem_explicit, _obj} = Problem.increment_objective(problem_explicit, center - left_margin - right_margin)

    # Ensure the same problem is generated in both cases
    assert problem_explicit == problem_implicit

    # Ensure the solution is the same
    # NOTE: since we've shown that the generated problems are the same,
    # this test is just showing that the solver is deterministic
    solution_implicit = Dantzig.solve(problem_implicit)
    solution_explicit = Dantzig.solve(problem_explicit)

    assert solution_implicit == solution_explicit
  end

  # From now on we'll use the implicit notation always

  test "more complex layout problem" do
    require Dantzig.Problem, as: Problem
    alias Dantzig.Solution
    use Dantzig.Polynomial.Operators

    total_width = 300.0

    problem = Problem.new(direction: :maximize)

    # Define a custom utility function to specify declaratively
    # that one element fits inside another.
    fits_inside = fn problem, inside, outside ->
      Problem.new_constraint(problem, inside <= outside)
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

      _c0 <~ Problem.new_constraint(canvas1_width + canvas2_width + canvas3_width == center)
      _c1 <~ Problem.new_constraint(canvas1_width == 2*canvas2_width)
      _c2 <~ Problem.new_constraint(canvas1_width == 2*canvas3_width)

      # Inside implicit problems, the <~ operator is rewriten so that
      # `z <~ f(a, b, c)` becomes `{problem, z} = f(problem, a, b, c)`
      # (where `problem` is the variable given to the macro)
      # The first two boxes must fit in the left margin
      _c3 <~ fits_inside.(box1_width, left_margin)
      _c4 <~ fits_inside.(box2_width, left_margin)

      # The last box must fit in the right margin
      _c5 <~ fits_inside.(box3_width, right_margin)

      # Get the box widths from our "slow call to an external program"
      # We get the widths all at once and only once the all the variables
      # are defined so that we can ask for all widths in a single call.
      [box1_w, box2_w, box3_w] = long_calculation_by_external_program.([
        box1_width,
        box2_width,
        box3_width
      ])

      _c6 <~ Problem.new_constraint(box1_width == box1_w)
      _c7 <~ Problem.new_constraint(box2_width == box2_w)
      _c8 <~ Problem.new_constraint(box3_width == box3_w)

      # All the margins must add to the given total length
      # NOTE: total_width is not a variable! It's a constant we've defined before
      # The custom operators from the Dantzig.Polynomial.Operators module handle
      # both numbers and polynomials
      _c9 <~ Problem.new_constraint(left_margin + center + right_margin == total_width)

      # Minimize the margins and maximize the center
      _obj <~ Problem.increment_objective(center - left_margin - right_margin)
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
end
