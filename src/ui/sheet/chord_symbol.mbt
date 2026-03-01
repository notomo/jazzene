///|
/// Chord symbol rendering

///|
const CHORD_SYMBOL_Y_OFFSET = -85.0

///|
const CHORD_SYMBOL_X_OFFSET = 10.0

///|
const CHORD_SYMBOL_FONT_SIZE = "26"

///|
/// Render chord symbols positioned proportionally within the measure width
fn render_chord_symbol(
  measure : @music.Measure,
  x : Double,
  y : Double,
  measure_width~ : Double,
) -> Array[@luna_dom.DomNode] {
  let num_chords = measure.chords.length()
  guard num_chords > 0 else { return [] }
  measure.chords
  .iter()
  .mapi(fn(i, chord) {
    let chord_x = x +
      i.to_double() / num_chords.to_double() * measure_width +
      CHORD_SYMBOL_X_OFFSET
    @luna_dom.svg_text(
      x=chord_x.to_string(),
      y=(y + CHORD_SYMBOL_Y_OFFSET).to_string(),
      text_anchor="start",
      font_size=CHORD_SYMBOL_FONT_SIZE,
      font_family="serif",
      attrs=[("stroke", @luna_dom.Attr::AttrString("none"))],
      [@luna_dom.text(@music.format_chord(chord))],
    )
  })
  .collect()
}
