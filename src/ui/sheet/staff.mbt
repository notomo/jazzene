///|
/// Staff notation rendering functions (staff lines, treble clef, bar lines, ledger lines)

///|
let treble_clef_scale_divisor = 32.0

///|
let treble_clef_x_offset = 10.0

///|
let ledger_line_half_width = 15.0

///|
let first_ledger_line_below_step = -2

///|
let upper_ledger_line_threshold = 8

///|
let first_ledger_line_above_step = 10

///|
/// Render a single staff line
fn render_staff_line(
  x : Double,
  y : Double,
  width : Double,
  index : Int,
) -> @luna_dom.DomNode {
  let line_y = y + index.to_double() * staff_line_spacing
  @luna_dom.svg_line(
    x1=x.to_string(),
    y1=line_y.to_string(),
    x2=(x + width).to_string(),
    y2=line_y.to_string(),
    stroke=color_foreground,
    stroke_width="1",
  )
}

///|
/// Render staff lines (5 horizontal lines)
fn render_staff_lines(
  x : Double,
  y : Double,
  width? : Double = measure_width,
) -> @luna_dom.DomNode {
  let lines = Array::makei(staff_lines, fn(i) {
    render_staff_line(x, y, width, i)
  })
  @luna_dom.svg_g(lines)
}

///|
/// Render treble clef symbol with detailed SVG path
fn render_treble_clef(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / treble_clef_scale_divisor
  let cx = x + treble_clef_x_offset
  let cy = y + staff_line_spacing * 2.0 // Middle of staff
  @luna_dom.svg_path(
    d="m 13.033591,-103.221 c -12.1824453,4.01628 -16.7468607,13.509311 -20.665233,21.541876 -3.91837,8.032565 -3.757323,17.160478 -3.420575,23.002343 0.336747,5.841868 1.3616292,10.953499 2.4707101,17.525598 1.1090711,6.572103 23.6492619,125.234983 24.8425289,133.267543 1.193259,8.03257 -0.815347,17.5256 -9.7538365,20.81165 -8.9384975,3.28605 -15.1811592,0.32477 -17.9959425,-1.82558 -4.082403,-3.11875 -4.402656,-4.77963 -1.888938,-5.50986 2.513726,-0.73023 15.0812868,-1.87047 13.41893505,-9.82504 -1.74278895,-8.33947 -8.36199035,-12.04885 -14.20386005,-12.04885 -5.84186,0 -11.235794,4.007462 -11.824651,10.22327 -0.530852,5.603507 0.736519,12.25314 6.142918,17.89071 5.441823,5.67451 17.405725,10.58838 29.4197957,3.65117 12.0140813,-6.93722 10.6734873,-17.5256 9.5012763,-25.19305 -1.172211,-7.66745 -24.5689223,-128.521032 -25.2918365,-134.728014 -0.7229039,-6.20698 2.2199936,-24.827926 6.9106893,-32.130259 4.6906955,-7.302331 10.4767412,-14.604662 13.3766342,-14.969779 2.899883,-0.365117 2.963023,0.730233 3.840581,3.286049 0.877567,2.555816 5.005486,17.160481 -5.21138,29.939559 -10.2168646,12.779081 -47.460595,50.7512041 -52.50269,64.6256341 -5.042085,13.8744299 -2.641838,36.5116599 8.535849,46.7349199 11.177687,10.22326 29.9421394,17.860204 44.227597,13.50931 14.1314,-4.303973 30.003621,-17.89071 25.883028,-38.70235 -3.976277,-20.0827599 -15.129906,-28.11397986 -31.9252763,-28.11397986 -16.795358,0 -24.2596577,9.85814996 -26.2682627,19.35117986 -2.008605,9.49303 -0.311267,18.555845 7.034207,27.01863 3.274171,3.772202 5.1354401,3.460725 5.43742,2.365375 0.3019699,-1.09535 -7.838587,-6.016545 -6.342429,-18.065395 1.496159,-12.04884 10.0063966,-16.43024 20.5737297,-16.79536 10.5673323,-0.36512 18.0096633,8.39768 20.2561873,15.70001 2.246516,7.30234 4.969787,29.20933 -13.742676,33.95584 -18.7124492,4.74652 -43.034337,-5.47674 -46.249,-29.57444 -3.214664,-24.0976899 10.393475,-35.0511899 19.037321,-43.4488699 8.6438339,-8.3976801 31.409723,-31.3245111 34.905703,-40.5279391 4.438135,-11.68373 3.343706,-30.669792 1.118238,-37.607007 -2.225467,-6.937215 -6.339665,-14.969784 -9.646762,-15.334894 z",
    fill=color_foreground,
    stroke=color_foreground,
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
    y2=(y + staff_line_spacing * (staff_lines - 1).to_double()).to_string(),
    stroke=color_foreground,
    stroke_width="2",
  )
}

///|
/// Calculate diatonic steps from E4 (bottom line of treble clef)
fn midi_to_diatonic_step(midi : Int) -> Int {
  let pitch_class = midi % 12
  let octave = midi / 12 - 1
  let e4_pitch_class = 4
  let e4_octave = 4
  let note_diatonic_step = pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = pitch_class_to_diatonic_step(e4_pitch_class)
  (octave - e4_octave) * 7 + (note_diatonic_step - e4_diatonic_step)
}

///|
/// Render a single ledger line
fn render_ledger_line(
  note_x : Double,
  staff_y : Double,
  step : Int,
) -> @luna_dom.DomNode {
  let line_y = staff_y +
    staff_line_spacing * (staff_lines - 1).to_double() -
    step.to_double() * (staff_line_spacing / 2.0)
  @luna_dom.svg_line(
    x1=(note_x - ledger_line_half_width).to_string(),
    y1=line_y.to_string(),
    x2=(note_x + ledger_line_half_width).to_string(),
    y2=line_y.to_string(),
    stroke=color_foreground,
    stroke_width="1",
  )
}

///|
/// Generate ledger line steps for notes below the staff
fn ledger_steps_below(step : Int) -> Array[Int] {
  if step >= 0 {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (first_ledger_line_below_step - end_step) / 2 + 1
  Array::makei(count, fn(i) { first_ledger_line_below_step - i * 2 })
}

///|
/// Generate ledger line steps for notes above the staff
fn ledger_steps_above(step : Int) -> Array[Int] {
  if step <= upper_ledger_line_threshold {
    return []
  }
  let end_step = if step % 2 == 0 { step } else { step - 1 }
  let count = (end_step - first_ledger_line_above_step) / 2 + 1
  Array::makei(count, fn(i) { first_ledger_line_above_step + i * 2 })
}

///|
/// Render ledger lines for notes outside the staff
fn render_ledger_lines(
  midi : Int,
  note_x : Double,
  staff_y : Double,
) -> Array[@luna_dom.DomNode] {
  let step = midi_to_diatonic_step(midi)
  let below = ledger_steps_below(step)
  let above = ledger_steps_above(step)
  below
  .iter()
  .concat(above.iter())
  .map(fn(s) { render_ledger_line(note_x, staff_y, s) })
  .collect()
}
