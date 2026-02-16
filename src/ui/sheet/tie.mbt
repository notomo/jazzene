///|
/// Tie arc rendering for notes that span measure or beat boundaries

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
/// Render tie arcs from pre-computed SheetTieArc data
fn render_tie_arcs_from_sheet(
  arcs : Array[@music.SheetTieArc],
) -> Array[@luna_dom.DomNode] {
  arcs.map(fn(arc) { render_tie_arc(arc) })
}

///|
/// Render a single tie arc from SheetTieArc data
fn render_tie_arc(arc : @music.SheetTieArc) -> @luna_dom.DomNode {
  let arc_height = if arc.stem_up { TIE_ARC_HEIGHT } else { -TIE_ARC_HEIGHT }
  let y_offset = if arc.stem_up { TIE_Y_OFFSET } else { -TIE_Y_OFFSET }

  // Determine if this is a tie-start or tie-end based on x positions
  // start_x < end_x for tie-start, start_x > end_x (impossible) or we use note_y
  let start_x = arc.start_x + TIE_NOTE_HEAD_X_OFFSET
  let start_y = arc.note_y + y_offset

  let end_x = arc.end_x - TIE_EDGE_MARGIN
  let end_y = start_y

  let width = end_x - start_x
  let ctrl1_x = start_x + width * TIE_CONTROL_POINT_1_RATIO
  let ctrl2_x = start_x + width * TIE_CONTROL_POINT_2_RATIO
  let ctrl_y = start_y + arc_height

  let inner_ctrl_y = ctrl_y +
    (if arc.stem_up { -TIE_THICKNESS } else { TIE_THICKNESS })
  let path = tie_arc_path(
    start_x, start_y, end_x, end_y, ctrl1_x, ctrl2_x, ctrl_y, inner_ctrl_y,
  )

  @luna_dom.svg_path(d=path, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(TIE_STROKE_WIDTH)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}

///|
fn tie_arc_path(
  start_x : Double,
  start_y : Double,
  end_x : Double,
  end_y : Double,
  ctrl1_x : Double,
  ctrl2_x : Double,
  ctrl_y : Double,
  inner_ctrl_y : Double,
) -> String {
  let coords = fn(values : Array[Double]) -> String {
    values.map(fn(v) { v.to_string() }).join(" ")
  }
  [
    "M " + coords([start_x, start_y]),
    "C " + coords([ctrl1_x, ctrl_y, ctrl2_x, ctrl_y, end_x, end_y]),
    "C " +
    coords([ctrl2_x, inner_ctrl_y, ctrl1_x, inner_ctrl_y, start_x, start_y]),
    "Z",
  ].join(" ")
}
