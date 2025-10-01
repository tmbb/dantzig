defmodule PerformanceBenchmarkTest do
  use ExUnit.Case

  alias Dantzig.Problem

  @moduletag :performance

  describe "Performance Benchmarks" do
    test "knapsack problem scaling" do
      # Test with increasing number of items
      for num_items <- [5, 10, 15] do
        {time, _result} = :timer.tc(fn ->
          create_and_solve_knapsack(num_items)
        end)

        IO.puts("Knapsack with #{num_items} items: #{time / 1_000}ms")
        assert time < 30_000_000  # Should complete within 30 seconds
      end
    end

    test "assignment problem scaling" do
      # Test with increasing matrix sizes
      for size <- [3, 4, 5] do
        {time, _result} = :timer.tc(fn ->
          create_and_solve_assignment(size)
        end)

        IO.puts("Assignment #{size}x#{size}: #{time / 1_000}ms")
        assert time < 10_000_000  # Should complete within 10 seconds
      end
    end

    test "production planning scaling" do
      # Test with increasing time periods
      for periods <- [4, 6, 8] do
        {time, _result} = :timer.tc(fn ->
          create_and_solve_production_planning(periods)
        end)

        IO.puts("Production planning #{periods} periods: #{time / 1_000}ms")
        assert time < 15_000_000  # Should complete within 15 seconds
      end
    end

    test "memory usage tracking" do
      # Monitor memory usage during problem solving
      initial_memory = :erlang.memory(:total)

      problem = create_large_knapsack_problem(20)
      {:ok, solution} = Dantzig.solve(problem)

      final_memory = :erlang.memory(:total)
      memory_used = final_memory - initial_memory

      IO.puts("Memory usage for 20-item knapsack: #{memory_used} bytes")
      assert memory_used < 100_000_000  # Should use less than 100MB
      assert solution != nil
    end
  end

  # Helper functions for creating test problems
  defp create_and_solve_knapsack(num_items) do
    items = for i <- 1..num_items, do: "item#{i}"
    values = for i <- 1..num_items, into: %{}, do: {"item#{i}", i * 10}
    weights = for i <- 1..num_items, into: %{}, do: {"item#{i}", i * 2}
    capacity = num_items * 2

    problem =
      Problem.define do
        new(direction: :maximize)
        variables("select", [item <- items], :binary)
        constraints([item <- items], select(item) <= 1)
        objective(sum(for item <- items, do: select(item) * values[item]))
      end

    Dantzig.solve(problem)
  end

  defp create_and_solve_assignment(size) do
    workers = for i <- 1..size, do: "Worker#{i}"
    tasks = for i <- 1..size, do: "Task#{i}"
    costs = for w <- workers, into: %{}, do: {
      w,
      for t <- tasks, into: %{}, do: {"Task#{String.to_integer(String.last(t))}", w <> t}
    }

    problem =
      Problem.define do
        new(direction: :minimize)
        variables("assign", [w <- workers, t <- tasks], :binary)
        constraints([w <- workers], sum(assign(w, :_)) == 1)
        constraints([t <- tasks], sum(assign(:_, t)) == 1)
        objective(sum(for w <- workers, t <- tasks, do: assign(w, t) * 1))
      end

    Dantzig.solve(problem)
  end

  defp create_and_solve_production_planning(periods) do
    time_periods = 1..periods
    demand = for t <- time_periods, into: %{}, do: {t, 100 + t * 10}
    production_cost = for t <- time_periods, into: %{}, do: {t, 10 + t}

    problem =
      Problem.define do
        new(direction: :minimize)
        variables("produce", [t <- time_periods], :continuous, min: 0)
        variables("inventory", [t <- time_periods], :continuous, min: 0)

        constraints([t <- [1]], produce(t) - demand[1] == 0)
        constraints([t <- 2..periods], inventory(t-1) + produce(t) - demand[t] == 0)

        objective(sum(for t <- time_periods, do: produce(t) * production_cost[t]))
      end

    Dantzig.solve(problem)
  end

  defp create_large_knapsack_problem(num_items) do
    items = for i <- 1..num_items, do: "item#{i}"
    values = for i <- 1..num_items, into: %{}, do: {"item#{i}", i * 10}
    weights = for i <- 1..num_items, into: %{}, do: {"item#{i}", i * 2}
    capacity = num_items * 2

    Problem.define do
      new(direction: :maximize)
      variables("select", [item <- items], :binary)
      constraints([item <- items], select(item) <= 1)
      objective(sum(for item <- items, do: select(item) * values[item]))
    end
  end
end
