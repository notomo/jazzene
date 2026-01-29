///|
const DOT_RADIUS_RATIO = 0.15

///|
const DOT_X_OFFSET_RATIO = 1.5

///|
/// Render duration dot for dotted notes and rests
fn render_duration_dot(
  duration : @music.NoteDuration,
  x : Double,
  y : Double,
) -> @luna_dom.DomNode? {
  match duration {
    DottedEighth | DottedQuarter | DottedHalf => {
      let dot_radius = STAFF_LINE_SPACING * DOT_RADIUS_RATIO
      let dot_x = x + STAFF_LINE_SPACING * DOT_X_OFFSET_RATIO
      Some(
        @luna_dom.svg_circle(
          cx=dot_x.to_string(),
          cy=y.to_string(),
          r=dot_radius.to_string(),
          fill=COLOR_FOREGROUND,
        ),
      )
    }
    _ => None
  }
}
