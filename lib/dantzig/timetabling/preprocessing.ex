defmodule Dantzig.Timetabling.Preprocessing do
  @moduledoc """
  Preprocessing and data reduction techniques for timetabling problems.

  Implements the reduction algorithms described in the ITC 2019 paper
  to remove redundancies and improve problem solvability.
  """

  alias Dantzig.Timetabling.ConflictGraph
  alias Dantzig.Timetabling.DistributionConstraints

  @type reduction_result :: %{
          removed_constraints: [DistributionConstraints.distribution_constraint()],
          removed_vertices: [String.t()],
          removed_edges: [{String.t(), String.t()}],
          applied_reductions: [String.t()]
        }

  @doc """
  Apply all preprocessing reductions to a timetabling problem.
  """
  @spec reduce_problem(map()) :: map()
  def reduce_problem(problem) do
    reductions = %{
      removed_constraints: [],
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: []
    }

    # Apply constraint reductions
    {problem, constraint_reductions} = reduce_constraints(problem)

    # Apply graph-based reductions
    {problem, graph_reductions} = reduce_conflict_graphs(problem)

    # Combine all reductions
    all_reductions = merge_reductions([constraint_reductions, graph_reductions])

    # Update preprocessing metadata
    updated_preprocessing =
      Map.update!(problem.preprocessing, :reductions_applied, fn existing ->
        existing ++ all_reductions.applied_reductions
      end)

    %{problem | preprocessing: updated_preprocessing}
  end

  @doc """
  Reduce redundant distribution constraints.
  """
  @spec reduce_constraints(map()) :: {map(), reduction_result()}
  def reduce_constraints(problem) do
    constraints = problem.distribution_constraints

    reductions = %{
      removed_constraints: [],
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: []
    }

    # Remove constraints with single class
    {filtered_constraints, single_class_reductions} = remove_single_class_constraints(constraints)

    # Remove constraints with zero penalty (if soft)
    {filtered_constraints, zero_penalty_reductions} =
      remove_zero_penalty_constraints(filtered_constraints)

    # Remove constraints that generate no conflicts
    {filtered_constraints, no_conflict_reductions} =
      remove_no_conflict_constraints(filtered_constraints, problem)

    # Remove subset constraints
    {filtered_constraints, subset_reductions} = remove_subset_constraints(filtered_constraints)

    # Combine all constraint reductions
    all_constraint_reductions =
      merge_reductions([
        single_class_reductions,
        zero_penalty_reductions,
        no_conflict_reductions,
        subset_reductions
      ])

    updated_problem = %{problem | distribution_constraints: filtered_constraints}

    {updated_problem, all_constraint_reductions}
  end

  @doc """
  Apply graph-based reductions using conflict graphs.
  """
  @spec reduce_conflict_graphs(map()) :: {map(), reduction_result()}
  def reduce_conflict_graphs(problem) do
    reductions = %{
      removed_constraints: [],
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: []
    }

    # Reduce class-time graph
    {updated_graphs, time_reductions} =
      reduce_graph_by_fixed_vertices(problem.conflict_graphs.class_time)

    # Reduce class-room graph
    {updated_graphs, room_reductions} =
      reduce_graph_by_fixed_vertices(updated_graphs, :class_room)

    # Apply clique-based reductions
    {updated_graphs, clique_reductions} = reduce_graphs_by_cliques(updated_graphs)

    # Combine all graph reductions
    all_graph_reductions = merge_reductions([time_reductions, room_reductions, clique_reductions])

    updated_problem = %{problem | conflict_graphs: updated_graphs}

    {updated_problem, all_graph_reductions}
  end

  # Constraint reduction functions

  defp remove_single_class_constraints(constraints) do
    {single_class, multi_class} = Enum.split_with(constraints, fn c -> length(c.classes) < 2 end)

    reductions = %{
      removed_constraints: single_class,
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: ["single_class_constraints"]
    }

    {multi_class, reductions}
  end

  defp remove_zero_penalty_constraints(constraints) do
    {zero_penalty, valid_constraints} =
      Enum.split_with(constraints, fn c ->
        not c.is_hard and (c.penalty == nil or c.penalty == 0)
      end)

    reductions = %{
      removed_constraints: zero_penalty,
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: ["zero_penalty_constraints"]
    }

    {valid_constraints, reductions}
  end

  defp remove_no_conflict_constraints(constraints, problem) do
    # Generate temporary conflict graphs to check for conflicts
    temp_class_time_graph = generate_temp_conflict_graph(:class_time, constraints, problem)
    temp_class_room_graph = generate_temp_conflict_graph(:class_room, constraints, problem)

    {no_conflict, valid_constraints} =
      Enum.split_with(constraints, fn constraint ->
        graph_has_conflicts?(constraint, temp_class_time_graph, temp_class_room_graph)
      end)

    reductions = %{
      removed_constraints: no_conflict,
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: ["no_conflict_constraints"]
    }

    {valid_constraints, reductions}
  end

  defp remove_subset_constraints(constraints) do
    # Group constraints by type
    constraints_by_type = Enum.group_by(constraints, fn c -> c.type end)

    {subset_constraints, valid_constraints} =
      Enum.split_with(constraints, fn constraint ->
        constraint_type = constraint.type
        same_type_constraints = Map.get(constraints_by_type, constraint_type, [])

        # Check if this constraint's classes are a subset of another constraint's classes
        Enum.any?(same_type_constraints, fn other_constraint ->
          other_constraint != constraint and
            MapSet.subset?(MapSet.new(constraint.classes), MapSet.new(other_constraint.classes))
        end)
      end)

    reductions = %{
      removed_constraints: subset_constraints,
      removed_vertices: [],
      removed_edges: [],
      applied_reductions: ["subset_constraints"]
    }

    {valid_constraints, reductions}
  end

  # Graph reduction functions

  defp reduce_graph_by_fixed_vertices(graph, graph_type \\ :class_time) do
    # Find fixed vertices (classes with only one possible time/room)
    fixed_vertices = find_fixed_vertices(graph)

    # Remove neighbors of fixed vertices (they create conflicts)
    {reduced_graph, removed_vertices} = remove_fixed_vertex_neighbors(graph, fixed_vertices)

    reductions = %{
      removed_constraints: [],
      removed_vertices: removed_vertices,
      removed_edges: [],
      applied_reductions: ["fixed_vertices_#{graph_type}"]
    }

    {reduced_graph, reductions}
  end

  defp reduce_graphs_by_cliques(graphs) do
    # Apply clique-based reductions to each graph
    {updated_class_time, time_clique_reductions} = reduce_graph_by_cliques(graphs.class_time)
    {updated_class_room, room_clique_reductions} = reduce_graph_by_cliques(graphs.class_room)

    updated_graphs = %{
      class_time: updated_class_time,
      class_room: updated_class_room,
      class_time_room: graphs.class_time_room
    }

    all_reductions = merge_reductions([time_clique_reductions, room_clique_reductions])

    {updated_graphs, all_reductions}
  end

  defp reduce_graph_by_cliques(graph) do
    # Find cliques in the graph
    cliques = find_cliques(graph)

    # Apply clique-based reductions
    {reduced_graph, clique_reductions} = apply_clique_reductions(graph, cliques)

    {reduced_graph, clique_reductions}
  end

  # Helper functions

  defp generate_temp_conflict_graph(graph_type, constraints, problem) do
    # Generate a temporary conflict graph for analysis
    case graph_type do
      :class_time ->
        ConflictGraph.new(:class_time)
        |> add_temp_vertices(:class_time, problem)
        |> DistributionConstraints.add_class_time_conflicts(constraints)

      :class_room ->
        ConflictGraph.new(:class_room)
        |> add_temp_vertices(:class_room, problem)
        |> DistributionConstraints.add_class_room_conflicts(constraints)
    end
  end

  defp add_temp_vertices(graph, graph_type, problem) do
    # Add vertices for the graph type
    case graph_type do
      :class_time ->
        Enum.reduce(problem.classes, graph, fn {class_id, class_data}, acc_graph ->
          available_times = Map.get(class_data, :available_times, [])

          Enum.reduce(available_times, acc_graph, fn time_id, acc_acc_graph ->
            vertex_id = ConflictGraph.class_time_vertex_id(class_id, time_id)
            vertex_data = %{class_id: class_id, time_id: time_id, room_id: nil}
            ConflictGraph.add_vertex(acc_acc_graph, vertex_id, vertex_data)
          end)
        end)

      :class_room ->
        Enum.reduce(problem.classes, graph, fn {class_id, class_data}, acc_graph ->
          available_rooms = Map.get(class_data, :available_rooms, [])

          Enum.reduce(available_rooms, acc_graph, fn room_id, acc_acc_graph ->
            vertex_id = ConflictGraph.class_room_vertex_id(class_id, room_id)
            vertex_data = %{class_id: class_id, time_id: nil, room_id: room_id}
            ConflictGraph.add_vertex(acc_acc_graph, vertex_id, vertex_data)
          end)
        end)
    end
  end

  defp graph_has_conflicts?(constraint, class_time_graph, class_room_graph) do
    # Check if a constraint generates any conflicts in the graphs
    # This is a simplified check - full implementation would analyze the specific constraint
    false
  end

  defp find_fixed_vertices(graph) do
    # Find vertices that represent classes with only one option
    graph.vertices
    |> Enum.filter(fn {_vertex_id, vertex_data} ->
      # Check if this is the only vertex for this class
      class_id = vertex_data.class_id
      class_vertices = ConflictGraph.vertices_for_class(graph, class_id)
      length(class_vertices) == 1
    end)
    |> Enum.map(fn {vertex_id, _} -> vertex_id end)
  end

  defp remove_fixed_vertex_neighbors(graph, fixed_vertices) do
    # Remove all neighbors of fixed vertices
    {remaining_vertices, removed_vertices} =
      Enum.split_with(graph.vertices, fn {vertex_id, _} ->
        vertex_id not in fixed_vertices and
          not Enum.any?(fixed_vertices, fn fixed_id ->
            ConflictGraph.connected?(graph, vertex_id, fixed_id)
          end)
      end)

    # Rebuild graph with only remaining vertices
    reduced_graph =
      Enum.reduce(remaining_vertices, ConflictGraph.new(graph.type), fn {vertex_id, vertex_data},
                                                                        acc ->
        ConflictGraph.add_vertex(acc, vertex_id, vertex_data)
      end)

    # Add back edges between remaining vertices
    reduced_graph =
      Enum.reduce(ConflictGraph.edges(graph), reduced_graph, fn {v1, v2, weight} ->
        if Map.has_key?(reduced_graph.vertices, v1) and Map.has_key?(reduced_graph.vertices, v2) do
          ConflictGraph.add_edge(reduced_graph, v1, v2, weight)
        else
          reduced_graph
        end
      end)

    {reduced_graph, removed_vertices |> Enum.map(fn {vertex_id, _} -> vertex_id end)}
  end

  defp find_cliques(graph) do
    # Simplified clique finding - in practice, would use a proper clique algorithm
    # For now, return empty list (no clique-based reductions)
    []
  end

  defp apply_clique_reductions(graph, cliques) do
    # Apply reductions based on found cliques
    # This would implement the clique reduction logic from the paper
    {graph,
     %{removed_constraints: [], removed_vertices: [], removed_edges: [], applied_reductions: []}}
  end

  defp merge_reductions(reductions_list) do
    Enum.reduce(
      reductions_list,
      %{removed_constraints: [], removed_vertices: [], removed_edges: [], applied_reductions: []},
      fn reduction, acc ->
        %{
          removed_constraints: acc.removed_constraints ++ reduction.removed_constraints,
          removed_vertices: acc.removed_vertices ++ reduction.removed_vertices,
          removed_edges: acc.removed_edges ++ reduction.removed_edges,
          applied_reductions: acc.applied_reductions ++ reduction.applied_reductions
        }
      end
    )
  end

  @doc """
  Get statistics about the reductions applied.
  """
  @spec get_reduction_stats(map()) :: map()
  def get_reduction_stats(problem) do
    %{
      constraints_reduced: length(problem.preprocessing.reductions_applied),
      applied_reductions: problem.preprocessing.reductions_applied
    }
  end
end
