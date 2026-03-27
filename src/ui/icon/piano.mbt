///|
/// Piano keyboard icon (white keys with divider lines, filled black keys)
pub fn piano_icon(active : Bool) -> @luna_dom.DomNode {
  let color = if active { "#93c5fd" } else { "#94a3b8" }
  // Outer border
  let border : @luna_dom.DomNode = @luna_dom.svg_rect(
    x="1",
    y="1",
    width="14",
    height="14",
    fill="none",
    stroke=color,
    attrs=[("stroke-width", @luna_dom.Attr::AttrString("1"))],
  )
  // Black key positions: center_x values for divider alignment
  let black_key_centers = [5.5, 10.5]
  // White key divider lines (aligned to black key centers)
  let dividers : Array[@luna_dom.DomNode] = black_key_centers.map(fn(cx) {
    let x = cx.to_string()
    @luna_dom.svg_line(x1=x, y1="1", x2=x, y2="15", stroke=color, attrs=[
      ("stroke-width", @luna_dom.Attr::AttrString("0.8")),
    ])
  })
  // Black keys (filled rectangles)
  let black_keys : Array[@luna_dom.DomNode] = black_key_centers.map(fn(cx) {
    let x = (cx - 1.5).to_string()
    @luna_dom.svg_rect(x~, y="1", width="3", height="8", fill=color)
  })
  @luna_dom.svg([border] + dividers + black_keys, attrs=[
    ("viewBox", @luna_dom.Attr::AttrString("0 0 16 16")),
    ("width", @luna_dom.Attr::AttrString("16")),
    ("height", @luna_dom.Attr::AttrString("16")),
  ])
}
