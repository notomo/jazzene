///|
/// Time signature display on staff (fraction format)

///|
const TIME_SIG_FONT_SIZE = "36"

///|
/// Render time signature as a fraction (numerator over denominator)
/// Positioned after the treble clef and key signature on the first row
fn render_time_signature_display(
  time_signature : @signal.Signal[@music.TimeSignature],
  key : @signal.Signal[@music.KeySignature],
) -> @luna_dom.DomNode {
  let key_sig_width = key_signature_width(key.get())
  let x = MEASURE_START_X +
    TREBLE_CLEF_X_OFFSET +
    KEY_SIG_START_OFFSET +
    key_sig_width
  let y = STAFF_TOP
  let staff_center = y + STAFF_LINE_SPACING * 2.0
  let ts = time_signature.get()
  @luna_dom.svg_g([
    // Numerator (top half of staff)
    @luna_dom.svg_text(
      x=x.to_string(),
      y=(staff_center - STAFF_LINE_SPACING * 0.1).to_string(),
      font_size=TIME_SIG_FONT_SIZE,
      text_anchor="middle",
      dominant_baseline="auto",
      attrs=[
        ("font-weight", @luna_dom.Attr::AttrString("bold")),
        ("stroke", @luna_dom.Attr::AttrString("none")),
      ],
      [@luna_dom.text(ts.numerator.to_string())],
    ),
    // Denominator (bottom half of staff)
    @luna_dom.svg_text(
      x=x.to_string(),
      y=(staff_center + STAFF_LINE_SPACING * 0.1).to_string(),
      font_size=TIME_SIG_FONT_SIZE,
      text_anchor="middle",
      dominant_baseline="hanging",
      attrs=[
        ("font-weight", @luna_dom.Attr::AttrString("bold")),
        ("stroke", @luna_dom.Attr::AttrString("none")),
      ],
      [@luna_dom.text(ts.denominator.to_string())],
    ),
  ])
}
