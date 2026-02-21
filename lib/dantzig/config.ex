defmodule Dantzig.Config do
  @moduledoc false

  @highs_version_file_basename "highs_version.txt"

  def default_highs_binary_path() do
    :dantzig
    |> :code.priv_dir()
    |> Path.join("bin")
    |> Path.join("highs")
  end

  def read_downloaded_version() do
    bin_path = default_highs_binary_path()
    bin_dir = Path.dirname(bin_path)
    vsn_path = Path.join(bin_dir, @highs_version_file_basename)

    case File.read(vsn_path) do
      {:ok, version} -> version
      {:error, _error} -> nil
    end
  end

  def persist_downloaded_version(version) do
    bin_path = default_highs_binary_path()
    bin_dir = Path.dirname(bin_path)
    vsn_path = Path.join(bin_dir, @highs_version_file_basename)

    File.write!(vsn_path, version)
  end

  # NOTE: from version 1.12 onwards, HiGHS uses an optimized
  # algorithm, which requires access to a dynamically linked
  # systems BLAS library (e.g. libopenblas.so on linux).
  # While Dantzig would certainly like using the latest and
  # most optimized version of HiGHS, requiring a BLAS library
  # requires the installation of external packages, which
  # goes against the philosophy of just adding the package
  # to your mix.exs file and having it run seamlessly.
  # For now, if the user wants to access HiGHS v1.12 or v1.13,
  # they have to manually specify binary version and set up
  # their machine correctly

  def get_highs_version() do
    Application.get_env(:dantzig, :highs_version, "1.11.0")
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
