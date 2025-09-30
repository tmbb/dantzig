# Immediate Task List - Dantzig DSL Enhancement

## Current Status

✅ Unary minus functionality implemented and working
✅ Negative coefficient multiplication fixed
✅ All arithmetic operations tests passing
✅ Core DSL functionality stable

## Phase 1: Classical Examples (Week 1-2)

### Priority 1: Simple Problems (Start Here)

1. **N-Queens Problem** - `examples/nqueens_dsl.exs` ✅ (Already exists)
   - Place N queens on N×N board without conflicts
   - Test with 4×4 and 8×8 boards
   - Verify no two queens attack each other

2. **Diet Problem** - `examples/diet_problem.exs` ✅ (Already exists)
   - Minimize cost while meeting nutritional requirements
   - Test with 3 foods, 2 nutrients
   - Verify nutritional constraints satisfied

3. **Knapsack Problem** - `examples/knapsack_problem.exs`
   - Maximize value within weight constraint
   - Test with 5 items, capacity 20
   - Verify total weight ≤ capacity

4. **Assignment Problem** - `examples/assignment_problem.exs`
   - Assign workers to tasks optimally
   - Test with 3×3 assignment matrix
   - Verify each worker/task assigned exactly once

### Priority 2: Medium Complexity Problems

5. **Transportation Problem** - `examples/transportation_problem.exs`
   - Minimize shipping costs from suppliers to customers
   - Test with 3 suppliers, 4 customers
   - Validate solution makes economic sense

6. **Production Planning** - `examples/production_planning.exs`
   - Optimize production over 4 time periods
   - Include inventory holding costs
   - Verify demand satisfaction

7. **Network Flow** - `examples/network_flow.exs`
   - Maximize flow through 5-node network
   - Include capacity constraints
   - Verify flow conservation

8. **Blending Problem** - `examples/blending_problem.exs`
   - Blend raw materials to meet specifications
   - Test with 3 materials, 2 quality constraints
   - Verify quality specifications met

### Priority 3: Complex Problems

9. **Cutting Stock Problem** - `examples/cutting_stock.exs`
   - Minimize waste when cutting standard lengths
   - Test with 3 stock lengths, 4 demand lengths
   - Verify demand satisfaction

10. **Facility Location** - `examples/facility_location.exs`
    - Choose optimal locations for facilities
    - Test with 3 potential facilities, 5 customers
    - Verify service constraints

### Priority 4: Advanced Problems

11. **Portfolio Optimization** - `examples/portfolio_optimization.exs`
    - Maximize return while controlling risk
    - Test with 4 assets, risk constraint
    - Verify risk limits respected

12. **School Timetabling** - `examples/school_timetabling.exs` ⭐ (Showcase Example)
    - Schedule teachers, students, rooms, and equipment
    - **Complexity**: Teachers with skills/availability, students with curriculum, rooms with equipment
    - **Scale**: 5 teachers, 3 subjects, 4 time slots, 3 rooms, 2 equipment types
    - **Constraints**: Teacher availability, room capacity, equipment requirements, curriculum needs
    - **Objective**: Minimize conflicts and maximize resource utilization
    - **Note**: This will be the showcase example for README.md

### Testing Strategy for Examples

- [ ] Create `test/examples/` directory
- [ ] Test each example compiles and runs
- [ ] Validate solutions are feasible
- [ ] Check constraint satisfaction
- [ ] Verify objective optimization

## Phase 2: Code Cleanup (Week 3-4)

### File Size Management

- [ ] **Identify large files** (> 500 lines):
  - `lib/dantzig/problem/dsl/internal.ex` (678 lines) - Split into logical modules
  - Check other files for size violations

- [ ] **Split `internal.ex`** into:
  - `lib/dantzig/problem/dsl/parser.ex` - AST parsing functions
  - `lib/dantzig/problem/dsl/evaluator.ex` - Expression evaluation
  - `lib/dantzig/problem/dsl/bindings.ex` - Binding management
  - `lib/dantzig/problem/dsl/arithmetic.ex` - Arithmetic operations

### Remove Unused Code

- [ ] **Scan for unused functions**:
  - Check `lib/dantzig/problem/dsl.ex` for unused private functions
  - Remove experimental code
  - Clean up commented code

- [ ] **Remove obsolete test files**:
  - Clean up `test/dantzig/dsl/experimental/` directory
  - Remove duplicate tests
  - Consolidate related tests

### Code Organization

- [ ] **Reorganize module structure**:
  - Group related functionality
  - Improve module naming
  - Create clear interfaces

## Phase 3: Documentation (Week 5-6)

### Tutorial Documentation

- [ ] **Getting Started Guide** - `docs/getting_started.md`
- [ ] **Syntax Reference** - `docs/syntax_reference.md`
- [ ] **Tutorial Series** - `docs/tutorial/`

### Developer Documentation

- [ ] **Architecture Guide** - `docs/architecture.md`
- [ ] **Development Guide** - `docs/development.md`
- [ ] **Macro Development Guide** - `docs/macro_development.md`

## Phase 4: Testing Enhancement (Week 7-8)

### Test Coverage

- [ ] **Achieve > 90% test coverage**
- [ ] **Add property-based tests**
- [ ] **Performance benchmarks**

### Quality Assurance

- [ ] **Static analysis**
- [ ] **Code quality metrics**
- [ ] **Performance monitoring**

## Immediate Next Steps (Today)

### Step 1: Create First Classical Example

- [ ] **Knapsack Problem** (Start with simple problem)
  - Research the classical formulation
  - Create example file
  - Test with small dataset
  - Validate solution

### Step 2: Set Up Example Testing

- [ ] **Create test infrastructure**
  - `test/examples/` directory
  - Example validation helpers
  - Solution checking utilities

### Step 3: Begin Code Cleanup

- [ ] **Analyze current file sizes**
  - List all files > 500 lines
  - Plan splitting strategy
  - Identify unused code

## Success Metrics

### Functional

- [ ] 12 classical examples working (including existing N-Queens and Diet)
- [ ] All examples have tests
- [ ] Documentation complete
- [ ] No unused code
- [ ] School Timetabling example ready for README.md showcase

### Quality

- [ ] All files < 500 lines
- [ ] > 90% test coverage
- [ ] Clear module organization
- [ ] Performance maintained

## Risk Mitigation

### Technical Risks

- **Breaking changes**: Comprehensive test suite
- **Performance issues**: Benchmark before/after
- **Complexity**: Incremental changes

### Resource Risks

- **Time constraints**: Prioritize high-impact tasks
- **Scope creep**: Stick to defined phases

## School Timetabling Problem Details

### Problem Description

Schedule teachers, students, rooms, and equipment for a school week with the following constraints:

### Entities

- **Teachers**: 5 teachers with different skills and availability
- **Subjects**: 3 subjects (Math, Science, English)
- **Time Slots**: 4 time slots per day, 5 days = 20 total slots
- **Rooms**: 3 rooms with different capacities and equipment
- **Equipment**: 2 types (Projector, Lab Equipment) - some moveable, some fixed

### Variables

- `schedule[teacher, subject, room, time_slot]` = 1 if teacher teaches subject in room at time
- `equipment_used[equipment, room, time_slot]` = 1 if equipment is used in room at time

### Constraints

1. **Teacher Constraints**:
   - Each teacher can only teach one class at a time
   - Teachers have specific subject skills
   - Teachers have availability constraints

2. **Student Constraints**:
   - Each student group needs specific subjects
   - Room capacity must accommodate student groups

3. **Room Constraints**:
   - Each room can only host one class at a time
   - Equipment requirements must be met

4. **Equipment Constraints**:
   - Fixed equipment stays in assigned rooms
   - Moveable equipment can be moved but with cost
   - Equipment conflicts (can't be in two places at once)

### Objective

Minimize total scheduling conflicts and equipment movement costs.

---

*This task list will be updated as we progress through the phases.*
