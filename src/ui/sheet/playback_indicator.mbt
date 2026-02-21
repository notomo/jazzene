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
  playback_position : @signals.Signal[@music.Duration],
  bpm : @signals.Signal[Int],
  measure_count : () -> Int,
  key : @signals.Signal[@music.KeySignature],
  time_signature : @signals.Signal[@music.TimeSignature],
  measure_width : () -> Double,
) -> @luna_dom.DomNode {
  let staff_height = (@sheet_layout.STAFF_LINES - 1).to_double() *
    @sheet_layout.STAFF_LINE_SPACING

  let line_top_offset = PLAYBACK_INDICATOR_TOP_OFFSET
  let line_bottom_offset = staff_height + PLAYBACK_INDICATOR_BOTTOM_OFFSET

  // Memoize x and y to avoid duplicate calculation for x1/x2 and y1/y2
  let indicator_x = @signals.memo(fn() {
    let beats_per_measure = time_signature.get().beats_per_measure()
    calculate_indicator_x(
      playback_position.get(),
      bpm.get(),
      measure_count(),
      key.get(),
      beats_per_measure~,
      measure_width=measure_width(),
    )
  })
  let indicator_y = @signals.memo(fn() {
    let beats_per_measure = time_signature.get().beats_per_measure()
    calculate_indicator_y(
      playback_position.get(),
      bpm.get(),
      measure_count(),
      beats_per_measure~,
    )
  })

  @luna_dom.svg_line(
    stroke=PLAYBACK_INDICATOR_COLOR,
    stroke_width=PLAYBACK_INDICATOR_STROKE_WIDTH,
    attrs=[
      ("stroke-linecap", @luna_dom.Attr::AttrString("round")),
      ("stroke-opacity", @luna_dom.Attr::AttrString("0.5")),
    ],
    dyn_attrs=[
      ("x1", @luna_dom.AttrValue::Dynamic(fn() { indicator_x().to_string() })),
      ("x2", @luna_dom.AttrValue::Dynamic(fn() { indicator_x().to_string() })),
      (
        "y1",
        @luna_dom.AttrValue::Dynamic(fn() {
          (indicator_y() + line_top_offset).to_string()
        }),
      ),
      (
        "y2",
        @luna_dom.AttrValue::Dynamic(fn() {
          (indicator_y() + line_bottom_offset).to_string()
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
  measure_width? : Double = @sheet_layout.MIN_MEASURE_WIDTH,
) -> Double {
  let pos_ms = position.to_milliseconds()
  let ms_per_measure = @music.ms_per_measure(bpm, beats_per_measure~)
  let clef_and_key_width = @sheet_layout.CLEF_SPACE_WIDTH +
    @sheet_layout.key_signature_layout_width(key)

  if ms_per_measure <= 0.0 || measure_count <= 0 {
    return @sheet_layout.MEASURE_START_X + clef_and_key_width
  }

  let measure_idx = (pos_ms / ms_per_measure).to_int()
  let raw_progress = (pos_ms - measure_idx.to_double() * ms_per_measure) /
    ms_per_measure

  let (clamped_idx, progress) = if measure_idx >= measure_count {
    (measure_count - 1, 1.0)
  } else {
    (measure_idx, raw_progress)
  }

  let col = clamped_idx % @sheet_layout.MEASURES_PER_ROW

  let measure_x = @sheet_layout.MEASURE_START_X +
    clef_and_key_width +
    col.to_double() * measure_width
  measure_x + progress * measure_width
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
    return @sheet_layout.STAFF_TOP
  }

  let measure_idx = (pos_ms / ms_per_measure).to_int()

  let clamped_idx = if measure_idx >= measure_count {
    measure_count - 1
  } else {
    measure_idx
  }

  let row = clamped_idx / @sheet_layout.MEASURES_PER_ROW

  @sheet_layout.STAFF_TOP + row.to_double() * @sheet_layout.ROW_HEIGHT
}
