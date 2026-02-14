///|
/// 8va (Ottava Alta) notation — shifts high notes down an octave visually

///|
const OTTAVA_THRESHOLD_MIDI = 84 // C6

///|
const OTTAVA_SHIFT = 12

///|
const OTTAVA_TEXT_Y_OFFSET = -55.0

///|
const OTTAVA_TEXT_X_OFFSET = 5.0

///|
const OTTAVA_LINE_Y_OFFSET = -50.0

///|
const OTTAVA_TICK_LENGTH = 8.0

///|
const OTTAVA_FONT_SIZE = "16"

///|
/// Returns true if any pitched note in the measure has MIDI >= threshold
fn should_apply_8va(positioned : Array[(Double, @music.MeasureNote)]) -> Bool {
  positioned
  .iter()
  .any(fn(pair) {
    match pair.1.midi {
      Some(midi) => midi >= OTTAVA_THRESHOLD_MIDI
      None => false
    }
  })
}

///|
/// Creates a copy with all MIDI values shifted down by OTTAVA_SHIFT
fn shift_for_ottava(
  positioned : Array[(Double, @music.MeasureNote)],
) -> Array[(Double, @music.MeasureNote)] {
  positioned.map(fn(pair) {
    let (pos, note) = pair
    let shifted_midi = note.midi.map(fn(m) { m - OTTAVA_SHIFT })
    (pos, { ..note, midi: shifted_midi })
  })
}

///|
/// Renders the 8va marking: italic text, dashed line, and end tick
fn render_8va_marking(
  measure_x : Double,
  staff_y : Double,
  measure_width : Double,
) -> Array[@luna_dom.DomNode] {
  let text_x = measure_x + OTTAVA_TEXT_X_OFFSET
  let text_y = staff_y + OTTAVA_TEXT_Y_OFFSET
  let line_start_x = text_x + 30.0
  let line_end_x = measure_x + measure_width - 5.0
  let line_y = staff_y + OTTAVA_LINE_Y_OFFSET
  [
    @luna_dom.svg_text(
      x=text_x.to_string(),
      y=text_y.to_string(),
      text_anchor="start",
      font_size=OTTAVA_FONT_SIZE,
      font_family="serif",
      attrs=[
        ("font-style", @luna_dom.Attr::AttrString("italic")),
        ("stroke", @luna_dom.Attr::AttrString("none")),
      ],
      [@luna_dom.text("8va")],
    ),
    @luna_dom.svg_line(
      x1=line_start_x.to_string(),
      y1=line_y.to_string(),
      x2=line_end_x.to_string(),
      y2=line_y.to_string(),
      stroke_width="1",
      attrs=[("stroke-dasharray", @luna_dom.Attr::AttrString("6,4"))],
    ),
    // Small downward tick at the end
    @luna_dom.svg_line(
      x1=line_end_x.to_string(),
      y1=line_y.to_string(),
      x2=line_end_x.to_string(),
      y2=(line_y + OTTAVA_TICK_LENGTH).to_string(),
      stroke_width="1",
    ),
  ]
}
