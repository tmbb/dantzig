defmodule Dantzig.Polynomial.Operators do
  @moduledoc """
  Operator overloads for `Dantzig.Polynomial`.

  Use in modules with:

      use Dantzig.Polynomial.Operators

  This hides Kernel's arithmetic operators and rebinds them to the polynomial
  operations. Mixed usage with numbers is supported; numbers are coerced to
  constants.
  """
  import Kernel, except: [+: 2, -: 2, *: 2, /: 2]
  alias Dantzig.Polynomial

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [+: 2, -: 2, *: 2, /: 2]
      import unquote(__MODULE__)
    end
  end

  def p + q, do: Polynomial.add(p, q)
  def p - q, do: Polynomial.subtract(p, q)
  def p * q, do: Polynomial.multiply(p, q)
  def p / q, do: Polynomial.divide(p, q)
end
