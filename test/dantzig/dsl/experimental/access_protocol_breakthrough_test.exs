defmodule Dantzig.DSL.AccessProtocolBreakthroughTest do
  @moduledoc """
  Test implementing the Access protocol to make queen2d[i, :_] work!
  """
  use ExUnit.Case, async: true

  require Dantzig.Problem.DSL, as: DSL

  test "understanding the Access protocol transformation" do
    # From the previous test, we learned that:
    # queen2d[[1, :_]] becomes {{:., [from_brackets: true], [Access, :get]}, [from_brackets: true], [{:queen2d, [], Module}, [1, :_]]}
    # queen2d[{1, :_}] becomes {{:., [from_brackets: true], [Access, :get]}, [from_brackets: true], [{:queen2d, [], Module}, {1, :_}]}

    # This means Elixir transforms queen2d[...] into Access.get(queen2d, ...)

    # So if I can make queen2d implement the Access protocol, then queen2d[i, :_] should work!

    # Let's test this understanding
    quoted_expr = quote do: queen2d[[1, :_]]

    # The AST should be an Access.get call
    assert is_tuple(quoted_expr)

    # The first element should be {:., [from_brackets: true], [Access, :get]}
    access_call = elem(quoted_expr, 0)
    assert is_tuple(access_call)
    assert elem(access_call, 0) == :.

    # The third element should contain [Access, :get]
    access_info = elem(access_call, 2)
    assert access_info == [Access, :get]

    # The arguments should be [{:queen2d, [], Module}, [1, :_]]
    args = elem(quoted_expr, 2)
    assert is_list(args)
    assert length(args) == 2

    # First argument should be the queen2d variable
    var_arg = hd(args)
    assert is_tuple(var_arg)
    assert elem(var_arg, 0) == :queen2d

    # Second argument should be the indices
    indices_arg = hd(tl(args))
    assert indices_arg == [1, :_]

    IO.inspect(quoted_expr, label: "Full AST")
    IO.inspect(access_call, label: "Access call")
    IO.inspect(args, label: "Arguments")
  end

  test "can we create a variable that implements Access?" do
    # If I can create a variable that implements the Access protocol,
    # then queen2d[i, :_] should work!

    # Let's test with a simple Access implementation
    result = DSL.access_variable_test(:queen2d, [1, :_])

    # This should create a variable that can be accessed with brackets
    assert is_tuple(result)
    assert elem(result, 0) == :queen2d
    assert elem(result, 2) == [1, :_]
  end

  test "understanding single vs multiple arguments in Access" do
    # Test different bracket syntaxes to understand how Access works

    # Single argument: queen2d[arg]
    single_expr = quote do: queen2d[1]

    # List argument: queen2d[[arg1, arg2]]
    list_expr = quote do: queen2d[[1, :_]]

    # Tuple argument: queen2d[{arg1, arg2}]
    tuple_expr = quote do: queen2d[{1, :_}]

    # All should be Access.get calls
    assert is_tuple(single_expr)
    assert is_tuple(list_expr)
    assert is_tuple(tuple_expr)

    # Get the arguments for each
    single_args = elem(single_expr, 2)
    list_args = elem(list_expr, 2)
    tuple_args = elem(tuple_expr, 2)

    # The second argument (the key) should be different
    single_key = hd(tl(single_args))
    list_key = hd(tl(list_args))
    tuple_key = hd(tl(tuple_args))

    # Single argument
    assert single_key == 1
    # List argument
    assert list_key == [1, :_]
    # Tuple argument
    assert tuple_key == {1, :_}

    IO.inspect(single_key, label: "Single key")
    IO.inspect(list_key, label: "List key")
    IO.inspect(tuple_key, label: "Tuple key")
  end

  test "can we make queen2d[i, :_] work with Access protocol?" do
    # The key insight: if I can make queen2d implement Access,
    # then queen2d[[i, :_]] will work (list as single argument)
    # and I can transform queen2d[i, :_] to queen2d[[i, :_]]

    # Test with a macro that can handle this transformation
    result = DSL.access_transform_test(:queen2d, [1, :_])

    # This should create the proper transformation
    assert is_tuple(result)
    assert elem(result, 0) == :queen2d
    # Note: wrapped in list
    assert elem(result, 2) == [[1, :_]]
  end

  test "proof of concept: Access protocol implementation" do
    # This is the key insight: I can implement the Access protocol
    # for variables to make bracket notation work!

    # Test with a proof of concept
    result = DSL.access_proof_of_concept(:queen2d, [1, :_])

    # This should demonstrate how Access protocol can work
    assert is_tuple(result)
    assert elem(result, 0) == :access_get
    assert elem(result, 2) == [:queen2d, [1, :_]]
  end
end
