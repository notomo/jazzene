///|
/// Chord symbol rendering

///|
const CHORD_SYMBOL_Y_OFFSET = -85.0

///|
const CHORD_SYMBOL_X_OFFSET = 10.0

///|
const CHORD_SYMBOL_FONT_SIZE = "26"

///|
/// Render chord symbols positioned proportionally within the measure width.
/// Each chord symbol has an invisible clickable area for editing.
fn render_chord_symbol(
  measure : @music.Measure,
  x : Double,
  y : Double,
  measure_width~ : Double,
  measure_idx~ : Int,
  on_chord_click~ : (Int, Int) -> Unit,
) -> Array[@luna_dom.DomNode] {
  let num_chords = measure.chords.length()
  guard num_chords > 0 else { return [] }
  let chord_slot_width = measure_width / num_chords.to_double()
  measure.chords
  .iter()
  .mapi(fn(i, chord) {
    let chord_x = x +
      i.to_double() / num_chords.to_double() * measure_width +
      CHORD_SYMBOL_X_OFFSET
    let click_x = x + i.to_double() / num_chords.to_double() * measure_width
    let ci = i
    @luna_dom.svg_g([
      @luna_dom.svg_text(
        x=chord_x.to_string(),
        y=(y + CHORD_SYMBOL_Y_OFFSET).to_string(),
        text_anchor="start",
        font_size=CHORD_SYMBOL_FONT_SIZE,
        font_family="serif",
        attrs=[
          ("stroke", @luna_dom.Attr::AttrString("none")),
          ("style", @luna_dom.Attr::AttrString("cursor: pointer")),
        ],
        [@luna_dom.text(@music.format_chord(chord))],
      ),
      // Transparent click target covering the chord symbol area
      @luna_dom.svg_rect(
        x=click_x.to_string(),
        y=(y + CHORD_SYMBOL_Y_OFFSET - 26.0).to_string(),
        width=chord_slot_width.to_string(),
        height="34",
        fill="transparent",
        stroke="none",
        style="cursor: pointer",
        on=@luna_dom.events().click(fn(_) { on_chord_click(measure_idx, ci) }),
      ),
    ])
  })
  .collect()
}
