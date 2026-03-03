///|
/// Tension label rendering for sheet music notation

///|
/// Render a tension degree label (e.g. "9", "11", "13") above a note
fn render_tension_label(
  degree : Int,
  note_x : Double,
  note_y : Double,
  on_line : Bool,
) -> @luna_dom.DomNode {
  // When the note is in a space (on_line=false), note_y - 1.5*spacing lands on a line.
  // Shift an extra half-spacing to keep the label between lines.
  let label_y = if on_line {
    note_y - @sheet_layout.STAFF_LINE_SPACING * 1.5
  } else {
    note_y - @sheet_layout.STAFF_LINE_SPACING * 2.2
  }
  @luna_dom.svg_text(
    x=note_x.to_string(),
    y=label_y.to_string(),
    text_anchor="middle",
    font_size="20",
    font_family="sans-serif",
    dominant_baseline="central",
    attrs=[
      ("stroke", @luna_dom.Attr::AttrString("#0f172a")),
      ("stroke-width", @luna_dom.Attr::AttrString("3")),
      ("paint-order", @luna_dom.Attr::AttrString("stroke fill")),
      ("fill", @luna_dom.Attr::AttrString("#4ade80")),
    ],
    [@luna_dom.text(degree.to_string())],
  )
}

///|
/// Render tension label for a note, if it has one (rendered separately to appear above beams)
fn render_note_tension_label(
  note : @sheet_layout.SheetNote,
  show_legend : () -> Bool,
) -> @luna_dom.DomNode? {
  match note.tone_origin {
    Some(Tension(degree)) =>
      Some(
        @luna_dom.show(show_legend, fn() {
          render_tension_label(degree, note.x, note.y, note.on_line)
        }),
      )
    _ => None
  }
}
