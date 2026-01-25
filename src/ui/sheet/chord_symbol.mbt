///|
/// Chord symbol rendering with dynamic highlighting

///|
/// Format array of chords for display, joining with " | " separator
fn format_chords(chords : Array[@music.Chord]) -> String {
  chords.iter().map(@music.format_chord).collect().join(" ")
}

///|
/// Render chord symbol with background highlight based on current measure
pub fn render_chord_symbol(
  measure : @music.Measure,
  x : Double,
  y : Double,
  current_measure_index : () -> Int,
) -> Array[@luna_dom.DomNode] {
  let children : Array[@luna_dom.DomNode] = []

  // Don't show chord for measures without chords (e.g., leading rest measure)
  if measure.chords.is_empty() {
    return children
  }

  // Calculate chord y position relative to staff
  // Position high enough to avoid overlap with ledger line notes (E6 at step 14 is at y - 45)
  let chord_y_rect = y - 100.0 // Background rectangle y position
  let chord_y_text = y - 85.0 // Text y position

  // Background rectangle for highlighted chord (white background for better contrast)
  children.push(
    @luna_dom.svg_rect(
      x=(x + 5.0).to_string(),
      y=chord_y_rect.to_string(),
      rx="6",
      ry="6",
      dyn_attrs=[
        (
          "width",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              let chord_text = format_chords(measure.chords)
              let estimated_width = chord_text.length().to_double() * 18.0 +
                20.0
              estimated_width.to_int().to_string()
            } else {
              "0"
            }
          }),
        ),
        (
          "height",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              "32"
            } else {
              "0"
            }
          }),
        ),
        (
          "fill",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              "#ffffff"
            } else {
              "transparent"
            }
          }),
        ),
        (
          "opacity",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              "0.95"
            } else {
              "0"
            }
          }),
        ),
      ],
    ),
  )

  // Chord text
  children.push(
    @luna_dom.svg_text(
      x=(x + 10.0).to_string(),
      y=chord_y_text.to_string(),
      text_anchor="start",
      font_size="26",
      font_family="serif",
      dyn_attrs=[
        (
          "fill",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              "#1e3a8a" // Dark blue for strong contrast on white background
            } else {
              color_foreground
            }
          }),
        ),
        (
          "font-weight",
          @luna_dom.AttrValue::Dynamic(fn() {
            if measure.measure_index == current_measure_index() {
              "bold"
            } else {
              "normal"
            }
          }),
        ),
      ],
      [@luna_dom.text(format_chords(measure.chords))],
    ),
  )
  children
}
