defmodule Dantzig.Config do
  @moduledoc false

  def default_solver_path() do
    :dantzig
    |> :code.priv_dir()
    |> Path.join("bin")
    |> Path.join("highs")
  end

  def get_solver_path() do
    case Application.fetch_env(:dantzig, :solver_path) do
      {:ok, value} ->
        value

      :error ->
        default_solver_path()
    end
  end

  def put_solver_path(value) do
    Application.put_env(:dantzig, :solver_path, value)
  end
end
