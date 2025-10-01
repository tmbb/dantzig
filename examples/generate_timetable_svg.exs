#!/usr/bin/env elixir

# SVG Generator for School Timetabling Results
# This script generates visual timetables showing the scheduling results

# Sample timetable data (in a real implementation, this would come from the solution)
timetable_data = %{
  "Slot1" => %{
    "Room1" => "Teacher4 - Math",
    "Room2" => "Teacher2 - English",
    "Room3" => "Teacher1 - Science"
  },
  "Slot2" => %{
    "Room1" => "Teacher3 - English",
    "Room2" => "Teacher5 - Science",
    "Room3" => "Available"
  },
  "Slot3" => %{
    "Room1" => "Teacher4 - Science",
    "Room2" => "Teacher1 - Math",
    "Room3" => "Teacher2 - Math"
  },
  "Slot4" => %{
    "Room1" => "Teacher3 - Science",
    "Room2" => "Teacher5 - Science",
    "Room3" => "Teacher4 - English"
  }
}

# SVG dimensions and styling
width = 800
height = 600
cell_width = 200
cell_height = 100
margin = 40

# Colors for different subjects
subject_colors = %{
  "Math" => "#FFE4B5",
  "Science" => "#98FB98",
  "English" => "#DDA0DD",
  "Available" => "#F0F0F0"
}

# Generate SVG content
svg_content = """
<?xml version="1.0" encoding="UTF-8"?>
<svg width="#{width}" height="#{height}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <style>
      .header { font-family: Arial, sans-serif; font-size: 14px; font-weight: bold; fill: #333; }
      .cell { font-family: Arial, sans-serif; font-size: 12px; fill: #333; }
      .title { font-family: Arial, sans-serif; font-size: 18px; font-weight: bold; fill: #333; text-anchor: middle; }
    </style>
  </defs>

  <!-- Background -->
  <rect width="100%" height="100%" fill="#FFFFFF"/>

  <!-- Title -->
  <text x="#{width / 2}" y="30" class="title">School Timetabling Solution</text>

  <!-- Time slot headers -->
  <text x="#{margin}" y="#{margin + 30}" class="header">Time Slot</text>
  <text x="#{margin + cell_width}" y="#{margin + 30}" class="header">Room 1</text>
  <text x="#{margin + 2 * cell_width}" y="#{margin + 30}" class="header">Room 2</text>
  <text x="#{margin + 3 * cell_width}" y="#{margin + 30}" class="header">Room 3</text>
"""

# Add the timetable cells
y_offset = margin + 50

Enum.each(Map.keys(timetable_data), fn time_slot ->
  # Time slot label
  svg_content =
    svg_content <>
      """
        <text x="#{margin + 10}" y="#{y_offset + 20}" class="cell">#{time_slot}</text>
      """

  # Room assignments
  x_offset = margin + cell_width

  Enum.each(["Room1", "Room2", "Room3"], fn room ->
    assignment = Map.get(timetable_data[time_slot], room, "Available")

    # Extract subject for coloring
    subject =
      case assignment do
        "Available" ->
          "Available"

        _ ->
          parts = String.split(assignment, " - ")
          if length(parts) >= 2, do: List.last(parts), else: "Other"
      end

    color = Map.get(subject_colors, subject, "#E6E6FA")

    # Draw cell background
    svg_content =
      svg_content <>
        """
          <rect x="#{x_offset}" y="#{y_offset}" width="#{cell_width - 20}" height="#{cell_height - 10}"
                fill="#{color}" stroke="#CCC" stroke-width="1"/>
        """

    # Draw text (split into multiple lines if needed)
    text_lines =
      case assignment do
        "Available" -> ["Available"]
        _ -> String.split(assignment, " ")
      end

    text_y = y_offset + 15

    Enum.each(text_lines, fn line ->
      svg_content =
        svg_content <>
          """
            <text x="#{x_offset + 10}" y="#{text_y}" class="cell">#{line}</text>
          """

      text_y = text_y + 15
    end)

    x_offset = x_offset + cell_width
  end)

  y_offset = y_offset + cell_height
end)

# Add legend
legend_y = y_offset + 40

svg_content =
  svg_content <>
    """
      <text x="#{margin}" y="#{legend_y}" class="header">Legend:</text>
    """

legend_colors = [
  {"Math", "#FFE4B5"},
  {"Science", "#98FB98"},
  {"English", "#DDA0DD"},
  {"Available", "#F0F0F0"}
]

legend_x = margin

Enum.each(legend_colors, fn {subject, color} ->
  svg_content =
    svg_content <>
      """
        <rect x="#{legend_x}" y="#{legend_y + 10}" width="20" height="15" fill="#{color}" stroke="#CCC"/>
        <text x="#{legend_x + 25}" y="#{legend_y + 22}" class="cell">#{subject}</text>
      """

  legend_x = legend_x + 100
end)

svg_content =
  svg_content <>
    """
    </svg>
    """

# Write SVG to file
File.write!("examples/school_timetable.svg", svg_content)

IO.puts("✅ SVG timetable generated: examples/school_timetable.svg")
IO.puts("📊 SVG dimensions: #{width}x#{height}")
IO.puts("🎨 Includes color-coded subjects and clear layout")
IO.puts("📝 Ready for embedding in README.md")
