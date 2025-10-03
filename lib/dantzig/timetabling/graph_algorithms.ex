defmodule Dantzig.Timetabling.GraphAlgorithms do
  @moduledoc """
  Graph algorithms for constraint generation in timetabling problems.

  Implements clique covers, star covers, and other graph algorithms
  described in the ITC 2019 paper for generating efficient constraints.
  """

  alias Dantzig.Timetabling.ConflictGraph

  @type clique :: [String.t()]
  @type star :: %{center: String.t(), leaves: [String.t()]}
  @type clique_cover :: [clique()]
  @type star_cover :: [star()]

  @doc """
  Generate a clique cover for a conflict graph.

  A clique cover finds groups of vertices where every pair is connected,
  allowing us to generate at-most-one constraints for hard conflicts.
  """
  @spec clique_cover(ConflictGraph.t()) :: clique_cover()
  def clique_cover(graph) do
    # Use a greedy approach to find cliques
    vertices = ConflictGraph.vertices_by_degree(graph)
    {cover, _used_vertices} = find_clique_cover(vertices, graph, [], MapSet.new())

    cover
  end

  @doc """
  Generate a star cover for a conflict graph.

  A star cover finds center vertices and their neighbors, allowing us
  to generate constraints where either the center or any leaf can be selected.
  """
  @spec star_cover(ConflictGraph.t()) :: star_cover()
  def star_cover(graph) do
    vertices = ConflictGraph.vertices_by_degree(graph)
    {cover, _used_vertices} = find_star_cover(vertices, graph, [], MapSet.new())

    cover
  end

  @doc """
  Generate a special star cover for soft constraints.

  Special stars group vertices by edge weights and class membership.
  """
  @spec special_star_cover(ConflictGraph.t()) :: star_cover()
  def special_star_cover(graph) do
    # Group edges by weight
    edge_groups = group_edges_by_weight(graph)

    # Generate star covers for each weight group
    Enum.flat_map(edge_groups, fn {weight, subgraph} ->
      vertices = ConflictGraph.vertices_by_degree(subgraph)
      {cover, _used} = find_special_star_cover(vertices, subgraph, [], MapSet.new(), weight)
      cover
    end)
  end

  @doc """
  Generate a complete bipartite cover for overlap conflicts.

  Used for modeling conflicts between two classes where at most one
  vertex can be selected from the combined set.
  """
  @spec complete_bipartite_cover(ConflictGraph.t()) :: [clique()]
  def complete_bipartite_cover(graph) do
    # Find connected components (should be bipartite for two classes)
    components = find_connected_components(graph)

    Enum.flat_map(components, fn component ->
      generate_bipartite_cliques(component, graph)
    end)
  end

  @doc """
  Find odd cycles in the conflict graph for additional constraints.
  """
  @spec find_odd_cycles(ConflictGraph.t()) :: [[String.t()]]
  def find_odd_cycles(graph) do
    # Use DFS to find odd cycles
    vertices = ConflictGraph.vertices(graph)
    find_odd_cycles_from_vertices(vertices, graph, [])
  end

  # Private helper functions

  defp find_clique_cover([], _graph, cover, _used), do: {cover, MapSet.new()}

  defp find_clique_cover([vertex | rest], graph, cover, used) do
    if MapSet.member?(used, vertex) do
      find_clique_cover(rest, graph, cover, used)
    else
      # Find a clique starting from this vertex
      clique = grow_clique([vertex], graph)

      if length(clique) > 1 do
        # Only add cliques with more than one vertex
        new_cover = [clique | cover]
        new_used = Enum.reduce(clique, used, fn v, acc -> MapSet.put(acc, v) end)
        find_clique_cover(rest, graph, new_cover, new_used)
      else
        find_clique_cover(rest, graph, cover, used)
      end
    end
  end

  defp grow_clique(clique, graph) do
    # Try to add vertices that are connected to all existing clique members
    candidates = find_clique_candidates(clique, graph)

    case candidates do
      [] ->
        clique

      [candidate | _] ->
        # Add the candidate and recurse
        new_clique = [candidate | clique]
        grow_clique(new_clique, graph)
    end
  end

  defp find_clique_candidates(clique, graph) do
    # Find vertices connected to all clique members
    non_clique_vertices = ConflictGraph.vertices(graph) -- clique

    Enum.filter(non_clique_vertices, fn candidate ->
      Enum.all?(clique, fn member ->
        ConflictGraph.connected?(graph, candidate, member)
      end)
    end)
  end

  defp find_star_cover([], _graph, cover, _used), do: {cover, MapSet.new()}

  defp find_star_cover([vertex | rest], graph, cover, used) do
    if MapSet.member?(used, vertex) do
      find_star_cover(rest, graph, cover, used)
    else
      # Create a star with this vertex as center
      neighbors = ConflictGraph.neighbors(graph, vertex)
      unvisited_neighbors = Enum.filter(neighbors, fn n -> not MapSet.member?(used, n) end)

      if Enum.empty?(unvisited_neighbors) do
        find_star_cover(rest, graph, cover, used)
      else
        star = %{center: vertex, leaves: unvisited_neighbors}
        new_cover = [star | cover]

        new_used =
          Enum.reduce([vertex | unvisited_neighbors], used, fn v, acc -> MapSet.put(acc, v) end)

        find_star_cover(rest, graph, new_cover, new_used)
      end
    end
  end

  defp find_special_star_cover([], _graph, cover, _used, _weight), do: {cover, MapSet.new()}

  defp find_special_star_cover([vertex | rest], graph, cover, used, weight) do
    if MapSet.member?(used, vertex) do
      find_special_star_cover(rest, graph, cover, used, weight)
    else
      # Group neighbors by class
      neighbors = ConflictGraph.neighbors(graph, vertex)
      unvisited_neighbors = Enum.filter(neighbors, fn n -> not MapSet.member?(used, n) end)

      if Enum.empty?(unvisited_neighbors) do
        find_special_star_cover(rest, graph, cover, used, weight)
      else
        # Group neighbors by class
        neighbors_by_class = group_neighbors_by_class(unvisited_neighbors, graph)

        # Create special stars for each class group
        new_stars =
          Enum.map(neighbors_by_class, fn {class_id, class_neighbors} ->
            %{center: vertex, leaves: class_neighbors, class: class_id, weight: weight}
          end)

        new_cover = new_stars ++ cover

        new_used =
          Enum.reduce([vertex | unvisited_neighbors], used, fn v, acc -> MapSet.put(acc, v) end)

        find_special_star_cover(rest, graph, new_cover, new_used, weight)
      end
    end
  end

  defp group_neighbors_by_class(neighbors, graph) do
    Enum.group_by(neighbors, fn neighbor ->
      vertex_data = ConflictGraph.vertex_data(graph, neighbor)
      vertex_data.class_id
    end)
  end

  defp group_edges_by_weight(graph) do
    edges = ConflictGraph.edges(graph)

    edges
    |> Enum.group_by(fn {_v1, _v2, weight} -> weight end)
    |> Enum.map(fn {weight, edge_list} ->
      # Create subgraph for this weight
      subgraph = create_weight_subgraph(graph, edge_list, weight)
      {weight, subgraph}
    end)
  end

  defp create_weight_subgraph(original_graph, edges, weight) do
    # Create a new graph with only edges of the specified weight
    subgraph = ConflictGraph.new(original_graph.type)

    # Add all vertices from the original graph
    subgraph =
      Enum.reduce(ConflictGraph.vertices(original_graph), subgraph, fn vertex_id, acc ->
        vertex_data = ConflictGraph.vertex_data(original_graph, vertex_id)
        ConflictGraph.add_vertex(acc, vertex_id, vertex_data)
      end)

    # Add only edges with the specified weight
    subgraph =
      Enum.reduce(edges, subgraph, fn {v1, v2, edge_weight}, acc ->
        if edge_weight == weight do
          ConflictGraph.add_edge(acc, v1, v2, weight)
        else
          acc
        end
      end)

    subgraph
  end

  defp find_connected_components(graph) do
    vertices = ConflictGraph.vertices(graph)
    find_components(vertices, graph, [])
  end

  defp find_components([], _graph, components), do: components

  defp find_components([vertex | rest], graph, components) do
    if Enum.any?(components, fn component -> vertex in component end) do
      find_components(rest, graph, components)
    else
      # Start BFS from this vertex to find the component
      component = bfs_component([vertex], graph, MapSet.new([vertex]))
      find_components(rest, graph, [component | components])
    end
  end

  defp bfs_component(queue, graph, visited) do
    case queue do
      [] ->
        MapSet.to_list(visited)

      [vertex | rest] ->
        neighbors = ConflictGraph.neighbors(graph, vertex)
        unvisited_neighbors = Enum.filter(neighbors, fn n -> not MapSet.member?(visited, n) end)

        new_visited =
          Enum.reduce(unvisited_neighbors, visited, fn n, acc -> MapSet.put(acc, n) end)

        new_queue = rest ++ unvisited_neighbors

        bfs_component(new_queue, graph, new_visited)
    end
  end

  defp generate_bipartite_cliques(component, graph) do
    # For a bipartite graph, find the two partitions and generate cliques
    # This is a simplified implementation
    vertices = Enum.sort(component)

    case vertices do
      [] ->
        []

      [_single] ->
        [[hd(vertices)]]

      vertices ->
        # Split into two groups (simplified bipartition)
        {group1, group2} = Enum.split(vertices, div(length(vertices), 2))

        # Generate complete bipartite cliques
        for v1 <- group1, v2 <- group2 do
          [v1, v2]
        end
    end
  end

  defp find_odd_cycles_from_vertices([], _graph, cycles), do: cycles

  defp find_odd_cycles_from_vertices([vertex | rest], graph, cycles) do
    # Use DFS to find cycles starting from this vertex
    new_cycles =
      find_cycles_from_vertex(vertex, graph, vertex, [vertex], MapSet.new([vertex]), cycles)

    find_odd_cycles_from_vertices(rest, graph, new_cycles)
  end

  defp find_cycles_from_vertex(start_vertex, graph, current_vertex, path, visited, cycles) do
    # Look for cycles by checking neighbors
    neighbors = ConflictGraph.neighbors(graph, current_vertex)

    Enum.reduce(neighbors, cycles, fn neighbor, acc_cycles ->
      if neighbor == start_vertex and length(path) >= 3 do
        # Found a cycle
        cycle = Enum.reverse(path)

        if rem(length(cycle), 2) == 1 do
          # It's an odd cycle
          [cycle | acc_cycles]
        else
          acc_cycles
        end
      else
        if not MapSet.member?(visited, neighbor) and neighbor != start_vertex do
          # Continue DFS
          new_path = [neighbor | path]
          new_visited = MapSet.put(visited, neighbor)

          find_cycles_from_vertex(
            start_vertex,
            graph,
            neighbor,
            new_path,
            new_visited,
            acc_cycles
          )
        else
          acc_cycles
        end
      end
    end)
  end

  @doc """
  Convert a clique cover to constraint expressions.
  """
  @spec cliques_to_constraints(clique_cover(), ConflictGraph.t()) :: [any()]
  def cliques_to_constraints(clique_cover, graph) do
    Enum.map(clique_cover, fn clique ->
      # Generate at-most-one constraint for the clique
      generate_clique_constraint(clique, graph)
    end)
  end

  @doc """
  Convert a star cover to constraint expressions.
  """
  @spec stars_to_constraints(star_cover(), ConflictGraph.t()) :: [any()]
  def stars_to_constraints(star_cover, graph) do
    Enum.map(star_cover, fn star ->
      # Generate star constraint
      generate_star_constraint(star, graph)
    end)
  end

  defp generate_clique_constraint(clique, graph) do
    # Generate constraint: at most one vertex in clique can be selected
    # This would return a constraint expression for the Dantzig solver
    {:clique_constraint, clique}
  end

  defp generate_star_constraint(star, graph) do
    # Generate constraint: center or any leaf can be selected
    # This would return a constraint expression for the Dantzig solver
    {:star_constraint, star}
  end

  @doc """
  Get statistics about the graph algorithms results.
  """
  @spec get_algorithm_stats(ConflictGraph.t(), clique_cover(), star_cover()) :: map()
  def get_algorithm_stats(graph, clique_cover, star_cover) do
    %{
      graph_vertices: ConflictGraph.size(graph),
      graph_edges: ConflictGraph.edge_count(graph),
      clique_cover_size: length(clique_cover),
      star_cover_size: length(star_cover),
      average_clique_size:
        if(Enum.empty?(clique_cover),
          do: 0,
          else: Enum.sum_by(clique_cover, &length/1) / length(clique_cover)
        ),
      average_star_size:
        if(Enum.empty?(star_cover),
          do: 0,
          else: Enum.sum_by(star_cover, fn s -> length(s.leaves) + 1 end) / length(star_cover)
        )
    }
  end
end
