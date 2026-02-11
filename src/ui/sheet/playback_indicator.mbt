///|
/// Playback position indicator - vertical line overlay

///|
const PLAYBACK_INDICATOR_TOP_OFFSET = -100.0

///|
const PLAYBACK_INDICATOR_BOTTOM_OFFSET = 100.0

///|
const PLAYBACK_INDICATOR_COLOR = "#3b82f6"

///|
const PLAYBACK_INDICATOR_STROKE_WIDTH = "10"

///|
/// Render a vertical line indicator showing the current playback position
fn render_playback_indicator(
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
  measure_count : () -> Int,
  key : @signal.Signal[@music.KeySignature],
  time_signature : @signal.Signal[@music.TimeSignature],
) -> @luna_dom.DomNode {
  // Staff height (5 lines with spacing between them)
  let staff_height = (STAFF_LINES - 1).to_double() * STAFF_LINE_SPACING

  let line_top_offset = PLAYBACK_INDICATOR_TOP_OFFSET
  let line_bottom_offset = staff_height + PLAYBACK_INDICATOR_BOTTOM_OFFSET
  @luna_dom.svg_line(
    stroke=PLAYBACK_INDICATOR_COLOR,
    stroke_width=PLAYBACK_INDICATOR_STROKE_WIDTH,
    attrs=[
      ("stroke-linecap", @luna_dom.Attr::AttrString("round")),
      ("stroke-opacity", @luna_dom.Attr::AttrString("0.5")),
    ],
    dyn_attrs=[
      (
        "x1",
        @luna_dom.AttrValue::Dynamic(fn() {
          let beats_per_measure = time_signature.get().beats_per_measure()
          calculate_indicator_x(
            playback_position.get(),
            bpm.get(),
            measure_count(),
            key.get(),
            beats_per_measure~,
          ).to_string()
        }),
      ),
      (
        "x2",
        @luna_dom.AttrValue::Dynamic(fn() {
          let beats_per_measure = time_signature.get().beats_per_measure()
          calculate_indicator_x(
            playback_position.get(),
            bpm.get(),
            measure_count(),
            key.get(),
            beats_per_measure~,
          ).to_string()
        }),
      ),
      (
        "y1",
        @luna_dom.AttrValue::Dynamic(fn() {
          let beats_per_measure = time_signature.get().beats_per_measure()
          let y = calculate_indicator_y(
            playback_position.get(),
            bpm.get(),
            measure_count(),
            beats_per_measure~,
          )
          (y + line_top_offset).to_string()
        }),
      ),
      (
        "y2",
        @luna_dom.AttrValue::Dynamic(fn() {
          let beats_per_measure = time_signature.get().beats_per_measure()
          let y = calculate_indicator_y(
            playback_position.get(),
            bpm.get(),
            measure_count(),
            beats_per_measure~,
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
  key : @music.KeySignature,
  beats_per_measure~ : Double,
) -> Double {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm, beats_per_measure~)
  let clef_and_key_width = CLEF_SPACE_WIDTH + key_signature_width(key)

  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return MEASURE_START_X + clef_and_key_width
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
  let col = clamped_idx % MEASURES_PER_ROW

  // X position: start of measure + progress within measure (with clef space offset)
  let measure_x = MEASURE_START_X +
    clef_and_key_width +
    col.to_double() * MEASURE_WIDTH
  measure_x + progress * MEASURE_WIDTH
}

///|
/// Calculate Y position (staff top) of the playback indicator
fn calculate_indicator_y(
  position : @music.Duration,
  bpm : Int,
  measure_count : Int,
  beats_per_measure~ : Double,
) -> Double {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm, beats_per_measure~)
  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return STAFF_TOP
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
  let row = clamped_idx / MEASURES_PER_ROW

  // Y position: staff top for this row
  STAFF_TOP + row.to_double() * ROW_HEIGHT
}
