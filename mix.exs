defmodule Dantzig.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :dantzig,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "Danztig",
      description: "Linear progamming solver for elixir",
      source_url: "https://github.com/tmbb/dantzig"
    ]
  end

  def elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  def elixirc_paths(:prod), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Dantzig.Application, []},
      extra_applications: [
        :logger,
        :public_key,
        :crypto,
        inets: :optional,
        ssl: :optional]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:stream_data, "~> 0.5", only: [:test, :dev]}
    ]
  end

  defp package() do
    [
      # These are the default files included in the package
      files: ~w(lib priv .formatter.exs mix.exs README* LICENSE* CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/tmbb/dantzig"}
    ]
  end
end
