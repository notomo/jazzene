///|
/// Beam rendering from pre-computed SheetBeamGroup data

///|
const TRIPLET_LABEL_FONT_SIZE = "20"

///|
/// Render a single beam group from pre-computed data
fn render_beam_group_from_sheet(
  group : @sheet_layout.SheetBeamGroup,
) -> Array[@luna_dom.DomNode] {
  let nodes : Array[@luna_dom.DomNode] = []

  // Render stems
  for stem in group.stems {
    nodes.push(
      @luna_dom.svg_line(
        x1=stem.x.to_string(),
        y1=stem.y1.to_string(),
        x2=stem.x.to_string(),
        y2=stem.y2.to_string(),
        stroke_width="1.5",
      ),
    )
  }

  // Render beam as polygon
  let (first_top, first_bottom, last_top, last_bottom) = if group.stem_up {
    (
      group.first_beam_y,
      group.first_beam_y + @sheet_layout.BEAM_THICKNESS,
      group.last_beam_y,
      group.last_beam_y + @sheet_layout.BEAM_THICKNESS,
    )
  } else {
    (
      group.first_beam_y - @sheet_layout.BEAM_THICKNESS,
      group.first_beam_y,
      group.last_beam_y - @sheet_layout.BEAM_THICKNESS,
      group.last_beam_y,
    )
  }
  let points = "\{group.first_x},\{first_top} \{group.last_x},\{last_top} \{group.last_x},\{last_bottom} \{group.first_x},\{first_bottom}"
  nodes.push(@luna_dom.svg_polygon(points~, stroke="none"))

  // Render triplet "3" label
  if group.show_triplet_label {
    nodes.push(
      @luna_dom.svg_text(
        x=group.triplet_label_x.to_string(),
        y=group.triplet_label_y.to_string(),
        text_anchor="middle",
        font_size=TRIPLET_LABEL_FONT_SIZE,
        font_family="serif",
        attrs=[
          ("stroke", @luna_dom.Attr::AttrString("none")),
          ("font-style", @luna_dom.Attr::AttrString("italic")),
        ],
        [@luna_dom.text("3")],
      ),
    )
  }

  // Render secondary beams (for Sixteenth notes)
  for seg in group.secondary_beams {
    let (sx, sy, ex, ey) = seg
    let (first_top, first_bottom, last_top, last_bottom) = if group.stem_up {
      (
        sy,
        sy + @sheet_layout.BEAM_THICKNESS,
        ey,
        ey + @sheet_layout.BEAM_THICKNESS,
      )
    } else {
      (
        sy - @sheet_layout.BEAM_THICKNESS,
        sy,
        ey - @sheet_layout.BEAM_THICKNESS,
        ey,
      )
    }
    let sx_s = sx.to_string()
    let ex_s = ex.to_string()
    let ft_s = first_top.to_string()
    let lt_s = last_top.to_string()
    let lb_s = last_bottom.to_string()
    let fb_s = first_bottom.to_string()
    let pts = "\{sx_s},\{ft_s} \{ex_s},\{lt_s} \{ex_s},\{lb_s} \{sx_s},\{fb_s}"
    nodes.push(@luna_dom.svg_polygon(points=pts, stroke="none"))
  }

  // Render rests
  for rest in group.rests {
    nodes.push(render_rest_symbol(rest.duration, rest.x, rest.y))
  }

  nodes
}

///|
/// Render all beam groups from pre-computed data
fn render_beams_from_sheet(
  beam_groups : Array[@sheet_layout.SheetBeamGroup],
) -> Array[@luna_dom.DomNode] {
  beam_groups
  .iter()
  .flat_map(fn(group) { render_beam_group_from_sheet(group).iter() })
  .collect()
}
