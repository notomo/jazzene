///|
/// Measure assembly - combines all musical notation elements

///|
/// Render a single measure with all its elements
pub fn render_measure(
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
  let chord_nodes = render_chord_symbol(measure, x, y, current_measure_index)
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
        let note_y = @music.midi_to_staff_y(midi, y)
        let stem_up = midi < 71
        let measure_start_x = x // Left edge of measure (ties come from previous measure)
        let measure_end_x = x + measure_width
        match note.tie_state {
          @music.TieStart =>
            children.push(
              render_tie_start(note_x, note_y, measure_end_x, stem_up),
            )
          @music.TieEnd =>
            children.push(
              render_tie_end(measure_start_x, note_x, note_y, stem_up),
            )
          @music.TieBoth => {
            children.push(
              render_tie_end(measure_start_x, note_x, note_y, stem_up),
            )
            children.push(
              render_tie_start(note_x, note_y, measure_end_x, stem_up),
            )
          }
          @music.TieState::None => ()
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
  @luna_dom.svg_g(children)
}
