defmodule Dantzig.Timetabling.ConflictGraph do
  @moduledoc """
  Conflict graph data structures for timetabling problems.

  Based on the ITC 2019 graph-based MIP formulation, this module provides
  data structures for representing conflicts between classes, times, and rooms.
  """

  alias Dantzig.Polynomial

  @type vertex_id :: String.t()
  @type edge_weight :: number()
  @type graph_type :: :class_time | :class_room | :class_time_room | :hard | :soft

  @type t :: %__MODULE__{
          type: graph_type(),
          vertices: %{vertex_id() => vertex_data()},
          edges: %{vertex_id() => %{vertex_id() => edge_weight()}},
          metadata: map()
        }

  @type vertex_data :: %{
          class_id: String.t(),
          time_id: String.t() | nil,
          room_id: String.t() | nil,
          variable: Polynomial.t() | nil
        }

  defstruct type: :class_time,
            vertices: %{},
            edges: %{},
            metadata: %{}

  @doc """
  Create a new conflict graph of the specified type.
  """
  @spec new(graph_type()) :: t()
  def new(type) do
    %__MODULE__{type: type}
  end

  @doc """
  Add a vertex to the conflict graph.
  """
  @spec add_vertex(t(), vertex_id(), vertex_data()) :: t()
  def add_vertex(%__MODULE__{} = graph, vertex_id, vertex_data) do
    %{
      graph
      | vertices: Map.put(graph.vertices, vertex_id, vertex_data),
        edges: Map.put(graph.edges, vertex_id, %{})
    }
  end

  @doc """
  Add an edge between two vertices with optional weight.
  """
  @spec add_edge(t(), vertex_id(), vertex_id(), edge_weight()) :: t()
  def add_edge(%__MODULE__{} = graph, from_vertex, to_vertex, weight \\ 1.0) do
    # Ensure both vertices exist
    if Map.has_key?(graph.vertices, from_vertex) and Map.has_key?(graph.vertices, to_vertex) do
      updated_edges =
        graph.edges
        |> Map.update!(from_vertex, fn edges -> Map.put(edges, to_vertex, weight) end)
        |> Map.update!(to_vertex, fn edges -> Map.put(edges, from_vertex, weight) end)

      %{graph | edges: updated_edges}
    else
      graph
    end
  end

  @doc """
  Get all vertices in the graph.
  """
  @spec vertices(t()) :: [vertex_id()]
  def vertices(%__MODULE__{} = graph) do
    Map.keys(graph.vertices)
  end

  @doc """
  Get all edges in the graph.
  """
  @spec edges(t()) :: [{vertex_id(), vertex_id(), edge_weight()}]
  def edges(%__MODULE__{} = graph) do
    graph.edges
    |> Enum.flat_map(fn {from_vertex, edge_map} ->
      edge_map
      |> Enum.map(fn {to_vertex, weight} ->
        # Avoid double-counting by only including each edge once
        if from_vertex < to_vertex do
          {from_vertex, to_vertex, weight}
        else
          nil
        end
      end)
      |> Enum.filter(&(&1 != nil))
    end)
  end

  @doc """
  Get neighbors of a vertex.
  """
  @spec neighbors(t(), vertex_id()) :: [vertex_id()]
  def neighbors(%__MODULE__{} = graph, vertex_id) do
    case Map.get(graph.edges, vertex_id) do
      nil -> []
      edge_map -> Map.keys(edge_map)
    end
  end

  @doc """
  Get the weight of an edge between two vertices.
  """
  @spec edge_weight(t(), vertex_id(), vertex_id()) :: edge_weight() | nil
  def edge_weight(%__MODULE__{} = graph, from_vertex, to_vertex) do
    case Map.get(graph.edges, from_vertex) do
      nil -> nil
      edge_map -> Map.get(edge_map, to_vertex)
    end
  end

  @doc """
  Check if two vertices are connected by an edge.
  """
  @spec connected?(t(), vertex_id(), vertex_id()) :: boolean()
  def connected?(graph, from_vertex, to_vertex) do
    edge_weight(graph, from_vertex, to_vertex) != nil
  end

  @doc """
  Get vertex data for a given vertex.
  """
  @spec vertex_data(t(), vertex_id()) :: vertex_data() | nil
  def vertex_data(%__MODULE__{} = graph, vertex_id) do
    Map.get(graph.vertices, vertex_id)
  end

  @doc """
  Get all vertices for a specific class.
  """
  @spec vertices_for_class(t(), String.t()) :: [vertex_id()]
  def vertices_for_class(%__MODULE__{} = graph, class_id) do
    graph.vertices
    |> Enum.filter(fn {_vertex_id, data} -> data.class_id == class_id end)
    |> Enum.map(fn {vertex_id, _data} -> vertex_id end)
  end

  @doc """
  Get the degree (number of neighbors) of a vertex.
  """
  @spec degree(t(), vertex_id()) :: non_neg_integer()
  def degree(%__MODULE__{} = graph, vertex_id) do
    length(neighbors(graph, vertex_id))
  end

  @doc """
  Get all vertices sorted by degree (highest first).
  """
  @spec vertices_by_degree(t()) :: [vertex_id()]
  def vertices_by_degree(%__MODULE__{} = graph) do
    graph.vertices
    |> Enum.map(fn {vertex_id, _data} -> vertex_id end)
    |> Enum.sort_by(fn vertex_id -> degree(graph, vertex_id) end, :desc)
  end

  @doc """
  Create a class-time conflict graph vertex ID.
  """
  @spec class_time_vertex_id(String.t(), String.t()) :: vertex_id()
  def class_time_vertex_id(class_id, time_id) do
    "ct_#{class_id}_#{time_id}"
  end

  @doc """
  Create a class-room conflict graph vertex ID.
  """
  @spec class_room_vertex_id(String.t(), String.t()) :: vertex_id()
  def class_room_vertex_id(class_id, room_id) do
    "cr_#{class_id}_#{room_id}"
  end

  @doc """
  Create a class-time-room conflict graph vertex ID.
  """
  @spec class_time_room_vertex_id(String.t(), String.t(), String.t()) :: vertex_id()
  def class_time_room_vertex_id(class_id, time_id, room_id) do
    "ctr_#{class_id}_#{time_id}_#{room_id}"
  end

  @doc """
  Extract class, time, and room IDs from a vertex ID.
  """
  @spec parse_vertex_id(vertex_id()) :: {String.t() | nil, String.t() | nil, String.t() | nil}
  def parse_vertex_id(vertex_id) do
    case String.split(vertex_id, "_", parts: 3) do
      ["ct", class_id, time_id] -> {class_id, time_id, nil}
      ["cr", class_id, room_id] -> {class_id, nil, room_id}
      ["ctr", class_id, time_id, room_id] -> {class_id, time_id, room_id}
      _ -> {nil, nil, nil}
    end
  end

  @doc """
  Extract class, time, and room IDs from a vertex ID.
  """
  @spec parse_vertex_id(vertex_id()) :: {String.t() | nil, String.t() | nil, String.t() | nil}
  def parse_vertex_id(vertex_id) do
    case String.split(vertex_id, "_", parts: 3) do
      ["ct", class_id, time_id] -> {class_id, time_id, nil}
      ["cr", class_id, room_id] -> {class_id, nil, room_id}
      ["ctr", class_id, time_id, room_id] -> {class_id, time_id, room_id}
      _ -> {nil, nil, nil}
    end
  end

  @doc """
  Check if the graph is empty.
  """
  @spec empty?(t()) :: boolean()
  def empty?(%__MODULE__{} = graph) do
    map_size(graph.vertices) == 0
  end

  @doc """
  Get the number of vertices in the graph.
  """
  @spec size(t()) :: non_neg_integer()
  def size(%__MODULE__{} = graph) do
    map_size(graph.vertices)
  end

  @doc """
  Get the number of edges in the graph.
  """
  @spec edge_count(t()) :: non_neg_integer()
  def edge_count(%__MODULE__{} = graph) do
    length(edges(graph))
  end

  @doc """
  Create a subgraph containing only the specified vertices.
  """
  @spec subgraph(t(), [vertex_id()]) :: t()
  def subgraph(%__MODULE__{} = graph, vertex_ids) do
    vertex_set = MapSet.new(vertex_ids)

    # Filter vertices
    filtered_vertices =
      Map.filter(graph.vertices, fn {id, _} -> MapSet.member?(vertex_set, id) end)

    # Filter edges (only include edges where both vertices are in the subgraph)
    filtered_edges =
      graph.edges
      |> Enum.filter(fn {id, _} -> MapSet.member?(vertex_set, id) end)
      |> Enum.map(fn {id, edge_map} ->
        {id, Map.filter(edge_map, fn {target_id, _} -> MapSet.member?(vertex_set, target_id) end)}
      end)
      |> Enum.into(%{})

    %{graph | vertices: filtered_vertices, edges: filtered_edges}
  end

  @doc """
  Merge two conflict graphs of the same type.
  """
  @spec merge(t(), t()) :: t()
  def merge(%__MODULE__{type: type1} = graph1, %__MODULE__{type: type2} = graph2) do
    if type1 != type2 do
      raise ArgumentError, "Cannot merge graphs of different types: #{type1} vs #{type2}"
    end

    merged_vertices = Map.merge(graph1.vertices, graph2.vertices)

    merged_edges =
      Map.merge(graph1.edges, graph2.edges, fn _k, edges1, edges2 ->
        Map.merge(edges1, edges2, fn _k, w1, w2 -> max(w1, w2) end)
      end)

    %{graph1 | vertices: merged_vertices, edges: merged_edges}
  end

  @doc """
  Convert graph to a human-readable string representation.
  """
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = graph) do
    vertex_count = size(graph)
    edge_count = edge_count(graph)

    "ConflictGraph(#{graph.type}, vertices: #{vertex_count}, edges: #{edge_count})"
  end
end
