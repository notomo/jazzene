///|
/// Time signature display on staff (fraction format)

///|
const TIME_SIG_FONT_SIZE = "36"

///|
/// Render time signature for a measure (only on first measure)
fn render_measure_time_signature(
  time_signature : @music.TimeSignature,
  x : Double,
  y : Double,
  is_first_measure : Bool,
) -> Array[@luna_dom.DomNode] {
  match is_first_measure {
    true => render_time_signature_display(time_signature, x, y)
    false => []
  }
}

///|
/// Render time signature as a fraction (numerator over denominator)
/// Positioned after the treble clef and key signature
fn render_time_signature_display(
  time_signature : @music.TimeSignature,
  x : Double,
  y : Double,
) -> Array[@luna_dom.DomNode] {
  let staff_center = y + STAFF_LINE_SPACING * 2.0
  let ts_x = x - CLEF_SPACE_WIDTH + TREBLE_CLEF_X_OFFSET + KEY_SIG_START_OFFSET
  [
    // Numerator (top half of staff)
    @luna_dom.svg_text(
      x=ts_x.to_string(),
      y=(staff_center - STAFF_LINE_SPACING * 0.1).to_string(),
      font_size=TIME_SIG_FONT_SIZE,
      text_anchor="middle",
      dominant_baseline="auto",
      attrs=[
        ("font-weight", @luna_dom.Attr::AttrString("bold")),
        ("stroke", @luna_dom.Attr::AttrString("none")),
      ],
      [@luna_dom.text(time_signature.numerator.to_string())],
    ),
    // Denominator (bottom half of staff)
    @luna_dom.svg_text(
      x=ts_x.to_string(),
      y=(staff_center + STAFF_LINE_SPACING * 0.1).to_string(),
      font_size=TIME_SIG_FONT_SIZE,
      text_anchor="middle",
      dominant_baseline="hanging",
      attrs=[
        ("font-weight", @luna_dom.Attr::AttrString("bold")),
        ("stroke", @luna_dom.Attr::AttrString("none")),
      ],
      [@luna_dom.text(time_signature.denominator.to_string())],
    ),
  ]
}
