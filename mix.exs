defmodule Dantzig.MixProject do
  use Mix.Project

  @version "0.2.0"

  def project do
    [
      app: :dantzig,
      version: @version,
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: Mix.compilers() ++ [:download_solver_binary],
      aliases: [
        "compile.download_solver_binary": &download_solver_binary/1
      ],
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      name: "Dantzig",
      description: "Linear programming solver for Elixir",
      source_url: "https://github.com/tmbb/dantzig",
      docs: [
        main: "readme",
        extras: [
          "README.md",
          "docs/GETTING_STARTED.md",
          "docs/TUTORIAL.md",
          "docs/COMPREHENSIVE_TUTORIAL.md",
          "docs/MODELING_GUIDE.md",
          "docs/ARCHITECTURE.md",
          "docs/ADVANCED_AST.md",
          "docs/ARCHITECTURE.md",
          "docs/PATTERN_BASED_OPERATIONS.md",
          "docs/README_MACROS.md",
          "docs/VARIADIC_OPERATIONS.md"
        ],
        groups_for_modules: [
          Core: [
            Dantzig,
            Dantzig.Problem,
            Dantzig.ProblemVariable,
            Dantzig.Constraint,
            Dantzig.SolvedConstraint,
            Dantzig.Polynomial,
            Dantzig.Polynomial.Operators,
            Dantzig.Solution
          ],
          "AST & Macros": [
            Dantzig.AST,
            Dantzig.AST.Parser,
            Dantzig.AST.Analyzer,
            Dantzig.AST.Transformer,
            Dantzig.DSL
          ],
          Solver: [
            Dantzig.HiGHS,
            Dantzig.HiGHSDownloader,
            Dantzig.Config,
            Dantzig.Solution.Parser
          ]
        ]
      ]
    ]
  end

  defp download_solver_binary(_) do
    Dantzig.HiGHSDownloader.maybe_download_for_target()
  end

  def elixirc_paths(env) when env in [:dev, :test], do: ["lib", "test"]
  def elixirc_paths(:prod), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [
        :logger,
        :public_key,
        :crypto,
        inets: :optional,
        ssl: :optional
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nimble_parsec, "~> 1.4"},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false, warn_if_outdated: true},
      {:stream_data, "~> 1.1", only: [:test, :dev]}
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
