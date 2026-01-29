///|
/// Tie arc rendering for notes that span measure boundaries

///|
const TIE_THICKNESS = 6.0

///|
const TIE_ARC_HEIGHT = 16.0

///|
const TIE_Y_OFFSET = 10.0

///|
const TIE_NOTE_HEAD_X_OFFSET = 10.0

///|
const TIE_EDGE_MARGIN = 6.0

///|
const TIE_CONTROL_POINT_1_RATIO = 0.3

///|
const TIE_CONTROL_POINT_2_RATIO = 0.7

///|
const TIE_STROKE_WIDTH = "0.5"

///|
/// Render tie arc nodes for a note based on its tie state
fn render_tie_arcs(
  tie : @music.Tie?,
  note_x : Double,
  midi : Int,
  staff_y : Double,
  measure_x : Double,
) -> Array[@luna_dom.DomNode] {
  let note_y = midi_to_staff_y(midi, staff_y)
  let stem_up = midi < STEM_DIRECTION_MIDI_THRESHOLD
  let measure_start_x = measure_x
  let measure_end_x = measure_x + MEASURE_WIDTH
  match tie {
    Some(@music.TieStart) =>
      [render_tie_start(note_x, note_y, measure_end_x, stem_up)]
    Some(@music.TieEnd) =>
      [render_tie_end(measure_start_x, note_x, note_y, stem_up)]
    Some(@music.TieBoth) =>
      [
        render_tie_end(measure_start_x, note_x, note_y, stem_up),
        render_tie_start(note_x, note_y, measure_end_x, stem_up),
      ]
    None => []
  }
}

///|
/// Render a tie arc from a note to the right edge of the measure (TieStart)
/// The arc curves away from the stem direction (down if stem up, up if stem down)
fn render_tie_start(
  note_x : Double,
  note_y : Double,
  measure_end_x : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  // Tie parameters
  let arc_height = if stem_up { TIE_ARC_HEIGHT } else { -TIE_ARC_HEIGHT }
  let y_offset = if stem_up { TIE_Y_OFFSET } else { -TIE_Y_OFFSET }

  // Start from the right side of the note head
  let start_x = note_x + TIE_NOTE_HEAD_X_OFFSET
  let start_y = note_y + y_offset

  // End at the right edge of the measure
  let end_x = measure_end_x - TIE_EDGE_MARGIN
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * TIE_CONTROL_POINT_1_RATIO
  let ctrl2_x = start_x + width * TIE_CONTROL_POINT_2_RATIO
  let ctrl_y = start_y + arc_height

  // Inner arc control points
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -TIE_THICKNESS } else { TIE_THICKNESS })

  // Create filled path with outer and inner cubic Bezier arcs
  let path = "M " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " C " +
    ctrl1_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    ctrl2_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    end_x.to_string() +
    " " +
    end_y.to_string() +
    " C " +
    ctrl2_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    ctrl1_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Z"
  @luna_dom.svg_path(d=path, fill=COLOR_FOREGROUND, stroke=COLOR_FOREGROUND, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(TIE_STROKE_WIDTH)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}

///|
/// Render a tie arc from the left edge of the measure to a note (TieEnd)
/// The arc curves away from the stem direction
fn render_tie_end(
  measure_start_x : Double,
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  // Tie parameters
  let arc_height = if stem_up { TIE_ARC_HEIGHT } else { -TIE_ARC_HEIGHT }
  let y_offset = if stem_up { TIE_Y_OFFSET } else { -TIE_Y_OFFSET }

  // Start from the left edge of the measure
  let start_x = measure_start_x + TIE_EDGE_MARGIN
  let start_y = note_y + y_offset

  // End at the left side of the note head
  let end_x = note_x - TIE_NOTE_HEAD_X_OFFSET
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * TIE_CONTROL_POINT_1_RATIO
  let ctrl2_x = start_x + width * TIE_CONTROL_POINT_2_RATIO
  let ctrl_y = start_y + arc_height

  // Inner arc control points
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -TIE_THICKNESS } else { TIE_THICKNESS })

  // Create filled path with outer and inner cubic Bezier arcs
  let path = "M " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " C " +
    ctrl1_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    ctrl2_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    end_x.to_string() +
    " " +
    end_y.to_string() +
    " C " +
    ctrl2_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    ctrl1_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Z"
  @luna_dom.svg_path(d=path, fill=COLOR_FOREGROUND, stroke=COLOR_FOREGROUND, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(TIE_STROKE_WIDTH)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}
