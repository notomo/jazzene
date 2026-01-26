///|
/// Playback position indicator - vertical line overlay

///|
/// Render a vertical line indicator showing the current playback position
pub fn render_playback_indicator(
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
  measure_count : () -> Int,
) -> @luna_dom.DomNode {
  // Staff height (5 lines with spacing between them)
  let staff_height = (staff_lines - 1).to_double() * staff_line_spacing

  // Vertical line from above chord symbols to below staff
  let line_top_offset = -100.0 // Same as chord_y_rect
  let line_bottom_offset = staff_height + 100.0 // Extended to cover low notes
  @luna_dom.svg_line(
    stroke="#3b82f6",
    stroke_width="10",
    attrs=[
      ("stroke-linecap", @luna_dom.Attr::AttrString("round")),
      ("stroke-opacity", @luna_dom.Attr::AttrString("0.5")),
    ],
    dyn_attrs=[
      (
        "x1",
        @luna_dom.AttrValue::Dynamic(fn() {
          calculate_indicator_x(
            playback_position.get(),
            bpm.get(),
            measure_count(),
          ).to_string()
        }),
      ),
      (
        "x2",
        @luna_dom.AttrValue::Dynamic(fn() {
          calculate_indicator_x(
            playback_position.get(),
            bpm.get(),
            measure_count(),
          ).to_string()
        }),
      ),
      (
        "y1",
        @luna_dom.AttrValue::Dynamic(fn() {
          let y = calculate_indicator_y(
            playback_position.get(),
            bpm.get(),
            measure_count(),
          )
          (y + line_top_offset).to_string()
        }),
      ),
      (
        "y2",
        @luna_dom.AttrValue::Dynamic(fn() {
          let y = calculate_indicator_y(
            playback_position.get(),
            bpm.get(),
            measure_count(),
          )
          (y + line_bottom_offset).to_string()
        }),
      ),
    ],
  )
}

///|
/// Calculate X position of the playback indicator
fn calculate_indicator_x(
  position : @music.Duration,
  bpm : Int,
  measure_count : Int,
) -> Double {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm)
  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return measure_start_x
  }

  // Calculate current measure index and progress within measure
  let measure_idx = (pos_ms / ms_per_measure).to_int()
  let raw_progress = (pos_ms - measure_idx.to_double() * ms_per_measure) /
    ms_per_measure

  // Clamp to valid measure range
  // When at or past the end, set progress to 1.0 to show indicator at end of last measure
  let (clamped_idx, progress) = if measure_idx >= measure_count {
    (measure_count - 1, 1.0)
  } else {
    (measure_idx, raw_progress)
  }

  // Calculate column position
  let col = clamped_idx % measures_per_row

  // X position: start of measure + progress within measure
  let measure_x = measure_start_x + col.to_double() * measure_width
  measure_x + progress * measure_width
}

///|
/// Calculate Y position (staff top) of the playback indicator
fn calculate_indicator_y(
  position : @music.Duration,
  bpm : Int,
  measure_count : Int,
) -> Double {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm)
  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return staff_top
  }

  // Calculate current measure index
  let measure_idx = (pos_ms / ms_per_measure).to_int()

  // Clamp to valid measure range
  let clamped_idx = if measure_idx >= measure_count {
    measure_count - 1
  } else {
    measure_idx
  }

  // Calculate row position
  let row = clamped_idx / measures_per_row

  // Y position: staff top for this row
  staff_top + row.to_double() * row_height
}
