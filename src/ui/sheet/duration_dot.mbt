///|
const DOT_RADIUS_RATIO = 0.15

///|
const DOT_X_OFFSET_RATIO = 1.5

///|
/// Render duration dot for dotted notes and rests.
/// When on_line is true, the dot is shifted up to the space above
/// so it does not overlap with the staff line.
fn render_duration_dot(
  duration : @music.NoteDuration,
  x : Double,
  y : Double,
  on_line? : Bool = false,
) -> @luna_dom.DomNode? {
  match duration {
    DottedEighth | DottedQuarter | DottedHalf => {
      let dot_radius = @music.STAFF_LINE_SPACING * DOT_RADIUS_RATIO
      let dot_x = x + @music.STAFF_LINE_SPACING * DOT_X_OFFSET_RATIO
      let dot_y = if on_line { y - @music.STAFF_LINE_SPACING / 2.0 } else { y }
      Some(
        @luna_dom.svg_circle(
          cx=dot_x.to_string(),
          cy=dot_y.to_string(),
          r=dot_radius.to_string(),
          stroke="none",
        ),
      )
    }
    _ => None
  }
}
