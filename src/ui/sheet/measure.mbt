///|
/// Measure assembly - combines all musical notation elements

///|
/// Render a single measure with all its elements
pub fn render_measure(
  measure : @music.Measure,
  display_index : Int,
  playback_position : @signal.Signal[@music.Duration],
) -> @luna_dom.DomNode {
  let (x, y) = measure_position(display_index)
  let children : Array[@luna_dom.DomNode] = []

  // Clickable background for seeking (added last to be on top)
  let measure_number = display_index + 1
  let clickable_background = @luna_dom.svg_rect(
    x=x.to_string(),
    y=(y - 80.0).to_string(),
    width=measure_width.to_string(),
    height=row_height.to_string(),
    fill="transparent",
    style="cursor: pointer",
    attrs=[
      ("aria-label", @luna_dom.Attr::AttrString("measure \{measure_number}")),
      ("pointer-events", @luna_dom.Attr::AttrString("all")),
    ],
    on=@luna_dom.events().click(fn(_) {
      playback_position.set(measure.start_time)
    }),
  )

  // Staff lines (extend to include clef space on first measure of each row)
  let is_first_in_row = display_index % measures_per_row == 0
  if is_first_in_row {
    children.push(
      render_staff_lines(
        x - clef_space_width,
        y,
        width=measure_width + clef_space_width,
      ),
    )
  } else {
    children.push(render_staff_lines(x, y))
  }

  // Treble clef (only on first measure of each row, positioned in clef space)
  if is_first_in_row {
    children.push(render_treble_clef(x - clef_space_width, y))
  }

  // Chord symbol (static)
  let chord_nodes = render_chord_symbol(measure, x, y)
  for node in chord_nodes {
    children.push(node)
  }

  // Notes and rests
  for note in measure.notes {
    let note_x = x + 60.0 + note.start_beat * (measure_width - 80.0) / 4.0
    match note.midi {
      Some(midi) => {
        // Render note
        let note_nodes = render_note(note, note_x, y)
        for node in note_nodes {
          children.push(node)
        }

        // Render tie arcs if needed
        for node in render_tie_arcs(note.tie, note_x, midi, y, x) {
          children.push(node)
        }
      }
      None => {
        // Render rest
        let rest_nodes = render_rest(note, note_x, y)
        for node in rest_nodes {
          children.push(node)
        }
      }
    }
  }

  // Bar line
  children.push(render_bar_line(x + measure_width, y))

  // Add clickable background on top
  children.push(clickable_background)
  @luna_dom.svg_g(children)
}
