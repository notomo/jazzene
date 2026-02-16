///|
/// Beam rendering from pre-computed SheetBeamGroup data

///|
const TRIPLET_LABEL_FONT_SIZE = "20"

///|
/// Render a single beam group from pre-computed data
fn render_beam_group_from_sheet(
  group : @music.SheetBeamGroup,
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
      group.first_beam_y + @music.BEAM_THICKNESS,
      group.last_beam_y,
      group.last_beam_y + @music.BEAM_THICKNESS,
    )
  } else {
    (
      group.first_beam_y - @music.BEAM_THICKNESS,
      group.first_beam_y,
      group.last_beam_y - @music.BEAM_THICKNESS,
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

  // Render rests
  for rest in group.rests {
    nodes.push(render_rest_symbol(rest.duration, rest.x, rest.y))
  }

  nodes
}

///|
/// Render all beam groups from pre-computed data
fn render_beams_from_sheet(
  beam_groups : Array[@music.SheetBeamGroup],
) -> Array[@luna_dom.DomNode] {
  beam_groups
  .iter()
  .flat_map(fn(group) { render_beam_group_from_sheet(group).iter() })
  .collect()
}
