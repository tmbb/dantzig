defmodule Dantzig.HiGHSDownloader do
  alias Dantzig.Config
  require Logger

  @highs_version "1.9.0"

  # Available targets: https://github.com/evanw/esbuild/tree/main/npm/@esbuild
  def target() do
    # Get erlang's interpretation of what the system architecture is
    arch_str = :erlang.system_info(:system_architecture)
    # Split the architecture string into its component parts
    parts = arch_str |> List.to_string() |> String.split("-")
    [arch | rest] = parts
    [os, suffix] = Enum.take(rest, -2)

    case {arch, os, suffix} do
      {"aarch64", "apple", "darwin"} -> "aarch64-apple-darwin"
      {"aarch64", "linux", "gnu"} -> "aarch64-linux-gnu-cxx11"
      {"aarch64", "linux", "musl"} -> "aarch64-linux-musl-cxx11"
      {"aarch64", "unknown", "freebsd"} -> "aarch64-unknown-freebsd"
      {"x86_64", "apple", "darwin"} -> "x86_64-apple-darwin"
      {"x86_64", "linux", "gnu"} -> "x86_64-linux-gnu-cxx11"
      {"x86_64", "linux", "musl"} -> "x86_64-linux-musl-cxx11"
      {"x86_64", "unknown", "freebsd"} -> "x86_64-unknown-freebsd"
      {"x86_64", "w64", "mingw32"} -> "x86_64-w64-mingw32"
    end
  end

  @base_url (
    "https://github.com/JuliaBinaryWrappers/" <>
    "HiGHSstatic_jll.jl/releases/download/" <>
    "HiGHSstatic-v#{@highs_version}%2B0/"
  )

  defp tar_gz_url(target) do
    @base_url <> "HiGHSstatic.v#{@highs_version}.#{target}.tar.gz"
  end

  defp fetch_file!(url) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    {:ok, resp} = :httpc.request(:get, {to_charlist(url), []}, [], [body_format: :binary])
    {{_, 200, 'OK'}, _headers, body} = resp

    body
  end

  def maybe_download_for_target() do
    case File.exists?(Config.get_solver_path()) do
      true ->
        :ok

      false ->
        download_for_target(target())
    end
  end

  def download_for_target(target) do
    url = tar_gz_url(target)

    Logger.debug("Downloading HiGHS solver from #{url}")

    tar_archive = fetch_file!(url)

    random_suffix = 1..100_000_000 |> Enum.random() |> to_string()
    unpack_dir = "unpacked_#{random_suffix}"
    tmp_dir = System.tmp_dir!() |> Path.join(unpack_dir)

    unpacked =
      :erl_tar.extract({:binary, tar_archive}, [
        :compressed,
        files: ['bin/highs'],
        cwd: to_charlist(tmp_dir)
      ])

    case unpacked do
      :ok -> :ok
      {:error, :eof} ->
        # Even if `:erl_tar.extract/2` return this error,
        # it seems like it unpacks the file correctly
        :ok
      other -> raise "couldn't unpack archive: #{inspect(other)}"
    end

    bin_path = Path.join([tmp_dir, "bin", "highs"])

    dst_path = Config.default_solver_path()

    # Create the destination directory if
    # it does not exist
    dst_path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.cp!(bin_path, dst_path)

    :ok
  end
end
