defmodule Dantzig.ConstraintMetadata do
  defstruct app: nil,
            module: nil,
            file: nil,
            line: nil,
            tags: [],
            attrs: %{}

  def from_env(env, extra) do
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
