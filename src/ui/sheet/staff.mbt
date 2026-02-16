///|
/// Staff notation rendering functions (staff lines, treble clef, bar lines, ledger lines)

///|
const TREBLE_CLEF_SCALE_DIVISOR = 32.0

///|
const TREBLE_CLEF_X_OFFSET = 10.0

///|
const LEDGER_LINE_HALF_WIDTH = 15.0

///|
/// Render a single staff line
fn render_staff_line(
  x : Double,
  y : Double,
  width : Double,
  index : Int,
) -> @luna_dom.DomNode {
  let line_y = y + index.to_double() * @sheet_layout.STAFF_LINE_SPACING
  @luna_dom.svg_line(
    x1=x.to_string(),
    y1=line_y.to_string(),
    x2=(x + width).to_string(),
    y2=line_y.to_string(),
    stroke_width="1",
  )
}

///|
/// Render staff lines (5 horizontal lines)
fn render_staff_lines(
  x : Double,
  y : Double,
  width? : Double = @sheet_layout.MEASURE_WIDTH,
) -> @luna_dom.DomNode {
  @luna_dom.svg_g(
    Array::makei(@sheet_layout.STAFF_LINES, fn(i) {
      render_staff_line(x, y, width, i)
    }),
  )
}

///|
/// Render treble clef symbol with detailed SVG path
fn render_treble_clef(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = @sheet_layout.STAFF_LINE_SPACING / TREBLE_CLEF_SCALE_DIVISOR
  let cx = x + TREBLE_CLEF_X_OFFSET
  let cy = y + @sheet_layout.STAFF_LINE_SPACING * 2.0
  @luna_dom.svg_path(
    d="m 13.033591,-103.221 c -12.1824453,4.01628 -16.7468607,13.509311 -20.665233,21.541876 -3.91837,8.032565 -3.757323,17.160478 -3.420575,23.002343 0.336747,5.841868 1.3616292,10.953499 2.4707101,17.525598 1.1090711,6.572103 23.6492619,125.234983 24.8425289,133.267543 1.193259,8.03257 -0.815347,17.5256 -9.7538365,20.81165 -8.9384975,3.28605 -15.1811592,0.32477 -17.9959425,-1.82558 -4.082403,-3.11875 -4.402656,-4.77963 -1.888938,-5.50986 2.513726,-0.73023 15.0812868,-1.87047 13.41893505,-9.82504 -1.74278895,-8.33947 -8.36199035,-12.04885 -14.20386005,-12.04885 -5.84186,0 -11.235794,4.007462 -11.824651,10.22327 -0.530852,5.603507 0.736519,12.25314 6.142918,17.89071 5.441823,5.67451 17.405725,10.58838 29.4197957,3.65117 12.0140813,-6.93722 10.6734873,-17.5256 9.5012763,-25.19305 -1.172211,-7.66745 -24.5689223,-128.521032 -25.2918365,-134.728014 -0.7229039,-6.20698 2.2199936,-24.827926 6.9106893,-32.130259 4.6906955,-7.302331 10.4767412,-14.604662 13.3766342,-14.969779 2.899883,-0.365117 2.963023,0.730233 3.840581,3.286049 0.877567,2.555816 5.005486,17.160481 -5.21138,29.939559 -10.2168646,12.779081 -47.460595,50.7512041 -52.50269,64.6256341 -5.042085,13.8744299 -2.641838,36.5116599 8.535849,46.7349199 11.177687,10.22326 29.9421394,17.860204 44.227597,13.50931 14.1314,-4.303973 30.003621,-17.89071 25.883028,-38.70235 -3.976277,-20.0827599 -15.129906,-28.11397986 -31.9252763,-28.11397986 -16.795358,0 -24.2596577,9.85814996 -26.2682627,19.35117986 -2.008605,9.49303 -0.311267,18.555845 7.034207,27.01863 3.274171,3.772202 5.1354401,3.460725 5.43742,2.365375 0.3019699,-1.09535 -7.838587,-6.016545 -6.342429,-18.065395 1.496159,-12.04884 10.0063966,-16.43024 20.5737297,-16.79536 10.5673323,-0.36512 18.0096633,8.39768 20.2561873,15.70001 2.246516,7.30234 4.969787,29.20933 -13.742676,33.95584 -18.7124492,4.74652 -43.034337,-5.47674 -46.249,-29.57444 -3.214664,-24.0976899 10.393475,-35.0511899 19.037321,-43.4488699 8.6438339,-8.3976801 31.409723,-31.3245111 34.905703,-40.5279391 4.438135,-11.68373 3.343706,-30.669792 1.118238,-37.607007 -2.225467,-6.937215 -6.339665,-14.969784 -9.646762,-15.334894 z",
    stroke_width="0",
    attrs=[("transform", scale_translate(scale, cx, cy))],
  )
}

///|
/// Render bar line
fn render_bar_line(x : Double, y : Double) -> @luna_dom.DomNode {
  @luna_dom.svg_line(
    x1=x.to_string(),
    y1=y.to_string(),
    x2=x.to_string(),
    y2=(y +
    @sheet_layout.STAFF_LINE_SPACING *
    (@sheet_layout.STAFF_LINES - 1).to_double()).to_string(),
    stroke_width="2",
  )
}

///|
/// Render a single ledger line
fn render_ledger_line(
  note_x : Double,
  staff_y : Double,
  step : Int,
) -> @luna_dom.DomNode {
  let line_y = staff_y +
    @sheet_layout.STAFF_LINE_SPACING *
    (@sheet_layout.STAFF_LINES - 1).to_double() -
    step.to_double() * (@sheet_layout.STAFF_LINE_SPACING / 2.0)
  @luna_dom.svg_line(
    x1=(note_x - LEDGER_LINE_HALF_WIDTH).to_string(),
    y1=line_y.to_string(),
    x2=(note_x + LEDGER_LINE_HALF_WIDTH).to_string(),
    y2=line_y.to_string(),
    stroke_width="1",
  )
}

///|
/// Render ledger lines from pre-computed SheetNote data
fn render_ledger_lines_from_sheet(
  note : @sheet_layout.SheetNote,
) -> Array[@luna_dom.DomNode] {
  guard note.midi is Some(_) else { return [] }
  // Recover staff_y from note_y and diatonic_step:
  // note_y = staff_y + STAFF_LINE_SPACING * (STAFF_LINES - 1) - step * (STAFF_LINE_SPACING / 2)
  // staff_y = note_y - STAFF_LINE_SPACING * (STAFF_LINES - 1) + step * (STAFF_LINE_SPACING / 2)
  let staff_y = note.y -
    @sheet_layout.STAFF_LINE_SPACING *
    (@sheet_layout.STAFF_LINES - 1).to_double() +
    note.diatonic_step.to_double() * (@sheet_layout.STAFF_LINE_SPACING / 2.0)
  let step = note.diatonic_step
  [
    ..@sheet_layout.ledger_steps_above(step),
    ..@sheet_layout.ledger_steps_below(step),
  ].map(fn(s) { render_ledger_line(note.x, staff_y, s) })
}
