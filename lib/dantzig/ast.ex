defmodule Dantzig.AST do
  @moduledoc """
  Abstract Syntax Tree representation for Dantzig optimization expressions.

  This module defines the internal AST structures used to represent
  optimization expressions before they are transformed into linear constraints.
  """

  @doc """
  Represents a variable with indices: x[i, j] or x[_, j]
  """
  defmodule Variable do
    defstruct [:name, :indices, :pattern]

    @type t :: %__MODULE__{
            name: atom(),
            indices: [any()],
            pattern: [any()] | nil
          }
  end

  @doc """
  Represents a sum operation: sum(x[i, _])
  """
  defmodule Sum do
    defstruct [:variable]

    @type t :: %__MODULE__{
            variable: Variable.t()
          }
  end

  @doc """
  Represents a generator-based sum operation: sum(expr for i <- list, j <- list)
  """
  defmodule GeneratorSum do
    defstruct [:expression, :generators]

    @type t :: %__MODULE__{
            expression: t(),
            generators: [tuple()]
          }
  end

  @doc """
  Represents an absolute value operation: abs(x[i, j])
  """
  defmodule Abs do
    defstruct [:expr]

    @type t :: %__MODULE__{
            expr: t()
          }
  end

  @doc """
  Represents a maximum operation: max(x, y, z, ...)
  """
  defmodule Max do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  @doc """
  Represents a minimum operation: min(x, y, z, ...)
  """
  defmodule Min do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  @doc """
  Represents a constraint: left operator right
  """
  defmodule Constraint do
    defstruct [:left, :operator, :right]

    @type t :: %__MODULE__{
            left: t(),
            operator: atom(),
            right: t()
          }
  end

  @doc """
  Represents a binary operation: left operator right
  """
  defmodule BinaryOp do
    defstruct [:left, :operator, :right]

    @type t :: %__MODULE__{
            left: t(),
            operator: atom(),
            right: t()
          }
  end

  @doc """
  Represents a piecewise linear function
  """
  defmodule PiecewiseLinear do
    defstruct [:expr, :breakpoints, :slopes, :intercepts]

    @type t :: %__MODULE__{
            expr: t(),
            breakpoints: [number()],
            slopes: [number()],
            intercepts: [number()]
          }
  end

  @doc """
  Represents a logical AND operation: x AND y AND z AND ...
  """
  defmodule And do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  @doc """
  Represents a logical OR operation: x OR y OR z OR ...
  """
  defmodule Or do
    defstruct [:args]

    @type t :: %__MODULE__{
            args: [t()]
          }
  end

  @doc """
  Represents an IF-THEN-ELSE operation: IF condition THEN x ELSE y
  """
  defmodule IfThenElse do
    defstruct [:condition, :then_expr, :else_expr]

    @type t :: %__MODULE__{
            condition: t(),
            then_expr: t(),
            else_expr: t()
          }
  end

  @doc """
  Union type for all AST nodes
  """
  @type t ::
          Variable.t()
          | Sum.t()
          | GeneratorSum.t()
          | Abs.t()
          | Max.t()
          | Min.t()
          | Constraint.t()
          | BinaryOp.t()
          | PiecewiseLinear.t()
          | And.t()
          | Or.t()
          | IfThenElse.t()
          | number()
          | atom()
end
