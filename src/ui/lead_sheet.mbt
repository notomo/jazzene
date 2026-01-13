///|
/// Lead Sheet Visualization Component
/// Displays chord symbols, staff notation, and rhythm in SVG format

// Color constants
let color_background = "#111827"

///|
let color_foreground = "#f1f5f9"

///|
let color_muted = "#9ca3af"

// Layout constants

///|
let staff_top = 80.0

///|
let staff_line_spacing = 15.0

///|
let staff_lines = 5

///|
let measures_per_row = 4

///|
let measure_width = 280.0

///|
let measure_start_x = 40.0

///|
let row_height = 250.0

///|
/// Calculate measure position in the layout
fn measure_position(measure_index : Int) -> (Double, Double) {
  let col = measure_index % measures_per_row
  let row = measure_index / measures_per_row
  let x = measure_start_x + col.to_double() * measure_width
  let y = staff_top + row.to_double() * row_height
  (x, y)
}

///|
/// Render staff lines (5 horizontal lines)
fn render_staff_lines(x : Double, y : Double) -> @luna_dom.DomNode {
  let lines = []
  for i = 0; i < staff_lines; {
    let line_y = y + i.to_double() * staff_line_spacing
    lines.push(
      @luna_dom.svg_line(
        x1=x.to_string(),
        y1=line_y.to_string(),
        x2=(x + measure_width).to_string(),
        y2=line_y.to_string(),
        stroke=color_foreground,
        stroke_width="1",
      ),
    )
    continue i + 1
  }
  @luna_dom.svg_g(lines)
}

///|
/// Render treble clef symbol with detailed SVG path
fn render_treble_clef(x : Double, y : Double) -> @luna_dom.DomNode {
  let scale = staff_line_spacing / 32.0
  let cx = x + 10.0
  let cy = y + staff_line_spacing * 2.0 // Middle of staff
  let transform = "scale(" +
    scale.to_string() +
    ") translate(" +
    (cx / scale).to_string() +
    " " +
    (cy / scale).to_string() +
    ")"
  @luna_dom.svg_path(
    d="m 13.033591,-103.221 c -12.1824453,4.01628 -16.7468607,13.509311 -20.665233,21.541876 -3.91837,8.032565 -3.757323,17.160478 -3.420575,23.002343 0.336747,5.841868 1.3616292,10.953499 2.4707101,17.525598 1.1090711,6.572103 23.6492619,125.234983 24.8425289,133.267543 1.193259,8.03257 -0.815347,17.5256 -9.7538365,20.81165 -8.9384975,3.28605 -15.1811592,0.32477 -17.9959425,-1.82558 -4.082403,-3.11875 -4.402656,-4.77963 -1.888938,-5.50986 2.513726,-0.73023 15.0812868,-1.87047 13.41893505,-9.82504 -1.74278895,-8.33947 -8.36199035,-12.04885 -14.20386005,-12.04885 -5.84186,0 -11.235794,4.007462 -11.824651,10.22327 -0.530852,5.603507 0.736519,12.25314 6.142918,17.89071 5.441823,5.67451 17.405725,10.58838 29.4197957,3.65117 12.0140813,-6.93722 10.6734873,-17.5256 9.5012763,-25.19305 -1.172211,-7.66745 -24.5689223,-128.521032 -25.2918365,-134.728014 -0.7229039,-6.20698 2.2199936,-24.827926 6.9106893,-32.130259 4.6906955,-7.302331 10.4767412,-14.604662 13.3766342,-14.969779 2.899883,-0.365117 2.963023,0.730233 3.840581,3.286049 0.877567,2.555816 5.005486,17.160481 -5.21138,29.939559 -10.2168646,12.779081 -47.460595,50.7512041 -52.50269,64.6256341 -5.042085,13.8744299 -2.641838,36.5116599 8.535849,46.7349199 11.177687,10.22326 29.9421394,17.860204 44.227597,13.50931 14.1314,-4.303973 30.003621,-17.89071 25.883028,-38.70235 -3.976277,-20.0827599 -15.129906,-28.11397986 -31.9252763,-28.11397986 -16.795358,0 -24.2596577,9.85814996 -26.2682627,19.35117986 -2.008605,9.49303 -0.311267,18.555845 7.034207,27.01863 3.274171,3.772202 5.1354401,3.460725 5.43742,2.365375 0.3019699,-1.09535 -7.838587,-6.016545 -6.342429,-18.065395 1.496159,-12.04884 10.0063966,-16.43024 20.5737297,-16.79536 10.5673323,-0.36512 18.0096633,8.39768 20.2561873,15.70001 2.246516,7.30234 4.969787,29.20933 -13.742676,33.95584 -18.7124492,4.74652 -43.034337,-5.47674 -46.249,-29.57444 -3.214664,-24.0976899 10.393475,-35.0511899 19.037321,-43.4488699 8.6438339,-8.3976801 31.409723,-31.3245111 34.905703,-40.5279391 4.438135,-11.68373 3.343706,-30.669792 1.118238,-37.607007 -2.225467,-6.937215 -6.339665,-14.969784 -9.646762,-15.334894 z",
    fill=color_foreground,
    stroke=color_foreground,
    stroke_width="0",
    attrs=[("transform", @luna_dom.Attr::AttrString(transform))],
  )
}

///|
/// Render bar line
fn render_bar_line(x : Double, y : Double) -> @luna_dom.DomNode {
  @luna_dom.svg_line(
    x1=x.to_string(),
    y1=y.to_string(),
    x2=x.to_string(),
    y2=(y + staff_line_spacing * 4.0).to_string(),
    stroke=color_foreground,
    stroke_width="2",
  )
}

///|
/// Calculate diatonic steps from E4 (bottom line of treble clef)
fn midi_to_diatonic_step(midi : Int) -> Int {
  let pitch_class = midi % 12
  let octave = midi / 12 - 1

  // E4 = pitch_class 4, octave 4
  let e4_pitch_class = 4
  let e4_octave = 4
  let pitch_class_to_diatonic_step = fn(pc : Int) -> Int {
    match pc {
      0 | 1 => 0 // C, C#
      2 | 3 => 1 // D, D#
      4 => 2 // E
      5 | 6 => 3 // F, F#
      7 | 8 => 4 // G, G#
      9 | 10 => 5 // A, A#
      11 => 6 // B
      _ => 0
    }
  }
  let note_diatonic_step = pitch_class_to_diatonic_step(pitch_class)
  let e4_diatonic_step = pitch_class_to_diatonic_step(e4_pitch_class)
  (octave - e4_octave) * 7 + (note_diatonic_step - e4_diatonic_step)
}

///|
/// Render ledger lines for notes outside the staff
fn render_ledger_lines(
  midi : Int,
  note_x : Double,
  staff_y : Double,
) -> Array[@luna_dom.DomNode] {
  let step = midi_to_diatonic_step(midi)
  let lines = []

  // Ledger line length (slightly longer than note head)
  let line_half_width = 15.0

  // Below staff (step < 0, even steps only)
  if step < 0 {
    let end_step = if step % 2 == 0 { step } else { step - 1 }
    let mut current_step = -2 // First ledger line below staff
    while current_step >= end_step {
      let line_y = staff_y +
        staff_line_spacing * 4.0 -
        current_step.to_double() * (staff_line_spacing / 2.0)
      lines.push(
        @luna_dom.svg_line(
          x1=(note_x - line_half_width).to_string(),
          y1=line_y.to_string(),
          x2=(note_x + line_half_width).to_string(),
          y2=line_y.to_string(),
          stroke=color_foreground,
          stroke_width="1",
        ),
      )
      current_step = current_step - 2
    }
  }

  // Above staff (step > 8, even steps only)
  if step > 8 {
    let end_step = if step % 2 == 0 { step } else { step - 1 }
    let mut current_step = 10 // First ledger line above F5
    while current_step <= end_step {
      let line_y = staff_y +
        staff_line_spacing * 4.0 -
        current_step.to_double() * (staff_line_spacing / 2.0)
      lines.push(
        @luna_dom.svg_line(
          x1=(note_x - line_half_width).to_string(),
          y1=line_y.to_string(),
          x2=(note_x + line_half_width).to_string(),
          y2=line_y.to_string(),
          stroke=color_foreground,
          stroke_width="1",
        ),
      )
      current_step = current_step + 2
    }
  }
  lines
}

///|
/// Render a single measure with all its elements
fn render_measure(
  measure : @music.Measure,
  display_index : Int,
  current_measure_index : () -> Int,
) -> @luna_dom.DomNode {
  let (x, y) = measure_position(display_index)
  let children : Array[@luna_dom.DomNode] = []

  // Staff lines
  children.push(render_staff_lines(x, y))

  // Treble clef (only on first measure of each row)
  if display_index % measures_per_row == 0 {
    children.push(render_treble_clef(x, y))
  }

  // Chord symbol (dynamic based on current_measure_index)
  // Don't show chord for leading rest measure (measure_index = 0)
  if measure.measure_index > 0 {
    // Calculate chord y position relative to staff
    let chord_y_rect = y - 66.0 // Background rectangle y position
    let chord_y_text = y - 40.0 // Text y position

    // Background rectangle for highlighted chord (white background for better contrast)
    children.push(
      @luna_dom.svg_rect(
        x=(x + 5.0).to_string(),
        y=chord_y_rect.to_string(),
        rx="6",
        ry="6",
        dyn_attrs=[
          (
            "width",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                let chord_text = @music.format_chord(measure.chord)
                let estimated_width = chord_text.length().to_double() * 18.0 +
                  20.0
                estimated_width.to_int().to_string()
              } else {
                "0"
              }
            }),
          ),
          (
            "height",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                "32"
              } else {
                "0"
              }
            }),
          ),
          (
            "fill",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                "#ffffff"
              } else {
                "transparent"
              }
            }),
          ),
          (
            "opacity",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                "0.95"
              } else {
                "0"
              }
            }),
          ),
        ],
      ),
    )

    // Chord text
    children.push(
      @luna_dom.svg_text(
        x=(x + 10.0).to_string(),
        y=chord_y_text.to_string(),
        text_anchor="start",
        font_size="26",
        font_family="serif",
        dyn_attrs=[
          (
            "fill",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                "#1e3a8a" // Dark blue for strong contrast on white background
              } else {
                color_foreground
              }
            }),
          ),
          (
            "font-weight",
            @luna_dom.AttrValue::Dynamic(fn() {
              if measure.measure_index == current_measure_index() {
                "bold"
              } else {
                "normal"
              }
            }),
          ),
        ],
        [@luna_dom.text(@music.format_chord(measure.chord))],
      ),
    )
  }

  // Notes (dynamic coloring based on current_measure_index)
  for note in measure.notes {
    let note_x = x + 60.0 + note.start_beat * (measure_width - 80.0) / 4.0
    match note.midi {
      Some(midi) => {
        // Render note
        let note_y = @music.midi_to_staff_y(midi, y)

        // Ledger lines (for notes outside the staff)
        let ledger_lines = render_ledger_lines(midi, note_x, y)
        for line in ledger_lines {
          children.push(line)
        }

        // Note head
        children.push(
          match note.duration {
            Eighth | DottedEighth | Quarter | DottedQuarter => {
              // Filled note head - rotated ellipse for more realistic appearance
              let rx = staff_line_spacing * 0.37894733 * 1.9
              let ry = staff_line_spacing * 0.2542448 * 1.9
              @luna_dom.svg_ellipse(
                cx=note_x.to_string(),
                cy=note_y.to_string(),
                rx=rx.to_string(),
                ry=ry.to_string(),
                fill=color_foreground,
                stroke="none",
                attrs=[
                  (
                    "transform",
                    @luna_dom.Attr::AttrString(
                      "rotate(-25, " +
                      note_x.to_string() +
                      ", " +
                      note_y.to_string() +
                      ")",
                    ),
                  ),
                ],
              )
            }
            Half | DottedHalf => {
              // Hollow note head - hollow ellipse path for more realistic appearance
              let scale = staff_line_spacing / 50.0
              let transform_str = "scale(" +
                scale.to_string() +
                ") translate(" +
                (note_x / scale).to_string() +
                " " +
                (note_y / scale).to_string() +
                ")"
              @luna_dom.svg_path(
                d="m 11.9799,-28.044092 a 25.42448,37.894733 65 0 0 -22.724708,5.001244 25.42448,37.894733 65 0 0 -23.599593,39.057558 25.42448,37.894733 65 0 0 45.089241,7.02748 25.42448,37.894733 65 0 0 23.59959,-39.05756 25.42448,37.894733 65 0 0 -22.36453,-12.028722 z m -11.9801455354,5.461682 a 16.280342,22.582411 0 0 1 16.2806555354,22.58208337714 16.280342,22.582411 0 0 1 -16.2806555354,22.58259662286 16.280342,22.582411 0 0 1 -16.2801434646,-22.58259662286 16.280342,22.582411 0 0 1 16.2801434646,-22.58208337714 z",
                fill=color_foreground,
                stroke="none",
                attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
              )
            }
          },
        )

        // Stem and flag
        let stem_height = staff_line_spacing * 3.0 // 3 staff spaces
        let stem_up = midi < 71
        match note.duration {
          Eighth | DottedEighth | Quarter | DottedQuarter => {
            // Calculate stem attachment point on rotated ellipse
            // Ellipse is rotated -25 degrees
            let rx = staff_line_spacing * 0.37894733 * 1.9
            let cos_25 = 0.906308
            let sin_25 = 0.422618
            let (stem_x_offset, stem_y_offset) = if stem_up {
              // Attach to right side of ellipse (0 degrees before rotation)
              (rx * cos_25, -(rx * sin_25))
            } else {
              // Attach to left side of ellipse (180 degrees before rotation)
              (-(rx * cos_25), rx * sin_25)
            }
            let stem_x = note_x + stem_x_offset
            let y1 = note_y + stem_y_offset
            let y2 = if stem_up { y1 - stem_height } else { y1 + stem_height }
            children.push(
              @luna_dom.svg_line(
                x1=stem_x.to_string(),
                y1=y1.to_string(),
                x2=stem_x.to_string(),
                y2=y2.to_string(),
                stroke=color_foreground,
                stroke_width="1.5",
              ),
            )

            // Flag for eighth notes
            match note.duration {
              Eighth | DottedEighth => {
                let scale = staff_line_spacing / 32.0
                let flag_transform = if stem_up {
                  "scale(" +
                  scale.to_string() +
                  ") translate(" +
                  (stem_x / scale).to_string() +
                  " " +
                  (y2 / scale).to_string() +
                  ")"
                } else {
                  "scale(" +
                  scale.to_string() +
                  " " +
                  (-scale).to_string() +
                  ") translate(" +
                  (stem_x / scale).to_string() +
                  " " +
                  (-y2 / scale).to_string() +
                  ")"
                }
                children.push(
                  @luna_dom.svg_path(
                    d="m 0.1322915,0.20079656 v 29.17519544 c 0,0 0.94525,1.04738 2.86031,2.860314 2.96256,2.804577 11.7267205,11.463111 16.3037905,16.875851 4.32124,5.11019 8.60276,12.11629 9.13525,19.19871 0.53655,7.13637 -1.14271,16.58785 -4.70907,26.52439 -1.9313,5.380953 -3.62376,8.222963 -3.06452,8.587383 0.79714,0.51945 2.7385,-2.97941 6.4668,-10.625733 6.32003,-12.96167 7.43952,-25.40692 6.55264,-34.62269 -1.15046,-11.95469 -2.28519,-23.402003 -9.94627,-35.007151 -6.79549,-10.293932 -14.7193405,-17.7092604 -19.5333005,-20.7143534 -2.59687,-1.62108305 -4.06563,-2.25191604 -4.06563,-2.25191604 z",
                    fill=color_foreground,
                    stroke="none",
                    attrs=[
                      ("transform", @luna_dom.Attr::AttrString(flag_transform)),
                    ],
                  ),
                )
              }
              _ => ()
            }
          }
          Half | DottedHalf => ()
        }

        // Dot for dotted notes
        match note.duration {
          DottedEighth | DottedQuarter | DottedHalf => {
            let dot_radius = staff_line_spacing * 0.15
            let dot_x = note_x + staff_line_spacing * 1.5
            let dot_y = note_y
            children.push(
              @luna_dom.svg_circle(
                cx=dot_x.to_string(),
                cy=dot_y.to_string(),
                r=dot_radius.to_string(),
                fill=color_foreground,
              ),
            )
          }
          _ => ()
        }
      }
      None => {
        // Render rest
        let rest_y = y + staff_line_spacing * 2.0
        children.push(
          match note.duration {
            Quarter | DottedQuarter => {
              // Quarter rest with detailed SVG path
              let scale = staff_line_spacing / 40.0
              let transform_str = "scale(" +
                scale.to_string() +
                ") translate(" +
                (note_x / scale).to_string() +
                " " +
                (rest_y / scale).to_string() +
                ")"
              @luna_dom.svg_path(
                d="m -16.211221,-70.215638 c -1.61619,1.614428 -1.011,3.125643 1.00395,5.644331 2.01495,2.51869 16.8752195,21.912602 17.1270895,23.675682 0.25187,1.76308 -14.3565295,36.0172608 -14.1046595,39.0396808 0.25187,3.02243 23.641819,32.2836802 23.641819,32.2836802 0,0 -6.1681595,-5.06483 -13.8442995,-6.74396 -5.74739,-1.25721 -11.6310095,0.39343 -16.1196095,6.29672 -4.90857,6.45564 -6.47301,15.64047 -2.24145,23.57473 3.66088,6.86424 13.6009195,15.37074 18.8901695,15.364 4.18228,-0.005 4.28177,-1.00747 3.52616,-2.26682 -0.75560996,-1.25934 -19.3229595,-17.78691 -7.05233,-26.94997 10.05045,-7.50515 20.7031805,-1.07037 22.4662605,0.44084 1.76308,1.51121 3.5431,3.29123 5.80992,1.52815 2.26682,-1.76308 3.50923,-2.03189 -0.0169,-5.80992 -3.52617,-3.77803 -10.88029,-13.53803 -13.3989805,-20.59036 -2.51869,-7.0523302 -3.02243,-9.3191502 -0.75561,-14.6084002 2.2668195,-5.28925 13.0971905,-29.7205298 12.3415805,-32.4910898 -0.75561,-2.770561 -32.73768,-36.767581 -33.74515,-37.775056 -1.00748,-1.007475 -1.91526,-2.020238 -3.52793,-0.612238 z",
                fill=color_foreground,
                stroke="none",
                attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
              )
            }
            Half | DottedHalf => {
              // Half rest - simple rectangle (same as reference)
              let rest_width = staff_line_spacing * 2.0
              let rest_height = staff_line_spacing / 2.0
              @luna_dom.svg_rect(
                x=(note_x - rest_width / 2.0).to_string(),
                y=(rest_y - rest_height / 2.0).to_string(),
                width=rest_width.to_string(),
                height=rest_height.to_string(),
                fill=color_foreground,
              )
            }
            Eighth | DottedEighth => {
              // Eighth rest with detailed SVG path
              let scale = staff_line_spacing / 40.0
              let transform_str = "scale(" +
                scale.to_string() +
                ") translate(" +
                (note_x / scale).to_string() +
                " " +
                (rest_y / scale).to_string() +
                ")"
              @luna_dom.svg_path(
                d="m 3.8445495,48.209315 c 2.61469,0.79432 4.67175,-1.61714 5.57016,-4.31238 0.8984105,-2.69524 16.7104905,-69.5372 17.2495405,-71.33403 0.53905,-1.79682 -0.35937,-4.49206 -1.79683,-4.67175 -1.43746,-0.17968 -3.23429,1.0781 -3.77334,3.59366 -0.53904,2.51555 -1.71153,6.15488 -2.78963,7.41266 -1.07809,1.25778 -6.91323,6.78227 -10.8662505,8.21973 -3.95302,1.43746 -10.84962,2.9872902 -11.32001,1.61714 -0.32006,-0.93228 1.72138,-1.27833 3.59365996,-3.59365 1.20101,-1.48521 2.33587004,-5.57016 1.79682004,-7.90604 -0.53905004,-2.33587 -2.69524,-7.90603 -7.366989,-9.70286 -4.6717485,-1.79683 -10.6012775,-0.53905 -13.8355655,4.1327 -3.234288,4.67175 -3.234288,11.49969 0.179684,15.27303 3.413969,3.7733302 9.343498,7.7263502 17.9682705,6.6482602 8.62476,-1.0781 14.3746105,-4.1327102 15.8120705,-5.2108002 1.43746,-1.0781 3.05461,-2.51556 3.05461,-2.51556 0,0 -15.6962205,54.82677 -16.59463054,57.16265 -0.89841,2.33587 0.60287004,4.53233 3.11843004,5.18724 z",
                fill=color_foreground,
                stroke="none",
                attrs=[("transform", @luna_dom.Attr::AttrString(transform_str))],
              )
            }
          },
        )

        // Dot for dotted rests
        match note.duration {
          DottedEighth | DottedQuarter | DottedHalf => {
            let dot_radius = staff_line_spacing * 0.15
            let dot_x = note_x + staff_line_spacing * 1.5
            let dot_y = rest_y
            children.push(
              @luna_dom.svg_circle(
                cx=dot_x.to_string(),
                cy=dot_y.to_string(),
                r=dot_radius.to_string(),
                fill=color_foreground,
              ),
            )
          }
          _ => ()
        }
      }
    }
  }

  // Bar line
  children.push(render_bar_line(x + measure_width, y))
  @luna_dom.svg_g(children)
}

///|
/// Main lead sheet component
pub fn lead_sheet(
  measures : () -> Array[@music.Measure],
  playback_position : @signal.Signal[@music.Duration],
  bpm : @signal.Signal[Int],
) -> @luna_dom.DomNode {
  // Calculate current measure index
  let current_measure_index = @signal.memo(fn() {
    let pos = playback_position.get().to_milliseconds()
    let measure_duration_ms = 60000.0 * 4.0 / bpm.get().to_double()
    if measure_duration_ms > 0.0 {
      // Leading rest is measure 0, chord measures start at 1
      let measure_idx = (pos / measure_duration_ms).to_int()
      // For measure 0 (leading rest), return -1 to not highlight any chord
      // For measures >= 1, return the measure index
      if measure_idx == 0 {
        -1 // Still in leading rest, no chord to highlight
      } else {
        measure_idx
      }
    } else {
      0
    }
  })

  // Calculate SVG height based on number of rows
  let svg_height = @signal.memo(fn() {
    let measure_count = measures().length()
    if measure_count == 0 {
      return "400"
    }
    let rows = (measure_count + measures_per_row - 1) / measures_per_row
    let height = staff_top + rows.to_double() * row_height + 50.0
    height.to_int().to_string()
  })

  // Return container with SVG
  @luna_dom.div(class="w-full h-full overflow-auto bg-gray-900 p-4", [
    @luna_dom.svg(viewBox="0 0 1200 " + svg_height(), width="100%", [
      // Dark background for the sheet
      @luna_dom.svg_rect(
        x="0",
        y="0",
        width="1200",
        height=svg_height(),
        fill=color_background,
      ),
      // Empty state message
      @luna_dom.show(fn() { measures().length() == 0 }, fn() {
        @luna_dom.svg_text(
          x="600",
          y="200",
          text_anchor="middle",
          font_size="20",
          fill=color_muted,
          [@luna_dom.text("Enter a chord progression to see the lead sheet")],
        )
      }),
      // Measures using for_each (reactive!)
      @luna_dom.for_each(measures, fn(measure, idx) {
        render_measure(measure, idx, current_measure_index)
      }),
    ]),
  ])
}
