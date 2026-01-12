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
/// Render treble clef symbol
fn render_treble_clef(x : Double, y : Double) -> @luna_dom.DomNode {
  @luna_dom.svg_text(
    x=(x + 10.0).to_string(),
    y=(y + staff_line_spacing * 3.0).to_string(),
    font_size="48",
    font_family="serif",
    fill=color_foreground,
    [@luna_dom.text("𝄞")],
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
  let line_half_width = 8.0

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
  current_measure_index : () -> Int,
) -> @luna_dom.DomNode {
  let (x, y) = measure_position(measure.measure_index)
  let children : Array[@luna_dom.DomNode] = []

  // Staff lines
  children.push(render_staff_lines(x, y))

  // Treble clef (only on first measure of each row)
  if measure.measure_index % measures_per_row == 0 {
    children.push(render_treble_clef(x, y))
  }

  // Chord symbol (dynamic based on current_measure_index)
  // Background rectangle for highlighted chord (white background for better contrast)
  children.push(
    @luna_dom.svg_rect(x=(x + 5.0).to_string(), y="14", rx="6", ry="6", dyn_attrs=[
      (
        "width",
        @luna_dom.AttrValue::Dynamic(fn() {
          if measure.measure_index == current_measure_index() {
            let chord_text = @music.format_chord(measure.chord)
            let estimated_width = chord_text.length().to_double() * 18.0 + 20.0
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
    ]),
  )

  // Chord text
  children.push(
    @luna_dom.svg_text(
      x=(x + 10.0).to_string(),
      y="40",
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
            Eighth | Quarter =>
              @luna_dom.svg_circle(
                cx=note_x.to_string(),
                cy=note_y.to_string(),
                r="5",
                fill=color_foreground,
                stroke="none",
              )
            Half =>
              @luna_dom.svg_circle(
                cx=note_x.to_string(),
                cy=note_y.to_string(),
                r="5",
                fill="none",
                stroke=color_foreground,
                stroke_width="1.5",
              )
          },
        )

        // Stem and flag
        let stem_height = 30.0
        let stem_up = midi < 71
        match note.duration {
          Eighth | Quarter => {
            let stem_x = if stem_up { note_x + 4.0 } else { note_x - 4.0 }
            let y1 = note_y
            let y2 = if stem_up {
              note_y - stem_height
            } else {
              note_y + stem_height
            }
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
              Eighth => {
                let flag_d = if stem_up {
                  "M " +
                  stem_x.to_string() +
                  " " +
                  y2.to_string() +
                  " q 8 3 8 10"
                } else {
                  "M " +
                  stem_x.to_string() +
                  " " +
                  y2.to_string() +
                  " q -8 3 -8 10"
                }
                children.push(
                  @luna_dom.svg_path(
                    d=flag_d,
                    fill="none",
                    stroke=color_foreground,
                    stroke_width="1.5",
                  ),
                )
              }
              _ => ()
            }
          }
          Half => ()
        }
      }
      None => {
        // Render rest
        let rest_y = y + staff_line_spacing * 2.0
        children.push(
          match note.duration {
            Quarter => {
              let path_d = "M " +
                note_x.to_string() +
                " " +
                rest_y.to_string() +
                " l 5 -10 l -5 -5 l 5 5 l -5 10 l 3 8"
              @luna_dom.svg_path(
                d=path_d,
                stroke=color_foreground,
                fill=color_foreground,
                stroke_width="1",
              )
            }
            Half =>
              @luna_dom.svg_rect(
                x=(note_x - 6.0).to_string(),
                y=(rest_y - 4.0).to_string(),
                width="12",
                height="4",
                fill=color_foreground,
              )
            Eighth => {
              let path_d = "M " +
                note_x.to_string() +
                " " +
                rest_y.to_string() +
                " l 3 -8 l 4 4"
              @luna_dom.svg_path(
                d=path_d,
                stroke=color_foreground,
                fill="none",
                stroke_width="1.5",
              )
            }
          },
        )
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
      // Account for leading rest (1 measure)
      let pos_after_rest = pos - measure_duration_ms
      if pos_after_rest < 0.0 {
        -1 // Still in leading rest, no chord to highlight
      } else {
        (pos_after_rest / measure_duration_ms).to_int()
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
      @luna_dom.for_each(fn() { measures() }, fn(measure, _idx) {
        render_measure(measure, current_measure_index)
      }),
    ]),
  ])
}
