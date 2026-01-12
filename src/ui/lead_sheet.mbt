///|
/// Lead Sheet Visualization Component
/// Displays chord symbols, staff notation, and rhythm in SVG format

// Layout constants
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
/// Render measure background highlight
fn render_measure_background(
  x : Double,
  y : Double,
  is_current : Bool,
) -> @luna_dom.DomNode {
  @luna_dom.svg_rect(
    x=x.to_string(),
    y=(y - 20.0).to_string(),
    width=measure_width.to_string(),
    height="180",
    fill=if is_current { "rgba(59, 130, 246, 0.1)" } else { "transparent" },
    stroke=if is_current { "#3b82f6" } else { "#e2e8f0" },
    stroke_width=if is_current { "2" } else { "1" },
    rx="4",
  )
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
        stroke="#1e293b",
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
    fill="#1e293b",
    [@luna_dom.text("𝄞")],
  )
}

///|
/// Render chord symbol
fn render_chord_symbol(
  x : Double,
  chord : @music.Chord,
  is_current : Bool,
) -> @luna_dom.DomNode {
  let fill_color = if is_current { "#3b82f6" } else { "#1e293b" }
  let font_weight = if is_current { "bold" } else { "normal" }
  @luna_dom.svg_text(
    x=(x + 10.0).to_string(),
    y="40",
    text_anchor="start",
    font_size="24",
    font_family="serif",
    fill=fill_color,
    attrs=[("font-weight", @luna_dom.Attr::AttrString(font_weight))],
    [@luna_dom.text(@music.format_chord(chord))],
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
    stroke="#1e293b",
    stroke_width="2",
  )
}

///|
/// Render note head (filled or hollow based on duration)
fn render_note_head(
  x : Double,
  y : Double,
  duration : @music.NoteDuration,
  is_current : Bool,
) -> @luna_dom.DomNode {
  let fill_color = if is_current { "#3b82f6" } else { "#000000" }
  match duration {
    Eighth | Quarter =>
      @luna_dom.svg_circle(
        cx=x.to_string(),
        cy=y.to_string(),
        r="4",
        fill=fill_color,
        stroke="none",
      )
    Half =>
      @luna_dom.svg_circle(
        cx=x.to_string(),
        cy=y.to_string(),
        r="4",
        fill="none",
        stroke=fill_color,
        stroke_width="1.5",
      )
  }
}

///|
/// Render note stem and flag
fn render_note_stem(
  x : Double,
  y : Double,
  midi : Int,
  duration : @music.NoteDuration,
  is_current : Bool,
) -> Array[@luna_dom.DomNode] {
  let stroke_color = if is_current { "#3b82f6" } else { "#000000" }
  let nodes = []
  let stem_height = 30.0
  let stem_up = midi < 71 // B4 and below: stem up
  match duration {
    Eighth | Quarter => {
      // Render stem
      let stem_x = if stem_up { x + 4.0 } else { x - 4.0 }
      let y1 = y
      let y2 = if stem_up { y - stem_height } else { y + stem_height }
      nodes.push(
        @luna_dom.svg_line(
          x1=stem_x.to_string(),
          y1=y1.to_string(),
          x2=stem_x.to_string(),
          y2=y2.to_string(),
          stroke=stroke_color,
          stroke_width="1.5",
        ),
      )

      // Add flag for eighth notes
      match duration {
        Eighth => {
          let flag_d = if stem_up {
            "M " + stem_x.to_string() + " " + y2.to_string() + " q 8 3 8 10"
          } else {
            "M " + stem_x.to_string() + " " + y2.to_string() + " q -8 3 -8 10"
          }
          nodes.push(
            @luna_dom.svg_path(
              d=flag_d,
              stroke=stroke_color,
              fill="none",
              stroke_width="1.5",
            ),
          )
        }
        _ => ()
      }
    }
    Half => ()
  }
  nodes
}

///|
/// Render a rest symbol
fn render_rest(
  x : Double,
  y : Double,
  duration : @music.NoteDuration,
) -> @luna_dom.DomNode {
  match duration {
    Quarter => {
      // Quarter rest (simplified zigzag)
      let path_d = "M " +
        x.to_string() +
        " " +
        y.to_string() +
        " l 5 -10 l -5 -5 l 5 5 l -5 10 l 3 8"
      @luna_dom.svg_path(
        d=path_d,
        stroke="#000000",
        fill="#000000",
        stroke_width="1",
      )
    }
    Half =>
      // Half rest (rectangle above middle line)
      @luna_dom.svg_rect(
        x=(x - 6.0).to_string(),
        y=(y - 4.0).to_string(),
        width="12",
        height="4",
        fill="#000000",
      )
    Eighth => {
      // Eighth rest (simplified flag)
      let path_d = "M " + x.to_string() + " " + y.to_string() + " l 3 -8 l 4 4"
      @luna_dom.svg_path(
        d=path_d,
        stroke="#000000",
        fill="none",
        stroke_width="1.5",
      )
    }
  }
}

///|
/// Render all notes in a measure
fn render_notes(
  measure_x : Double,
  measure_y : Double,
  notes : Array[@music.MeasureNote],
  is_current : Bool,
) -> Array[@luna_dom.DomNode] {
  let nodes = []
  let rest_y = measure_y + staff_line_spacing * 2.0 // Middle of staff
  for note in notes {
    let note_x = measure_x +
      60.0 +
      note.start_beat * (measure_width - 80.0) / 4.0
    match note.midi {
      Some(midi) => {
        // Render note
        let note_y = @music.midi_to_staff_y(midi, measure_y)
        nodes.push(render_note_head(note_x, note_y, note.duration, is_current))
        let stem_nodes = render_note_stem(
          note_x,
          note_y,
          midi,
          note.duration,
          is_current,
        )
        for stem_node in stem_nodes {
          nodes.push(stem_node)
        }
      }
      None =>
        // Render rest
        nodes.push(render_rest(note_x, rest_y, note.duration))
    }
  }
  nodes
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

  // Build SVG content
  let svg_content = @signal.memo(fn() {
    let measure_list = measures()
    let current_idx = current_measure_index()
    let children : Array[@luna_dom.DomNode] = []
    if measure_list.length() == 0 {
      // Show placeholder message in SVG
      children.push(
        @luna_dom.svg_text(
          x="600",
          y="200",
          text_anchor="middle",
          font_size="20",
          fill="#6b7280",
          [@luna_dom.text("Enter a chord progression to see the lead sheet")],
        ),
      )
    } else {
      // Render measures
      for measure in measure_list {
        let (x, y) = measure_position(measure.measure_index)
        let is_current = measure.measure_index == current_idx

        // Background highlight
        children.push(render_measure_background(x, y, is_current))

        // Staff lines
        children.push(render_staff_lines(x, y))

        // Treble clef (only on first measure of each row)
        if measure.measure_index % measures_per_row == 0 {
          children.push(render_treble_clef(x, y))
        }

        // Chord symbol
        children.push(render_chord_symbol(x, measure.chord, is_current))

        // Notes
        let note_nodes = render_notes(x, y, measure.notes, is_current)
        for node in note_nodes {
          children.push(node)
        }

        // Bar line
        children.push(render_bar_line(x + measure_width, y))
      }
    }
    children
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
  @luna_dom.div(class="w-full h-full overflow-auto bg-white p-4", [
    @luna_dom.svg(
      viewBox="0 0 1200 " + svg_height(),
      width="100%",
      svg_content(),
    ),
  ])
}
