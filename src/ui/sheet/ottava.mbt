///|
/// Ottava notation rendering — 8va and 8vb markings

///|
const OTTAVA_TEXT_X_OFFSET = 5.0

///|
const OTTAVA_TICK_LENGTH = 8.0

///|
const OTTAVA_FONT_SIZE = "16"

///|
const OTTAVA_ALTA_TEXT_Y_OFFSET = -55.0

///|
const OTTAVA_ALTA_LINE_Y_OFFSET = -50.0

///|
const OTTAVA_BASSA_TEXT_Y_OFFSET = 100.0

///|
const OTTAVA_BASSA_LINE_Y_OFFSET = 95.0

///|
/// Renders the 8va marking with span-aware label and end tick
fn render_8va_marking(
  measure_x : Double,
  staff_y : Double,
  measure_width : Double,
  role : @sheet_layout.OttavaSpanRole,
) -> Array[@luna_dom.DomNode] {
  let show_label = match role {
    SpanSole | SpanFirst => true
    SpanMiddle | SpanLast => false
  }
  let show_tick = match role {
    SpanSole | SpanLast => true
    SpanFirst | SpanMiddle => false
  }
  let text_x = measure_x + OTTAVA_TEXT_X_OFFSET
  let text_y = staff_y + OTTAVA_ALTA_TEXT_Y_OFFSET
  let line_start_x = if show_label { text_x + 30.0 } else { measure_x }
  let line_end_x = measure_x + measure_width - 5.0
  let line_y = staff_y + OTTAVA_ALTA_LINE_Y_OFFSET
  let label_nodes : Array[@luna_dom.DomNode] = if show_label {
    [
      @luna_dom.svg_text(
        x=text_x.to_string(),
        y=text_y.to_string(),
        text_anchor="start",
        font_size=OTTAVA_FONT_SIZE,
        font_family="serif",
        attrs=[
          ("font-style", @luna_dom.Attr::AttrString("italic")),
          ("stroke", @luna_dom.Attr::AttrString("none")),
        ],
        [@luna_dom.text("8va")],
      ),
    ]
  } else {
    []
  }
  let tick_nodes : Array[@luna_dom.DomNode] = if show_tick {
    [
      @luna_dom.svg_line(
        x1=line_end_x.to_string(),
        y1=line_y.to_string(),
        x2=line_end_x.to_string(),
        y2=(line_y + OTTAVA_TICK_LENGTH).to_string(),
        stroke_width="1",
      ),
    ]
  } else {
    []
  }
  [
    ..label_nodes,
    @luna_dom.svg_line(
      x1=line_start_x.to_string(),
      y1=line_y.to_string(),
      x2=line_end_x.to_string(),
      y2=line_y.to_string(),
      stroke_width="1",
      attrs=[("stroke-dasharray", @luna_dom.Attr::AttrString("6,4"))],
    ),
    ..tick_nodes,
  ]
}

///|
/// Renders the 8vb marking with span-aware label and end tick
fn render_8vb_marking(
  measure_x : Double,
  staff_y : Double,
  measure_width : Double,
  role : @sheet_layout.OttavaSpanRole,
) -> Array[@luna_dom.DomNode] {
  let show_label = match role {
    SpanSole | SpanFirst => true
    SpanMiddle | SpanLast => false
  }
  let show_tick = match role {
    SpanSole | SpanLast => true
    SpanFirst | SpanMiddle => false
  }
  let text_x = measure_x + OTTAVA_TEXT_X_OFFSET
  let text_y = staff_y + OTTAVA_BASSA_TEXT_Y_OFFSET
  let line_start_x = if show_label { text_x + 30.0 } else { measure_x }
  let line_end_x = measure_x + measure_width - 5.0
  let line_y = staff_y + OTTAVA_BASSA_LINE_Y_OFFSET
  let label_nodes : Array[@luna_dom.DomNode] = if show_label {
    [
      @luna_dom.svg_text(
        x=text_x.to_string(),
        y=text_y.to_string(),
        text_anchor="start",
        font_size=OTTAVA_FONT_SIZE,
        font_family="serif",
        attrs=[
          ("font-style", @luna_dom.Attr::AttrString("italic")),
          ("stroke", @luna_dom.Attr::AttrString("none")),
        ],
        [@luna_dom.text("8vb")],
      ),
    ]
  } else {
    []
  }
  let tick_nodes : Array[@luna_dom.DomNode] = if show_tick {
    [
      @luna_dom.svg_line(
        x1=line_end_x.to_string(),
        y1=line_y.to_string(),
        x2=line_end_x.to_string(),
        y2=(line_y - OTTAVA_TICK_LENGTH).to_string(),
        stroke_width="1",
      ),
    ]
  } else {
    []
  }
  [
    ..label_nodes,
    @luna_dom.svg_line(
      x1=line_start_x.to_string(),
      y1=line_y.to_string(),
      x2=line_end_x.to_string(),
      y2=line_y.to_string(),
      stroke_width="1",
      attrs=[("stroke-dasharray", @luna_dom.Attr::AttrString("6,4"))],
    ),
    ..tick_nodes,
  ]
}
