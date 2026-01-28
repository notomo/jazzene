///|
/// Chord symbol rendering

///|
let chord_symbol_y_offset = -85.0

///|
let chord_symbol_x_offset = 10.0

///|
let chord_symbol_font_size = "26"

///|
/// Format array of chords for display, joining with " " separator
fn format_chords(chords : Array[@music.Chord]) -> String {
  chords.iter().map(@music.format_chord).collect().join(" ")
}

///|
/// Render chord symbol as static text
fn render_chord_symbol(
  measure : @music.Measure,
  x : Double,
  y : Double,
) -> Array[@luna_dom.DomNode] {
  // Don't show chord for measures without chords (e.g., leading rest measure)
  if measure.chords.is_empty() {
    return []
  }

  // Calculate chord y position relative to staff
  // Position high enough to avoid overlap with ledger line notes (E6 at step 14 is at y - 45)
  let chord_y_text = y + chord_symbol_y_offset
  [
    @luna_dom.svg_text(
      x=(x + chord_symbol_x_offset).to_string(),
      y=chord_y_text.to_string(),
      text_anchor="start",
      font_size=chord_symbol_font_size,
      font_family="serif",
      fill=color_foreground,
      [@luna_dom.text(format_chords(measure.chords))],
    ),
  ]
}
