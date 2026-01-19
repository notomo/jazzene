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
  let tie_thickness = 4.0
  let arc_height = if stem_up { 18.0 } else { -18.0 }
  let y_offset = if stem_up { 10.0 } else { -10.0 }

  // Start from the right side of the note head
  let start_x = note_x + 12.0
  let start_y = note_y + y_offset

  // End at the right edge of the measure
  let end_x = measure_end_x - 8.0
  let end_y = start_y

  // Control points for quadratic Bezier curve
  let mid_x = (start_x + end_x) / 2.0
  let ctrl_y = start_y + arc_height

  // Create filled path with outer and inner arcs
  let outer_arc = "M " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Q " +
    mid_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    end_x.to_string() +
    " " +
    end_y.to_string()
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -tie_thickness } else { tie_thickness })
  let inner_arc = " Q " +
    mid_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Z"
  @luna_dom.svg_path(
    d=outer_arc + inner_arc,
    fill=color_foreground,
    stroke="none",
    attrs=[],
  )
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
  let tie_thickness = 4.0
  let arc_height = if stem_up { 18.0 } else { -18.0 }
  let y_offset = if stem_up { 10.0 } else { -10.0 }

  // Start from the left edge of the measure
  let start_x = measure_start_x + 8.0
  let start_y = note_y + y_offset

  // End at the left side of the note head
  let end_x = note_x - 12.0
  let end_y = start_y

  // Control points for quadratic Bezier curve
  let mid_x = (start_x + end_x) / 2.0
  let ctrl_y = start_y + arc_height

  // Create filled path with outer and inner arcs
  let outer_arc = "M " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Q " +
    mid_x.to_string() +
    " " +
    ctrl_y.to_string() +
    " " +
    end_x.to_string() +
    " " +
    end_y.to_string()
  let inner_ctrl_y = ctrl_y +
    (if stem_up { -tie_thickness } else { tie_thickness })
  let inner_arc = " Q " +
    mid_x.to_string() +
    " " +
    inner_ctrl_y.to_string() +
    " " +
    start_x.to_string() +
    " " +
    start_y.to_string() +
    " Z"
  @luna_dom.svg_path(
    d=outer_arc + inner_arc,
    fill=color_foreground,
    stroke="none",
    attrs=[],
  )
}
