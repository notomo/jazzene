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
/// Render tie arc nodes for a note based on its tie state.
/// prev_note_x/next_note_x are provided for within-measure ties;
/// when None, arcs extend to measure edges (cross-measure ties).
fn render_tie_arcs(
  tie : @music.Tie?,
  note_x : Double,
  midi : Int,
  staff_y : Double,
  measure_x : Double,
  key : @music.KeySignature,
  prev_note_x? : Double? = None,
  next_note_x? : Double? = None,
) -> Array[@luna_dom.DomNode] {
  let note_y = midi_to_staff_y(midi, staff_y, key)
  let stem_up = midi < STEM_DIRECTION_MIDI_THRESHOLD
  let measure_start_x = measure_x
  let measure_end_x = measure_x + MEASURE_WIDTH
  match tie {
    Some(@music.TieStart) => {
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [render_tie_start(note_x, note_y, end_x, stem_up)]
    }
    Some(@music.TieEnd) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      [render_tie_end(start_x, note_x, note_y, stem_up)]
    }
    Some(@music.TieBoth) => {
      let start_x = match prev_note_x {
        Some(px) => px
        None => measure_start_x
      }
      let end_x = match next_note_x {
        Some(nx) => nx
        None => measure_end_x
      }
      [
        render_tie_end(start_x, note_x, note_y, stem_up),
        render_tie_start(note_x, note_y, end_x, stem_up),
      ]
    }
    None => []
  }
}

///|
/// Render a tie arc from a note to the right (TieStart)
/// The arc curves away from the stem direction (down if stem up, up if stem down)
fn render_tie_start(
  note_x : Double,
  note_y : Double,
  end_target_x : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  let arc_height = if stem_up { TIE_ARC_HEIGHT } else { -TIE_ARC_HEIGHT }
  let y_offset = if stem_up { TIE_Y_OFFSET } else { -TIE_Y_OFFSET }

  let start_x = note_x + TIE_NOTE_HEAD_X_OFFSET
  let start_y = note_y + y_offset

  let end_x = end_target_x - TIE_EDGE_MARGIN
  let end_y = start_y

  let width = end_x - start_x
  let ctrl1_x = start_x + width * TIE_CONTROL_POINT_1_RATIO
  let ctrl2_x = start_x + width * TIE_CONTROL_POINT_2_RATIO
  let ctrl_y = start_y + arc_height

  let inner_ctrl_y = ctrl_y +
    (if stem_up { -TIE_THICKNESS } else { TIE_THICKNESS })
  let path = tie_arc_path(
    start_x, start_y, end_x, end_y, ctrl1_x, ctrl2_x, ctrl_y, inner_ctrl_y,
  )

  @luna_dom.svg_path(d=path, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(TIE_STROKE_WIDTH)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}

///|
/// Render a tie arc from a start position to a note (TieEnd)
/// The arc curves away from the stem direction
fn render_tie_end(
  start_origin_x : Double,
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  let arc_height = if stem_up { TIE_ARC_HEIGHT } else { -TIE_ARC_HEIGHT }
  let y_offset = if stem_up { TIE_Y_OFFSET } else { -TIE_Y_OFFSET }

  let start_x = start_origin_x + TIE_EDGE_MARGIN
  let start_y = note_y + y_offset

  let end_x = note_x - TIE_NOTE_HEAD_X_OFFSET
  let end_y = start_y

  let width = end_x - start_x
  let ctrl1_x = start_x + width * TIE_CONTROL_POINT_1_RATIO
  let ctrl2_x = start_x + width * TIE_CONTROL_POINT_2_RATIO
  let ctrl_y = start_y + arc_height

  let inner_ctrl_y = ctrl_y +
    (if stem_up { -TIE_THICKNESS } else { TIE_THICKNESS })
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
