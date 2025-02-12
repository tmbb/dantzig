defmodule Dantzig.ConstraintMetadata do
  @moduledoc """
  Constraint metadata for debugging purposes.
  """

  @type t :: %__MODULE__{}

  defstruct app: nil,
            module: nil,
            file: nil,
            line: nil,
            tags: [],
            attrs: %{}

  @doc """
  Create a metadata struct from an environment (e.g. `__ENV__`, `__CALLER__`),
  and some extra attributes.

  Supports the following extra attributes:

    - `:tags` (*optional*, default: [])
    - `:attrs` (*optional*, default: [])
  """
  def from_env(env, extra \\ []) do
    app = Application.get_application(env.module)

    %__MODULE__{
      app: app,
      module: env.module,
      file: env.file,
      line: env.line,
      tags: Keyword.get(extra, :tags, []),
      attrs: Keyword.get(extra, :attrs, %{})
    }
  end

  @doc """
  Updates a metadata struct withn extra attributes.

  Supports the following extra attributes:

    - `:tags` (*optional*, default: [])
    - `:attrs` (*optional*, default: [])

  If the `:app` field isn't present, the function will attempt
  to get the `:app` value from the given `:module`.
  If the metadata was created from an environment,
  sometimes the application name can't be deduced at
  compile time, and if this function runs at runtime,
  it will pretty much always be able to get the application
  from the module name.
  """
  def update(metadata, extra) do
    # Create an actual metadata struct if it doesn't exist
    metadata = metadata || %__MODULE__{}

    # Try to find the app at runtime if it couldn't be found
    # at compile-time
    app =
      case {metadata.app, metadata.module} do
        {nil, nil} ->
          nil

        {nil, module} ->
          Application.get_application(module)

        {app, _module} ->
          app
      end

    new_tags = Keyword.get(extra, :tags, [])
    new_attrs = Keyword.get(extra, :attrs, %{})

    all_tags = metadata.tags ++ new_tags
    all_attrs = Map.merge(metadata.attrs, new_attrs)

    %{metadata | app: app, tags: all_tags, attrs: all_attrs}
  end

  @doc """
  Converts constraint metadata into a comment in the `.lp` file format.

  Supports `nil` as an argument, so it can be used for constraints without metadata.
  """
  def to_lp_comment(nil), do: ""

  def to_lp_comment(metadata) do
    location_line =
      case metadata.file do
        nil ->
          ""

        file ->
          relative_path = Path.relative_to(file, File.cwd!())
          "  \\\\ location: #{relative_path}:#{metadata.line}\n"
      end

    tags = inspect(metadata.tags)

    [
      "  \\\\ app: #{inspect(metadata.app)} | module: #{inspect(metadata.module)}\n",
      location_line,
      "  \\\\ tags: #{tags}\n"
    ]
  end
end
