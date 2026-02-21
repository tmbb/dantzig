defmodule Dantzig.Polynomial.Operators do
  import Kernel, except: [+: 2, -: 2, *: 2, /: 2]
  alias Dantzig.Polynomial

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [+: 2, -: 2, *: 2, /: 2, **: 2]
      import unquote(__MODULE__)
    end
  end

  def p + q, do: Polynomial.add(p, q)
  def p - q, do: Polynomial.subtract(p, q)
  def p * q, do: Polynomial.multiply(p, q)
  def p / q, do: Polynomial.divide(p, q)
  def p ** n, do: Polynomial.power(p, n)
end
