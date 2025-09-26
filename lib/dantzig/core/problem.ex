defmodule Dantzig.Problem do
  @moduledoc """
  Optimization model: variables, constraints, and objective.

  A problem holds:

  - `:direction` – `:maximize` or `:minimize`
  - `:objective` – a `Dantzig.Polynomial` (linear or quadratic)
  - `:variable_defs` – map of scalar variable name to `%Dantzig.ProblemVariable{}` containing
    optional bounds and `:type`
  - `:variables` – map of variable set name to index-to-monomial mapping
    (N‑D families; scalars appear with the empty tuple key `{}`)
  - `:constraints` – map of unique constraint id to `%Dantzig.Constraint{}`

  Build a problem by creating variables, adding constraints, and adjusting
  the objective. Then solve with `Dantzig.solve/1`.
  """
  alias Dantzig.Polynomial
  alias Dantzig.ProblemVariable
  alias Dantzig.Constraint
  alias Dantzig.SolvedConstraint

  @nr_of_zeros 8

  @type t :: %__MODULE__{}

  defstruct variable_counter: 0,
            constraint_counter: 0,
            objective: Polynomial.const(0.0),
            direction: nil,
            variable_defs: %{},
            variables: %{},
            constraints: %{},
            contraints_metadata: %{}

  @spec solve_for_all_variables(t()) :: %{
          ProblemVariable.variable_namme() => SolvedConstraint.t()
        }
  def solve_for_all_variables(%__MODULE__{} = problem) do
    Enum.reduce(problem.constraints, %{}, fn {_id, constraint}, acc ->
      variable_names = Polynomial.variables(constraint.left_hand_side)

      Enum.reduce(variable_names, acc, fn variable_name, acc2 ->
        solved_constraint = Constraint.solve_for_variable(constraint, variable_name)

        if solved_constraint do
          Map.put(acc2, variable_name, solved_constraint)
        else
          acc2
        end
      end)
    end)
  end

  @spec new(keyword()) :: t()
  def new(opts \\ []) do
    case Keyword.fetch(opts, :direction) do
      {:ok, direction} when direction in [:minimize, :maximize] ->
        %__MODULE__{direction: direction}

      _ ->
        raise "Problem.new/1 requires :direction (:minimize or :maximize)"
    end
  end

  @spec add_constraint(t(), Constraint.t()) :: t()
  def add_constraint(problem, constraint) do
    constraint_id = generate_constraint_id(problem.constraint_counter)
    new_constraint_counter = problem.constraint_counter + 1

    %{
      problem
      | constraints: Map.put(problem.constraints, constraint_id, constraint),
        constraint_counter: new_constraint_counter
    }
  end

  @spec new_variable(t(), String.t(), keyword()) :: {t(), Polynomial.t()}
  def new_variable(problem, name, opts \\ []) do
    type = Keyword.get(opts, :type, :continuous)
    min_bound = Keyword.get(opts, :min, nil)
    max_bound = Keyword.get(opts, :max, nil)

    variable = %ProblemVariable{
      name: name,
      type: type,
      min: min_bound,
      max: max_bound
    }

    new_problem = %{
      problem
      | variable_defs: Map.put(problem.variable_defs, name, variable),
        variable_counter: problem.variable_counter + 1
    }

    monomial = Polynomial.variable(name)

    # mirror scalar in N-D map with empty tuple key
    existing_map = Map.get(new_problem.variables, name, %{})
    updated_map = Map.put(existing_map, {}, monomial)

    newer_problem = %{
      new_problem
      | variables: Map.put(new_problem.variables, name, updated_map)
    }

    {newer_problem, monomial}
  end

  @spec new_unmangled_variable(t(), String.t(), keyword()) :: {t(), Polynomial.t()}
  def new_unmangled_variable(problem, name, opts \\ []) do
    new_variable(problem, name, opts)
  end

  @spec new_variables(t(), [String.t()], keyword()) :: {t(), [Polynomial.t()]}
  def new_variables(problem, names, opts \\ []) do
    Enum.reduce(names, {problem, []}, fn name, {current_problem, monomials} ->
      {new_problem, monomial} = new_variable(current_problem, name, opts)
      {new_problem, [monomial | monomials]}
    end)
    |> then(fn {final_problem, monomials} -> {final_problem, Enum.reverse(monomials)} end)
  end

  @spec minimize(t(), Polynomial.t()) :: t()
  def minimize(problem, objective) do
    %{problem | objective: objective, direction: :minimize}
  end

  @spec maximize(t(), Polynomial.t()) :: t()
  def maximize(problem, objective) do
    %{problem | objective: objective, direction: :maximize}
  end

  @spec set_objective(t(), Polynomial.t()) :: t()
  def set_objective(problem, objective) do
    %{problem | objective: objective}
  end

  @spec increment_objective(t(), Polynomial.t()) :: t()
  def increment_objective(problem, objective_increment) do
    new_objective = Polynomial.add(problem.objective, objective_increment)
    %{problem | objective: new_objective}
  end

  @spec get_variable(t(), String.t()) :: ProblemVariable.t() | nil
  def get_variable(problem, name) do
    Map.get(problem.variable_defs, name)
  end

  @spec get_constraint(t(), String.t()) :: Constraint.t() | nil
  def get_constraint(problem, constraint_id) do
    Map.get(problem.constraints, constraint_id)
  end

  @spec get_variables_nd(t(), String.t()) :: map() | nil
  def get_variables_nd(problem, set_name) do
    Map.get(problem.variables, set_name)
  end

  @spec put_variables_nd(t(), String.t(), map()) :: t()
  def put_variables_nd(problem, set_name, var_map) do
    %{problem | variables: Map.put(problem.variables, set_name, var_map)}
  end

  # Private functions

  defp generate_constraint_id(counter) do
    "c#{String.pad_leading(to_string(counter), @nr_of_zeros, "0")}"
  end
end
