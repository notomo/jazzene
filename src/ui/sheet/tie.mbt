///|
/// Tie arc rendering for notes that span measure boundaries

///|
let tie_thickness = 6.0

///|
let tie_arc_height = 16.0

///|
let tie_y_offset = 10.0

///|
let tie_note_head_x_offset = 10.0

///|
let tie_edge_margin = 6.0

///|
let tie_control_point_1_ratio = 0.3

///|
let tie_control_point_2_ratio = 0.7

///|
let tie_stroke_width = "0.5"

///|
/// Render tie arc nodes for a note based on its tie state
pub fn render_tie_arcs(
  tie : @music.Tie?,
  note_x : Double,
  midi : Int,
  staff_y : Double,
  measure_x : Double,
) -> Array[@luna_dom.DomNode] {
  let note_y = midi_to_staff_y(midi, staff_y)
  let stem_up = midi < stem_direction_midi_threshold
  let measure_start_x = measure_x
  let measure_end_x = measure_x + measure_width
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
pub fn render_tie_start(
  note_x : Double,
  note_y : Double,
  measure_end_x : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  // Tie parameters
  let arc_height = if stem_up { tie_arc_height } else { -tie_arc_height }
  let y_offset = if stem_up { tie_y_offset } else { -tie_y_offset }

  // Start from the right side of the note head
  let start_x = note_x + tie_note_head_x_offset
  let start_y = note_y + y_offset

  // End at the right edge of the measure
  let end_x = measure_end_x - tie_edge_margin
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * tie_control_point_1_ratio
  let ctrl2_x = start_x + width * tie_control_point_2_ratio
  let ctrl_y = start_y + arc_height

  // Inner arc control points
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -tie_thickness } else { tie_thickness })

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
  @luna_dom.svg_path(d=path, fill=color_foreground, stroke=color_foreground, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(tie_stroke_width)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}

///|
/// Render a tie arc from the left edge of the measure to a note (TieEnd)
/// The arc curves away from the stem direction
pub fn render_tie_end(
  measure_start_x : Double,
  note_x : Double,
  note_y : Double,
  stem_up : Bool,
) -> @luna_dom.DomNode {
  // Tie parameters
  let arc_height = if stem_up { tie_arc_height } else { -tie_arc_height }
  let y_offset = if stem_up { tie_y_offset } else { -tie_y_offset }

  // Start from the left edge of the measure
  let start_x = measure_start_x + tie_edge_margin
  let start_y = note_y + y_offset

  // End at the left side of the note head
  let end_x = note_x - tie_note_head_x_offset
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * tie_control_point_1_ratio
  let ctrl2_x = start_x + width * tie_control_point_2_ratio
  let ctrl_y = start_y + arc_height

  // Inner arc control points
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -tie_thickness } else { tie_thickness })

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
  @luna_dom.svg_path(d=path, fill=color_foreground, stroke=color_foreground, attrs=[
    ("stroke-width", @luna_dom.Attr::AttrString(tie_stroke_width)),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}
