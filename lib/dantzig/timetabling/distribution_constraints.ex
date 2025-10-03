defmodule Dantzig.Timetabling.DistributionConstraints do
  @moduledoc """
  Implementation of the 19 distribution constraint types from ITC 2019.

  This module handles the logic for generating conflicts in the various
  conflict graphs based on the different types of distribution constraints.
  """

  alias Dantzig.Timetabling.ConflictGraph

  @type constraint_type ::
          :SameStart
          | :SameTime
          | :SameDays
          | :SameWeeks
          | :SameRoom
          | :DifferentTime
          | :DifferentDays
          | :DifferentWeeks
          | :DifferentRoom
          | :NotOverlap
          | :Overlap
          | :SameAttendees
          | :Precedence
          | :Workday
          | :MinGap
          | :MaxDays
          | :MaxDayLoad
          | :MaxBreaks
          | :MaxBlock

  @type distribution_constraint :: %{
          type: constraint_type(),
          classes: [String.t()],
          parameters: map(),
          penalty: number() | nil,
          is_hard: boolean()
        }

  @doc """
  Add conflicts to class-time conflict graph based on distribution constraints.
  """
  @spec add_class_time_conflicts(ConflictGraph.t(), [distribution_constraint()]) ::
          ConflictGraph.t()
  def add_class_time_conflicts(graph, constraints) do
    Enum.reduce(constraints, graph, fn constraint, acc_graph ->
      add_constraint_to_class_time_graph(acc_graph, constraint)
    end)
  end

  @doc """
  Add conflicts to class-room conflict graph based on distribution constraints.
  """
  @spec add_class_room_conflicts(ConflictGraph.t(), [distribution_constraint()]) ::
          ConflictGraph.t()
  def add_class_room_conflicts(graph, constraints) do
    Enum.reduce(constraints, graph, fn constraint, acc_graph ->
      add_constraint_to_class_room_graph(acc_graph, constraint)
    end)
  end

  @doc """
  Add conflicts to class-time-room conflict graph based on distribution constraints.
  """
  @spec add_class_time_room_conflicts(ConflictGraph.t(), [distribution_constraint()]) ::
          ConflictGraph.t()
  def add_class_time_room_conflicts(graph, constraints) do
    Enum.reduce(constraints, graph, fn constraint, acc_graph ->
      add_constraint_to_class_time_room_graph(acc_graph, constraint)
    end)
  end

  # Private functions for adding constraints to specific graph types

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :SameStart, classes: classes} = constraint
       ) do
    # Classes must start at the same time
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :SameTime, classes: classes} = constraint
       ) do
    # Classes must be taught at the same time
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :SameDays, classes: classes} = constraint
       ) do
    # Classes must be taught on the same days
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :SameWeeks, classes: classes} = constraint
       ) do
    # Classes must be taught in the same weeks
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :DifferentTime, classes: classes} = constraint
       ) do
    # Classes must not be taught at the same time
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :DifferentDays, classes: classes} = constraint
       ) do
    # Classes must not be taught on the same days
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :DifferentWeeks, classes: classes} = constraint
       ) do
    # Classes must not be taught in the same weeks
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :NotOverlap, classes: classes} = constraint
       ) do
    # Classes must not overlap in time
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(graph, %{type: :Overlap, classes: classes} = constraint) do
    # Classes must overlap in time
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :SameAttendees, classes: classes} = constraint
       ) do
    # Classes must be scheduled so attendees can be present at all
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :Precedence, classes: classes} = constraint
       ) do
    # Classes must be taught in the specified order
    add_precedence_conflicts(graph, classes, constraint)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :Workday, classes: classes, parameters: params} = constraint
       ) do
    # Restriction on daily work hours
    max_slots = Map.get(params, :max_slots, 5)
    add_workday_conflicts(graph, classes, max_slots, constraint)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :MinGap, classes: classes, parameters: params} = constraint
       ) do
    # Minimum gap between classes
    min_gap = Map.get(params, :min_gap, 1)
    add_min_gap_conflicts(graph, classes, min_gap, constraint)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :MaxDays, classes: classes, parameters: params} = constraint
       ) do
    # Maximum number of different days
    max_days = Map.get(params, :max_days, 5)
    add_max_days_conflicts(graph, classes, max_days, constraint)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :MaxDayLoad, classes: classes, parameters: params} = constraint
       ) do
    # Maximum load per day
    max_load = Map.get(params, :max_load, 8)
    add_max_day_load_conflicts(graph, classes, max_load, constraint)
  end

  defp add_constraint_to_class_time_graph(
         graph,
         %{type: :MaxBlock, classes: classes, parameters: params} = constraint
       ) do
    # Maximum block length
    max_block = Map.get(params, :max_block, 4)
    min_gap = Map.get(params, :min_gap, 1)
    add_max_block_conflicts(graph, classes, max_block, min_gap, constraint)
  end

  # Default case for unhandled constraint types
  defp add_constraint_to_class_time_graph(graph, _constraint) do
    # For now, ignore constraint types that don't affect class-time graph
    graph
  end

  # Class-room graph constraint handlers

  defp add_constraint_to_class_room_graph(
         graph,
         %{type: :SameRoom, classes: classes} = constraint
       ) do
    # Classes must use the same room
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_room_graph(
         graph,
         %{type: :DifferentRoom, classes: classes} = constraint
       ) do
    # Classes must not use the same room
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  defp add_constraint_to_class_room_graph(graph, %{type: :Overlap, classes: classes} = constraint) do
    # Classes must overlap (implies cannot use same room)
    add_pairwise_conflicts(graph, classes, :hard, constraint.penalty)
  end

  # Default case for class-room graph
  defp add_constraint_to_class_room_graph(graph, _constraint) do
    graph
  end

  # Class-time-room graph constraint handlers

  defp add_constraint_to_class_time_room_graph(
         graph,
         %{type: :SameAttendees, classes: classes} = constraint
       ) do
    # Time-room overlap part of SameAttendees constraint
    add_same_attendees_time_room_conflicts(graph, classes, constraint)
  end

  # Default case for class-time-room graph
  defp add_constraint_to_class_time_room_graph(graph, _constraint) do
    graph
  end

  # Helper functions for adding specific types of conflicts

  defp add_pairwise_conflicts(graph, classes, constraint_type, penalty) do
    # Add conflicts between all pairs of classes
    case constraint_type do
      :hard ->
        add_hard_pairwise_conflicts(graph, classes)

      :soft ->
        add_soft_pairwise_conflicts(graph, classes, penalty)
    end
  end

  defp add_hard_pairwise_conflicts(graph, classes) do
    # Add hard conflicts (edges with no weight or weight 1)
    class_pairs = combinations(classes, 2)

    Enum.reduce(class_pairs, graph, fn [class1, class2], acc_graph ->
      # Add edges between all time combinations of the two classes
      add_class_pair_time_conflicts(acc_graph, class1, class2)
    end)
  end

  defp add_soft_pairwise_conflicts(graph, classes, penalty) do
    # Add soft conflicts (edges with penalty weight)
    class_pairs = combinations(classes, 2)

    Enum.reduce(class_pairs, graph, fn [class1, class2], acc_graph ->
      add_class_pair_time_conflicts(acc_graph, class1, class2, penalty)
    end)
  end

  defp add_class_pair_time_conflicts(graph, class1, class2, weight \\ 1.0) do
    # Get all time vertices for both classes
    class1_times = ConflictGraph.vertices_for_class(graph, class1)
    class2_times = ConflictGraph.vertices_for_class(graph, class2)

    # Add conflicts between all pairs of times
    Enum.reduce(class1_times, graph, fn time1, acc_graph ->
      Enum.reduce(class2_times, acc_graph, fn time2, acc_acc_graph ->
        ConflictGraph.add_edge(acc_acc_graph, time1, time2, weight)
      end)
    end)
  end

  defp add_precedence_conflicts(graph, classes, constraint) do
    # Add conflicts to enforce precedence order
    # This is a simplified implementation
    class_pairs = combinations(classes, 2)

    Enum.reduce(class_pairs, graph, fn [class1, class2], acc_graph ->
      add_class_pair_time_conflicts(acc_graph, class1, class2)
    end)
  end

  defp add_workday_conflicts(graph, classes, max_slots, constraint) do
    # Add conflicts for workday constraints
    # This would implement the logic for workday(S) constraints
    graph
  end

  defp add_min_gap_conflicts(graph, classes, min_gap, constraint) do
    # Add conflicts for minimum gap constraints
    # This would implement the logic for MinGap(G) constraints
    graph
  end

  defp add_max_days_conflicts(graph, classes, max_days, constraint) do
    # Add conflicts for maximum days constraints
    # This would implement the logic for MaxDays(D) constraints
    graph
  end

  defp add_max_day_load_conflicts(graph, classes, max_load, constraint) do
    # Add conflicts for maximum day load constraints
    # This would implement the logic for MaxDayLoad(S) constraints
    graph
  end

  defp add_max_block_conflicts(graph, classes, max_block, min_gap, constraint) do
    # Add conflicts for maximum block constraints
    # This would implement the logic for MaxBlock(M,S) constraints
    graph
  end

  defp add_same_attendees_time_room_conflicts(graph, classes, constraint) do
    # Add time-room overlap conflicts for SameAttendees
    # This would implement the time-room overlap logic
    graph
  end

  # Helper function to generate combinations
  defp combinations(_, 0), do: [[]]
  defp combinations(list, n) when length(list) < n, do: []

  defp combinations([head | tail], n) do
    for(combo <- combinations(tail, n - 1), do: [head | combo]) ++ combinations(tail, n)
  end

  @doc """
  Create a distribution constraint of the specified type.
  """
  @spec new_constraint(constraint_type(), [String.t()], map(), number() | nil, boolean()) ::
          distribution_constraint()
  def new_constraint(type, classes, parameters \\ %{}, penalty \\ nil, is_hard \\ true) do
    %{
      type: type,
      classes: classes,
      parameters: parameters,
      penalty: penalty,
      is_hard: is_hard
    }
  end

  @doc """
  Create a SameStart constraint.
  """
  @spec same_start([String.t()], number() | nil) :: distribution_constraint()
  def same_start(classes, penalty \\ nil) do
    new_constraint(:SameStart, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a SameTime constraint.
  """
  @spec same_time([String.t()], number() | nil) :: distribution_constraint()
  def same_time(classes, penalty \\ nil) do
    new_constraint(:SameTime, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a SameRoom constraint.
  """
  @spec same_room([String.t()], number() | nil) :: distribution_constraint()
  def same_room(classes, penalty \\ nil) do
    new_constraint(:SameRoom, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a DifferentTime constraint.
  """
  @spec different_time([String.t()], number() | nil) :: distribution_constraint()
  def different_time(classes, penalty \\ nil) do
    new_constraint(:DifferentTime, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a NotOverlap constraint.
  """
  @spec not_overlap([String.t()], number() | nil) :: distribution_constraint()
  def not_overlap(classes, penalty \\ nil) do
    new_constraint(:NotOverlap, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a SameAttendees constraint.
  """
  @spec same_attendees([String.t()], number() | nil) :: distribution_constraint()
  def same_attendees(classes, penalty \\ nil) do
    new_constraint(:SameAttendees, classes, %{}, penalty, is_nil(penalty))
  end

  @doc """
  Create a MaxDays constraint.
  """
  @spec max_days([String.t()], pos_integer(), number() | nil) :: distribution_constraint()
  def max_days(classes, max_days, penalty \\ nil) do
    new_constraint(:MaxDays, classes, %{max_days: max_days}, penalty, is_nil(penalty))
  end

  @doc """
  Create a Workday constraint.
  """
  @spec workday([String.t()], pos_integer(), number() | nil) :: distribution_constraint()
  def workday(classes, max_slots, penalty \\ nil) do
    new_constraint(:Workday, classes, %{max_slots: max_slots}, penalty, is_nil(penalty))
  end
end
