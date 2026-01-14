///|
/// Layout constants and calculations for lead sheet rendering

///|
pub let color_foreground = "#f1f5f9"

// Layout constants

///|
pub let staff_top = 80.0

///|
pub let staff_line_spacing = 15.0

///|
pub let staff_lines = 5

///|
pub let measures_per_row = 4

///|
pub let measure_width = 280.0

///|
pub let measure_start_x = 40.0

///|
pub let row_height = 250.0

///|
/// Calculate measure position in the layout
pub fn measure_position(measure_index : Int) -> (Double, Double) {
  let col = measure_index % measures_per_row
  let row = measure_index / measures_per_row
  let x = measure_start_x + col.to_double() * measure_width
  let y = staff_top + row.to_double() * row_height
  (x, y)
}
