defmodule Dantzig.DSL.ReferenceSyntaxTest do
  @moduledoc """
  Test the actual reference syntax from nqueens_dsl.exs.
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL
  alias Dantzig.Problem, as: Problem

  test "reference syntax should work with proper macro transformation" do
    # This is what the reference syntax SHOULD look like after macro transformation
    # From: [i <- 1..4, j <- 1..4]
    # To:   [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}]

    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "queen2d",
        [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}],
        :binary,
        description: "Queen position"
      )

    # This is what the reference syntax SHOULD look like after macro transformation
    # From: queen2d[i, :_] == 1
    # To:   {:==, [], [{:queen2d, [], [1, :_]}, 1]}

    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:i, [], nil}, 1..4]}],
        {:==, [], [{:queen2d, [], [{:i, [], nil}, :_]}, 1]},
        "One queen per row"
      )

    # Should create 4 constraints (one for each i in 1..4)
    assert result.name == "test"
    assert map_size(result.constraints) == 4
  end

  test "show the difference between source and AST" do
    # Source code: [i <- 1..4]
    # AST: [{:<-, [], [{:i, [], nil}, 1..4]}]

    # Let's demonstrate this transformation
    source_ast = quote do: [i <- 1..4]
    expected_ast = [{:<-, [], [{:i, [], nil}, 1..4]}]

    # The source AST is more complex because it includes metadata
    assert is_list(source_ast)
    assert length(source_ast) == 1

    # The first element should be the generator
    generator = hd(source_ast)
    assert is_tuple(generator)
    assert elem(generator, 0) == :<-

    # The variable should be {:i, [], nil}
    var_part = elem(generator, 2) |> hd()
    assert var_part == {:i, [], nil}

    # The range should be 1..4
    range_part = elem(generator, 2) |> tl() |> hd()
    assert range_part == 1..4
  end

  test "show why queen2d[i, :_] is invalid" do
    # This demonstrates why queen2d[i, :_] is invalid Elixir syntax

    # Valid Elixir bracket syntax:
    valid_syntax = quote do: queen2d[i]
    assert is_tuple(valid_syntax)

    # Invalid Elixir bracket syntax (this would cause a compilation error):
    # invalid_syntax = quote do: queen2d[i, :_]
    # This would fail with: "too many arguments when accessing a value"

    # The valid AST for multi-argument access should be:
    valid_multi_arg = {:queen2d, [], [1, :_]}
    assert is_tuple(valid_multi_arg)
    assert elem(valid_multi_arg, 0) == :queen2d
    assert elem(valid_multi_arg, 2) == [1, :_]
  end

  test "demonstrate the macro transformation needed" do
    # The DSL macros should transform:
    # Source: [i <- 1..4, j <- 1..4]
    # Into:   [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}]

    # Source: queen2d[i, :_]
    # Into:   {:queen2d, [], [{:i, [], nil}, :_]}

    # This is what our DSL.constraints macro should do:
    problem =
      Problem.new(name: "test")
      |> Problem.variables(
        "queen2d",
        [{:<-, [], [{:i, [], nil}, 1..4]}, {:<-, [], [{:j, [], nil}, 1..4]}],
        :binary,
        description: "Queen position"
      )

    # Test the transformed syntax
    result =
      DSL.constraints(
        problem,
        [{:<-, [], [{:i, [], nil}, 1..4]}],
        {:==, [], [{:queen2d, [], [{:i, [], nil}, :_]}, 1]},
        "One queen per row"
      )

    assert result.name == "test"
    assert map_size(result.constraints) == 4
  end
end
