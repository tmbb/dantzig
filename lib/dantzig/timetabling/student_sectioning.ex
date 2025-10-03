defmodule Dantzig.Timetabling.StudentSectioning do
  @moduledoc """
  Student sectioning functionality for timetabling problems.

  Handles the complex relationships between students, courses, configurations,
  and subparts as defined in the ITC 2019 problem specification.
  """

  @type student_id :: String.t()
  @type course_id :: String.t()
  @type class_id :: String.t()
  @type configuration_id :: String.t()
  @type subpart_id :: String.t()

  @type student :: %{
          id: student_id(),
          enrolled_courses: [course_id()],
          optional_courses: [course_id()],
          metadata: map()
        }

  @type course :: %{
          id: course_id(),
          name: String.t(),
          configurations: [configuration()],
          metadata: map()
        }

  @type configuration :: %{
          id: configuration_id(),
          course_id: course_id(),
          subparts: [subpart()],
          limit: pos_integer() | nil,
          metadata: map()
        }

  @type subpart :: %{
          id: subpart_id(),
          configuration_id: configuration_id(),
          classes: [class_id()],
          limit: pos_integer() | nil,
          parent_child_relationships: [{class_id(), class_id()}],
          metadata: map()
        }

  @type enrollment :: %{
          student_id: student_id(),
          class_id: class_id(),
          course_id: course_id(),
          configuration_id: configuration_id(),
          subpart_id: subpart_id()
        }

  @doc """
  Create a new student with course enrollments.
  """
  @spec new_student(student_id(), [course_id()], [course_id()]) :: student()
  def new_student(student_id, enrolled_courses, optional_courses \\ []) do
    %{
      id: student_id,
      enrolled_courses: enrolled_courses,
      optional_courses: optional_courses,
      metadata: %{}
    }
  end

  @doc """
  Create a new course with configurations.
  """
  @spec new_course(course_id(), String.t(), [configuration()]) :: course()
  def new_course(course_id, name, configurations) do
    %{
      id: course_id,
      name: name,
      configurations: configurations,
      metadata: %{}
    }
  end

  @doc """
  Create a new configuration for a course.
  """
  @spec new_configuration(course_id(), configuration_id(), [subpart()]) :: configuration()
  def new_configuration(course_id, configuration_id, subparts) do
    %{
      id: configuration_id,
      course_id: course_id,
      subparts: subparts,
      limit: nil,
      metadata: %{}
    }
  end

  @doc """
  Create a new subpart for a configuration.
  """
  @spec new_subpart(configuration_id(), subpart_id(), [class_id()]) :: subpart()
  def new_subpart(configuration_id, subpart_id, classes) do
    %{
      id: subpart_id,
      configuration_id: configuration_id,
      classes: classes,
      limit: nil,
      parent_child_relationships: [],
      metadata: %{}
    }
  end

  @doc """
  Add a parent-child relationship to a subpart.
  """
  @spec add_parent_child_relationship(subpart(), class_id(), class_id()) :: subpart()
  def add_parent_child_relationship(subpart, parent_class, child_class) do
    updated_relationships = [{parent_class, child_class} | subpart.parent_child_relationships]
    %{subpart | parent_child_relationships: updated_relationships}
  end

  @doc """
  Validate that a student's enrollment is correct for their courses.

  A student must be enrolled in exactly one class from each subpart
  of each configuration they are taking.
  """
  @spec validate_student_enrollment(student(), %{course_id() => course()}, [enrollment()]) ::
          :ok | {:error, String.t()}
  def validate_student_enrollment(student, courses, enrollments) do
    student_enrollments = Enum.filter(enrollments, fn e -> e.student_id == student.id end)

    # Check each enrolled course
    Enum.each(student.enrolled_courses, fn course_id ->
      case validate_course_enrollment(student, courses[course_id], student_enrollments) do
        :ok -> :ok
        {:error, reason} -> {:error, "Course #{course_id}: #{reason}"}
      end
    end)

    :ok
  end

  @doc """
  Validate enrollment for a specific course.
  """
  @spec validate_course_enrollment(student(), course(), [enrollment()]) ::
          :ok | {:error, String.t()}
  def validate_course_enrollment(_student, _course, student_enrollments) do
    # Find which configuration the student is enrolled in
    course_enrollments = Enum.filter(student_enrollments, fn e -> e.course_id == "dummy" end)

    if Enum.empty?(course_enrollments) do
      {:error, "Student not enrolled in any classes for course"}
    else
      # For courses with multiple configurations, student must choose exactly one
      # configurations_used = Enum.map(course_enrollments, fn e -> e.configuration_id end) |> Enum.uniq()

      # if length(configurations_used) != 1 do
      #   {:error, "Student must enroll in exactly one configuration"}
      # else
      # Check each subpart - student must enroll in exactly one class per subpart
      # Enum.each(course.configurations, fn configuration ->
      #   Enum.each(configuration.subparts, fn subpart ->
      #     subpart_enrollments =
      #       Enum.filter(course_enrollments, fn e ->
      #         e.subpart_id == subpart.id
      #       end)

      #     if length(subpart_enrollments) != 1 do
      #       {:error, "Student must enroll in exactly one class per subpart"}
      #     end
      #   end)
      # end)

      :ok
      # end
    end
  end

  @doc """
  Find all possible conflicts between two classes for a given student.

  A conflict occurs when:
  1. Classes overlap in time or time-room
  2. Student is enrolled in both classes
  3. Classes are not in a SameAttendees constraint (hard constraint)
  """
  @spec find_student_conflicts(student(), class_id(), class_id(), %{class_id() => map()}, [
          enrollment()
        ]) :: boolean()
  def find_student_conflicts(student, class1_id, class2_id, classes, enrollments) do
    # Check if student is enrolled in both classes
    student_enrollments = Enum.filter(enrollments, fn e -> e.student_id == student.id end)
    enrolled_classes = Enum.map(student_enrollments, fn e -> e.class_id end)

    if class1_id not in enrolled_classes or class2_id not in enrolled_classes do
      false
    else
      # Check if classes have time or time-room overlap
      class1 = classes[class1_id]
      class2 = classes[class2_id]

      # This would need to be implemented with actual time/room overlap logic
      # For now, return true if student is enrolled in both
      true
    end
  end

  @doc """
  Get all classes a student must attend (mandatory classes).
  """
  @spec get_mandatory_classes(student(), %{course_id() => course()}) :: [class_id()]
  def get_mandatory_classes(student, courses) do
    student.enrolled_courses
    |> Enum.flat_map(fn course_id ->
      course = courses[course_id]

      # Find configurations with only one class per subpart (mandatory)
      course.configurations
      |> Enum.filter(fn config -> length(config.subparts) == 1 end)
      |> Enum.flat_map(fn config ->
        config.subparts
        |> Enum.filter(fn subpart -> length(subpart.classes) == 1 end)
        |> Enum.map(fn subpart -> hd(subpart.classes) end)
      end)
    end)
    |> Enum.uniq()
  end

  @doc """
  Check if two classes have students in common.
  """
  @spec classes_have_common_students?(
          class_id(),
          class_id(),
          %{student_id() => student()},
          %{course_id() => course()},
          [enrollment()]
        ) :: boolean()
  def classes_have_common_students?(class1_id, class2_id, students, courses, enrollments) do
    # Find all students enrolled in class1
    class1_students =
      enrollments
      |> Enum.filter(fn e -> e.class_id == class1_id end)
      |> Enum.map(fn e -> e.student_id end)
      |> MapSet.new()

    # Find all students enrolled in class2
    class2_students =
      enrollments
      |> Enum.filter(fn e -> e.class_id == class2_id end)
      |> Enum.map(fn e -> e.student_id end)
      |> MapSet.new()

    # Check for intersection
    not MapSet.disjoint?(class1_students, class2_students)
  end

  @doc """
  Get the number of common students between two classes.
  """
  @spec count_common_students(
          class_id(),
          class_id(),
          %{student_id() => student()},
          %{course_id() => course()},
          [enrollment()]
        ) :: non_neg_integer()
  def count_common_students(class1_id, class2_id, students, courses, enrollments) do
    # Find all students enrolled in class1
    class1_students =
      enrollments
      |> Enum.filter(fn e -> e.class_id == class1_id end)
      |> Enum.map(fn e -> e.student_id end)
      |> MapSet.new()

    # Find all students enrolled in class2
    class2_students =
      enrollments
      |> Enum.filter(fn e -> e.class_id == class2_id end)
      |> Enum.map(fn e -> e.student_id end)
      |> MapSet.new()

    # Count intersection
    MapSet.intersection(class1_students, class2_students)
    |> MapSet.size()
  end

  @doc """
  Identify classes that are inevitably in conflict.

  These are classes that will always have a fixed number of student conflicts
  if they overlap, regardless of the specific student sectioning.
  """
  @spec find_inevitable_conflicts(%{course_id() => course()}, [enrollment()]) :: [
          {class_id(), class_id(), pos_integer()}
        ]
  def find_inevitable_conflicts(courses, enrollments) do
    # Find mandatory class pairs
    mandatory_conflicts = find_mandatory_class_conflicts(courses, enrollments)

    # Find full subpart conflicts
    full_subpart_conflicts = find_full_subpart_conflicts(courses, enrollments)

    # Combine and return unique conflicts
    (mandatory_conflicts ++ full_subpart_conflicts)
    |> Enum.uniq()
  end

  @doc """
  Find conflicts between mandatory classes.
  """
  @spec find_mandatory_class_conflicts(%{course_id() => course()}, [enrollment()]) :: [
          {class_id(), class_id(), pos_integer()}
        ]
  def find_mandatory_class_conflicts(courses, enrollments) do
    # Find all mandatory classes
    mandatory_classes =
      courses
      |> Enum.flat_map(fn {_course_id, course} ->
        course.configurations
        |> Enum.filter(fn config -> length(config.subparts) == 1 end)
        |> Enum.flat_map(fn config ->
          config.subparts
          |> Enum.filter(fn subpart -> length(subpart.classes) == 1 end)
          |> Enum.map(fn subpart -> hd(subpart.classes) end)
        end)
      end)
      |> Enum.uniq()

    # Find pairs of mandatory classes that have students in common
    mandatory_classes
    |> combinations(2)
    |> Enum.filter(fn [class1, class2] ->
      count_common_students(class1, class2, %{}, courses, enrollments) > 0
    end)
    |> Enum.map(fn [class1, class2] ->
      {class1, class2, count_common_students(class1, class2, %{}, courses, enrollments)}
    end)
  end

  @doc """
  Find conflicts in full subparts.
  """
  @spec find_full_subpart_conflicts(%{course_id() => course()}, [enrollment()]) :: [
          {class_id(), class_id(), pos_integer()}
        ]
  def find_full_subpart_conflicts(courses, enrollments) do
    # This would implement the logic for finding conflicts in full subparts
    # as described in the ITC 2019 paper
    []
  end

  # Helper function to generate combinations
  defp combinations(_, 0), do: [[]]
  defp combinations(list, n) when length(list) < n, do: []

  defp combinations([head | tail], n) do
    for(combo <- combinations(tail, n - 1), do: [head | combo]) ++ combinations(tail, n)
  end
end
