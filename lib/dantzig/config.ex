defmodule Dantzig.Config do
  @moduledoc false

  def default_highs_binary_path() do
    :dantzig
    |> :code.priv_dir()
    |> Path.join("bin")
    |> Path.join("highs")
  end

  def get_highs_version() do
    Application.get_env(:dantzig, :highs_version, "1.8.0")
  end

  def get_highs_binary_path() do
    case Application.fetch_env(:dantzig, :highs_binary_path) do
      {:ok, value} ->
        value

      :error ->
        default_highs_binary_path()
    end
  end

  def put_highs_binary_path(value) do
    Application.put_env(:dantzig, :highs_binary_path, value)
  end
end
