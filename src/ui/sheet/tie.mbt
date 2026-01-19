///|
/// Tie arc rendering for notes that span measure boundaries

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
  let tie_thickness = 6.0
  let arc_height = if stem_up { 16.0 } else { -16.0 }
  let y_offset = if stem_up { 10.0 } else { -10.0 }

  // Start from the right side of the note head
  let start_x = note_x + 10.0
  let start_y = note_y + y_offset

  // End at the right edge of the measure
  let end_x = measure_end_x - 6.0
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * 0.3
  let ctrl2_x = start_x + width * 0.7
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
    ("stroke-width", @luna_dom.Attr::AttrString("0.5")),
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
  let tie_thickness = 6.0
  let arc_height = if stem_up { 16.0 } else { -16.0 }
  let y_offset = if stem_up { 10.0 } else { -10.0 }

  // Start from the left edge of the measure
  let start_x = measure_start_x + 6.0
  let start_y = note_y + y_offset

  // End at the left side of the note head
  let end_x = note_x - 10.0
  let end_y = start_y

  // Control points for cubic Bezier curve (smoother than quadratic)
  let width = end_x - start_x
  let ctrl1_x = start_x + width * 0.3
  let ctrl2_x = start_x + width * 0.7
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
    ("stroke-width", @luna_dom.Attr::AttrString("0.5")),
    ("stroke-linejoin", @luna_dom.Attr::AttrString("round")),
  ])
}
