defmodule Dantzig.Solution do
  alias Dantzig.Solution.Parser
  alias Dantzig.Polynomial

  defstruct model_status: nil,
            feasibility: true,
            objective: nil,
            variables: %{},
            constraints: %{}

  def evaluate(%__MODULE__{} = _solution, number) when is_number(number), do: number

  def evaluate(%__MODULE__{} = solution, polynomial) do
    substituted = Polynomial.substitute(polynomial, solution.variables)

    case Polynomial.constant?(substituted) do
      true ->
        Map.get(substituted.simplified, [], 0.0)

      false ->
        substituted
    end
  end

  def nr_of_constraints(%__MODULE__{} = solution) do
    map_size(solution.constraints)
  end

  def nr_of_variables(%__MODULE__{} = solution) do
    map_size(solution.variables)
  end

  def from_file_contents(file_contents) do
    case Parser.parse(file_contents) do
      {:ok, opts} ->
        {:ok, struct(__MODULE__, opts)}

      {:error, _} ->
        :error
    end
  end

  def from_file_contents!(file_contents) do
    {:ok, result} = from_file_contents(file_contents)
    result
  end
end
