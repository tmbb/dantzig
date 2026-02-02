defmodule Dantzig.HiGHSDownloader do
  alias Dantzig.Config
  require Logger

  @external_resource Dantzig.Config.get_highs_binary_path()

  def maybe_download_for_target() do
    downloaded_version = Config.read_downloaded_version()
    highs_version = Config.get_highs_version()
    binary_path = Config.get_highs_binary_path()
    default_binary_path = Config.default_highs_binary_path()

    # We only download the binary if the user hasn't specified
    # a new binary path. If users decide to use a different binary,
    # they're on their own.
    if default_binary_path == binary_path do
      # The user hasn't specified a custom path;
      # We'll download the binary if appropriate.
      case {File.exists?(binary_path), downloaded_version == highs_version} do
        {true, true} ->
          # The binary exists and the version matches the one given by the user;
          # Do nothing
          :ok

        {false, true} ->
          # For some reason, we have a version file but not a binary.
          # Download the binary again
          download_for_target(highs_version, target())

        {_, false} ->
          # The current version doesn't match the one given by the user.
          # Download the binary again and write a new version number
          download_for_target(highs_version, target())
      end
    else
      # Do nothing
      :ok
    end
  end

  def download_for_target(version, target) do
    url = tar_gz_url(version, target)

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

    dst_path = Config.default_highs_binary_path()

    # Create the destination directory if
    # it does not exist
    dst_dir = Path.dirname(dst_path)
    File.mkdir_p!(dst_dir)

    # Write the artifact and version number
    # (overwriting previously written files if needed)
    Config.persist_downloaded_version(version)
    File.cp!(bin_path, dst_path)

    :ok
  end

  # Available targets: https://github.com/evanw/esbuild/tree/main/npm/@esbuild
  def target() do
    # Get erlang's interpretation of what the system architecture is
    arch_str = :erlang.system_info(:system_architecture)
    # Split the architecture string into its component parts
    parts = arch_str |> List.to_string() |> String.split("-")
    [arch | rest] = parts
    [os, suffix] = Enum.take(rest, -2)

    case {arch, os, suffix} do
      {"aarch64", "apple", "darwin" <> _} -> "aarch64-apple-darwin"
      {"aarch64", "linux", "gnu"} -> "aarch64-linux-gnu-cxx11"
      {"aarch64", "linux", "musl"} -> "aarch64-linux-musl-cxx11"
      {"aarch64", "unknown", "freebsd"} -> "aarch64-unknown-freebsd"
      {"i686", "linux", "gnu"} -> "i686-linux-gnu-cxx11"
      {"i686", "linux", "musl"} -> "i686-linux-gnu-cxx11"
      {"x86_64", "apple", "darwin"} -> "x86_64-apple-darwin"
      {"x86_64", "linux", "gnu"} -> "x86_64-linux-gnu-cxx11"
      {"x86_64", "linux", "musl"} -> "x86_64-linux-musl-cxx11"
      {"x86_64", "unknown", "freebsd"} -> "x86_64-unknown-freebsd"
      {"x86_64", "w64", "mingw32"} -> "x86_64-w64-mingw32"
    end
  end

  defp tar_gz_url(highs_version, target) do
    "https://github.com/JuliaBinaryWrappers/" <>
    "HiGHSstatic_jll.jl/releases/download/" <>
    "HiGHSstatic-v#{highs_version}%2B0/" <>
    "HiGHSstatic.v#{highs_version}.#{target}.tar.gz"
  end

  defp fetch_file!(url, retry \\ true) do
    {:ok, _} = Application.ensure_all_started(:inets)
    {:ok, _} = Application.ensure_all_started(:ssl)

    case {retry, do_fetch(url)} do
      {_, {:ok, {{_, 200, _}, _headers, body}}} ->
        body

      {true, {:error, {:failed_connect, [{:to_address, _}, {inet, _, reason}]}}}
      when inet in [:inet, :inet6] and
             reason in [:ehostunreach, :enetunreach, :eprotonosupport, :nxdomain] ->
        :httpc.set_options(ipfamily: fallback(inet))
        fetch_file!(url, false)

      other ->
        raise """
        couldn't fetch #{url}: #{inspect(other)}

        You may also install the "highs" executable manually.
        """
    end
  end

  defp fallback(:inet), do: :inet6
  defp fallback(:inet6), do: :inet

  defp do_fetch(url) do
    scheme = URI.parse(url).scheme
    url = String.to_charlist(url)

    :httpc.request(
      :get,
      {url, []},
      [
        ssl: [
          verify: :verify_peer,
          # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
          cacerts: :public_key.cacerts_get(),
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]
      |> maybe_add_proxy_auth(scheme),
      body_format: :binary
    )
  end

  defp proxy_for_scheme("http") do
    System.get_env("HTTP_PROXY") || System.get_env("http_proxy")
  end

  defp proxy_for_scheme("https") do
    System.get_env("HTTPS_PROXY") || System.get_env("https_proxy")
  end

  defp maybe_add_proxy_auth(http_options, scheme) do
    case proxy_auth(scheme) do
      nil -> http_options
      auth -> [{:proxy_auth, auth} | http_options]
    end
  end

  defp proxy_auth(scheme) do
    with proxy when is_binary(proxy) <- proxy_for_scheme(scheme),
         %{userinfo: userinfo} when is_binary(userinfo) <- URI.parse(proxy),
         [username, password] <- String.split(userinfo, ":") do
      {String.to_charlist(username), String.to_charlist(password)}
    else
      _ -> nil
    end
  end
end
