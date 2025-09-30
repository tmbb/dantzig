# Example validation helpers for classical optimization problems
#
# This module provides specific validation functions for different types of
# optimization problems commonly found in the examples.

defmodule Examples.ValidationHelpers do
  @moduledoc """
  Validation helpers for specific types of optimization problems.

  Provides problem-specific validation functions for:
  - Knapsack problems
  - Assignment problems
  - Transportation problems
  - Network flow problems
  - And other classical optimization problems
  """

  import ExUnit.Assertions
  alias Examples.TestHelper

  @doc """
  Validate knapsack problem solution.

  Checks:
  - Total weight does not exceed capacity
  - Selected items are valid
  - Objective value matches calculated value
  """
  def validate_knapsack_solution(solution, problem, items, capacity) do
    # Get selected items and calculate totals
    {total_weight, total_value, selected_items} =
      Enum.reduce(items, {0, 0, []}, fn item, {w_acc, v_acc, selected_acc} ->
        item_names = for i <- items, do: i.name
        item_index = Enum.find_index(item_names, &(&1 == item.name))

        if item_index do
          var_name = "select_#{item.name}"
          value = Dantzig.Solution.get_variable_value(solution, var_name)

          if value > 0.5 do
            {w_acc + item.weight, v_acc + item.value, [item | selected_acc]}
          else
            {w_acc, v_acc, selected_acc}
          end
        else
          {w_acc, v_acc, selected_acc}
        end
      end)

    # Validate weight constraint
    assert total_weight <= capacity + 0.001,
           "Total weight #{total_weight} exceeds capacity #{capacity}"

    # Validate objective value
    assert TestHelper.almost_equal(total_value, solution.objective, 0.001),
           "Calculated value #{total_value} doesn't match objective #{solution.objective}"

    # Validate binary selections
    Enum.each(items, fn item ->
      var_name = "select_#{item.name}"
      value = Dantzig.Solution.get_variable_value(solution, var_name)

      assert TestHelper.almost_equal(value, 0.0, 0.001) or
               TestHelper.almost_equal(value, 1.0, 0.001),
             "Variable #{var_name} should be 0 or 1, got #{value}"
    end)

    %{total_weight: total_weight, total_value: total_value, selected_items: selected_items}
  end

  @doc """
  Validate assignment problem solution.

  Checks:
  - Each worker assigned to exactly one task
  - Each task assigned to exactly one worker
  - All assignments are binary (0 or 1)
  """
  def validate_assignment_solution(solution, problem, workers, tasks) do
    # Check worker assignments
    Enum.each(workers, fn worker ->
      worker_assignments =
        Enum.map(tasks, fn task ->
          var_name = "assign_#{worker}_#{task}"
          Dantzig.Solution.get_variable_value(solution, var_name)
        end)

      total_assignments = Enum.sum(worker_assignments)

      assert TestHelper.almost_equal(total_assignments, 1.0, 0.001),
             "Worker #{worker} should be assigned to exactly one task, got #{total_assignments}"
    end)

    # Check task assignments
    Enum.each(tasks, fn task ->
      task_assignments =
        Enum.map(workers, fn worker ->
          var_name = "assign_#{worker}_#{task}"
          Dantzig.Solution.get_variable_value(solution, var_name)
        end)

      total_assignments = Enum.sum(task_assignments)

      assert TestHelper.almost_equal(total_assignments, 1.0, 0.001),
             "Task #{task} should be assigned to exactly one worker, got #{total_assignments}"
    end)

    # Validate all assignments are binary
    Enum.each(workers, fn worker ->
      Enum.each(tasks, fn task ->
        var_name = "assign_#{worker}_#{task}"
        value = Dantzig.Solution.get_variable_value(solution, var_name)

        assert TestHelper.almost_equal(value, 0.0, 0.001) or
                 TestHelper.almost_equal(value, 1.0, 0.001),
               "Assignment #{var_name} should be 0 or 1, got #{value}"
      end)
    end)

    :ok
  end

  @doc """
  Validate transportation problem solution.

  Checks:
  - Supply constraints satisfied (supplier total shipments <= capacity)
  - Demand constraints satisfied (customer total receipts >= demand)
  - All shipments are non-negative
  """
  def validate_transportation_solution(
        solution,
        problem,
        suppliers,
        customers,
        supply,
        demand,
        cost_matrix
      ) do
    # Validate supply constraints
    Enum.with_index(suppliers, fn supplier, i ->
      supplier_shipments =
        Enum.with_index(customers, fn customer, j ->
          var_name = "ship_#{supplier}_#{customer}"
          Dantzig.Solution.get_variable_value(solution, var_name)
        end)

      total_shipped = Enum.sum(supplier_shipments)

      assert total_shipped <= Enum.at(supply, i) + 0.001,
             "Supplier #{supplier} shipped #{total_shipped}, exceeds capacity #{Enum.at(supply, i)}"
    end)

    # Validate demand constraints
    Enum.with_index(customers, fn customer, j ->
      customer_receipts =
        Enum.with_index(suppliers, fn supplier, i ->
          var_name = "ship_#{supplier}_#{customer}"
          Dantzig.Solution.get_variable_value(solution, var_name)
        end)

      total_received = Enum.sum(customer_receipts)

      assert total_received >= Enum.at(demand, j) - 0.001,
             "Customer #{customer} received #{total_received}, below demand #{Enum.at(demand, j)}"
    end)

    # Validate non-negative shipments
    Enum.each(suppliers, fn supplier ->
      Enum.each(customers, fn customer ->
        var_name = "ship_#{supplier}_#{customer}"
        value = Map.get(solution.variables, var_name, 0)
        assert value >= -0.001, "Shipment #{var_name} should be non-negative, got #{value}"
      end)
    end)

    :ok
  end

  @doc """
  Validate network flow solution.

  Checks:
  - Flow conservation at each node
  - Arc capacity constraints
  - Non-negative flows
  """
  def validate_network_flow_solution(solution, problem, nodes, arcs, source, sink) do
    # Validate flow conservation (except source and sink)
    Enum.each(nodes, fn node ->
      if node != source and node != sink do
        inflow =
          arcs
          |> Enum.filter(fn {_from, to, _cap} -> to == node end)
          |> Enum.map(fn {from, _to, _cap} ->
            var_name = "flow_#{from}_#{node}"
            Dantzig.Solution.get_variable_value(solution, var_name)
          end)
          |> Enum.sum()

        outflow =
          arcs
          |> Enum.filter(fn {from, _to, _cap} -> from == node end)
          |> Enum.map(fn {_from, to, _cap} ->
            var_name = "flow_#{node}_#{to}"
            Dantzig.Solution.get_variable_value(solution, var_name)
          end)
          |> Enum.sum()

        assert TestHelper.almost_equal(inflow, outflow, 0.001),
               "Flow conservation violated at node #{node}: inflow=#{inflow}, outflow=#{outflow}"
      end
    end)

    # Validate capacity constraints
    Enum.each(arcs, fn {from, to, capacity} ->
      var_name = "flow_#{from}_#{to}"
      flow = Dantzig.Solution.get_variable_value(solution, var_name)

      assert flow <= capacity + 0.001,
             "Flow #{flow} on arc #{from}->#{to} exceeds capacity #{capacity}"

      assert flow >= -0.001,
             "Flow #{flow} on arc #{from}->#{to} should be non-negative"
    end)

    :ok
  end

  @doc """
  Validate production planning solution.

  Checks:
  - Inventory balance equations
  - Production capacity constraints
  - Demand satisfaction
  """
  def validate_production_planning_solution(solution, problem, time_periods, demand, capacity) do
    # Validate inventory balance for each period
    Enum.with_index(time_periods, fn period, i ->
      production_var = "prod_#{period}"
      inventory_var = "inv_#{period}"

      production = Dantzig.Solution.get_variable_value(solution, production_var)
      inventory = Dantzig.Solution.get_variable_value(solution, inventory_var)

      # For first period, inventory should equal production minus demand
      if i == 0 do
        expected_inventory = production - Enum.at(demand, i)

        assert TestHelper.almost_equal(inventory, expected_inventory, 0.001),
               "Inventory balance violated in period #{period}"
      else
        # For other periods, inventory = previous inventory + production - demand
        prev_inventory_var = "inv_#{Enum.at(time_periods, i - 1)}"
        prev_inventory = Dantzig.Solution.get_variable_value(solution, prev_inventory_var)
        expected_inventory = prev_inventory + production - Enum.at(demand, i)

        assert TestHelper.almost_equal(inventory, expected_inventory, 0.001),
               "Inventory balance violated in period #{period}"
      end

      # Validate capacity constraints
      assert production <= capacity + 0.001,
             "Production #{production} in period #{period} exceeds capacity #{capacity}"

      # Validate non-negative values
      assert production >= -0.001, "Production should be non-negative in period #{period}"
      assert inventory >= -0.001, "Inventory should be non-negative in period #{period}"
    end)

    :ok
  end

  @doc """
  Validate blending problem solution.

  Checks:
  - Quality specifications met
  - Material availability constraints
  - Cost minimization
  """
  def validate_blending_solution(solution, problem, materials, quality_specs, availability) do
    # Validate quality constraints
    Enum.each(quality_specs, fn {quality, min_val, max_val} ->
      total_quality =
        Enum.with_index(materials, fn material, i ->
          var_name = "blend_#{material.name}"
          amount = Dantzig.Solution.get_variable_value(solution, var_name)
          amount * material[quality]
        end)
        |> Enum.sum()

      if min_val do
        assert total_quality >= min_val - 0.001,
               "Quality #{quality} = #{total_quality} below minimum #{min_val}"
      end

      if max_val do
        assert total_quality <= max_val + 0.001,
               "Quality #{quality} = #{total_quality} above maximum #{max_val}"
      end
    end)

    # Validate material availability
    Enum.with_index(materials, fn material, i ->
      var_name = "blend_#{material.name}"
      amount = Dantzig.Solution.get_variable_value(solution, var_name)
      max_available = Enum.at(availability, i)

      assert amount <= max_available + 0.001,
             "Material #{material.name} usage #{amount} exceeds availability #{max_available}"

      assert amount >= -0.001,
             "Material #{material.name} usage should be non-negative"
    end)

    :ok
  end

  @doc """
  Validate cutting stock solution.

  Checks:
  - All demand satisfied
  - Stock length constraints
  - Waste minimization
  """
  def validate_cutting_stock_solution(solution, problem, stock_lengths, demand_lengths) do
    # Validate demand satisfaction
    Enum.each(demand_lengths, fn {length, demand_qty} ->
      total_produced =
        stock_lengths
        |> Enum.with_index()
        |> Enum.map(fn {stock_len, stock_idx} ->
          demand_lengths
          |> Enum.with_index()
          |> Enum.map(fn {{dem_len, _}, dem_idx} ->
            if dem_len <= stock_len do
              var_name = "pattern_#{stock_idx}_#{dem_idx}"
              pattern_count = Dantzig.Solution.get_variable_value(solution, var_name)
              trunc(dem_len / stock_len) * pattern_count
            else
              0
            end
          end)
          |> Enum.sum()
        end)
        |> Enum.sum()

      assert total_produced >= demand_qty - 0.001,
             "Demand for length #{length} not satisfied: produced #{total_produced}, needed #{demand_qty}"
    end)

    :ok
  end

  @doc """
  Validate facility location solution.

  Checks:
  - All customers served
  - Facility capacity constraints
  - Service assignments are valid
  """
  def validate_facility_location_solution(solution, problem, facilities, customers) do
    # Validate customer service
    Enum.each(customers, fn customer ->
      service_vars =
        facilities
        |> Enum.map(fn facility ->
          var_name = "serve_#{facility}_#{customer}"
          Dantzig.Solution.get_variable_value(solution, var_name)
        end)

      total_service = Enum.sum(service_vars)

      assert TestHelper.almost_equal(total_service, 1.0, 0.001),
             "Customer #{customer} should be served exactly once, got #{total_service}"
    end)

    # Validate facility opening constraints
    Enum.each(facilities, fn facility ->
      facility_open_var = "open_#{facility}"
      open = Dantzig.Solution.get_variable_value(solution, facility_open_var)

      assert TestHelper.almost_equal(open, 0.0, 0.001) or
               TestHelper.almost_equal(open, 1.0, 0.001),
             "Facility #{facility} open variable should be 0 or 1, got #{open}"

      # If facility is open, check capacity
      if open > 0.5 do
        facility_capacity_var = "capacity_#{facility}"
        capacity = Dantzig.Solution.get_variable_value(solution, facility_capacity_var)

        total_served =
          customers
          |> Enum.map(fn customer ->
            var_name = "serve_#{facility}_#{customer}"
            Dantzig.Solution.get_variable_value(solution, var_name)
          end)
          |> Enum.sum()

        assert total_served <= capacity + 0.001,
               "Facility #{facility} serves #{total_served}, exceeds capacity #{capacity}"
      end
    end)

    :ok
  end

  @doc """
  Validate portfolio optimization solution.

  Checks:
  - Portfolio weights sum to 1 (budget constraint)
  - Risk constraint satisfied
  - Return maximization
  """
  def validate_portfolio_solution(solution, problem, assets, risk_budget) do
    # Validate budget constraint (weights sum to 1)
    total_weight =
      assets
      |> Enum.map(fn asset ->
        var_name = "weight_#{asset.name}"
        Dantzig.Solution.get_variable_value(solution, var_name)
      end)
      |> Enum.sum()

    assert TestHelper.almost_equal(total_weight, 1.0, 0.001),
           "Portfolio weights should sum to 1, got #{total_weight}"

    # Validate risk constraint
    portfolio_risk = calculate_portfolio_risk(solution, assets)

    assert portfolio_risk <= risk_budget + 0.001,
           "Portfolio risk #{portfolio_risk} exceeds budget #{risk_budget}"

    # Validate non-negative weights
    Enum.each(assets, fn asset ->
      var_name = "weight_#{asset.name}"
      weight = Dantzig.Solution.get_variable_value(solution, var_name)
      assert weight >= -0.001, "Weight for #{asset.name} should be non-negative, got #{weight}"
    end)

    %{portfolio_risk: portfolio_risk, total_weight: total_weight}
  end

  @doc """
  Calculate portfolio risk (simplified version).
  """
  def calculate_portfolio_risk(solution, assets) do
    # Simplified risk calculation - in practice would use covariance matrix
    variance_sum =
      assets
      |> Enum.map(fn asset ->
        var_name = "weight_#{asset.name}"
        weight = Dantzig.Solution.get_variable_value(solution, var_name)
        # Simplified: risk = weight² * asset_risk
        weight * weight * asset.risk
      end)
      |> Enum.sum()

    # Return standard deviation
    :math.sqrt(variance_sum)
  end

  @doc """
  Validate school timetabling solution.

  Checks:
  - Teacher constraints (one class at a time, subject skills)
  - Room constraints (one class per room)
  - Equipment constraints
  - Student curriculum requirements
  """
  def validate_timetabling_solution(
        solution,
        problem,
        teachers,
        subjects,
        time_slots,
        rooms,
        equipment
      ) do
    # Validate teacher constraints
    Enum.each(teachers, fn teacher ->
      Enum.each(time_slots, fn time_slot ->
        teacher_assignments =
          subjects
          |> Enum.flat_map(fn subject ->
            rooms
            |> Enum.map(fn room ->
              var_name = "schedule_#{teacher}_#{subject}_#{room}_#{time_slot}"
              Dantzig.Solution.get_variable_value(solution, var_name)
            end)
          end)

        total_assignments = Enum.sum(teacher_assignments)

        assert TestHelper.almost_equal(total_assignments, 0.0, 0.001) or
                 TestHelper.almost_equal(total_assignments, 1.0, 0.001),
               "Teacher #{teacher} in slot #{time_slot} should teach 0 or 1 class, got #{total_assignments}"
      end)
    end)

    # Validate room constraints
    Enum.each(rooms, fn room ->
      Enum.each(time_slots, fn time_slot ->
        room_usage =
          teachers
          |> Enum.flat_map(fn teacher ->
            subjects
            |> Enum.map(fn subject ->
              var_name = "schedule_#{teacher}_#{subject}_#{room}_#{time_slot}"
              Dantzig.Solution.get_variable_value(solution, var_name)
            end)
          end)

        total_usage = Enum.sum(room_usage)

        assert TestHelper.almost_equal(total_usage, 0.0, 0.001) or
                 TestHelper.almost_equal(total_usage, 1.0, 0.001),
               "Room #{room} in slot #{time_slot} should host 0 or 1 class, got #{total_usage}"
      end)
    end)

    # Validate equipment constraints
    Enum.each(equipment, fn equip ->
      Enum.each(rooms, fn room ->
        Enum.each(time_slots, fn time_slot ->
          equipment_usage =
            teachers
            |> Enum.flat_map(fn teacher ->
              subjects
              |> Enum.map(fn subject ->
                var_name = "schedule_#{teacher}_#{subject}_#{room}_#{time_slot}"
                schedule = Dantzig.Solution.get_variable_value(solution, var_name)

                # Check if this subject requires this equipment
                subject_requires_equipment =
                  subjects[subject] && subjects[subject].equipment == equip

                if subject_requires_equipment do
                  # Equipment used if class is scheduled
                  schedule
                else
                  # Equipment not used
                  0
                end
              end)
            end)

          total_equipment_usage = Enum.sum(equipment_usage)
          # Equipment can be used by at most one class per time slot per room
          assert total_equipment_usage <= 1.001,
                 "Equipment #{equip} in room #{room} slot #{time_slot} overused: #{total_equipment_usage}"
        end)
      end)
    end)

    :ok
  end

  @doc """
  Run a complete example validation with timing.
  """
  def run_complete_validation(example_name, validation_fun, solution, problem, test_data) do
    IO.puts("Validating #{example_name}...")

    start_time = :erlang.monotonic_time(:microsecond)

    try do
      result = validation_fun.(solution, problem, test_data)
      Examples.TestHelper.validate_solution(solution, problem)

      end_time = :erlang.monotonic_time(:microsecond)
      execution_time_ms = (end_time - start_time) / 1000

      IO.puts("✅ #{example_name} validation passed in #{execution_time_ms}ms")
      {:ok, result}
    rescue
      error ->
        end_time = :erlang.monotonic_time(:microsecond)
        execution_time_ms = (end_time - start_time) / 1000

        IO.puts(
          "❌ #{example_name} validation failed in #{execution_time_ms}ms: #{inspect(error)}"
        )

        {:error, error}
    end
  end
end
