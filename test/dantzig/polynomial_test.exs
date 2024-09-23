defmodule Dantzig.PolynomialTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  require Dantzig.Polynomial, as: Polynomial
  alias Dantzig.Test.PolynomialGenerators, as: Gen

  property "commutative property of addition" do
    check all([p1, p2] <- Gen.polynomials(nr_of_polynomials: 2)) do
      Polynomial.algebra do
        assert Polynomial.equal?(p1 + p2, p2 + p1)
      end
    end
  end

  property "associative property of addition" do
    check all([p1, p2, p3] <- Gen.polynomials(nr_of_polynomials: 3)) do
      Polynomial.algebra do
        assert Polynomial.equal?(p1 + (p2 + p3), p2 + p1 + p3)
      end
    end
  end

  property "zero is identity for addition" do
    check all(p <- Gen.polynomial()) do
      Polynomial.algebra do
        # Add an explicit constant
        assert Polynomial.equal?(p, p + Polynomial.const(0))
        assert Polynomial.equal?(p, p + Polynomial.const(0.0))
        # Add a raw numeric value
        assert Polynomial.equal?(p, p + 0)
        assert Polynomial.equal?(p, p + 0.0)
      end
    end
  end

  property "commutative property of multiplication" do
    # Limit the polynomial degree to make tests faster
    check all([p1, p2] <- Gen.polynomials(nr_of_polynomials: 2, max_degree: 3)) do
      Polynomial.algebra do
        assert Polynomial.equal?(p1 * p2, p2 * p1)
      end
    end
  end

  property "associative property of multiplication" do
    # Limit the polynomial degree to make tests faster
    check all([p1, p2, p3] <- Gen.polynomials(nr_of_polynomials: 3, max_degree: 3)) do
      Polynomial.algebra do
        assert Polynomial.equal?(p1 * (p2 * p3), p1 * p2 * p3)
      end
    end
  end

  property "one is the identity element of multiplication" do
    check all(p <- Gen.polynomial()) do
      Polynomial.algebra do
        # Multiply by an explicit constant
        assert Polynomial.equal?(p, p * Polynomial.const(1))
        # Multiply by a raw integer
        assert Polynomial.equal?(p, p * 1)
        # NOTE: we don't use floats because it can change
        # the type of the polynomial coefficients
      end
    end
  end

  property "distributive property" do
    # Limit the polynomial degree to make tests faster
    check all([p1, p2, q] <- Gen.polynomials(nr_of_polynomials: 3, max_degree: 3)) do
      Polynomial.algebra do
        assert Polynomial.equal?(q * (p1 + p2), q * p1 + q * p2)
      end
    end
  end
end
