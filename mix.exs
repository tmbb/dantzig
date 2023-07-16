defmodule Dantzig.MixProject do
  use Mix.Project

  def project do
    [
      app: :dantzig,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  def elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test/support"]
  def elixirc_paths(:prod), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.0"},
      {:stream_data, "~> 0.5", only: [:test, :dev]}
    ]
  end
end
